"""146번 검증 — 390×844 · DPR3 · 터치. 사진 등록 → [⚡ 1클릭 자동 빈칸] → ✕/모두 지우기/되돌리기 → 손 기능 → 프리셋 → 다음 칸/Enter.
사용: python verify.py <OUT> <URL> <testset 폴더> <theform 폴더>"""
import base64, json, sys, time
from urllib.parse import urlparse
from playwright.sync_api import sync_playwright

OUT, URL, TS, TFD = sys.argv[1:5]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {}
SHOTS = []

GT_JS = """([pid, pg1]) => { const f = TF.BUILT.find(x => x.id === pid); return f.fields.filter(x => x.type !== 'erase' && (!x.pg || x.pg === pg1)).map(x => [x.x, x.y, x.w, x.h]); }"""
SCORE_JS = """(gt) => { const A = TF.CUR.fields.filter(f => f._auto);
  const inG = (d, g) => { const cx = d.x + d.w / 2, cy = d.y + d.h / 2; return cx >= g[0] - 1.5 && cx <= g[0] + g[2] + 1.5 && cy >= g[1] - 1.5 && cy <= g[1] + g[3] + 1.5; };
  const fp = A.filter(d => !gt.some(g => inG(d, g)));
  return {n:A.length, fp:fp.length, gt:gt.length, gtCovered:gt.filter(g => A.some(d => inG(d, g))).length, fpBoxes:fp.map(d => [d.x, d.y, d.w, d.h])}; }"""
OVERLAY_JS = """(gt) => { const c = document.createElement('canvas'), B = TF.BG; c.width = 900; c.height = Math.round(900 * (B.naturalHeight || B.height) / (B.naturalWidth || B.width));
  const g = c.getContext('2d'); g.drawImage(B, 0, 0, c.width, c.height); g.lineWidth = 2;
  const inG = (d, q) => { const cx = d.x + d.w / 2, cy = d.y + d.h / 2; return cx >= q[0] - 1.5 && cx <= q[0] + q[2] + 1.5 && cy >= q[1] - 1.5 && cy <= q[1] + q[3] + 1.5; };
  TF.CUR.fields.filter(f => f._auto).forEach(d => { const ok = gt.some(q => inG(d, q)); g.strokeStyle = ok ? '#FF6B00' : '#DC2626'; g.fillStyle = ok ? 'rgba(255,107,0,.18)' : 'rgba(220,38,38,.38)';
    const X = d.x / 100 * c.width, Y = d.y / 100 * c.height, W = d.w / 100 * c.width, H = d.h / 100 * c.height; g.fillRect(X, Y, W, H); g.strokeRect(X, Y, W, H); });
  return c.toDataURL('image/png'); }"""
CNT = "TF.CUR.fields.length"
NAUTO = "TF.CUR.fields.filter(f=>f._auto).length"


def shot(pg, name, sel=None):
    if sel:
        pg.evaluate(f"document.querySelector('{sel}').scrollIntoView({{block:'start'}}); scrollBy(0,-70)")
        pg.wait_for_timeout(350)
    pg.screenshot(path=f"{OUT}/{name}")
    SHOTS.append(name)


