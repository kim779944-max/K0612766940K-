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
        b = it.get("blog", {})
        if b.get("status", "pending") == "pending" and not b.get("photo_missing"):
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
               .map(b => (b.className || '').slice(0, 60) + ' :: ' + (b.textContent || '').trim().slice(0, 30)).slice(0, 60),
             toolbar: [...document.querySelectorAll('[data-name]')]
               .filter(b => b.offsetParent)
               .map(b => [b.getAttribute('data-name'), b.getAttribute('data-value'), b.getAttribute('data-log'),
                          b.getAttribute('aria-label'), b.getAttribute('title'),
                          (b.textContent || '').replace(/\\s+/g, ' ').trim().slice(0, 20)].join('|')).slice(0, 120),
             inputs: [...document.querySelectorAll('[contenteditable="true"], input')]
               .filter(e => e.offsetParent || e.type === 'file')
               .map(e => (e.tagName + '.' + (e.className || '') + ' type=' + (e.type || '') +
                          ' ph=' + (e.getAttribute('placeholder') || ''))).slice(0, 40)
           })""")
    log(f"[PROBE:{tag}] url={info['url']}")
    log(f"[PROBE:{tag}] buttons={info['buttons']}")
    log(f"[PROBE:{tag}] inputs={info['inputs']}")
    for row in info.get("toolbar", []):
        log(f"[PROBE:{tag}] toolbar {row}")


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


# ---------------------------------------------------------------- 임시저장함 실측

DRAFTS_JS = """async (blogId) => {
  const u = v => `https://blog.naver.com/TempPostList.naver?blogId=${blogId}&editorVersion=${v}&onlyCount=false`;
  const out = {list: [], counts: {}};
  for (const v of [4, 2]) {
    try {
      const r = await fetch(u(v), {credentials: 'include'});
      const t = await r.text();
      const j = JSON.parse(t.slice(t.indexOf('{')));
      out.counts[v] = (j.result && j.result.totalCount) || 0;
      for (const x of ((j.result && j.result.tempPostList) || []))
        out.list.push({logNo: String(x.logNo), title: x.title, modiDate: x.modiDate, editorVersion: x.editorVersion});
    } catch (e) { out.counts[v] = 'ERR ' + e; }
  }
  return out;
}"""


def fetch_drafts(fr_or_page, blog_id):
    """임시저장함 목록(읽기 전용 GET). blog.naver.com 출처 페이지/프레임에서 호출해야 쿠키가 붙는다."""
    d = fr_or_page.evaluate(DRAFTS_JS, blog_id)
    for x in d["list"]:
        x["saved"] = datetime.datetime.fromtimestamp(x["modiDate"] / 1000).strftime("%Y-%m-%d %H:%M:%S")
    d["counts"] = {int(k): v for k, v in d["counts"].items()}
    uniq = {}
    for x in d["list"]:
        uniq[x["logNo"]] = x            # 같은 글이 두 목록에 나와도 1편으로
    d["list"] = sorted(uniq.values(), key=lambda v: -v["modiDate"])
    d["total"] = len(d["list"])
    return d


def classify(q, drafts):
    by_title = {}
    for x in drafts["list"]:
        by_title.setdefault(x["title"].strip(), []).append(x)
    matched, missing = [], []
    for it in ordered(q):
        t = it["blog"]["title"].strip()
        if t in by_title:
            matched.append((it, by_title[t]))
        else:
            missing.append(it)
    qtitles = {it["blog"]["title"].strip() for it in q["items"]}
    extra = [x for x in drafts["list"] if x["title"].strip() not in qtitles]
    return matched, extra, missing


def with_blog_page(blog_id, fn):
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        ctx = p.chromium.connect_over_cdp(CDP).contexts[0]
        page = ctx.new_page()
        try:
            page.goto(f"https://blog.naver.com/{blog_id}", wait_until="domcontentloaded")
            time.sleep(2)
            if "nid.naver.com" in page.url:
                raise SetupError("네이버 로그인이 풀렸습니다 — start_sns_chrome.bat 창에서 다시 로그인하세요")
            return fn(page)
        finally:
            page.close()


def print_drafts(q, d):
    matched, extra, missing = classify(q, d)
    log(f"[임시저장함] 총 {d['total']}편 (에디터4 {d['counts'].get(4)} · 에디터2 {d['counts'].get(2)})")
    log(f"{'logno':<14} {'저장시각':<19} 제목")
    for x in d["list"]:
        log(f"{x['logNo']:<14} {x['saved']:<19} {x['title'][:50]}")
    log(f"① 일치(재작성 대상) {len(matched)}편: " + ", ".join(
        f"{it['id'].split('_', 1)[1]}={'/'.join(x['logNo'] for x in xs)}" for it, xs in matched))
    dup = [it["id"] for it, xs in matched if len(xs) > 1]
    if dup:
        log(f"   [주의] 같은 제목이 2편 이상: {dup} (삭제하지 않음 — 대표님 판단)")
    log(f"② 큐에 없음(손대지 않음) {len(extra)}편: " + (", ".join(f"{x['logNo']} {x['title'][:30]}" for x in extra) or "없음"))
    log(f"③ 큐에 있는데 임시저장 없음(신규 작성 대상) {len(missing)}편: " + (", ".join(it["id"] for it in missing) or "없음"))
    return matched, extra, missing


def git_commit_queue(msg):
    """post_queue.json 만 커밋(로컬에만 남겨 두지 않는다 — 다음 실행 중복 방지)."""
    repo = ROOT.parent.parent
    try:
        subprocess.run(["git", "-C", str(repo), "add", str(QUEUE)], check=True, capture_output=True, timeout=60)
        r = subprocess.run(["git", "-C", str(repo), "commit", "-m", msg, "--", str(QUEUE)],
                           capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=60)
        out = (r.stdout + r.stderr).strip().splitlines()
        log(f"  git commit: {out[0] if out else r.returncode}")
        return r.returncode == 0
    except Exception as e:
        log(f"  [주의] git commit 실패(큐 파일은 저장됨): {str(e)[:200]}")
        return False


def reconcile(q, d):
    matched, extra, missing = print_drafts(q, d)
    changed = 0
    for it, xs in matched:
        b = it["blog"]
        x = sorted(xs, key=lambda v: v["modiDate"])[-1]
        if b.get("draft_logno") != x["logNo"] or b.get("status") != "drafted":
            b["draft_logno"] = x["logNo"]
            b["status"] = "drafted"
            b["drafted_at"] = b.get("drafted_at") or x["saved"].replace(" ", "T")
            changed += 1
    save_queue(q)
    log(f"[reconcile] 큐 반영 {changed}건")
    return changed


# ---------------------------------------------------------------- 1건 작성(새 글 / 덮어쓰기)

def _upload(page, fr, path):
    """upload_photo 재사용. 'input' 경로가 조용히 실패하면 파일 선택창으로 한 번 더."""
    n0 = fr.locator(".se-component.se-image").count()
    how = upload_photo(page, fr, path)
    if how == "input":
        time.sleep(4)
        if fr.locator(".se-component.se-image").count() == n0:
            with page.expect_file_chooser(timeout=15000) as fc:
                fr.locator(nf.SEL["image"]).first.click()
            fc.value.set_files(str(path))
            how = "chooser(재시도)"
    return how


def open_editor(page, blog_id):
    page.goto(f"https://blog.naver.com/{blog_id}?Redirect=Write", wait_until="domcontentloaded")
    time.sleep(5)
    if "nid.naver.com" in page.url:
        raise SetupError("네이버 로그인이 풀렸습니다 — start_sns_chrome.bat 창에서 다시 로그인하세요")
    fr = editor_frame(page)
    for _ in range(15):
        if fr.locator(".se-documentTitle").count():
            break
        time.sleep(1)
    time.sleep(1)
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
    return fr


def editor_title(fr):
    return fr.evaluate("""() => { const t = document.querySelector('.se-documentTitle .se-text-paragraph');
                                  return t ? t.textContent.replace(/\\u00a0/g, ' ').trim() : null; }""")


def load_draft(page, fr, title):
    """임시저장 목록 패널에서 제목이 정확히 같은 글을 연다(삭제 버튼은 후보에서 제외)."""
    btn = fr.locator("button[class*='save_count_btn']").first
    if not btn.count():
        raise RuntimeError("임시저장 개수 버튼을 못 찾음 — --probe 확인")
    btn.click()
    time.sleep(2.5)
    items = fr.locator("button[class*='article_button']")
    hit = None
    for i in range(items.count()):
        el = items.nth(i)
        t = (el.locator("strong").first.text_content() or "").strip()
        full = (el.text_content() or "") + " " + (el.get_attribute("class") or "") + " " + (el.get_attribute("title") or "")
        if any(b in full.lower() for b in NO_CLICK) or any(b in full for b in FORBID):
            continue
        if t == title.strip():
            hit = el
            break
    if hit is None:
        raise RuntimeError("임시저장 목록에서 같은 제목을 못 찾음")
    hit.click()
    time.sleep(4)
    got = editor_title(fr)
    if (got or "").strip() != title.strip():
        raise RuntimeError(f"불러온 글 제목 불일치: {got!r}")


def body_texts(fr):
    return fr.evaluate("""() => [...document.querySelectorAll('.se-component')]
                           .filter(c => !c.classList.contains('se-documentTitle'))
                           .map(c => [...c.querySelectorAll('.se-text-paragraph')]
                                .filter(p => !p.querySelector('.se-placeholder')).map(p => p.textContent).join('')).join('')""")


def clear_body(page, fr):
    fr.locator(".se-section-text .se-text-paragraph, .se-component.se-text .se-text-paragraph").first.click()
    for _ in range(2):
        page.keyboard.press("Control+a")
        time.sleep(0.4)
    page.keyboard.press("Delete")
    time.sleep(1.5)
    left = fr.evaluate("""() => [...document.querySelectorAll('.se-component')]
                           .filter(c => !c.classList.contains('se-documentTitle')).length""")
    if left > 1 or body_texts(fr).strip():
        raise RuntimeError(f"본문 비우기 실패(컴포넌트 {left}개 남음)")


def body_start(fr):
    sel, loc = first_visible(fr, [".se-section-text .se-text-paragraph", ".se-component.se-text .se-text-paragraph",
                                  ".se-content .se-text-paragraph"])
    if loc is None:
        dump_buttons(fr, "body-fail")
        raise RuntimeError("본문 칸을 못 찾음 — --probe 로 구조 확인 필요")
    loc.click()
    time.sleep(0.5)


def shots_three(page, fr, name):
    """본문 상단·중단·하단 3장."""
    out = []
    comps = fr.locator(".se-component")
    n = comps.count()
    for tag, idx in (("1", 0), ("2", n // 2), ("3", n - 1)):
        try:
            comps.nth(max(0, idx)).scroll_into_view_if_needed()
            time.sleep(0.8)
            path = LOGDIR / f"{name}_{tag}.png"
            page.screenshot(path=str(path))
            out.append(path.name)
        except Exception:
            pass
    return out


def write_verify(rec):
    LOGDIR.mkdir(exist_ok=True)
    path = LOGDIR / f"format_verify_{datetime.date.today():%Y%m%d}.json"
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
    data.append(rec)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return path.name


def do_one(page_factory, blog_id, it, state, mode="new"):
    """1건 임시저장(mode=new) 또는 기존 임시저장 덮어쓰기(mode=rework).
    state['saved_clicked'] 가 True 가 되면 재시도하지 않는다(중복 임시저장 방지)."""
    blog = it["blog"]
    key = it["id"].split("_", 1)[1]
    have = sum(1 for n in range(1, MAX_PHOTOS + 1) if (photo_path(blog, n) or Path("-")).exists())
    if blog.get("photo_missing") or have < MIN_PHOTOS:
        raise HoldError(f"사진 부족으로 보류: {key} 확보 {have}/3 — prepare_images.py --prepare 먼저")
    page = page_factory()
    try:
        fr = open_editor(page, blog_id)
        before = fetch_drafts(fr, blog_id)
        state["drafts_before"] = before["total"]

        if mode == "rework":
            load_draft(page, fr, blog["title"])
            clear_body(page, fr)
        else:
            sel, loc = first_visible(fr, [".se-documentTitle .se-text-paragraph", ".se-title-text",
                                          ".se-documentTitle [contenteditable='true']"])
            if loc is None:
                dump_buttons(fr, "title-fail")
                raise RuntimeError("제목 칸을 못 찾음 — --probe 로 구조 확인 필요")
            loc.click()
            page.keyboard.insert_text(blog["title"])
            time.sleep(1)
        if (editor_title(fr) or "").strip() != blog["title"].strip():
            raise RuntimeError("제목 입력 확인 실패")

        body_start(fr)
        # 태그 칸이 화면에 실제로 보일 때만 그 칸에(발행 설정창은 열지 않는다), 아니면 본문 끝 태그 블록
        tags = [t for t in blog.get("tags", [])][:12]
        tagbox = fr.locator("input[placeholder*='태그']")
        tagbox_visible = bool(tags and tagbox.count() and tagbox.first.is_visible())
        blocks, _ = nf.plan_blocks(blog, with_tags=not tagbox_visible)
        stats = nf.render(page, fr, blocks, lambda n: photo_path(blog, n), _upload, log, FORMAT_BUDGET)
        if tagbox_visible:
            for tag in tags:
                tagbox.first.click()
                page.keyboard.insert_text(tag)
                page.keyboard.press("Enter")
                time.sleep(0.3)
            log(f"  태그 {len(tags)}개 태그 칸에 입력")
        log(f"  조판 {stats['seconds']}초 · 소제목 {stats['headings']}(대체 {stats['heading_fallback']}) · "
            f"인용구 {stats['quotes']} · 구분선 {stats['hrs']} · 사진 {stats['photos']} · 줄간격 {stats['line_height']}"
            + (f" · {stats['log'][:4]}" if stats["log"] else ""))
        if stats["photos"] < MIN_PHOTOS:
            raise HoldError(f"사진 {stats['photos']}장만 들어감(<{MIN_PHOTOS}) → 저장하지 않고 보류")
        time.sleep(1.5)

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

        # 임시저장 개수: 덮어쓰기는 +0, 새 글은 +1 이어야 한다
        after = fetch_drafts(fr, blog_id)
        expect = before["total"] + (0 if mode == "rework" else 1)
        state["drafts_after"] = after["total"]
        mine = sorted([x for x in after["list"] if x["title"].strip() == blog["title"].strip()],
                      key=lambda v: v["modiDate"])
        if after["total"] != expect:
            screenshot(page, "naver_COUNT", full=False)
            raise AlertError(f"임시저장 개수 {before['total']}→{after['total']} (기대 {expect}) — 중복 생성 의심, 전부 중단")

        m = nf.measure(fr)
        ok, why = nf.judge(blog, m, with_tags=not tagbox_visible)
        shots = shots_three(page, fr, f"rework_{key}" if mode == "rework" else f"naver_fmt_{key}")
        rec = {"key": key, "mode": mode, "at": f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}",
               "logno": mine[-1]["logNo"] if mine else None, "drafts_before": before["total"],
               "drafts_after": after["total"], "headings": len(m["headings"]),
               "heading_min_px": min([h["size"] for h in m["headings"]] or [0]),
               "heading_min_weight": min([h["weight"] for h in m["headings"]] or [0]),
               "quotes": len(m["quotes"]), "hrs": m["hrs"], "photos": m["photos"],
               "tags_line": (m["lines"][-1] if m["lines"] and m["lines"][-1].startswith("#") else ""),
               "text_lines": len(m["lines"]), "spacing_bad": m["spacing_bad"], "format_timeout": stats["format_timeout"],
               "seconds": stats["seconds"], "ok": ok, "why": why, "screenshot": shots}
        vf = write_verify(rec)
        log(f"  [OK] 임시저장 · 사진 {m['photos']}장 · 개수 {before['total']}→{after['total']} · "
            f"알림 {toast or '(못 찾음 — 스크린샷으로 확인)'} · 판정 {'합격' if ok else '불합격 ' + str(why)} · {vf} · {shots}")

        blog["status"] = "drafted"
        blog["drafted_at"] = f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}"
        if mine:
            blog["draft_logno"] = mine[-1]["logNo"]
        blog["format_version"] = 2
        blog["format_ok"] = ok
        if ok:
            blog.pop("format_issue", None)
        else:
            blog["format_issue"] = "; ".join(why)[:300]
        if stats["format_timeout"]:
            blog["format_timeout"] = True
        if mode == "rework":
            blog["reworked_at"] = blog["drafted_at"]
        state["ok"] = ok
        state["why"] = why
        return 0
    except (AlertError, SetupError, HoldError):
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

    held = [it["id"] for it in ordered(q) if it.get("blog", {}).get("status", "pending") == "pending"
            and it["blog"].get("photo_missing")]
    if held:
        log(f"[보류] 사진 부족 항목 건너뜀: {held} — prepare_images.py --prepare 후 다시")
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
                    do_one(new_page, blog_id, it, state, mode="new")
                    save_queue(q)          # drafted 기록 후에만 다음 건으로
                    ok += 1
                    break
                except AlertError as e:
                    log(f"[확인필요] {e}")
                    code = 2
                except SetupError as e:
                    log(f"[SKIP] {e}")
                    code = 3
                except HoldError as e:
                    log(f"[보류] {e}")
                    it["blog"]["photo_missing"] = True
                    save_queue(q)
                    code = 1
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


def rework_targets(q, only=None):
    out = []
    for it in ordered(q):
        b = it["blog"]
        k = it["id"].split("_", 1)[1]
        if only and k not in only:
            continue
        if b.get("status") == "drafted" and b.get("draft_logno") and (b.get("format_version") != 2 or b.get("format_ok") is False):
            out.append(it)
    return out


def run_rework(cfg, q, count, only=None):
    """기존 임시저장 글을 새 양식으로 덮어쓴다. 한 편이라도 합격 기준을 못 넘으면 거기서 멈춘다(게이트)."""
    blog_id = cfg.get("NAVER_BLOG_ID", "")
    if not blog_id:
        log("[SKIP] NAVER_BLOG_ID 없음 (.env.local)")
        return 3
    if not cdp_alive():
        log("[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요")
        return 3
    items = rework_targets(q, only)[:max(1, count)]
    if not items:
        log("[SKIP] 재작성 대상 없음(--reconcile 먼저, 또는 이미 새 양식)")
        return 0
    from playwright.sync_api import sync_playwright
    t0 = time.time()
    done = 0
    with sync_playwright() as p:
        ctx = p.chromium.connect_over_cdp(CDP).contexts[0]

        def new_page():
            pg = ctx.new_page()
            pg.set_default_timeout(20000)
            return pg

        for idx, it in enumerate(items):
            if time.time() - t0 > REWORK_LIMIT:
                log(f"[중단] {REWORK_LIMIT // 60}분 상한 — 남은 {len(items) - idx}편은 다음 실행이 이어서")
                return 0
            log(f"[재작성 {idx + 1}/{len(items)}] {it['id']} · logno {it['blog'].get('draft_logno')} · {it['blog']['title'][:40]}")
            state = {"saved_clicked": False}
            try:
                do_one(new_page, blog_id, it, state, mode="rework")
                save_queue(q)
                done += 1
            except AlertError as e:
                save_queue(q)
                log(f"[확인필요] {e}")
                return 2
            except SetupError as e:
                log(f"[SKIP] {e}")
                return 3
            except HoldError as e:
                log(f"[보류] {e} — 여기서 멈춤")
                return 1
            except Exception as e:
                log(f"[실패] {str(e)[:300]} — 저장 버튼 {'누름' if state['saved_clicked'] else '안 누름'}, 여기서 멈춤")
                return 1
            if not state.get("ok"):
                log(f"[게이트] {it['id']} 합격 기준 미달 {state.get('why')} — 나머지는 손대지 않고 멈춤")
                return 1
            if idx + 1 < len(items):
                time.sleep(random.randint(20, 40))
    log(f"재작성 {done}편 완료")
    return 0


def audit(q):
    log(f"{'key':<10} {'본문':>5} {'소제목':>4} {'quotes':>6} {'사진':>5} {'태그':>3} {'링크':>3} {'구분선':>4}  판정")
    bad = 0
    for it in ordered(q):
        b = it["blog"]
        key = it["id"].split("_", 1)[1]
        blocks, rep = nf.plan_blocks(b)
        have = sum(1 for n in range(1, MAX_PHOTOS + 1) if (photo_path(b, n) or Path("-")).exists())
        tags = b.get("tags", [])
        verdict = []
        if have < MIN_PHOTOS or b.get("photo_missing"):
            verdict.append("사진부족")
        if rep["quotes_matched"] != rep["quotes_total"] or rep["quotes_total"] != 2:
            verdict.append("문구불일치")
        if rep["headings"] < 6:
            verdict.append("소제목<6")
        if rep["links"] > 1:
            verdict.append("링크>1")
        if len(tags) != 12 or len(set(tags)) != 12:
            verdict.append("태그≠12")
        exp = [re.sub(r"^■\s*", "", l.rstrip()) for l in b["body"].split("\n")
               if l.strip() and not nf.PHOTO_RE.match(l.strip())]
        if nf.expected_lines(b, with_tags=False) != exp:
            verdict.append("계획≠원문")
        v = "OK" if not verdict else "/".join(verdict)
        bad += bool(verdict)
        log(f"{key:<10} {len(b['body']):>5} {rep['headings']:>5} {rep['quotes_matched']:>4}/{rep['quotes_total']} "
            f"{have:>3}/3 {len(tags):>4} {rep['links']:>4} {rep['hrs'] + 1:>5}  {v}"
            + (f"  미일치 quote: {[x[:20] for x in rep['unmatched_quotes']]}" if rep["unmatched_quotes"] else ""))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description="네이버 블로그 임시저장(발행 금지)")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--list", action="store_true")
    g.add_argument("--dry-run", action="store_true")
    g.add_argument("--live", action="store_true")
    g.add_argument("--probe", action="store_true")
    g.add_argument("--audit", action="store_true")
    g.add_argument("--list-drafts", action="store_true")
    g.add_argument("--reconcile", action="store_true")
    g.add_argument("--rework", action="store_true")
    ap.add_argument("--count", type=int, default=10, help="--live/--rework 때 건수(기본 10, --rework 는 1편 게이트 권장)")
    ap.add_argument("--key", default="", help="--rework/--dry-run 대상 key(쉼표 구분, 예: slope)")
    ap.add_argument("--no-commit", action="store_true", help="--reconcile 때 git commit 생략")
    a = ap.parse_args()
    scheduled = not (a.list or a.dry_run or a.live or a.probe or a.audit or a.list_drafts or a.reconcile or a.rework)
    only = {s.strip() for s in a.key.split(",") if s.strip()} or None

    cfg = load_env()
    q = load_queue()

    if a.list:
        for it in ordered(q):
            b = it.get("blog", {})
            log(f"{it['id']:<26} blog={b.get('status', 'pending'):<8} {len(b.get('body', '')):>5}자  "
                f"logno={b.get('draft_logno', '-')} v{b.get('format_version', 1)}  {b.get('title', '')[:40]}")
        return 0

    if a.audit:
        return audit(q)

    if a.dry_run:
        pool = [it for it in ordered(q) if not only or it["id"].split("_", 1)[1] in only]
        items = [it for it in pool if it["blog"].get("status", "pending") == "pending"] or pool[:1]
        if not items:
            log("[DRY] 블로그 큐에 남은 글이 없습니다")
            return 0
        item = items[0]
        blog = item["blog"]
        blocks, rep = nf.plan_blocks(blog)
        log(f"[DRY] 항목 {item['id']} · 상태 {blog.get('status')} · 제목 {blog['title']}")
        log(f"[DRY] 본문 {len(blog['body'])}자 · 제목2(소제목) {rep['headings']}개 · 인용구 {rep['quotes_matched']}/{rep['quotes_total']}개 · "
            f"가로선 {rep['hrs']}+1(태그)개 · 사진 {len(rep['photos'])}장 {rep['photos']} · 링크 {rep['links']}줄 · "
            f"태그 {len(blog.get('tags', []))}개")
        for n in range(1, MAX_PHOTOS + 1):
            pth = photo_path(blog, n)
            if pth:
                log(f"[DRY] 사진{n} {pth.name} · {'있음' if pth.exists() else '없음 → 사진 2장 미만이면 저장 보류'}")
        if "발행" in json.dumps(ALLOW_SAVE, ensure_ascii=False):
            log("[DRY] 오류: 허용 버튼에 '발행'이 들어 있음")
            return 1
        print("[DRY] ---- 블록 계획 ----")
        for kind, val in blocks:
            print(f"  {kind:<8} {str(val)[:70]}")
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

    if a.list_drafts or a.reconcile:
        blog_id = cfg.get("NAVER_BLOG_ID", "")
        if not blog_id:
            log("[SKIP] NAVER_BLOG_ID 없음 (.env.local)")
            return 3
        if not cdp_alive():
            log("[SKIP] 크롬 창이 없습니다 — start_sns_chrome.bat 을 먼저 실행하세요")
            return 3
        try:
            d = with_blog_page(blog_id, lambda pg: fetch_drafts(pg, blog_id))
        except SetupError as e:
            log(f"[SKIP] {e}")
            return 3
        if a.list_drafts:
            print_drafts(q, d)
            return 0
        changed = reconcile(q, d)
        if changed and not a.no_commit:
            git_commit_queue(f"chore(sns): 임시저장함 실측 반영(reconcile) — {d['total']}편 · drafted {changed}건")
        return 0

    if a.rework:
        return run_rework(cfg, q, a.count, only)

    if scheduled:
        if cfg.get("SNS_DAILY_ENABLED", "1") == "0":
            log("[SKIP] SNS_DAILY_ENABLED=0 (비상 정지)")
            return 0
        return run_live(cfg, q, 1, scheduled=True)
    return run_live(cfg, q, max(1, a.count), scheduled=False)


if __name__ == "__main__":
    sys.exit(main())
