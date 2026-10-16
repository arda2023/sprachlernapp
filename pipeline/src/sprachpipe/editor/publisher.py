"""Private publication transport. Auth tokens exist only in this process."""
from __future__ import annotations
import hashlib
import json
import os
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from ..authoring_service import AuthoringError, require
from ..word_registry import digest

FILES=('content.sqlite','pack.json','registry.json','history_inventory.json','editorial_reviews.json',
       'provenance.json','finalization_report.json','content.manifest.json','reader_report.json')

# Never reflect arbitrary remote text or even arbitrary remote "code" strings:
# either field could contain credentials, signed URLs or content. Known protocol
# codes are useful diagnostics; explanations are authored locally.
SERVER_REASONS={
    'REQUEST_FAILED':'Server konnte die Anfrage nicht verarbeiten.',
    'REQUEST_OBJECT':'Server erwartet ein JSON-Objekt im Anfrageinhalt.',
    'AUTH_REQUIRED':'Anmeldung ist serverseitig nicht gültig.',
    'PUBLISHER_REQUIRED':'Publisherrecht fehlt.',
    'UPLOAD_FORBIDDEN':'Upload gehört nicht zum angemeldeten Konto.',
    'UPLOAD_EXPIRED':'Upload ist abgelaufen oder bereits als fehlgeschlagen markiert.',
    'OBJECT_MISSING':'Eine hochgeladene Datei fehlt.',
    'OBJECT_HASH':'Prüfsumme einer hochgeladenen Datei stimmt nicht.',
    'OBJECT_SIZE':'Größe einer hochgeladenen Datei stimmt nicht.',
    'OBJECT_JSON':'Eine hochgeladene JSON-Datei ist nicht lesbar.',
    'BACKEND_UNAVAILABLE':'Function konnte ihren Backendzugriff nicht abschließen.',
    'CONFLICT':'Serverstand hat sich geändert.',
}
SERVER_CODES=frozenset(SERVER_REASONS)|frozenset('''REQUEST_ID SCOPE_UNSUPPORTED GENERATION_INVALID
    PARENT_INVALID PUBLICATION_KIND ADOPTION_FIRST_ONLY MANIFEST_INCOMPATIBLE VERSION_INVALID
    OBJECT_SET_INVALID OBJECT_LIMIT MANIFEST_HASH_MISMATCH SERVER_CONFIG SCOPE_INVALID READER_REQUIRED
    UPLOAD_ID OBJECT_KEY JSON_LIMIT MANIFEST_CHANGED ATTESTATION_INVALID VALIDATION_HASH REVIEW_UNBOUND
    SIDECAR_HASH HISTORY_INVALID PACK_SCOPE INCOMPLETE_DELIVERY PARENT_CHANGED REGISTRY_INVALID
    REGISTRY_HISTORY_LOSS HISTORY_LOSS CONTEXT_HISTORY_LOSS STORY_HISTORY_LOSS ADOPTION_INVALID
    ADOPTION_CONFIRMATION ADOPTION_CONTENT_CHANGED ADOPTION_CHANNEL_OCCUPIED CATALOG_INVALID
    METHOD REQUEST_LIMIT REQUEST_CONFLICT NOT_FOUND'''.split())


class PublicationHTTPError(AuthoringError):
    def __init__(self,status,step,server_code,reason):
        self.diagnostic={'step':step,'http_status':status,'server_code':server_code,'reason':reason}
        message=f'{step}: HTTP {status}'+(f' · {server_code}' if server_code else '')+f'. {reason}'
        super().__init__('PUBLISH_HTTP_'+str(status),message,status=status if status in (401,403,409) else 502)

    def finding(self):
        return {**super().finding(),'diagnostic':self.diagnostic}


