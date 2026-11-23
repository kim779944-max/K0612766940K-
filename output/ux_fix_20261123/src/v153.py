"""153 독심술 검증 — 6문항·복수 체크 규칙·가중치·완주 시간·결과문 어미/반전·유형 분리·과거 결과·?deep=1·넘침·캡처.
python -P -X utf8 v153.py <out_dir> [base_after] [base_before] [tag]"""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
AFTER = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8791/"
BEFORE = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:8792/"
TAG = sys.argv[4] if len(sys.argv) > 4 else ""
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
BAN = re.compile(r"편이죠|성격입니다|하게 됩니다")
res = {}

LEGACY = [{"at": "2026-11-20T10:00:00.000Z", "mode": "self", "modeNm": "나를 볼 때", "code": "", "card": "정면의 장군", "line": "예전 결과 한 줄", "tno": 1, "birth": ""}]


def ctx_new(br):
    return br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True, service_workers="block")


def start(pg, base, pics=(0, 4), q=""):
    pg.goto(base + "navi2/" + q); pg.wait_for_timeout(800)
    pg.evaluate("localStorage.removeItem('kts_helper_pos_v1')")
    for i in pics: pg.locator("#gal16 .pic").nth(i).click()
    pg.click("#btnStart"); pg.wait_for_timeout(300)


