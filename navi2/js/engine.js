/* ============================================================
   속내 v2.0 — 엔진 (라우팅 · 채점 · 모순 처리 · 결과 조립 · 공유)
   정본: output/속내_v2_군단회의_디테일설계.md §3-5 · §6 · §9-4 · §11 · §13-4
   서버 호출 0건. 답은 기기 밖으로 나가지 않습니다.
   ============================================================ */
(function(root){
  var C = root.CARDS, Q = root.Q, M = root.MODES, LINT = root.LINT;

  var OPP = { SPEED:'PUTOFF', PUTOFF:'SPEED', EYE:'FACE', FACE:'EYE',
              CALC:'LOYAL', LOYAL:'CALC', PERFECT:'FREE', FREE:'PERFECT' };

  var SLOT = {
    self:  ['summary','jeonggok','guard','doit','workPlus','workMinus','episode'],
    deal:  ['line','jeonggok','order','taboo','next'],
    love:  ['line','jeonggok','order','taboo','next'],
    senior:['line','jeonggok','order','taboo','next'],
    junior:['line','jeonggok','order','taboo','next']
  };
  var KIND = { summary:'summary', line:'summary', jeonggok:'jeonggok', guard:'guard', doit:'doit',
               workPlus:'work', workMinus:'work', episode:'episode',
               order:'order', taboo:'taboo', next:'next' };

  var SAFE = {
    summary:  '겉으로는 조용한데, 속으로는 이미 정리가 끝나 있으시죠.',
    jeonggok: '겉으로는 아무렇지 않은데, 속으로는 그 자리가 오래 남아 있으시죠.',
    guard:    '오늘은 결정 하나만 미루지 말고 바로 정해 보세요.',
    doit:     '오늘 할 일 하나를 정해서 끝까지 해 보세요.',
    work:     '맡은 자리에서 끝까지 해내는 힘이 있습니다.',
    episode:  '그런 장면이 한 번쯤 있으시죠.',
    order:    '한 가지 정하기 → 확인 → 마무리',
    taboo:    '재촉하는 말',
    next:     '이 한 가지만 정하고 나머지는 제가 하겠습니다'
  };

  function pad2(n){ return (n < 10 ? '0' : '') + n; }

  /* ── 날짜·시간·요일·계절·나이대 문맥 (§11) ── */
  function context(now, birth){
    now = now || new Date();
    var y = now.getFullYear(), m = now.getMonth() + 1, d = now.getDate(), h = now.getHours();
    var bucket = (h >= 5 && h < 12) ? 'am' : (h >= 12 && h < 19) ? 'day' : 'night';
    var timeNoun = { am:'아침', day:'낮', night:'밤' }[bucket];
    var dow = now.getDay();
    var dowNm = ['일','월','화','수','목','금','토'][dow] + '요일';
    var dowWord = (dow === 1 || dow === 2) ? '밀어붙이는 날' :
                  (dow === 3 || dow === 4) ? '점검하는 날' :
                  (dow === 5) ? '마감하는 날' : '사람에게 쓰는 날';
    var seasonName = (m >= 3 && m <= 5) ? '시작의 계절' :
                     (m >= 6 && m <= 8) ? '속도의 계절' :
                     (m >= 9 && m <= 10) ? '정산의 계절' : '한 해를 접는';
    var seasonWord = seasonName + ' ' + m + '월';

    var age = null, band = 'unknown';
    if (birth && /^[0-9]{8}$/.test(String(birth))){
      var by = +String(birth).slice(0, 4), bm = +String(birth).slice(4, 6), bd = +String(birth).slice(6, 8);
      if (by > 1900 && bm >= 1 && bm <= 12 && bd >= 1 && bd <= 31){
        age = y - by - ((m < bm || (m === bm && d < bd)) ? 1 : 0);
        band = age >= 60 ? 'senior' : age >= 40 ? 'mid' : 'young';
      }
    }
    var ageLead = { young:'아직 판을 키우는 나이', mid:'책임이 가장 무거운 나이',
                    senior:'아침이 먼저 오는 나이', unknown:'나이를 밝히지 않으셨어도' }[band];

    return {
      date: y + '-' + pad2(m) + '-' + pad2(d),
      dateKo: m + '월 ' + d + '일 ' + dowNm,
      month: m, weekday: dowNm, weekdayWord: dowWord,
      bucket: bucket, timeNoun: timeNoun, seasonName: seasonName, seasonWord: seasonWord,
      age: age, band: band, ageLead: ageLead,
      ageTag: { young:'20s', mid:'40s', senior:'60s', unknown:'' }[band],
      when: ageLead + ', ' + seasonWord + ' ' + dowNm + ' ' + timeNoun + '이죠.'
    };
  }

  /* ── 채점 (§3-2: 1순위 3점 · 2순위 1점) ── */
  function score(picks){
    var s = {}, first = {}, order = [];
    picks.forEach(function(p){
      var t = p.opt.t;
      if (!(t in s)){ s[t] = 0; first[t] = 0; order.push(t); }
      s[t] += (p.rank === 1 ? 3 : 1);
      if (p.rank === 1) first[t] += 1;
    });
    var arr = order.map(function(t, i){ return { t:t, v:s[t], f:first[t], i:i }; });
    arr.sort(function(a, b){ return (b.v - a.v) || (b.f - a.f) || (a.i - b.i); });
    return {
      primary: arr[0] ? arr[0].t : null,
      secondary: arr[1] ? arr[1].t : null,
      gap: arr[1] ? (arr[0].v - arr[1].v) : (arr[0] ? arr[0].v : 0),
      scores: s
    };
  }

  /* ── 에피소드 선택: 나이대 우선 → 시간대 → 첫 번째 (§6) ── */
  function pickEpisode(card, ctx){
    var eps = card.episodes || [];
    var byAge = eps.filter(function(e){ return e.age && ctx.ageTag && e.age === ctx.ageTag; });
    if (byAge.length) return byAge[0].s;
    var byTime = eps.filter(function(e){ return e.time && e.time === ctx.bucket; });
    if (byTime.length) return byTime[0].s;
    return eps.length ? eps[0].s : '';
  }

  /* ── 결과 조립 (+ 린터 통과 실패 시 대체문장 교체) ── */
  function compose(mode, picks, birth, now){
    var ctx = context(now, birth);
    var sc = score(picks);
    var primary = sc.primary, secondary = sc.secondary;
    var conflict = !!(secondary && OPP[primary] === secondary && sc.gap <= 1);
    var sPri = sc.scores[primary] || 0, sSec = secondary ? (sc.scores[secondary] || 0) : 0;
    var useSub = !!(secondary && !conflict && sSec * 2 >= sPri);
    var card = C[primary], sub = useSub ? C[secondary] : null;
    var labels = picks.map(function(p){ return p.opt.label; });
    var cells = {}, fixed = [];

    function put(key, text, alts){
      var kind = KIND[key] || 'work';
      var errs = LINT.lintCell(text, labels, kind);
      if (!errs.length){ cells[key] = text; return; }
      var used = null, cand = [].concat(alts || []);
      for (var i = 0; i < cand.length; i++){
        if (cand[i] && !LINT.lintCell(cand[i], labels, kind).length){ used = cand[i]; break; }
      }
      if (used == null){
        var first = String(text).split(/(?<=[.!?])\s/)[0];
        if (first && first !== text && !LINT.lintCell(first, labels, kind).length) used = first;
      }
      if (used == null) used = SAFE[kind] || text;
      fixed.push({ key: key, errs: errs, to: used, from: text, where: (used === SAFE[kind] ? 'safe' : 'alt') });
      cells[key] = used;
    }

    if (mode === 'self'){
      var sum = ctx.when + ' ' + card.summary[ctx.bucket];
      put('summary', sum, [ctx.when + ' ' + card.alt.summary, ctx.when + ' ' + card.summary.am]);

      var jg = card.jeonggok.p;
      if (conflict) jg = card.conflict.self;
      else if (sub) jg += ' 그런데 결정적일 땐, ' + sub.subLine;
      else if (card.jeonggok.s) jg += ' ' + card.jeonggok.s;
      put('jeonggok', jg, [card.alt.jeonggok, card.jeonggok.s, card.jeonggok.p]);

      put('guard', card.guard, [card.warn]);
      put('doit', card.doit, [card.alt.doit]);
      put('workPlus', card.workPlus, [card.workMinus]);
      put('workMinus', card.workMinus, [card.alt.doit, card.workPlus]);
      put('episode', pickEpisode(card, ctx),
          [card.episodes[1] && card.episodes[1].s, card.episodes[0] && card.episodes[0].s]);
    } else {
      var r = card.rel[mode];
      var secRel = (sub && sub.rel[mode]) ? sub.rel[mode] : null;
      put('line', r.line, [card.alt.summary, r.order.join(' → ')]);
      var jg3 = conflict ? card.conflict.rel : (card.jeonggok3 + (secRel ? ' 막상 판이 엎어지면, ' + sub.subLine : ''));
      put('jeonggok', jg3, [card.jeonggok3, card.alt.jeonggok]);
      put('order', r.order.join(' → '), [r.order.slice(0, 2).join(' → ')]);
      put('taboo', r.taboo, [SAFE.taboo]);
      put('next', r.next, [SAFE.next]);
    }

    var code = picks.map(function(p){ return p.idx; }).join('');
    return {
      mode: mode, modeNm: M[mode].nm, ctx: ctx, code: code,
      card: card.code, cardName: card.name,
      primary: primary, secondary: secondary, gap: sc.gap, scores: sc.scores,
      conflict: conflict, useSub: useSub,
      cells: cells, baseline: {
        summary: ctx.when + ' ' + card.summary[ctx.bucket],
        jeonggok: card.jeonggok.p + (card.jeonggok.s ? ' ' + card.jeonggok.s : '')
      },
      fixed: fixed, picks: picks.map(function(p){ return { lv: p.lv, idx: p.idx, rank: p.rank, label: p.opt.label, t: p.opt.t }; }),
      bypass: card.bypass
    };
  }

  /* ── 공유: 우회 전략(bypass)은 링크에 싣지 않는다 (§10-3) ── */
  function b64enc(str){
    try { return btoa(unescape(encodeURIComponent(str))).replace(/=+$/, ''); } catch (e) { return ''; }
  }
  function b64dec(str){
    try { return decodeURIComponent(escape(atob(str))); } catch (e) { return ''; }
  }
  function shareLink(mode, res){
    var payload = { m: mode, c: res.code, s: res.cells.summary || res.cells.line, j: res.cells.jeonggok };
    return '#r=' + b64enc(JSON.stringify(payload));
  }
  function readShare(hash){
    var m = /#r=([A-Za-z0-9+/_-]+)/.exec(hash || '');
    if (!m) return null;
    try {
      var o = JSON.parse(b64dec(m[1]));
      if (!o || !o.s) return null;
      return o;
    } catch (e) { return null; }
  }

  /* ── 최근 20건 (localStorage) ── */
  var HKEY = 'soknae_v2_history';
  function loadHistory(){
    try { var v = JSON.parse(localStorage.getItem(HKEY) || '[]'); return Array.isArray(v) ? v : []; }
    catch (e) { return []; }
  }
  function saveHistory(entry){
    var list = loadHistory();
    list.unshift(entry);
    list = list.slice(0, 20);
    try { localStorage.setItem(HKEY, JSON.stringify(list)); } catch (e) {}
    return list;
  }

  function questionAt(mode, lv, variant){
    var table = Q[mode][lv] || {};
    return table[variant] || table['*'] || null;
  }

  var APP = {
    context: context, score: score, compose: compose, questionAt: questionAt,
    shareLink: shareLink, readShare: readShare, loadHistory: loadHistory, saveHistory: saveHistory,
    OPP: OPP, SLOT: SLOT, SAFE: SAFE, CARDS: C, Q: Q, MODES: M
  };
  root.APP = APP;
})(typeof window !== 'undefined' ? window : globalThis);
