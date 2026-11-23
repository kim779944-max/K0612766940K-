"""원클릭 서비스 마인드맵 PNG 생성 — 문구는 TREE 만 고치고 다시 돌리면 된다.
usage: python make_mindmap.py OUTDIR   → OUTDIR/마인드맵.png, OUTDIR/src/mindmap.html
배지: ○ 시중에 흔함(실험 가치 낮음) · △ 있지만 우리 것이 다름 · ● 거의 없음 (148번)"""
import html, json, os, sys
from playwright.sync_api import sync_playwright

OUT = sys.argv[1]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# (번호, 이름, 경로, 한 줄, 배지, [하위])
TREE = [
  ("① 부동산·중개", "물건 하나가 계약까지 가는 순서", [
    ("1", "경사도", "slope/", "필지·임야 경사·단면 → A4·PNG", "△", []),
    ("2", "매물수집기", "realty/", "문자·카톡으로 온 매물 접수·정리", "●", []),
    ("3", "매물장", "listing/", "사진 2~4장 → A4 한 장 + 명함 + 챗봇", "△",
       [("3-1", "물건 포스터", "준비 중 · 설계도", "매물장에서 클릭 → 사진만 넣으면 A4 포스터(개요+권리분석)", "△")]),
    ("4", "재개발 진행조회기", "redev/", "지번 → 구역·단계·인가일", "△", []),
    ("5", "교환급매물 포털", "exchange", "급매·교환 물건 전문관", "●", []),
    ("6", "계약", "→연결", "③의 더양식(부동산 표준양식) → 더싸인 → 계약서 생성기", "", []),
  ]),
  ("② 사업자·매장", "상품을 만들고 팔고, 돈을 관리하는 순서", [
    ("1", "설명서 제작기", "thedetail/", "상품·매물 상세설명서 1초 (구 '더상세')", "○", []),
    ("2", "원클릭 셀러", "seller/", "담기 → 올리기 → 발주", "△", []),
    ("3", "이커머스 5종", "commerce/", "상품·블로그·인스타 자동", "○", []),
    ("4", "롱테일 키워드", "keyword", "검색어 발굴", "○", []),
    ("5", "오늘의 특가", "sale/", "도매 대용량·땡처리 → 발주서 1초", "△", []),
    ("6", "결제문자 가계부", "gagebu/", "카드 문자 → 장부", "○", []),
    ("7", "더통역", "tongyeok/", "외국 손님 응대", "○", []),
    ("8", "사업자 대출", "loan.html + tax.html", "한 화면 두 탭: 기업 대출 | 창업·세무", "△", []),
    ("9", "인테리어 견적", "interior/", "집·매장 자재 바꿔 보기 + 하·중·상 원가", "△", []),
  ]),
  ("③ 서류·계약", "서류를 받아서 처리하고 서명해 끝내는 순서", [
    ("1", "더스캔", "thescan/", "종이 → 스캔", "○", []),
    ("2", "더뷰", "viewer.html", "받은 파일 그대로 열람·저장(30~50장)", "△", []),
    ("3", "더양식", "theform/", "종이 양식 빈칸 채우기 + 표 사진→한글·엑셀 탭(구 문서변환기)", "△", []),
    ("4", "더지우개", "theeraser", "사진 글씨·얼룩 지우기", "○", []),
    ("5", "더싸인", "sign/", "사인·도장 → 투명 PNG → 날인·간인", "△", []),
    ("6", "계약서 생성기", "contract/", "매매·임대차 3부 인쇄", "○", []),
  ]),
  ("④ 생활·기록", "개인이 매일 쓰는 순서", [
    ("1", "폰정리", "organizer/", "중복·안 쓰는 앱 정리", "○", []),
    ("2", "세이캡", "saycap/", "말로 남기는 사진 기록 + 갤러리(통합)", "△", []),
    ("3", "독심술", "navi2/", "그림·질문 → 마음 읽기", "○", []),
    ("4", "호갱 탈출 내비", "hogang/", "휴대폰 월 납부액 최저", "○", []),
    ("5", "골프 스윙 교정", "golf/", "스윙 사진 비교", "○", []),
    ("6", "동물 번역기", "petmind/", "반려동물 소리·표정 (실험 가치 낮음)", "○", []),
  ]),
  ("준비 중", "보이기만 · 클릭 0", [
    ("·", "혼합 장부 취합기", "append", "여러 장부 합치기", "△", []),
    ("·", "유튜브 1초 최적화", "youtube", "제목·썸네일 문구·해시태그", "○", []),
    ("·", "여행 패스", "travel", "전국 펜션 10박", "△", []),
  ]),
]

