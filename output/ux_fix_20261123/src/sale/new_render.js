  var state = { kind:'all', filter:'all', sel:{} };  // sel: { 'gid|oi': qty }

  $('#asof').textContent = '기준 ' + D.asOf.slice(5).replace('-', '/');
  $('#footAsOf').textContent = D.asOfKo + ' ' + D.asOfTime;
  if ($('#footNotice')) $('#footNotice').textContent = D.notice || '';
  if ($('#sheetTip')) $('#sheetTip').textContent = '값은 ' + D.asOf + ' 기준 특가이고, 1+1·2+1 품목은 묶음 수량으로 계산했습니다. 결제 전 매장·쇼핑몰에서 확인하세요.';

  function won(n){ return (n == null) ? '값 확인' : n.toLocaleString('ko-KR') + '원'; }
  function key(g, i){ return g.id + '|' + i; }
  function priceOf(o){ return (o && typeof o.p === 'number') ? o.p : null; }
  /* (160번) 정가(o)가 확인된 것만 할인율을 낸다 — 정가 없으면 % 없음 */
  function hasOrg(o){ return !!o && typeof o.p === 'number' && typeof o.o === 'number' && o.o > o.p; }
  function pct(o){ return hasOrg(o) ? Math.round((1 - o.p / o.o) * 100) : 0; }
  function gPct(g){ return g.offers.reduce(function(a, o){ return Math.max(a, pct(o)); }, 0); }
  function eachOf(o){
    if (priceOf(o) == null) return null;
    if (typeof o.each === 'number') return o.each;
    var m = /^(\d+)\s*(개|팩|병|봉|매|입)/.exec(o.pack || '');
    return m ? Math.floor(o.p / +m[1]) : o.p;
  }
  function gEach(g){
    return g.offers.reduce(function(a, o){ var e = eachOf(o); return (e != null && e < a) ? e : a; }, Infinity);
  }
  /* (수정 2026-11-22) 기준일(D.asOf)에서 계산 — 날짜를 코드에 박지 않는다 */
  function isEndToday(u){
    if (!u) return false;
    if (/오늘/.test(u)) return true;
    var part = String(u).split('~').pop()          // '11/12~11/18' → '11/18'
                  .replace(/까지|부터|\(.*?\)/g, '');
    var m = /(\d{1,2})\/(\d{1,2})/.exec(part);
    if (!m) return false;
    var b = D.asOf.split('-');                     // '2026-11-22'
    return (+m[1] === +b[1]) && (+m[2] === +b[2]); // 끝나는 날 == 기준일
  }
  function isBogo(g, o){ return /1\+1|2\+1/.test((o && o.c) || '') || /^1\+1$|^2\+1$/.test(g.tag || ''); }

  /* ── 탭: 물건 기준 (전체 · 식자재 · 공산품 · 생활용품 · 기타) ── */
  var tabs = $('#tabs');
  [{ k:'all', nm:'전체', tag:'할인율 높은 순' }].concat(D.kinds).forEach(function(c){
    var b = document.createElement('button');
    b.type = 'button'; b.dataset.k = c.k;
    var n = c.k === 'all' ? D.groups.length : D.groups.filter(function(g){ return g.k === c.k; }).length;
    b.innerHTML = '<b>' + c.nm + ' <small>' + n + '</small></b><i>' + c.tag + '</i>';
    if (c.k === state.kind) b.className = 'on';
    b.addEventListener('click', function(){
      state.kind = c.k;
      [].forEach.call(tabs.children, function(x){ x.classList.toggle('on', x === b); });
      render();
      var y = tabs.getBoundingClientRect().top + window.pageYOffset - 70;
      if (window.pageYOffset > y) window.scrollTo({ top: y, behavior:'smooth' });
    });
    tabs.appendChild(b);
  });

  [].forEach.call($('#filters').children, function(b){
    b.addEventListener('click', function(){
      state.filter = b.dataset.f;
      [].forEach.call($('#filters').children, function(x){ x.classList.toggle('on', x === b); });
      render();
    });
  });

  var NOTE = {
    all:'정가와 특가를 나란히 놓고 할인율 높은 순으로 줄 세웠습니다. 정가(취소선)는 같은 상품·같은 규격의 할인 전 값이 확인된 것만 적었고, 확인 못 한 것은 % 없이 "특가"만 보여 줍니다. 판매처는 각 줄의 작은 글씨로 적었습니다.',
    food:'고기·면·소스·간편식처럼 요리·식사에 쓰는 것입니다. 도매 박스·땡처리는 구매 단위(5개 단위 등)와 소비기한을 꼭 확인하세요.',
    goods:'음료·과자·건전지처럼 공장에서 나온 완제품입니다. 편의점 1+1은 2개를 집어 1개 값, 2+1은 3개를 집어 2개 값입니다.',
    life:'휴지·세제·핫팩·고무장갑처럼 가게·집에서 쓰는 소모품입니다. 박스·카톤 단위는 개당 값으로 비교하세요.',
    etc:'카페 쿠폰·백화점 세일처럼 값이 정해지지 않은 행사입니다. 조건만 있어서 % 를 붙이지 않았습니다.'
  };

  function pass(g){
    if (state.kind !== 'all' && g.k !== state.kind) return false;
    if (state.filter === 'all' || state.filter === 'each') return true;
    return g.offers.some(function(o){
      if (state.filter === 'bogo') return isBogo(g, o);
      if (state.filter === 'half') return pct(o) >= 40;
      if (state.filter === 'today') return isEndToday(o.u);
      return true;
    });
  }
  function sortG(arr){
    var idx = arr.map(function(g, i){ return { g:g, i:i, p:gPct(g), e:gEach(g) }; });
    idx.sort(function(a, b){
      if (state.filter === 'each') return (a.e - b.e) || (b.p - a.p) || (a.i - b.i);
      return (b.p - a.p) || (a.i - b.i);
    });
    return idx.map(function(x){ return x.g; });
  }

  function card(g){
    var card = document.createElement('div'); card.className = 'g';

    var prices = g.offers.map(priceOf).filter(function(v){ return v != null; });
    var min = prices.length ? Math.min.apply(null, prices) : null;
    var multi = prices.length > 1;

    var head = document.createElement('div'); head.className = 'gh';

    /* (추가 2026-11-22) 카드 좌측 썸네일 — 사진 없으면 이니셜 타일 */
    var th = document.createElement('div'); th.className = 'th';
    if (g.img){
      var im = document.createElement('img');
      im.src = g.img; im.alt = g.item; im.width = 56; im.height = 56;
      im.loading = 'lazy'; im.decoding = 'async';
      im.addEventListener('error', function(){          // 실패해도 빈 칸 + 첫 글자 (가짜 사진 금지)
        th.className = 'th ph';
        th.innerHTML = '<span>' + String(g.item || '?').slice(0,1) + '</span>';
      });
      th.appendChild(im);
    } else {
      th.className = 'th ph';
      th.innerHTML = '<span>' + String(g.item || '?').slice(0,1) + '</span>';
    }
    head.appendChild(th);                               // ← .t 보다 먼저 (좌측)

    var t = document.createElement('div'); t.className = 't';
    var nm = document.createElement('div'); nm.className = 'nm'; nm.textContent = g.item; t.appendChild(nm);
    var sp = document.createElement('div'); sp.className = 'sp2';
    sp.textContent = g.spec + (multi ? ' · ' + g.offers.length + '곳 비교' : '');
    t.appendChild(sp); head.appendChild(t);
    var tg = document.createElement('div');
    tg.className = 'tg' + (g.blk === 'ddang' ? ' dd' : (g.blk === 'whole' ? ' wh' : (multi ? ' hot' : '')));
    tg.textContent = g.tag || (multi ? '최저 비교' : '특가');
    head.appendChild(tg);
    card.appendChild(head);

    var rows = document.createElement('div'); rows.className = 'rows';
    g.offers.forEach(function(o, i){
      var k = key(g, i);
      var qty = state.sel[k] || 0;
      var row = document.createElement('div');
      row.className = 'row' + (qty ? ' on' : '') + (priceOf(o) == null ? ' off' : '');
      row.setAttribute('role', 'checkbox');
      row.setAttribute('aria-checked', qty ? 'true' : 'false');

      var ck = document.createElement('div'); ck.className = 'ck'; row.appendChild(ck);

      var mid = document.createElement('div'); mid.className = 'mid';
      if (hasOrg(o)){                                   // 정가(취소선·회색) → 특가(큰 오렌지) + −% 배지
        var og = document.createElement('div'); og.className = 'org';
        og.innerHTML = '정가 <s>' + won(o.o) + '</s>';
        mid.appendChild(og);
      }
      var pr = document.createElement('div'); pr.className = 'pr';
      if (priceOf(o) == null){
        pr.textContent = '값 확인';
        var sm = document.createElement('small');
        sm.textContent = '조건만'; pr.appendChild(sm);
      } else {
        var now = document.createElement('span'); now.className = 'now'; now.textContent = won(o.p); pr.appendChild(now);
        var bd = document.createElement('span');
        if (hasOrg(o)) { bd.className = 'pct'; bd.textContent = '−' + pct(o) + '%'; }
        else { bd.className = 'spc'; bd.textContent = '특가'; }
        pr.appendChild(bd);
        if (multi && o.p === min) { var be = document.createElement('span'); be.className = 'best'; be.textContent = '최저'; pr.appendChild(be); }
      }
      mid.appendChild(pr);
      var cd = document.createElement('div'); cd.className = 'cd';
      cd.innerHTML = '<b>' + (o.c || '특가') + '</b>' + (o.u ? ' · ' + o.u : '') +
                     (o.pack ? ' · ' + o.pack : '') + (o.each ? ' · 개당 ' + won(o.each) : '');
      mid.appendChild(cd);
      var src = document.createElement('div'); src.className = 'store';
      src.innerHTML = '<b>' + o.st + '</b> · 확인 ' + (o.src || '');
      mid.appendChild(src);
      row.appendChild(mid);

      var q = document.createElement('div'); q.className = 'qty';
      var mi = document.createElement('button'); mi.type = 'button'; mi.textContent = '−'; mi.setAttribute('aria-label', '수량 줄이기');
      var nu = document.createElement('span'); nu.textContent = String(qty || 1);
      var pl = document.createElement('button'); pl.type = 'button'; pl.textContent = '+'; pl.setAttribute('aria-label', '수량 늘리기');
      mi.addEventListener('click', function(ev){
        ev.stopPropagation();
        var cur = state.sel[k] || 0;
        if (!cur) return;
        if (cur <= 1) delete state.sel[k]; else state.sel[k] = cur - 1;
        render(); syncBar();
      });
      pl.addEventListener('click', function(ev){
        ev.stopPropagation();
        var cur = state.sel[k] || 0;
        if (cur >= 99) return;
        state.sel[k] = cur + 1;
        render(); syncBar();
      });
      q.appendChild(mi); q.appendChild(nu); q.appendChild(pl);
      row.appendChild(q);

      row.addEventListener('click', function(){
        if (priceOf(o) == null){ toast('조건만 있는 행사입니다 — 앱·매장에서 값 확인'); return; }
        if (state.sel[k]) delete state.sel[k]; else state.sel[k] = 1;
        render(); syncBar();
      });
      rows.appendChild(row);
    });
    card.appendChild(rows);
    return card;
  }

  function fillBlock(el, title, sub, arr){
    el.innerHTML = '';
    if (!arr.length) { el.style.display = 'none'; return; }
    el.style.display = '';
    var h = document.createElement('div'); h.className = 'whsh';
    h.innerHTML = '<b>' + title + ' <small>' + arr.length + '</small></b><span>' + sub + '</span>';
    el.appendChild(h);
    var box = document.createElement('div'); box.className = 'list';
    arr.forEach(function(g){ box.appendChild(card(g)); });
    el.appendChild(box);
  }

  function render(){
    var all = D.groups.filter(pass);
    var whole = sortG(all.filter(function(g){ return g.blk === 'whole'; }));
    var ddang = sortG(all.filter(function(g){ return g.blk === 'ddang'; }));
    var rest = sortG(all.filter(function(g){ return !g.blk; }));

    fillBlock($('#whWhole'), '도매 대용량', '박스·카톤·업소용 묶음 — 개당 값이 쌉니다', whole);
    fillBlock($('#whDdang'), '유통기한 임박 땡처리', '소비기한 확인하고 바로 쓸 만큼만', ddang);
    $('#whb').style.display = (whole.length || ddang.length) ? '' : 'none';

    var list = $('#list'); list.innerHTML = '';
    if (!rest.length){
      var e = document.createElement('div');
      e.className = 'empty';
      e.textContent = '이 조건에 맞는 특가가 오늘은 없습니다. 다른 탭이나 [전체]로 보세요.';
      list.appendChild(e);
    }
    rest.forEach(function(g){ list.appendChild(card(g)); });

    var nItem = all.length, nOffer = 0;
    all.forEach(function(g){ nOffer += g.offers.length; });
    $('#count').innerHTML = '<b>' + nItem + '</b>개 품목 · <b>' + nOffer + '</b>개 특가 · ' +
      (state.filter === 'each' ? '개당 값 낮은 순' : '할인율 높은 순') + ' · ' + D.asOfKo.replace('2026년 ', '');
    var kn = state.kind === 'all' ? '전체' : ((D.kinds.filter(function(c){ return c.k === state.kind; })[0] || {}).nm || '');
    $('#catnote').innerHTML = '<b>' + kn + '</b> — ' + NOTE[state.kind];
    syncBar();
  }

