/* ===== KTS 원클릭 공통 도우미 (9차 재사용 · 11차 확장) (복사·저장·인쇄·기기 저장·개인정보 가림) ===== */
const $ = s => document.querySelector(s), $$ = s => [...document.querySelectorAll(s)];
let _tt; function toast(m){ const e = $('#toast'); e.textContent = m; e.classList.add('on'); clearTimeout(_tt); _tt = setTimeout(() => e.classList.remove('on'), 2400); }
const esc = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
async function copyText(t){
  try{ await navigator.clipboard.writeText(t); return true; }catch(e){}
  try{ const a = document.createElement('textarea'); a.value = t; a.style.position = 'fixed'; a.style.opacity = '0'; document.body.appendChild(a); a.select(); const ok = document.execCommand('copy'); a.remove(); return ok; }catch(e){ return false; }
}
function copyOut(t, msg){ window.__lastCopy = t; copyText(t).then(ok => toast(ok ? (msg || '복사했습니다') : '복사하지 못했습니다. 글자를 길게 눌러 직접 복사해 주세요')); }
function download(name, text, mime){ window.__lastDownload = {name:name, size:text.length}; const b = new Blob([text], {type:mime || 'text/plain;charset=utf-8'}); const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = name; document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1500); }
const toCSV = rows => rows.map(r => r.map(c => { c = String(c == null ? '' : c); return /[",\r\n]/.test(c) ? '"' + c.replace(/"/g, '""') + '"' : c; }).join(',')).join('\r\n');
function saveCSV(name, rows){ download(name, '﻿' + toCSV(rows), 'text/csv;charset=utf-8'); toast('CSV 파일을 저장했습니다 (엑셀에서 열림)'); }
function printDoc(html){ $('#printArea').innerHTML = html; setTimeout(() => window.print(), 60); }
const LS = { get(k, d){ try{ const v = localStorage.getItem(k); return v == null ? d : JSON.parse(v); }catch(e){ return d; } },
  set(k, v){ try{ localStorage.setItem(k, JSON.stringify(v)); }catch(e){} } };
const pad2 = n => String(n).padStart(2, '0');
const ymd = d => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
const todayS = () => ymd(new Date());
const addDays = (d, n) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };
const parseD = s => { const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || ''); return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null; };
const WK = ['일', '월', '화', '수', '목', '금', '토'];
const korD = d => d ? `${d.getMonth() + 1}월 ${d.getDate()}일(${WK[d.getDay()]})` : '';
/* CSV 붙여넣기 읽기 (따옴표·쉼표·탭 지원) */
function parseCSV(text){
  text = String(text || '').replace(/^﻿/, '');
  const sep = (text.split('\n')[0].indexOf('\t') >= 0) ? '\t' : ',';
  const rows = []; let row = [], cur = '', q = false;
  for (let i = 0; i < text.length; i++){
    const c = text[i];
    if (q){ if (c === '"'){ if (text[i + 1] === '"'){ cur += '"'; i++; } else q = false; } else cur += c; }
    else if (c === '"') q = true;
    else if (c === sep){ row.push(cur.trim()); cur = ''; }
    else if (c === '\n'){ row.push(cur.trim()); rows.push(row); row = []; cur = ''; }
    else if (c !== '\r') cur += c;
  }
  if (cur !== '' || row.length){ row.push(cur.trim()); rows.push(row); }
  return rows.filter(r => r.some(x => x !== ''));
}
/* 개인정보 가림: 휴대폰·일반전화·이메일 */
function maskPII(s){
  return String(s || '')
    .replace(/([\w.+-]{1,64})@([\w-]+(?:\.[\w-]+)+)/g, (m, u, d) => u.slice(0, 2) + '***@' + d)
    .replace(/(01[016789])[-.\s]?(\d{3,4})[-.\s]?(\d{4})/g, (m, a, b, c) => a + '-****-' + c)
    .replace(/(0[2-6]\d?)[-.\s](\d{3,4})[-.\s](\d{4})/g, (m, a, b, c) => a + '-****-' + c);
}
/* 받침에 맞춘 조사: jo('주문','을를') → 주문을 */
const jo = (w, p) => { w = String(w); const c = w.charCodeAt(w.length - 1); const has = c >= 0xAC00 && c <= 0xD7A3 && (c - 0xAC00) % 28 > 0; return w + (has ? p[0] : p[1]); };
const PHONE_RE = /(01[016789])[-.\s]?(\d{3,4})[-.\s]?(\d{4})/;
/* ===== 공통 도우미 끝 ===== */
/* ===== 11차 추가 도우미 ===== */
const num = s => { if (s == null) return NaN; s = String(s).replace(/[,\s원₩$]/g, ''); if (s === '') return NaN; return Number(s); };
const won = n => (isFinite(n) ? Math.round(n).toLocaleString('ko-KR') : '-');
const fx2 = n => (isFinite(n) ? (Math.round(n * 100) / 100).toFixed(2) : '-');
const pct = (n, d) => (isFinite(n) ? (n * 100).toFixed(d == null ? 1 : d) + '%' : '-');
const daysBetween = (a, b) => Math.round((b - a) / 86400000);
function icsFile(name, events){
  const st = d => `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}`;
  const stamp = new Date(); const ds = st(stamp) + 'T' + pad2(stamp.getHours()) + pad2(stamp.getMinutes()) + '00';
  const e = s => String(s).replace(/([,;\\])/g, '\\$1').replace(/\n/g, '\\n');
  const L = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//KTS OneClick//KO', 'CALSCALE:GREGORIAN'];
  events.forEach((v, i) => { L.push('BEGIN:VEVENT', `UID:kts-${st(v.date)}-${i}-${Math.random().toString(36).slice(2, 8)}@oneclick`, `DTSTAMP:${ds}`, `DTSTART;VALUE=DATE:${st(v.date)}`, `DTEND;VALUE=DATE:${st(addDays(v.date, 1))}`, `SUMMARY:${e(v.title)}`, `DESCRIPTION:${e(v.desc || '')}`, 'END:VEVENT'); });
  L.push('END:VCALENDAR'); download(name, L.join('\r\n'), 'text/calendar;charset=utf-8'); return events.length;
}
const utf8Bytes = s => new TextEncoder().encode(String(s)).length;
const maskTel4 = s => { const d = String(s || '').replace(/\D/g, ''); return d.length >= 4 ? '***-****-' + d.slice(-4) : (s ? '****' : ''); };
/* ===== 11차 추가 끝 ===== */
/* ===== 10차 추가 도우미 (문장·숫자·인쇄) ===== */
function splitSent(text){
  const out = [];
  String(text || '').replace(/\r/g, '').split('\n').forEach(line => {
    line = line.trim(); if (!line) return;
    const parts = line.match(/[^.!?。]+(?:[.!?。]+|$)/g) || [line];
    let buf = '';
    parts.forEach(p => { buf += p; if (/(다|요|함|음|임|됨|니다|까|오)[.!?。]\s*$|[!?]\s*$/.test(buf.trim()) || buf.length > 160){ out.push(buf.trim()); buf = ''; } });
    if (buf.trim()) out.push(buf.trim());
  });
  return out.filter(s => s.replace(/[\s\d.,·\-]/g, '').length >= 2);
}
const STOP = new Set('그리고 그러나 하지만 또한 이번 해당 관련 대한 위한 통해 따라 경우 있습니다 합니다 했습니다 됩니다 있는 하는 것을 것은 것이 등을 등의 및 수 있다 한다 이를 이에 우리 저희 그 이 저 것 등 때 중 더 각 약 내 외'.split(' '));
function words(s){
  return (String(s).match(/[가-힣A-Za-z][가-힣A-Za-z0-9]+/g) || []).map(w => w.replace(/(으로|에서|에게|까지|부터|에는|과의|와의|이며|이고|하고|했다|한다|합니다|하는|되는|된다|입니다|이다|은|는|이|가|을|를|의|에|와|과|도|로|만)$/, '')).filter(w => w.length >= 2 && !STOP.has(w));
}
const uniq = a => [...new Set(a)];
/* ===== 10차 추가 끝 ===== */
/* ===== .ics 생성기 (RFC 5545: CRLF · 75바이트 접기 · Asia/Seoul · VALARM) ===== */
function icsFold(line){ const enc = new TextEncoder(); if (enc.encode(line).length <= 75) return line; const out = []; let cur = '', n = 0;
  for (const ch of line){ const b = enc.encode(ch).length; if (n + b > (out.length ? 74 : 75)){ out.push(cur); cur = ''; n = 0; } cur += ch; n += b; } out.push(cur); return out.join('\r\n '); }
const icsEsc = s => String(s == null ? '' : s).replace(/\\/g, '\\\\').replace(/([,;])/g, '\\$1').replace(/\r?\n/g, '\\n');
const icsD = d => `${d.getFullYear()}${pad2(d.getMonth() + 1)}${pad2(d.getDate())}`;
const icsDT = (d, hm) => icsD(d) + 'T' + hm.replace(':', '') + '00';
/* ev: {title, date(Date), start:'HH:MM'|'', end:'HH:MM'|'', allDay, location, desc, alarm:['10m','1h','1d']} */
function icsBuild(evs){
  const now = new Date(), stamp = now.getUTCFullYear() + pad2(now.getUTCMonth() + 1) + pad2(now.getUTCDate()) + 'T' + pad2(now.getUTCHours()) + pad2(now.getUTCMinutes()) + pad2(now.getUTCSeconds()) + 'Z';
  const L = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//KTS OneClick//KO', 'CALSCALE:GREGORIAN', 'METHOD:PUBLISH', 'X-WR-TIMEZONE:Asia/Seoul',
    'BEGIN:VTIMEZONE', 'TZID:Asia/Seoul', 'BEGIN:STANDARD', 'DTSTART:19700101T000000', 'TZOFFSETFROM:+0900', 'TZOFFSETTO:+0900', 'TZNAME:KST', 'END:STANDARD', 'END:VTIMEZONE'];
  evs.forEach((v, i) => {
    L.push('BEGIN:VEVENT', `UID:kts-${icsD(v.date)}-${i}-${(v.title.length * 7919 + i * 104729).toString(36)}-${stamp}@oneclick.local`, 'DTSTAMP:' + stamp);
    if (v.allDay || !v.start){ L.push('DTSTART;VALUE=DATE:' + icsD(v.date), 'DTEND;VALUE=DATE:' + icsD(addDays(v.date, 1))); }
    else { let e = v.end || ''; if (!e){ const [h, m] = v.start.split(':').map(Number); e = pad2(Math.min(23, h + 1)) + ':' + pad2(m); } L.push('DTSTART;TZID=Asia/Seoul:' + icsDT(v.date, v.start), 'DTEND;TZID=Asia/Seoul:' + icsDT(v.date, e)); }
    L.push('SUMMARY:' + icsEsc(v.title), 'LOCATION:' + icsEsc(v.location || ''), 'DESCRIPTION:' + icsEsc(v.desc || ''));
    (v.alarm || []).forEach(a => { const t = {'10m':'-PT10M', '1h':'-PT1H', '1d':'-P1D'}[a]; if (t) L.push('BEGIN:VALARM', 'ACTION:DISPLAY', 'DESCRIPTION:' + icsEsc(v.title), 'TRIGGER:' + t, 'END:VALARM'); });
    L.push('END:VEVENT');
  });
  L.push('END:VCALENDAR'); return L.map(icsFold).join('\r\n') + '\r\n';
}
