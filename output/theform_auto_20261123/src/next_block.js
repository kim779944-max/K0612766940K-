/* ---------- 다음 칸 연속 입력 (적립 146번) — 배열 순서 · 지운 자리·서명·자동 계산 칸은 건너뜀 ---------- */
function navIdx(){
  if (!CUR) return [];
  return CUR.fields.map((f, i) => i).filter(i => { const f = CUR.fields[i];
    return f.type !== 'erase' && f.type !== 'sign' && !(CUR.calc && CUR.calc[f.label]) && $(`#valList [data-f="${i}"]`); });
}
function navEl(i){ return $(`#valList [data-f="${i}"]`); }
function navFocus(i){
  const el = navEl(i); if (!el) return;
  el.focus({preventScroll:true});
  try{ if (el.value && el.select) el.select(); }catch(e){}
  el.scrollIntoView({block:'center', behavior:'smooth'});
  updNavPos(i);
}
function updNavPos(i){
  const L = navIdx(), k = L.indexOf(i), el = $('#nfPos'); if (!el) return;
  el.textContent = (k >= 0 ? k + 1 : '-') + ' / ' + (L.length || '-');
}
function nextField(i){
  const L = navIdx(), nx = L.find(k => k > i);
  if (nx == null){ toast('마지막 칸입니다 · [미리보기]로 넘어가세요'); const nb = $('#nextBtn'); if (nb){ nb.focus(); nb.scrollIntoView({block:'center', behavior:'smooth'}); } return; }
  navFocus(nx);
}
function prevField(i){
  const L = navIdx(); let pv = null; L.forEach(k => { if (k < i) pv = k; });
  if (pv == null) return toast('첫 칸입니다');
  navFocus(pv);
}
const navCur = () => { const a = document.activeElement; if (a && a.closest && a.closest('#valList') && a.dataset.f != null) return +a.dataset.f;
  return (LAST_INPUT && LAST_INPUT.isConnected && LAST_INPUT.dataset.f != null) ? +LAST_INPUT.dataset.f : -1; };
$('#valList').addEventListener('keydown', e => {
  if (e.key !== 'Enter') return;
  if (e.isComposing || e.keyCode === 229) return;        /* 한글 조합 중 Enter = 글자 확정 → 이동하지 않는다 */
  const i = e.target.dataset.f; if (i == null) return;
  if (e.target.tagName === 'TEXTAREA') return;            /* 여러 줄 칸은 줄바꿈 그대로 */
  e.preventDefault();
  nextField(+i);
});
$('#valList').addEventListener('focusin', e => { if (e.target.dataset.f != null) updNavPos(+e.target.dataset.f); });
/* 버튼을 눌러도 입력칸 포커스(모바일 자판)가 빠지지 않게 pointerdown 기본 동작을 막는다 */
['#nfPrev', '#nfNext'].forEach(s => $(s).addEventListener('pointerdown', e => e.preventDefault()));
$('#nfNext').onclick = () => { const c = navCur(); if (c < 0){ const L = navIdx(); if (L.length) navFocus(L[0]); return; } nextField(c); };
$('#nfPrev').onclick = () => { const c = navCur(); if (c < 0){ const L = navIdx(); if (L.length) navFocus(L[0]); return; } prevField(c); };
