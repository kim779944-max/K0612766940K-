"""도우미 검증: 12개 도구(사전) 캡처·단계 대상·겹침·네트워크·인쇄 + 45개 전 페이지 로드 확인."""
import json, sys, time
from playwright.sync_api import sync_playwright

CAP = sys.argv[1]
BASE = "http://127.0.0.1:8791/"
TOOLS = [("index", ""), ("redev", "redev/"), ("sign", "sign/"), ("gagebu", "gagebu/"), ("slope", "slope/"),
         ("hogang", "hogang/"), ("thescan", "thescan/"), ("thedetail", "thedetail/"), ("theform", "theform/"),
         ("contract", "contract/"), ("sale", "sale/"), ("converter_auto", "converter.html")]
ALL = sys.argv[2].split(",") if len(sys.argv) > 2 else []

MEASURE = """(()=>{
 const H=innerHeight,W=innerWidth,b=document.getElementById('kts-helper-btn');
 if(!b) return null;
 const rb=b.getBoundingClientRect();
 const inter=(a,c)=>Math.max(0,Math.min(a.right,c.right)-Math.max(a.left,c.left))*Math.max(0,Math.min(a.bottom,c.bottom)-Math.max(a.top,c.top));
 const bars=[];
 document.querySelectorAll('body *').forEach(el=>{
   if(el===b||el.closest('#kts-helper')) return;
   const cs=getComputedStyle(el); if(cs.position!=='fixed'||cs.display==='none'||cs.visibility==='hidden') return;
   const r=el.getBoundingClientRect(); if(r.height<=0||r.width<=0) return;
   if(r.top>=H*0.5 && r.bottom>=H-1 && r.width>=W*0.5) bars.push({sel:(el.id?'#'+el.id:el.className&&typeof el.className==='string'?'.'+el.className.split(' ')[0]:el.tagName),h:Math.round(r.height),top:Math.round(r.top),x:inter(rb,r)});
 });
 const tt=document.querySelector('.totop,#toTop'); let tti=null;
 if(tt){const r=tt.getBoundingClientRect(); tti={rect:[Math.round(r.left),Math.round(r.top),Math.round(r.right),Math.round(r.bottom)],x:inter(rb,r)};}
 // 하단 고정 요소 중 버튼과 겹치는 모든 fixed 요소 (토스트·dim 제외: opacity 0 / 전체화면)
 const over=[];
 document.querySelectorAll('body *').forEach(el=>{
   if(el===b||el.closest('#kts-helper')||b.contains(el)) return;
   const cs=getComputedStyle(el); if(cs.position!=='fixed'||cs.display==='none'||cs.visibility==='hidden'||+cs.opacity===0) return;
   const r=el.getBoundingClientRect(); if(r.width>=W*0.95&&r.height>=H*0.9) return;
   const x=inter(rb,r); if(x>0) over.push((el.id?'#'+el.id:'.'+String(el.className).split(' ')[0])+':'+Math.round(x));
 });
 return {btn:[Math.round(rb.left),Math.round(rb.top),Math.round(rb.right),Math.round(rb.bottom)],w:Math.round(rb.width),h:Math.round(rb.height),
   bottom:getComputedStyle(b).bottom,z:getComputedStyle(b).zIndex,bars,totop:tti,overlaps:over,sw:document.documentElement.scrollWidth};
})()"""

STEPCHECK = """(()=>{
 const H=window.KTS_HELPER; const st=H.steps();
 return st.map(s=>{ let el=s.el; if(!el&&s.sel){ for(const q of s.sel){ const e=document.querySelector(q); if(e&&(e.offsetWidth||e.offsetHeight||e.getClientRects().length)){el=e;break;} } }
   return {t:s.t, found:!!el, y: el? Math.round(el.getBoundingClientRect().top+scrollY):null}; });
})()"""

