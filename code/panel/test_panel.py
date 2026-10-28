import http.client, json, pathlib, tempfile, threading, unittest
from server import Store, make_server, receipt_status
class PanelTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.root=pathlib.Path(self.tmp.name)
  self.results=self.root/'results';p=self.results/'sample/status';p.mkdir(parents=True)
  (p/'hub_sync_receipt.json').write_text(json.dumps({'repo':'demo','branch':'arena/test','tasks_all_ok':True,'tasks_executed':[{'step':'check','exit_code':0,'stdout':'SECRET_NOT_TO_EXPOSE'}]}))
  self.s=Store(self.root/'data',self.results,self.root/'hub')
 def tearDown(self): self.tmp.cleanup()
 def test_receipt_is_not_running(self):
  self.assertEqual(receipt_status({'tasks_all_ok':True}),'completed');self.assertEqual(receipt_status({}),'no_receipt')
 def test_discovers_and_hides_raw_output(self):
  data=self.s.snapshot();self.assertEqual(len(data['sessions']),1);self.assertNotIn('SECRET_NOT_TO_EXPOSE',json.dumps(data));self.assertEqual(data['sessions'][0]['prompt_source'],'unrecorded')
 def test_prompt_persists_and_unknown_id_rejected(self):
  self.s.record({'id':'sample','title':'测试','prompt':'记录任务结果'});self.assertEqual(self.s.sessions()[0]['prompt'],'记录任务结果')
  with self.assertRaises(ValueError):self.s.record({'id':'../escape','prompt':'x'})
 def test_protects_hub_and_arbitrary_command(self):
  for name in ['git-sync-hub','arena-desk-panel','x;shutdown','../something']:
   with self.assertRaises(ValueError):self.s.control(name,'stop')
 def test_secret_block(self):
  with self.assertRaises(ValueError):self.s.record({'id':'sample','title':'x','prompt':'token=private-test-secret'})
 def test_corrupt_json(self):
  (self.results/'sample/status/hub_sync_receipt.json').write_text('{bad');self.assertEqual(self.s.sessions()[0]['status'],'no_receipt')
 def test_manifest(self):
  (self.results/'sample/status/session_manifest.json').write_text('{"user_prompt":"hello"}');self.assertEqual(self.s.sessions()[0]['prompt_source'],'manifest')
 def test_http_security(self):
  server=make_server('127.0.0.1',0,self.s);threading.Thread(target=server.serve_forever,daemon=True).start()
  def req(path,method='GET',headers=None,body=None):
   c=http.client.HTTPConnection('127.0.0.1',server.server_port);c.request(method,path,body=body,headers=headers or {});r=c.getresponse();data=r.read();c.close();return r.status,data
  try:
   self.assertEqual(req('/api/state')[0],200)
   self.assertEqual(req('/api/state',headers={'Host':'evil.example'})[0],403)
   self.assertEqual(req('/../../server.py')[0],404)
   self.assertEqual(req('/api/control','POST',body='{}')[0],403)
   headers={'Origin':f'http://127.0.0.1:{server.server_port}','X-CSRF-Token':server.csrf,'Content-Type':'application/json'}
   self.assertEqual(req('/api/control','POST',headers,json.dumps({'name':'git-sync-hub','action':'stop'}))[0],400)
   self.assertEqual(req('/api/session','POST',headers,json.dumps({'id':'sample','title':'ok','prompt':'user task'}))[0],200)
   self.s.demo=True
   self.assertEqual(req('/api/session','POST',headers,json.dumps({'id':'sample','title':'bad','prompt':'ignored'}))[0],403)
  finally:server.shutdown();server.server_close()
if __name__=='__main__':unittest.main()
