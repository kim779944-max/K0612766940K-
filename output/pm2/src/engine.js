/* ===== 아래 엔진은 oneclick/converter.html 에서 그대로 가져온 복사본입니다(수정 금지·동기화 대상) ===== */
const XLET = /^[₩$]?[\d,]+(\.\d+)?$/;
/* ================= 사진 → 구조(JSON) ================= */
/* 문서 전체 1:1 복제 — 표 하나가 아니라 사진 속 종이 한 장의 모든 요소를 위→아래 순서로 읽는다 */
const PROMPT = `이미지는 한국 사업용 문서(안내문·공고문·견적서·거래명세표·정산표)를 찍은 사진입니다.
사진 속 종이 한 장 전체를 한글/엑셀 문서로 원본과 1:1 복제하려 합니다. 표 하나만이 아니라, 종이에 보이는 모든 요소(상단 작은 표, 제목 배너, 본문 문단, 색 글자, 형광펜 줄, 메인 표, 하단 날짜·서명)를 위에서 아래 순서대로 빠짐없이 담으세요.
아래 형식의 JSON만 출력하세요. 다른 말은 절대 쓰지 마세요.

{"blocks":[블록, 블록, ...]}

블록은 두 종류입니다.
1) 표 블록
{"t":"table","main":0또는1,"x":왼쪽위치%,"w":너비%,"nRows":행수,"nCols":열수,"colWidths":[각 열 너비 %, 정수, 합 100],
 "cells":[[r,c,rowSpan,colSpan,"글자",bold(0/1),align("L"/"C"/"R"),"bg #RRGGBB 또는 빈칸","color #RRGGBB 또는 빈칸",num(0/1),noBorder(0/1)], ...]}
2) 글 블록(제목 배너·문단·한 줄 안내·날짜·서명 등 표가 아닌 모든 글)
{"t":"text","align":"L"/"C"/"R","size":글자크기pt,"bg":"배경 #RRGGBB 또는 빈칸","x":왼쪽위치%,"w":너비%,
 "runs":[["글자",bold(0/1),"color #RRGGBB 또는 빈칸","형광펜 #RRGGBB 또는 빈칸","밑줄 #RRGGBB 또는 빈칸"], ...]}

규칙:
- x, w는 종이(문서 본문) 전체 너비를 100으로 본 가로 위치·너비입니다. 가운데 놓인 것은 좌우 여백이 같게.
- 가장 크고 중요한 표 하나만 "main":1, 나머지 표는 0.
- 같은 높이에 작은 표 두 개가 좌우로 떨어져 있으면(예: 왼쪽 '공고번호', 오른쪽 '게시기간') 하나의 표 블록으로 합치고, 가운데 빈 열을 넣어 그 칸들은 noBorder 1로 적으세요.
- 제목이 색 띠(배너) 안에 있으면 글 블록의 bg에 띠 색을, runs 색에 글자색(흰색이면 #FFFFFF)을 적고 size를 크게(예: 20~26).
- 문단 안에서 색이 바뀌는 부분(빨간 글씨 등)은 runs를 나눠 color를 적으세요. 검정 글씨는 color 빈칸.
- 노란 형광펜이 칠해진 글은 형광펜에 그 색(#FFFF00 등)을, 밑줄 친 글은 밑줄에 밑줄 색을 적으세요.
- 본문 글자 크기는 10을 기준으로 상대 크기를 적으세요(작은 글 9, 큰 제목 22 등).
- '- 아 래 -' 같은 가운데 한 줄, 하단 날짜, 회사명·직인 문구도 각각 글 블록으로 넣으세요. 로고 그림은 그 안의 글자만 적으세요.
- 문단은 원본의 줄바꿈이 아니라 문단 단위로 한 블록에 이어 적으세요(띄어쓰기는 원본대로).
- 표: nRows/nCols는 병합을 포함한 전체 격자. colWidths 길이 = nCols. cells는 병합 안 된 칸마다 하나씩(빈 칸 포함). 병합 칸은 좌상단 칸에만 rowSpan/colSpan을 적고 덮인 칸은 넣지 마세요.
- 표 머리글 줄은 bold 1. 머리글 칸에 옅은 파란·회색 바탕이 있으면 bg에 그 색을 적으세요(흰색이면 빈칸). 칸 전체가 색 글씨면 color에 적으세요.
- 한 칸 안에서 일부 글자만 색이 다르면(예: "…, 화물 1호기"의 '화물 1호기'만 빨강) 그 칸 배열 끝(12번째)에 runs를 붙이세요: [["인승 1~4호기, 비상 1호기, ",0,"","",""],["화물 1호기",0,"#C00000","",""]]. runs 글자를 이으면 5번째 "글자"와 같아야 합니다.
- 숫자만 든 칸은 align "C". 긴 목록·설명 칸은 align "L". num은 금액·수량처럼 계산하는 숫자면 1(날짜·전화번호는 0).
- 글자는 사진에 보이는 그대로. 한글·숫자·괄호·물결표(~)·쉼표·띄어쓰기를 원본대로. 없는 글자 절대 지어내지 마세요.
- 사진 밖 배경(벽지·액자·게시판)은 무시하세요.
- 압축된 JSON(줄바꿈/공백 없이)으로 출력하세요.`;

const sleep = ms => new Promise(r => setTimeout(r, ms));

function fileToImage(file, maxSide){
  return new Promise((res, rej) => {
    const url = URL.createObjectURL(file), im = new Image();
    im.onload = () => {
      const s = Math.min(1, maxSide / Math.max(im.width, im.height));
      const w = Math.max(1, Math.round(im.width * s)), h = Math.max(1, Math.round(im.height * s));
      const cv = document.createElement('canvas'); cv.width = w; cv.height = h;
      const g = cv.getContext('2d'); g.fillStyle = '#fff'; g.fillRect(0, 0, w, h); g.drawImage(im, 0, 0, w, h);
      const data = cv.toDataURL('image/jpeg', 0.92).split(',')[1];
      URL.revokeObjectURL(url); res({data, w, h, preview: im.src});
    };
    im.onerror = () => { URL.revokeObjectURL(url); rej(new Error('사진을 열지 못했습니다')); };
    im.src = url;
  });
}

