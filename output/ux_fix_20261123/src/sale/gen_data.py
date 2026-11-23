"""160번 data.js 재생성 — sale_before.json(기존 window.SALE) + det/*.json(떠리몰 상세, 2026-11-24 04:45 확인).
원칙: 정가(o)는 확인된 값만. 지난 행사(끝난 날 < 11/24)는 뺀다. 새 값은 src 에 확인처·확인일."""
import json, re, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
D = json.load(open(os.path.join(HERE, "sale_before.json"), encoding="utf-8"))
ASOF = (11, 24)
CHK = "2026-11-24 확인"


def det(n):
    d = json.load(open(os.path.join(HERE, "det", f"{n}.json"), encoding="utf-8"))
    sp = int(d["price"]["salePrice"]); f = sp - int(d["price"]["immediateDiscountAmt"])
    ex = d["baseInfo"].get("expirationYmdt")
    return sp, f, (ex[5:7].lstrip("0") + "/" + ex[8:10].lstrip("0")) if ex else None


def ended(u):
    if not u: return False
    if "종료" in u: return True
    part = str(u).split("~").pop()
    part = re.sub(r"까지|부터|\(.*?\)", "", part)
    m = re.search(r"(\d{1,2})/(\d{1,2})", part)
    if not m or "부터" in u: return False
    return (int(m.group(1)), int(m.group(2))) < ASOF


FOODY_CVS = {"삼양", "김희은", "CJ", "간편식"}
groups = []

# ── ① 오늘의 도매 특가 — 도매 대용량(박스·카톤) ──
WHOLE = [  # (상품번호, id, 이름, spec, kind, pack, 개수(개당 계산용), 비고)
    (122200212, "w01", "외갓집 진심 육개장 600g × 15팩", "냉동 · 업소 대용량", "food", "15팩", 15, "15팩 한 박스"),
    (122200211, "w02", "외갓집 서정리 부대찌개 1kg × 7팩", "냉동 · 업소 대용량", "food", "7팩", 7, "7팩 한 박스"),
    (136670271, "w03", "마부 코코주스 320ml × 24개입", "음료 · 박스 (망고/파인애플/딸기)", "goods", "24개", 24, "24개 한 박스"),
    (137655697, "w04", "도시바 알카라인 AAA 건전지 60개입", "벌크형 대용량", "goods", "60개", 60, "벌크 60개"),
    (137640509, "w05", "진짜사나이 핫팩 150g × 120매", "1카톤 · 업소·현장용", "life", "120매", 120, "1카톤"),
    (135700443, "w06", "명진 마이마이 고무장갑(소) × 10개", "주방 소모품 · 묶음", "life", "10개", 10, "10개 묶음"),
    (133558602, "w07", "코끼리리빙 퍼퓸 건조기시트 40매 × 10개", "세탁 소모품 · 체리블라썸향", "life", "400매", 400, "10개 묶음"),
]
for n, gid, nm, spec, kind, pack, cnt, note in WHOLE:
    sp, f, ex = det(n)
    pc = round((1 - f / sp) * 100)
    groups.append({"id": gid, "k": kind, "blk": "whole", "item": nm, "spec": spec, "tag": "도매",
                   "offers": [{"st": "떠리몰 대량구매관", "p": f, "o": sp, "pack": pack, "each": f // cnt,
                               "c": f"대량구매 {pc}% · {note}", "u": "재고 소진 시",
                               "src": f"떠리몰 대량구매관 상품 {n} 표시 정가·판매가 ({CHK})"}]})

# ── ② 오늘의 도매 특가 — 유통기한 임박 땡처리 ──
DDANG = [
    (137655555, "d01", "육향가 한돈 고추장 제육불고기 300g", "냉동 · 5개 단위 구매", "food", "1팩", 1),
    (133457842, "d02", "진주햄 무항생제 순수안심비엔나 350g", "냉장 · 5팩 단위 구매", "food", "1팩", 1),
    (137601487, "d03", "타이댄서 스리라차 칠리 핫소스 200ml", "소스 · 2개 이상 구매", "food", "1병", 1),
    (137706783, "d04", "빨강떡볶이 DIY 대구납작만두 (5종 택1)", "냉동 · 6개 이상 구매", "food", "1봉", 1),
    (138032192, "d05", "곰표 튀김가루 500g × 10개", "업소 대용량", "food", "10개", 10),
    (131758741, "d06", "수박모양 탱탱젤리 900g (18g × 50개입)", "간식 · 대용량", "goods", "50개", 50),
    (137654886, "d07", "피쇼 생육 80% 어포 스낵 15g × 50개", "간식 · 간장20+매운맛5+바베큐15", "goods", "50개", 50),
]
for n, gid, nm, spec, kind, pack, cnt in DDANG:
    sp, f, ex = det(n)
    pc = round((1 - f / sp) * 100)
    o = {"st": "떠리몰 임박특가", "p": f, "o": sp, "pack": pack, "c": f"임박 땡처리 {pc}% · 소비기한 {ex}", "u": "재고 소진 시",
         "src": f"떠리몰 임박특가 상품 {n} 표시 정가·판매가·소비기한 ({CHK})"}
    if cnt > 1: o["each"] = f // cnt
    groups.append({"id": gid, "k": kind, "blk": "ddang", "item": nm, "spec": spec, "tag": "땡처리", "offers": [o]})

