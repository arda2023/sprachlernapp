"""Crash-safe JSON revisions and receipts, under one process/writer lock."""
from __future__ import annotations

import copy
import json
import os
import re
import sys
import threading
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

from ..authoring_service import AuthoringError
from ..word_registry import digest


def utc_now(): return datetime.now(timezone.utc).isoformat()


def default_directory():
    if sys.platform=='win32':return Path(os.environ['LOCALAPPDATA'])/'SprachappContentEditor'
    if sys.platform=='darwin':return Path.home()/'Library'/'Application Support'/'SprachappContentEditor'
    return Path.home()/'.local'/'share'/'SprachappContentEditor'


def atomic_json(path,value):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
    temporary=path.with_name('.'+path.name+'.'+uuid.uuid4().hex+'.tmp')
    try:
        with temporary.open('x',encoding='utf-8',newline='\n') as f:
            json.dump(value,f,ensure_ascii=False,sort_keys=True,indent=2,allow_nan=False);f.write('\n');f.flush();os.fsync(f.fileno())
        os.replace(temporary,path)
        if os.name!='nt':
            fd=os.open(path.parent,os.O_RDONLY)
            try:os.fsync(fd)
            finally:os.close(fd)
    finally:
        temporary.unlink(missing_ok=True)


def read_json(path):
    with Path(path).open(encoding='utf-8') as f:return json.load(f)


class EditorStore:
    def __init__(self,root=None):
        self.root=Path(root or default_directory()).resolve()
        self.root.mkdir(parents=True,exist_ok=True)
        self.mutex=threading.RLock()
        self._lock=(self.root/'process.lock').open('a+b')
        self._lock.seek(0);self._lock.write(b'0');self._lock.flush();self._lock.seek(0)
        try:
            if os.name=='nt':
                import msvcrt
                msvcrt.locking(self._lock.fileno(),msvcrt.LK_NBLCK,1)
            else:
                import fcntl
                fcntl.flock(self._lock.fileno(),fcntl.LOCK_EX|fcntl.LOCK_NB)
        except OSError:
            self._lock.close();raise AuthoringError('EDITOR_RUNNING','Dieses Editorverzeichnis wird bereits von einem Dienst verwendet.',status=409)
        self._recover_jobs()

    def close(self):
        if self._lock.closed:return
        if os.name=='nt':
            import msvcrt
            self._lock.seek(0);msvcrt.locking(self._lock.fileno(),msvcrt.LK_UNLCK,1)
        else:
            import fcntl
            fcntl.flock(self._lock.fileno(),fcntl.LOCK_UN)
        self._lock.close()

    @staticmethod
    def identifier(value):
        if not isinstance(value,str) or not re.fullmatch(r'[a-zA-Z0-9_-]{1,100}',value):
            raise AuthoringError('IDENTIFIER_INVALID','Ungültige lokale Referenz.',status=400)
        return value

    def path(self,kind,identifier):
        if kind not in ('drafts','imports','jobs','artifacts','releases','languages','bases','heads'):
            raise ValueError('unknown store kind')
        return self.root/kind/self.identifier(identifier)

    def put(self,kind,identifier,value):
        with self.mutex:atomic_json(self.path(kind,identifier).with_suffix('.json'),value)

    def get(self,kind,identifier):
        try:return read_json(self.path(kind,identifier).with_suffix('.json'))
        except FileNotFoundError:raise AuthoringError('NOT_FOUND','Lokaler Eintrag nicht gefunden.',status=404) from None

    def list(self,kind):
        folder=self.root/kind
        if not folder.exists():return []
        return [read_json(p) for p in sorted(folder.glob('*.json'))]

    @staticmethod
    def etag(draft):return f'"draft:{draft["draft_id"]}:{draft["revision"]}:{digest(draft)}"'

    def load_draft(self,identifier):
        folder=self.path('drafts',identifier)
        try: pointer=read_json(folder/'current.json');return read_json(folder/'revisions'/f'{pointer["revision"]}.json')
        except FileNotFoundError:raise AuthoringError('NOT_FOUND','Entwurf nicht gefunden.',status=404) from None

    def save_draft(self,draft,expected=None):
        with self.mutex:
            folder=self.path('drafts',draft['draft_id'])
            exists=(folder/'current.json').exists()
            if exists:
                current=self.load_draft(draft['draft_id'])
                if expected is None:raise AuthoringError('PRECONDITION_REQUIRED','Entwurfsrevision fehlt.',status=428)
                if expected!=self.etag(current):raise AuthoringError('DRAFT_CHANGED','Dieser Entwurf wurde in einem anderen Tab geändert. Aktuellen Stand laden und vergleichen.',status=409)
                revision=current['revision']+1
            else:revision=1
            saved=copy.deepcopy(draft);saved.update(revision=revision,updated_at=utc_now())
            atomic_json(folder/'revisions'/f'{revision}.json',saved)
            atomic_json(folder/'current.json',{'revision':revision})
            return saved

    def drafts(self):
        folder=self.root/'drafts'
        return [self.load_draft(p.name) for p in sorted(folder.iterdir()) if p.is_dir() and (p/'current.json').exists()] if folder.exists() else []

    def artifact(self,path,filename,media_type):
        path=Path(path).resolve()
        if not path.is_relative_to(self.root):raise ValueError('artifact outside editor storage')
        identifier=str(uuid.uuid4())
        self.put('artifacts',identifier,{'id':identifier,'path':str(path.relative_to(self.root)),
                 'filename':Path(filename).name,'media_type':media_type})
        return identifier

    def artifact_path(self,identifier):
        metadata=self.get('artifacts',identifier);path=(self.root/metadata['path']).resolve()
        if not path.is_relative_to(self.root) or not path.is_file():raise AuthoringError('NOT_FOUND','Exportdatei nicht verfügbar.',status=404)
        return path,metadata

    def _recover_jobs(self):
        for job in self.list('jobs'):
            if job['state'] in ('queued','running','cancelling'):
                job.update(state='interrupted',message='Dienst wurde beendet. Ausgangsstand bleibt erhalten; Auftrag erneut starten.')
                self.put('jobs',job['job_id'],job)
