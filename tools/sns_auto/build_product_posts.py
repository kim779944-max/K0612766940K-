#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""상품별 상세 글 생성기 — catalog.json → 블로그 원고 + 쓰레드 훅 → post_queue.json
   py -3 build_product_posts.py --list         # 상품별 큐에 있는지 보기(파일 변경 없음)
   py -3 build_product_posts.py --add          # 새 상품만 큐 뒤에 추가
   py -3 build_product_posts.py --update       # '자동 생성' pending 글만 최신 정보로 갱신(손으로 쓴 글은 안 건드림)
   py -3 build_product_posts.py --capture      # 상품 페이지 실물 캡처(images/, CDP 크롬 필요)
   --only KEY  로 상품 하나만
수치는 catalog.json 에 있는 값만 쓴다. 원리·내부구조는 쓰지 않는다.
"""
import argparse, datetime, json, os, sys, time, urllib.request
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
IMGDIR = ROOT / "images"
CATALOG = "https://autooneclick.com/catalog.json"
SITE = "https://autooneclick.com/"
AUTO_MARK = "자동 생성"

# ① 상황 첫마디 — 상품 key 별. 새 상품은 여기에 한 줄 추가한다.
SITUATION = {
    "sale": "장 볼 때마다 '여기가 싼가' 싶어서 몇 집을 돌아다닌 적 있습니다.",
    "photo2doc": "거래명세표 사진을 받고 엑셀로 다시 타이핑하다가 마지막에 합계가 안 맞았습니다.",
    "theform": "관공서 양식을 받아 놓고 어디에 무엇을 써야 하는지 몰라 한참 멈춘 적 있습니다.",
    "contract": "계약서를 급하게 써야 해서 예전 문서를 복사했는데, 남의 주소가 그대로 남아 있었습니다.",
    "thedetail": "매물 사진은 많은데 손님께 보여 줄 한 장이 없어서 결국 전화로 설명했습니다.",
    "viewer": "카톡으로 온 한글파일이 폰에서 안 열려서 '집 가서 볼게요' 하고 넘긴 적 있습니다.",
    "loan": "자금이 필요한데 어디에 넣어야 할지 몰라 은행만 세 번 바꿔 갔습니다.",
    "tax": "돈은 필요한데 순서를 몰라 통장부터 만들다가 꼬인 적이 있습니다.",
    "navi": "답장이 짧아졌다고 화난 걸로 단정했다가, 그냥 바빴다는 걸 나중에 알았습니다.",
    "saycap": "사진은 많은데 그 사진을 다시 찾으려면 갤러리를 한참 넘겨야 합니다.",
    "organizer": "앱이 백 개가 되니 홈 화면에서 필요한 걸 못 찾겠습니다.",
    "keyword": "검색창에 무슨 단어를 쳐야 할지 몰라 고민만 하다 끝난 적 있습니다.",
    "sign": "서명 한 장 때문에 프린터 있는 곳을 찾아다닌 적 있습니다.",
    "tongyeok": "외국인 손님 앞에서 말이 막혀 손짓만 했습니다.",
    "realty": "아침에 온 매물 문자 20건 중 절반은 광고였습니다.",
    "slope": "땅 보러 갔는데 '경사가 좀 있다'는 말만 듣고 왔습니다.",
    "commerce": "상품 하나 올리려는데 제목·상세·엑셀을 각각 따로 만들어야 했습니다.",
    "redev": "'곧 될 겁니다'만 듣고 계약했다가 몇 년을 기다린 이야기를 주변에서 봤습니다.",
    "gagebu": "이번 달에 얼마 썼는지 물으면 답을 못 합니다.",
    "hogang": "대리점에서 '이게 제일 싸다'고 해서 바꿨는데, 집에 와서도 확신이 없었습니다.",
    "golf": "영상은 봤는데 내 자세가 뭐가 틀렸는지 몰라 그대로 쳤습니다.",
    "petmind": "강아지가 자꾸 같은 행동을 해서 혼냈는데, 나중에 뜻이 달랐습니다.",
}
FALLBACK = "{nm}이(가) 필요한 순간은 대개 일이 막혔을 때입니다. 검색해 보고, 앱을 깔고, 결국 다시 원래대로 돌아옵니다."
STOP = ["최고", "1위", "유일", "보장", "완벽", "혁명"]


def fetch_catalog():
    req = urllib.request.Request(CATALOG, headers={"User-Agent": "kts-sns-auto/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8")) if QUEUE.exists() else {"version": 2, "items": []}


def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)


def existing_keys(q, prods):
    """큐에 이미 있는 상품 key. product_key 가 없는 손글(초기 10편)은 첫 댓글 링크로 판별한다."""
    have = {it.get("product_key") for it in q["items"] if it.get("product_key")}
    comments = " ".join(it.get("threads", {}).get("first_comment", "") for it in q["items"])
    for p in prods:
        if p.get("link") and (SITE + p["link"]) in comments:
            have.add(p["k"])
    return have


def make_hook(p):
    sit = SITUATION.get(p["k"]) or FALLBACK.format(nm=p["nm"])
    fact = (p.get("line") or p.get("sub") or "").strip().rstrip(".")
    return f"{sit}\n{fact}.\n바로 써볼 수 있습니다. (링크는 댓글)"


def make_blog(p):
    nm, sub = p["nm"], p.get("sub", "")
    sit = SITUATION.get(p["k"]) or FALLBACK.format(nm=nm)
    how = p.get("how") or []
    bullets = p.get("bullets") or []
    notes = p.get("notes") or p.get("note") or []
    if isinstance(notes, str):
        notes = [notes]
    price, price2 = p.get("price", ""), p.get("price2", "")
    link = SITE + (p.get("link") or "")

    lines = [f"■ {sit}",
             "그때 필요한 건 설명이 아니라 화면 하나입니다. 이 글에서는 무엇을 어떻게 확인하는지 순서대로 적었습니다.", "",
             f"■ {nm}가 하는 일", p.get("blurb", ""), "", "[사진1]", "",
             "■ 쓰는 순서"]
    for i, h in enumerate(how, 1):
        lines.append(f"{i}. {h}")
    lines += ["", "■ 한눈에 보는 항목"]
    for b in bullets:
        if isinstance(b, list) and len(b) >= 2:
            lines.append(f"- {b[0]}: {b[1]}")
    lines += ["", "[사진2]", "", "■ 실제로 이렇게 씁니다",
              "급할 때 열어 보고, 결과를 그대로 저장하거나 보내는 식으로 씁니다. 한 번 써 두면 다음부터는 검색하지 않게 됩니다.",
              "", "[사진3]", "", "■ 주의"]
    for n in notes:
        lines.append(f"- {n}")
    lines += ["- 화면에 나오는 값은 참고용입니다. 법적 판단·계약은 공부(등기·대장)와 원본 서류를 기준으로 하세요.",
              "", "■ 비용", f"{price}" + (f" / {price2}" if price2 else ""), "", link]

    body = "\n".join([l for l in lines if l is not None]).strip()
    for w in STOP:
        body = body.replace(w, "")
    title = f"{nm}, 이럴 때 이렇게 씁니다 — {sub}" if sub else f"{nm} 쓰는 방법"
    tags = [nm.replace(" ", ""), p.get("cat", ""), "무료", "사용법", "정리", "업무", "생활", "초보"] + \
           [b[0] for b in bullets if isinstance(b, list)][:4]
    return title, body, [t for t in dict.fromkeys([x for x in tags if x])][:14]


def make_item(p, order):
    title, body, tags = make_blog(p)
    key = p["k"]
    return {
        "id": f"{datetime.date.today():%Y-%m-%d}_{key}", "order": order, "topic": p["nm"],
        "status": "pending", "product_key": key,
        "threads": {"text": make_hook(p),
                    "image_url": (SITE + p["shot"]) if p.get("shot") else "",
                    "first_comment": f"{p['nm']} 바로 써보기 → {SITE}{p.get('link', '')}"},
        "blog": {"status": "pending", "title": title, "body": body, "tags": tags,
                 "images": [f"{key}_1.png", f"{key}_2.png", f"{key}_3.png"]},
        "notes": ("상황문장 없음(일반 문장 사용) " if key not in SITUATION else "") +
                 f"{AUTO_MARK} — 발행 전 사람이 한 번 읽고 다듬기",
    }


def capture(p, cdp="http://127.0.0.1:9222"):
    from playwright.sync_api import sync_playwright
    IMGDIR.mkdir(exist_ok=True)
    with sync_playwright() as pw:
        b = pw.chromium.connect_over_cdp(cdp)
        page = b.contexts[0].new_page()
        page.set_viewport_size({"width": 1200, "height": 900})
        try:
            page.goto(SITE + (p.get("link") or ""), wait_until="networkidle", timeout=45000)
            time.sleep(2)
            page.screenshot(path=str(IMGDIR / f"{p['k']}_1.png"))
            page.mouse.wheel(0, 900); time.sleep(1)
            page.screenshot(path=str(IMGDIR / f"{p['k']}_2.png"))
            page.mouse.wheel(0, 900); time.sleep(1)
            page.screenshot(path=str(IMGDIR / f"{p['k']}_3.png"))
        finally:
            page.close()


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--list", action="store_true")
    g.add_argument("--add", action="store_true")
    g.add_argument("--update", action="store_true")
    g.add_argument("--capture", action="store_true")
    ap.add_argument("--only", help="상품 key 하나만")
    a = ap.parse_args()

    try:
        cat = fetch_catalog()
    except Exception as e:
        print(f"[실패] catalog.json 읽기: {e}")
        return 1
    prods = [p for p in cat["products"] if p.get("status") == "live" and p.get("link")]
    if a.only:
        prods = [p for p in prods if p["k"] == a.only]
    q = load_queue()
    have = existing_keys(q, prods)

    if a.list:
        print(f"catalog {cat.get('v', '')} · live+링크 {len(prods)}개 · 큐 {len(q['items'])}건")
        for p in prods:
            print(f"{p['k']:<14}{p['nm']:<18}{'있음' if p['k'] in have else '없음'}")
        return 0

    if a.capture:
        for p in prods:
            try:
                capture(p)
                print(f"[OK] 캡처 {p['k']}")
            except Exception as e:
                print(f"[실패] {p['k']}: {e}")
        return 0

    added = updated = 0
    for p in prods:
        if p["k"] in have:
            if a.update:
                for it in q["items"]:
                    if (it.get("product_key") == p["k"] and it.get("status") == "pending"
                            and AUTO_MARK in it.get("notes", "")):
                        keep_id = it["id"]
                        it.update(make_item(p, it["order"]))
                        it["id"] = keep_id
                        updated += 1
                        print(f"[UPDATE] {p['k']}")
            continue
        if a.update:
            continue
        order = max([it.get("order", 0) for it in q["items"]] or [0]) + 1
        q["items"].append(make_item(p, order))
        have.add(p["k"])
        added += 1
        print(f"[ADD] {p['k']} → order {order}")
    if added or updated:
        q["updated"] = f"{datetime.date.today()}"
        save_queue(q)
    print(f"완료: 추가 {added}건 · 갱신 {updated}건 · 전체 {len(q['items'])}건")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