async function visionStruct(file, onStep){
  const cfg = window.KTS_AI || {};
  let key = cfg.key || '';
  try{ key = localStorage.getItem('kts_ai_key') || key; }catch(e){}
  if (!key || /^__/.test(key)) throw new Error('NO_KEY');
  const img = await fileToImage(file, cfg.maxSide || 1800);
  onStep && onStep('사진을 정리했습니다 · AI에게 보내는 중…', 26);
  const models = cfg.models || ['gemini-3.5-flash'];
  let lastErr = null, quotaHit = false;
  for (const model of models){
    for (let attempt = 0; attempt < 2; attempt++){
    try{
      const body = {contents:[{parts:[{text:PROMPT},{inline_data:{mime_type:'image/jpeg', data:img.data}}]}],
        generationConfig:{responseMimeType:'application/json', temperature:0, maxOutputTokens:65535}};
      const ctl = new AbortController(); const to = setTimeout(() => ctl.abort(), 120000);
      const r = await fetch(cfg.endpoint + model + ':generateContent?key=' + encodeURIComponent(key),
        {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body), signal:ctl.signal});
      clearTimeout(to);
      if (r.status === 429){ quotaHit = true; lastErr = new Error('QUOTA'); await sleep(1500); break; }
      if (r.status === 503 || r.status === 500){ lastErr = new Error('AI_BUSY'); await sleep(800); break; }
      if (!r.ok){ lastErr = new Error('AI ' + r.status); break; }
      const j = await r.json();
      const txt = (((j.candidates || [])[0] || {}).content || {}).parts?.[0]?.text || '';
      const raw = parseJsonLoose(txt);
      const st0 = raw ? docFromRaw(raw, img.preview) : null;
      if (!st0) { lastErr = new Error('AI가 표를 찾지 못했습니다'); continue; }
      onStep && onStep('문서 전체 구조를 정리하는 중…', 78);
      return st0;
    }catch(e){ lastErr = e; }
    }
  }
  if (quotaHit) throw new Error('QUOTA');
  throw lastErr || new Error('AI 변환에 실패했습니다');
}
function parseJsonLoose(txt){
  let t = String(txt || '').trim().replace(/^```(?:json)?/i, '').replace(/```$/, '').trim();
  try{ return JSON.parse(t); }catch(e){}
  const a = t.indexOf('{'), b = t.lastIndexOf('}');
  if (a >= 0 && b > a){ try{ return JSON.parse(t.slice(a, b + 1)); }catch(e){} }
  return null;
}
/* 병합·겹침·빈칸을 정리해 반드시 '딱 맞는 격자'로 만든다 */
function normalize(raw, preview){
  const toObj = c => Array.isArray(c)
    ? {r:+c[0]||0, c:+c[1]||0, rs:Math.max(1, +c[2]||1), cs:Math.max(1, +c[3]||1),
       text:String(c[4] == null ? '' : c[4]), bold:!!+c[5],
       align:(c[6] === 'L' || c[6] === 'left') ? 'L' : ((c[6] === 'R' || c[6] === 'right') ? 'R' : 'C'),
       bg:normHex(c[7]), color:normHex(c[8]), num:!!+c[9], nb:!!+c[10], runs:normRuns(c[11])}
    : {r:+c.r||0, c:+c.c||0, rs:Math.max(1, +(c.rowSpan||1)), cs:Math.max(1, +(c.colSpan||1)),
       text:String(c.text == null ? '' : c.text), bold:!!c.bold,
       align:(c.align === 'left' || c.align === 'L') ? 'L' : ((c.align === 'right' || c.align === 'R') ? 'R' : 'C'),
       bg:normHex(c.bg), color:normHex(c.color), num:!!c.num, nb:!!c.nb, runs:normRuns(c.runs)};
  let cells = (raw.cells || []).map(toObj).filter(c => c.r >= 0 && c.c >= 0);
  let nRows = Math.max(1, +raw.nRows || 1), nCols = Math.max(1, +raw.nCols || 1);
  cells.forEach(c => { nRows = Math.max(nRows, c.r + c.rs); nCols = Math.max(nCols, c.c + c.cs); });
  // 열 너비
  let cw = (raw.colWidths || []).map(x => Math.max(0, Math.round(+x || 0)));
  if (cw.length !== nCols){
    const tmp = []; for (let i = 0; i < nCols; i++) tmp.push(cw[i] || Math.round(100 / nCols));
    cw = tmp;
  }
  let sum = cw.reduce((a, b) => a + b, 0) || 1;
  cw = cw.map(w => Math.max(2, Math.round(w / sum * 1000) / 10));
  // 격자 채우기(겹치면 잘라내고, 빈칸은 빈 셀)
  cells.sort((a, b) => a.r - b.r || a.c - b.c);
  const occ = Array.from({length: nRows}, () => new Array(nCols).fill(false));
  const out = [];
  for (const c of cells){
    if (c.r >= nRows || c.c >= nCols) continue;
    let cs = 1, rs = 1;
    while (c.c + cs < nCols && !occ[c.r][c.c + cs] && cs < c.cs) cs++;
    while (c.r + rs < nRows && !occ[c.r + rs][c.c] && rs < c.rs) rs++;
    let free = true;
    for (let r = c.r; r < c.r + rs && free; r++) for (let k = c.c; k < c.c + cs; k++) if (occ[r][k]) { free = false; break; }
    if (!free) continue;
    for (let r = c.r; r < c.r + rs; r++) for (let k = c.c; k < c.c + cs; k++) occ[r][k] = true;
    const o = {r:c.r, c:c.c, rs, cs, text:c.text, bold:c.bold, align:c.align, bg:c.bg, color:c.color, num:c.num};
    if (c.nb) o.nb = true;
    if (c.runs && c.runs.length > 1){ o.runs = c.runs; o.text = c.runs.map(x => x.text).join(''); }
    out.push(o);
  }
  for (let r = 0; r < nRows; r++) for (let c = 0; c < nCols; c++){
    if (!occ[r][c]) out.push({r, c, rs:1, cs:1, text:'', bold:false, align:'C', bg:'', color:'', num:false});
  }
  out.sort((a, b) => a.r - b.r || a.c - b.c);
  // 열이 너무 좁아 '5/13' 같은 값이 두 줄로 쪼개지는 것 방지: 가장 긴 토큰 기준으로 최소 폭 확보
  const minW = new Array(nCols).fill(0);
  out.forEach(c => {
    if (c.cs !== 1) return;
    const toks = String(c.text || '').split(/\s+/).filter(Boolean);
    const len = toks.length ? Math.max(...toks.map(t => t.length)) : 0;
    minW[c.c] = Math.max(minW[c.c], Math.min(14, Math.max(3.5, len * 1.55)));
  });
  if (!raw.lockWidths) cw = cw.map((w, i) => Math.max(w, minW[i]));   /* 사진에서 읽은 원본 너비는 잠근다 */
  const tot2 = cw.reduce((a, b) => a + b, 0) || 1;
  cw = cw.map(w => Math.round(w / tot2 * 1000) / 10);
  const st = {title:String(raw.title || '').trim(), nRows, nCols, colWidths:cw, cells:out, preview};
  /* 실제 글자 폭(9pt)으로 다시 한 번 맞춤 — 미리보기·한글·엑셀이 같은 너비를 쓰게 */
  if (raw.lockWidths) st.lockWidths = true;   /* 사진에서 읽은 원본 열 너비를 그대로 고정 */
  else { try{ st.colWidths = fitColWidths(st, 41952); }catch(e){} }
  return st;
}
function normHex(v){ const s = String(v || '').trim(); return /^#[0-9a-f]{6}$/i.test(s) ? s.toUpperCase() : ''; }

/* ================= 문서 전체(배너·문단·작은 표·메인 표·서명) ================= */
/* 글 조각(run): {text, b, color, hl(형광펜), ul(밑줄 색)} — 같은 모양이 이어지면 하나로 합친다 */
function normRuns(a){
  if (!Array.isArray(a)) return null;
  const ulOf = v => normHex(v) || ((v === 1 || v === '1' || v === true) ? '#000000' : '');
  const out = [];
  a.forEach(x => {
    if (Array.isArray(x)) out.push({text:String(x[0] == null ? '' : x[0]), b:!!+x[1], color:normHex(x[2]), hl:normHex(x[3]), ul:ulOf(x[4])});
    else if (x && typeof x === 'object') out.push({text:String(x.text == null ? '' : x.text), b:!!(x.b || x.bold), color:normHex(x.color), hl:normHex(x.hl || x.highlight), ul:ulOf(x.ul || x.underline)});
    else if (typeof x === 'string') out.push({text:x, b:false, color:'', hl:'', ul:''});
  });
  const m = [];
  out.filter(r => r.text !== '').forEach(r => {
    const p = m[m.length - 1];
    if (p && p.b === r.b && p.color === r.color && p.hl === r.hl && p.ul === r.ul) p.text += r.text; else m.push(r);
  });
  return m;
}
function clampPct(v, d){ const n = +v; return isFinite(n) ? Math.max(0, Math.min(100, n)) : d; }
function placeXW(b){
  let x = clampPct(b.x, 0), w = clampPct(b.w, 100);
  if (w < 5) w = 100;
  if (x + w > 100) x = Math.max(0, 100 - w);
  return {x: Math.round(x * 10) / 10, w: Math.round(w * 10) / 10};
}
/* AI 결과 → 구조. st 자체는 '메인 표'(편집 화면이 그대로 쓰는 표)이고, st.doc 에 종이 전체 순서가 담긴다 */
function docFromRaw(raw, preview){
  if (!raw || typeof raw !== 'object') return null;
  if (!Array.isArray(raw.blocks)){                       /* 예전 형식(표 하나) */
    if (!raw.cells || !raw.cells.length) return null;
    return normalize(raw, preview);
  }
  const blocks = raw.blocks.filter(b => b && typeof b === 'object');
  const isTbl = b => (b.t || b.type) === 'table' && Array.isArray(b.cells) && b.cells.length;
  const tables = blocks.filter(isTbl);
  const main = tables.find(b => +b.main === 1) || tables.slice().sort((a, b) => b.cells.length - a.cells.length)[0] || null;
  const doc = []; let st = null, textN = 0;
  for (const b of blocks){
    const t = b.t || b.type;
    if (t === 'table'){
      if (!isTbl(b)) continue;
      const p = placeXW(b);
      if (b === main){ st = normalize(b, preview); doc.push({t:'table', main:true, x:p.x, w:p.w}); }
      else doc.push({t:'table', x:p.x, w:p.w, tbl:normalize(Object.assign({}, b, {lockWidths:true}), '')});
    } else if (t === 'text'){
      let runs = normRuns(b.runs);
      if ((!runs || !runs.length) && b.text) runs = [{text:String(b.text), b:!!+b.bold, color:normHex(b.color), hl:'', ul:''}];
      runs = runs || [];
      let size = +b.size; if (!isFinite(size) || size <= 0) size = 10; size = Math.max(7, Math.min(32, size));
      const al = String(b.align || 'L').toUpperCase().charAt(0);
      const p = placeXW(b);
      if (runs.length) textN++;
      doc.push({t:'text', runs, align:al === 'C' ? 'C' : (al === 'R' ? 'R' : 'L'), size, bg:normHex(b.bg), x:p.x, w:p.w});
    }
  }
  if (!st){
    if (!textN) return null;
    /* 표가 없는 문서 — 글만 복제한다(메인 표 자리는 비워 둔다) */
    st = normalize({nRows:1, nCols:1, colWidths:[100], cells:[[0, 0, 1, 1, '', 0, 'C', '', '', 0]]}, preview);
    st._noMain = true;
  }
  st.title = '';
  st.doc = doc;
  return st;
}
function docCounts(st){
  const d = (st && st.doc) || [];
  return {tables: d.filter(b => b.t === 'table').length, texts: d.filter(b => b.t === 'text' && b.runs.length).length,
    colors: [...new Set(docColors(st))]};
}
/* 문서에 쓰인 색(배경·글자·형광펜·밑줄)을 모두 모은다 — 검증·안내용 */
function docColors(st){
  const out = [];
  const addCell = c => { if (c.bg) out.push(c.bg); if (c.color) out.push(c.color); (c.runs || []).forEach(r => { if (r.color) out.push(r.color); if (r.hl) out.push(r.hl); }); };
  (st.cells || []).forEach(addCell);
  ((st && st.doc) || []).forEach(b => {
    if (b.t === 'text'){ if (b.bg) out.push(b.bg); b.runs.forEach(r => { if (r.color) out.push(r.color); if (r.hl) out.push(r.hl); if (r.ul) out.push(r.ul); }); }
    else if (b.tbl) b.tbl.cells.forEach(addCell);
  });
  return out;
}
/* ================= 글꼴 (원본과 같게, 없으면 유사 폰트) ================= */
const FONT_ALIAS = {'HY신명조':'바탕', 'HY중고딕':'돋움', '한컴바탕':'바탕', '새바탕':'바탕',
  '한컴돋움':'돋움', '새돋움':'돋움', '맑은고딕':'맑은 고딕', 'Malgun Gothic':'맑은 고딕'};
let CUR_FONT = '';
function hwFont(xml, face){
  if (!face) return xml;
  xml = xml.replace(/<hh:fontface lang="([A-Z]+)" fontCnt="1">(<hh:font id="0"[^>]*\/>)<\/hh:fontface>/g,
    (m, lang, f0) => `<hh:fontface lang="${lang}" fontCnt="2">${f0}<hh:font id="1" face="${face}" type="TTF" isEmbedded="0"/></hh:fontface>`);
  xml = xml.replace(/<hh:fontRef hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"\/>/,
    '<hh:fontRef hangul="1" latin="1" hanja="1" japanese="1" other="1" symbol="0" user="0"/>');
  return xml;
}

/* ================= ZIP (store/deflate-raw) ================= */
const CRC_TABLE = (() => { const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++){ let c = n; for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1); t[n] = c >>> 0; }
  return t; })();
