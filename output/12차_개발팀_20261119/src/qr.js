/* ===== KTS 순수 JS QR 인코더 (외부 라이브러리 0 · 바이트 모드 · 오류정정 L/M/Q/H · 버전 1~40 · 마스크 자동)
   구조는 공개 알고리즘(ISO/IEC 18004)을 따름. 사용: const m = QRgen('텍스트', 'L') → {size, get(x,y), version} ===== */
const QRgen = (() => {
  const ECW = [ // 블록당 오류정정 코드워드 [L,M,Q,H][버전]
    [-1,7,10,15,20,26,18,20,24,30,18,20,24,26,30,22,24,28,30,28,28,28,28,30,30,26,28,30,30,30,30,30,30,30,30,30,30,30,30,30,30],
    [-1,10,16,26,18,24,16,18,22,22,26,30,22,22,24,24,28,28,26,26,26,26,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28],
    [-1,13,22,18,26,18,24,18,22,20,24,28,26,24,20,30,24,28,28,26,30,28,30,30,30,30,28,30,30,30,30,30,30,30,30,30,30,30,30,30,30],
    [-1,17,28,22,16,22,28,26,26,24,28,24,28,22,24,24,30,28,28,26,28,30,24,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30]];
  const NB = [ // 오류정정 블록 수
    [-1,1,1,1,1,1,2,2,2,2,4,4,4,4,4,6,6,6,6,7,8,8,9,9,10,12,12,12,13,14,15,16,17,18,19,19,20,21,22,24,25],
    [-1,1,1,1,2,2,4,4,4,5,5,5,8,9,9,10,10,11,13,14,16,17,17,18,20,21,23,25,26,28,29,31,33,35,37,38,40,43,45,47,49],
    [-1,1,1,2,2,4,4,6,6,8,8,8,10,12,16,12,17,16,18,21,20,23,23,25,27,29,34,34,35,38,40,43,45,48,51,53,56,59,62,65,68],
    [-1,1,1,2,4,4,4,5,6,8,8,11,11,16,16,18,16,19,21,25,25,25,34,30,32,35,37,40,42,45,48,51,54,57,60,63,66,70,74,77,81]];
  const EI = {L:0, M:1, Q:2, H:3}, FMT = {L:1, M:0, Q:3, H:2};
  function rawModules(v){ let r = (16 * v + 128) * v + 64; if (v >= 2){ const n = Math.floor(v / 7) + 2; r -= (25 * n - 10) * n - 55; if (v >= 7) r -= 36; } return r; }
  const dataCW = (v, e) => Math.floor(rawModules(v) / 8) - ECW[e][v] * NB[e][v];
  function rsDiv(deg){ const r = new Array(deg).fill(0); r[deg - 1] = 1; let root = 1;
    for (let i = 0; i < deg; i++){ for (let j = 0; j < r.length; j++){ r[j] = mul(r[j], root); if (j + 1 < r.length) r[j] ^= r[j + 1]; } root = mul(root, 2); } return r; }
  function mul(x, y){ let z = 0; for (let i = 7; i >= 0; i--){ z = (z << 1) ^ ((z >>> 7) * 0x11D); z ^= ((y >>> i) & 1) * x; } return z & 0xFF; }
  function rsRem(data, div){ const r = div.map(() => 0); for (const b of data){ const f = b ^ r.shift(); r.push(0); div.forEach((c, i) => r[i] ^= mul(c, f)); } return r; }
  function align(v){ if (v === 1) return []; const n = Math.floor(v / 7) + 2, step = (v === 32) ? 26 : Math.ceil((v * 4 + 4) / (n * 2 - 2)) * 2; const r = [6]; for (let p = v * 4 + 10; r.length < n; p -= step) r.splice(1, 0, p); return r; }
  return function(text, ecl){
    ecl = ecl || 'M'; const e = EI[ecl]; const bytes = Array.from(new TextEncoder().encode(String(text)));
    let v = 1; for (; v <= 40; v++){ const cc = v < 10 ? 8 : 16; if (4 + cc + bytes.length * 8 <= dataCW(v, e) * 8) break; }
    if (v > 40) throw new Error('QR_TOO_LONG');
    const bits = []; const put = (val, n) => { for (let i = n - 1; i >= 0; i--) bits.push((val >>> i) & 1); };
    put(4, 4); put(bytes.length, v < 10 ? 8 : 16); bytes.forEach(b => put(b, 8));
    const cap = dataCW(v, e) * 8; put(0, Math.min(4, cap - bits.length)); put(0, (8 - bits.length % 8) % 8);
    for (let p = 0xEC; bits.length < cap; p ^= 0xEC ^ 0x11) put(p, 8);
    const data = []; for (let i = 0; i < bits.length; i += 8){ let b = 0; for (let j = 0; j < 8; j++) b = (b << 1) | bits[i + j]; data.push(b); }
    /* 블록 나누기 + 오류정정 + 섞기 */
    const nb = NB[e][v], ecLen = ECW[e][v], raw = Math.floor(rawModules(v) / 8), nShort = nb - raw % nb, shortLen = Math.floor(raw / nb);
    const blocks = [], div = rsDiv(ecLen);
    for (let i = 0, k = 0; i < nb; i++){ const dl = shortLen - ecLen + (i < nShort ? 0 : 1); const d = data.slice(k, k + dl); k += dl; const ec = rsRem(d, div); if (i < nShort) d.push(0); blocks.push(d.concat(ec)); }
    const all = []; for (let i = 0; i < blocks[0].length; i++) blocks.forEach((b, j) => { if (i !== shortLen - ecLen || j >= nShort) all.push(b[i]); });
    /* 모듈 배치 */
    const size = v * 4 + 17, M = [], F = []; for (let i = 0; i < size; i++){ M.push(new Array(size).fill(false)); F.push(new Array(size).fill(false)); }
    const set = (x, y, d) => { M[y][x] = d; F[y][x] = true; };
    for (let i = 0; i < size; i++){ set(6, i, i % 2 === 0); set(i, 6, i % 2 === 0); }
    const finder = (cx, cy) => { for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++){ const d = Math.max(Math.abs(dx), Math.abs(dy)), x = cx + dx, y = cy + dy; if (x >= 0 && x < size && y >= 0 && y < size) set(x, y, d !== 2 && d !== 4); } };
    finder(3, 3); finder(size - 4, 3); finder(3, size - 4);
    const ap = align(v); ap.forEach((a, i) => ap.forEach((b, j) => { if ((i === 0 && j === 0) || (i === 0 && j === ap.length - 1) || (i === ap.length - 1 && j === 0)) return; for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) set(a + dx, b + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1); }));
    const drawFormat = mask => { const d = FMT[ecl] << 3 | mask; let r = d; for (let i = 0; i < 10; i++) r = (r << 1) ^ ((r >>> 9) * 0x537); const b = (d << 10 | r) ^ 0x5412; const g = i => ((b >>> i) & 1) !== 0;
      for (let i = 0; i <= 5; i++) set(8, i, g(i)); set(8, 7, g(6)); set(8, 8, g(7)); set(7, 8, g(8)); for (let i = 9; i < 15; i++) set(14 - i, 8, g(i));
      for (let i = 0; i < 8; i++) set(size - 1 - i, 8, g(i)); for (let i = 8; i < 15; i++) set(8, size - 15 + i, g(i)); set(8, size - 8, true); };
    drawFormat(0);
    if (v >= 7){ let r = v; for (let i = 0; i < 12; i++) r = (r << 1) ^ ((r >>> 11) * 0x1F25); const b = v << 12 | r; for (let i = 0; i < 18; i++){ const bit = ((b >>> i) & 1) !== 0, a = size - 11 + i % 3, c = Math.floor(i / 3); set(a, c, bit); set(c, a, bit); } }
    let i = 0; for (let right = size - 1; right >= 1; right -= 2){ if (right === 6) right = 5; for (let vert = 0; vert < size; vert++) for (let j = 0; j < 2; j++){ const x = right - j, up = ((right + 1) & 2) === 0, y = up ? size - 1 - vert : vert; if (!F[y][x] && i < all.length * 8){ M[y][x] = ((all[i >>> 3] >>> (7 - (i & 7))) & 1) !== 0; i++; } } }
    const MK = [(x, y) => (x + y) % 2 === 0, (x, y) => y % 2 === 0, (x, y) => x % 3 === 0, (x, y) => (x + y) % 3 === 0, (x, y) => (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0, (x, y) => x * y % 2 + x * y % 3 === 0, (x, y) => (x * y % 2 + x * y % 3) % 2 === 0, (x, y) => ((x + y) % 2 + x * y % 3) % 2 === 0];
    const applyMask = k => { for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) if (!F[y][x] && MK[k](x, y)) M[y][x] = !M[y][x]; };
    const penalty = () => { let p = 0; const line = get => { for (let a = 0; a < size; a++){ let run = 1; const seq = [get(a, 0)]; for (let b = 1; b < size; b++){ const c = get(a, b); seq.push(c); if (c === get(a, b - 1)){ run++; if (run === 5) p += 3; else if (run > 5) p++; } else run = 1; }
        const s = seq.map(Number).join(''); let k = -1; while ((k = s.indexOf('1011101', k + 1)) >= 0){ if (s.slice(Math.max(0, k - 4), k) === '0000' && k >= 4 || s.slice(k + 7, k + 11) === '0000') p += 40; } } };
      line((a, b) => M[a][b]); line((a, b) => M[b][a]);
      for (let y = 0; y < size - 1; y++) for (let x = 0; x < size - 1; x++){ const c = M[y][x]; if (c === M[y][x + 1] && c === M[y + 1][x] && c === M[y + 1][x + 1]) p += 3; }
      let dark = 0; M.forEach(r => r.forEach(c => dark += c ? 1 : 0)); const t = size * size; p += (Math.ceil(Math.abs(dark * 20 - t * 10) / t) - 1) * 10; return p; };
    let best = 0, bp = Infinity; for (let k = 0; k < 8; k++){ applyMask(k); drawFormat(k); const p = penalty(); if (p < bp){ bp = p; best = k; } applyMask(k); }
    applyMask(best); drawFormat(best);
    return {size, version:v, ecl, mask:best, bytes:bytes.length, get:(x, y) => x >= 0 && y >= 0 && x < size && y < size && M[y][x]};
  };
})();
/* QR → SVG 문자열 (조용한 영역 4칸) */
function qrSVG(q, px){ const n = q.size + 8, s = px || 4; let d = ''; for (let y = 0; y < q.size; y++) for (let x = 0; x < q.size; x++) if (q.get(x, y)) d += `M${x + 4} ${y + 4}h1v1h-1z`; return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${n} ${n}" width="${n * s}" height="${n * s}" shape-rendering="crispEdges"><rect width="100%" height="100%" fill="#fff"/><path d="${d}" fill="#000"/></svg>`; }
