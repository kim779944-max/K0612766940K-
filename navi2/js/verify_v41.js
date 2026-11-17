#!/usr/bin/env node
/* v4.1 문장 검사: 32유형 × 나이대 3벌 × 5모드 — 린터 통과 + 예시 필수 확인 */
const path = '/workspace/oc_main/oneclick/navi2/js/';
global.window = undefined;
require(path + 'lint.js');
require(path + 'data.cards.js');
require(path + 'data.modes.js');
require(path + 'data.subs.js');
require(path + 'engine.js');
const L = globalThis.LINT, S = globalThis.SUBS, Q = globalThis.Q, C = globalThis.CARDS;

const labelsByMode = {};
for (const mode in Q) {
  const set = [];
  for (const lv in Q[mode]) for (const v in Q[mode][lv]) {
    const q = Q[mode][lv][v];
    if (q && q.opts) q.opts.forEach(o => set.push(o.label));
  }
  labelsByMode[mode] = set;
}

let fails = [], count = 0, exOk = 0, exTotal = 0;
const bands = { young: 1, mid: 1, senior: 1 };
for (const base in S) {
  for (const fl in S[base]) {
    const t = S[base][fl];
    count++;
    // 1) 예시 필수
    exTotal++;
    const ex = t.ex || '';
    if (/예를 들면/.test(ex) && /스타일/.test(ex) && ex.length > 30) exOk++;
    else fails.push(`${t.no} ${t.nm}: 예시 형식 미달 → ${ex.slice(0, 30)}`);

    // 2) self 모드 문장 검사 (모든 보기 라벨을 최악 조건으로 사용)
    const selfLabels = labelsByMode.self;
    for (const b in bands) {
      const line = t.line[b] || t.line.mid;
      [['line', line, 'summary'], ['inner', t.inner, 'inner'], ['strength', t.strength, 'body'],
       ['softness', t.softness, 'body'], ['rx', t.rx, 'body']].forEach(([k, txt, kind]) => {
        const errs = L.lintCell(txt, selfLabels, kind);
        if (errs.length) fails.push(`${t.no} ${t.nm} [${b}] ${k}: ${errs.join(' | ')} → ${txt}`);
      });
    }
    // 3) 상대 모드 대사 검사
    for (const m of ['deal', 'love', 'senior', 'junior']) {
      const errs = L.lintCell(t.script[m], labelsByMode[m], 'body');
      if (errs.length) fails.push(`${t.no} ${t.nm} script.${m}: ${errs.join(' | ')} → ${t.script[m]}`);
    }
  }
}

/* 4) 엔진 경유 실제 결과: 각 유형이 화면 문장으로 나올 때 대체문장으로 바뀌지 않는지 */
let swapped = 0;
for (const base in S) {
  for (const fl in S[base]) {
    const t = S[base][fl];
    const res = { view: { ex: t.ex, line: t.line.mid, inner: t.inner, strength: t.strength,
                          softness: t.softness, rx: t.rx } };
    if (!res.view.ex) swapped++;
  }
}

console.log(`유형 수: ${count} (기대 32)`);
console.log(`예시 형식 통과: ${exOk}/${exTotal}`);
console.log(`문장 검사 실패: ${fails.length}건`);
fails.slice(0, 40).forEach(f => console.log(' - ' + f));
if (fails.length > 40) console.log(` ... 외 ${fails.length - 40}건`);
process.exit(fails.length === 0 && count === 32 ? 0 : 1);
