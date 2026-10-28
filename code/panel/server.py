"""Local, credential-free control plane. The permanent hub is never writable here."""
import argparse, datetime as dt, hashlib, http.server, json, os, pathlib, re
import secrets, subprocess, threading, time, urllib.parse
HERE = pathlib.Path(__file__).resolve().parent
ALLOWED = {'jev-chat-monitor', 'jev-chat-analyze', 'arena-dsh-web', 'arena-desktop-pet'}
NOTION = 'https://app.notion.com/p/407186af12d381cf97eeebf4ec37f0c9'
SECRET = re.compile(r'(?:\b(?:ntn_|secret_|ghp_|github_pat_|sk-)[\w-]{12,}|-----BEGIN .*PRIVATE KEY|(?:password|token|api_key)\s*[:=]\s*\S+)', re.I)
def read_json(path, default=None):
    try:
        if path.stat().st_size > 2_000_000: return default
        return json.loads(path.read_text(encoding='utf-8-sig'))
    except (OSError, ValueError): return default

def stamp(): return dt.datetime.now(dt.timezone.utc).isoformat()
def redact(text): return SECRET.sub('[REDACTED]', str(text))

def receipt_status(r):
    if not r: return 'no_receipt'
    if r.get('tasks_all_ok') is False: return 'failed'
    if r.get('tasks_all_ok') is True: return 'completed'
    return 'unknown'

class Store:
    def __init__(self, data, results, hub, demo=False):
        self.data, self.results, self.hub, self.demo = data, results, hub, demo
        data.mkdir(parents=True, exist_ok=True)
        self.lock=threading.RLock(); self.tasks=[]; self.sampled=None; self.error='Waiting for first sample'
    def audit(self, event):
        with self.lock, (self.data/'audit.jsonl').open('a',encoding='utf-8') as f:
            f.write(json.dumps({'at':stamp(),**event},ensure_ascii=False)+'\n')
    def sessions(self):
        notes=read_json(self.data/'sessions.json',{}) or {}; rows=[]
        if self.results.exists():
            for folder in self.results.iterdir():
                if not folder.is_dir() or folder.is_symlink(): continue
                r=read_json(folder/'status/hub_sync_receipt.json',{}) or {}
                manifest=read_json(folder/'status/session_manifest.json',{}) or {}
                note=notes.get(folder.name,{})
                # Only specific metadata, never stdout, command lines or chat logs.
                prompt=note.get('prompt') or manifest.get('user_prompt') or ''
                rows.append(dict(id=folder.name,repo=r.get('repo',''),branch=r.get('branch',''),
                    host=r.get('host',''),at=r.get('synced_at_utc',''),status=receipt_status(r),
                    source=r.get('source_commit',''),result_dir=str(folder),
                    sync_mode='results + deliverable' if r else 'unverified',
                    steps=[{'name':x.get('step',''), 'exit':x.get('exit_code'), 'elapsed':x.get('elapsed_ms')} for x in r.get('tasks_executed',[]) if isinstance(x,dict)],
                    title=note.get('title') or manifest.get('title') or folder.name,
                    prompt=redact(str(prompt)[:12000]),prompt_source='manual' if note.get('prompt') else 'manifest' if prompt else 'unrecorded'))
        return sorted(rows,key=lambda r:r['at'],reverse=True)
    def record(self, payload):
        sid=payload.get('id',''); title=payload.get('title',''); prompt=payload.get('prompt','')
        if not all(isinstance(x,str) for x in (sid,title,prompt)): raise ValueError('Text fields required')
        if sid not in {s['id'] for s in self.sessions()}: raise ValueError('Unknown session')
        if len(prompt)>12000 or len(title)>160: raise ValueError('Text too long')
        if SECRET.search(prompt): raise ValueError('Possible credential detected; remove secrets before saving')
        with self.lock:
            path=self.data/'sessions.json'; notes=read_json(path,{}) or {}
            # Keep edit history locally without publishing it.
            if sid in notes:
                with (self.data/'prompt-history.jsonl').open('a',encoding='utf-8') as f: f.write(json.dumps({'id':sid,**notes[sid]},ensure_ascii=False)+'\n')
            notes[sid]={'title':title,'prompt':prompt,'saved_at':stamp()}
            tmp=path.with_suffix('.tmp');tmp.write_text(json.dumps(notes,ensure_ascii=False,indent=2),encoding='utf-8');tmp.replace(path)
            self.audit({'event':'prompt_saved','session':sid})
        return {'ok':True}
    def control(self, name, action):
        if name not in ALLOWED or action not in {'start','stop','hide','show','open'}: raise ValueError('Protected or unknown action')
        if action=='open' and name!='arena-dsh-web': raise ValueError('Only DSH can be opened')
        if action in {'hide','show'} and name!='arena-desktop-pet': raise ValueError('Only desktop pet can be hidden')
        if self.demo or os.name!='nt': raise ValueError('Preview is read-only; no Windows task changes')
        with self.lock:
            r=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(HERE/'control.ps1'),'-Action',action,'-Name',name],capture_output=True,timeout=35,creationflags=0x08000000)
            self.audit({'event':'control','name':name,'action':action,'exit':r.returncode})
        if r.returncode: raise ValueError(redact(r.stderr.decode('utf-8','replace'))[:600])
        return {'ok':True,'note':'Command completed; wait for refreshed scheduler state'}
    def poll(self):
        while True:
            try:
                if os.name=='nt' and not self.demo:
                    r=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(HERE/'control.ps1'),'-Action','snapshot'],capture_output=True,timeout=20,creationflags=0x08000000)
                    if r.returncode: raise ValueError('Windows scheduler query failed')
                    rows=json.loads(r.stdout.decode('utf-8-sig'))
                    self.tasks=rows if isinstance(rows,list) else [rows];self.error=''
                else: self.error='Read-only preview: Windows scheduler is not available here'
                self.sampled=stamp()
            except Exception as e: self.error=str(e)
            time.sleep(10)
    def snapshot(self):
        hub=read_json(self.hub/'hub-state.json',{}) or {}
        age=None
        try: age=max(0,round(time.time()-dt.datetime.fromisoformat(hub['updated_at'].replace('Z','+00:00')).timestamp()))
        except (ValueError,KeyError): pass
        sessions=self.sessions()
        installs=(read_json(HERE/'software-registry.json',[]) or []) + (read_json(self.data/'install-state.json',[]) or [])
        latest={}
        for item in installs:
            if isinstance(item,dict) and item.get('name') not in {'installer','dsh-help','dsh-plugin-help'}: latest[item.get('name','')]=item
        return {'at':stamp(),'demo':self.demo,'notion':NOTION,'hub':hub,'heartbeat_age':age,
                'tasks':self.tasks,'tasks_sampled':self.sampled,'tasks_error':self.error,
                'sessions':sessions,'software':list(latest.values()),
                'sync':{'policy':'results + deliverable; runtime code exists only for execution',
                        'notion':'on-demand snapshots, not continuous synchronization'},
                'notion_snapshot':read_json(HERE/'notion-links.json',{})}

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def host_ok(self):
        host=self.headers.get('Host','')
        return host in self.server.hosts or (self.server.store.demo and re.fullmatch(r"[a-zA-Z0-9-]+\.e2b\.app", host) is not None)
    def send(self, code, data, kind='application/json; charset=utf-8'):
        body=json.dumps(data,ensure_ascii=False).encode() if isinstance(data,(dict,list)) else data
        self.send_response(code);self.send_header('Content-Type',kind);self.send_header('Content-Length',str(len(body)))
        self.send_header('Cache-Control','no-store');self.send_header('X-Content-Type-Options','nosniff')
        self.send_header('Referrer-Policy','no-referrer')
        self.send_header('Content-Security-Policy',"default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'self' https://*.arena.ai https://arena.ai https://*.e2b.app")
        self.end_headers();self.wfile.write(body)
    def do_GET(self):
        if not self.host_ok(): return self.send(403,{'error':'Host rejected'})
        route=urllib.parse.urlsplit(self.path).path
        if route=='/api/state': return self.send(200,self.server.store.snapshot())
        if route=='/api/bootstrap': return self.send(200,{'csrf':self.server.csrf,'readonly':self.server.store.demo})
        files={'/':'index.html','/app.js':'app.js','/style.css':'style.css'}
        if route in files:
            mime={'/':'text/html; charset=utf-8','/app.js':'text/javascript; charset=utf-8','/style.css':'text/css; charset=utf-8'}
            return self.send(200,(HERE/files[route]).read_bytes(),mime[route])
        return self.send(404,{'error':'Not found'})
    def do_POST(self):
        if not self.host_ok(): return self.send(403,{'error':'Host rejected'})
        # Strict same-origin + non-simple custom header; no permissive CORS.
        origin=self.headers.get('Origin','')
        if origin not in self.server.origins or not secrets.compare_digest(self.headers.get('X-CSRF-Token',''),self.server.csrf):
            return self.send(403,{'error':'Origin/CSRF rejected'})
        if self.server.store.demo: return self.send(403,{'error':'Read-only preview'})
        try:
            n=int(self.headers.get('Content-Length','0'))
            if n<=0 or n>65536: raise ValueError('Invalid body length')
            if self.headers.get_content_type()!='application/json': raise ValueError('JSON required')
            data=json.loads(self.rfile.read(n))
            if not isinstance(data,dict): raise ValueError('Object required')
            if self.path=='/api/session': result=self.server.store.record(data)
            elif self.path=='/api/control': result=self.server.store.control(data.get('name'),data.get('action'))
            else: return self.send(404,{'error':'Not found'})
            self.send(200,result)
        except (ValueError,TypeError,subprocess.TimeoutExpired) as e: self.send(400,{'error':str(e)})
        except Exception: self.send(500,{'error':'Operation failed; see local diagnostics'})

