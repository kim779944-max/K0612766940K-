/* consult.html 실측 — CDP Runtime.evaluate 로 실행. 결과는 JSON 문자열.
   단위: css px(96dpi). PNG px = css px × S (S = 1489 / 페이지 폭 css px) */
(function(){
  var MM = 96 / 25.4;
  var out = {pages: [], fields: [], texts: [], blocks: [], fonts: {}};
  var pages = document.querySelectorAll('.page');
  var pw = pages[0].getBoundingClientRect().width;
  var S = 1489 / pw;
  out.pageW = pw; out.pageH = pages[0].getBoundingClientRect().height; out.S = S;
  function rel(r, pr){ return {x: r.left - pr.left, y: r.top - pr.top, w: r.width, h: r.height}; }
  for (var i = 0; i < pages.length; i++){
    var pg = pages[i], pr = pg.getBoundingClientRect();
    var cs = getComputedStyle(pg);
    var kids = pg.children, last = null, bottom = 0, topMost = 1e9;
    for (var k = 0; k < kids.length; k++){
      var r = kids[k].getBoundingClientRect(); if (!r.height) continue;
      if (r.bottom - pr.top > bottom){ bottom = r.bottom - pr.top; last = kids[k]; }
      if (r.top - pr.top < topMost) topMost = r.top - pr.top;
    }
    /* 글자 실제 끝(마지막 요소 안쪽 텍스트 포함) */
    var heads = []; var hs = pg.querySelectorAll('h1,h2');
    for (var h = 0; h < hs.length; h++) heads.push({t: hs[h].textContent, y: hs[h].getBoundingClientRect().top - pr.top});
    out.pages.push({
      id: pg.id, top: pr.top + window.scrollY, left: pr.left + window.scrollX, w: pr.width, h: pr.height,
      padL: parseFloat(cs.paddingLeft), padR: parseFloat(cs.paddingRight), padT: parseFloat(cs.paddingTop), padB: parseFloat(cs.paddingBottom),
      contentTop: topMost, contentBottom: bottom, lastTag: last ? (last.tagName + '.' + last.className) : '',
      scrollH: pg.scrollHeight, clientH: pg.clientHeight, heads: heads
    });
  }
  /* 글꼴 실측 */
  function fsOf(sel){ var e = document.querySelector(sel); if (!e) return null; var c = getComputedStyle(e);
    return {sel: sel, fontSizePx: parseFloat(c.fontSize), lineHeightPx: parseFloat(c.lineHeight), family: c.fontFamily, padT: parseFloat(c.paddingTop), padL: parseFloat(c.paddingLeft), borderTop: parseFloat(c.borderTopWidth)}; }
  out.fonts.body = fsOf('#p1 .txt');
  out.fonts.lead = fsOf('#p1 .lead');
  out.fonts.h1 = fsOf('h1');
  out.fonts.h2 = fsOf('h2');
  out.fonts.tdLabel = fsOf('.t1 th.lb');
  out.fonts.td = fsOf('.t1 td');
  out.fonts.t4td = fsOf('.t4 td');
  /* 실제 그려진 서체(로컬 폰트 이름) — document.fonts 는 로컬만 */
  out.fonts.check = {malgun: document.fonts.check('11pt "Malgun Gothic"')};
  /* 필드 좌표(페이지 기준 css px) */
  function pageOf(el){ return el.closest('.page'); }
  var fs = document.querySelectorAll('[data-f]');
  for (var j = 0; j < fs.length; j++){
    var el = fs[j], pg2 = pageOf(el), pr2 = pg2.getBoundingClientRect(), r2 = el.getBoundingClientRect();
    var rr = rel(r2, pr2);
    if (el.tagName === 'TD'){ /* 괘선 안쪽 */
      var c2 = getComputedStyle(el), bl = parseFloat(c2.borderLeftWidth), bt = parseFloat(c2.borderTopWidth);
      rr = {x: rr.x + bl, y: rr.y + bt, w: rr.w - bl - parseFloat(c2.borderRightWidth), h: rr.h - bt - parseFloat(c2.borderBottomWidth)};
    }
    out.fields.push({id: el.getAttribute('data-f'), page: pg2.id === 'p1' ? 1 : 2, kind: el.tagName === 'TD' ? 'cell' : 'blank', r: rr});
  }
  /* 서명 칸: 성명 줄(라벨 끝 ~ 칸 안쪽 오른쪽), ( 인 ) 상자 */
  var ns = document.querySelectorAll('[data-n]');
  for (var n = 0; n < ns.length; n++){
    var e3 = ns[n], id = e3.getAttribute('data-n'), pg3 = pageOf(e3), pr3 = pg3.getBoundingClientRect();
    var td = e3.closest('td'), tr = td.getBoundingClientRect(), tc = getComputedStyle(td);
    var inL = tr.left + parseFloat(tc.borderLeftWidth) + parseFloat(tc.paddingLeft), inR = tr.right - parseFloat(tc.borderRightWidth) - parseFloat(tc.paddingRight);
    var rg = document.createRange(); rg.selectNodeContents(e3); var tb = rg.getBoundingClientRect();
    var rr3;
    if (/_name$/.test(id)){
      rr3 = {x: tb.right + 6 - pr3.left, y: tb.top - 2 - pr3.top, w: inR - tb.right - 6, h: tb.height + 4};
    } else { /* ( 인 ) 중심에 가로 22mm × 세로 12mm 상자(칸 안쪽으로 제한) */
      var cx = (tb.left + tb.right) / 2, cy = (tb.top + tb.bottom) / 2, W = 22 * MM, H = 12 * MM;
      cx = Math.min(cx, inR + parseFloat(tc.paddingRight) - W / 2 - 1);
      cy = Math.min(cy, tr.bottom - parseFloat(tc.borderBottomWidth) - H / 2 - 1);
      rr3 = {x: cx - W / 2 - pr3.left, y: cy - H / 2 - pr3.top, w: W, h: H};
    }
    out.fields.push({id: id, page: 2, kind: /_name$/.test(id) ? 'line' : 'sign', r: rr3, text: {x: tb.left - pr3.left, y: tb.top - pr3.top, w: tb.width, h: tb.height}});
  }
  /* 원문 대조용 문단 텍스트 */
  var ps = document.querySelectorAll('[data-p]');
  for (var t = 0; t < ps.length; t++) out.texts.push(ps[t].textContent);
  /* 글자 위치 지문(테마 비교용): 모든 텍스트 노드의 줄 상자 */
  var tw = document.createTreeWalker(document.getElementById('sheets'), NodeFilter.SHOW_TEXT, null), node, sig = [];
  while ((node = tw.nextNode())){
    if (!node.nodeValue.trim()) continue;
    var pg5 = node.parentNode.closest(".page"), p5 = pg5.getBoundingClientRect(), zf = p5.width / pg5.offsetWidth;
    var rg2 = document.createRange(); rg2.selectNodeContents(node); var rs = rg2.getClientRects();
    for (var q = 0; q < rs.length; q++) sig.push([pg5.id, Math.round((rs[q].left - p5.left) / zf * 100) / 100, Math.round((rs[q].top - p5.top) / zf * 100) / 100, Math.round(rs[q].width / zf * 100) / 100, Math.round(rs[q].height / zf * 100) / 100]);
  }
  out.sigCount = sig.length; out.sig = JSON.stringify(sig);
  /* 쪽 안 블록(조문 단위) 위치: 쪽 끝 고아 확인용 */
  for (var b = 0; b < pages.length; b++){
    var pr4 = pages[b].getBoundingClientRect(), ch = pages[b].children;
    for (var c = 0; c < ch.length; c++){ var r4 = ch[c].getBoundingClientRect();
      out.blocks.push({page: b + 1, tag: ch[c].tagName, cls: ch[c].className, text: ch[c].textContent.replace(/\s+/g, ' ').slice(0, 24), top: r4.top - pr4.top, bottom: r4.bottom - pr4.top}); }
  }
  out.scrollW = document.documentElement.scrollWidth; out.clientW = document.documentElement.clientWidth;
  out.errs = window.__errs || [];
  return JSON.stringify(out);
})()
