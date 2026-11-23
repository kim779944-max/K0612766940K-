#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""네이버 블로그 임시저장 (발행 금지) — PC 크롬 전용 프로필에 CDP로 붙는다.
   py -3 naver_blog_draft.py --list
   py -3 naver_blog_draft.py --dry-run
   py -3 naver_blog_draft.py --live --count 10    # 임시저장함에 10건 채우기(기본 10)
   py -3 naver_blog_draft.py --live --count 1
   py -3 naver_blog_draft.py --probe              # 에디터 구조 덤프(툴바 data-name·aria-label·title·글자 포함)
   py -3 naver_blog_draft.py --audit              # 브라우저 없이 조판 계획·사진 확보·문구 무결성 검사
   py -3 naver_blog_draft.py --list-drafts        # 임시저장함 실측(제목·logno·저장시각) + 큐 대조 3분류
   py -3 naver_blog_draft.py --reconcile          # 위 결과를 큐에 반영(draft_logno·drafted) + post_queue.json 커밋
   py -3 naver_blog_draft.py --rework --count 1   # 기존 임시저장 글을 새 양식으로 덮어쓰기(1편 게이트)
   py -3 naver_blog_draft.py                      # 스케줄러용: 1건, 오늘 이미 했으면 건너뜀, SNS_DAILY_ENABLED=0 이면 정지

조판(소제목·인용구·구분선·사진·태그 블록)은 naver_format.py. 사진은 prepare_images.py 가 채운다 —
유효 사진 2장 미만(blog.photo_missing)이면 그 글은 저장하지 않는다(글만 있는 포스트 금지).

