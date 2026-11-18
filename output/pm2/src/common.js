/* ===== KTS 원클릭 공통 도우미(화면·숫자·날짜·AI 열쇠·60초 문의) — 앱마다 같은 내용 ===== */
const $ = s => document.querySelector(s), $$ = s => [...document.querySelectorAll(s)];
let tT; function toast(m){ const e = $('#toast'); e.textContent = m; e.classList.add('on'); clearTimeout(tT); tT = setTimeout(() => e.classList.remove('on'), 2600); }
const escH = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const busyOn = t => { $('#busyT').textContent = t; $('#busy').classList.add('on'); };
const busyOff = () => $('#busy').classList.remove('on');
/* 한글 금액 */
function korNum(n){
  n = Math.floor(+n || 0); if (!n) return '영';
  const D = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'], U = ['', '십', '백', '천'], B = ['', '만', '억', '조'];
  let out = '', g = 0;
  while (n > 0){
    const part = n % 10000; n = Math.floor(n / 10000);
    if (part){ let s = ''; const ds = String(part).padStart(4, '0');
      for (let i = 0; i < 4; i++){ const d = +ds[i]; if (d) s += D[d] + U[3 - i]; }
      out = s + B[g] + out; }
    g++;
  }
  return out;
}
const comma = n => (Math.round(+n) || 0).toLocaleString('ko-KR');
const num = v => +String(v == null ? '' : v).replace(/[^\d]/g, '') || 0;
const wonBoth = n => `금 ${comma(n)}원(금 ${korNum(n)} 원)`;
/* 날짜 */
const WK = ['일', '월', '화', '수', '목', '금', '토'];
const ymd = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const parseD = s => { const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || ''); return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null; };
const korD = d => d ? `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일` : '';
const korDW = d => d ? `${korD(d)}(${WK[d.getDay()]})` : '';
const addDays = (d, n) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
const todayS = () => ymd(new Date());
/* 복사(클립보드 → 안 되면 선택 복사) */
async function copyText(t){
  try{ await navigator.clipboard.writeText(t); return true; }catch(e){}
  try{ const a = document.createElement('textarea'); a.value = t; a.style.position = 'fixed'; a.style.opacity = '0'; document.body.appendChild(a); a.select(); const ok = document.execCommand('copy'); a.remove(); return ok; }catch(e){ return false; }
}
function downloadBlob(b, nm){ const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = nm; document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1500); }

/* ---------- AI (손님 자기 제미나이 무료 열쇠 · 그 기기에만 보관) ---------- */
function myKey(){ let k = ''; try{ k = localStorage.getItem('kts_ai_key') || ''; }catch(e){}
  if (!k && window.KTS_FREE && window.KTS_FREE.p && window.KTS_FREE.p.length) k = window.KTS_FREE.p.join('');
  return (k && !/^__/.test(k)) ? k : ''; }
