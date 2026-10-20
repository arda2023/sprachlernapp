"""User-run, one-time Auth Admin helper. Never imported by the editor.

No credential arguments, environment loading, files, or raw remote diagnostics.
"""
from __future__ import annotations

import getpass
import json
import sys
import urllib.error
import urllib.request
import warnings
from datetime import datetime, timezone

PROJECT_REF = 'yevntxclpchapacqdizm'
USER_ID = '2af98709-72e6-4f38-b36c-997473e9eb48'
PROJECT_URL = 'https://' + PROJECT_REF + '.supabase.co'


class AdminSetupError(Exception):
    pass


class RejectRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise AdminSetupError('Weiterleitung abgewiesen; keine Zugangsdaten weitergegeben.')


def admin_request(method, key, body=None):
    request = urllib.request.Request(
        PROJECT_URL + '/auth/v1/admin/users/' + USER_ID,
        data=None if body is None else json.dumps(body).encode('utf-8'),
        headers={'apikey': key, 'Authorization': 'Bearer ' + key,
                 'Content-Type': 'application/json'}, method=method,
    )
    try:
        with urllib.request.build_opener(RejectRedirect()).open(request, timeout=30) as response:
            raw = response.read(1024 * 1024 + 1)
            if len(raw) > 1024 * 1024:
                raise AdminSetupError('Adminantwort zu groß.')
            return json.loads(raw)
    except urllib.error.HTTPError as error:
        raise AdminSetupError('Auth Admin hat die Anfrage abgewiesen (HTTP ' + str(error.code) + ').') from None
    except (urllib.error.URLError, OSError, ValueError):
        raise AdminSetupError('Adminanfrage nicht bestätigt. Verbindung und Zielkonto prüfen.') from None


def validate_user(user, expected_email):
    if not isinstance(user, dict) or user.get('id') != USER_ID or user.get('email', '').casefold() != expected_email.casefold():
        raise AdminSetupError('UID oder E-Mail stimmt nicht mit dem bestehenden Zielkonto überein.')
    if not user.get('email_confirmed_at'):
        raise AdminSetupError('Adresse ist unbestätigt. Bestätigung dieses Kontos zuerst administrativ klären.')
    banned = user.get('banned_until')
    if banned and datetime.fromisoformat(banned.replace('Z', '+00:00')) > datetime.now(timezone.utc):
        raise AdminSetupError('Konto ist gesperrt. Sperre zuerst administrativ klären.')


def main():
    if len(sys.argv) != 1 or not sys.stdin.isatty():
        raise AdminSetupError('Ohne Argumente in einem interaktiven Terminal ausführen; keine Eingabeumleitung.')
    warnings.simplefilter('error', getpass.GetPassWarning)
    print('Nur Projekt sprachapp: ' + PROJECT_REF + '\nNur bestehende UID: ' + USER_ID)
    if input('Zielprojektref zur Prüfung eingeben: ').strip() != PROJECT_REF:
        raise AdminSetupError('Falsches Zielprojekt; abgebrochen.')
    email = input('Erwartete E-Mail des bestehenden Kontos: ').strip()
    key = password = repeated = None
    try:
        key = getpass.getpass('Admin-Secret/Service-Role-Key des Zielprojekts (verdeckt): ')
        validate_user(admin_request('GET', key), email)
        password = getpass.getpass('Neues Passwort (mindestens 12 Zeichen, verdeckt): ')
        repeated = getpass.getpass('Passwort wiederholen (verdeckt): ')
        if len(password) < 12 or password != repeated:
            raise AdminSetupError('Passwörter stimmen nicht überein oder sind zu kurz; nichts geändert.')
        if input('Zum Passwortsetzen exakt die oben genannte UID eingeben: ').strip() != USER_ID:
            raise AdminSetupError('Nicht bestätigt; nichts geändert.')
        validate_user(admin_request('PUT', key, {'password': password}), email)
        print('Passwort für die bestehende UID aktualisiert. Regulären Login selbst prüfen.')
    finally:
        # Drop references; Python cannot guarantee erasure of immutable strings from RAM.
        key = password = repeated = None


if __name__ == '__main__':
    try:
        main()
    except (AdminSetupError, getpass.GetPassWarning) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except (KeyboardInterrupt, EOFError):
        print('Abgebrochen.', file=sys.stderr)
        sys.exit(1)
    except Exception:
        print('Vorgang nicht bestätigt; Zielkonto prüfen. Keine Rohdiagnose mit Secrets ausgegeben.', file=sys.stderr)
        sys.exit(1)