e = html.escape
def leaf(n, nm, path, line, bd, cls=""):
    b = f'<span class="bd {({"○":"o","△":"t","●":"f"}).get(bd,"n")}">{e(bd)}</span>' if bd else '<span class="bd"></span>'
    return (f'<div class="leaf {cls}"><span class="n">{e(n)}</span><b>{e(nm)}</b>'
            f'<span class="p">{e(path)}</span>{b}<span class="l">{e(line)}</span></div>')

rows = []
for bi, (bt, bs, items) in enumerate(TREE):
    lv = []
    for (n, nm, path, line, bd, subs) in items:
        s = ''.join(f'<div class="subwrap">{leaf(a, b, c, d, f, "sub")}</div>' for (a, b, c, d, f) in subs)
        lv.append(f'<div class="item">{leaf(n, nm, path, line, bd, "link" if path=="→연결" else "")}{s}</div>')
    rows.append(f'<div class="br{" soon" if bt=="준비 중" else ""}"><div class="bnode"><b>{e(bt)}</b><span>{e(bs)}</span></div>'
                f'<div class="leaves">{"".join(lv)}</div></div>')

PAGE = f"""<!doctype html><html lang="ko"><head><meta charset="utf-8"><style>
*{{box-sizing:border-box}}
body{{margin:0;background:#0B1730;color:#EAF0F8;font-family:'Malgun Gothic','맑은 고딕',sans-serif;width:3400px}}
#wrap{{position:relative;padding:70px 80px 60px}}
h1{{margin:0 0 6px;font-size:44px;color:#fff;letter-spacing:-1px}}
.cap{{font-size:22px;color:#9FB0C8;margin:0 0 40px}}
.cap b{{color:#FF8A33}}
.lg{{display:inline-flex;gap:22px;margin-left:24px;font-size:21px;color:#C9D4E3}}
#tree{{display:flex;align-items:center;gap:150px;position:relative}}
.center{{flex:0 0 auto;background:#FF6B00;color:#fff;border-radius:28px;padding:34px 40px;text-align:center;box-shadow:0 0 0 6px rgba(255,107,0,.25)}}
.center b{{display:block;font-size:52px;letter-spacing:-1px}}.center span{{font-size:22px;opacity:.92}}
.branches{{display:flex;flex-direction:column;gap:46px}}
.br{{display:flex;align-items:center;gap:120px}}
.bnode{{flex:0 0 360px;border:3px solid #FF6B00;background:#13254A;border-radius:22px;padding:22px 24px}}
.bnode b{{display:block;font-size:34px;color:#FFB070}}.bnode span{{display:block;font-size:20px;color:#BFCBDD;margin-top:6px;line-height:1.35}}
.br.soon .bnode{{border-color:#5B6B86;background:#18233A}}.br.soon .bnode b{{color:#AEBACB}}
.leaves{{display:flex;flex-direction:column;gap:12px}}
.item{{display:flex;align-items:center;gap:90px}}
.leaf{{display:flex;align-items:center;gap:14px;background:#142A52;border:2px solid #2C4675;border-radius:14px;padding:12px 18px;width:1520px;font-size:23px}}
.leaf.sub{{width:1000px;border-style:dashed;border-color:#FF8A33;background:#1A2B4C}}
.leaf.link{{border-style:dashed;border-color:#6B83AE;background:#101F3D}}
.br.soon .leaf{{opacity:.7;background:#17213A;border-color:#3A4964}}
.leaf .n{{flex:0 0 46px;color:#FF8A33;font-weight:900}}
.leaf b{{flex:0 0 280px;font-size:26px;color:#fff}}
.leaf .p{{flex:0 0 270px;font-family:Consolas,monospace;font-size:19px;color:#8FB4E8}}
.leaf .l{{flex:1;color:#D3DCEA;line-height:1.3}}
.bd{{flex:0 0 40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:900}}
.bd.o{{background:#3A4A66;color:#C9D4E3}}.bd.t{{background:#FFE2C7;color:#B34A00}}.bd.f{{background:#FF6B00;color:#fff}}
svg{{position:absolute;left:0;top:0;pointer-events:none;overflow:visible}}
.foot{{margin-top:44px;font-size:20px;color:#8D9DB6;line-height:1.6}}
</style></head><body><div id="wrap">
<h1>원클릭 서비스 마인드맵 — 「쓰는 순서」 축 (2026-11-23 확정)</h1>
<p class="cap">중심 1 → 대분류 4 + 준비 중 → 상품 → (하위 단계) · <b>한 상품은 한 곳에만</b>, 다른 가지에서는 →연결로만 가리킴
<span class="lg"><span class="bd f" style="display:inline-flex">●</span>거의 없음 <span class="bd t" style="display:inline-flex">△</span>있지만 우리 것이 다름 <span class="bd o" style="display:inline-flex">○</span>시중에 흔함(실험 가치 낮음)</span></p>
<div id="tree"><div class="center"><b>원클릭</b><span>autooneclick.com</span></div>
<div class="branches">{''.join(rows)}</div></div>
<p class="foot">쇼룸 제외(트리 밖 · 폴더는 유지): 답글생성기 ad_magnet/ (내부용 · 165) · 번개알바 bungee/ (별도 플랫폼 · 156) · 군단 상황판 ops/ (마스터 전용)<br>
통합: 문서변환기(photo2doc) → 더양식 ② 탭 (158) · 창업·대출 세무구조 내비(tax) → 사업자 대출 탭 (162) · 갤러리 → 세이캡 (166) · 더상세 → 설명서 제작기 (161)<br>
148 배지는 지니 1차 판정(대표님 최종 판정 대기) · 유튜브 1초 최적화·여행 패스는 PC 추가 판정</p>
<svg id="lines"></svg></div>
<script>
(function(){{
 var W=document.getElementById('wrap'), S=document.getElementById('lines'), wr=W.getBoundingClientRect();
 S.setAttribute('width',W.scrollWidth); S.setAttribute('height',W.scrollHeight);
 function R(el){{var r=el.getBoundingClientRect();return {{l:r.left-wr.left,r:r.right-wr.left,y:(r.top+r.bottom)/2-wr.top}};}}
 function line(a,b,c,dash){{var p=document.createElementNS('http://www.w3.org/2000/svg','path');var mx=(a.r+b.l)/2;
  p.setAttribute('d','M'+a.r+' '+a.y+' C'+mx+' '+a.y+' '+mx+' '+b.y+' '+b.l+' '+b.y);p.setAttribute('fill','none');
  p.setAttribute('stroke',c);p.setAttribute('stroke-width',dash?3:4);if(dash)p.setAttribute('stroke-dasharray','10 8');S.appendChild(p);}}
 var C=R(document.querySelector('.center'));
 document.querySelectorAll('.br').forEach(function(br){{
  var bn=R(br.querySelector('.bnode')), soon=br.classList.contains('soon');
  line(C,bn,soon?'#5B6B86':'#FF6B00',soon);
  br.querySelectorAll(':scope > .leaves > .item').forEach(function(it){{
   var lf=it.querySelector(':scope > .leaf'); line(bn,R(lf),soon?'#4A5A75':'#4E78C0',soon||lf.classList.contains('link'));
   it.querySelectorAll('.subwrap .leaf').forEach(function(s){{line(R(lf),R(s),'#FF8A33',true);}});
  }});
 }});
}})();
</script></body></html>"""