res = {"tools": {}, "all": {}}
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe", headless=True)
    ctx = br.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2, is_mobile=True, has_touch=True,
                         service_workers="block")
    for name, url in TOOLS:
        pg = ctx.new_page()
        errs, reqs = [], []
        pg.on("pageerror", lambda e, errs=errs: errs.append(str(e)[:160]))
        pg.on("console", lambda m, errs=errs: errs.append(m.text[:160]) if m.type == "error" else None)
        pg.on("request", lambda r, reqs=reqs: reqs.append(r.url))
        pg.goto(BASE + url, wait_until="load")
        pg.wait_for_timeout(1800)
        r = {"key": pg.evaluate("KTS_HELPER.key"), "tool": pg.evaluate("KTS_HELPER.tool()")}
        r["top"] = pg.evaluate(MEASURE)
        pg.evaluate("scrollTo(0,document.documentElement.scrollHeight)"); pg.wait_for_timeout(2300)
        r["bottom_scrolled"] = pg.evaluate(MEASURE)
        pg.screenshot(path=f"{CAP}/helper_{name}_btn_390.png")
        pg.evaluate("scrollTo(0,0)"); pg.wait_for_timeout(300)
        n0 = len(reqs)
        pg.click("#kts-helper-btn"); pg.wait_for_timeout(300)
        r["steps"] = pg.evaluate(STEPCHECK)
        r["panel"] = pg.evaluate("(()=>{const s=document.querySelector('#kts-helper .kh-sh').getBoundingClientRect();return {w:Math.round(s.width),h:Math.round(s.height),maxh:getComputedStyle(document.querySelector('#kts-helper .kh-sh')).maxHeight,z:getComputedStyle(document.getElementById('kts-helper')).zIndex,head:document.querySelector('#kts-helper .kh-hd b').textContent}})()")
        pg.screenshot(path=f"{CAP}/helper_{name}_390.png")
        # FAQ · 묻기 · 신고 · 문의
        pg.click("[data-kh-t='1']"); pg.click("#kts-helper details[data-i='0'] summary"); pg.wait_for_timeout(100)
        r["faq_free"] = pg.evaluate("document.querySelector('#kts-helper details[data-i=\"0\"] p').textContent")
        pg.fill("#kh-q", "주차장 몇 대 있어요?"); pg.click("[data-kh='ask']")
        pg.fill("#kh-q", "저장이 안 돼요"); pg.click("[data-kh='ask']")
        r["ask"] = pg.evaluate("[...document.querySelectorAll('#kh-log .bot')].map(x=>x.textContent)")
        if name == "redev":
            pg.screenshot(path=f"{CAP}/helper_{name}_faq_390.png")
        pg.click("[data-kh-t='2']"); pg.fill("#kh-rep", "검증용 신고 — " + name); pg.click("[data-kh='send']"); pg.wait_for_timeout(100)
        r["report"] = pg.evaluate("(()=>{const l=JSON.parse(localStorage.getItem('kts_helper_report_v1')||'[]');return {n:l.length,last:l[l.length-1],sms:document.getElementById('kh-sms').getAttribute('href').slice(0,80)}})()")
        if name == "index":
            pg.screenshot(path=f"{CAP}/helper_{name}_report_390.png")
        pg.click("[data-kh-t='3']")
        r["contact"] = pg.evaluate("[...document.querySelectorAll('#kts-helper [data-kh-p=\"3\"] a')].map(a=>a.getAttribute('href').slice(0,60))")
        # 여기로 (1단계)
        pg.click("[data-kh-t='0']"); pg.click("[data-kh='go'][data-i='0']"); pg.wait_for_timeout(700)
        r["go_closed"] = pg.evaluate("!document.getElementById('kts-helper').classList.contains('on')")
        pg.click("#kts-helper-btn"); pg.wait_for_timeout(150); pg.click("#kts-helper", position={"x": 10, "y": 10}); pg.wait_for_timeout(150)
        r["dim_closes"] = pg.evaluate("!document.getElementById('kts-helper').classList.contains('on')")
        r["helper_window_requests"] = reqs[n0:]
        pg.emulate_media(media="print")
        r["print_display"] = pg.evaluate("getComputedStyle(document.getElementById('kts-helper-btn')).display")
        pg.emulate_media(media="screen")
        r["errors"] = errs
        res["tools"][name] = r
        pg.close()
    for u in ALL:
        pg = ctx.new_page()
        errs = []
        pg.on("pageerror", lambda e, errs=errs: errs.append(str(e)[:160]))
        try:
            pg.goto(BASE + u, wait_until="load", timeout=20000)
            pg.wait_for_timeout(1200)
            info = pg.evaluate("[!!window.KTS_HELPER, !!document.getElementById('kts-helper-btn'), window.KTS_HELPER?KTS_HELPER.key:null, window.KTS_HELPER?KTS_HELPER.tool():null, location.pathname, (()=>{const b=document.getElementById('kts-helper-btn');return b?getComputedStyle(b).bottom:null})()]")
        except Exception as e:
            info = ["ERR", str(e)[:120]]
        res["all"][u] = {"info": info, "errors": errs}
        pg.close()
    br.close()
print(json.dumps(res, ensure_ascii=False, indent=1))
