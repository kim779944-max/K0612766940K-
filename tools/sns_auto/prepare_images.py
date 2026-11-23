#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""블로그 사진 준비 — images/{key}_N.png 를 채운다(images/ 는 커밋 금지 그대로).
   py -3 prepare_images.py --audit            # 무엇이 있고 없는지만 표로(네트워크 0건)
   py -3 prepare_images.py --prepare          # 없는 것만 채움(다운로드 → 라이브 캡처)
   py -3 prepare_images.py --prepare --force  # 전부 다시
   py -3 prepare_images.py --prepare --only slope,doksim

순서(항목별 1~3번 슬롯): ① 이미 있으면 검사만 ② blog.photo_urls 다운로드 ③ 모자란 슬롯은 전용 크롬(CDP 9222)
새 탭 1개로 라이브 캡처(1200×800). 검증: PNG 시그니처 · 가로≥800 · 세로≥500 · 40KB 이상.
유효 사진이 2장 미만인 항목은 blog.photo_missing=true → naver_blog_draft.py 가 그 글을 저장하지 않는다.
종료 코드: 0 정상 · 1 일부 항목 사진 부족 · 3 크롬 없음(캡처 필요한데 못 함)
"""
import argparse, datetime, hashlib, json, os, struct, sys, time, urllib.request
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
IMGDIR = ROOT / "images"
LOGDIR = ROOT / "logs"
SAMPLES = ROOT / "samples"
CDP = "http://127.0.0.1:9222"
SITE = "https://autooneclick.com"
MIN_W, MIN_H, MIN_BYTES = 800, 500, 40 * 1024
MIN_PHOTOS = 2
VIEWPORT = {"width": 1200, "height": 800}

PAGES = {
    "slope": "/slope/", "doksim": "/navi2/", "viewer": "/viewer.html", "sign": "/sign/",
    "thescan": "/thescan/", "realty": "/realty/", "bungee": "/bungee/", "redev": "/redev/",
    "hogang": "/hogang/", "converter": "/converter.html",
}
# blog.photo_urls[i] 를 몇 번 슬롯에 넣을지(1번 슬롯은 '첫 화면' 캡처 자리라 보통 2·3번에 둔다)
DL_SLOTS = {"slope": [2], "doksim": [3], "viewer": [3], "realty": [3], "redev": [2], "converter": [3]}


def log(msg):
    LOGDIR.mkdir(exist_ok=True)
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line)
    with open(LOGDIR / f"images_{datetime.date.today():%Y-%m-%d}.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8"))


def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)


def item_key(it):
    return it["id"].split("_", 1)[1]


def png_info(path: Path):
    """(ok, 사유, w, h, bytes). PNG 시그니처 + IHDR 로 크기를 읽는다(Pillow 불필요)."""
    if not path.exists():
        return False, "없음", 0, 0, 0
    size = path.stat().st_size
    with open(path, "rb") as f:
        head = f.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        return False, "PNG 아님", 0, 0, size
    w, h = struct.unpack(">II", head[16:24])
    if w < MIN_W or h < MIN_H:
        return False, f"작음 {w}x{h}", w, h, size
    if size < MIN_BYTES:
        return False, f"용량 {size // 1024}KB(<40KB, 빈 화면 의심)", w, h, size
    return True, "OK", w, h, size


def slot_path(blog, n):
    imgs = blog.get("images", []) or []
    return IMGDIR / imgs[n - 1] if 0 < n <= len(imgs) else None


def valid_count(blog):
    """유효 사진 수. 같은 파일(바이트 동일)이 두 슬롯에 있으면 1장으로 센다."""
    seen = set()
    for n in range(1, min(3, len(blog.get("images", []))) + 1):
        p = slot_path(blog, n)
        if png_info(p)[0]:
            seen.add(hashlib.sha1(p.read_bytes()).hexdigest())
    return len(seen)


def audit(q):
    print(f"{'key':<10} {'슬롯':<5} {'파일':<18} {'상태':<26} {'크기':>11} {'용량':>7}")
    short = []
    for it in sorted(q["items"], key=lambda x: x.get("order", 0)):
        key, blog = item_key(it), it["blog"]
        for n in range(1, min(3, len(blog.get("images", []))) + 1):
            p = slot_path(blog, n)
            ok, why, w, h, b = png_info(p)
            print(f"{key:<10} {n:<5} {p.name:<18} {why:<26} {f'{w}x{h}' if w else '-':>11} {b // 1024:>5}KB")
        vc = valid_count(blog)
        if vc < MIN_PHOTOS:
            short.append(f"{key}({vc}/3)")
    print(f"사진 부족(2장 미만) 항목: {', '.join(short) if short else '없음'}")
    return 1 if short else 0


def download(url, dest: Path):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (sns_auto prepare_images)"})
    with urllib.request.urlopen(req, timeout=60) as r:
        ctype = r.headers.get("Content-Type", "")
        data = r.read()
    if not ctype.startswith("image/"):
        raise RuntimeError(f"이미지가 아님: {ctype}")
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise RuntimeError("PNG 헤더(IHDR) 불일치")
    IMGDIR.mkdir(exist_ok=True)
    tmp = dest.with_suffix(".dl")
    tmp.write_bytes(data)
    os.replace(tmp, dest)


# ------------------------------------------------------------------ 예시 문서(samples/)

def ensure_samples():
    """viewer·thescan 캡처용 예시 문서. 개인정보 없는 '예시' 견적서만 만든다."""
    SAMPLES.mkdir(exist_ok=True)
    pdf, png = SAMPLES / "sample_quote.pdf", SAMPLES / "sample_scan.png"
    if pdf.exists() and png.exists():
        return pdf, png
    from PIL import Image, ImageDraw, ImageFont
    font_path = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts" / "malgun.ttf"
    f_big = ImageFont.truetype(str(font_path), 64)
    f_mid = ImageFont.truetype(str(font_path), 34)
    img = Image.new("RGB", (1240, 1754), "white")
    d = ImageDraw.Draw(img)
    d.text((80, 90), "견 적 서 (예시)", font=f_big, fill="black")
    d.text((80, 200), "수신: 예시 고객 귀하        일자: 2026. 11. 23.", font=f_mid, fill="black")
    rows = [("품목", "수량", "단가", "금액"), ("A4 복사용지", "10", "4,500", "45,000"),
            ("토너 카트리지", "2", "38,000", "76,000"), ("스테이플러 심", "5", "1,200", "6,000"),
            ("합계", "", "", "127,000")]
    y = 300
    xs = [80, 560, 760, 960, 1160]
    for r in rows:
        d.rectangle([80, y, 1160, y + 70], outline="black", width=2)
        for i, cell in enumerate(r):
            d.text((xs[i] + 16, y + 14), cell, font=f_mid, fill="black")
            if i:
                d.line([xs[i], y, xs[i], y + 70], fill="black", width=2)
        y += 70
    d.text((80, y + 60), "※ 이 문서는 화면 설명용 예시입니다. 실제 거래 내용이 아닙니다.", font=f_mid, fill="#444")
    img.save(png)
    img.save(pdf, "PDF", resolution=150)
    return pdf, png


# ------------------------------------------------------------------ 라이브 캡처 레시피

def _shot(page, dest: Path):
    IMGDIR.mkdir(exist_ok=True)
    page.screenshot(path=str(dest))


def _scroll(page, y):
    page.evaluate(f"window.scrollTo(0, {y})")
    time.sleep(1.0)


def _scroll_to(page, sel, offset=-80):
    page.evaluate("""([s, o]) => { const e = document.querySelector(s); if (e) window.scrollTo(0, e.getBoundingClientRect().top + scrollY + o); }""",
                  [sel, offset])
    time.sleep(1.0)


def _click(page, sel, wait=1.5):
    loc = page.locator(sel).first
    if loc.count():
        loc.click()
        time.sleep(wait)
        return True
    return False


def cap_slope(page, n):
    # 조회를 일으키지 않는다(무료 3건/일 보호): 1 첫 화면, 2 지도 카드(색 격자), 3 지도 아래 통계표
    if n == 1:
        return True
    if n == 2:
        _scroll_to(page, "#mapcv", -150)
    else:
        _scroll_to(page, "#chkGo", -420) if page.locator("#chkGo").count() else _scroll(page, 1300)
    return True


def cap_doksim(page, n):
    if n == 1:
        return True
    pics = page.locator("button.pic")
    for i in (0, 4, 9):
        if pics.count() > i:
            pics.nth(i).click()
            time.sleep(0.4)
    if n == 2:
        _scroll_to(page, "button.pic", -160)
        return True
    # 3: 고른 뒤 시작 → 문항 진행 화면(한 번만)
    if not _click(page, "#btnStart", 2.5):
        return False
    _scroll(page, 0)
    return True


def cap_viewer(page, n):
    if n == 1:
        return True
    pdf, _ = ensure_samples()
    inp = page.locator("input[type=file]")
    if not inp.count():
        return False
    inp.first.set_input_files(str(pdf))
    time.sleep(6)
    if n == 3:                      # 원본 크기로 확대한 화면
        _click(page, "#vtOne", 2) or _click(page, "#vtIn", 2)
    return True


def cap_sign(page, n):
    if n == 1:
        return True
    cv = page.locator("canvas").first
    if not cv.count():
        return False
    cv.scroll_into_view_if_needed()
    box = cv.bounding_box()
    if not box:
        return False
    x0, y0, w, h = box["x"], box["y"], box["width"], box["height"]
    pts = [(0.15, 0.6), (0.25, 0.3), (0.32, 0.7), (0.42, 0.35), (0.5, 0.65), (0.6, 0.4), (0.72, 0.6), (0.85, 0.45)]
    page.mouse.move(x0 + w * pts[0][0], y0 + h * pts[0][1])
    page.mouse.down()
    for px, py in pts[1:]:
        page.mouse.move(x0 + w * px, y0 + h * py, steps=8)
    page.mouse.up()
    time.sleep(1)
    if n == 2:
        _scroll(page, max(0, page.evaluate("scrollY") - 120))
    else:                           # 3: 서명 아래 '도장함 · 문서에 도장 찍기' 영역(대화상자 없이)
        _scroll(page, page.evaluate("scrollY") + 650)
    return True


def cap_thescan(page, n):
    if n == 1:
        return True
    _, png = ensure_samples()
    inp = page.locator("#fFile")
    if not inp.count():
        inp = page.locator("input[type=file]")
    if not inp.count():
        return False
    # 2: 한 장 올린 정리 화면 · 3: 두 장 올려 '내 스캔' 목록에 쌓인 화면(연결 전)
    inp.first.set_input_files([str(png)] if n == 2 else [str(png), str(png)])
    time.sleep(6)
    if n == 3:
        _scroll_to(page, "#btnJoin", -520)
    return True


def cap_realty(page, n):
    if n == 1:
        return True
    if not (_click(page, "#btnSample", 1) and _click(page, "#btnParse", 3)):
        return False
    if n == 3:
        _scroll(page, 650)
    return True


def cap_bungee(page, n):
    if n == 1:
        return True
    tab = "단독 홈피" if n == 2 else "포스터"
    page.get_by_role("button", name=tab, exact=True).first.click()
    time.sleep(1.5)
    # 예시 입력의 전화번호 칸은 가짜 번호로 바꿔 찍는다(실제 연락처 노출 금지)
    page.evaluate(r"""() => document.querySelectorAll('input, textarea').forEach(e => {
        if (e.offsetParent && /01[016789][-\s]?\d{3,4}[-\s]?\d{4}/.test(e.value)) {
          e.value = e.value.replace(/01[016789][-\s]?\d{3,4}[-\s]?\d{4}/g, '010-1234-5678');
          e.dispatchEvent(new Event('input', {bubbles: true}));
        } })""")
    time.sleep(1)
    return True


def cap_redev(page, n):
    if n == 1:
        return True
    if not _click(page, "button.item", 3):
        return False
    if n == 3:                      # 상세 패널 안쪽(단계 타임라인·지도)으로 휠 스크롤
        page.mouse.move(600, 500)
        for _ in range(6):
            page.mouse.wheel(0, 120)
            time.sleep(0.2)
        time.sleep(1)
    return True


def cap_hogang(page, n):
    if n == 1:
        return True
    _scroll(page, 800 if n == 2 else 1600)
    return True


def cap_converter(page, n):
    if n == 1:
        return True
    page.evaluate("() => document.querySelectorAll('details.paste').forEach(d => d.open = true)")
    time.sleep(0.5)
    ta = page.locator("#pasteArea")
    if not ta.count():
        return False
    sample = (ta.first.get_attribute("placeholder") or "").strip()
    if not sample:
        return False
    if n == 2:                      # 붙여넣은 표 → 변환 결과
        ta.first.fill(sample)
        _click(page, "#btnPaste", 3)
        _scroll_to(page, "#pasteArea", -60)
    else:                           # 3: 사진 고르기·요금 안내 영역
        _scroll_to(page, "#btnPick", -200)
    return True


FAKE_PHONES = ("1234-5678", "12345678", "0000-0000", "00000000", "9876-5432", "98765432", "5678-1234",
               "2222-3333", "22223333")   # 사이트 예시 데이터에 쓰인 가짜 번호


def hide_contact_lines(page):
    """하단 안내 줄(footer 등 짧은 문의 줄)에 실제 전화번호가 있으면 이 탭 화면에서만 숨긴다.
    본문·입력칸·미리보기 안의 번호는 숨기지 않는다 → 그대로 남으면 그 컷은 버린다."""
    page.evaluate(r"""() => {
      const re = /01[016789][-\s.]?\d{3,4}[-\s.]?\d{4}/;
      document.querySelectorAll('footer, .foot, .footer, [class*=foot], p, div, small').forEach(e => {
        if (!e.offsetParent) return;
        const t = (e.textContent || '').trim();
        if (t.length < 90 && re.test(t) && /문의|원클릭|KTS/.test(t) && !e.querySelector('input, textarea, canvas, img')
            && !e.closest('[class*=preview], [class*=poster], [class*=card-pv], iframe'))
          e.style.display = 'none';
      });
    }""")
    time.sleep(0.3)


def pii_in_view(page):
    """화면(뷰포트) 안에 보이는 전화번호 중 예시 번호가 아닌 것을 돌려준다(뒤 4자리 가림)."""
    found = page.evaluate(r"""() => {
      const out = [], re = /01[016789][-\s.]?\d{3,4}[-\s.]?\d{4}/g, H = innerHeight;
      const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
      let t;
      while ((t = w.nextNode())) {
        const m = (t.textContent || '').match(re); if (!m) continue;
        const el = t.parentElement; if (!el || !el.offsetParent) continue;
        const r = el.getBoundingClientRect(); if (r.bottom < 0 || r.top > H) continue;
        out.push(...m);
      }
      document.querySelectorAll('input, textarea').forEach(e => {
        const r = e.getBoundingClientRect(); if (!e.offsetParent || r.bottom < 0 || r.top > H) return;
        const m = (e.value || '').match(re); if (m) out.push(...m);
      });
      return out;
    }""")
    bad = []
    for num in found:
        digits = "".join(ch for ch in num if ch.isdigit())
        if any(f.replace("-", "") in digits for f in FAKE_PHONES):
            continue
        bad.append(num[:-4] + "****")
    return bad


RECIPES = {"slope": cap_slope, "doksim": cap_doksim, "viewer": cap_viewer, "sign": cap_sign,
           "thescan": cap_thescan, "realty": cap_realty, "bungee": cap_bungee, "redev": cap_redev,
           "hogang": cap_hogang, "converter": cap_converter}


def cdp_alive():
    try:
        with urllib.request.urlopen(f"{CDP}/json/version", timeout=5) as r:
            return r.status == 200
    except Exception:
        return False


def capture(key, slots, blog):
    """slots 에 있는 번호만 캡처. 슬롯마다 페이지를 새로 연다(앞 동작이 뒤 화면을 오염시키지 않게)."""
    from playwright.sync_api import sync_playwright
    url = SITE + PAGES[key]
    done = []
    with sync_playwright() as p:
        ctx = p.chromium.connect_over_cdp(CDP).contexts[0]
        page = ctx.new_page()          # 새 탭 하나만 쓴다
        try:
            page.set_viewport_size(VIEWPORT)
            page.set_default_timeout(20000)
            for n in slots:
                dest = slot_path(blog, n)
                try:
                    page.goto(url, wait_until="networkidle", timeout=45000)
                    time.sleep(1.5)
                    if not RECIPES[key](page, n):
                        log(f"  {key}_{n} 캡처 동작 실패(요소 없음) — 건너뜀")
                        continue
                    bad = pii_in_view(page)
                    if bad:                 # 사이트 하단 '문의 010-…' 줄 — 그 줄만 이 탭에서 숨기고 다시 본다
                        hide_contact_lines(page)
                        bad = pii_in_view(page)
                    if bad:
                        log(f"  {key}_{n} 개인정보(전화번호 {bad}) 보임 → 이 컷은 버림")
                        continue
                    _shot(page, dest)
                    ok, why, w, h, b = png_info(dest)
                    log(f"  {key}_{n} 캡처 {why} {w}x{h} {b // 1024}KB")
                    if ok:
                        done.append(n)
                    else:
                        dest.unlink(missing_ok=True)
                except Exception as e:
                    log(f"  {key}_{n} 캡처 오류: {str(e)[:200]}")
        finally:
            page.close()
    return done


def prepare(q, force=False, only=None):
    need_cdp = False
    short = []
    for it in sorted(q["items"], key=lambda x: x.get("order", 0)):
        key, blog = item_key(it), it["blog"]
        if only and key not in only:
            continue
        nslot = min(3, len(blog.get("images", [])))
        missing = [n for n in range(1, nslot + 1) if force or not png_info(slot_path(blog, n))[0]]
        for n in missing:               # 다시 채울 슬롯의 옛 파일은 먼저 치운다(실패 시 옛 컷이 남지 않게)
            slot_path(blog, n).unlink(missing_ok=True)
        log(f"[{key}] 채울 슬롯 {missing or '없음'}")
        # ② 다운로드
        for url, n in zip(blog.get("photo_urls", []) or [], DL_SLOTS.get(key, [])):
            if n not in missing:
                continue
            try:
                download(url, slot_path(blog, n))
                ok, why, w, h, b = png_info(slot_path(blog, n))
                log(f"  {key}_{n} 다운로드 {why} {w}x{h} {b // 1024}KB ← {url}")
                if ok:
                    missing.remove(n)
                else:
                    slot_path(blog, n).unlink(missing_ok=True)
            except Exception as e:
                log(f"  {key}_{n} 다운로드 실패: {str(e)[:200]}")
        # ③ 라이브 캡처
        if missing:
            if key not in RECIPES:
                log(f"  {key}: 캡처 레시피 없음")
            elif not cdp_alive():
                need_cdp = True
                log(f"  {key}: 크롬(CDP 9222) 없음 — 캡처 {missing} 보류")
            else:
                capture(key, missing, blog)
        vc = valid_count(blog)
        if vc < MIN_PHOTOS:
            blog["photo_missing"] = True
            short.append(f"{key}({vc}/3)")
            log(f"  [보류] {key} 유효 사진 {vc}장 → photo_missing=true (임시저장 안 함)")
        else:
            blog.pop("photo_missing", None)
            log(f"  [OK] {key} 유효 사진 {vc}/3")
    save_queue(q)
    log(f"사진 부족으로 보류: {', '.join(short) if short else '없음'}")
    if need_cdp:
        return 3
    return 1 if short else 0


def main():
    ap = argparse.ArgumentParser(description="블로그 사진 준비")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--audit", action="store_true")
    g.add_argument("--prepare", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--only", default="", help="쉼표로 key 지정(예: slope,doksim)")
    a = ap.parse_args()
    q = load_queue()
    if a.audit:
        return audit(q)
    only = {s.strip() for s in a.only.split(",") if s.strip()} or None
    return prepare(q, force=a.force, only=only)


if __name__ == "__main__":
    sys.exit(main())
