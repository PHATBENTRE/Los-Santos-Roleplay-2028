// No packages required: exercise the real browser script against the CEF/DOM boundary.
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
class Element {
  constructor() { this.children=[]; this.value=''; this.hidden=false; this.disabled=false; this.textContent=''; this.classes=new Set(); this.classList={add:(name)=>this.classes.add(name),remove:(name)=>this.classes.delete(name),toggle:(name,on)=>on?this.classes.add(name):this.classes.delete(name)}; }
  append(...nodes) { for (const node of nodes) { node.parent=this; node.isConnected=true; this.children.push(node); } }
  appendChild(node) { this.append(node); }
  remove() { if (this.parent) this.parent.children=this.parent.children.filter(node=>node!==this); this.isConnected=false; }
  removeAttribute(name) { delete this[name]; }
  focus() {}
}
const elements = new Map();
const events = new Map();
const emitted=[];
const browserEvents = new Map();
const timers = new Map();
let timerId = 0;
const context = {
  performance: {now:()=>0},
  requestAnimationFrame(fn) { context.frame = fn; (context.frames ||= []).push(fn); },
  document: {getElementById(id) { if(!elements.has(id)) elements.set(id,new Element()); return elements.get(id); }, createElement() {return new Element();}},
  window: {location:{hash:''},addEventListener:(name,fn)=>browserEvents.set(name,fn),cef:{on:(name,fn)=>events.set(name,fn),emit:(...args)=>emitted.push(args)}},
  URLSearchParams,
  setTimeout(fn) { timers.set(++timerId,fn); return timerId; },
  clearTimeout(id) { timers.delete(id); },
  setInterval(fn) { timers.set(++timerId,fn); return timerId; },
  clearInterval(id) { timers.delete(id); }
};
const html = readFileSync(join(__dirname,'../scriptfiles/cef/lsrp/index.html'),'utf8');
const app = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const {createHash} = require('node:crypto');
assert.ok(html.includes(`'sha256-${createHash('sha256').update(app).digest('base64')}'`),'embedded app matches CSP');
assert.ok(html.includes('src="logo.png"'));
assert.ok(!html.includes('OOC'),'no OOC label remains in the page');
vm.runInNewContext(app,context);
const get=id=>elements.get(id);
assert.equal(emitted[0][0],'lsrp:ready');
events.get('lsrp:screen')(1,'');
assert.equal(get('value').type,'text');
get('value').value='Test_User';
get('form').onsubmit({preventDefault(){}});
assert.deepEqual(emitted.at(-1),['lsrp:submit','Test_User']);
const count=emitted.length;
get('form').onsubmit({preventDefault(){}});
assert.equal(emitted.length,count,'duplicate submissions blocked while pending');
events.get('lsrp:screen')(3,'Test_User');
assert.equal(get('value').type,'password');
get('value').value='test-secret';
get('form').onsubmit({preventDefault(){}});
assert.equal(get('value').value,'','password removed after submission');
events.get('lsrp:error')('Wrong password');
assert.equal(get('submit').disabled,false);
assert.equal(get('error').textContent,'Wrong password');
events.get('lsrp:screen')(4,'Test_User');
assert.equal(get('auth').hidden,true);
assert.equal(get('characters').hidden,false);
events.get('lsrp:character')(0,'<img onerror=alert(1)>',3,26,true,true);
assert.equal(get('slots').children[0].children[2].textContent,'<img onerror=alert(1)>','names rendered as text');
assert.equal(get('play').disabled,false);
get('slots').children[1].onclick();
assert.deepEqual(emitted.at(-1),['lsrp:slot',1]);
events.get('lsrp:character')(1,'',0,0,false,true);
assert.equal(get('play').disabled,true);
get('classic').onclick();
assert.equal(emitted.at(-1)[0],'lsrp:classic');
console.log('PASS: ready, auth, duplicate submit, password clearing, errors, slots, safe text, fallback');
events.get('lsrp:screen')(['3','Test_User']);
assert.equal(get('value').type,'password','array-wrapped string stage accepted');
assert.equal(get('auth-step').textContent,'02 / 02','password stage advances the step label');
events.get('lsrp:screen')(1,'');
assert.equal(get('auth-step').textContent,'01 / 02','username stage resets the step label');
get('value').value='bad name';
const invalidCount=emitted.length;
get('form').onsubmit({preventDefault(){}});
assert.equal(emitted.length,invalidCount,'invalid username shows a local error without a silent submit');
assert.match(get('error').textContent,/3–24/);
console.log('PASS: embedded script/CSP, logo, array-shaped bridge payload, visible input validation');