os.makedirs(os.path.join(OUT, "src"), exist_ok=True)
hp = os.path.join(OUT, "src", "mindmap.html")
open(hp, "w", encoding="utf-8").write(PAGE)
with sync_playwright() as p:
    br = p.chromium.launch(executable_path=CHROME, headless=True)
    pg = br.new_page(viewport={"width": 3400, "height": 1200}, device_scale_factor=1)
    pg.goto("file:///" + os.path.abspath(hp).replace("\\", "/")); pg.wait_for_timeout(600)
    info = pg.evaluate("""(()=>{const ls=[...document.querySelectorAll('.leaf,.bnode,.center')].map(e=>e.getBoundingClientRect());
      let ov=0; for(let i=0;i<ls.length;i++)for(let j=i+1;j<ls.length;j++){const a=ls[i],b=ls[j];
        if(a.left<b.right-1&&b.left<a.right-1&&a.top<b.bottom-1&&b.top<a.bottom-1)ov++;}
      const clip=[...document.querySelectorAll('.leaf .l,.leaf b,.bnode span,.bnode b')].filter(e=>e.scrollWidth>e.clientWidth+1).length;
      return {w:document.body.scrollWidth,h:document.documentElement.scrollHeight,overlap:ov,clipped:clip,
              nodes:document.querySelectorAll('.leaf').length};})()""")
    pg.screenshot(path=os.path.join(OUT, "마인드맵.png"), full_page=True)
    br.close()
info["png_bytes"] = os.path.getsize(os.path.join(OUT, "마인드맵.png"))
print(json.dumps(info, ensure_ascii=False))