설계 원칙: 이 코드에는 '발행' 버튼을 누르는 경로가 없다. 저장 버튼만 글자로 찾아 누르고,
글자에 '발행'이 들어간 요소는 어떤 경우에도 누르지 않는다.
종료 코드: 0 정상/할 일 없음 · 1 오류 · 2 확인 필요(발행 의심) · 3 설정 없음/크롬 없음/로그인 만료
"""
import argparse, datetime, json, os, random, re, subprocess, sys, time, urllib.request
from pathlib import Path

import naver_format as nf

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
ENV = ROOT / ".env.local"
LOGDIR = ROOT / "logs"
IMGDIR = ROOT / "images"
CDP = "http://127.0.0.1:9222"
ALLOW_SAVE = ["임시저장", "저장"]
FORBID = ["발행", "공개발행", "예약발행", "publish"]
MAX_PHOTOS = 3
RETRY_WAIT = 180          # 자동 재시도는 1회만, 3분 뒤
MIN_PHOTOS = 2            # 사진이 이보다 적게 들어가면 저장하지 않는다
FORMAT_BUDGET = 150       # 글당 조판 상한(초)
REWORK_LIMIT = 60 * 60    # 재작성 일괄 실행 상한(초)
NO_CLICK = ["삭제", "삭제하기", "delete", "로그아웃", "log out"]   # 임시저장 목록 등에서 절대 누르지 않을 글자


class AlertError(RuntimeError):
    """발행 의심 — 사람이 바로 봐야 함(종료 2)."""


class SetupError(RuntimeError):
    """로그인 만료 등(종료 3)."""


class HoldError(RuntimeError):
    """사진 부족 등 — 저장하지 않고 보류(다음 건으로 넘어가지 않음)."""


def log(msg):
    LOGDIR.mkdir(exist_ok=True)
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line)
    with open(LOGDIR / f"naver_{datetime.date.today():%Y-%m-%d}.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_env():
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            s = raw.strip()
            if s and not s.startswith("#") and "=" in s:
                k, v = s.split("=", 1)
                cfg[k.strip()] = v.strip().strip('"').strip("'")
    return cfg


def cdp_alive():
    try:
        with urllib.request.urlopen(f"{CDP}/json/version", timeout=5) as r:
            return r.status == 200
    except Exception:
        return False


def load_queue():
    return json.loads(QUEUE.read_text(encoding="utf-8"))


def save_queue(q):
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)


def ordered(q):
    return sorted(q.get("items", []), key=lambda it: it.get("order", 10 ** 6))


def pending_items(q, n):
    out = []
    for it in ordered(q):
        if it.get("blog", {}).get("status", "pending") == "pending":
            out.append(it)
        if len(out) >= n:
            break
    return out


def split_by_photo(body: str):
    """본문을 [(타입, 값)] 로 자른다. 타입은 'text' 또는 'photo'."""
    parts, last = [], 0
    for m in re.finditer(r"^\[사진(\d)\]\s*$", body, flags=re.M):
        if body[last:m.start()].strip():
            parts.append(("text", body[last:m.start()]))
        parts.append(("photo", int(m.group(1))))
        last = m.end()
    if body[last:].strip():
        parts.append(("text", body[last:]))
    return parts


def photo_path(blog, n):
    imgs = blog.get("images", []) or []
    if n < 1 or n > len(imgs) or n > MAX_PHOTOS:
        return None
    p = Path(imgs[n - 1])
    return p if p.is_absolute() else (IMGDIR / p)


# ---------------------------------------------------------------- 브라우저 조작

JS_CLICK = """([wanted, forbid, saveLike]) => {
  const els = [...document.querySelectorAll('button, a, span, div, li')];
  for (const el of els) {
    if (!el.offsetParent) continue;
    const t = (el.textContent || '').replace(/\\s+/g, ' ').trim();
    const cls = (typeof el.className === 'string' ? el.className : '') || '';
    const low = (t + ' ' + cls).toLowerCase();
    if (forbid.some(b => low.includes(b.toLowerCase()))) continue;   // 금지어가 조금이라도 섞이면 절대 안 누름
    let ok = wanted.includes(t);
    if (!ok && saveLike) ok = /^(임시)?저장\\s*\\d*$/.test(t);       // '저장 3' 처럼 개수가 붙은 저장 버튼
    if (ok && !el.querySelector('button, a')) { el.click(); return t + ' :: ' + cls.slice(0, 60); }
  }
  return null;
}"""


def click_by_text(fr, texts, save_like=False):
    for t in texts:
        if any(b in t for b in FORBID):
            raise AlertError(f"금지 버튼 클릭 차단: {t}")
    hit = fr.evaluate(JS_CLICK, [texts, FORBID, save_like])
    if not hit:
        raise RuntimeError(f"버튼 못 찾음: {texts}")
    return hit


def dump_buttons(fr, tag=""):
    """에디터 개편으로 셀렉터가 바뀌었을 때 원인을 찾는 진단용."""
    info = fr.evaluate(
        """() => ({
             url: location.href,
             buttons: [...document.querySelectorAll('button')]
               .filter(b => b.offsetParent)
               .map(b => (b.className || '') + ' :: ' + (b.textContent || '').trim()).slice(0, 60),
             inputs: [...document.querySelectorAll('[contenteditable="true"], input')]
               .filter(e => e.offsetParent || e.type === 'file')
               .map(e => (e.tagName + '.' + (e.className || '') + ' type=' + (e.type || '') +
                          ' ph=' + (e.getAttribute('placeholder') || ''))).slice(0, 40)
           })""")
    log(f"[PROBE:{tag}] url={info['url']}")
    log(f"[PROBE:{tag}] buttons={info['buttons']}")
    log(f"[PROBE:{tag}] inputs={info['inputs']}")


def editor_frame(page):
    """옛 구조(#mainFrame iframe)와 새 구조(postwrite 직접) 모두 지원."""
    for _ in range(20):
        fr = page.frame(name="mainFrame")
        if fr is not None:
            try:
                fr.wait_for_load_state("domcontentloaded", timeout=20000)
            except Exception:
                pass
            return fr
        if "postwrite" in page.url.lower() or page.locator(".se-content").count():
            return page.main_frame
        time.sleep(1)
    return page.main_frame


def first_visible(fr, sels):
    for sel in sels:
        loc = fr.locator(sel).first
        try:
            if loc.count() and loc.is_visible():
                return sel, loc
        except Exception:
            continue
    return None, None


def screenshot(page, name, full=False):
    LOGDIR.mkdir(exist_ok=True)
    shot = LOGDIR / f"{name}_{datetime.datetime.now():%Y%m%d_%H%M%S}.png"
    try:
        page.screenshot(path=str(shot), full_page=full)
    except Exception:
        pass
    return shot


def published_suspect(page, fr):
    urls = [page.url]
    try:
        urls.append(fr.url)
    except Exception:
        pass
    for u in urls:
        lu = u.lower()
        if "postview" in lu:
            return u
        if "logno=" in lu and "redirect=write" not in lu and "postwrite" not in lu:
            return u
    return None


def upload_photo(page, fr, path):
    """사진 1장을 현재 커서 위치에 넣는다. 파일 선택창은 Playwright 가 가로챈다."""
    inp = fr.locator("input[type=file]")
    if inp.count():
        inp.first.set_input_files(str(path))
        return "input"
    with page.expect_file_chooser(timeout=15000) as fc:
        sel, btn = first_visible(fr, ["button.se-image-toolbar-button", "button[data-name='image']",
                                      "button[data-log='dot.img']"])
        if btn is not None:
            btn.click()
        else:
            click_by_text(fr, ["사진"])
    fc.value.set_files(str(path))
    return "chooser"


def type_text(page, val):
    for block in [b for b in val.split("\n\n") if b.strip()]:
        for line in block.split("\n"):
            if line:
                page.keyboard.type(line, delay=8)
            page.keyboard.press("Enter")
            time.sleep(0.1)
        page.keyboard.press("Enter")
        time.sleep(0.15)


def do_one(page_factory, blog_id, it, state):
    """1건 임시저장. state['saved_clicked'] 가 True 가 되면 재시도하지 않는다(중복 임시저장 방지)."""
    blog = it["blog"]
    page = page_factory()
    try:
        page.goto(f"https://blog.naver.com/{blog_id}?Redirect=Write", wait_until="domcontentloaded")
        time.sleep(5)
        if "nid.naver.com" in page.url:
            raise SetupError("네이버 로그인이 풀렸습니다 — start_sns_chrome.bat 창에서 다시 로그인하세요")
        fr = editor_frame(page)
        time.sleep(2)
        if "captcha" in (fr.content() or "").lower()[:20000]:
            screenshot(page, "naver_CAPTCHA")
            raise SetupError("캡차/추가 인증 화면 — 사람이 처리해야 합니다")

        # 팝업 정리: '작성 중인 글이 있습니다' → 취소(새 글로 시작), 도움말 닫기
        for t in (["취소"], ["닫기"]):
            try:
                click_by_text(fr, t)
                time.sleep(1)
            except RuntimeError:
                pass
        fr.evaluate("""() => document.querySelectorAll('[class*="se-help"], [class*="help-panel"]')
                              .forEach(e => e.remove())""")

        # 제목
        sel, loc = first_visible(fr, [".se-documentTitle .se-text-paragraph", ".se-title-text",
                                      ".se-documentTitle [contenteditable='true']"])
        if loc is None:
            dump_buttons(fr, "title-fail")
            raise RuntimeError("제목 칸을 못 찾음 — --probe 로 구조 확인 필요")
        loc.click()
        page.keyboard.type(blog["title"], delay=15)
        time.sleep(1)

        # 본문 — 제목 다음 본문 칸
        sel, loc = first_visible(fr, [".se-section-text .se-text-paragraph", ".se-component.se-text .se-text-paragraph",
                                      ".se-content .se-text-paragraph"])
        if loc is None:
            dump_buttons(fr, "body-fail")
            raise RuntimeError("본문 칸을 못 찾음 — --probe 로 구조 확인 필요")
        loc.click()
        time.sleep(0.5)

        photos = 0
        for kind, val in split_by_photo(blog["body"]):
            if kind == "text":
                type_text(page, val)
                continue
            path = photo_path(blog, val)
            if not path or not path.exists():
                log(f"  [주의] [사진{val}] 파일 없음 — 자리만 건너뜀 ({path.name if path else '-'})")
                continue
            try:
                how = upload_photo(page, fr, path)
                time.sleep(6)
                page.keyboard.press("End")
                page.keyboard.press("Enter")
                photos += 1
                log(f"  사진{val} 업로드({how}) {path.name}")
            except Exception as e:
                log(f"  [주의] 사진{val} 업로드 실패({path.name}): {str(e)[:200]}")
        time.sleep(2)

        # 태그 — 에디터 화면에 태그 칸이 있을 때만(SmartEditor ONE 은 태그 칸이 '발행' 설정창 안에 있어
        # 이 경로로는 못 넣는다 → 본문 끝에 #태그 한 줄로 남기고, 발행 때 확인하도록 로그에 적는다)
        tags = [t for t in blog.get("tags", [])][:12]
        tagbox = fr.locator("input[placeholder*='태그']")
        if tags and tagbox.count() and tagbox.first.is_visible():
            for tag in tags:
                tagbox.first.click()
                page.keyboard.type(tag, delay=10)
                page.keyboard.press("Enter")
                time.sleep(0.3)
            log(f"  태그 {len(tags)}개 입력")
        elif tags:
            page.keyboard.type(" ".join("#" + t.replace(" ", "") for t in tags), delay=8)
            page.keyboard.press("Enter")
            log(f"  태그 칸 없음 → 본문 끝에 #태그 {len(tags)}개 한 줄로 넣음(발행 화면 태그 칸은 사람이 확인)")

        # ---- 저장(임시저장) — 발행 금지 ----
        if published_suspect(page, fr):
            raise AlertError(f"저장 전인데 글쓰기 화면이 아닙니다: {published_suspect(page, fr)}")
        state["saved_clicked"] = True
        clicked = click_by_text(fr, ALLOW_SAVE, save_like=True)
        log(f"  클릭: {clicked}")
        time.sleep(5)

        sus = published_suspect(page, fr)
        if sus:
            shot = screenshot(page, "naver_ALERT", full=True)
            raise AlertError(f"글쓰기 화면을 벗어났습니다(발행 의심) {sus} · 스크린샷 {shot.name}")
        toast = fr.evaluate("""() => [...document.querySelectorAll('div,span,p')]
              .filter(e => e.offsetParent && /저장(되었|됐|완료)/.test(e.textContent || '') && e.children.length < 3)
              .map(e => e.textContent.trim()).slice(0, 2)""")
        shot = screenshot(page, "naver")
        log(f"  [OK] 임시저장 · 사진 {photos}장 · 알림 {toast or '(못 찾음 — 스크린샷으로 확인)'} · {shot.name}")

        blog["status"] = "drafted"
        blog["drafted_at"] = f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}"
        return 0
    except (AlertError, SetupError):
        screenshot(page, "naver_ERR")
        raise
    except Exception:
        screenshot(page, "naver_ERR")
        raise
    finally:
        try:
            page.close()
        except Exception:
            pass