def toast(pg):
    return pg.evaluate("document.getElementById('toast').textContent")


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=3, is_mobile=True, has_touch=True, service_workers="block")
    pg = ctx.new_page()
    errs, hosts, dialogs = [], [], []
    pg.on("pageerror", lambda e: errs.append("pageerror " + str(e)[:200]))
    pg.on("console", lambda m: errs.append("console " + m.text[:200]) if m.type == "error" else None)
    pg.on("request", lambda r: hosts.append(urlparse(r.url).hostname or r.url[:20]))
    pg.on("dialog", lambda d: (dialogs.append(d.message), d.accept()))
    pg.goto(URL + "?t=%d" % time.time(), wait_until="load"); pg.wait_for_timeout(1500)
    R["sw_s1"] = pg.evaluate("document.documentElement.scrollWidth")

    def register(path):
        pg.evaluate("TF.go(1)"); pg.wait_for_timeout(300)
        pg.set_input_files("#photoIn", path)
        pg.wait_for_function("document.getElementById('busy').className.indexOf('on')<0 && TF.CUR && TF.CUR._new", timeout=20000)
        pg.wait_for_timeout(400)
        pg.click("#nextBtn"); pg.wait_for_timeout(700)

    def auto(tag, gt):
        pg.evaluate("window.TF_AUTO_LAST=null")
        h0 = len(hosts)
        t0 = time.time()
        pg.click("#autoF")
        pg.wait_for_function("window.TF_AUTO_LAST", timeout=20000)
        wall = round((time.time() - t0) * 1000)
        pg.wait_for_timeout(300)
        last = pg.evaluate("TF_AUTO_LAST")
        sc = pg.evaluate(SCORE_JS, gt)
        png = pg.evaluate(OVERLAY_JS, gt)
        open(f"{OUT}/overlay_{tag}.png", "wb").write(base64.b64decode(png.split(",")[1]))
        newHosts = sorted(set(h for h in hosts[h0:] if h not in ("127.0.0.1", "autooneclick.com")))
        r = {"algo_ms": last["ms"], "click_to_done_ms": wall, "SW": last["SW"], "SH": last["SH"], "bg": pg.evaluate("[TF.BG.naturalWidth,TF.BG.naturalHeight]"),
             "kinds": last["kinds"], "requests_during_auto": len(hosts) - h0, "new_hosts": newHosts,
             "autoBar": pg.evaluate("[getComputedStyle(document.getElementById('autoBar')).display, document.getElementById('autoBar').textContent]"),
             "fCount": pg.evaluate("document.getElementById('fCount').textContent"), "sw": pg.evaluate("document.documentElement.scrollWidth")}
        r.update(sc)
        return r

    # ---------- A. 자동 빈칸 — 시험 종이 3장 ----------
    tests = [("sale", f"{TFD}/tpl_sale.png", "p_sale", 1), ("lease", f"{TFD}/tpl_lease.png", "p_lease", 1),
             ("photo", f"{TS}/photo_consult_rot8_shadow.jpg", "p_consult", 1)]
    for tag, path, pid, pg1 in tests:
        register(path)
        gt = pg.evaluate(GT_JS, [pid, pg1])
        R["auto_" + tag] = auto(tag, gt)
        shot(pg, f"after_390_auto_{tag}.png", "#edStage")
    # 버튼 크기
    R["autoBtn_box"] = pg.evaluate("(()=>{const r=document.getElementById('autoF').getBoundingClientRect();return [Math.round(r.width),Math.round(r.height)]})()")
    R["xauto_box"] = pg.evaluate("(()=>{const b=document.querySelector('.xauto');if(!b)return null;const r=b.getBoundingClientRect(),s=getComputedStyle(b,'::before');return [r.width,r.height,s.width,s.height]})()")

    # ---------- ✕ 삭제 · 되돌리기 · 드래그 안 됨 ----------
    xd = {}
    pg.evaluate("(()=>{const b=document.querySelectorAll('.xauto')[3];b.scrollIntoView({block:'center'})})()"); pg.wait_for_timeout(300)
    pg.screenshot(path=f"{OUT}/after_390_xdelete_before.png"); SHOTS.append("after_390_xdelete_before.png")
    xd["before"] = pg.evaluate(CNT)
    target = pg.evaluate("(()=>{const b=document.querySelectorAll('.xauto')[3];const i=+b.dataset.x;const r=b.getBoundingClientRect();return {i,id:TF.CUR.fields[i].id,x:r.x+r.width/2,y:r.y+r.height/2,snap:JSON.stringify(TF.CUR.fields.map(f=>[f.id,f.x,f.y]))}})()")
    pg.touchscreen.tap(target["x"], target["y"]); pg.wait_for_timeout(400)
    xd["after_tap"] = pg.evaluate(CNT)
    xd["removed_id_gone"] = pg.evaluate(f"!TF.CUR.fields.some(f=>f.id==='{target['id']}')")
    xd["others_unmoved"] = pg.evaluate("(s)=>{const o=JSON.parse(s);return TF.CUR.fields.every(f=>{const q=o.find(z=>z[0]===f.id);return q&&q[1]===f.x&&q[2]===f.y})}", target["snap"])
    xd["toast"] = toast(pg)
    pg.screenshot(path=f"{OUT}/after_390_xdelete_after.png"); SHOTS.append("after_390_xdelete_after.png")
    # 마우스로 ✕ 를 누르고 끌어도 칸이 끌려가지 않는지
    b2 = pg.evaluate("(()=>{const b=document.querySelectorAll('.xauto')[2];const r=b.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2,snap:JSON.stringify(TF.CUR.fields.map(f=>[f.id,f.x,f.y]))}})()")
    pg.mouse.move(b2["x"], b2["y"]); pg.mouse.down(); pg.mouse.move(b2["x"] + 60, b2["y"] + 40, steps=6); pg.mouse.up(); pg.wait_for_timeout(300)
    xd["drag_on_x_count"] = pg.evaluate(CNT)
    xd["drag_on_x_others_unmoved"] = pg.evaluate("(s)=>{const o=JSON.parse(s);return TF.CUR.fields.every(f=>{const q=o.find(z=>z[0]===f.id);return q&&q[1]===f.x&&q[2]===f.y})}", b2["snap"])
    pg.click("#undoF"); pg.wait_for_timeout(200); pg.click("#undoF"); pg.wait_for_timeout(300)
    xd["after_undo2"] = pg.evaluate(CNT)
    R["xdelete"] = xd

    # ---------- 손 기능 보존 + 모두 지우기 ----------
    hand = {}
    n0 = pg.evaluate(CNT)
    pg.click("#addF"); pg.wait_for_timeout(300)
    hand["plus_add"] = pg.evaluate(CNT) - n0
    hand["plus_label_focus"] = pg.evaluate("document.activeElement.id")
    sel = pg.evaluate("(()=>{const e=document.querySelector('#edStage .fld.sel');e.scrollIntoView({block:'center'});return TF.SEL})()"); pg.wait_for_timeout(300)
    f0 = pg.evaluate(f"(({{x,y,w,h}})=>({{x,y,w,h}}))(TF.CUR.fields[{sel}])")
    bx = pg.evaluate("(()=>{const r=document.querySelector('#edStage .fld.sel').getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]})()")
    pg.mouse.move(bx[0], bx[1]); pg.mouse.down(); pg.mouse.move(bx[0] + 30, bx[1] + 25, steps=8); pg.mouse.up(); pg.wait_for_timeout(300)
    f1 = pg.evaluate(f"(({{x,y,w,h}})=>({{x,y,w,h}}))(TF.CUR.fields[{sel}])")
    hand["drag_moved"] = [round(f1["x"] - f0["x"], 2), round(f1["y"] - f0["y"], 2)]
    hd = pg.evaluate("(()=>{const r=document.querySelector('#edStage .fld.sel .hd2').getBoundingClientRect();return [r.x+r.width/2,r.y+r.height/2]})()")
    pg.mouse.move(hd[0], hd[1]); pg.mouse.down(); pg.mouse.move(hd[0] + 25, hd[1] + 12, steps=8); pg.mouse.up(); pg.wait_for_timeout(300)
    f2 = pg.evaluate(f"(({{x,y,w,h}})=>({{x,y,w,h}}))(TF.CUR.fields[{sel}])")
    hand["resized"] = [round(f2["w"] - f1["w"], 2), round(f2["h"] - f1["h"], 2)]
    hand["manual_has_no_x"] = pg.evaluate("!document.querySelector('#edStage .fld.sel .xauto')")
    # 모두 지우기 — 수동 칸은 남는다
    na, nt = pg.evaluate(NAUTO), pg.evaluate(CNT)
    pg.click("#autoClr"); pg.wait_for_timeout(300)
    hand["clear_all"] = {"auto_before": na, "total_before": nt, "auto_after": pg.evaluate(NAUTO), "total_after": pg.evaluate(CNT),
                         "autoBar_display": pg.evaluate("getComputedStyle(document.getElementById('autoBar')).display")}
    pg.click("#undoF"); pg.wait_for_timeout(300)
    hand["clear_all_undo"] = [pg.evaluate(NAUTO), pg.evaluate(CNT)]
    # [칸 삭제] (선택 칸)
    pg.evaluate(f"TF.SEL={sel};TF.drawEditor()")
    n1 = pg.evaluate(CNT); pg.click("#delF"); pg.wait_for_timeout(300)
    hand["del_button"] = n1 - pg.evaluate(CNT)
    # [🖼 그림·도장 지우기] → 빈 곳 탭
    pg.click("#ezBtn"); pg.wait_for_timeout(200)
    st = pg.evaluate("(()=>{const s=document.getElementById('edStage');s.scrollIntoView({block:'start'});const r=s.getBoundingClientRect();return [r.x,r.y,r.width,r.height]})()"); pg.wait_for_timeout(300)
    st = pg.evaluate("(()=>{const r=document.getElementById('edStage').getBoundingClientRect();return [r.x,r.y,r.width,r.height]})()")
    ne = pg.evaluate("TF.CUR.fields.filter(f=>f.type==='erase').length")
    pg.touchscreen.tap(st[0] + st[2] * .9, st[1] + 8); pg.wait_for_timeout(300)
    hand["erase_added"] = pg.evaluate("TF.CUR.fields.filter(f=>f.type==='erase').length") - ne
    pg.click("#ezBtn"); pg.wait_for_timeout(200)
    pg.click("#undoF"); pg.wait_for_timeout(200)
    R["hand"] = hand
    R["sw_s2"] = pg.evaluate("document.documentElement.scrollWidth")

    # ---------- C. 프리셋 ----------
    ps = {}
    pg.evaluate("localStorage.removeItem('tf_presets_v1')")
    pg.evaluate("TF.drawEditor()")
    nfix = pg.evaluate("TF.CUR.fields.filter(f=>!f._add&&f.type!=='erase').length")
    pg.evaluate("document.getElementById('psName').scrollIntoView({block:'center'})")
    pg.fill("#psName", "시험1"); pg.click("#psSave"); pg.wait_for_timeout(300)
    ps["toast_save"] = toast(pg)
    rec = pg.evaluate("JSON.parse(localStorage.getItem('tf_presets_v1'))")
    ps["saved"] = {"count": len(rec), "name": rec[0]["name"], "n": rec[0]["n"], "expected_n": nfix, "w": rec[0]["w"], "h": rec[0]["h"],
                   "field_keys": sorted(set(k for f in rec[0]["fields"] for k in f.keys())), "has_vals": "vals" in json.dumps(rec[0]).lower()}
    # 같은 이름 덮어쓰기 confirm
    d0 = len(dialogs); pg.fill("#psName", "시험1"); pg.click("#psSave"); pg.wait_for_timeout(300)
    ps["overwrite_dialog"] = dialogs[d0:]
    ps["count_after_overwrite"] = len(pg.evaluate("JSON.parse(localStorage.getItem('tf_presets_v1'))"))
    ps["fCount"] = pg.evaluate("document.getElementById('fCount').textContent")
    shot(pg, "after_390_preset.png", ".psbox")
    # 새로고침 후 유지
    pg.reload(wait_until="load"); pg.wait_for_timeout(1200)
    ps["after_reload"] = pg.evaluate("(JSON.parse(localStorage.getItem('tf_presets_v1'))||[]).map(p=>p.name+':'+p.n)")
    # 다른 사진(임대차) 등록 → 같은 라벨 값 → 불러오기
    register(f"{TFD}/tpl_lease.png")
    pg.evaluate("TF.VALS={'칸1':'홍길동','칸2':'010'}")
    d0 = len(dialogs); nb = pg.evaluate(CNT)
    pg.evaluate("document.querySelector('[data-pload]').scrollIntoView({block:'center'})")
    pg.click("[data-pload='0']"); pg.wait_for_timeout(400)
    ps["load"] = {"before": nb, "after": pg.evaluate(CNT), "preset_n": rec[0]["n"], "dialogs": dialogs[d0:], "toast": toast(pg),
                  "label_vals_kept": pg.evaluate("TF.CUR.fields.some(f=>f.label==='칸1') && TF.VALS['칸1']==='홍길동'")}
    pg.click("#undoF"); pg.wait_for_timeout(300)
    ps["undo_after_load"] = pg.evaluate(CNT)
    # 값이 3단계에서 그대로 보이는지
    pg.click("[data-pload='0']"); pg.wait_for_timeout(300)
    pg.evaluate("TF.go(3)"); pg.wait_for_timeout(500)
    ps["s3_shows_val"] = pg.evaluate("(()=>{const i=TF.CUR.fields.findIndex(f=>f.label==='칸1');const e=document.querySelector(`#valList [data-f=\"${i}\"]`);return e?e.value:null})()")
    # 비율이 다른 종이(가로로 긴 종이) — 경고
    pg.evaluate("""(async()=>{const c=document.createElement('canvas');c.width=1700;c.height=1000;const g=c.getContext('2d');g.fillStyle='#fff';g.fillRect(0,0,1700,1000);
      const im=new Image();await new Promise(r=>{im.onload=r;im.src=c.toDataURL('image/png')});TF.CUR={id:'ratio',name:'',fields:[],_new:true};TF.BG=im;TF.go(2);})()""")
    pg.wait_for_timeout(600)
    d0 = len(dialogs); pg.click("[data-pload='0']"); pg.wait_for_timeout(300)
    ps["ratio_dialog"] = dialogs[d0:]
    R["preset"] = ps

    # ---------- B. 다음 칸 / Enter ----------
    nx = {}
    pg.evaluate("localStorage.removeItem('tf_vals_b_trade')")
    pg.evaluate("TF.openForm('b_trade',3)"); pg.wait_for_timeout(900)
    nav = pg.evaluate("TF.navIdx()")
    nx["trade_fields"] = pg.evaluate("TF.CUR.fields.map(f=>f.type).filter(t=>t!=='erase').length")
    nx["trade_nav"] = len(nav)
    nx["calc_skipped"] = pg.evaluate("(()=>{const L=TF.navIdx();return Object.keys(TF.CUR.calc).every(k=>{const i=TF.CUR.fields.findIndex(f=>f.label===k);return i<0||L.indexOf(i)<0})})()")
    nx["sign_skipped"] = pg.evaluate("(()=>{const L=TF.navIdx();return TF.CUR.fields.every((f,i)=>f.type!=='sign'||L.indexOf(i)<0)})()")
    nx["sign_count"] = pg.evaluate("TF.CUR.fields.filter(f=>f.type==='sign').length")
    first = nav[0]
    pg.evaluate(f"document.querySelector('#valList [data-f=\"{first}\"]').scrollIntoView({{block:'center'}})")
    pg.click(f"#valList [data-f='{first}']"); pg.wait_for_timeout(200)
    # 한글 조합 중 Enter (isComposing / keyCode 229) → 이동 안 함
    comp = pg.evaluate("""(()=>{const a=document.activeElement;const r=[];
      for(const o of [{key:'Enter',isComposing:true},{key:'Enter',keyCode:229}]){const e=new KeyboardEvent('keydown',Object.assign({bubbles:true,cancelable:true},o));
        if(o.keyCode)Object.defineProperty(e,'keyCode',{get:()=>229});a.dispatchEvent(e);r.push(document.activeElement===a&&!e.defaultPrevented)}return r})()""")
    nx["composing_enter_stays"] = comp
    seq, ok = [], 0
    words = ["김", "태", "수", "홍길동", "12"]
    for k in range(5):
        cur = pg.evaluate("+document.activeElement.dataset.f")
        pg.keyboard.insert_text(words[k])
        pg.keyboard.press("Enter"); pg.wait_for_timeout(250)
        nxt = pg.evaluate("+document.activeElement.dataset.f")
        exp = next((i for i in nav if i > cur), None)
        seq.append([cur, nxt, exp]); ok += (nxt == exp)
    nx["enter_5"] = {"ok": ok, "seq": seq, "pos": pg.evaluate("document.getElementById('nfPos').textContent")}
    nx["vals_saved"] = pg.evaluate("Object.values(JSON.parse(localStorage.getItem('tf_vals_b_trade')||'{}')).filter(v=>['김','태','수','홍길동','12'].includes(v)).length")
    # [다음 칸 ▶] 3회
    btn = []
    for k in range(3):
        c0 = pg.evaluate("+document.activeElement.dataset.f")
        pg.tap("#nfNext"); pg.wait_for_timeout(450)
        btn.append([c0, pg.evaluate("+document.activeElement.dataset.f"), pg.evaluate("document.getElementById('nfPos').textContent")])
    nx["next_btn_3"] = btn
    pg.tap("#nfPrev"); pg.wait_for_timeout(400)
    nx["prev_btn"] = [pg.evaluate("+document.activeElement.dataset.f"), pg.evaluate("document.getElementById('nfPos').textContent")]
    nx["nf_btn_h"] = pg.evaluate("[...document.querySelectorAll('.nfrow button')].map(b=>Math.round(b.getBoundingClientRect().height))")
    pg.wait_for_timeout(500)
    shot(pg, "after_390_next.png", "#nfRow")
    # 계산 칸 자동 채움 그대로
    nx["calc_still_works"] = pg.evaluate("""(()=>{const F=TF.CUR.fields;const q=F.findIndex(f=>f.label==='수량1'),u=F.findIndex(f=>f.label==='단가1');
      const a=document.querySelector(`#valList [data-f="${q}"]`),b=document.querySelector(`#valList [data-f="${u}"]`);a.value='3';a.dispatchEvent(new Event('input',{bubbles:true}));b.value='1000';b.dispatchEvent(new Event('input',{bubbles:true}));return TF.VALS['금액1']})()""")
    # 마지막 칸 Enter
    last = nav[-1]
    pg.evaluate(f"document.querySelector('#valList [data-f=\"{last}\"]').focus()")
    pg.keyboard.press("Enter"); pg.wait_for_timeout(400)
    nx["last_enter"] = {"toast": toast(pg), "active": pg.evaluate("document.activeElement.id")}
    pg.evaluate("localStorage.removeItem('tf_vals_b_trade')")
    # 여러 줄 칸 — p_sale 특약사항
    pg.evaluate("localStorage.removeItem('tf_vals_p_sale')")
    pg.evaluate("TF.openForm('p_sale',3)"); pg.wait_for_timeout(1200)
    ta = pg.evaluate("(()=>{const t=document.querySelector('#valList textarea');t.scrollIntoView({block:'center'});return t.dataset.f})()")
    pg.wait_for_timeout(300)
    pg.click(f"#valList textarea[data-f='{ta}']")
    pg.keyboard.insert_text("첫째 줄"); pg.keyboard.press("Enter"); pg.keyboard.insert_text("둘째 줄"); pg.wait_for_timeout(200)
    nx["multi"] = {"value": pg.evaluate(f"document.querySelector('#valList textarea[data-f=\"{ta}\"]').value"),
                   "stayed": pg.evaluate(f"document.activeElement.dataset.f==='{ta}'")}
    pg.wait_for_timeout(400)
    pg.screenshot(path=f"{OUT}/after_390_multi.png"); SHOTS.append("after_390_multi.png")
    pg.tap("#nfNext"); pg.wait_for_timeout(450)
    nx["multi_next_btn"] = pg.evaluate("+document.activeElement.dataset.f")
    pg.evaluate("localStorage.removeItem('tf_vals_p_sale')")
    R["next"] = nx
    R["sw_s3"] = pg.evaluate("document.documentElement.scrollWidth")
    # 기본 양식에서 자동 빈칸 → 막힘
    pg.evaluate("TF.go(2)"); pg.wait_for_timeout(500)
    n_b = pg.evaluate(CNT); pg.click("#autoF"); pg.wait_for_timeout(300)
    R["builtin_blocked"] = {"toast": toast(pg), "unchanged": pg.evaluate(CNT) == n_b}
    pg.fill("#psName", "x"); pg.click("#psSave"); pg.wait_for_timeout(200)
    R["builtin_preset_blocked"] = toast(pg)

    R["errors"] = errs
    R["hosts_all"] = sorted(set(hosts))
    R["dialogs"] = dialogs
    R["shots"] = SHOTS
    print(json.dumps(R, ensure_ascii=False, indent=1))
    br.close()
