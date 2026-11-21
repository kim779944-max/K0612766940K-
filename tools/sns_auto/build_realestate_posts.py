#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""부동산 매물 → 네이버 블로그 상세 글 + 쓰레드 훅 → post_queue.json
   py -3 build_realestate_posts.py --list
   py -3 build_realestate_posts.py --add
입력: data/listings.json (대표님이 정리 — 이 폴더의 data/ 는 커밋하지 않는다)
price_public=false 면 금액을 쓰지 않는다. 표시광고(중개사 명칭·등록번호) 문구는 넣지 않고 notes 에 '표시광고 확인 필요'.
"""
import argparse, datetime, json, os, sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
DATA = ROOT / "data" / "listings.json"
ENV = ROOT / ".env.local"


def won(n):
    n = int(n or 0)
    eok, man = divmod(n, 100000000)
    man //= 10000
    out = []
    if eok:
        out.append(f"{eok}억")
    if man:
        out.append(f"{man:,}만")
    return " ".join(out) or "0"


def load_env():
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            if "=" in raw and not raw.strip().startswith("#"):
                k, v = raw.split("=", 1)
                cfg[k.strip()] = v.strip().strip('"').strip("'")
    return cfg


def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8")) if QUEUE.exists() else {"version": 2, "items": []}


def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)


def area_line(L):
    py, m2 = L.get("area_pyeong"), L.get("area_m2")
    if py and m2:
        return f"{py:,}평(약 {m2:,}㎡)"
    if py:
        return f"{py:,}평(약 {round(py * 3.3058):,}㎡)"
    return f"{m2:,}㎡" if m2 else "면적 미기재"


def money_block(L):
    if not L.get("price_public", True):
        return ["- 매매가: 문의", "- 대출·에쿼티: 문의", "- 교환 조건: 문의"]
    price, loan = int(L.get("price_krw") or 0), int(L.get("loan_krw") or 0)
    equity = int(L.get("equity_krw") or (price - loan))
    out = [f"- 매매가: {won(price)} 원", f"- 대출: {won(loan)} 원(승계 가능 여부 확인)",
           f"- 에쿼티(매매가−대출): {won(equity)} 원"]
    if L.get("area_pyeong") and price:
        out.append(f"- 평당: 약 {round(price / L['area_pyeong'] / 10000):,}만 원(계산값)")
    return out


def make_blog(L):
    where = f"{L.get('region', '')} {L.get('jibun', '')}".strip()
    kind = L.get("kind", "매물")
    title = f"{where} {area_line(L)} {kind} — 교환 매물 정리"
    if L.get("price_public", True) and L.get("price_krw"):
        title += f" (매가 {won(L['price_krw'])})"

    lines = [
        "■ 현금이 없어서 막히는 자리",
        "집을 바꾸고 싶은데 지금 집이 안 팔리면, 다음 집을 볼 수도 없습니다. 대출 한도는 줄고, 기다리는 동안 시세는 움직입니다.",
        "그래서 요즘은 '팔고 사는' 대신 '바꾸는' 쪽을 먼저 봅니다. 교환은 상대가 원하는 것과 내가 가진 것이 맞아야 성립하므로, 조건을 숫자로 정리해 두는 것이 먼저입니다.",
        "", f"■ {where} {area_line(L)} {kind}", "", "[사진1]", "",
        "■ 숫자로 보는 조건", *money_block(L), "",
        "■ 이 땅(물건)의 특징",
    ]
    for f in L.get("features", []) or ["특징 미기재"]:
        lines.append(f"- {f}")
    lines += ["", "[사진2]", "", "■ 교환 희망 조건",
              "- " + (", ".join(L.get("exchange_want", [])) if L.get("exchange_want") else "협의 가능")]
    if L.get("note"):
        lines += ["", "■ 참고", f"- {L['note']}"]
    lines += [
        "", "■ 계약 전에 확인할 서류",
        "- 등기부등본(근저당·가압류)",
        "- 토지대장·건축물대장(지목·면적·구조)",
        "- 토지이용계획확인원(용도지역·규제)",
        "- 실제 경계(측량 필요 시 비용·기간 확인)",
        "", "[사진3]", "",
        "■ 문의",
        "교환·매매 조건은 상대에 따라 달라집니다. 보고 계신 조건과 맞는지 편하게 문의 주세요.",
    ]
    contact = load_env().get("CONTACT_PHONE", "")
    if contact:
        lines.append(f"연락처: {contact}")
    return title, "\n".join(lines)


def make_item(L, order):
    title, body = make_blog(L)
    where = f"{L.get('region', '')} {L.get('jibun', '')}".strip()
    hook = (f"집을 바꾸고 싶은데 지금 집이 안 팔려서 다음 집을 못 보고 있습니다.\n"
            f"{where} {area_line(L)} {L.get('kind', '')} — 교환 조건을 숫자로 정리해 뒀습니다.\n"
            f"조건은 댓글에 적어 두었습니다.")
    return {
        "id": f"{datetime.date.today():%Y-%m-%d}_{L['id']}", "order": order,
        "topic": f"매물 {where}", "status": "pending", "product_key": f"listing:{L['id']}",
        "threads": {"text": hook, "image_url": "",
                    "first_comment": "매물 상세와 조건 → https://autooneclick.com/exchange/"},
        "blog": {"status": "pending", "title": title, "body": body,
                 "tags": [w for w in [L.get("region", "").split()[-1] if L.get("region") else "",
                                      L.get("kind", ""), "교환매물", "급매", "토지", "부동산",
                                      f"{L.get('area_pyeong', '')}평" if L.get("area_pyeong") else ""] if w][:12],
                 "images": L.get("photos", [])[:3]},
        "notes": "매물 자동 생성 — 금액·조건은 대표님 입력값. 표시광고 확인 필요. 발행 전 확인 필수",
    }


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--list", action="store_true")
    g.add_argument("--add", action="store_true")
    a = ap.parse_args()
    if not DATA.exists():
        print(f"[안내] 매물 데이터가 없습니다: data/listings.json")
        print("       지시서 §6-8 형식으로 대표님이 정리한 매물을 넣고 다시 실행하세요.")
        return 3
    data = json.loads(DATA.read_text(encoding="utf-8-sig"))
    Ls = data.get("listings", []) or data.get("items", [])
    q = load_queue()
    have = {it.get("product_key") for it in q["items"]}
    if a.list:
        for L in Ls:
            mark = "있음" if ("listing:" + str(L["id"])) in have else "없음"
            print(f"{L['id']:<18}{mark}")
        return 0
    added = 0
    for L in Ls:
        key = f"listing:{L['id']}"
        if key in have:
            continue
        order = max([it.get("order", 0) for it in q["items"]] or [0]) + 1
        q["items"].append(make_item(L, order))
        have.add(key)
        added += 1
        print(f"[ADD] {L['id']} → order {order}")
    if added:
        save_queue(q)
    print(f"완료: 추가 {added}건 · 전체 {len(q['items'])}건")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
