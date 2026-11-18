/* ===== KTS 원클릭 9차 공통 도우미 (복사·저장·인쇄·기기 저장·개인정보 가림) ===== */
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
