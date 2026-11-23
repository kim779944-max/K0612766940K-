import io, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8', newline='').read()
CRLF = '\r\n' in s
s = s.replace('\r\n', '\n')


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:80], s.count(a)); s = s.replace(a, b)


rep("""  var TOTAL = 10;
""", """  /* 153번: 기본 = 압축 6문항(NAVI.Q6) · ?deep=1 = 기존 10문항(NAVI.Q, 선택 심화) */
  var DEEP = typeof location !== 'undefined' && /[?&]deep=1(&|$)/.test(location.search || '');
  function QS(){ var N = root.NAVI || {}; return (!DEEP && N.Q6) ? N.Q6 : N.Q; }
  var TOTAL = (DEEP || !(root.NAVI && root.NAVI.Q6)) ? 10 : 6;

  /* 153번: 문항마다 1~3개 복수 체크 — picks[lv-1] = [ {idx,l,t,t2,p,s}, ... ]. 예전 단일 객체도 그대로 읽는다 */
  function isArr(x){ return Object.prototype.toString.call(x) === '[object Array]'; }
  function flatPicks(picks){
    var out = [];
    (picks || []).forEach(function(k){
      if (!k) return;
      if (isArr(k)) k.forEach(function(x){ if (x) out.push(x); }); else out.push(k);
    });
    return out;
  }
""")

rep("""    (state.picks || []).forEach(function(k){ add(k.t, 1.0); add(k.t2, 0.32); });""",
    """    /* 한 문항에서 n개를 고르면 보기마다 t 1.0/n · t2 0.32/n (문항당 합 = 단일 선택과 같음) */
    var weights = [];
    (state.picks || []).forEach(function(k){
      var arr = isArr(k) ? k.filter(Boolean) : (k ? [k] : []);
      var n = arr.length || 1;
      arr.forEach(function(x){ add(x.t, 1.0 / n); add(x.t2, 0.32 / n); weights.push({ lv:x.lv, t:x.t, w:1.0 / n, t2:x.t2, w2:0.32 / n }); });
    });""")

rep("""    var picks = state.picks || [];
    var lead = 0;
    picks.forEach(function(k){ if (k.t === arr[0].t) lead++; });
    return {
      primary: arr[0].t, secondary: arr[1] ? arr[1].t : null,
      gap: top - second, rank: arr, scores: s,
      total: total || 1, share: top / (total || 1),
      lead: lead, answers: picks.length
    };""", """    /* lead·answers 는 '고른 보기 수' 기준 — 복수 체크로 강/약 판정이 기울지 않게 */
    var picks = flatPicks(state.picks);
    var lead = 0;
    picks.forEach(function(k){ if (k.t === arr[0].t) lead++; });
    return {
      primary: arr[0].t, secondary: arr[1] ? arr[1].t : null,
      gap: top - second, rank: arr, scores: s,
      total: total || 1, share: top / (total || 1),
      lead: lead, answers: picks.length, questions: (state.picks || []).filter(Boolean).length, weights: weights
    };""")

rep("""    var table = (root.NAVI.Q || {})[lv];
    if (!table) return null;
    var keys = Object.keys(table);
    if (!state) return table['*'] || table[keys[0]];
    var g = groupOf(score(state).primary);
    return table[g] || table['*'] || table[keys[0]];""", """    var table = (QS() || {})[lv];
    if (!table) return null;
    var keys = Object.keys(table);
    if (!state) return table['*'] || table[keys[0]];
    var g = groupOf(score(state).primary);
    var g2 = (g === 'A' || g === 'B') ? 'X' : 'Y';          /* 6문항: 2갈래(X 일·실속 / Y 사람·여유) */
    return table[g] || table[g2] || table['*'] || table[keys[0]];""")

rep("""    var picks = state.picks || [];
    var want = [];""", """    var picks = flatPicks(state.picks);
    var want = [];""")

# 결과 문장 — 단정형 입말 + 겉/속 반전 (153번)
rep("""    var view = {
      teaser:""", """    /* 153번: ① 문항에서 직접 물어본 영역의 단정 한 줄 + ② 반전 한 줄 (뜻풀이 없음) */
    var V = NAV.VOICE || { DECL:{}, TURN:{} };
    var secAxis = sc.rank[1] && sc.rank[1].v > 0 ? sc.rank[1].t : OPP[primary];
    var turn = (V.TURN[primary] || {})[groupOf(secAxis)] || '';
    var ordered = picks.slice().sort(function(a, b){ return (a.lv - b.lv) || 0; });
    var mainPick = ordered.filter(function(k){ return k.t === primary && k.s; })[0] || null;
    var subj = isSelf ? '당신은 ' : '그 사람은 ';
    var decl = String(V.DECL[primary] || '').replace(/^당신은 /, subj);
    var said = mainPick ? subj + mainPick.s : decl;
    var declare = (said + ' ' + turn).trim();
    var more = [], usedLv = {};
    if (mainPick) usedLv[mainPick.lv] = 1;
    ordered.filter(function(k){ return k.s && k !== mainPick && (k.t === secAxis || k.t2 === primary); })
      .concat(ordered.filter(function(k){ return k.s && k !== mainPick; }))
      .forEach(function(k){ if (more.length < 2 && !usedLv[k.lv]){ usedLv[k.lv] = 1; more.push(k.s); } });
    var voiceInner = [mainPick ? decl : ''].concat(more).filter(Boolean).join(' ');

    var view = {
      teaser:""")

rep("""    if (!isSelf){
      view.teaser = (REL_LEAD[flavor] && REL_LEAD[flavor][mode] ? REL_LEAD[flavor][mode] : '') + card.rel[mode].line;
      view.keep = card.rel[mode].keep;""", """    if (!isSelf){
      view.keep = card.rel[mode].keep;""")
rep("""      script: (sub.script && sub.script[isSelf ? 'love' : mode]) || card.rel[isSelf ? 'love' : mode].script
    };""", """      script: (sub.script && sub.script[isSelf ? 'love' : mode]) || card.rel[isSelf ? 'love' : mode].script
    };
    /* 153번: 화면 결과문 = 단정 + 반전. 설명 문단(read·ex·inner 해설)은 내보내지 않는다 */
    view.teaser = declare;
    view.declare = declare;
    view.turn = turn;
    view.inner = voiceInner || decl;
    view.read = '';
    view.ex = '';""")

rep("""      picks: picks.map(function(k){ return { lv:k.lv, l:k.l, t:k.t, t2:k.t2 }; })""",
    """      picks: picks.map(function(k){ return { lv:k.lv, l:k.l, t:k.t, t2:k.t2 }; }),
      total: TOTAL, deep: DEEP, weights: sc.weights""")

rep("""    var QS = root.NAVI.Q, sets = 0,""", """    var QS = (function(){ var N = root.NAVI || {}; return (!DEEP && N.Q6) ? N.Q6 : N.Q; })(), sets = 0,""")
rep("""    typeCount: function(){ return 64; }, TOTAL: TOTAL, poolStats: poolStats,""",
    """    typeCount: function(){ return 64; }, TOTAL: TOTAL, DEEP: DEEP, flatPicks: flatPicks, poolStats: poolStats,""")
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if CRLF else s)
print('ok')
