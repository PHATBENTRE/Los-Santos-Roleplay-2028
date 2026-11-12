'use strict';
document.addEventListener('contextmenu',event=>event.preventDefault(),true);
document.addEventListener('auxclick',event=>{ if(event.button===2) event.preventDefault(); },true);
const $ = id => document.getElementById(id);
const definitions = {
  1: {name:'Nước uống',image:'items/water_bottle.png',max:10,description:'Một chai nước sạch. Dùng để hồi 5 máu.'},
  2: {name:'Đồ ăn nhẹ',image:'items/sandwich.png',max:8,description:'Một phần ăn nhẹ. Dùng để hồi 5 máu.'},
  3: {name:'Băng cứu thương',image:'items/bandage.png',max:5,description:'Băng cứu thương. Dùng để hồi 25 máu.'},
  4: {name:'Súng 9mm',image:'items/pistol_fivem.png',fallback:'items/pistol.svg',max:1,weapon:22,description:'Súng ngắn. Nạp bằng đạn pistol.'},
  5: {name:'Desert Eagle',image:'items/deagle_fivem.png',fallback:'items/deagle.svg',max:1,weapon:24,description:'Súng ngắn cỡ lớn. Nạp bằng đạn pistol.'},
  6: {name:'Shotgun',image:'items/shotgun_fivem.png',fallback:'items/shotgun.svg',max:1,weapon:25,description:'Súng bơm. Nạp bằng đạn shotgun.'},
  7: {name:'M4',image:'items/rifle_fivem.png',fallback:'items/rifle.svg',max:1,weapon:31,description:'Súng trường. Nạp bằng đạn rifle.'},
  8: {name:'Đạn pistol',image:'items/pistol_ammo.png',max:60,ammo:true,description:'Đạn dành cho súng 9mm và Desert Eagle.'},
  9: {name:'Đạn shotgun',image:'items/shotgun_ammo.png',max:30,ammo:true,description:'Đạn dành cho Shotgun.'},
  10: {name:'Đạn rifle',image:'items/rifle_ammo.png',max:90,ammo:true,description:'Đạn dành cho M4.'},
  11: {name:'Đạn SMG',image:'items/smg_ammo.png',max:90,ammo:true,description:'Đạn dành cho MP5.'},
  12: {name:'MP5',image:'items/smg_fivem.png',fallback:'items/smg.svg',max:1,weapon:29,description:'Súng tiểu liên. Nạp bằng đạn SMG.'}
};
const weaponNames = {
  22:'9mm', 23:'9mm giảm thanh', 24:'Deagle',
  25:'Shotgun', 26:'Sawn-off', 27:'SPAS-12',
  28:'Uzi', 29:'MP5', 32:'TEC-9',
  30:'AK-47', 31:'M4', 33:'Rifle', 34:'Sniper',
  35:'RPG', 36:'RPG khóa', 37:'Phun lửa', 38:'Minigun'
};
const SLOT_COUNT=50;
const ammoForWeapon={4:8,5:8,6:9,7:10,12:11};
const magazineSize={4:17,5:7,6:8,7:30,12:30};
let items = Array(SLOT_COUNT).fill(null), nearby = Array(SLOT_COUNT).fill(null), selected = -1, selectedSide = 0, lastHash = '';
let dragSource = null;
let dragGhost = null;
let dragFrame = 0, dragX = 0, dragY = 0;
let firstFrameSent = false;
let moveSource = null;
const slotNodes = [[], []];
function send(event, ...args) { if (window.cef && typeof window.cef.emit === 'function') window.cef.emit(event, ...args); }
function setItemImage(image, def) {
  image.onerror=def.fallback ? () => { image.onerror=null; image.src=def.fallback; } : null;
  image.src=def.image;
}
function traceId(id) { return String(1000000000000000 + id); }
function close() { send('inventory:close'); }
function moveGhost(event) {
  if (!dragSource) return;
  dragX=event.clientX; dragY=event.clientY;
  if (!dragGhost) {
    if (Math.abs(dragX-dragSource.x)<6 && Math.abs(dragY-dragSource.y)<6) return;
    const item=(dragSource.side ? nearby : items)[dragSource.slot];
    if (!item) return;
    dragGhost=document.createElement('div'); dragGhost.className='drag-ghost';
    const image=document.createElement('img'); setItemImage(image,definitions[item.type]); image.alt='';
    dragGhost.append(image); document.body.append(dragGhost);
  }
  if (dragFrame) return;
  if (typeof requestAnimationFrame === 'function')
    dragFrame=requestAnimationFrame(()=>{ dragFrame=0; if (dragGhost) dragGhost.style.transform=`translate3d(${dragX-42}px,${dragY-42}px,0)`; });
  else dragGhost.style.transform=`translate3d(${dragX-42}px,${dragY-42}px,0)`;
}
function clearGhost() {
  if (dragFrame && typeof cancelAnimationFrame === 'function') cancelAnimationFrame(dragFrame);
  dragFrame=0;
  if (dragGhost) dragGhost.remove();
  dragGhost=null;
}
function bindDrag(button, side, slot, hasItem) {
  button.dataset.side=String(side); button.dataset.slot=String(slot);
  button.onpointerdown=hasItem ? event=>{ clearGhost(); dragSource={side,slot,x:event.clientX,y:event.clientY}; } : null;
}
document.addEventListener('pointermove',moveGhost);
document.addEventListener('pointerup', event => {
  if (!dragSource || !dragGhost || typeof document.elementFromPoint !== 'function') { dragSource=null; clearGhost(); return; }
  const target=document.elementFromPoint(event.clientX,event.clientY)?.closest?.('.slot');
  const equipment=document.elementFromPoint(event.clientX,event.clientY)?.closest?.('.equipment-slot');
  const dragged=items[dragSource.slot];
  if (dragSource.fromEquipment && target && target.dataset.side==='0') {
    send('inventory:use',dragSource.slot);
  } else if (equipment && dragSource.side===0 && dragged) {
    const weaponSlot=Number(equipment.dataset.weaponSlot);
    if (defWeaponSlot(dragged.type)===weaponSlot && !dragged.equipped) send('inventory:use',dragSource.slot);
    else if (dragged.type>=8 && dragged.type<=11) send('inventory:reload_target',dragSource.slot,weaponSlot);
  } else if (target && target.dataset && target.dataset.side !== undefined) {
    const toSide=Number(target.dataset.side), toSlot=Number(target.dataset.slot);
    if (toSide!==dragSource.side || toSlot!==dragSource.slot)
      send('inventory:drag',dragSource.side,dragSource.slot,toSide,toSlot);
  }
  dragSource=null; clearGhost();
});
function defWeaponSlot(type) { return type===4||type===5 ? 2 : type===6 ? 3 : type===12 ? 4 : type===7 ? 5 : 0; }
document.addEventListener('pointercancel',()=>{dragSource=null;clearGhost();});
function hideMenu() { $('item-menu').hidden=true; $('detail').hidden=true; moveSource=null; selected=-1; render(); }
function selectSlot(slot,side) {
  if (moveSource) {
    if (moveSource.side!==side || moveSource.slot!==slot)
      send('inventory:drag',moveSource.side,moveSource.slot,side,slot);
    hideMenu(); return;
  }
  showDetail(slot,side);
}
function showDetail(slot, side = 0) {
  const item=(side ? nearby : items)[slot];
  if (!item) { hideMenu(); return; }
  selected=slot; selectedSide=side;
  const def=definitions[item.type], menu=$('item-menu'), detail=$('detail');
  menu.hidden=false; detail.hidden=true;
  setItemImage($('menu-image'),def);
  $('menu-title').textContent=def.name;
  const spare=def.weapon ? items.reduce((total,entry)=>total+(entry?.type===ammoForWeapon[item.type]?entry.quantity:0),0) : 0;
  $('menu-quantity').textContent=def.weapon ? `${item.ammo}/${magazineSize[item.type]} đạn · ${definitions[ammoForWeapon[item.type]].name} trong túi: ${spare}` : `×${item.quantity} / ${def.max}`;
  $('menu-use').hidden=!!side;
  $('menu-use').textContent=def.weapon ? (item.equipped?'Tháo súng':'Trang bị') : (def.ammo?'Nạp đạn':'Sử dụng');
  $('menu-use').onclick=()=>{ send('inventory:use',slot); hideMenu(); };
  $('menu-reload').hidden=!!side || !def.weapon || !item.equipped;
  $('menu-reload').textContent=def.weapon ? `Nạp ${definitions[ammoForWeapon[item.type]].name}` : 'Nạp đạn';
  $('menu-reload').onclick=()=>{ send('inventory:reload',slot); hideMenu(); };
  $('menu-transfer').textContent='Vứt bỏ';
  $('menu-transfer').hidden=!!item.equipped;
  $('menu-transfer').onclick=()=>{ send('inventory:discard',slot); hideMenu(); };
  $('menu-reorder').onclick=()=>{ moveSource={side,slot}; menu.hidden=true; render(); };
  $('menu-info').onclick=()=>{ detail.textContent=`${def.description} · ${def.weapon ? `Đạn: ${item.ammo}` : `Số lượng ${item.quantity}/${def.max}`} · ID #${traceId(item.id)}`; detail.hidden=!detail.hidden; };
  render();
}
function updateSlot(button, item, side, slot) {
  const key=item ? `${item.id}.${item.type}.${item.quantity}.${item.ammo}.${item.equipped}` : '';
  button.onclick=item || moveSource ? ()=>selectSlot(slot,side) : null;
  if (button.dataset.itemKey===key) return;
  button.dataset.itemKey=key;
  button.replaceChildren();
  button.title='';
  button.setAttribute('aria-label',item ? `${definitions[item.type].name}, số lượng ${item.quantity}` : 'Ô trống');
  bindDrag(button,side,slot,!!item);
  button.ondblclick=null;
  if (!item) return;
  const def=definitions[item.type];
  const image=document.createElement('img'); image.className='item-image'; setItemImage(image,def); image.alt=''; image.draggable=false;
  const quantity=document.createElement('span'); quantity.className='quantity'; quantity.textContent=`×${item.quantity}`;
  button.title=def.name;
  if (def.weapon) quantity.textContent=`${item.ammo} đạn`;
  if (item.equipped && def.weapon) {
    const label=document.createElement('span'); label.className='equipped-placeholder'; label.textContent='Ở ô trang bị';
    button.append(label,quantity);
  } else button.append(image,quantity);
  if (item.equipped) { const badge=document.createElement('span'); badge.className='equipped-badge'; badge.textContent='ĐANG DÙNG'; button.append(badge); }
}
function render() {
  for (let side=0;side<1;side++) {
    const list=side ? nearby : items, grid=$(side ? 'ground-slots' : 'slots');
    let count=0;
    list.forEach((item,slot)=>{
      if (item) count++;
      let button=slotNodes[side][slot];
      if (!button) {
        button=document.createElement('button'); button.type='button'; button.className='slot empty';
        slotNodes[side][slot]=button; grid.append(button);
      }
      const classes='slot'+(item?'':' empty')+(item?.equipped?' equipped':'')+(selectedSide===side&&selected===slot?' selected':'');
      if (button.className!==classes) button.className=classes;
      updateSlot(button,item,side,slot);
    });
    $(side ? 'ground-count' : 'count').textContent=`${count} / ${SLOT_COUNT} Ô`;
  }
}
function snapshot() {
  if (!location.hash || location.hash===lastHash) return;
  const data=new URLSearchParams(location.hash.slice(1)); if (!data.has('character')) return;
  lastHash=location.hash; $('character').textContent=(data.get('character')||'Nhân vật').replace(/_/g,' ');
  const money=value=>`$${Math.trunc(Number(value)||0).toLocaleString('en-US')}`;
  $('cash').textContent=money(data.get('cash'));
  $('bank').textContent=money(data.get('bank'));
  const skin=Number(data.get('skin'));
  if (Number.isInteger(skin) && skin>=0 && skin<=311 && skin!==74) {
    $('character-skin').src=`skins/${skin}.png`;
    $('equip-skin-image').src=`skins/${skin}.png`;
    $('equip-skin-name').textContent=`#${skin}`;
    $('skin-label').textContent=`Skin #${skin}`;
  }
  items=Array(SLOT_COUNT).fill(null);
  nearby=Array(SLOT_COUNT).fill(null);
  for(let i=0;i<SLOT_COUNT;i++) {
    const match=/^(\d+)\.(\d{1,2})\.(\d+)(?:\.(\d+)\.([01]))?$/.exec(data.get(`s${i}`)||'');
    if(match && definitions[Number(match[2])]) items[i]={id:Number(match[1]),type:Number(match[2]),quantity:Number(match[3]),ammo:Number(match[4]||0),equipped:match[5]==='1'};
  }
  for (let slot=2;slot<=7;slot++) {
    const match=/^(\d{1,2})\.(\d{1,9})$/.exec(data.get(`w${slot}`)||'');
    const weapon=match ? Number(match[1]) : 0;
    const ammo=match ? Number(match[2]) : 0;
    const equipped=items.find(item=>item?.equipped && definitions[item.type].weapon===weapon && defWeaponSlot(item.type)===slot);
    const tile=$(`weapon-${slot}`);
    tile.dataset.weaponSlot=String(slot);
    tile.className=equipped || weapon ? 'equipment-slot equipped' : 'equipment-slot';
    $(`weapon-${slot}-name`).textContent=equipped ? definitions[equipped.type].name : weapon ? (weaponNames[weapon]||`Vũ khí #${weapon}`) : 'Trống';
    $(`weapon-${slot}-ammo`).textContent=equipped || weapon ? `${ammo} đạn` : '';
    let icon=tile._weaponIcon;
    if (!icon && equipped) { icon=document.createElement('img'); icon.className='weapon-icon'; icon.alt=''; tile.append(icon); tile._weaponIcon=icon; }
    if (icon) { icon.hidden=!equipped; if (equipped) setItemImage(icon,definitions[equipped.type]); }
    tile.onclick=equipped ? ()=>showDetail(items.indexOf(equipped),0) : null;
    tile.onpointerdown=equipped ? event=>{
      clearGhost();
      dragSource={side:0,slot:items.indexOf(equipped),x:event.clientX,y:event.clientY,fromEquipment:true};
    } : null;
  }
  if (selected>=0 && !(selectedSide ? nearby : items)[selected]) hideMenu();
  else if (selected>=0 && !$('item-menu').hidden) showDetail(selected,selectedSide);
  else render();
  if (!firstFrameSent) {
    firstFrameSent = true;
    if (typeof requestAnimationFrame === 'function') requestAnimationFrame(()=>send('inventory:painted'));
    else send('inventory:painted');
  }
}
$('close').onclick=close;
$('menu-close').onclick=hideMenu;
function onEscape(event) {
  if (event.key !== 'Escape' && event.key !== 'Esc' && event.code !== 'Escape' && event.keyCode !== 27) return;
  event.preventDefault(); close();
}
document.addEventListener('keydown',onEscape,true);
window.addEventListener('keyup',onEscape,true);
function listenForEscape() {
  const bridge=window.cef;
  const on=bridge && (bridge.on || bridge.subscribe);
  if (!on) return false;
  on.call(bridge,'cef:escape_menu',visible=>{ if (visible) close(); });
  return true;
}
if (!listenForEscape() && typeof setInterval === 'function') {
  let attempts=0;
  const retry=setInterval(()=>{ if (listenForEscape() || ++attempts>=15) clearInterval(retry); },1000);
}
window.addEventListener('hashchange',snapshot);snapshot();render();if(!location.hash) send('inventory:ready');
