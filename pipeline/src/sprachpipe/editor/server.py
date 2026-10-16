"""Loopback-only HTTP adapter. No CORS, filesystem paths, shell or semantic rules."""
from __future__ import annotations

import hashlib
import hmac
import json
import secrets
import threading
import time
from email.parser import BytesParser
from email.policy import default
from http.cookies import SimpleCookie
from http.server import BaseHTTPRequestHandler,ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit,parse_qs,unquote

from ..authoring_service import AuthoringError,require,draft_content_hash,shared_gloss_impact,retirement_impact
from .exchange import ARCHIVE_LIMIT,json_bytes


class EditorHTTPServer(ThreadingHTTPServer):
    daemon_threads=True
    def __init__(self,service):
        self.service=service;self.bootstrap_token=secrets.token_urlsafe(32)
        self.bootstrap_deadline=time.monotonic()+300;self.sessions={};self.requests={};self.auth_lock=threading.Lock()
        super().__init__(('127.0.0.1',0),Handler)
        self.origin='http://127.0.0.1:'+str(self.server_port)

    @property
    def browser_url(self):return self.origin+'/#'+self.bootstrap_token


class Handler(BaseHTTPRequestHandler):
    protocol_version='HTTP/1.1'
    server_version='LocalContentEditor'

    def log_message(self,*args):pass

    def setup(self):
        super().setup();self.connection.settimeout(20)

    def respond(self,status,value,*,headers=None,media='application/json; charset=utf-8'):
        raw=value if isinstance(value,bytes) else json_bytes(value)
        self.send_response(status)
        for k,v in {'Content-Type':media,'Content-Length':str(len(raw)),'Cache-Control':'no-store',
                    'X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer',
                    'Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'",
                    'X-Frame-Options':'DENY','Connection':'close',**(headers or {})}.items():self.send_header(k,v)
        self.end_headers();self.wfile.write(raw);self.close_connection=True

    def guard(self):
        require(self.client_address[0]=='127.0.0.1','LOOPBACK_REQUIRED','Nur lokaler Zugriff.',status=403)
        require(self.headers.get_all('Host')==[self.server.origin.removeprefix('http://')],
                'HOST_REJECTED','Ungültiger Host.',status=403)
        origin=self.headers.get('Origin')
        require(origin is None or origin==self.server.origin,'ORIGIN_REJECTED','Fremder Ursprung.',status=403)
        if self.command=='POST':require(origin==self.server.origin,'ORIGIN_REQUIRED','Eigener Ursprung erforderlich.',status=403)

    def session(self):
        cookie=SimpleCookie()
        try:cookie.load(self.headers.get('Cookie',''))
        except Exception:pass
        token=cookie.get('editor_session');session=self.server.sessions.get(token.value if token else '')
        require(session is not None and session['expires']>time.monotonic(),'SESSION_REQUIRED','Lokale Sitzung abgelaufen. Dienst neu starten.',status=401)
        return session

    def body(self):
        lengths=self.headers.get_all('Content-Length') or []
        require(len(lengths)==1 and lengths[0].isdigit() and self.headers.get('Transfer-Encoding') is None,
                'BODY_INVALID','Eindeutige Inhaltslänge erforderlich.',status=400)
        length=int(lengths[0]);maximum=ARCHIVE_LIMIT+1024*1024 if self.path=='/api/v1/imports' else 25*1024*1024
        require(length<=maximum,'UPLOAD_LIMIT','Anfrage überschreitet das Größenlimit.',status=413)
        raw=self.rfile.read(length);require(len(raw)==length,'BODY_INVALID','Anfrage unvollständig.',status=400)
        if self.path=='/api/v1/imports' and self.headers.get_content_type()=='multipart/form-data':
            message=BytesParser(policy=default).parsebytes(('Content-Type: '+self.headers['Content-Type']+'\r\nMIME-Version: 1.0\r\n\r\n').encode()+raw)
            require(message.is_multipart(),'FORMAT_INVALID','Ungültiger Datei-Upload.')
            result={}
            for part in message.iter_parts():
                name=part.get_param('name',header='content-disposition')
                require(name in ('file','lang','source') and name not in result,'FORMAT_INVALID','Unbekanntes oder doppeltes Uploadfeld.')
                data=part.get_payload(decode=True)
                result[name]={'filename':part.get_filename(),'raw':data} if name=='file' else data.decode('utf-8')
            require('file' in result and 'lang' in result,'FIELD_REQUIRED','Datei und Sprache fehlen.')
            return result
        require(self.headers.get_content_type()=='application/json','FORMAT_UNSUPPORTED','JSON-Anfrage erforderlich.',status=400)
        def pairs(items):
            result={}
            for key,value in items:
                if key in result:raise ValueError('duplicate key')
                result[key]=value
            return result
        try:
            value=json.loads(raw,object_pairs_hook=pairs,parse_constant=lambda x:(_ for _ in ()).throw(ValueError(x)))
            require(isinstance(value,dict),'FORMAT_INVALID','JSON-Objekt erforderlich.',status=400)
            return value
        except (ValueError,UnicodeError):raise AuthoringError('FORMAT_INVALID','Ungültiges JSON.',status=400) from None

    def do_GET(self):self.dispatch()
    def do_POST(self):self.dispatch()

    def dispatch(self):
        try:
            self.guard();url=urlsplit(self.path);path=url.path;query={k:v[-1] for k,v in parse_qs(url.query).items()}
            if self.command=='GET' and path in ('/','/app.js','/style.css'):
                name='index.html' if path=='/' else path[1:]
                media={'index.html':'text/html; charset=utf-8','app.js':'text/javascript; charset=utf-8','style.css':'text/css; charset=utf-8'}[name]
                return self.respond(200,(Path(__file__).parent/'web'/name).read_bytes(),media=media)
            if self.command=='POST' and path=='/api/v1/session/bootstrap':
                data=self.body()
                with self.server.auth_lock:
                    require(self.server.bootstrap_token and time.monotonic()<self.server.bootstrap_deadline and
                            hmac.compare_digest(str(data.get('token','')),self.server.bootstrap_token),
                            'SESSION_REQUIRED','Startlink ist abgelaufen oder bereits verwendet.',status=401)
                    self.server.bootstrap_token='';token=secrets.token_urlsafe(32);csrf=secrets.token_urlsafe(32)
                    self.server.sessions[token]={'csrf':csrf,'expires':time.monotonic()+12*3600}
                return self.respond(200,{'csrf':csrf},headers={'Set-Cookie':'editor_session='+token+'; HttpOnly; SameSite=Strict; Path=/'})
            session=self.session()
            if self.command=='GET' and path=='/api/v1/session':return self.respond(200,{'csrf':session['csrf']})
            key=None;data={}
            if self.command=='POST':
                require(hmac.compare_digest(self.headers.get('X-CSRF-Token',''),session['csrf']),'CSRF_REJECTED','Sitzungsschutz fehlt.',status=403)
                key=self.headers.get('Idempotency-Key')
                require(key is not None and 8<=len(key)<=100,'REQUEST_KEY_REQUIRED','Anfragereferenz fehlt.',status=400)
                data=self.body()
                request_hash=hashlib.sha256(repr((path,data)).encode()).hexdigest();cache_key=session['csrf'],key
                with self.server.service.store.mutex:
                    cached=self.server.requests.get(cache_key)
                    if cached:
                        require(cached[0]==request_hash,'REQUEST_KEY_REUSED','Anfragereferenz mit anderem Inhalt.',status=409)
                        return self.respond(cached[1],cached[2],headers=cached[3])
                    result,status,headers=self.route(path,query,data)
                    self.server.requests[cache_key]=(request_hash,status,result,headers)
                    if len(self.server.requests)>1000:self.server.requests.pop(next(iter(self.server.requests)))
            else:result,status,headers=self.route(path,query,data)
            self.respond(status,result,headers=headers)
        except AuthoringError as e:self.respond(e.status,e.finding())
        except (KeyError,ValueError,TypeError,StopIteration) as e:
            self.respond(422,{'code':'FIELD_INVALID','message':'Ungültige oder fehlende Angabe: '+str(e)[:300]})
        except (BrokenPipeError,ConnectionResetError,TimeoutError):pass
        except Exception:
            self.respond(500,{'code':'LOCAL_SERVICE_ERROR','message':'Lokaler Vorgang fehlgeschlagen. Entwurf bleibt gespeichert.'})

    def route(self,path,query,data):
        service=self.server.service;store=service.store;get=self.command=='GET';etag=self.headers.get('If-Match')
        parts=[unquote(p) for p in path.removeprefix('/api/v1/').split('/')]
        require(path.startswith('/api/v1/'),'NOT_FOUND','Route nicht gefunden.',status=404)
        def draft_response(draft):return draft,200,{'ETag':store.etag(draft)}
        if parts==['publisher'] and get:return service.publisher.status(),200,{}
        if len(parts)==2 and parts[0]=='publisher' and not get:
            if parts[1]=='otp':return service.publisher.request_otp(data['email']),200,{}
            if parts[1]=='verify':return service.publisher.verify_otp(data['email'],data['code']),200,{}
            if parts[1]=='logout':return service.publisher.sign_out(),200,{}
        if len(parts)==4 and parts[0]=='releases' and parts[2]=='publish' and not get:
            return service.publish_release(parts[1],parts[3]),202,{}
        if parts==['workspace-view']:return service.workspace_view(None if get else data.get('selection',{})),200,{}
        if parts==['languages']:return (service.languages() if get else service.create_language(data)),200,{}
        if parts==['catalog'] and get:return service.catalog(query['lang'],draft_id=query.get('draft_id'),query=query.get('q',''),deck=query.get('deck'),cursor=query.get('cursor',0),limit=query.get('limit',50),status=query.get('status','active')),200,{}
        if parts==['drafts']:
            return (store.drafts(),200,{}) if get else draft_response(service.new_draft(data['lang'],data.get('deck_ref')))
        if parts==['releases'] and get:return store.list('releases'),200,{}
        if parts==['authoring-contexts'] and not get:return service.template(data['lang'],data['requested_count'],data.get('topic','')),200,{}
        if parts==['imports'] and not get:return service.preview_upload(data['file']['raw'],data['file']['filename'],data['lang'],data.get('source')),202,{}
        if len(parts)==2 and parts[0]=='imports' and get:return store.get('imports',parts[1]),200,{}
        if len(parts)==3 and parts[0]=='imports' and parts[2]=='accept' and not get:return service.accept_import(parts[1],data['preview_sha256'],draft_id=data.get('draft_id'),etag=etag),200,{}
        if len(parts)>=2 and parts[0]=='drafts':
            identifier=parts[1]
            if len(parts)==2 and get:return draft_response(store.load_draft(identifier))
            action=parts[2]
            if get:
                if action=='target':return service.target(identifier,query['ref']),200,{}
                if action=='story-contexts':return service.story_contexts(identifier),200,{}
                if action=='story-target':return service.story_target(identifier,query['ref']),200,{}
                if action=='vocabulary':return service.vocabulary(identifier,query['surface']),200,{}
                if action=='diff':
                    draft=store.load_draft(identifier)
                    return {'operations':draft['operations'],'added_counts':{t:len(r) for t,r in draft['add'].items()},'content_sha256':draft_content_hash(draft)},200,{}
                if action=='impact':
                    draft=store.load_draft(identifier);base=service.base(draft['lang'],draft['base'])
                    return (retirement_impact(base,query['ref']) if query['kind']=='retire' else shared_gloss_impact(base,query['table'],query['ref'])),200,{}
            else:
                if action=='story-history':return service.prepare_story_history(identifier,etag),202,{}
                if action=='rebase':return draft_response(service.rebase(identifier,etag))
                if action=='operations':return draft_response(service.save_operations(identifier,data['operations'],etag))
                if action=='target':return draft_response(service.update_target(identifier,data['ref'],data,etag))
                if action=='tokenize':return service.tokenize(identifier,data,etag),200,{}
                if action=='validate':return service.validate(identifier,etag),202,{}
                if action=='reviews':return draft_response(service.review(identifier,data,etag))
                if action=='exchange':return service.exchange(identifier,data['format'],etag),200,{}
                if action=='discard':return draft_response(service.discard(identifier,etag))
                if action=='releases':return service.release(identifier,data,etag),202,{}
        if len(parts)>=2 and parts[0]=='jobs':
            if len(parts)==2 and get:return store.get('jobs',parts[1]),200,{}
            if len(parts)==3 and parts[2]=='cancel' and not get:return service.jobs.cancel(parts[1]),200,{}
        if len(parts)==3 and parts[0]=='releases':
            if parts[2]=='staging-impact' and get:return service.staging_impact(parts[1]),200,{}
            if parts[2]=='stage' and not get:return service.stage(parts[1],data['impact_sha256']),202,{}
        if len(parts)==2 and parts[0]=='artifacts' and get:
            file,metadata=store.artifact_path(parts[1])
            # ASCII safe attachment label, with no user-controlled header text.
            filename=''.join(c for c in metadata['filename'] if c.isascii() and (c.isalnum() or c in '._-')) or 'export.bin'
            return file.read_bytes(),200,{'Content-Disposition':'attachment; filename="'+filename+'"','Content-Type':metadata['media_type']}
        raise AuthoringError('NOT_FOUND','Route nicht gefunden.',status=404)