def http_failure(error,path,*,file=None):
    step='Dateiupload' if file else 'Veröffentlichung'
    if path.startswith('/functions/v1/content-publish/'):
        action=path.split('?',1)[0].rsplit('/',1)[-1]
        step={'start':'Upload vorbereiten','channel':'Kanalbasis prüfen',
              'finalize':'Serverprüfung','commit':'Veröffentlichen'}.get(action,step)
    code=None;reason=None
    try:
        raw=error.read(16385)
        value=json.loads(raw) if len(raw)<=16384 else None
        if isinstance(value,dict):
            candidate=value.get('code')
            if isinstance(candidate,str) and candidate in SERVER_CODES:
                code=candidate;reason=SERVER_REASONS.get(code,'Server hat eine Vertrags- oder Inhaltsprüfung abgelehnt.')
            else:
                if type(candidate) is int and 400<=candidate<=599:code=candidate
                if value.get('message')=='Invalid JWT':reason='Gateway hat die Anmeldung abgelehnt (Invalid JWT).'
                elif value.get('message')=='Missing authorization header':reason='Gateway meldet einen fehlenden Authorization-Header.'
    except (ValueError,UnicodeError,OSError,RecursionError):pass
    if reason is None:
        reason=('Anmeldung/Berechtigung prüfen.' if error.code in (401,403) else
                'Serverstand geändert oder Datei bereits hochgeladen.' if error.code==409 else
                'Server meldet einen numerischen Fehlercode; freier Antworttext wurde nicht übernommen.' if code is not None else
                'Kein freigegebener Serverfehlercode lesbar; Antwortdetails aus Sicherheitsgründen nicht übernommen.')
    return PublicationHTTPError(error.code,step,code,reason)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,req,fp,code,msg,headers,newurl):
        raise AuthoringError('PUBLISH_REDIRECT','Unerwartete Weiterleitung der privaten Veröffentlichung.',status=502)


