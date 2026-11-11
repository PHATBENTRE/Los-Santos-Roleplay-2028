'use strict';
const $ = (id) => document.getElementById(id);
let bridge;
let attached = false;
let acknowledged = false;
let responseTimer;
let stage = 0;
let pending = false;
const slots = [];
let navigationState = false;
let lastSnapshot = '';

function character(index, name, level, skin, exists, selected) {
  const slot = slots[index];
  if (!slot) return;
  slot.name.textContent = exists ? name.replace(/_/g, ' ') : '+ Tạo nhân vật mới';
  slot.info.textContent = exists ? `Cấp ${level} · Ngoại hình #${skin}` : 'Một câu chuyện mới đang chờ';
  slot.button.classList.toggle('selected', !!selected);
  if (selected) $('play').disabled = !exists;
}

function applySnapshot() {
  const hash = window.location.hash;
  if (!hash || hash === lastSnapshot) return false;
  const data = new URLSearchParams(hash.slice(1));
  if (data.get('ui') !== '1' || !/^[0-5]$/.test(data.get('stage') || '')) return false;
  lastSnapshot = hash;
  navigationState = true;
  acknowledged = true;
  const next = Number(data.get('stage'));
  if (document.body && document.body.classList && typeof document.body.classList.add === 'function') document.body.classList.add('booted');
  screen(next, data.get('username') || '');
  if (next === 4) {
    for (let i = 0; i < 3; i++) character(i, data.get(`n${i}`) || '',
      Number(data.get(`l${i}`)), Number(data.get(`k${i}`)), data.get(`e${i}`) === '1',
      Number(data.get('selected')) === i + 1);
  }
  const errors = {
    1: 'Tên đăng nhập gồm 3–24 ký tự: chữ, số hoặc dấu gạch dưới (_). Mật khẩu đăng ký cần ít nhất 6 ký tự.',
    2: 'Mật khẩu chưa đúng. Vui lòng thử lại.',
    3: 'Mật khẩu tối đa 72 ký tự.'
  };
  if (errors[data.get('error')]) { busy(false); $('error').textContent = errors[data.get('error')]; }
  return true;
}
function emit(name, ...args) {
  try {
    if (!bridge || typeof bridge.emit !== 'function') throw new Error('CEF unavailable');
    bridge.emit(name, ...args);
    return true;
  } catch (_) {
    busy(false);
    $('error').textContent = 'Chưa kết nối được giao diện với máy chủ. Thử kết nối lại hoặc dùng /classicui.';
    return false;
  }
}
function busy(value) {
  pending = value;
  $('submit').disabled = value;
  $('back').disabled = value;
}
function screen(next, username) {
  clearTimeout(responseTimer);
  const auth = $('auth');
  const characters = $('characters');
  stage = Number(next);
  next = stage;
  busy(next === 5);
  const showCharacters = next === 4;
  if (next === 0) {
    [auth, characters].forEach((view) => {
      if (view.hidden) return;
      if (!view.classList) { view.hidden = true; return; }
      view.classList.remove('view-enter');
      view.classList.add('view-exit');
      setTimeout(() => { view.hidden = true; view.classList.remove('view-exit'); }, 380);
    });
    return;
  }
  auth.hidden = next === 0 || showCharacters;
  characters.hidden = !showCharacters;
  const activeView = showCharacters ? characters : auth;
  if (next !== 0) {
    if (activeView.classList && typeof activeView.classList.remove === 'function') {
      activeView.classList.remove('view-enter');
      void activeView.offsetWidth;
      activeView.classList.add('view-enter');
    }
  }
  if (next === 4) $('play').disabled = true;
  $('error').textContent = '';
  if (next === 5) {
    $('description').textContent = 'Đang xử lý, vui lòng chờ…';
    return;
  }
  const password = next === 2 || next === 3;
  $('title').textContent = next === 2 ? 'Tạo tài khoản' : next === 3 ? 'Đăng nhập' : 'Đăng nhập máy chủ';
  $('description').textContent = password ? `Tên đăng nhập: ${username}` : 'Nhập tên đăng nhập để tiếp tục.';
  $('label').textContent = password ? 'Mật khẩu' : 'Tên đăng nhập';
  const input = $('value');
  input.value = '';
  input.type = password ? 'password' : 'text';
  input.minLength = password ? (next === 2 ? 6 : 1) : 3;
  input.maxLength = password ? 72 : 24;
  input.placeholder = password ? 'Nhập mật khẩu' : 'Nhập tên đăng nhập';
  if (password) input.removeAttribute('pattern');
  else input.pattern = '[A-Za-z0-9_]{3,24}';
  $('submit').textContent = next === 2 ? 'Đăng ký →' : next === 3 ? 'Đăng nhập →' : 'Tiếp tục →';
  $('back').hidden = !password;
  if (next !== 4 && next !== 0) input.focus();
}
for (let i = 0; i < 3; i++) {
  const button = document.createElement('button');
  button.className = 'slot';
  const label = document.createElement('small');
  label.textContent = `NHÂN VẬT 0${i + 1}`;
  const name = document.createElement('strong');
  const info = document.createElement('em');
  button.append(label, name, info);
  button.onclick = () => { if (!pending) emit('lsrp:slot', i); };
  $('slots').append(button);
  slots.push({button, name, info});
}
$('form').onsubmit = (event) => {
  event.preventDefault();
  if (pending || ![1, 2, 3].includes(stage)) return;
  const value = $('value').value;
  if (stage === 1 && !/^[A-Za-z0-9_]{3,24}$/.test(value)) {
    $('error').textContent = 'Tên đăng nhập gồm 3–24 ký tự: chữ, số hoặc dấu gạch dưới (_).';
    return;
  }
  if ((stage === 2 && value.length < 6) || (stage === 3 && !value) || value.length > 72) {
    $('error').textContent = 'Kiểm tra mật khẩu: đăng ký cần 6–72 ký tự.';
    return;
  }
  if (!acknowledged) {
    $('error').textContent = 'Đang kết nối với máy chủ. Vui lòng chờ hoặc dùng /classicui.';
    emit('lsrp:ready');
    return;
  }
  busy(true);
  $('error').textContent = 'Đang gửi yêu cầu…';
  if (emit('lsrp:submit', value)) {
    responseTimer = setTimeout(() => {
      busy(false);
      $('error').textContent = 'Máy chủ chưa phản hồi. Hãy kết nối lại hoặc dùng /classicui.';
    }, 10000);
  }
  if (stage !== 1) $('value').value = '';
};
$('back').onclick = () => emit('lsrp:back');
$('classic').onclick = () => emit('lsrp:classic');
$('play').onclick = () => emit('lsrp:play');
function listen(name, handler) {
  const on = typeof bridge.on === 'function' ? bridge.on : bridge.subscribe;
  on.call(bridge, name, (...args) => {
    // Some WebView bridges deliver one argument array instead of a spread list.
    if (args.length === 1 && Array.isArray(args[0])) args = args[0];
    handler(...args);
  });
}
function attach() {
  bridge = window.cef;
  if (!bridge || typeof bridge.emit !== 'function' ||
      (typeof bridge.on !== 'function' && typeof bridge.subscribe !== 'function')) return false;
  if (attached) return true;
  listen('lsrp:screen', (next, username) => { if (!navigationState) { acknowledged = true; screen(next, username); } });
  listen('lsrp:character', (...args) => { if (!navigationState) character(...args); });
  listen('lsrp:error', (message) => { clearTimeout(responseTimer); busy(false); $('error').textContent = message; });
  attached = true;
  emit('lsrp:ready');
  return true;
}
screen(1, '');
busy(true);
$('error').textContent = 'Đang kết nối với máy chủ…';
window.addEventListener('hashchange', applySnapshot);
applySnapshot();
try { attach(); } catch (_) { $('error').textContent = 'Không khởi tạo được CEF. Hãy dùng /classicui.'; }
setTimeout(() => { if (document.body && document.body.classList && typeof document.body.classList.add === 'function') document.body.classList.add('booted'); }, 140);
let attempts = 0;
const retry = setInterval(() => {
  attempts++;
  try {
    if (!acknowledged && attach()) emit('lsrp:ready');
  } catch (_) { /* Show a useful status after the bounded retry period. */ }
  if (acknowledged || attempts >= 15) {
    clearInterval(retry);
    if (!acknowledged) {
      busy(false);
      $('error').textContent = 'CEF chưa nhận phản hồi máy chủ. Hãy dùng /classicui hoặc kết nối lại.';
    }
  }
}, 1000);
