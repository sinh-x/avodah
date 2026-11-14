// Private disposable Chrome profile + exact fixture certificate SPKI only.
// stdout is a private parent-process pipe; the parent never logs credentials.
import {spawn} from 'node:child_process';
import {readFile, mkdir} from 'node:fs/promises';
import {join} from 'node:path';
const [origin, codeFile, profile, spki] = process.argv.slice(2);
if (!/^https:\/\/localhost:\d+$/.test(origin) || !codeFile.includes('avo121-qualification-')) throw Error('fixture paths only');
await mkdir(profile, {recursive:true, mode:0o700});
const chrome = spawn(process.env.CHROME_EXECUTABLE || 'google-chrome', [
  '--headless=new','--no-sandbox','--disable-dev-shm-usage','--disable-gpu',
  '--enable-unsafe-swiftshader','--remote-debugging-port=0','--remote-debugging-address=127.0.0.1',
  `--user-data-dir=${profile}`,`--ignore-certificate-errors-spki-list=${spki}`,
  '--no-first-run','--no-default-browser-check',
  '--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost', 'about:blank',
], {stdio:['ignore','ignore','pipe']});
let ws;
try {
  const address = await new Promise((resolve,reject) => {
    let text=''; const timer=setTimeout(()=>reject(Error('Chrome startup timeout')),15000);
    chrome.stderr.on('data', b => { text+=b; const m=text.match(/DevTools listening on (ws:\/\/[^\s]+)/); if(m){clearTimeout(timer);resolve(m[1]);} });
    chrome.once('exit',()=>reject(Error('Chrome exited')));
  });
  ws = new WebSocket(address);
  await new Promise((resolve,reject)=>{ws.onopen=resolve;ws.onerror=reject;});
  let seq=0; const pending=new Map();
  ws.onmessage=({data})=>{const message=JSON.parse(data); if(message.id){const p=pending.get(message.id);if(p){pending.delete(message.id);clearTimeout(p.timer);message.error?p.reject(Error('CDP command failed')):p.resolve(message.result);}}};
  const send=(method,params={},sessionId)=>new Promise((resolve,reject)=>{
    const id=++seq; const timer=setTimeout(()=>{pending.delete(id);reject(Error(`CDP timeout ${method}`));},15000);
    pending.set(id,{resolve,reject,timer});ws.send(JSON.stringify({id,method,params,...(sessionId?{sessionId}:{})}));
  });
  const {targetId}=await send('Target.createTarget',{url:'about:blank'});
  const {sessionId}=await send('Target.attachToTarget',{targetId,flatten:true});
  await send('Page.enable',{},sessionId);await send('Runtime.enable',{},sessionId);
  const evaluate=async expression=>{
    const r=await send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true},sessionId);
    if(r.exceptionDetails)throw Error('Browser fixture evaluation failed');
    return r.result.value;
  };
  const wait=async(predicate,description,timeout=45000)=>{
    const start=Date.now();while(Date.now()-start<timeout){try{const value=await predicate();if(value)return value;}catch{}await new Promise(r=>setTimeout(r,200));}throw Error(description);
  };
  const click=async label=>{
    const rect=await wait(()=>evaluate(`(()=>{const e=[...document.querySelectorAll('[role="button"],button,[aria-label]')].find(e=>(e.getAttribute('aria-label')||e.textContent||'').includes(${JSON.stringify(label)}));if(!e)return null;const r=e.getBoundingClientRect();return r.width&&r.height?{x:r.x+r.width/2,y:r.y+r.height/2}:null;})()`),`Control unavailable: ${label}`);
    await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...rect},sessionId);
    await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...rect},sessionId);
  };
  await send('Page.navigate',{url:`${origin}/avodah/`},sessionId);
  await wait(()=>evaluate(`!!document.querySelector('flt-semantics-placeholder')`),'Flutter did not initialize');
  await evaluate(`document.querySelector('flt-semantics-placeholder').click()`);
  await wait(()=>evaluate(`!!document.querySelector('[aria-label*="Six-digit pairing code"]')`),'Pairing code field unavailable');
  await click('Six-digit pairing code');
  const code=await wait(async()=>{try{const value=(await readFile(codeFile,'utf8')).trim();return /^\d{6}$/.test(value)?value:null;}catch{return null;}},'Private fixture code unavailable');
  await send('Input.insertText',{text:code},sessionId);
  await click('Confirm & Pair');
  const credentials=await wait(()=>evaluate(`(()=>{const token=localStorage.getItem('avodah.pair.${origin}/avodah.token');const entry=Object.entries(localStorage).find(([k])=>k.includes('crdt_node_id:')&&k.includes('${origin}'));if(!token||!entry)return null;let node=entry[1];try{node=JSON.parse(node)}catch{}return {token,node};})()`),'Browser did not persist pairing');
  await send('Page.reload',{ignoreCache:true},sessionId);
  await wait(()=>evaluate(`localStorage.getItem('avodah.pair.${origin}/avodah.token')===${JSON.stringify(credentials.token)}`),'Credential did not survive reload');
  const result=await evaluate(`fetch('${origin}/avodah/api/config/categories',{headers:{'X-Av-Node-Id':${JSON.stringify(credentials.node)},'X-Av-Pair-Token':${JSON.stringify(credentials.token)}}}).then(async r=>({status:r.status,secure:isSecureContext,isolated:crossOriginIsolated}))`);
  if(result.status!==200||!result.secure||!result.isolated)throw Error('Authenticated HTTPS/isolation check failed');
  // Output only into the Python parent's PIPE, never a test log/artifact.
  process.stdout.write(JSON.stringify({credentials,result,version:(await send('Browser.getVersion')).product}));
} finally {
  ws?.close();chrome.kill('SIGTERM');
}
