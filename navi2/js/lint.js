/* ============================================================
   속내 v2.0 — 앵무새 린터 R1~R10
   정본: output/속내_v2_군단회의_디테일설계.md §9-1·§9-2·§9-4
   조립된 결과 칸을 검사해 걸린 칸만 대체문장으로 교체한다(engine.js).
   ============================================================ */
(function(root){
  var STOP = ['그리고','하지만','그래서','정도','생각','마음','사람','때문','경우','부분','이런','저런','쪽','때문에'];
  var TABOO = ['성격','결함','문제가 있','치료','진단','심리검사','장애','당신','귀하','본인'];
  var MARK = ['아니라','겉으','속으','때만','는데','지만','막상','정작'];
  var TEMPLATE_HEAD = ['휴가는','결정은','뿌듯함은','일이 엉키면'];
  var FORMAL_END = ['합니다','입니다','됩니다','하십시오'];
  var PARROT_TAIL = ['하는 쪽','하는 편','좋아하','선호','즐기','스타일'];
  var SPLIT = /[\s·,.!?~"'()\-—]+/;

  function toks(s){
    return String(s || '').split(SPLIT).filter(function(w){ return w.length >= 2; });
  }
  function inList(list, w){ return list.indexOf(w) !== -1; }

  function lintCell(cell, optLabels, kind){
    var errs = [];
    var S = String(cell || '').replace(/\s+/g, ' ').trim();
    var optSet = {};
    (optLabels || []).forEach(function(lb){ toks(lb).forEach(function(w){ optSet[w] = 1; }); });

    var hits = toks(S).filter(function(w){ return optSet[w] && !inList(STOP, w); });
    if (hits.length >= 2) errs.push('R1 보기 어절 2개 이상 재사용: ' + hits.join(','));

    var parrot = PARROT_TAIL.some(function(k){ return S.indexOf(k) !== -1; });
    if (hits.length >= 1 && parrot) errs.push('R2 환언 꼬리');

    if (TEMPLATE_HEAD.some(function(t){ return S.indexOf(t) === 0; })) errs.push('R3 v1 템플릿 머리');

    var tail = S.replace(/[.!?]+$/, '');
    if (FORMAL_END.some(function(e){ return tail.slice(-e.length) === e; })) errs.push('R6 문어체 종결');

    var side = S.split('쪽').length - 1;
    if (side >= 2) errs.push('R4 이어붙이기(쪽 2회)');

    if ((kind === 'summary' || kind === 'jeonggok') && !MARK.some(function(m){ return S.indexOf(m) !== -1; }))
      errs.push('R5 안쪽 마커 없음');

    if (TABOO.some(function(t){ return S.indexOf(t) !== -1; })) errs.push('R7 낙인·진단·거리 호칭');

    (optLabels || []).forEach(function(lb){
      var w = toks(lb);
      for (var i = 0; i + 2 < w.length; i++){
        if (S.indexOf(w.slice(i, i + 3).join(' ')) !== -1){ errs.push('R8 3어절 인용'); break; }
      }
    });

    var sents = S.split(/(?<=[.!?])\s/).filter(function(x){ return x; });
    if (sents.some(function(x){ return x.length > 45; })) errs.push('R9 문장 45자 초과');
    if (sents.length > 3) errs.push('R9 한 칸 3문장 초과');

    return errs;
  }

  var API = { lintCell: lintCell, toks: toks, RULES: { STOP:STOP, TABOO:TABOO, MARK:MARK } };
  root.LINT = API;
  if (typeof module !== 'undefined' && module.exports) module.exports = API;
})(typeof window !== 'undefined' ? window : globalThis);
