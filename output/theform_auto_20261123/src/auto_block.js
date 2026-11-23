
/* ---------- ⚡ 1클릭 자동 빈칸 (적립 146번) — 캔버스 픽셀 분석만 · 외부 요청 0 ----------
   조명 정규화 → 잉크 마스크 → 가로·세로 괘선 → (가) 밑줄 위 빈칸 · (나) 표 빈 칸 · (다) 글자 칸 안 넓은 여백 → 겹침 정리 */
const AUTO_CFG = {ink:170, hRun:40, vRun:30, lineT:4, ulInk:.025, cellInk:.015};
function autoDetectFields(){
  const t0 = performance.now();
  const W0 = bgW(), H0 = bgH(), SW = Math.min(1000, W0), SH = Math.round(SW * H0 / W0), N = SW * SH, sc = SW / 1000;
  const cv = document.createElement('canvas'); cv.width = SW; cv.height = SH;
  const g = cv.getContext('2d', {willReadFrequently:true}); g.fillStyle = '#fff'; g.fillRect(0, 0, SW, SH); g.drawImage(BG, 0, 0, SW, SH);
  const px = g.getImageData(0, 0, SW, SH).data, L = new Float32Array(N);
  for (let i = 0, j = 0; i < N; i++, j += 4) L[i] = .299 * px[j] + .587 * px[j + 1] + .114 * px[j + 2];
  /* 1) 조명 정규화 — 블록별 80퍼센타일 = 종이 밝기 → 3×3 평균 → 선형 보간 */
  const BS = Math.max(16, Math.round(Math.min(SW, SH) / 12)), bx = Math.ceil(SW / BS), by = Math.ceil(SH / BS), blk = new Float32Array(bx * by), hist = new Uint32Array(256);
  for (let j = 0; j < by; j++) for (let i = 0; i < bx; i++){
    hist.fill(0); let n = 0;
    for (let y = j * BS; y < Math.min(SH, (j + 1) * BS); y += 2) for (let x = i * BS; x < Math.min(SW, (i + 1) * BS); x += 2){ hist[L[y * SW + x] | 0]++; n++; }
    let k = 0, c = 0; const need = n * .8; while (k < 255 && c + hist[k] < need) c += hist[k++];
    blk[j * bx + i] = k;
  }
  const blk2 = new Float32Array(bx * by);
  for (let j = 0; j < by; j++) for (let i = 0; i < bx; i++){ let s = 0, n = 0;
    for (let dj = -1; dj <= 1; dj++) for (let di = -1; di <= 1; di++){ const a = i + di, b = j + dj; if (a >= 0 && b >= 0 && a < bx && b < by){ s += blk[b * bx + a]; n++; } }
    blk2[j * bx + i] = s / n; }
  const ink = new Uint8Array(N);
  for (let y = 0; y < SH; y++){
    const fy = Math.max(0, Math.min(by - 1, (y + .5) / BS - .5)), y0 = Math.floor(fy), y1 = Math.min(by - 1, y0 + 1), ty = fy - y0;
    for (let x = 0; x < SW; x++){
      const fx = Math.max(0, Math.min(bx - 1, (x + .5) / BS - .5)), x0 = Math.floor(fx), x1 = Math.min(bx - 1, x0 + 1), tx = fx - x0;
      const m = (blk2[y0 * bx + x0] * (1 - tx) + blk2[y0 * bx + x1] * tx) * (1 - ty) + (blk2[y1 * bx + x0] * (1 - tx) + blk2[y1 * bx + x1] * tx) * ty;
      const i = y * SW + x; if (Math.min(255, L[i] * 235 / Math.max(20, m)) < AUTO_CFG.ink) ink[i] = 1;
    }
  }
  /* 적분 영상 — 사각형 안 잉크 수를 바로 잰다 */
  const II = new Uint32Array((SW + 1) * (SH + 1));
  for (let y = 0; y < SH; y++){ let r = 0; for (let x = 0; x < SW; x++){ r += ink[y * SW + x]; II[(y + 1) * (SW + 1) + x + 1] = II[y * (SW + 1) + x + 1] + r; } }
  const inkIn = (x0, y0, x1, y1) => (x1 < x0 || y1 < y0) ? 0 : II[(y1 + 1) * (SW + 1) + x1 + 1] - II[y0 * (SW + 1) + x1 + 1] - II[(y1 + 1) * (SW + 1) + x0] + II[y0 * (SW + 1) + x0];
  /* 2) 괘선 — 연속 run 을 이웃 줄과 묶어 두께 1~lineT 만 선으로(더 두꺼우면 글씨·도장) */
  const lineT = Math.max(AUTO_CFG.lineT, Math.round(AUTO_CFG.lineT * sc));
  function lines(horiz){
    const A = horiz ? SH : SW, B = horiz ? SW : SH, minRun = Math.round((horiz ? AUTO_CFG.hRun : AUTO_CFG.vRun) * sc);
    const out = []; let act = [];
    for (let a = 0; a < A; a++){
      const runs = []; let s = -1;
      for (let b = 0; b <= B; b++){ const v = b < B && (horiz ? ink[a * SW + b] : ink[b * SW + a]);
        if (v){ if (s < 0) s = b; } else if (s >= 0){ if (b - s >= minRun) runs.push([s, b - 1]); s = -1; } }
      const nx = [];
      runs.forEach(([s0, s1]) => {
        const k = act.findIndex(q => q.a1 === a - 1 && Math.min(q.b1, s1) - Math.max(q.b0, s0) > .5 * Math.min(q.b1 - q.b0, s1 - s0));
        if (k >= 0){ const q = act.splice(k, 1)[0]; q.a1 = a; q.b0 = Math.min(q.b0, s0); q.b1 = Math.max(q.b1, s1); nx.push(q); }
        else nx.push({a0:a, a1:a, b0:s0, b1:s1});
      });
      act.forEach(q => out.push(q)); act = nx;
    }
    act.forEach(q => out.push(q));
    return out.filter(q => q.a1 - q.a0 + 1 <= lineT).map(q => ({a:Math.round((q.a0 + q.a1) / 2), a0:q.a0, a1:q.a1, b0:q.b0, b1:q.b1}));
  }
  const HL = lines(true), VL = lines(false);   /* HL: a=y, b=x · VL: a=x, b=y */
  const cand = [], tol = Math.max(3, Math.round(3 * sc)), m = Math.max(3, Math.round(3 * sc));
  const minW = .035 * SW, minH = .012 * SH, hMax = Math.round(.045 * SH), gapW = .05 * SW;
  const push = (x0, y0, x1, y1, k) => { if (x1 - x0 >= .03 * SW && y1 - y0 >= minH) cand.push({x0, y0, x1, y1, k}); };
  /* (다) 글자가 있는 칸 안의 넓은 빈 구간 — 세로 투영에서 잉크 없는 열이 gapW 이상 이어진 곳 */
  function gaps(x0, y0, x1, y1){
    let s = -1; const res = [];
    for (let x = x0; x <= x1 + 1; x++){
      const e = x <= x1 && inkIn(x, y0, x, y1) === 0;
      if (e){ if (s < 0) s = x; } else { if (s >= 0 && x - s >= gapW) res.push([s, x - 1]); s = -1; }
    }
    res.forEach(([a, b]) => push(a + 2, y0, b - 2, y1, 'gap'));
  }
  HL.forEach(h => {
    const y = h.a0;
    const cross = VL.filter(v => v.a >= h.b0 - tol && v.a <= h.b1 + tol && v.b0 <= h.a1 + tol && v.b1 >= y - tol);
    const xs = [h.b0].concat(cross.map(v => v.a).sort((p, q) => p - q), [h.b1]);
    const vAt = x => cross.find(v => Math.abs(v.a - x) <= tol && v.b0 < y - minH);
    for (let k = 0; k + 1 < xs.length; k++){
      const a = xs[k], b = xs[k + 1]; if (b - a < minW) continue;
      const va = vAt(a), vb = vAt(b);
      if (va && vb){                                              /* (나) 표 칸 — 위쪽 가로선 찾기 */
        let top = null;
        HL.forEach(u => { if (u.a1 < y - minH && u.b0 <= a + tol && u.b1 >= b - tol && (!top || u.a1 > top.a1)) top = u; });
        if (!top || va.b0 > top.a1 + tol || vb.b0 > top.a1 + tol) continue;
        const cx0 = a + m, cx1 = b - m, cy0 = top.a1 + m, cy1 = y - m;
        if (cy1 - cy0 > .25 * SH) continue;
        const area = (cx1 - cx0 + 1) * (cy1 - cy0 + 1); if (area <= 0) continue;
        if (inkIn(cx0, cy0, cx1, cy1) / area < AUTO_CFG.cellInk) push(cx0, cy0, cx1, cy1, 'cell');
        else gaps(cx0, cy0, cx1, cy1);
      } else if (!cross.length && b - a < .75 * SW){              /* (가) 밑줄 위 빈칸 */
        let top = y - hMax;
        for (let yy = y - 2; yy >= Math.max(0, y - hMax); yy--){ if (inkIn(a + m, yy, b - m, yy) >= 2){ top = yy + 1; break; } }
        top = Math.max(0, top);
        const area = (b - a + 1) * (y - top);
        if (area > 0 && inkIn(a, top, b, y - 1) / area < AUTO_CFG.ulInk) push(a, top, b, y - 1, 'line');
      }
    }
  });
  /* 3) 겹침 정리(IoU>.45 합침 · 넓은 쪽 유지) · 기존 칸과 IoU>.3 이면 버림 · % 변환 · 최대 200칸 */
  const iou = (p, q) => { const ix = Math.max(0, Math.min(p.x + p.w, q.x + q.w) - Math.max(p.x, q.x)), iy = Math.max(0, Math.min(p.y + p.h, q.y + q.h) - Math.max(p.y, q.y)), I = ix * iy; return I / (p.w * p.h + q.w * q.h - I || 1); };
  const r2 = v => Math.round(v * 100) / 100;
  const P = cand.map(c => ({x:r2(c.x0 / SW * 100), y:r2(c.y0 / SH * 100), w:r2((c.x1 - c.x0) / SW * 100), h:r2((c.y1 - c.y0) / SH * 100), k:c.k}))
    .filter(f => f.w >= 3 && f.h >= 1.2).sort((p, q) => q.w * q.h - p.w * p.h);
  const keep = [];
  P.forEach(f => { if (!keep.some(q => iou(f, q) > .45)) keep.push(f); });
  const old = CUR.fields.slice();
  const fin = keep.filter(f => !old.some(o => iou(f, o) > .3)).sort((p, q) => (Math.abs(p.y - q.y) < 1 ? p.x - q.x : p.y - q.y)).slice(0, 200);
  const ms = Math.round(performance.now() - t0);
  return {fields:fin, ms, SW, SH, nH:HL.length, nV:VL.length, kinds:fin.reduce((o, f) => (o[f.k] = (o[f.k] || 0) + 1, o), {})};
}
function runAutoDetect(){
  if (!CUR) return toast('먼저 양식을 열어 주세요');
  if (ro()) return toast('기본 양식은 이미 빈칸이 잡혀 있습니다 · 내 양식에서 쓰세요');
  if (!BG || BG instanceof HTMLCanvasElement) return toast('사진으로 등록한 양식에서 씁니다');
  const b = $('#autoF'); b.disabled = true; b.textContent = '자동으로 찾는 중…';
  setTimeout(() => {
    let r = null;
    try{ r = autoDetectFields(); }catch(e){ toast('자동으로 찾지 못했습니다'); }
    b.disabled = false; b.textContent = '⚡ 1클릭 자동 빈칸';
    if (!r) return;
    window.TF_AUTO_LAST = {ms:r.ms, n:r.fields.length, SW:r.SW, SH:r.SH, nH:r.nH, nV:r.nV, kinds:r.kinds};
    if (!r.fields.length){ drawEditor(); return toast('찾은 빈칸이 없습니다 · 빈 곳을 눌러 손으로 찍어 주세요'); }
    snap();
    let n = CUR.fields.filter(f => f.type !== 'erase').length;
    r.fields.forEach(f => CUR.fields.push({id:uid(), label:'칸' + (++n), type:'text', x:f.x, y:f.y, w:f.w, h:f.h, _auto:1}));
    SEL = -1; drawEditor();
    toast(`자동으로 ${r.fields.length}칸을 찾았습니다 · 틀린 칸은 ✕로 지우세요`);
  }, 30);
}
function updAutoBar(){
  const bar = $('#autoBar'); if (!bar) return;
  const n = CUR ? CUR.fields.filter(f => f._auto).length : 0;
  bar.style.display = n ? 'flex' : 'none';
  $('#autoN').textContent = n;
}
$('#autoF').onclick = runAutoDetect;
$('#autoClr').onclick = () => {
  if (!CUR || !CUR.fields.some(f => f._auto)) return;
  snap(); CUR.fields = CUR.fields.filter(f => !f._auto); SEL = -1; drawEditor(); toast('자동으로 찾은 칸을 모두 지웠습니다 · [되돌리기]로 복구');
};