// Regression: no Pawn -> JS events arrive at all, but server LoadUrl works.
context.window.location.hash='#ui=1&stage=1&rev=1&username=&selected=0&error=0';
browserEvents.get('hashchange')();
get('value').value='Transport_Test';
get('form').onsubmit({preventDefault(){}});
assert.deepEqual(emitted.at(-1),['lsrp:submit','Transport_Test'],'navigation acknowledges readiness without any CEF screen event');
context.window.location.hash='#ui=1&stage=3&rev=2&username=Transport_Test&selected=0&error=0';
browserEvents.get('hashchange')();
assert.equal(get('value').type,'password');
assert.equal(get('submit').disabled,false);
context.window.location.hash='#ui=1&stage=3&rev=3&username=Transport_Test&selected=0&error=2';
browserEvents.get('hashchange')();
assert.match(get('error').textContent,/chưa đúng/);
context.window.location.hash='#ui=1&stage=4&rev=4&username=Transport_Test&selected=1&error=0&n0=Test_Character&l0=2&k0=26&e0=1';
browserEvents.get('hashchange')();
assert.equal(get('characters').hidden,false);
assert.equal(get('slots').children[0].children[2].textContent,'Test Character');
assert.equal(get('play').disabled,false);
const titleBefore=get('title').textContent;
events.get('lsrp:screen')(1,'Old_State');
assert.equal(get('title').textContent,titleBefore,'late event cannot override navigation state');
console.log('PASS: navigation-only ready, submit, login, wrong-password and character slots with server events missing');

// omp-cef v1.4.0 prepends playerid AND browserid before registered event args.
// Check the Pawn boundary too: a browser-only mock cannot catch an ABI mismatch.
const pawn = readFileSync(join(__dirname,'../gamemodes/modules/core/player/cef/core.pwn'),'utf8');
let checked = 0;
for (const registration of pawn.matchAll(/CEF_RegisterEvent\("([^"]+)",\s*"([^"]+)"([^;]*)\);/g)) {
  const [, event, callback, args] = registration;
  const declaration = pawn.match(new RegExp(`public ${callback}\\(([^)]*)\\)`));
  assert.ok(declaration, `${event}: callback exists`);
  const params = declaration[1].split(',').map(x=>x.trim());
  assert.deepEqual(params.slice(0,2), ['playerid','browserid'], `${event}: omp-cef implicit arguments`);
  assert.equal(params.length, 2 + (args.match(/Argument_/g)||[]).length, `${event}: typed argument count`);
  checked++;
}
assert.equal(checked,8);
console.log('PASS: all eight Pawn event callbacks match the omp-cef playerid/browserid ABI');

context.window.location.hash='#ui=1&stage=6&rev=20&cbusy=0&error=0';
browserEvents.get('hashchange')();
get('creator-form').checkValidity=()=>true;
['creator-name','creator-birthdate','creator-gender','creator-tone','creator-voice','creator-height','creator-weight','creator-birthplace'].forEach(id=>context.document.getElementById(id));
for (const [id,value] of Object.entries({'creator-name':'Michael_Johnson','creator-birthdate':'2000-02-29','creator-gender':'1','creator-tone':'2','creator-voice':'3','creator-height':'180','creator-weight':'75','creator-birthplace':'2'})) get(id).value=value;
get('creator-form').onsubmit({preventDefault(){}});
assert.deepEqual(emitted.at(-1),['lsrp:creator_confirm','Michael_Johnson',1,29,2,2000,2,3,180,75,2]);
const submitted=emitted.length;
get('creator-form').onsubmit({preventDefault(){}});
assert.equal(emitted.length,submitted,'duplicate creator submit blocked');
events.get('lsrp:notify')('success','Saved');
const toast=get('notifications').children.at(-1);
toast.isConnected=true;
const progress=toast.children[2];
context.frame(2100);
assert.equal(progress.value,.5,'notification at half duration has half remaining');
toast.classList.add=()=>{};
context.frame(4200);
assert.equal(progress.value,0,'notification expires only after countdown reaches zero');
console.log('PASS: creator profile ABI, duplicate prevention, timed notification progress');
for (const [id,fn] of [...timers]) { fn(); timers.delete(id); }
context.frames=[];
for (const item of [...get('notifications').children]) item.remove();
for (let i=0;i<5;i++) events.get('lsrp:notify')('info',`Message ${i}`);
assert.equal(get('notifications').children.length,3,'only three notifications are visible at once');
assert.deepEqual(get('notifications').children.map(item=>item.children[1].children[1].textContent),
  ['Message 0','Message 1','Message 2']);
const beforeExpiry=new Set(timers.keys());
for (const frame of context.frames.splice(0)) frame(4200);
for (const [id,fn] of [...timers]) if (!beforeExpiry.has(id)) { fn(); timers.delete(id); }
assert.deepEqual(get('notifications').children.map(item=>item.children[1].children[1].textContent),
  ['Message 3','Message 4'],'queued notifications appear after earlier ones expire');
context.window.location.hash='#ui=1&stage=0&rev=21&username=&selected=0&error=0';
browserEvents.get('hashchange')();
const beforeDrain=new Set(timers.keys());
for (const frame of context.frames.splice(0)) frame(4200);
for (const [id,fn] of [...timers]) if (!beforeDrain.has(id)) { fn(); timers.delete(id); }
assert.equal(emitted.at(-1)[0],'lsrp:notify_drained','closed CEF is hidden only after the queue drains');
console.log('PASS: notification queue preserves messages without filling the screen');