# ── ③ 편의점 1+1·2+1 — 정가 = 공식 목록의 1개 값 × 집는 개수 (확인된 값으로 계산) ──
nb = 0
for g in D["groups"]:
    if g["cat"] != "cvs": continue
    head = g["spec"].split(" · ")[0]
    kind = "life" if head == "생활용품" else ("food" if head in FOODY_CVS else "goods")
    offers = []
    for o in g["offers"]:
        o = dict(o)
        if isinstance(o.get("p"), (int, float)):
            if o["c"].startswith("1+1"):
                o["o"] = o["p"] * 2                       # 2개 집는 값 = 1개 값 × 2
            elif o["c"].startswith("2+1"):
                assert o["p"] % 2 == 0, (g["id"], o)
                o["o"] = o["p"] // 2 * 3                  # 3개 집는 값 = 1개 값 × 3
            o["src"] = o["src"] + " · 정가=1개 값×개수"
            nb += 1
        offers.append(o)
    ng = {k: v for k, v in g.items() if k != "cat"}
    ng["k"] = kind; ng["offers"] = offers
    groups.append(ng)

# ── ④ 마트·카페·백화점 — 아직 끝나지 않은 것만 남긴다 ──
KEEP_KIND = {"f01": "food", "f03": "food", "m08": "food", "m11": "life"}
dropped = []
for g in D["groups"]:
    if g["cat"] == "cvs": continue
    offers = [dict(o) for o in g["offers"] if not ended(o.get("u"))]
    if not offers:
        dropped.append(g["id"] + " " + g["item"]); continue
    for o in offers:
        if o["c"].startswith("1+1") and isinstance(o.get("p"), (int, float)) and not o.get("o"):
            o["o"] = o["p"] * 2; o["src"] += " · 정가=1개 값×2"
    ng = {k: v for k, v in g.items() if k != "cat"}
    ng["k"] = KEEP_KIND.get(g["id"], "etc")
    ng["offers"] = offers
    groups.append(ng)

S = {
    "asOf": "2026-11-24", "asOfKo": "2026년 11월 24일 (화)", "asOfTime": "04:45",
    "notice": "떠리몰 대량구매관·임박특가(11-24 확인), 편의점 공식 행사목록(11-22 확인), 마트 전단(11-17)에서 확인한 값입니다. "
              "정가는 같은 상품·같은 규격의 할인 전 값이 확인된 것만 적었고, 확인 못 한 것은 특가만 보여 줍니다. "
              "매장·지점마다 값과 재고가 다르고 행사는 조기 종료될 수 있습니다. 결제 전 확인하세요. 이 앱은 결제를 받지 않습니다.",
    "kinds": [
        {"k": "food", "nm": "식자재", "tag": "고기·면·소스·간편식"},
        {"k": "goods", "nm": "공산품", "tag": "음료·과자·건전지"},
        {"k": "life", "nm": "생활용품", "tag": "휴지·세제·소모품"},
        {"k": "etc", "nm": "기타", "tag": "카페·백화점 행사"},
    ],
    "groups": groups,
}
head = """/* ============================================================
   #51 오늘의 특가 — 데이터 (160번 개편 · 2026-11-24)
   기준: 2026-11-24(화) 04:45 — 떠리몰 대량구매관·임박특가 상세 API 값(11-24) ·
         편의점 공식 행사목록(11-22) · 마트 전단(11-17, 아직 안 끝난 행사만)
   원칙: ① 할인·증정·특가 품목만 넣는다
        ② 정가(o)는 같은 상품·같은 규격의 할인 전 값이 확인된 것만.
           편의점 1+1·2+1 은 공식 목록의 1개 값 × 집는 개수(2·3)로 계산했다.
           확인 못 한 것은 o:null — 화면에 '특가'만, % 배지 없음. 정가를 지어내지 않는다.
        ③ 값마다 조건(c)·끝나는 날(u)·확인한 곳(src)을 같이 적는다
        ④ 분류(k)는 물건 기준: food 식자재 · goods 공산품 · life 생활용품 · etc 기타
           blk: whole 도매 대용량 / ddang 유통기한 임박 땡처리 → 맨 위 '오늘의 도매 특가'
   갱신: 이 파일 하나만 고치면 앱 전체가 바뀐다.
   ============================================================ */
window.SALE = """
body = json.dumps(S, ensure_ascii=False, indent=1)
body = re.sub(r'\n {2,}', ' ', body)  # 그룹 안쪽은 한 줄로 (그룹당 1~3줄)
body = body.replace('}, { "id"', '},\n  { "id"').replace('"groups": [ {', '"groups": [\n  {')
open(OUT, "w", encoding="utf-8", newline="\n").write(head + body + ";\n")
print("groups", len(groups), "cvs offers with o", nb, "dropped", len(dropped))
for x in dropped: print("  drop", x)
pc = sum(1 for g in groups if any(isinstance(o.get("p"), (int, float)) and isinstance(o.get("o"), (int, float)) and o["o"] > o["p"] for o in g["offers"]))
print("cards with 정가+%:", pc, "/", len(groups), round(pc / len(groups) * 100, 1), "%")
