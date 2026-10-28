"""Verify an original release bundle against the published private channel.

The editor base is the release's exact pack.json. No cloud route serves it, so
the original bundle files are copied into the editor store; they are never
rebuilt. The authenticated channel manifest is the only authority."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path

from ..authoring_service import require
from ..language_profiles import get_profile
from ..word_registry import digest
from .publisher import FILES

INBOX = 'published-bundles'
# Fields the server adds to (or overrides in) the uploaded draft manifest.
SERVER_FIELDS = {'pack_canonical_sha256', 'release_id', 'channel', 'generation',
                 'parent_release_id', 'parent_manifest_sha256', 'created_at'}
SHA = re.compile(r'[0-9a-f]{64}')
UUID = re.compile(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')


def _sha256(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def channel_binding(channel, lang):
    """Validates the publisher channel answer; returns its identity."""
    require(isinstance(channel, dict) and isinstance(channel.get('manifest'), dict)
            and type(channel.get('generation')) is int and channel['generation'] > 0 and channel.get('release_id'),
            'PUBLISHED_BASE_NONE', 'Im privaten Kanal ist noch keine Version veröffentlicht.', status=409)
    m = channel['manifest']
    require(UUID.fullmatch(str(channel['release_id'])) and m.get('release_id') == channel['release_id']
            and m.get('generation') == channel['generation'] and SHA.fullmatch(str(channel.get('manifest_sha256')))
            and digest(m) == channel['manifest_sha256'],
            'PUBLISHED_CHANNEL_INVALID', 'Antwort des privaten Kanals ist widersprüchlich.', status=502)
    profile = get_profile(lang, m.get('profile_id'))
    require(m.get('lang') == lang and m.get('channel') == 'internal' and m.get('schema_version') == 5
            and m.get('profile_id') == profile.id and m.get('profile_sha256') == profile.sha256
            and isinstance(m.get('version'), str) and type(m.get('size_bytes')) is int
            and all(SHA.fullmatch(str(m.get(k))) for k in ('sha256', 'pack_json_sha256', 'pack_canonical_sha256',
                    'registry_sha256', 'history_inventory_sha256', 'editorial_reviews_sha256')),
            'PROFILE_UNSUPPORTED', 'Veröffentlichte Version passt nicht zu Sprache, Schema oder Profil dieses Editors.', status=409)
    return {'generation': channel['generation'], 'release_id': channel['release_id'],
            'manifest_sha256': channel['manifest_sha256'], 'version': m['version']}


def verify_bundle(directory, manifest, lang):
    """All nine files present; every byte and canonical hash bound by the published manifest."""
    directory = Path(directory)
    def fail(message):
        return 'PUBLISHED_BUNDLE_MISMATCH', message
    for name in FILES:
        path = directory / name
        require(path.is_file() and not path.is_symlink(), 'PUBLISHED_BUNDLE_INCOMPLETE', 'Bundledatei fehlt: ' + name, status=409)
    files = {name: {'sha256': _sha256(directory / name), 'size_bytes': (directory / name).stat().st_size} for name in FILES}
    require(files['content.sqlite'] == {'sha256': manifest['sha256'], 'size_bytes': manifest['size_bytes']},
            *fail('content.sqlite entspricht nicht der veröffentlichten Version.'), status=409)
    require(files['pack.json']['sha256'] == manifest['pack_json_sha256'],
            *fail('pack.json entspricht nicht den veröffentlichten Bytes.'), status=409)
    raw = (directory / 'pack.json').read_bytes()
    require(hashlib.sha256(raw).hexdigest() == manifest['pack_json_sha256'], *fail('pack.json wurde während der Prüfung verändert.'), status=409)
    pack = json.loads(raw)
    require(digest(pack) == manifest['pack_canonical_sha256'], *fail('Kanonischer Packhash weicht ab.'), status=409)
    require(pack.get('lang') == lang and pack.get('release', {}).get('version') == manifest['version']
            and pack.get('word_registry', {}).get('sha256') == manifest['registry_sha256'],
            *fail('Sprache, Version oder Registry des Packs weichen ab.'), status=409)
    for name, key in [('registry.json', 'registry_sha256'), ('history_inventory.json', 'history_inventory_sha256'),
                      ('editorial_reviews.json', 'editorial_reviews_sha256')]:
        require(digest(json.loads((directory / name).read_text(encoding='utf-8'))) == manifest[key],
                *fail(name + ' entspricht nicht der veröffentlichten Version.'), status=409)
    local = json.loads((directory / 'content.manifest.json').read_text(encoding='utf-8'))
    shared = set(local) - {'local_only'} - SERVER_FIELDS
    require(local.get('local_only') is True and all(k in manifest and local[k] == manifest[k] for k in shared)
            and set(manifest) - shared <= SERVER_FIELDS,
            *fail('Lokales Bundlemanifest passt nicht zum veröffentlichten Manifest.'), status=409)
    return pack, raw, files


def locate(root, manifest, lang):
    """Finds the copied original bundle for the published manifest in the store inbox."""
    inbox = Path(root) / INBOX
    candidates = []
    for directory in sorted(p for p in inbox.iterdir() if p.is_dir() and not p.is_symlink()) if inbox.is_dir() else []:
        try:
            local = json.loads((directory / 'content.manifest.json').read_text(encoding='utf-8'))
        except (OSError, ValueError):
            continue
        if local.get('version') == manifest['version'] and local.get('sha256') == manifest['sha256']:
            candidates.append(directory)
    require(candidates, 'PUBLISHED_BUNDLE_MISSING',
            f'Originalbundle von „{manifest["version"]}“ fehlt. Die neun Dateien ' + ', '.join(FILES)
            + f' als eigenen Ordner nach {inbox} kopieren und die Vorschau erneut öffnen.', status=409)
    errors = []
    for directory in candidates:
        try:
            return (directory, *verify_bundle(directory, manifest, lang))
        except Exception as e:  # report the first concrete mismatch, never accept a partial match
            errors.append(e)
    raise errors[0]
