"""133·138번 검증: 390 실측 · 대표 3종 첫 화면 · 목록 완전성 · 도우미 겹침 · 열기 클릭 · 마스터 · 테마 · A4 인쇄 · 콘솔."""
import json, sys
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
BASE = sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8792/"
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
R = {}

COMPLETE = """(()=>{var all=[];(window.PRODUCTS||[]).forEach(function(p){all.push(p.k)});
Object.keys(window.LOCAL||{}).forEach(function(k){all.push(k)});
var G=window.__KTS_GROUPS,seen={},dup=[];G.forEach(function(g){g.ks.forEach(function(k){if(seen[k])dup.push(k);seen[k]=1})});
var miss=all.filter(function(k){return !seen[k]});var extra=Object.keys(seen).filter(function(k){return all.indexOf(k)<0});
var dom=[...document.querySelectorAll('#sections .row')].length;
return {products:(window.PRODUCTS||[]).length,local:Object.keys(window.LOCAL||{}).length,total:all.length,groups:Object.keys(seen).length,
 miss:miss,dup:dup,extra:extra,domRows:dom,catalog:(window.KTS_CATALOG||{}).v}})()"""

MEAS = """(()=>{const R=e=>{const r=e.getBoundingClientRect();return {x:Math.round(r.left),y:Math.round(r.top),w:Math.round(r.width),h:Math.round(r.height),b:Math.round(r.bottom)}};
const feat=[...document.querySelectorAll('#featRows .row')].map(e=>Object.assign(R(e),{nm:e.querySelector('.nm').textContent,btn:e.querySelector('.go').textContent}));
const hs=[...document.querySelectorAll('.k-theme, #featRows .go, #sections .go, .heroBtns .k-btn')].map(e=>e.getBoundingClientRect().height);
const small=[...document.querySelectorAll('body *')].filter(e=>e.offsetParent!==null&&e.childNodes.length&&[...e.childNodes].some(n=>n.nodeType===3&&n.textContent.trim())).map(e=>parseFloat(getComputedStyle(e).fontSize)).filter(f=>f<10.5).length;
return {sw:document.documentElement.scrollWidth,iw:innerWidth,feat:feat,minBtnH:Math.min(...hs),btnCount:hs.length,
 theme:R(document.querySelector('.k-theme')),hdH:Math.round(document.querySelector('header .hd').getBoundingClientRect().height),
 smallTextUnder10_5:small,
 secTitles:[...document.querySelectorAll('#sections .secH')].map(e=>e.querySelector('.no').textContent+' '+e.querySelector('h2').textContent+' ('+e.parentNode.querySelectorAll('.row').length+')'),
 order:[...document.querySelectorAll('#app > *')].filter(e=>e.offsetParent!==null||e.tagName==='HEADER').map(e=>e.id||e.className).slice(0,20)}})()"""

OVERLAP = """(()=>{const hit=(a,b)=>!(a.right<=b.left||a.left>=b.right||a.bottom<=b.top||a.top>=b.bottom);
const H=document.getElementById('kts-helper-btn'),T=document.getElementById('toTop');
const hr=H.getBoundingClientRect(),tr=T.getBoundingClientRect(),tOn=T.classList.contains('on');
const acts=[...document.querySelectorAll('.act .go, .act .soonb, .ks-strip .c')].filter(e=>{const r=e.getBoundingClientRect();return r.bottom>0&&r.top<innerHeight});
let nH=0,nT=0;acts.forEach(e=>{const r=e.getBoundingClientRect();if(hit(hr,r))nH++;if(tOn&&hit(tr,r))nT++});
return {scrollY:Math.round(scrollY),helper:{l:Math.round(hr.left),t:Math.round(hr.top),w:hr.width,h:hr.height,bottomCss:getComputedStyle(H).bottom},
 totop:{l:Math.round(tr.left),t:Math.round(tr.top),on:tOn,bottomCss:getComputedStyle(T).bottom},visibleActs:acts.length,hitHelper:nH,hitTotop:nT,helperVsTotop:hit(hr,tr)}})()"""


def ctx_new(br, w=390, h=844):
    return br.new_context(viewport={"width": w, "height": h}, device_scale_factor=2, is_mobile=w < 700, has_touch=w < 700,
                          service_workers="block")