class Publisher:
    def __init__(self,url=None,public_key=None,*,transport=None):
        self.url=(url if url is not None else os.environ.get('SPRACHAPP_SUPABASE_URL','')).rstrip('/')
        self.key=public_key if public_key is not None else os.environ.get('SPRACHAPP_SUPABASE_ANON_KEY','')
        self._session=None;self._lock=threading.RLock();self._transport=transport or self._http
        if self.url:
            parsed=urllib.parse.urlsplit(self.url)
            require(parsed.scheme=='https' or (parsed.scheme=='http' and parsed.hostname in ('127.0.0.1','localhost')),
                    'PUBLISH_CONFIG','Supabase benötigt HTTPS; HTTP ist nur lokal erlaubt.')
            require(not parsed.username and not parsed.password and not parsed.query and not parsed.fragment,'PUBLISH_CONFIG','Ungültige Projektadresse.')
        if self.key.startswith('ey'):
            import base64
            try:role=json.loads(base64.urlsafe_b64decode(self.key.split('.')[1]+'==='))['role']
            except (ValueError,KeyError,IndexError):role=None
            require(role!='service_role','PUBLISH_CONFIG','Lokaler Publisher darf keinen Service-Role-Schlüssel verwenden.')
        require(not self.key.startswith('sb_secret_'),'PUBLISH_CONFIG','Nur öffentlicher Authclientkey erlaubt.')

    def status(self):
        return {'configured':bool(self.url and self.key),'signed_in':self._session is not None,
                'expires_at':self._session.get('expires_at') if self._session else None}

    def _http(self,method,path,body=None,*,token=None,file=None):
        url=self.url+path
        headers={'apikey':self.key,'Content-Type':'application/json'}
        if token:headers['Authorization']='Bearer '+token
        stream=None
        try:
            if file:
                stream=Path(file).open('rb');body=stream
                headers.update({'Content-Type':'application/octet-stream','Content-Length':str(Path(file).stat().st_size),'x-upsert':'false'})
            elif body is not None:body=json.dumps(body,ensure_ascii=False,allow_nan=False).encode()
            request=urllib.request.Request(url,data=body,headers=headers,method=method)
            with urllib.request.build_opener(NoRedirect()).open(request,timeout=60) as response:
                raw=response.read(4*1024*1024+1)
                require(len(raw)<=4*1024*1024,'PUBLISH_RESPONSE','Serverantwort zu groß.',status=502)
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            # Never include URL, signed token, raw headers or remote response in logs.
            if path=='/auth/v1/token?grant_type=password':
                try:code=json.loads(e.read(16384)).get('error_code')
                except (ValueError,UnicodeError,AttributeError):code=None
                messages={
                    'invalid_credentials':'E-Mail-Adresse oder Passwort ist falsch.',
                    'email_not_confirmed':'E-Mail-Adresse noch nicht bestätigt. Kontostatus administrativ prüfen.',
                    'user_banned':'Dieses Konto ist gesperrt. Kontostatus administrativ prüfen.',
                }
                raise AuthoringError('PASSWORD_LOGIN_FAILED',messages.get(code,
                    'Anmeldung fehlgeschlagen. Zugangsdaten, Kontostatus und Verbindung prüfen.'),
                    status=401 if e.code in (400,401,403,422) else 502) from None
            raise http_failure(e,path,file=file) from None
        except (urllib.error.URLError,TimeoutError,OSError):
            raise AuthoringError('PUBLISH_NETWORK','Privater Server nicht erreichbar. Lokale Inhalte bleiben erhalten.',status=502) from None
        finally:
            if stream:stream.close()

    def _configured(self):require(self.status()['configured'],'PUBLISH_CONFIG','SPRACHAPP_SUPABASE_URL und öffentlichen SPRACHAPP_SUPABASE_ANON_KEY lokal konfigurieren.',status=503)

    def request_otp(self,email):
        self._configured();require(isinstance(email,str) and '@' in email and len(email)<=254,'EMAIL_INVALID','Gültige Einladungsadresse angeben.')
        self._transport('POST','/auth/v1/otp',{'email':email,'create_user':False})
        return {'sent':True}

    def verify_otp(self,email,code):
        self._configured();require(isinstance(code,str) and code.isdigit() and 6<=len(code)<=10,'OTP_INVALID','E-Mail-Code angeben.')
        session=self._transport('POST','/auth/v1/verify',{'email':email,'token':code,'type':'email'})
        with self._lock:self._remember_session(session)
        return self.status()

    def sign_in_with_password(self,email,password):
        self._configured()
        require(isinstance(email,str) and '@' in email and len(email)<=254,
                'EMAIL_INVALID','Gültige E-Mail-Adresse angeben.')
        require(isinstance(password,str) and 0<len(password)<=4096,
                'PASSWORD_INVALID','Passwort angeben (höchstens 4096 Zeichen).')
        with self._lock:
            session=self._transport('POST','/auth/v1/token?grant_type=password',
                                    {'email':email.strip(),'password':password})
            self._remember_session(session)
        return self.status()

    def _remember_session(self,session):
        require(isinstance(session,dict) and isinstance(session.get('user'),dict)
                and bool(session['user'].get('id')) and bool(session.get('access_token'))
                and bool(session.get('refresh_token')),'AUTH_REQUIRED','Anmeldung nicht bestätigt.',status=401)
        # Retain only session fields from the successful Auth response, never input credentials.
        self._session={'access_token':session['access_token'],'refresh_token':session['refresh_token'],
                       'user_id':session['user']['id'],
                       'expires_at':session.get('expires_at',time.time()+session.get('expires_in',3600))}

    def sign_out(self):
        # Local logout always succeeds offline and removes both tokens from memory.
        with self._lock:self._session=None
        return self.status()

    def _token(self):
        self._configured()
        with self._lock:
            require(self._session is not None,'AUTH_REQUIRED','Zuerst mit der eingeladenen E-Mail-Adresse anmelden.',status=401)
            if self._session['expires_at']<=time.time()+30:
                try:self._remember_session(self._transport('POST','/auth/v1/token?grant_type=refresh_token',{'refresh_token':self._session['refresh_token']}))
                except AuthoringError:self._session=None;raise
            return self._session['access_token']

    def call(self,path,body=None,method='POST'):
        # The function requires a JSON object for every POST, including finalize.
        if method=='POST' and body is None:body={}
        return self._transport(method,'/functions/v1/content-publish/'+path,body,token=self._token())

    def channel(self,lang):
        # Publisher-only channel query; publishing never relies on a reader grant.
        return self.call('channel?lang='+urllib.parse.quote(lang),method='GET')

    def upload(self,signed_path,file):
        parsed=urllib.parse.urlsplit(signed_path)
        require(not parsed.scheme and not parsed.netloc and parsed.path.startswith('/object/upload/sign/content-private/'),
                'UPLOAD_URL_INVALID','Ungültige private Uploadberechtigung.')
        try:return self._transport('PUT','/storage/v1'+signed_path,file=file)
        except AuthoringError as e:
            if e.status!=409:raise
            # Retry of an immutable object: finalization still hashes every byte.
            return {'already_exists':True}