def run_live(cfg, q, count, scheduled):
    blog_id = cfg.get("NAVER_BLOG_ID", "")
    if not blog_id:
        log("[SKIP] NAVER_BLOG_ID 없음 (.env.local)")
        return 3
    if not cdp_alive():
        log("[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요")
        return 3

    today = f"{datetime.date.today():%Y-%m-%d}"
    if scheduled and any(str(it.get("blog", {}).get("drafted_at", "")).startswith(today) for it in q["items"]):
        log("[SKIP] 오늘 이미 임시저장했습니다(같은 날 두 번 하지 않음)")
        return 0

    items = pending_items(q, count)
    if not items:
        log("[SKIP] 블로그 큐에 남은 글이 없습니다")
        return 0

    from playwright.sync_api import sync_playwright

    ok = fail = 0
    code = 0
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(CDP)
        ctx = browser.contexts[0] if browser.contexts else browser.new_context()

        def new_page():
            pg = ctx.new_page()
            pg.set_default_timeout(20000)
            return pg

        for idx, it in enumerate(items):
            log(f"[{idx + 1}/{len(items)}] {it['id']} · {it['blog']['title'][:40]}")
            for attempt in (1, 2):
                state = {"saved_clicked": False}
                try:
                    do_one(new_page, blog_id, it, state)
                    save_queue(q)          # drafted 기록 후에만 다음 건으로
                    ok += 1
                    break
                except AlertError as e:
                    log(f"[확인필요] {e}")
                    code = 2
                except SetupError as e:
                    log(f"[SKIP] {e}")
                    code = 3
                except Exception as e:
                    log(f"[실패] {str(e)[:300]}")
                    code = 1
                    if attempt == 1 and not state["saved_clicked"]:
                        log(f"  {RETRY_WAIT // 60}분 뒤 1회만 다시 시도합니다")
                        time.sleep(RETRY_WAIT)
                        continue
                break
            if it["blog"].get("status") != "drafted":
                fail += 1
                break                       # 실패하면 멈춘다(뒤 건은 다음 실행)
            code = 0
            if idx + 1 < len(items):
                time.sleep(random.randint(20, 40))   # 건 사이 20~40초
    log(f"임시저장 {ok}건 완료 · 실패 {fail}건")
    return code if fail else 0