function crc32(u8){ let c = 0xFFFFFFFF; for (let i = 0; i < u8.length; i++) c = CRC_TABLE[(c ^ u8[i]) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
async function deflateRaw(u8){
  if (typeof CompressionStream === 'undefined') return null;
  try{ const cs = new CompressionStream('deflate-raw');
    return new Uint8Array(await new Response(new Blob([u8]).stream().pipeThrough(cs)).arrayBuffer());
  }catch(e){ return null; }
}
async function makeZip(entries){
  const enc = new TextEncoder(), chunks = [], central = []; let offset = 0;
  for (const e of entries){
    const nameBytes = enc.encode(e.name);
    const data = typeof e.data === 'string' ? enc.encode(e.data) : e.data;
    const crc = crc32(data);
    let payload = data, method = 0;
    if (!e.store){ const d = await deflateRaw(data); if (d && d.length < data.length){ payload = d; method = 8; } }
    const lh = new Uint8Array(30 + nameBytes.length), dv = new DataView(lh.buffer);
    dv.setUint32(0, 0x04034b50, true); dv.setUint16(4, 20, true); dv.setUint16(6, 0, true);
    dv.setUint16(8, method, true); dv.setUint16(10, 0, true); dv.setUint16(12, 0x2100, true);
    dv.setUint32(14, crc, true); dv.setUint32(18, payload.length, true); dv.setUint32(22, data.length, true);
    dv.setUint16(26, nameBytes.length, true); lh.set(nameBytes, 30);
    chunks.push(lh, payload);
    const ch = new Uint8Array(46 + nameBytes.length), cv = new DataView(ch.buffer);
    cv.setUint32(0, 0x02014b50, true); cv.setUint16(4, 20, true); cv.setUint16(6, 20, true);
    cv.setUint16(10, method, true); cv.setUint16(14, 0x2100, true);
    cv.setUint32(16, crc, true); cv.setUint32(20, payload.length, true); cv.setUint32(24, data.length, true);
    cv.setUint16(28, nameBytes.length, true); cv.setUint32(42, offset, true); ch.set(nameBytes, 46);
    central.push(ch); offset += lh.length + payload.length;
  }
  const cs = central.reduce((a, b) => a + b.length, 0);
  const eocd = new Uint8Array(22), ev = new DataView(eocd.buffer);
  ev.setUint32(0, 0x06054b50, true); ev.setUint16(8, entries.length, true); ev.setUint16(10, entries.length, true);
  ev.setUint32(12, cs, true); ev.setUint32(16, offset, true);
  return new Blob([...chunks, ...central, eocd], {type:'application/zip'});
}
const xmlEsc = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const colName = c => { let s = '', n = c + 1; while (n > 0){ const m = (n - 1) % 26; s = String.fromCharCode(65 + m) + s; n = Math.floor((n - 1) / 26); } return s; };

/* ================= XLSX (병합·색·테두리·정렬·숫자) ================= */
function buildXlsx(st){
  if (st.doc) return buildXlsxDoc(st);   /* 종이 전체(배너·문단·작은 표·서명)를 한 시트에 */
  const fonts = [{b:false, color:''}], fills = ['', ''], borders = [false, true], xfs = [], numFmts = [];
  const fidx = (b, color) => { const k = (b ? 1 : 0) + '|' + color; let i = fonts.findIndex(f => (f.b ? 1 : 0) + '|' + f.color === k); if (i < 0){ fonts.push({b, color}); i = fonts.length - 1; } return i; };
  const gidx = bg => { if (!bg) return 0; let i = fills.indexOf(bg.toUpperCase()); if (i < 0){ fills.push(bg.toUpperCase()); i = fills.length - 1; } return i; };
  const xf = (font, fill, border, align, numFmt) => {
    const k = [font, fill, border, align, numFmt].join(';');
    let i = xfs.findIndex(x => x.k === k);
    if (i < 0){ xfs.push({k, font, fill, border, align, numFmt}); i = xfs.length - 1; }
    return i;
  };
  xf(0, 0, 0, '', 0); // 0 = 기본
  const totalW = 104; // A4 세로에 맞는 대략적 폭(문자 단위)
  let colsXml = '<cols>' + st.colWidths.map((w, i) => `<col min="${i + 1}" max="${i + 1}" width="${Math.max(6, Math.round(w / 100 * totalW * 10) / 10)}" customWidth="1"/>`).join('') + '</cols>';
  const rowsXml = [];
  for (let r = 0; r < st.nRows; r++){
    const rowCells = st.cells.filter(c => c.r === r).sort((a, b) => a.c - b.c);
    let sx = `<row r="${r + 1}">`;
    for (const c of rowCells){
      const ref = colName(c.c) + (r + 1);
      const txt = String(c.text || '');
      let t = null, v = null, nf = 0;
      if (c.num && XLET.test(txt.replace(/\s/g, ''))){
        const cur = /^[₩$]/.test(txt.trim());
        const raw = txt.replace(/[₩$,\s]/g, '');
        if (raw !== '' && !isNaN(+raw)){ t = 'n'; v = raw; nf = cur ? 164 : 3; }
      }
      const s = xf(fidx(!!c.bold, c.color), gidx(c.bg), 1, c.align, nf);
      if (t === 'n') sx += `<c r="${ref}" s="${s}"><v>${v}</v></c>`;
      else if (txt !== '') sx += `<c r="${ref}" s="${s}" t="inlineStr"><is><t xml:space="preserve">${xmlEsc(txt)}</t></is></c>`;
      else sx += `<c r="${ref}" s="${s}"/>`;
    }
    sx += '</row>'; rowsXml.push(sx);
  }
  let mergeXml = '';
  const mg = st.cells.filter(c => c.rs > 1 || c.cs > 1)
    .map(c => colName(c.c) + (c.r + 1) + ':' + colName(c.c + c.cs - 1) + (c.r + c.rs));
  if (mg.length) mergeXml = `<mergeCells count="${mg.length}">` + mg.map(m => `<mergeCell ref="${m}"/>`).join('') + '</mergeCells>';
  const lastRef = colName(st.nCols - 1) + st.nRows;
  const sheet = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    + `<dimension ref="A1:${lastRef}"/><sheetViews><sheetView workbookViewId="0" showGridLines="0"/></sheetViews><sheetFormatPr defaultRowHeight="17"/>`
    + colsXml + '<sheetData>' + rowsXml.join('') + '</sheetData>' + mergeXml
    + '<pageMargins left="0.4" right="0.4" top="0.5" bottom="0.5" header="0.3" footer="0.3"/></worksheet>';
  const ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    + '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    + '<Default Extension="xml" ContentType="application/xml"/>'
    + '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    + '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
    + '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    + '</Types>';
  const rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    + '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>';
  const wb = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    + '<sheets><sheet name="표" sheetId="1" r:id="rId1"/></sheets></workbook>';
  const wbrels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    + '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
    + '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>';
  const fontsXml = fonts.map(f => `<font>${f.b ? '<b/>' : ''}${f.color ? `<color rgb="FF${f.color.replace('#', '')}"/>` : ''}<sz val="11"/><name val="맑은 고딕"/><family val="2"/></font>`).join('');
  const fillsXml = fills.map((bg, i) => i === 0 ? '<fill><patternFill patternType="none"/></fill>' : (i === 1 ? '<fill><patternFill patternType="gray125"/></fill>' : `<fill><patternFill patternType="solid"><fgColor rgb="FF${bg.replace('#', '')}"/><bgColor indexed="64"/></patternFill></fill>`)).join('');
  const bordersXml = borders.map(b => b
    ? '<border><left style="thin"><color rgb="FF333333"/></left><right style="thin"><color rgb="FF333333"/></right><top style="thin"><color rgb="FF333333"/></top><bottom style="thin"><color rgb="FF333333"/></bottom><diagonal/></border>'
    : '<border><left/><right/><top/><bottom/><diagonal/></border>').join('');
  const xfsXml = xfs.map(x => {
    const al = x.align ? `<alignment horizontal="${x.align === 'L' ? 'left' : (x.align === 'R' ? 'right' : 'center')}" vertical="center" wrapText="1"/>` : '<alignment vertical="center" wrapText="1"/>';
    return `<xf numFmtId="${x.numFmt}" fontId="${x.font}" fillId="${x.fill}" borderId="${x.border}" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1" applyNumberFormat="1">${al}</xf>`;
  }).join('');
  const customFmts = '<numFmt numFmtId="164" formatCode="&quot;₩&quot;#,##0"/>';
  const styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    + `<numFmts count="1">${customFmts}</numFmts>`
    + `<fonts count="${fonts.length}">${fontsXml}</fonts>`
    + `<fills count="${fills.length}">${fillsXml}</fills>`
    + `<borders count="${borders.length}">${bordersXml}</borders>`
    + '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    + `<cellXfs count="${xfs.length}">${xfsXml}</cellXfs>`
    + '</styleSheet>';
  return [
    {name:'[Content_Types].xml', data:ct},
    {name:'_rels/.rels', data:rels},
    {name:'xl/workbook.xml', data:wb},
    {name:'xl/_rels/workbook.xml.rels', data:wbrels},
    {name:'xl/styles.xml', data:styles},
    {name:'xl/worksheets/sheet1.xml', data:sheet}
  ];
}

/* ================= XLSX — 문서 전체(시트 위아래에 제목 배너·본문·강조색·작은 표·서명까지) ================= */
/* 모든 표의 열 경계를 하나의 격자로 합쳐, 작은 표·메인 표·문단이 한 시트에서 원본 위치 그대로 놓이게 한다 */
function buildXlsxDoc(st){
  const PW = 41952;
  const tbls = [];
  st.doc.forEach(b => {
    if (b.t !== 'table') return;
    if (b.main){ if (!st._noMain) tbls.push({tst:st, x:b.x || 0, w:b.w || 100, main:true}); }
    else tbls.push({tst:b.tbl, x:b.x || 0, w:b.w || 100});
  });
  const edges = t => { const out = [t.x]; let acc = t.x; t.tst.colWidths.forEach(cw => { acc += cw * t.w / 100; out.push(acc); }); return out; };
  /* 1) 열 경계 합치기(메인 표 먼저 — 1.2% 안쪽으로 붙은 경계는 하나로) */
  const bounds = [0, 100];
  const addB = v => { v = Math.max(0, Math.min(100, v)); if (!bounds.some(b => Math.abs(b - v) < 1.2)) bounds.push(v); };
  tbls.filter(t => t.main).concat(tbls.filter(t => !t.main)).forEach(t => edges(t).forEach(addB));
  bounds.sort((a, b) => a - b);
  const NC = bounds.length - 1;
  const snap = v => { let bi = 0, bd = 1e9; bounds.forEach((b, i) => { const d = Math.abs(b - v); if (d < bd){ bd = d; bi = i; } }); return bi; };
  tbls.forEach(t => {
    const ix = edges(t).map(snap);
    for (let k = 1; k < ix.length; k++) if (ix[k] <= ix[k - 1]) ix[k] = Math.min(NC, ix[k - 1] + 1);
    t.ix = ix;
  });
  /* 2) 스타일 표 */
  const fonts = [{b:false, color:'', sz:11, u:false}], fills = ['', ''], xfs = [];
  const fidx = (b, color, sz, u) => {
    const k = [b ? 1 : 0, color || '', sz || 11, u ? 1 : 0].join('|');
    let i = fonts.findIndex(f => [f.b ? 1 : 0, f.color || '', f.sz, f.u ? 1 : 0].join('|') === k);
    if (i < 0){ fonts.push({b:!!b, color:color || '', sz:sz || 11, u:!!u}); i = fonts.length - 1; }
    return i;
  };
  const gidx = bg => { if (!bg) return 0; const u = bg.toUpperCase(); let i = fills.indexOf(u); if (i < 0){ fills.push(u); i = fills.length - 1; } return i; };
  const xf = (font, fill, border, align, numFmt) => {
    const k = [font, fill, border, align, numFmt].join(';');
    let i = xfs.findIndex(x => x.k === k);
    if (i < 0){ xfs.push({k, font, fill, border, align, numFmt}); i = xfs.length - 1; }
    return i;
  };
  xf(0, 0, 0, '', 0);
  const rich = (runs, base) => runs.map(r => {
    const b = base.b || r.b, color = r.color || base.color, sz = base.sz;
    return '<r><rPr>' + (b ? '<b/>' : '') + (r.ul ? '<u/>' : '') + `<sz val="${sz}"/>`
      + (color ? `<color rgb="FF${color.replace('#', '')}"/>` : '') + '<rFont val="맑은 고딕"/><family val="2"/></rPr>'
      + `<t xml:space="preserve">${xmlEsc(r.text)}</t></r>`;
  }).join('');
  /* 3) 행 만들기 */
  const grid = [];      /* grid[row] = {cells:{col:xml}, ht} */
  const merges = [];
  let R = 0;
  const putRow = () => { grid[R] = grid[R] || {cells:{}, ht:0}; return grid[R]; };
  const charsPerLine = sz => Math.max(8, Math.floor(104 / (sz / 11) / 1.9));   /* 한글 한 글자 ≈ 엑셀 1.9칸 */
  st.doc.forEach(b => {
    if (b.t === 'text'){
      const row = putRow();
      const sz = Math.max(8, Math.round(b.size * 1.1));
      const txt = b.runs.map(r => r.text).join('');
      if (!txt){ row.ht = 9; R++; return; }
      const hlChars = b.runs.filter(r => r.hl).reduce((a, r) => a + r.text.length, 0);
      const hl = b.runs.find(r => r.hl);
      const fillBg = b.bg || (hl && hlChars >= txt.length * 0.6 ? hl.hl : '');
      const uniform = b.runs.length === 1 && !b.runs[0].ul;
      const f0 = uniform ? fidx(b.runs[0].b, b.runs[0].color, sz, false) : fidx(false, '', sz, false);
      const s = xf(f0, gidx(fillBg), 0, b.align, 0);
      const c0 = snap(b.x || 0), c1 = Math.max(c0, snap((b.x || 0) + (b.w || 100)) - 1);
      const ref = colName(c0) + (R + 1);
      row.cells[c0] = uniform
        ? `<c r="${ref}" s="${s}" t="inlineStr"><is><t xml:space="preserve">${xmlEsc(txt)}</t></is></c>`
        : `<c r="${ref}" s="${s}" t="inlineStr"><is>${rich(b.runs, {b:false, color:'', sz})}</is></c>`;
      for (let k = c0 + 1; k <= c1; k++) row.cells[k] = `<c r="${colName(k) + (R + 1)}" s="${s}"/>`;
      if (c1 > c0) merges.push(ref + ':' + colName(c1) + (R + 1));
      const span = Math.max(0.1, ((b.w || 100)) / 100);
      const lines = Math.max(1, Math.ceil(txt.length / (charsPerLine(sz) * span)));
      row.ht = Math.round(lines * sz * 1.45 + (b.bg ? 14 : 5));
      R++;
      return;
    }
    if (b.t !== 'table') return;
    const t = tbls.find(x => (b.main ? x.main : x.tst === b.tbl));
    if (!t) return;
    const tst = t.tst;
    const tw = PW * t.w / 100;
    const widthsH = tst.colWidths.map(w => tw * w / 100);
    for (let r = 0; r < tst.nRows; r++){
      const row = (grid[R + r] = grid[R + r] || {cells:{}, ht:0});
      const n = rowLines(tst, r, widthsH, tw);
      row.ht = Math.max(row.ht, n <= 1 ? 20 : n * 15 + 6);
    }
    tst.cells.forEach(c => {
      const c0 = t.ix[c.c], c1 = Math.max(c0, t.ix[c.c + c.cs] - 1);
      const r0 = R + c.r, r1 = R + c.r + c.rs - 1;
      const txt = String(c.text || '');
      let tN = null, v = null, nf = 0;
      if (c.num && XLET.test(txt.replace(/\s/g, ''))){
        const cur = /^[₩$]/.test(txt.trim()), raw = txt.replace(/[₩$,\s]/g, '');
        if (raw !== '' && !isNaN(+raw)){ tN = 'n'; v = raw; nf = cur ? 164 : 3; }
      }
      const s = xf(fidx(!!c.bold, c.color, 11, false), gidx(c.bg), c.nb ? 0 : 1, c.align, nf);
      const ref = colName(c0) + (r0 + 1);
      let xml;
      if (tN === 'n') xml = `<c r="${ref}" s="${s}"><v>${v}</v></c>`;
      else if (c.runs && c.runs.length) xml = `<c r="${ref}" s="${s}" t="inlineStr"><is>${rich(c.runs, {b:!!c.bold, color:c.color || '', sz:11})}</is></c>`;
      else if (txt !== '') xml = `<c r="${ref}" s="${s}" t="inlineStr"><is><t xml:space="preserve">${xmlEsc(txt)}</t></is></c>`;
      else xml = `<c r="${ref}" s="${s}"/>`;
      for (let y = r0; y <= r1; y++){
        const row = (grid[y] = grid[y] || {cells:{}, ht:0});
        for (let k = c0; k <= c1; k++) row.cells[k] = (y === r0 && k === c0) ? xml : `<c r="${colName(k) + (y + 1)}" s="${s}"/>`;   /* 병합 영역 전체에 테두리·배경 */
      }
      if (c1 > c0 || r1 > r0) merges.push(ref + ':' + colName(c1) + (r1 + 1));
    });
    R += tst.nRows;
  });
  const rowsXml = [];
  for (let r = 0; r < Math.max(1, R); r++){
    const row = grid[r] || {cells:{}, ht:0};
    const cols = Object.keys(row.cells).map(Number).sort((a, b) => a - b);
    rowsXml.push(`<row r="${r + 1}"${row.ht ? ` ht="${row.ht}" customHeight="1"` : ''}>` + cols.map(k => row.cells[k]).join('') + '</row>');
  }
  const totalW = 104;
  const colsXml = '<cols>' + bounds.slice(1).map((b, i) => {
    const w = Math.max(1.2, Math.round((b - bounds[i]) / 100 * totalW * 10) / 10);
    return `<col min="${i + 1}" max="${i + 1}" width="${w}" customWidth="1"/>`;
  }).join('') + '</cols>';
  const mergeXml = merges.length ? `<mergeCells count="${merges.length}">` + merges.map(m => `<mergeCell ref="${m}"/>`).join('') + '</mergeCells>' : '';
  const lastRef = colName(NC - 1) + Math.max(1, R);
  const sheet = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    + '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>'
    + `<dimension ref="A1:${lastRef}"/><sheetViews><sheetView workbookViewId="0" showGridLines="0"/></sheetViews><sheetFormatPr defaultRowHeight="17"/>`
    + colsXml + '<sheetData>' + rowsXml.join('') + '</sheetData>' + mergeXml
    + '<pageMargins left="0.4" right="0.4" top="0.5" bottom="0.5" header="0.3" footer="0.3"/>'
    + '<pageSetup paperSize="9" orientation="portrait" fitToWidth="1" fitToHeight="0"/></worksheet>';
  const fontsXml = fonts.map(f => `<font>${f.b ? '<b/>' : ''}${f.u ? '<u/>' : ''}<sz val="${f.sz}"/>${f.color ? `<color rgb="FF${f.color.replace('#', '')}"/>` : ''}<name val="맑은 고딕"/><family val="2"/></font>`).join('');
  const fillsXml = fills.map((bg, i) => i === 0 ? '<fill><patternFill patternType="none"/></fill>' : (i === 1 ? '<fill><patternFill patternType="gray125"/></fill>' : `<fill><patternFill patternType="solid"><fgColor rgb="FF${bg.replace('#', '')}"/><bgColor indexed="64"/></patternFill></fill>`)).join('');
  const bordersXml = '<border><left/><right/><top/><bottom/><diagonal/></border>'
    + '<border><left style="thin"><color rgb="FF333333"/></left><right style="thin"><color rgb="FF333333"/></right><top style="thin"><color rgb="FF333333"/></top><bottom style="thin"><color rgb="FF333333"/></bottom><diagonal/></border>';
  const xfsXml = xfs.map(x => {
    const al = x.align ? `<alignment horizontal="${x.align === 'L' ? 'left' : (x.align === 'R' ? 'right' : 'center')}" vertical="center" wrapText="1"/>` : '<alignment vertical="center" wrapText="1"/>';
    return `<xf numFmtId="${x.numFmt}" fontId="${x.font}" fillId="${x.fill}" borderId="${x.border}" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1" applyNumberFormat="1">${al}</xf>`;
  }).join('');
  const styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    + '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    + '<numFmts count="1"><numFmt numFmtId="164" formatCode="&quot;₩&quot;#,##0"/></numFmts>'
    + `<fonts count="${fonts.length}">${fontsXml}</fonts>`
    + `<fills count="${fills.length}">${fillsXml}</fills>`
    + '<borders count="2">' + bordersXml + '</borders>'
    + '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
    + `<cellXfs count="${xfs.length}">${xfsXml}</cellXfs>`
    + '</styleSheet>';
  const base = buildXlsx({nRows:1, nCols:1, colWidths:[100], cells:[]});   /* 통 껍데기(관계·통합문서)는 기존 것을 그대로 쓴다 */
  return base.map(e => e.name === 'xl/worksheets/sheet1.xml' ? {name:e.name, data:sheet} : (e.name === 'xl/styles.xml' ? {name:e.name, data:styles} : e));
}

/* ================= HWPX (병합·열너비·배경·정렬·굵게) ================= */
let TPL = null;
async function loadTpl(){
  if (TPL) return TPL;
  const files = ['version.xml','settings.xml','META-INF__manifest.xml','META-INF__container.xml','META-INF__container.rdf','Contents__content.hpf','Contents__header.xml','sec_prefix.xml','tbl_parts.json'];
  const text = {};
  await Promise.all(files.map(async f => {
    const r = await fetch('tpl/' + f);
    if (!r.ok) throw new Error('tpl/' + f + ' 없음');
    text[f] = f.endsWith('.json') ? await r.json() : await r.text();
  }));
  TPL = {text, prefix:text['sec_prefix.xml'], parts:text['tbl_parts.json']};
  return TPL;
}
/* 글자 모양 열쇠 — 굵기|색|크기[|형광펜|밑줄] (형광펜·밑줄이 없으면 예전 열쇠와 같다) */
const chKey = (b, color, h, hl, ul) => (b ? 1 : 0) + '|' + (color || '') + '|' + (h || 900) + ((hl || ul) ? '|' + (hl || '') + '|' + (ul || '') : '');
function hwHeader(base, need){
  // need: {bgs:[], nbBgs:[], chars:[{b,color,h,hl,ul}], aligns:[]}
  let borderFills = '', chars = '', paras = '';
  let bfCnt = 2, chCnt = 3, paCnt = 10;
  const bfId = {}, chId = {}, paId = {};
  const bfXml = (id, bg, line) => {
    const side = s => `<hh:${s}Border type="${line ? 'SOLID' : 'NONE'}" width="${line ? '0.12 mm' : '0.1 mm'}" color="#000000"/>`;
    return `<hh:borderFill id="${id}" threeD="0" shadow="0" centerLine="NONE" breakCellSeparateLine="0">`
      + '<hh:slash type="NONE" Crooked="0" isCounter="0"/><hh:backSlash type="NONE" Crooked="0" isCounter="0"/>'
      + side('left') + side('right') + side('top') + side('bottom')
      + '<hh:diagonal type="SOLID" width="0.1 mm" color="#000000"/>'
      + (bg ? `<hc:fillBrush><hc:winBrush faceColor="${bg}" hatchColor="#999999" alpha="0"/></hc:fillBrush>` : '')
      + '</hh:borderFill>';
  };
  need.bgs.forEach(bg => {
    if (!bg){ bfId[''] = 2; return; }
    if (bfId[bg]) return;
    bfCnt++; bfId[bg] = 99 + bfCnt; borderFills += bfXml(bfId[bg], bg, true);
  });
  (need.nbBgs || []).forEach(bg => {          /* 테두리 없는 칸(좌우 작은 표 사이 빈 열·제목 배너) */
    const k = 'nb|' + (bg || '');
    if (bfId[k]) return;
    if (!bg){ bfId[k] = 1; return; }
    bfCnt++; bfId[k] = 99 + bfCnt; borderFills += bfXml(bfId[k], bg, false);
  });
  need.chars.forEach(c => {
    const key = chKey(c.b, c.color, c.h, c.hl, c.ul);
    if (chId[key]) return;
    chCnt++; const id = 99 + chCnt; chId[key] = id;
    chars += `<hh:charPr id="${id}" height="${c.h || 900}" textColor="${c.color || '#000000'}" shadeColor="${c.hl || 'none'}" useFontSpace="0" useKerning="0" symMark="NONE" borderFillIDRef="1">`
      + '<hh:fontRef hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"/>'
      + '<hh:ratio hangul="100" latin="100" hanja="100" japanese="100" other="100" symbol="100" user="100"/>'
      + '<hh:spacing hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"/>'
      + '<hh:relSz hangul="100" latin="100" hanja="100" japanese="100" other="100" symbol="100" user="100"/>'
      + '<hh:offset hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"/>'
      + (c.b ? '<hh:bold/>' : '')
      + `<hh:underline type="${c.ul ? 'BOTTOM' : 'NONE'}" shape="SOLID" color="${c.ul || '#000000'}"/><hh:strikeout shape="NONE" color="#000000"/>`
      + '<hh:outline type="NONE"/><hh:shadow type="NONE" color="#000000" offsetX="0" offsetY="0"/></hh:charPr>';
  });
  const paBase = /<hh:paraPr id="0".*?<\/hh:paraPr>/s.exec(base)[0];
  need.aligns.forEach(al => {
    if (paId[al]) return;
    paCnt++; const id = 99 + paCnt; paId[al] = id;
    /* 'L'/'C'/'R' = 표 칸(줄간격 125%) · 'TL'/'TC'/'TR' = 본문 문단(줄간격 160%, 문단 아래 여백) */
    const a = al.charAt(al.length - 1), text = al.length > 1;
    const horiz = a === 'L' ? 'JUSTIFY' : (a === 'R' ? 'RIGHT' : 'CENTER');
    let body = paBase.replace(/<hh:paraPr id="0"/, `<hh:paraPr id="${id}"`)
      .replace(/<hh:align horizontal="[A-Z]+"/, `<hh:align horizontal="${horiz}"`);
    if (text) body = body.replace(/<hc:next value="0" unit="HWPUNIT"\/>/g, '<hc:next value="500" unit="HWPUNIT"/>');
    else body = body.replace(/value="160" unit="HWPUNIT"/g, 'value="125" unit="HWPUNIT"');
    paras += body;
  });
  let xml = base;
  xml = xml.replace('<hh:borderFills itemCnt="2">', `<hh:borderFills itemCnt="${bfCnt}">`);
  xml = xml.replace('</hh:borderFills>', borderFills + '</hh:borderFills>');
  xml = xml.replace(/<hh:charProperties itemCnt="3">/, `<hh:charProperties itemCnt="${chCnt}">`);
  xml = xml.replace('</hh:charProperties>', chars + '</hh:charProperties>');
  xml = xml.replace(/<hh:paraProperties itemCnt="10">/, `<hh:paraProperties itemCnt="${paCnt}">`);
  xml = xml.replace('</hh:paraProperties>', paras + '</hh:paraProperties>');
  return {xml, bfId, chId, paId};
}
/* ================= 열 너무·행 높이: 원본 1:1 보장 ================= */
const HWPU_PER_PT = 100;           /* 1pt = 100 HWPUNIT */
const CELL_MARGIN = 360;           /* 좌우 여백 합 170+170 + 여유 */
function charUnits(ch){
  const c = ch.charCodeAt(0);
  if(c === 32) return 260;                       /* 공백 */
  if(c < 128) return 470;                        /* 영문·숫자·기호 */
  if(c >= 0x3130 && c <= 0x318F) return 480;      /* 한글 호환 자모 */
  return 900;                                    /* 한글·한자·확장 */
}
function textUnits(s){
  let n = 0;
  const t = String(s == null ? '' : s);
  for(const ch of t) n += charUnits(ch);
  return n;
}
/* 원본 열 너비를 잠그고 글자를 줄여 넣는다 — 넘치면 임의 줄바꿈 대신 크기를 줄인다 */
function shrinkH(text, w){
  const avail = Math.max(600, w - CELL_MARGIN);
  let h = 900;
  while (h > 700 && textUnits(text) * (h / 900) > avail) h -= 50;
  return h;
}
/* 열 너비(%): 원본 비율 유지하면서 ‘글자가 꾼기는 최소 폭’을 보장하고, 남는 폭에서 나눔 */
function fitColWidths(st, totalW){
  const n = st.nCols;
  let pct = (st.colWidths || []).slice(0, n).map(x => Math.max(1, +x || 0));
  while (pct.length < n) pct.push(100 / n);
  const sum0 = pct.reduce((a, b) => a + b, 0) || 100;
  pct = pct.map(x => x / sum0 * 100);
  /* 열별 ‘절대 넓히면 안 꾼기는’ 최소 HWPUNIT */
  const need = new Array(n).fill(0);
  st.cells.forEach(c => {
    if (c.cs > 1) return;                            /* 병합 칸은 기준에서 제외 */
    const lines = String(c.text == null ? '' : c.text).split('\n');
    let mx = 0;
    lines.forEach(l => { const u = textUnits(l); if (u > mx) mx = u; });
    if (mx > need[c.c]) need[c.c] = mx;
  });
  const minPct = need.map(u => Math.min(60, (u + CELL_MARGIN) / totalW * 100));
  /* 공백이 있으면 먼저 분배, 모자라면 넓은 열에서 가져온다 */
  for (let pass = 0; pass < 4; pass++){
    let deficit = 0;
    for (let i = 0; i < n; i++) if (pct[i] < minPct[i]) deficit += minPct[i] - pct[i];
    if (deficit < 0.01) break;
    let pool = 0;
    for (let i = 0; i < n; i++) pool += Math.max(0, pct[i] - minPct[i]);
    for (let i = 0; i < n; i++){
      if (pct[i] < minPct[i]){ pct[i] = minPct[i]; continue; }
      const flex = Math.max(0, pct[i] - minPct[i]);
      if (pool > 0) pct[i] -= flex / pool * Math.min(deficit, pool);
    }
    const s = pct.reduce((a, b) => a + b, 0) || 100;
    pct = pct.map(x => x / s * 100);
  }
  return pct.map(x => Math.max(1, Math.round(x * 10) / 10));
}
/* 행 높이 — 그 행에서 몇 줄까지 꾼이는지 계산해 1줄은 1:1로 유지 */
function rowLines(st, r, widths, totalW){
  let maxLines = 1;
  st.cells.forEach(c => {
    if (c.r > r || c.r + c.rs <= r) return;
    let w = 0;
    for (let k = 0; k < c.cs; k++) w += widths[c.c + k] || 0;
    const avail = Math.max(600, w - CELL_MARGIN);
    const lines = String(c.text == null ? '' : c.text).split('\n');
    let need = 1;
    lines.forEach(l => { need += Math.ceil(textUnits(l) / avail); });
    need = Math.max(1, need - 1);
    if (need > maxLines) maxLines = need;
  });
  return maxLines;
}

async function buildHwpx(st){
  if (st.doc) return buildHwpxDoc(st);   /* AI가 종이 전체를 읽은 경우 — 배너·문단·작은 표까지 함께 */
  const t = await loadTpl();
  const totalW = t.parts.total_w;
  /* 열 너비를 원본 비율로 시작해, 글자가 꺾이지 않는 최소 폭을 보장한다 (월일 열 3줄 꺾임 방지)
     사진에서 읽은 원본 너비는 그대로 잠그고(st.lockWidths) 글자 크기를 줄여 맞춘다 */
  if (!st.lockWidths) st.colWidths = fitColWidths(st, totalW);
  const widths = st.colWidths.map(w => Math.max(600, Math.round(totalW * w / 100)));
  // 폭 합 보정
  let wsum = widths.reduce((a, b) => a + b, 0);
  widths[widths.length - 1] += totalW - wsum;
  const bgs = [...new Set(st.cells.map(c => c.bg || ''))];
  const charKeys = [];
  st.cells.forEach(c => {
    let cw2 = 0; for (let k = 0; k < c.cs; k++) cw2 += widths[c.c + k] || 0;
    c._h = st.lockWidths ? shrinkH(c.text, cw2) : 900;
    const k = (c.bold ? 1 : 0) + '|' + (c.color || '') + '|' + c._h;
    if (!charKeys.includes(k)) charKeys.push(k);
  });
  const chars = charKeys.map(k => { const p = k.split('|'); return {b:p[0] === '1', color:p[1], h:(+p[2] || 900)}; });
  chars.push({b:true, color:'#111111', h:1100});
  const aligns = [...new Set(st.cells.map(c => c.align || 'C'))];
  const face = FONT_ALIAS[CUR_FONT] || CUR_FONT || '';
  const H = hwHeader(hwFont(t.text['Contents__header.xml'], face), {bgs, chars, aligns});
  const chGet = (b, color, h) => H.chId[(b ? 1 : 0) + '|' + (color || '') + '|' + (h || 900)] || 0;
  const titleChar = H.chId['1|#111111|1100'];
  const rowH = (r) => { const n = rowLines(st, r, widths, totalW); return n <= 1 ? 1150 : (n * 1100 + 300); };
  st._rowLines = [];
  for (let r = 0; r < st.nRows; r++) st._rowLines.push(rowLines(st, r, widths, totalW));
  let totalH = 0; for (let r = 0; r < st.nRows; r++) totalH += rowH(r);
  let body = '', pid = 200;
  if (st.title){
    body += `<hp:p id="${pid}" paraPrIDRef="${H.paId['C']}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0"><hp:run charPrIDRef="${titleChar ? titleChar : 1}"><hp:t>${xmlEsc(st.title)}</hp:t></hp:run></hp:p>`;
    pid++;
  }
  body += `<hp:p id="${pid}" paraPrIDRef="${H.paId['L'] || 0}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0"><hp:run charPrIDRef="0">`;
  body += `<hp:tbl id="1" zOrder="0" numberingType="NONE" textWrap="TOP_AND_BOTTOM" textFlow="BOTH_SIDES" lock="0" dropcapstyle="None" pageBreak="CELL" repeatHeader="1" rowCnt="${st.nRows}" colCnt="${st.nCols}" cellSpacing="0" borderFillIDRef="2" noAdjust="0">`;
  body += `<hp:sz width="${totalW}" widthRelTo="ABSOLUTE" height="${totalH}" heightRelTo="ABSOLUTE" protect="0"/>`;
  body += t.parts.pos + t.parts.outm + t.parts.inm;
  const byRow = {}; st.cells.forEach(c => (byRow[c.r] = byRow[c.r] || []).push(c));
  // 위쪽 행에서 내려온 병합이 덮고 있는 칸 표시(빈 칸 보충 시 겹침 방지)
  const covered = Array.from({length: st.nRows}, () => new Array(st.nCols).fill(false));
  st.cells.forEach(c => { for (let y = c.r; y < c.r + c.rs; y++) for (let x = c.c; x < c.c + c.cs; x++) if (covered[y]) covered[y][x] = true; });
  let seq = 5000;
  const blank = {bold:false, color:'', bg:'', align:'C'};
  for (let r = 0; r < st.nRows; r++){
    const list = (byRow[r] || []).sort((a, b) => a.c - b.c);
    let acc = 0;
    body += '<hp:tr>';
    for (const c of list){
      let w = 0; for (let k = 0; k < c.cs; k++) w += widths[c.c + k] || 0;
      for (let k = acc; k < c.c; k++){ // 앞쪽 빈 칸(다른 행 병합이 덮은 칸은 건너뜀)
        if (!covered[r][k]) body += hwCell(blank, r, k, 1, 1, '', widths[k], rowH(r), H, seq++);
      }
      body += hwCell(c, r, c.c, c.cs, c.rs, c.text, w, rowH(r) * c.rs, H, seq++);
      acc = c.c + c.cs;
    }
    for (let k = acc; k < st.nCols; k++){
      if (!covered[r][k]) body += hwCell(blank, r, k, 1, 1, '', widths[k], rowH(r), H, seq++);
    }
    body += '</hp:tr>';
  }
  body += '</hp:tbl></hp:run></hp:p>';
  const section = t.prefix + body + '</hs:sec>';
  return [
    {name:'mimetype', data:'application/hwp+zip', store:true},
    {name:'version.xml', data:t.text['version.xml']},
    {name:'settings.xml', data:t.text['settings.xml']},
    {name:'META-INF/manifest.xml', data:t.text['META-INF__manifest.xml']},
    {name:'META-INF/container.xml', data:t.text['META-INF__container.xml']},
    {name:'META-INF/container.rdf', data:t.text['META-INF__container.rdf']},
    {name:'Contents/content.hpf', data:t.text['Contents__content.hpf']},
    {name:'Contents/header.xml', data:H.xml},
    {name:'Contents/section0.xml', data:section}
  ];
}
function hwCell(cell, r, c, cs, rs, value, w, h, H, seq){
  const bf = cell.nb ? (H.bfId['nb|' + (cell.bg || '')] || 1) : (H.bfId[cell.bg || ''] || 2);
  const pa = H.paId[cell.align || 'C'] || 0;
  let paras = '';
  if (cell.runs && cell.runs.length){
    paras = hwRunParas(cell.runs, {b:!!cell.bold, color:cell.color || '', h:cell._h || 900}, pa, H, seq * 10);
  } else {
    const ch = H.chId[chKey(cell.bold, cell.color, cell._h || 900)] || 0;
    const lines = String(value == null ? '' : value).split('\n');
    lines.forEach((line, k) => {
      paras += `<hp:p id="${seq * 10 + k}" paraPrIDRef="${pa}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">`
        + `<hp:run charPrIDRef="${ch}">` + (line === '' ? '<hp:t/>' : `<hp:t>${xmlEsc(line)}</hp:t>`) + '</hp:run></hp:p>';
    });
  }
  const mg = cell._pad ? '<hp:cellMargin left="510" right="510" top="280" bottom="280"/>' : '<hp:cellMargin left="170" right="170" top="60" bottom="60"/>';
  return `<hp:tc name="" header="0" hasMargin="${cell._pad ? 1 : 0}" protect="0" editable="0" dirty="0" borderFillIDRef="${bf}">`
    + `<hp:subList id="" textDirection="HORIZONTAL" lineWrap="BREAK" vertAlign="CENTER" linkListIDRef="0" linkListNextIDRef="0" textWidth="0" textHeight="0" hasTextRef="0" hasNumRef="0">${paras}</hp:subList>`
    + `<hp:cellAddr colAddr="${c}" rowAddr="${r}"/><hp:cellSpan colSpan="${cs}" rowSpan="${rs}"/>`
    + `<hp:cellSz width="${w}" height="${h}"/>${mg}</hp:tc>`;
}

/* 글 조각(run) → 한글 문단들. 조각마다 글자색·굵기·형광펜(음영)·밑줄을 따로 준다 */
function runLines(runs){
  const lines = [[]];
  runs.forEach(r => String(r.text).split('\n').forEach((seg, i) => {
    if (i > 0) lines.push([]);
    if (seg !== '') lines[lines.length - 1].push(Object.assign({}, r, {text:seg}));
  }));
  return lines;
}
const runCharKey = (r, base) => chKey(base.b || r.b, r.color || base.color, base.h, r.hl, r.ul);
function hwRunParas(runs, base, pa, H, idBase){
  return runLines(runs).map((ln, k) =>
    `<hp:p id="${idBase + k}" paraPrIDRef="${pa}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">`
    + (ln.length
      ? ln.map(r => `<hp:run charPrIDRef="${H.chId[runCharKey(r, base)] || 0}"><hp:t>${xmlEsc(r.text)}</hp:t></hp:run>`).join('')
      : `<hp:run charPrIDRef="${H.chId[chKey(base.b, base.color, base.h)] || 0}"><hp:t/></hp:run>`)
    + '</hp:p>').join('');
}

/* ================= HWPX — 문서 전체(작은 표·제목 배너·문단·색 글자·형광펜·메인 표·서명) ================= */
/* 제목 배너(색 띠 안 흰 글씨)는 테두리 없는 1×1 표에 배경색을 깔아 똑같이 보이게 한다 */
function bannerTable(b){
  return {nRows:1, nCols:1, colWidths:[100], lockWidths:true, _banner:true,
    cells:[{r:0, c:0, rs:1, cs:1, text:b.runs.map(x => x.text).join(''), bold:false, align:b.align, bg:b.bg, color:'',
      nb:true, runs:b.runs, _h:Math.round(b.size * 100), _fixH:true, _pad:true}]};
}
async function buildHwpxDoc(st){
  const t = await loadTpl();
  const PW = t.parts.total_w;
  /* 1) 종이 위→아래 순서로 놓을 것들 */
  const items = [];
  st.doc.forEach(b => {
    if (b.t === 'table'){
      if (b.main){ if (!st._noMain) items.push({kind:'tbl', tst:st, x:b.x, w:b.w, main:true}); }
      else items.push({kind:'tbl', tst:b.tbl, x:b.x, w:b.w});
    } else if (b.t === 'text'){
      if (b.bg && b.runs.length) items.push({kind:'tbl', tst:bannerTable(b), x:b.x, w:b.w});
      else items.push({kind:'txt', b});
    }
  });
  /* 2) 표마다 열 너비·글자 크기·행 높이 계산 */
  const need = {bgs:[''], nbBgs:[''], chars:[], aligns:['TL', 'TC', 'TR']};
  const addChar = (b, color, h, hl, ul) => need.chars.push({b:!!b, color:color || '', h:h || 900, hl:hl || '', ul:ul || ''});
  items.forEach(it => {
    if (it.kind === 'txt'){
      const h = Math.round(it.b.size * 100);
      addChar(false, '', h);
      it.b.runs.forEach(r => addChar(r.b, r.color, h, r.hl, r.ul));
      return;
    }
    const tst = it.tst;
    const tw = Math.max(3000, Math.round(PW * (it.w || 100) / 100));
    if (it.main && !tst.lockWidths) tst.colWidths = fitColWidths(tst, tw);
    const widths = tst.colWidths.map(w => Math.max(600, Math.round(tw * w / 100)));
    widths[widths.length - 1] += tw - widths.reduce((a, b) => a + b, 0);
    it.tw = tw; it.widths = widths;
    it.off = Math.max(0, Math.min(PW - tw, Math.round(PW * (it.x || 0) / 100)));
    tst.cells.forEach(c => {
      let cw2 = 0; for (let k = 0; k < c.cs; k++) cw2 += widths[c.c + k] || 0;
      if (!c._fixH) c._h = tst.lockWidths ? shrinkH(c.text, cw2) : 900;
      if (c.nb) need.nbBgs.push(c.bg || ''); else need.bgs.push(c.bg || '');
      need.aligns.push(c.align || 'C');
      const base = {b:!!c.bold, color:c.color || '', h:c._h};
      addChar(base.b, base.color, base.h);
      (c.runs || []).forEach(r => addChar(base.b || r.b, r.color || base.color, base.h, r.hl, r.ul));
    });
    it.rowH = [];
    for (let r = 0; r < tst.nRows; r++){
      const n = rowLines(tst, r, widths, tw);
      let hMax = 900;
      tst.cells.forEach(c => { if (c.r === r && c.rs === 1) hMax = Math.max(hMax, c._h || 900); });
      let h = n <= 1 ? 1150 : (n * 1100 + 300);
      if (hMax > 900) h = Math.max(h, n * Math.round(hMax * 1.35) + (tst._banner ? 900 : 400));
      it.rowH.push(h);
    }
  });
  const face = FONT_ALIAS[CUR_FONT] || CUR_FONT || '';
  const H = hwHeader(hwFont(t.text['Contents__header.xml'], face), {
    bgs:[...new Set(need.bgs)], nbBgs:[...new Set(need.nbBgs)], chars:need.chars, aligns:[...new Set(need.aligns)]});
  /* 3) 본문 */
  let body = '', pid = 200, seq = 5000, tblId = 1;
  for (const it of items){
    if (it.kind === 'txt'){
      const b = it.b, h = Math.round(b.size * 100);
      const pa = H.paId['T' + b.align] || 0;
      body += b.runs.length ? hwRunParas(b.runs, {b:false, color:'', h}, pa, H, pid * 10)
        : `<hp:p id="${pid * 10}" paraPrIDRef="${pa}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0"><hp:run charPrIDRef="${H.chId[chKey(false, '', h)] || 0}"><hp:t/></hp:run></hp:p>`;
      pid++;
      continue;
    }
    const tst = it.tst, widths = it.widths, rowH = r => it.rowH[r];
    let totalH = 0; for (let r = 0; r < tst.nRows; r++) totalH += rowH(r);
    body += `<hp:p id="${pid * 10}" paraPrIDRef="${H.paId['L'] || H.paId['TL'] || 0}" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0"><hp:run charPrIDRef="0">`;
    pid++;
    body += `<hp:tbl id="${tblId++}" zOrder="0" numberingType="NONE" textWrap="TOP_AND_BOTTOM" textFlow="BOTH_SIDES" lock="0" dropcapstyle="None" pageBreak="CELL" repeatHeader="1" rowCnt="${tst.nRows}" colCnt="${tst.nCols}" cellSpacing="0" borderFillIDRef="${tst._banner ? 1 : 2}" noAdjust="0">`;
    body += `<hp:sz width="${it.tw}" widthRelTo="ABSOLUTE" height="${totalH}" heightRelTo="ABSOLUTE" protect="0"/>`;
    body += t.parts.pos.replace('horzOffset="0"', `horzOffset="${it.off}"`) + t.parts.outm + t.parts.inm;
    const byRow = {}; tst.cells.forEach(c => (byRow[c.r] = byRow[c.r] || []).push(c));
    const covered = Array.from({length: tst.nRows}, () => new Array(tst.nCols).fill(false));
    tst.cells.forEach(c => { for (let y = c.r; y < c.r + c.rs; y++) for (let x = c.c; x < c.c + c.cs; x++) if (covered[y]) covered[y][x] = true; });
    const blank = {bold:false, color:'', bg:'', align:'C'};
    for (let r = 0; r < tst.nRows; r++){
      const list = (byRow[r] || []).sort((a, b) => a.c - b.c);
      let acc = 0;
      body += '<hp:tr>';
      for (const c of list){
        let w = 0; for (let k = 0; k < c.cs; k++) w += widths[c.c + k] || 0;
        let h = 0; for (let k = 0; k < c.rs; k++) h += rowH(r + k) || rowH(r);
        for (let k = acc; k < c.c; k++) if (!covered[r][k]) body += hwCell(blank, r, k, 1, 1, '', widths[k], rowH(r), H, seq++);
        body += hwCell(c, r, c.c, c.cs, c.rs, c.text, w, h, H, seq++);
        acc = c.c + c.cs;
      }
      for (let k = acc; k < tst.nCols; k++) if (!covered[r][k]) body += hwCell(blank, r, k, 1, 1, '', widths[k], rowH(r), H, seq++);
      body += '</hp:tr>';
    }
    body += '</hp:tbl></hp:run></hp:p>';
  }
  const section = t.prefix + body + '</hs:sec>';
  return [
    {name:'mimetype', data:'application/hwp+zip', store:true},
    {name:'version.xml', data:t.text['version.xml']},
    {name:'settings.xml', data:t.text['settings.xml']},
    {name:'META-INF/manifest.xml', data:t.text['META-INF__manifest.xml']},
    {name:'META-INF/container.xml', data:t.text['META-INF__container.xml']},
    {name:'META-INF/container.rdf', data:t.text['META-INF__container.rdf']},
    {name:'Contents/content.hpf', data:t.text['Contents__content.hpf']},
    {name:'Contents/header.xml', data:H.xml},
    {name:'Contents/section0.xml', data:section}
  ];
}
/* ===== converter.html 엔진 복사본 끝 ===== */