def inspect_bundle(directory,record,draft):
    directory=Path(directory)
    manifest=json.loads((directory/'content.manifest.json').read_text())
    require(manifest==record['manifest'],'BUNDLE_CHANGED','Manifest des geprüften Bundles verändert.',status=409)
    report=json.loads((directory/'finalization_report.json').read_text());reviews=json.loads((directory/'editorial_reviews.json').read_text())
    from ..authoring_service import draft_content_hash
    validation=report.get('validation',{})
    from ..baseline_adoption import KIND,verify_receipt
    require(record.get('publication_kind')==manifest.get('publication_kind') and
            manifest.get('publication_kind') in (None,KIND),'ADOPTION_INVALID','Unbekannte oder abweichende Veröffentlichungsart.')
    if manifest.get('publication_kind')==KIND:
        provenance=json.loads((directory/'provenance.json').read_text(encoding='utf-8'))
        require(isinstance(provenance,list) and len(provenance)==1,'ADOPTION_INVALID','Übernahmebeleg fehlt.')
        pack=json.loads((directory/'pack.json').read_text(encoding='utf-8'))
        verify_receipt(provenance[0],manifest,report,reviews,pack)
        require(digest(reviews)==manifest['editorial_reviews_sha256'],'ADOPTION_INVALID','Reviews verändert.')
    else:
        require(draft is not None and draft.get('state')!='discarded' and validation.get('technical')=='valid' and validation.get('editorial')=='approved'
                and validation.get('content_sha256')==draft_content_hash(draft),'REVIEW_STALE','Entwurf seit dem geprüften Export geändert oder nicht bestätigt. Neu prüfen und exportieren.',status=409)
        require(any(r.get('decision')=='approved' and r.get('payload_sha256')==validation['content_sha256'] for r in reviews)
                and digest(reviews)==manifest['editorial_reviews_sha256'],'REVIEW_STALE','Exportfreigabe fehlt oder wurde verändert.',status=409)
    objects={}
    for name in FILES:
        path=directory/name;require(path.is_file() and not path.is_symlink(),'BUNDLE_CHANGED','Bundledatei fehlt.',status=409)
        h=hashlib.sha256()
        with path.open('rb') as stream:
            for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
        objects[name]={'sha256':h.hexdigest(),'size_bytes':path.stat().st_size}
    require(objects['content.sqlite']['sha256']==manifest['sha256'] and objects['content.sqlite']['size_bytes']==manifest['size_bytes']
            and objects['pack.json']['sha256']==manifest['pack_json_sha256'],'BUNDLE_CHANGED','Exportdateien verändert.',status=409)
    for name,key in [('registry.json','registry_sha256'),('history_inventory.json','history_inventory_sha256')]:
        require(digest(json.loads((directory/name).read_text()))==manifest[key],'BUNDLE_CHANGED','Historien-/Registrydatei verändert.',status=409)
    return manifest,objects