def make_server(bind,port,store,extra_hosts=()):
    s=http.server.ThreadingHTTPServer((bind,port),Handler)
    s.store=store;s.csrf=secrets.token_urlsafe(32)
    p=s.server_port;s.hosts={f'127.0.0.1:{p}',f'localhost:{p}',*extra_hosts}
    s.origins={f'{scheme}://{h}' for h in s.hosts for scheme in ('http','https')}
    return s

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--bind',default='127.0.0.1');ap.add_argument('--port',type=int,default=18765)
    ap.add_argument('--data',default=str(HERE/'data'));ap.add_argument('--results',default='E:/0github/results')
    ap.add_argument('--hub',default=str(pathlib.Path.home()/'.git-sync-hub'));ap.add_argument('--demo',action='store_true');ap.add_argument('--allow-host',action='append',default=[])
    a=ap.parse_args()
    if not a.demo and a.bind not in ('127.0.0.1','localhost'): raise SystemExit('Writable control plane must remain loopback-only')
    store=Store(pathlib.Path(a.data),pathlib.Path(a.results),pathlib.Path(a.hub),a.demo)
    server=make_server(a.bind,a.port,store,a.allow_host)
    threading.Thread(target=store.poll,daemon=True).start()
    print('Arena Desk listening on %s:%s (%s)'%(a.bind,a.port,'read-only' if a.demo else 'local control'),flush=True)
    server.serve_forever()
if __name__=='__main__': main()