function updKey(){ const b = $('#keyBtn'); if (b) b.textContent = 'AI 열쇠 · ' + (myKey() ? '있음' : '없음'); }
function parseJ(txt){
  let t = String(txt || '').trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
  try{ return JSON.parse(t); }catch(e){}
  const a = t.indexOf('{'), b = t.lastIndexOf('}');
  if (a >= 0 && b > a){ try{ return JSON.parse(t.slice(a, b + 1)); }catch(e){} }
  return null;
}
async function askAI(prompt, b64){
  const key = myKey(); if (!key) throw new Error('NO_KEY');
  const cfg = window.KTS_AI || {}, models = cfg.models || ['gemini-flash-lite-latest'];
  const ep = cfg.endpoint || 'https://generativelanguage.googleapis.com/v1beta/models/';
  const parts = [{text:prompt}]; if (b64) parts.push({inline_data:{mime_type:'image/jpeg', data:b64}});
  let last = null;
  for (const m of models){
    try{
      const r = await fetch(ep + m + ':generateContent?key=' + encodeURIComponent(key), {method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({contents:[{parts}], generationConfig:{responseMimeType:'application/json', temperature:0}})});
      if (!r.ok){ last = new Error(r.status === 429 ? 'QUOTA' : 'AI ' + r.status); continue; }
      const j = await r.json(); const t = (((j.candidates || [])[0] || {}).content || {}).parts?.[0]?.text || '';
      const o = parseJ(t); if (o) return o; last = new Error('AI 응답을 읽지 못했습니다');
    }catch(e){ last = e; }
  }
  throw last || new Error('AI 실패');
}
const aiErr = e => e.message === 'NO_KEY' ? '오른쪽 위 [AI 열쇠]에 내 제미나이 무료 열쇠를 넣어 주세요' : (e.message === 'QUOTA' ? '오늘 무료 사용량을 다 썼습니다. 내일 다시 해 주세요' : 'AI 처리에 실패했습니다');
function photoB64(file, maxSide = 1600){
  return new Promise((res, rej) => {
    const url = URL.createObjectURL(file), im = new Image();
    im.onload = () => { const s = Math.min(1, maxSide / Math.max(im.width, im.height));
      const c = document.createElement('canvas'); c.width = Math.max(1, Math.round(im.width * s)); c.height = Math.max(1, Math.round(im.height * s));
      const g = c.getContext('2d'); g.fillStyle = '#fff'; g.fillRect(0, 0, c.width, c.height); g.drawImage(im, 0, 0, c.width, c.height);
      URL.revokeObjectURL(url); res(c.toDataURL('image/jpeg', 0.88).split(',')[1]); };
    im.onerror = () => { URL.revokeObjectURL(url); rej(new Error('사진을 열지 못했습니다')); };
    im.src = url;
  });
}
function initKey(){
  updKey();
  $('#keyBtn').onclick = () => { let k = ''; try{ k = localStorage.getItem('kts_ai_key') || ''; }catch(e){} $('#keyIn').value = k; $('#keyModal').classList.add('on'); };
  $('#keyClose').onclick = () => $('#keyModal').classList.remove('on');
  $('#keySave').onclick = () => { const k = $('#keyIn').value.trim(); if (!/^AIza[\w-]{20,}$/.test(k)) return toast('AIza로 시작하는 열쇠를 넣어 주세요');
    try{ localStorage.setItem('kts_ai_key', k); }catch(e){} updKey(); $('#keyModal').classList.remove('on'); toast('이 기기에만 저장했습니다'); };
  $('#keyDel').onclick = () => { try{ localStorage.removeItem('kts_ai_key'); }catch(e){} $('#keyIn').value = ''; updKey(); toast('열쇠를 지웠습니다'); };
}

/* ---------- 60초 문의 (발송 없음 · 사람 승인 후) ---------- */
function initInquiry(appName, freeLine){
  const LSQ = 'kts_inquiry_queue';
  const make = () => {
    const n = $('#qName').value.trim(), t = $('#qTel').value.trim(), m = $('#qMsg').value.trim();
    let bad = false; [['#qName', n], ['#qTel', t], ['#qMsg', m]].forEach(([s, v]) => { $(s).classList.toggle('miss', !v); if (!v) bad = true; });
    if (bad){ toast('빨간 칸을 채워 주세요'); return null; }
    return {name:n, tel:t, msg:m, at:new Date().toISOString(), app:appName,
      draft:`${n}님, 안녕하세요. KTS 원클릭 ${appName}입니다.\n남겨 주신 문의 "${m.slice(0, 60)}${m.length > 60 ? '…' : ''}" 잘 받았습니다.\n말씀하신 내용을 살펴보고 ${t} 으로 하루 안에 연락드리겠습니다.\n${freeLine}`};
  };
  $('#qMake').onclick = () => { const q = make(); if (!q) return; $('#qDraft').style.display = 'block'; $('#qDraft').textContent = '[답장 초안 · 아직 보내지 않음]\n' + q.draft; };
  $('#qSave').onclick = () => { const q = make(); if (!q) return; let a = []; try{ a = JSON.parse(localStorage.getItem(LSQ) || '[]'); }catch(e){} a.push(q); try{ localStorage.setItem(LSQ, JSON.stringify(a)); }catch(e){}
    $('#qDraft').style.display = 'block'; $('#qDraft').textContent = '[승인 대기 ' + a.length + '건 · 사람이 확인 후 발송]\n' + q.draft; $('#qInfo').textContent = '이 기기의 승인 대기 목록에 담았습니다. 자동으로 보내지 않습니다.'; };
}
/* ===== 공통 도우미 끝 ===== */