def main():
    ap = argparse.ArgumentParser(description="네이버 블로그 임시저장(발행 금지)")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--list", action="store_true")
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--live", action="store_true")
    g.add_argument("--probe", action="store_true")
    ap.add_argument("--count", type=int, default=10, help="--live 때 임시저장할 건수(기본 10)")
    a = ap.parse_args()
    scheduled = not (a.list or a.dry_run or a.live or a.probe)

    cfg = load_env()
    q = load_queue()

    if a.list:
        for it in ordered(q):
            b = it.get("blog", {})
            log(f"{it['id']:<26} blog={b.get('status', 'pending'):<8} {len(b.get('body', '')):>5}자  {b.get('title', '')[:40]}")
        return 0

    if a.dry_run:
        items = pending_items(q, 1)
        if not items:
            log("[DRY] 블로그 큐에 남은 글이 없습니다")
            return 0
        item = items[0]
        blog = item["blog"]
        parts = split_by_photo(blog["body"])
        log(f"[DRY] 항목 {item['id']} · 제목 {blog['title']}")
        log(f"[DRY] 본문 {len(blog['body'])}자 · 문단묶음 {sum(1 for k, _ in parts if k == 'text')} · "
            f"사진자리 {[v for k, v in parts if k == 'photo']}")
        log(f"[DRY] 태그 {len(blog.get('tags', []))}개: {', '.join(blog.get('tags', []))}")
        for n, img in enumerate(blog.get("images", [])[:MAX_PHOTOS], 1):
            pth = photo_path(blog, n)
            log(f"[DRY] 사진{n} {img} · {'있음' if pth and pth.exists() else '없음(건너뜀)'}")
        if "발행" in json.dumps(ALLOW_SAVE, ensure_ascii=False):
            log("[DRY] 오류: 허용 버튼에 '발행'이 들어 있음")
            return 1
        print("[DRY] ---- 본문 ----")
        print(blog["body"])
        print("[DRY] ---- 끝 ----")
        return 0

    if a.probe:
        blog_id = cfg.get("NAVER_BLOG_ID", "")
        if not blog_id:
            log("[SKIP] NAVER_BLOG_ID 없음 (.env.local)")
            return 3
        if not cdp_alive():
            log("[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요")
            return 3
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            ctx = p.chromium.connect_over_cdp(CDP).contexts[0]
            page = ctx.new_page()
            try:
                page.goto(f"https://blog.naver.com/{blog_id}?Redirect=Write", wait_until="domcontentloaded")
                time.sleep(6)
                if "nid.naver.com" in page.url:
                    log("[SKIP] 네이버 로그인이 풀렸습니다")
                    return 3
                dump_buttons(editor_frame(page), "probe")
                log(f"[PROBE] 스크린샷 {screenshot(page, 'naver_PROBE').name}")
            finally:
                page.close()        # 아무것도 입력·저장하지 않고 닫는다
        return 0

    if scheduled:
        if cfg.get("SNS_DAILY_ENABLED", "1") == "0":
            log("[SKIP] SNS_DAILY_ENABLED=0 (비상 정지)")
            return 0
        return run_live(cfg, q, 1, scheduled=True)
    return run_live(cfg, q, max(1, a.count), scheduled=False)


if __name__ == "__main__":
    sys.exit(main())