def run_answers(pg, plan, pause=0):
    """plan = 문항별 고를 보기 인덱스 목록"""
    for lv, idxs in enumerate(plan, 1):
        for i in idxs:
            pg.locator("#ogrid .opt").nth(i).click()
            if pause: pg.wait_for_timeout(pause)
        pg.click("#btnNext"); pg.wait_for_timeout(150 if not pause else pause)
    pg.wait_for_selector("#sResult.on, #sResult.active, #btnReveal:not(.hidden)", timeout=15000)
    pg.wait_for_timeout(300)


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    if not TAG:
        c = ctx_new(br); pg = c.new_page()
        start(pg, BEFORE)
        pg.screenshot(path=os.path.join(OUT, "153_before_q10.png"))
        res["before"] = {"pnum": pg.text_content("#pnum"), "start": None}
        c.close()

    c = ctx_new(br); pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("console", lambda m: errs.append(m.text[:200]) if m.type == "error" else None)
    # 과거 결과(예전 형식) 심어 두고 열기
    pg.goto(AFTER + "navi2/"); pg.evaluate("localStorage.setItem('doksim_v6_history', %s)" % json.dumps(json.dumps(LEGACY, ensure_ascii=False)))
    pg.reload(); pg.wait_for_timeout(800)
    res["history_legacy"] = pg.evaluate("(()=>{const b=document.getElementById('histBox');return {hidden:b.classList.contains('hidden'), text:b.textContent.slice(0,80)}})()")
    pg.locator("#gal16 .pic").nth(0).click(); pg.locator("#gal16 .pic").nth(4).click()
    res["startBtn"] = pg.text_content("#btnStart")
    res["intro_nq"] = pg.evaluate("[...document.querySelectorAll('.nq')].map(n=>n.textContent)")
    pg.click("#btnStart"); pg.wait_for_timeout(300)
    pg.screenshot(path=os.path.join(OUT, f"153_after_q1{TAG}.png"))
    st = lambda: pg.evaluate("""(()=>({pnum:document.getElementById('pnum').textContent, next:document.getElementById('btnNext').disabled,
        sel:document.getElementById('qsel').textContent, on:document.querySelectorAll('#ogrid .opt.on').length, lock:document.querySelectorAll('#ogrid .opt.lock').length,
        max:document.getElementById('qmax').textContent, q:document.getElementById('qtxt').textContent,
        h:[...document.querySelectorAll('#ogrid .opt')].map(b=>Math.round(b.getBoundingClientRect().height)), sw:document.documentElement.scrollWidth}))()""")
    m = {"0": st()}
    pg.locator("#ogrid .opt").nth(0).click(); pg.wait_for_timeout(700); m["1"] = st()   # 자동 진행 없음 확인(700ms 뒤에도 같은 문항)
    pg.locator("#ogrid .opt").nth(1).click(); m["2"] = st()
    pg.locator("#ogrid .opt").nth(2).click(); m["3"] = st()
    pg.locator("#ogrid .opt").nth(3).click(); m["4_try"] = st()
    pg.screenshot(path=os.path.join(OUT, f"153_multi3{TAG}.png"))
    pg.locator("#ogrid .opt").nth(2).click(); m["uncheck_to_2"] = st()
    res["multi"] = m
    # 가중치: 지금 2개(0,1) 고른 상태로 [다음]
    pg.click("#btnNext"); pg.wait_for_timeout(200)
    res["weights_q1_two"] = pg.evaluate("(()=>{const s=APP.score({pics:[],picks:__ST.picks});return {weights:s.weights, answers:s.answers, questions:s.questions, picks:__ST.picks.map(a=>a.map(k=>k.l))}})()")
    res["pnum_seq"] = [pg.text_content("#pnum")]
    for lv in range(2, 7):
        pg.locator("#ogrid .opt").nth(lv % 4).click(); pg.click("#btnNext"); pg.wait_for_timeout(150)
        if lv < 6: res["pnum_seq"].append(pg.text_content("#pnum"))
    pg.wait_for_selector("#btnReveal:not(.hidden)", timeout=15000); pg.wait_for_timeout(300)
    res["result_a_teaser"] = pg.text_content("#resBody .big")
    pg.screenshot(path=os.path.join(OUT, f"153_result_a{TAG}.png"))
    pg.click("#btnReveal"); pg.wait_for_timeout(500)
    full = pg.evaluate("document.getElementById('sResult').innerText")
    res["result_a"] = {"ban": BAN.findall(full), "turn": bool(re.search(r"하지만|다만", full)), "lint": pg.evaluate("window.__NAVI_LINT"),
                       "sec1": pg.evaluate("(document.querySelector('#resBody .sec[data-part=\"1\"] .line')||{}).textContent"),
                       "sec2": pg.evaluate("(document.querySelector('#resBody .sec[data-part=\"2\"] p')||{}).textContent"),
                       "type": pg.evaluate("[__ST.res.tno, __ST.res.cardName, __ST.res.primary, __ST.res.flavor, __ST.res.pol]"),
                       "sw": pg.evaluate("document.documentElement.scrollWidth")}
    pg.evaluate("document.querySelector('#resBody .sec[data-part=\"1\"]').scrollIntoView()"); pg.wait_for_timeout(200)
    pg.screenshot(path=os.path.join(OUT, f"153_result_a_full{TAG}.png"))
    res["history_after"] = pg.evaluate("(()=>{const b=document.getElementById('histBox');return [...b.querySelectorAll('.hit b')].map(x=>x.textContent)})()")

    # 서로 다른 응답 3조합 → 서로 다른 유형
    combos = {"A_speed": ((8, 11), [[0], [0], [0], [0], [1], [0]]),
              "B_loyal": ((2, 13), [[0, 1], [0], [1], [0, 2], [0], [2]]),
              "C_free": ((0, 15), [[3], [2], [3], [3], [2], [1, 3]])}
    types = {}
    for name, (pics, plan) in combos.items():
        start(pg, AFTER, pics)
        t0 = time.time(); run_answers(pg, plan, pause=900 if name == "A_speed" else 0); el = time.time() - t0
        types[name] = {"type": pg.evaluate("[__ST.res.tno, __ST.res.cardName, __ST.res.primary, __ST.res.flavor, __ST.res.pol]"),
                       "teaser": pg.text_content("#resBody .big"), "sec": round(el, 1)}
        if name == "B_loyal":
            pg.screenshot(path=os.path.join(OUT, f"153_result_b{TAG}.png"))
    res["types"] = types
    res["distinct_types"] = len(set(tuple(v["type"][:2]) for v in types.values()))

    # 결과문 대량 검사 — 6문항 세트에서 무작위 600조합(1~3개 복수) → compose
    res["bulk"] = pg.evaluate("""(()=>{
      let seed=7; const rnd=()=>{seed=(seed*16807)%2147483647; return seed/2147483647;};
      const N=600; let ban=0, turn=0, types=new Set(), primaries={}, bad=[];
      const RX=/편이죠|성격입니다|하게 됩니다/;
      for(let k=0;k<N;k++){
        const pics=[]; const np=1+Math.floor(rnd()*4); for(let i=0;i<np;i++){ pics.push(NAVI.START[Math.floor(rnd()*16)]); }
        const st={pics, picks:[], hesit:[]};
        for(let lv=1; lv<=APP.TOTAL; lv++){
          const set=APP.setFor(lv, st); const n=1+Math.floor(rnd()*3); const idx=[0,1,2,3].sort(()=>rnd()-.5).slice(0,n).sort();
          st.picks.push(idx.map(i=>({lv, idx:i, l:set.opts[i].l, t:set.opts[i].t, t2:set.opts[i].t2, p:set.opts[i].p, s:set.opts[i].s})));
        }
        for(const mode of ['self','deal']){
          const r=APP.compose(mode, st, '', new Date());
          const v=r.view; const txt=[v.teaser,v.declare,v.inner,v.past,v.soon,v.risk,v.hedge,v.prevent,v.rx,v.keep,v.avoid,v.script,(v.interest||{}).line].join(' ');
          if(RX.test(txt)){ ban++; if(bad.length<3) bad.push(txt.match(RX)[0]); }
          if(/하지만|다만/.test(v.declare)) turn++;
          types.add(r.tno); primaries[r.primary]=(primaries[r.primary]||0)+1;
        }
      }
      return {runs:N*2, ban, turnPct:Math.round(turn/(N*2)*1000)/10, types:types.size, primaries, bad};
    })()""")
    # 예전 형식(단일 객체) picks 호환
    res["legacy_picks_compose"] = pg.evaluate("""(()=>{try{const r=APP.compose('self',{pics:[NAVI.START[0]],picks:[{lv:1,idx:0,l:'x',t:'SPEED',t2:'FACE'},{lv:2,idx:1,l:'y',t:'CALC',t2:'EYE'}],hesit:[]},'',new Date());
       return {ok:true, tno:r.tno, answers:r.answers, teaser:r.view.teaser}}catch(e){return {ok:false, err:String(e)}}})()""")
    res["poolStats"] = pg.evaluate("APP.poolStats()")
    res["errors"] = errs
    c.close()

    # ?deep=1 — 기존 10문항
    c = ctx_new(br); pg = c.new_page()
    start(pg, AFTER, q="?deep=1")
    res["deep"] = {"pnum": pg.text_content("#pnum"), "TOTAL": pg.evaluate("APP.TOTAL"), "q1": pg.text_content("#qtxt"), "nq": pg.evaluate("[...document.querySelectorAll('.nq')].map(n=>n.textContent)")}
    run_answers(pg, [[0]] * 10)
    res["deep"]["result"] = pg.evaluate("[__ST.res.tno, __ST.res.cardName, __ST.res.total]")
    c.close(); br.close()

json.dump(res, open(os.path.join(OUT, f"153_verify{TAG}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
short = dict(res); short.pop("poolStats", None)
print(json.dumps(short, ensure_ascii=False, indent=1)[:9000])
print("poolStats", {k: res["poolStats"][k] for k in ("sets", "options", "levels", "bad", "imgMissing")})