with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    ctx = ctx_new(br)
    pg = ctx.new_page()
    errs = []
    pg.on("pageerror", lambda e: errs.append("pageerror " + str(e)[:200]))
    pg.on("console", lambda m: errs.append("console " + m.text[:200]) if m.type == "error" else None)
    pg.goto(BASE, wait_until="networkidle")
    pg.wait_for_function("window.KTS_CATALOG && window.KTS_CATALOG.v==='20261123a'", timeout=15000)
    pg.wait_for_timeout(800)
    R["htmlTheme0"] = pg.evaluate("document.documentElement.getAttribute('data-kts-theme')")
    R["measure"] = pg.evaluate(MEAS)
    R["complete"] = pg.evaluate(COMPLETE)
    pg.screenshot(path=f"{OUT}/first_390.png")
    pg.screenshot(path=f"{OUT}/full_390_dark.png", full_page=True)

    # 도우미 겹침 — 스크롤 3곳
    H = pg.evaluate("document.documentElement.scrollHeight")
    ov = []
    for i, y in enumerate([0, H // 2, H]):
        pg.evaluate(f"window.scrollTo(0,{y})"); pg.wait_for_timeout(2600)  # helper place() 2초 주기
        ov.append(pg.evaluate(OVERLAP))
        pg.screenshot(path=f"{OUT}/helper_390_{['top','mid','bottom'][i]}.png")
    R["overlap"] = ov

    # 가계부 카드 텍스트(중복 문구 확인)
    R["gagebuCard"] = pg.evaluate("(()=>{const b=document.querySelector('#sections [data-open=\"gagebu\"]');const r=b&&b.closest('.row');return r?r.innerText:null})()")
    R["listingCard"] = pg.evaluate("(()=>{const r=[...document.querySelectorAll('#sections .row')].find(e=>e.querySelector('a.main[href*=\"k=listing\"]'));return r?{text:r.innerText,soon:r.classList.contains('soon'),btnDisabled:r.querySelector('.go').disabled,img:r.querySelector('img')&&r.querySelector('img').naturalWidth}:null})()")
    R["preserved"] = pg.evaluate("""(()=>({kBtn:!!document.getElementById('kBtn'),mKey:!!document.getElementById('mKey'),askOpen:!!document.getElementById('askOpen'),
      sms:!!document.querySelector('a[href^="sms:01020022899"]'),toTop:!!document.getElementById('toTop'),boxStrip:!!document.querySelector('#boxStrip .ks-strip'),
      scripts:[...document.scripts].map(s=>s.src.split('/').pop()).filter(Boolean),detailLinks:document.querySelectorAll('a[href^="detail.html?k="]').length,
      KTS_KEYS:!!window.KTS_KEYS,helper:!!document.getElementById('kts-helper-btn')}))()""")

    # 히어로 버튼 스크롤
    pg.evaluate("window.scrollTo(0,0)"); pg.wait_for_timeout(300)
    pg.click(".heroBtns a[data-jump='allGroups']"); pg.wait_for_timeout(1200)
    R["jumpAllGroups"] = pg.evaluate("Math.round(document.getElementById('allGroups').getBoundingClientRect().top)")

    # [열기] 클릭 — 4묶음에서 각 2개씩 (마스터 모드 없이, 1회 무료 시연 관문 그대로)
    picks = ['realty', 'slope', 'commerce', 'thedetail', 'gagebu', 'loan', 'sale', 'hogang']
    opens = []
    for k in picks:
        pg.goto(BASE, wait_until="networkidle"); pg.wait_for_timeout(600)
        st = None
        try:
            with pg.expect_navigation(timeout=6000) as nav:
                pg.click(f"#sections [data-open='{k}']")
            resp = nav.value
            st = resp.status if resp else None
        except Exception as e:
            st = "no-nav: " + str(e)[:80]
        opens.append({"k": k, "url": pg.url.replace(BASE, '/'), "status": st})
    R["opens"] = opens
    # 대표 3종 [열기]
    fo = []
    # 같은 기기에서 같은 도구를 두 번째 열면 1회 무료 시연 관문(내 박스 안내)이 뜨는 것이 정상 → 새 기기(컨텍스트)로 확인
    for k in ['sign', 'slope']:
        cf = ctx_new(br); pf = cf.new_page()
        pf.goto(BASE, wait_until="networkidle"); pf.wait_for_timeout(600)
        try:
            with pf.expect_navigation(timeout=6000) as nav:
                pf.click(f"#featRows [data-open='{k}']")
            fo.append({"k": k, "url": pf.url.replace(BASE, '/'), "status": nav.value.status if nav.value else None})
            pf.go_back(); pf.wait_for_timeout(500)
            fo[-1]["backOk"] = pf.url.rstrip('/') == BASE.rstrip('/')
        except Exception as e:
            fo.append({"k": k, "err": str(e)[:80]})
        cf.close()
    # 두 번째 열기 = 관문 동작 확인(같은 기기에서 slope 재열기)
    pg.goto(BASE, wait_until="networkidle"); pg.wait_for_timeout(500)
    pg.click("#featRows [data-open='slope']"); pg.wait_for_timeout(1200)
    fo.append({"gateOnSecondOpen": pg.evaluate("({url:location.pathname,modal:!!document.querySelector('.kk-dim')})")})
    pg.screenshot(path=f"{OUT}/gate_second_open.png")
    R["featOpens"] = fo

    # 마스터
    pg.goto(BASE + "?master=2899", wait_until="networkidle"); pg.wait_for_timeout(1000)
    R["master"] = pg.evaluate("({shown:!document.getElementById('mst').hidden,mstN:document.getElementById('mstN').textContent,grid:document.querySelectorAll('#mstGrid a').length,live:(window.PRODUCTS||[]).filter(p=>p.status==='live'&&p.link).length})")
    pg.screenshot(path=f"{OUT}/master_390.png")
    pg.click("#mstOff"); pg.wait_for_timeout(300)

    # 테마
    th = []
    pg.goto(BASE, wait_until="networkidle"); pg.wait_for_timeout(500)
    st = lambda: pg.evaluate("[document.documentElement.getAttribute('data-kts-theme'),localStorage.getItem('kts_theme'),document.querySelector('.k-theme').textContent,document.querySelector('.k-theme').getAttribute('aria-label'),getComputedStyle(document.body).backgroundColor]")
    th.append(["start"] + st())
    pg.click(".k-theme"); pg.wait_for_timeout(300); th.append(["toggle1"] + st())
    pg.screenshot(path=f"{OUT}/first_390_light.png")
    pg.screenshot(path=f"{OUT}/full_390_light.png", full_page=True)
    pg.reload(wait_until="networkidle"); pg.wait_for_timeout(500); th.append(["reload"] + st())
    pg.click(".k-theme"); pg.wait_for_timeout(300); th.append(["toggle2"] + st())
    pg.reload(wait_until="networkidle"); pg.wait_for_timeout(500); th.append(["reload2"] + st())
    R["theme"] = th

    # 인쇄 — 라이트·다크 둘 다 흰 배경 강제
    pr = {}
    for t in ['dark', 'light']:
        pg.evaluate(f"KTSUI.setTheme('{t}')")
        pg.emulate_media(media="print"); pg.wait_for_timeout(300)
        pr[t] = pg.evaluate("({bodyBg:getComputedStyle(document.body).backgroundColor,nmColor:getComputedStyle(document.querySelector('#sections .nm')).color,h1:getComputedStyle(document.querySelector('h1')).color,themeBtn:getComputedStyle(document.querySelector('.k-theme')).display,header:getComputedStyle(document.querySelector('header')).display,helper:getComputedStyle(document.getElementById('kts-helper-btn')).display})")
        pg.screenshot(path=f"{OUT}/print_preview_{t}.png", full_page=True)
        pg.emulate_media(media="screen")
    pg.evaluate("KTSUI.setTheme('dark')")
    pg.pdf(path=f"{OUT}/print_a4.pdf", format="A4", print_background=True)
    pg.emulate_media(media="print"); pg.wait_for_timeout(200)
    pg.set_viewport_size({"width": 794, "height": 1123}); pg.wait_for_timeout(300)
    pg.screenshot(path=f"{OUT}/print_a4.png")
    pg.emulate_media(media="screen")
    R["print"] = pr

    # detail.html — 새 이름
    pg.set_viewport_size({"width": 390, "height": 844})
    pg.goto(BASE + "detail.html?k=gagebu", wait_until="networkidle"); pg.wait_for_timeout(800)
    R["detailGagebu"] = pg.evaluate("({title:document.title,has:document.body.innerText.indexOf('결제문자 가계부')>=0,old:document.body.innerText.indexOf('원클릭 가계부')>=0})")
    pg.screenshot(path=f"{OUT}/detail_gagebu.png")
    pg.goto(BASE + "detail.html?k=listing", wait_until="networkidle"); pg.wait_for_timeout(800)
    R["detailListing"] = pg.evaluate("({title:document.title,has:document.body.innerText.indexOf('매물장 뷰어')>=0,brokenImg:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).map(i=>i.getAttribute('src'))})")
    pg.screenshot(path=f"{OUT}/detail_listing.png")
    R["errors390"] = errs[:]

    # 넓은 화면 — 도우미 위치
    c2 = ctx_new(br, 1280, 900); p2 = c2.new_page()
    e2 = []
    p2.on("pageerror", lambda e: e2.append(str(e)[:200]))
    p2.on("console", lambda m: e2.append(m.text[:200]) if m.type == "error" else None)
    p2.goto(BASE, wait_until="networkidle"); p2.wait_for_timeout(2500)
    p2.evaluate("window.scrollTo(0,1400)"); p2.wait_for_timeout(2500)
    R["wide"] = p2.evaluate(OVERLAP); R["wide"]["app"] = p2.evaluate("(()=>{const r=document.getElementById('app').getBoundingClientRect();return [Math.round(r.left),Math.round(r.right)]})()")
    R["wide"]["hdH"] = p2.evaluate("Math.round(document.querySelector('header .hd').getBoundingClientRect().height)")
    p2.screenshot(path=f"{OUT}/wide_1280.png")
    R["errorsWide"] = e2
    br.close()

json.dump(R, open(f"{OUT}/verify.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(json.dumps(R, ensure_ascii=False, indent=1))
