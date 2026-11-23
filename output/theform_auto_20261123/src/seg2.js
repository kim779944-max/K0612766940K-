  /* 2) 괘선 — 연속 run(점선은 짧은 틈 허용)을 이웃 줄과 묶어 두께 1~lineT 만 선으로(더 두꺼우면 글씨·도장) */
  const lineT = Math.max(AUTO_CFG.lineT, Math.round(AUTO_CFG.lineT * sc));
  function lines(horiz, minRun, gapTol){
    const A = horiz ? SH : SW, B = horiz ? SW : SH;
    const out = []; let act = [];
    for (let a = 0; a < A; a++){
      const runs = []; let s = -1, e = -1, cnt = 0;
      for (let b = 0; b <= B; b++){ const v = b < B && (horiz ? ink[a * SW + b] : ink[b * SW + a]);
        if (v){ if (s < 0){ s = b; cnt = 0; } e = b; cnt++; }
        else if (s >= 0 && (b >= B || b - e > gapTol)){ if (e - s + 1 >= minRun && cnt / (e - s + 1) >= .18) runs.push([s, e, cnt]); s = -1; } }
      const nx = [];
      runs.forEach(([s0, s1, c]) => {
        const k = act.findIndex(q => q.a1 === a - 1 && Math.min(q.b1, s1) - Math.max(q.b0, s0) > .5 * Math.min(q.b1 - q.b0, s1 - s0));
        if (k >= 0){ const q = act.splice(k, 1)[0]; q.a1 = a; q.b0 = Math.min(q.b0, s0); q.b1 = Math.max(q.b1, s1); q.c += c; nx.push(q); }
        else nx.push({a0:a, a1:a, b0:s0, b1:s1, c});
      });
      act.forEach(q => out.push(q)); act = nx;
    }
    act.forEach(q => out.push(q));
    return out.filter(q => q.a1 - q.a0 + 1 <= lineT).map(q => ({a:Math.round((q.a0 + q.a1) / 2), a0:q.a0, a1:q.a1, b0:q.b0, b1:q.b1, d:q.c / ((q.b1 - q.b0 + 1) * (q.a1 - q.a0 + 1))}));
  }
  const tol = Math.max(3, Math.round(3 * sc)), m = Math.max(2, Math.round(2 * sc));
  const HL = lines(true, Math.round(AUTO_CFG.hRun * sc), 0), VL = lines(false, Math.round(AUTO_CFG.vRun * sc), 0);   /* HL: a=y, b=x · VL: a=x, b=y */
  /* 점선(특약사항 줄 등) — 6px 이하 틈을 이어 붙여 폭 30% 이상, 실선과 겹치지 않는 것 */
  const DL = lines(true, Math.round(.3 * SW), Math.round(6 * sc)).filter(d => d.d < .85 && !HL.some(h => Math.abs(h.a - d.a) <= tol && Math.min(h.b1, d.b1) - Math.max(h.b0, d.b0) > .5 * (d.b1 - d.b0)));
  const cand = [];
  const minW = .035 * SW, minH = .012 * SH, hMax = Math.round(.045 * SH), ulH = Math.round(.028 * SH), gapW = .05 * SW;
  const push = (x0, y0, x1, y1, k) => { if (x1 - x0 >= .03 * SW && y1 - y0 >= minH) cand.push({x0, y0, x1, y1, k}); };
  /* (다) 글자가 있는 칸 안의 넓은 빈 구간 — 양옆에 글자가 있는 빈 열 구간(gapW 이상)만. 글자 두 개 사이를 띄운 머리글('주   소')은 뺀다 */
  function gaps(x0, y0, x1, y1){
    const segs = []; let s = x0, cur = inkIn(x0, y0, x0, y1) === 0;
    for (let x = x0 + 1; x <= x1 + 1; x++){
      const e = x <= x1 && inkIn(x, y0, x, y1) === 0;
      if (x > x1 || e !== cur){ segs.push({e:cur, a:s, b:x - 1}); s = x; cur = e; }
    }
    const big = segs.filter(q => q.e && q.b - q.a + 1 >= gapW);
    const blocks = []; let bs = null;   /* 큰 빈 구간으로 나뉜 글자 덩어리 */
    segs.forEach(q => { if (q.e && q.b - q.a + 1 >= gapW){ if (bs) blocks.push(bs); bs = null; } else if (!q.e){ bs = bs ? {a:bs.a, b:q.b} : {a:q.a, b:q.b}; } });
    if (bs) blocks.push(bs);
    if (blocks.length === 2 && blocks.every(q => q.b - q.a < .035 * SW)) return;
    big.forEach(q => { if (q.a > x0 && q.b < x1) push(q.a + 2, y0, q.b - 2, y1, 'gap'); });
  }
  /* (나) 표 칸 — 괘선 마스크로 막힌 빈 영역을 이어 칠하기(병합 칸·긴 칸도 그대로 잡힌다) */
  const mask = new Uint8Array(N);
  const fillM = (x0, y0, x1, y1) => { x0 = Math.max(0, x0); y0 = Math.max(0, y0); x1 = Math.min(SW - 1, x1); y1 = Math.min(SH - 1, y1); for (let y = y0; y <= y1; y++) mask.fill(1, y * SW + x0, y * SW + x1 + 1); };
  HL.forEach(h => fillM(h.b0 - tol, h.a0 - 1, h.b1 + tol, h.a1 + 1));
  VL.forEach(v => fillM(v.a0 - 1, v.b0 - tol, v.a1 + 1, v.b1 + tol));
  const lab = new Uint8Array(N), stk = new Int32Array(N);
  for (let p0 = 0; p0 < N; p0++){
    if (mask[p0] || lab[p0]) continue;
    let sp = 0, cnt = 0, edge = false, X0 = SW, Y0 = SH, X1 = 0, Y1 = 0; stk[sp++] = p0; lab[p0] = 1;
    while (sp){ const p = stk[--sp], x = p % SW, y = (p - x) / SW; cnt++;
      if (x < X0) X0 = x; if (x > X1) X1 = x; if (y < Y0) Y0 = y; if (y > Y1) Y1 = y;
      if (x === 0 || y === 0 || x === SW - 1 || y === SH - 1){ edge = true; }
      if (x > 0 && !mask[p - 1] && !lab[p - 1]){ lab[p - 1] = 1; stk[sp++] = p - 1; }
      if (x < SW - 1 && !mask[p + 1] && !lab[p + 1]){ lab[p + 1] = 1; stk[sp++] = p + 1; }
      if (y > 0 && !mask[p - SW] && !lab[p - SW]){ lab[p - SW] = 1; stk[sp++] = p - SW; }
      if (y < SH - 1 && !mask[p + SW] && !lab[p + SW]){ lab[p + SW] = 1; stk[sp++] = p + SW; } }
    const w = X1 - X0 + 1, h = Y1 - Y0 + 1;
    if (edge || w < minW || h < minH || h > .25 * SH || w * h > .3 * N || cnt / (w * h) < .8) continue;
    const cx0 = X0 + m, cx1 = X1 - m, cy0 = Y0 + m, cy1 = Y1 - m, area = (cx1 - cx0 + 1) * (cy1 - cy0 + 1); if (area <= 0) continue;
    if (inkIn(cx0, cy0, cx1, cy1) / area < AUTO_CFG.cellInk) push(cx0, cy0, cx1, cy1, 'cell');
    else gaps(cx0, cy0, cx1, cy1);
  }
  /* (가) 밑줄·점선 위 빈칸 — 표 괘선(세로선과 만나는 선)은 빼고, 위로 첫 잉크까지(한 줄 높이 이내) */
  HL.concat(DL).forEach(h => {
    const y = h.a0, a = h.b0, b = h.b1;
    if (b - a < minW || b - a > .9 * SW) return;
    if (VL.some(v => v.a >= a - tol && v.a <= b + tol && v.b0 <= h.a1 + tol && v.b1 >= y - tol)) return;
    let top = y - hMax;
    for (let yy = y - 2; yy >= Math.max(0, y - hMax); yy--){ if (inkIn(a + m, yy, b - m, yy) >= 2){ top = yy + 1; break; } }
    top = Math.max(0, top, y - ulH);
    const area = (b - a + 1) * (y - top);
    if (area > 0 && inkIn(a, top, b, y - 1) / area < AUTO_CFG.ulInk) push(a, top, b, y - 1, h.d < .85 ? 'dot' : 'line');
  });
