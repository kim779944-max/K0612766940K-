/* ============================================================
   속내 엔진 — 일관성 판독 · 처방전 생성 · 이용권(기기 잠금) · 릴레이 코드
   서버 호출 0건. 답은 기기 밖으로 나가지 않습니다.
   ============================================================ */
(function(){
  const $ = s => document.querySelector(s);
  const A = window.AX, M = window.MODES;

  /* ---------- 저장소 ---------- */
  const S = {
    get(k, d){ try{ const v = localStorage.getItem(k); return v == null ? d : JSON.parse(v); }catch(e){ return d; } },
    set(k, v){ try{ localStorage.setItem(k, JSON.stringify(v)); }catch(e){} },
    del(k){ try{ localStorage.removeItem(k); }catch(e){} }
  };

  /* ---------- 일관성 ---------- */
  function consistency(picks){
    const c = {};
    picks.forEach(n => c[n] = (c[n]||0)+1);
    const top = Object.keys(c).sort((a,b)=>c[b]-c[a])[0];
    const max = c[top];
    const allSame = max === 4;
    const tri = max >= 3;
    return {
      level: allSame ? 'same' : (tri ? 'tri' : 'ok'),
      flag: allSame || tri,
      dominant: Number(top),
      label: allSame ? '같은 번호 4개' : (tri ? '같은 번호 3개' : '네 축 일치'),
      badge: allSame ? 'warn' : (tri ? 'warn' : 'ok')
    };
  }

  /* ---------- 처방전 ---------- */
  function build(picks, bonus, modeKey){
    const d = picks.map(Number);
    const a = {1:A[1][d[0]], 2:A[2][d[1]], 3:A[3][d[2]], 4:A[4][d[3]]};
    const mode = M[modeKey] || M.sales;
    const cons = consistency(d);
    const br = cons.flag ? window.BRANCH[String(cons.dominant)] : null;

    /* 받침에 맞는 조사 (감각으로 / 실리로) */
    const josaRo = w => {
      const c = String(w).charCodeAt(String(w).length - 1) - 0xAC00;
      if (c < 0 || c > 11171) return '로';
      const jong = c % 28;
      return (jong === 0 || jong === 8) ? '로' : '으로';
    };

    const mind = `${a[1].read.replace('사람입니다','분')}. ${a[2].read.replace('사람입니다','분')}. `
      + `결정은 ${({1:'손에 쥐는 순간',2:'원인 한 줄',3:'지금 불 끄는 순간',4:'선을 긋는 순간'})[d[2]]}에 나오고, `
      + `칭찬은 ${a[4].nm}에 꽂힙니다.`;

    const sig = [
      `판단 기준 · ${a[2].nm} — ${a[2].read}. ${a[2].want}. ${a[2].press}.`,
      `압박 반응 · ${a[3].nm} — ${a[3].read}. 반론으로 ${a[3].obj}가 나옵니다.`,
      `칭찬 포인트 · ${a[4].nm} — ${a[4].read}. ${a[4].want}.`
    ];

    const first = `${a[1].open} ${a[1].tail}`;
    const order = mode.order(a);
    const forbid = mode.forbid(a);
    const next = mode.next(a);

    let bonusLine = '';
    if (bonus && bonus.length){
      const lead = bonus[0] === 'lead', ask = bonus[1] === 'ask';
      bonusLine = `${lead ? '먼저 말을 거는 쪽' : '말을 기다리는 쪽'} · ${ask ? '한 사람 붙잡고 묻는 쪽' : '혼자 굳히는 쪽'}`
        + ` — ${lead ? '첫 마디를 먼저 던지세요' : '질문으로 열고 기다리세요'}, ${ask ? '결정 전에 한 사람을 붙이세요' : '한 장으로 정리해 혼자 판단할 시간을 주세요'}.`;
    }

    return {
      code: d.join(''), mode: modeKey, modeNm: mode.nm, modeLine: mode.line,
      cons, branch: br, mind, sig, first, order, forbid, next, bonusLine,
      person: `${a[1].nm} 쪽으로 결정하고(${d[0]}), ${a[2].nm}${josaRo(a[2].nm)} 판단하고(${d[1]}), ${a[3].nm} 쪽으로 받고(${d[2]}), ${a[4].nm}에서 웃는(${d[3]}) 분`
    };
  }

  /* ---------- 기기 지문 ---------- */
  function deviceId(){
    let id = S.get('sn_dev', null);
    if (id) return id;
    const raw = [navigator.userAgent, navigator.language, screen.width+'x'+screen.height,
      new Date().getTimezoneOffset(), navigator.hardwareConcurrency || 0].join('|');
    let h = 5381;
    for (let i = 0; i < raw.length; i++) h = ((h * 33) ^ raw.charCodeAt(i)) >>> 0;
    id = 'D' + h.toString(36).toUpperCase() + Math.floor(Math.random()*1e6).toString(36).toUpperCase();
    S.set('sn_dev', id);
    return id;
  }

  /* ---------- 이용권 (SN-XXXX-XXXX-CC) ---------- */
  const SALT = 'SOKNAE-LIC-2026';
  function hash2(body){
    let h = 2166136261;
    const s = body + SALT;
    for (let i = 0; i < s.length; i++){ h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0; }
    return String(h % 100).padStart(2, '0');
  }
  function normalizeKey(v){
    let s = String(v||'').toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (s.startsWith('SN') && s.length === 12) return 'SN-' + s.slice(2,6) + '-' + s.slice(6,10) + '-' + s.slice(10,12);
    if (s.startsWith('SNRE') && s.length === 12) return 'SN-RE-' + s.slice(4,8) + '-' + s.slice(8,12);
    return null;
  }
  function keyValid(key){
    if (!key) return false;
    if (key.startsWith('SN-RE-')) return true;  // 재인증 키는 대표님이 수동 발급
    const body = key.slice(3, 7) + key.slice(8, 12);
    return hash2(body) === key.slice(13, 15);
  }
  function licState(){ return S.get('sn_lic', null); }
  function licOn(){
    const l = licState();
    return !!(l && l.ok && l.dev === deviceId());
  }
  function activate(key){
    const prev = licState();
    if (prev && prev.key === key && prev.dev !== deviceId()){
      const n = (prev.re) || 0;
      if (n >= 3) return {ok:false, msg:'기기 변경 재인증은 연 3회까지입니다. 대표님께 SN-RE 키를 요청해 주세요.'};
      S.set('sn_lic', {key, dev:deviceId(), ok:true, at:Date.now(), re:n+1});
      return {ok:true, msg:`기기를 다시 묶었습니다 (재인증 ${n+1}/3)`};
    }
    if (prev && prev.key !== key && prev.dev === deviceId()) { /* 다른 키로 교체 허용 */ }
    S.set('sn_lic', {key, dev:deviceId(), ok:true, at:Date.now(), re: prev ? prev.re||0 : 0});
    return {ok:true, msg:'이 기기에 열렸습니다'};
  }
  function keyTail(){
    const l = licState();
    return l && l.key ? l.key.slice(-2) : '';
  }

  /* ---------- (릴레이) 코드 보내기 ---------- */
  function sendCode(code){
    const text = '속내 ' + code;
    const a = document.createElement('a');
    a.href = 'sms:?&body=' + encodeURIComponent(text);
    a.style.display = 'none';
    document.body.appendChild(a); a.click(); a.remove();
    return text;
  }
  async function shareCode(code){
    const text = '속내 ' + code;
    if (navigator.share){
      try{ await navigator.share({text}); return true; }catch(e){ return false; }
    }
    return false;
  }

  window.SN = {S, consistency, build, deviceId, normalizeKey, keyValid, licOn, activate, licState, keyTail, sendCode, shareCode, hash2};
})();