/* ---------- 💾 내 양식 프리셋 — 칸 배치만 저장(값·서명 0건) · tf_presets_v1 · 최대 12개 ---------- */
const LS_PRESET = 'tf_presets_v1';
const myPresets = () => lsGet(LS_PRESET, []);
function renderPresets(){
  const box = $('#psList'); if (!box) return;
  const a = myPresets();
  box.innerHTML = a.length ? a.map((p, i) => `<div class="psi"><div class="pn">${escH(p.name)}<small>${p.n}칸 · 저장 ${escH(String(p.at || '').slice(0, 10))}</small></div><button type="button" data-pload="${i}">불러오기</button><button type="button" data-pdel="${i}">지우기</button></div>`).join('')
    : '<p class="kv" style="margin:6px 0 0">저장한 프리셋이 없습니다. 칸을 다 찍은 뒤 이름을 적고 [저장]을 누르세요.</p>';
}
function savePreset(){
  if (!CUR) return toast('먼저 양식을 열어 주세요');
  if (ro()) return toast('기본 양식은 [복제] 후 쓰세요');
  /* 지운 자리(erase·_add)는 종이마다 다르므로 빼고, 자동 칸도 손님이 남긴 것이면 배치로 저장한다 */
  const fs = CUR.fields.filter(f => !f._add && f.type !== 'erase').map(f => ({label:f.label, type:f.type, x:f.x, y:f.y, w:f.w, h:f.h}));
  if (!fs.length) return toast('저장할 칸이 없습니다 · 칸을 먼저 찍어 주세요');
  const name = $('#psName').value.trim(); if (!name){ $('#psName').focus(); return toast('프리셋 이름을 적어 주세요'); }
  let a = myPresets(); const k = a.findIndex(p => p.name === name);
  if (k >= 0){ if (!confirm('같은 이름이 있습니다. 덮어쓸까요?')) return; a.splice(k, 1); }
  a.unshift({id:uid(), name, n:fs.length, w:bgW(), h:bgH(), at:new Date().toISOString().slice(0, 10), fields:fs});
  if (a.length > 12) a = a.slice(0, 12);
  if (!lsSet(LS_PRESET, a)) return;
  $('#psName').value = ''; renderPresets(); drawEditor(); toast(`프리셋 "${name}" 저장 · ${fs.length}칸`);
}
function loadPreset(i){
  if (!CUR) return toast('먼저 양식을 열어 주세요');
  if (ro()) return toast('기본 양식은 [복제] 후 쓰세요');
  const p = myPresets()[i]; if (!p) return;
  const r0 = p.w / p.h, r1 = bgW() / bgH();
  if (Math.abs(r1 - r0) / r0 > .08 && !confirm('종이 비율이 조금 다릅니다. 그래도 이 배치를 얹을까요?')) return;
  const n = CUR.fields.length;
  if (n && !confirm(`지금 칸 ${n}개를 프리셋 배치(${p.fields.length}개)로 바꿉니다. 되돌리기 1번이면 원래대로 돌아옵니다.`)) return;
  snap(); CUR.fields = p.fields.map(f => Object.assign({id:uid()}, f)); SEL = -1; drawEditor();
  toast(`프리셋 배치를 얹었습니다 · ${p.fields.length}칸`);
}
$('#psSave').onclick = savePreset;
$('#psList').onclick = e => {
  const b = e.target.closest('button'); if (!b) return;
  if (b.dataset.pload != null) loadPreset(+b.dataset.pload);
  else if (b.dataset.pdel != null){ if (!confirm('이 프리셋을 지울까요?')) return; const a = myPresets(); a.splice(+b.dataset.pdel, 1); lsSet(LS_PRESET, a); renderPresets(); if (CUR) drawEditor(); }
};
