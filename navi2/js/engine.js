/* ============================================================
   독심술 v3.0 — 엔진 (채점 · 나이대 치환 · 3단 조립 · 공유)
   근거: output/독심술_심리학_근거데이터.md §2 규칙표 · §3 문장 5단
   서버 호출 0건. 답은 기기 밖으로 나가지 않습니다.
   ============================================================ */
(function(root){
  var C = root.CARDS, Q = root.Q, M = root.MODES, LINT = root.LINT;

  var OPP = { SPEED:'PUTOFF', PUTOFF:'SPEED', EYE:'FACE', FACE:'EYE',
              CALC:'LOYAL', LOYAL:'CALC', PERFECT:'FREE', FREE:'PERFECT' };

  var SAFE = {
    line:    '당신은 겉으로 다 말하지 않는 사람입니다.',
    inner:   '겉으로는 아무렇지 않은데, 속으로는 그 자리가 오래 남아 있으시죠.',
    strength:'맡은 자리에서 끝까지 해내는 힘이 있습니다.',
    softness:'그 마음이 커서 가끔 혼자 다 짊어집니다.',
    rx:      '오늘 할 일 하나를 정해서 끝까지 해 보세요.',
    good:    '미뤄 둔 일 하나가 생각보다 쉽게 풀립니다.',
    risk:    '말이 먼저 나가 한 번 되돌릴 자리가 생깁니다.',
    hedge:   '보내기 전 30초만 멈추는 규칙 하나로 충분합니다.',
    keep:    '이 사람의 강점을 먼저 말해 주세요.',
    avoid:   '단점을 직접 짚는 말은 피하세요.',
    script:  '이 한 가지만 정해 주시면 나머진 제가 하겠습니다'
  };

  function pad2(n){ return (n < 10 ? '0' : '') + n; }

  /* ── 날짜·시간·요일·나이대 ── */
  function context(now, birth){
    now = now || new Date();
    var y = now.getFullYear(), m = now.getMonth() + 1, d = now.getDate(), h = now.getHours();
    var bucket = (h >= 5 && h < 12) ? 'am' : (h >= 12 && h < 19) ? 'day' : 'night';
    var timeNoun = { am:'아침', day:'낮', night:'밤' }[bucket];
    var timeLead = { am:'오늘 아침엔', day:'오늘 낮엔', night:'오늘 밤엔' }[bucket];
    var dow = now.getDay();
    var dowNm = ['일','월','화','수','목','금','토'][dow] + '요일';
    var dayLead = (dow === 1 || dow === 2) ? '이번 주 초반엔' :
                  (dow === 3 || dow === 4) ? '주중엔' :
                  (dow === 5) ? '금요일엔' : '이번 주말엔';

    var age = null, band = 'unknown';
    if (birth && /^[0-9]{8}$/.test(String(birth))){
      var by = +String(birth).slice(0, 4), bm = +String(birth).slice(4, 6), bd = +String(birth).slice(6, 8);
      if (by > 1900 && bm >= 1 && bm <= 12 && bd >= 1 && bd <= 31){
        age = y - by - ((m < bm || (m === bm && d < bd)) ? 1 : 0);
        band = age >= 60 ? 'senior' : age >= 40 ? 'mid' : 'young';
      }
    }
    return {
      date: y + '-' + pad2(m) + '-' + pad2(d),
      dateKo: m + '월 ' + d + '일 ' + dowNm,
      brief: m + '월 ' + dowNm + ' ' + timeNoun,
      month: m, weekday: dowNm, bucket: bucket, timeNoun: timeNoun,
      timeLead: timeLead, dayLead: dayLead,
      age: age, band: band,
      bandLabel: { young:'20·30대', mid:'40·50대', senior:'60대 이상', unknown:'나이 미입력' }[band]
    };
  }

  /* ── 채점: 1순위 3점 · 2순위 1점 ── */
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

  function hash(str){
    var h = 0;
    for (var i = 0; i < str.length; i++) h = (h * 31 + str.charCodeAt(i)) % 999983;
    return h;
  }

  /* ── 3단 조립 ── */
  function compose(mode, picks, birth, now){
    var ctx = context(now, birth);
    var sc = score(picks);
    var primary = sc.primary, secondary = sc.secondary;
    var conflict = !!(secondary && OPP[primary] === secondary && (sc.gap <= 1 || sc.scores[secondary] >= (sc.scores[primary] || 0)));
    var sPri = sc.scores[primary] || 0, sSec = secondary ? (sc.scores[secondary] || 0) : 0;
    /* 보조 결이 있으면 한 줄 덧붙인다 — 같은 결로 읽혀도 문장이 겹치지 않게 */
    var useSub = !!(secondary && !conflict && sSec > 0);
    var card = C[primary];
    var band = ctx.band === 'unknown' ? 'mid' : ctx.band;
    var labels = picks.map(function(p){ return p.opt.label; });
    var code = picks.filter(function(p){ return p.rank === 1; }).map(function(p){ return p.idx; }).join('');
    var seed = hash(primary + '|' + (secondary || '-') + '|' + band + '|' + ctx.date + '|' + ctx.bucket + '|' + code);
    var tagIdx = (Number(code.charAt(0)) + 2 * Number(code.charAt(1)) + 3 * Number(code.charAt(2)) + 4 * Number(code.charAt(3))) % 4;
    var fixed = [];

    function ok(text, kindPOS){
      return !LINT || !LINT.lintCell(text, labels, kindPOS).length;
    }
    function put(text, kind, safeKey){
      var errs = LINT ? LINT.lintCell(text, labels, kind) : [];
      if (!errs.length) return text;
      var fb = SAFE[safeKey || kind];
      if (fb && !LINT.lintCell(fb, labels, kind).length){ fixed.push({ key:safeKey || kind, errs:errs, from:text, to:fb }); return fb; }
      fixed.push({ key:safeKey || kind, errs:errs, from:text, to:text });
      return text;
    }
    /* 문장을 더했을 때 린터에 걸리면 덧붙이지 않는다(본문을 대체문장으로 바꾸지 않음) */
    function join(text, extra, kind){
      if (!extra) return text;
      var merged = text + ' ' + extra;
      if (LINT && LINT.lintCell(merged, labels, kind).length) return text;
      return merged;
    }

    var view = {};
    if (mode === 'self'){
      view.line = put(ctx.brief + ', ' + card.line[band], 'summary', 'line');
      var inner = card.inner[seed % card.inner.length];
      view.inner = put(join(inner, card.tag[tagIdx], 'inner'), 'inner', 'inner');
      view.strength = put(card.strength[band], 'body', 'strength');
      var extra = conflict ? card.flip : (useSub ? C[secondary].blend : '');
      view.softness = put(join(card.softness[band], extra, 'body'), 'body', 'softness');
      view.rx = put(card.rx[band], 'body', 'rx');
      view.good = put(ctx.timeLead + ' ' + card.good[band], 'body', 'good');
      view.risk = put(ctx.dayLead + ' ' + card.risk[band], 'body', 'risk');
      view.hedge = put(card.hedge[band], 'body', 'hedge');
    } else {
      var r = card.rel[mode];
      view.line = put(r.line, 'summary', 'line');
      view.inner = put(join(card.inner[seed % card.inner.length], card.tag[tagIdx], 'inner'), 'inner', 'inner');
      view.keep = put(r.keep, 'body', 'keep');
      view.avoid = put(r.avoid, 'body', 'avoid');
      view.script = put(r.script, 'body', 'script');
    }

    return {
      mode: mode, modeNm: M[mode].nm, ctx: ctx, code: code,
      card: card.code, cardName: card.name, cardNo: card.no, cardSub: card.sub, img: card.img,
      primary: primary, secondary: useSub ? secondary : null,
      conflict: conflict, useSub: useSub, band: band,
      view: view, fixed: fixed,
      picks: picks.map(function(p){ return { lv:p.lv, idx:p.idx, rank:p.rank, label:p.opt.label, t:p.opt.t }; })
    };
  }

  /* ── 공유 ── */
  function b64enc(str){
    try { return btoa(unescape(encodeURIComponent(str))).replace(/=+$/, ''); } catch (e) { return ''; }
  }
  function b64dec(str){
    try { return decodeURIComponent(escape(atob(str))); } catch (e) { return ''; }
  }
  function shareLink(mode, res){
    var payload = { m:mode, c:res.code, s:res.view.line, j:res.view.inner };
    return '#r=' + b64enc(JSON.stringify(payload));
  }
  function readShare(hashStr){
    var m = /#r=([A-Za-z0-9+/_-]+)/.exec(hashStr || '');
    if (!m) return null;
    try {
      var o = JSON.parse(b64dec(m[1]));
      if (!o || !o.s) return null;
      return o;
    } catch (e) { return null; }
  }

  /* ── 최근 결과 (기기에만) ── */
  var HKEY = 'doksim_v3_history';
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
    OPP: OPP, SAFE: SAFE, CARDS: C, Q: Q, MODES: M
  };
  root.APP = APP;
  if (typeof module !== 'undefined' && module.exports) module.exports = APP;
})(typeof window !== 'undefined' ? window : globalThis);
