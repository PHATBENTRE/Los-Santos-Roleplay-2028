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
let lastToastRevision = 0;

function character(index, name, level, skin, exists, selected) {
  const slot = slots[index];
  if (!slot) return;
  slot.name.textContent = exists ? name.replace(/_/g, ' ') : '+ Tạo nhân vật mới';
  slot.info.textContent = exists ? `Cấp ${level} · Tiếp tục câu chuyện` : 'Bắt đầu một cuộc đời mới';
  slot.button.classList.toggle('empty', !exists);
  slot.button.classList.toggle('selected', !!selected);
  if (selected) $('play').disabled = !exists;
}

function applySnapshot() {
  const hash = window.location.hash;
  if (!hash || hash === lastSnapshot) return false;
  const data = new URLSearchParams(hash.slice(1));
  if (data.get('ui') !== '1' || !/^[0-6]$/.test(data.get('stage') || '')) return false;
  lastSnapshot = hash;
  navigationState = true;
  acknowledged = true;
  const next = Number(data.get('stage'));
  if (document.body && document.body.classList && typeof document.body.classList.add === 'function') document.body.classList.add('booted');
  screen(next, data.get('username') || '');
  const toastRevision = Number(data.get('toast') || 0);
  if (toastRevision > lastToastRevision) {
    lastToastRevision = toastRevision;
    notify('success', 'Đã tạo nhân vật thành công.');
  }
  if (next === 6) {
    clearTimeout(window.creatorSaveTimer);
    setCreatorBusy(data.get('cbusy') === '1');
    if (data.get('cactive') === '1' && data.get('cname')) $('creator-name').value = data.get('cname');
  }
  if (next === 4) {
    for (let i = 0; i < 3; i++) character(i, data.get(`n${i}`) || '',
      Number(data.get(`l${i}`)), Number(data.get(`k${i}`)), data.get(`e${i}`) === '1',
      Number(data.get('selected')) === i + 1);
  }
  const errors = {
    1: 'Tên đăng nhập gồm 3–24 ký tự: chữ, số hoặc dấu gạch dưới (_). Mật khẩu đăng ký cần ít nhất 6 ký tự.',
    2: 'Mật khẩu chưa đúng. Vui lòng thử lại.',
    3: 'Mật khẩu tối đa 72 ký tự.',
    4: 'Tên nhân vật hoặc ô nhân vật đã được sử dụng.',
    5: 'Tên nhân vật phải có dạng Tên_Họ, mỗi phần ít nhất 2 chữ cái.',
    6: 'Ngày sinh không hợp lệ. Hãy kiểm tra lại ngày, tháng và năm.',
    7: 'Kiểm tra chiều cao (150–210 cm), cân nặng (45–150 kg) và các lựa chọn.',
    8: 'Chưa thể xác nhận lưu. Hãy kết nối lại để kiểm tra nhân vật trước khi thử tiếp.',
    9: 'Ô nhân vật không còn hợp lệ. Hãy mở lại màn chọn nhân vật.'
  };
  if (errors[data.get('error')]) {
    busy(false);
    const message = errors[data.get('error')];
    $(next === 6 ? 'creator-error' : 'error').textContent = message;
    notify('error', message);
  }
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
const notificationQueue = [];
function showQueuedNotifications() {
  const host = $('notifications');
  if (!host) return;
  while (host.children.length < 3 && notificationQueue.length) {
  const { type, message } = notificationQueue.shift();
  const item = document.createElement('div');
  const kind = type || 'info';
  const meta = { info: ['i', 'THÔNG TIN'], success: ['✓', 'THÀNH CÔNG'], warning: ['!', 'CẢNH BÁO'], error: ['×', 'LỖI'] }[kind] || ['i', 'THÔNG TIN'];
  item.className = `notify notify-${kind}`;
  const icon = document.createElement('span'); icon.className = 'notify-icon'; icon.textContent = meta[0];
  const content = document.createElement('span'); content.className = 'notify-content';
  const title = document.createElement('strong'); title.textContent = meta[1];
  const text = document.createElement('span'); text.textContent = message || '';
  const badge = document.createElement('span'); badge.className = 'notify-badge'; badge.textContent = 'SERVER';
  const bar = document.createElement('progress');
  bar.className = 'notify-bar';
  bar.max = 1; bar.value = 1;
  content.append(title, text); item.append(icon, content, bar, badge);
  host.appendChild(item);
  const start = performance.now();
  function tick(now) {
    if (!item.isConnected) return;
    bar.value = Math.max(0, 1 - (now - start) / 4200);
    if (bar.value > 0) requestAnimationFrame(tick);
    else { item.classList.add('notify-leave'); setTimeout(() => {
      item.remove();
      showQueuedNotifications();
      if (!host.children.length && !notificationQueue.length && stage === 0) emit('lsrp:notify_drained');
    }, 180); }
  }
  requestAnimationFrame(tick);
  }
}
function notify(type, message) {
  notificationQueue.push({ type, message });
  showQueuedNotifications();
  if (type === 'info' && String(message).includes('kiểm tra tên')) setCreatorBusy(false);
  if (type === 'info' && String(message).includes('kiểm tra tên')) clearTimeout(window.creatorSaveTimer);
  if (type === 'info' && String(message).includes('hoàn tất hồ sơ')) {
    clearTimeout(window.creatorSaveTimer);
    setCreatorBusy(false);
  }
  if (type === 'info' && String(message).includes('lưu hồ sơ')) setCreatorBusy(true);
  if ((type === 'error' || type === 'warning' || type === 'success') && window.creatorBusy) {
    clearTimeout(window.creatorSaveTimer);
    setCreatorBusy(false);
  }
}
function setCreatorBusy(value) {
  window.creatorBusy = !!value;
  const creator = $('creator');
  if (!creator || typeof creator.querySelectorAll !== 'function') return;
  creator.querySelectorAll('input,select,button').forEach((control) => { control.disabled = !!value; });
  const confirm = $('creator-confirm');
  if (confirm) confirm.textContent = value ? 'Đang lưu…' : 'Xác nhận nhân vật →';
}
function busy(value) {
  pending = value;
  $('submit').disabled = value;
  $('back').disabled = value;
}
function screen(next, username) {
  const changed = stage !== Number(next);
  clearTimeout(responseTimer);
  const auth = $('auth');
  const characters = $('characters');
  stage = Number(next);
  next = stage;
  busy(next === 5);
  const showCharacters = next === 4;
  const showCreator = next === 6;
  const creator = $('creator');
  if (creator) creator.hidden = !showCreator;
  ['site-header', 'site-intro', 'site-footer'].forEach((id) => {
    const part = $(id);
    if (part) part.hidden = showCreator || showCharacters;
  });
  if (document.body && document.body.classList && typeof document.body.classList.toggle === 'function') {
    document.body.classList.toggle('creator-mode', showCreator);
    document.body.classList.toggle('selector-mode', showCharacters);
  }
  if (next === 0) {
    clearTimeout(window.creatorSaveTimer);
    setCreatorBusy(false);
    if (document.body) document.body.classList.add('closed');
    ['auth','characters','creator','site-header','site-intro','site-footer','classic'].forEach(id => { if ($(id)) $(id).hidden = true; });
    return;
    [auth, characters].forEach((view) => {
      if (view.hidden) return;
      if (!view.classList) { view.hidden = true; return; }
      view.classList.remove('view-enter');
      view.classList.add('view-exit');
      setTimeout(() => { view.hidden = true; view.classList.remove('view-exit'); }, 380);
    });
    return;
  }
  auth.hidden = next === 0 || showCharacters || showCreator;
  characters.hidden = !showCharacters;
  const activeView = showCreator ? creator : showCharacters ? characters : auth;
  if (document.body) document.body.classList.remove('closed');
  if (next !== 0 && changed) {
    if (activeView.classList && typeof activeView.classList.remove === 'function') {
      activeView.classList.remove('view-enter');
      void activeView.offsetWidth;
      activeView.classList.add('view-enter');
    }
  }
  if (next === 4) $('play').disabled = true;
  if (next === 4 || next === 6) return;
  $('error').textContent = '';
  if (next === 5) {
    $('description').textContent = 'Đang xử lý, vui lòng chờ…';
    return;
  }
  const password = next === 2 || next === 3;
  $('auth-step').textContent = password ? '02 / 02' : '01 / 02';
  $('auth-eyebrow').textContent = next === 2 ? 'TẠO TÀI KHOẢN' : next === 3 ? 'CHÀO MỪNG TRỞ LẠI' : 'BẮT ĐẦU CÂU CHUYỆN';
  if ($('toggle-password')) $('toggle-password').hidden = !password;
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
  if (changed && !window.matchMedia?.('(pointer: coarse)').matches) input.focus();
}
for (let i = 0; i < 3; i++) {
  const button = document.createElement('button');
  button.className = 'slot';
  const label = document.createElement('small');
  label.textContent = `NHÂN VẬT 0${i + 1}`;
  const name = document.createElement('strong');
  const info = document.createElement('em');
  const symbol = document.createElement('span'); symbol.className = 'slot-symbol'; symbol.textContent = `0${i + 1}`;
  button.append(label, symbol, name, info);
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
if ($('toggle-password')) $('toggle-password').onclick = () => {
  const show = $('value').type === 'password';
  $('value').type = show ? 'text' : 'password';
  $('toggle-password').textContent = show ? 'Ẩn' : 'Hiện';
};
if ($('creator-form')) $('creator-form').onsubmit = (event) => {
  event.preventDefault();
  if ($('creator-confirm').disabled) return;
  const name = $('creator-name') ? $('creator-name').value.trim() : '';
  if (!/^[A-Za-z]{2,}_[A-Za-z]{2,}$/.test(name) || name.length > 24) { notify('warning', 'Tên nhân vật phải có dạng Tên_Họ, mỗi phần ít nhất 2 chữ cái.'); return; }
  const [year, month, day] = $('creator-birthdate').value.split('-').map(Number);
  if (!year || !month || !day || !$('creator-form').checkValidity()) { notify('warning', 'Hãy kiểm tra ngày sinh, chiều cao và cân nặng.'); return; }
  const numeric = id => Number($(id).value);
  setCreatorBusy(true);
  $('creator-error').textContent = '';
  const confirm = $('creator-confirm');
  confirm.disabled = true;
  confirm.textContent = 'Đang kiểm tra…';
  window.creatorSaveTimer = setTimeout(() => {
    if (confirm.disabled) {
      setCreatorBusy(false);
      notify('error', 'Máy chủ chưa phản hồi việc lưu nhân vật. Bạn có thể thử lại.');
    }
  }, 15000);
  if (!emit('lsrp:creator_confirm', name, numeric('creator-gender'), day, month, year, numeric('creator-tone'), numeric('creator-voice'), numeric('creator-height'), numeric('creator-weight'), numeric('creator-birthplace'))) setCreatorBusy(false);
};
if ($('creator') && typeof $('creator').querySelectorAll === 'function') $('creator').querySelectorAll('select').forEach((select) => {
  select.addEventListener('change', () => {
    const skin = $('creator').querySelectorAll('select')[3];
    const gender = $('creator').querySelectorAll('select')[0];
    if ($('skin-preview')) $('skin-preview').textContent = `${skin.value} · ${gender.value}`;
  });
});
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
  listen('lsrp:notify', (type, message) => notify(type, message));
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
