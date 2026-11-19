/* ===== 부동산 공통 도우미 (10차 listingcompare 재사용): 평↔㎡ · "9억 5000" 읽기 · 만원 표기 ===== */
const PY = 3.3058;
function areaOf(s){ s = String(s || ''); const v = parseFloat(s.replace(/[^\d.]/g, '')); if (!isFinite(v)) return null; return /평/.test(s) ? {py:v, m2:v * PY} : {py:v / PY, m2:v}; }
/* 만원 단위로 읽기: "9억 5000" → 95000, "3억5천" → 35000, "12억" → 120000, "52000" → 52000, "1,250만" → 1250 */
function manOf(s){ s = String(s == null ? '' : s).replace(/[,\s원]/g, '').replace(/천만?$/, m => m); if (!s) return NaN;
  let m = /^(?:(\d+(?:\.\d+)?)억)?(?:(\d+(?:\.\d+)?)(천만|천|백만|만)?)?$/.exec(s); if (!m || (!m[1] && !m[2])) return NaN;
  let v = m[1] ? parseFloat(m[1]) * 10000 : 0; if (m[2]){ const u = m[3] || ''; v += parseFloat(m[2]) * ({'천만':1000, '천':1000, '백만':100, '만':1, '':1}[u]); } return v; }
const manTxt = v => isFinite(v) ? (Math.abs(v) >= 10000 ? (v < 0 ? '−' : '') + Math.floor(Math.abs(v) / 10000) + '억' + (Math.round(Math.abs(v) % 10000) ? ' ' + Math.round(Math.abs(v) % 10000).toLocaleString('ko-KR') : '') : won(v)) + '만원' : '-';
const median = a => { const s = a.slice().sort((x, y) => x - y), n = s.length; return n ? (n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2) : NaN; };
