"""Resume a truncated GitHub release; size and published SHA are both required."""
import hashlib,json,os,pathlib,re,shutil,time,urllib.request,zipfile
ROOT=pathlib.Path('E:/0apps/DSHPet'); STATE=pathlib.Path('E:/0apps/ArenaDesk/data/install-state.json')
URL='https://github.com/MerZlin/dsh-pet-indesktop/releases/download/v4.4.0/dsh-pet-standalone-webm-portable.zip'
SIZE=348968895; SHA='fa049e31f1b0d184f77639a749f239b55b48c64b2ba14b59d08b3897168b55aa'
def record(status,detail,**extra):
 rows=json.loads(STATE.read_text(encoding='utf-8'));rows.append(dict(name='desktop-pet',status=status,detail=detail,at=time.strftime('%Y-%m-%d %H:%M:%S'),**extra))
 tmp=STATE.with_suffix('.tmp');tmp.write_text(json.dumps(rows,ensure_ascii=True,indent=2),encoding='utf-8');tmp.replace(STATE)
def main():
 archive=ROOT/'pet-v4.4.0.zip'
 try:
  for attempt in range(12):
   size=archive.stat().st_size if archive.exists() else 0
   if size==SIZE:break
   if size>SIZE:raise ValueError('File larger than published size')
   record('downloading','Resuming verified release: %d / %d bytes'%(size,SIZE))
   req=urllib.request.Request(URL,headers={'Range':'bytes=%d-'%size,'User-Agent':'ArenaDesk/1.0'})
   with urllib.request.urlopen(req,timeout=60) as src:
    cr=src.headers.get('Content-Range','')
    if src.status==206:
     m=re.fullmatch(r'bytes (\d+)-(\d+)/(\d+)',cr)
     if not m or int(m[1])!=size or int(m[3])!=SIZE:raise ValueError('Unexpected Content-Range: '+cr)
     mode='ab'
    elif src.status==200:mode='wb'
    else:raise ValueError('Unexpected HTTP status')
    with archive.open(mode) as dst:
     for chunk in iter(lambda:src.read(1024*1024),b''):dst.write(chunk)
   if archive.stat().st_size<=size:raise ValueError('No download progress; server did not resume')
  if archive.stat().st_size!=SIZE:raise ValueError('Incomplete release: %d / %d'%(archive.stat().st_size,SIZE))
  h=hashlib.sha256()
  with archive.open('rb') as f:
   for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
  if h.hexdigest()!=SHA:raise ValueError('SHA256 still mismatched; refusing to run')
  with zipfile.ZipFile(archive) as z:
   for name in z.namelist():
    if not (ROOT/name).resolve().is_relative_to(ROOT.resolve()):raise ValueError('Unsafe archive path')
   z.extractall(ROOT)
  exes=list(ROOT.rglob('dsh-pet-standalone-webm.exe'))
  if not exes:raise ValueError('No expected executable')
  record('installed','Size and SHA-256 verified; non-chat portable version',exe=str(exes[0]),sha256=SHA)
 except Exception as e:record('failed',str(e))
if __name__=='__main__':main()
