# -*- coding: utf-8 -*-
"""쓰레드 — 전용 크롬(CDP 9222, 프로필 %USERPROFILE%\\KTS_SNS_CHROME) 경로. threads_autopost.py 가 부른다.

원칙: 사람처럼 한 번만. 로그인 시도·로그아웃·삭제·계정 설정은 하지 않는다. 줄바꿈은 Shift+Enter
(작성창에서 Enter 는 '게시'). 게시 버튼은 1회만 누르고, 결과가 불확실하면 다시 누르지 않는다.
외부인 댓글에 자동 답글하는 코드는 없다(reply_to 는 대표님이 대상·문장을 지정해 부를 때만).
"""
import datetime
import re
import subprocess
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LOGDIR = ROOT / "logs"
CDP = "http://127.0.0.1:9222"
HOME = "https://www.threads.com/"
START_BAT = ROOT / "start_sns_chrome.bat"
NO_CLICK = ["삭제", "delete", "취소", "cancel", "로그아웃", "log out", "신고", "report"]
COMPOSE_TEXTS = ["새로운 스레드", "만들기", "Create", "New thread", "Start a thread", "무슨 생각을 하고 계신가요?",
                 "새 스레드"]
POST_TEXTS = ["게시", "Post"]


class ChromeSetupError(RuntimeError):
    """크롬 없음·로그인 풀림(종료 3)."""


class ChromeUnsure(RuntimeError):
    """게시 클릭 후 결과 불확실(종료 2, publishing 잠금)."""


def _norm(s):
    return re.sub(r"\s+", " ", (s or "").replace(" ", " ")).strip()


def cdp_alive():
    try:
        with urllib.request.urlopen(f"{CDP}/json/version", timeout=5) as r:
            return r.status == 200
    except Exception:
        return False


def ensure_chrome(log):
    """CDP 가 없으면 start_sns_chrome.bat 을 직접 실행하고 최대 60초 기다린다(프로필 폴더는 건드리지 않음)."""
    if cdp_alive():
        return
    if not START_BAT.exists():
        raise ChromeSetupError("start_sns_chrome.bat 이 없습니다")
    log("  전용 크롬이 꺼져 있어 start_sns_chrome.bat 실행")
    subprocess.Popen(["cmd", "/c", str(START_BAT)], cwd=str(ROOT),
                     creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    for _ in range(30):
        time.sleep(2)
        if cdp_alive():
            time.sleep(3)
            return
    raise ChromeSetupError("전용 크롬(CDP 9222)이 60초 안에 뜨지 않았습니다")


def shot(page, name):
    LOGDIR.mkdir(exist_ok=True)
    p = LOGDIR / f"{name}_{datetime.datetime.now():%Y%m%d_%H%M%S}.png"
    try:
        page.screenshot(path=str(p))
    except Exception:
        pass
    return p.name


LOGIN_JS = r"""() => {
  const vis = e => e.offsetParent && getComputedStyle(e).visibility !== 'hidden';
  const t = e => (e.textContent || '').replace(/\s+/g, ' ').trim();
  const loginBtn = [...document.querySelectorAll('a, button, [role=button]')]
      .some(e => vis(e) && /^(로그인|Log in)$/.test(t(e)));
  const loginUrl = /\/login|accounts\/login/.test(location.href);
  const nav = [...document.querySelectorAll('a[href^="/@"]')].filter(vis)
      .find(a => /프로필|Profile/.test(a.getAttribute('aria-label') || t(a) || ''));
  return {loginBtn, loginUrl, handle: nav ? nav.getAttribute('href').split('/')[1] : null};
}"""


def check_login(page):
    """로그인 판정: '로그인' 버튼·로그인 주소가 보이면 실패. 로그인 시도는 하지 않는다."""
    st = page.evaluate(LOGIN_JS)
    if st["loginBtn"] or st["loginUrl"]:
        raise ChromeSetupError("전용 크롬에서 threads 로그인이 풀렸습니다")
    return st


def read_handle(page, cfg_handle=""):
    if cfg_handle:
        return cfg_handle.lstrip("@")
    st = page.evaluate(LOGIN_JS)
    if st.get("handle"):
        return st["handle"].lstrip("@")
    # 왼쪽 '프로필' 아이콘 링크가 aria-label 없이 올 때: 첫 /@ 링크 중 /post/ 가 없는 것
    h = page.evaluate("""() => { const a = [...document.querySelectorAll('nav a[href^="/@"], a[href^="/@"]')]
                                  .find(x => !x.getAttribute('href').includes('/post/'));
                                 return a ? a.getAttribute('href').split('/')[1] : null; }""")
    return (h or "").lstrip("@")


TOP_POST_JS = r"""(handle) => {
  const a = [...document.querySelectorAll(`a[href^="/@${handle}/post/"]`)]
              .find(x => !/\/media|\/replies/.test(x.getAttribute('href')));
  if (!a) return null;
  let box = a.closest('[data-pressable-container]') || a;
  for (let i = 0; i < 8 && box && box.textContent.length < 20; i++) box = box.parentElement;
  return {href: a.getAttribute('href'), text: (box.innerText || box.textContent || '')};
}"""


def top_post(page, handle):
    page.goto(f"https://www.threads.com/@{handle}", wait_until="domcontentloaded")
    time.sleep(5)
    r = page.evaluate(TOP_POST_JS, handle)
    if not r:
        return None
    r["permalink"] = "https://www.threads.com" + r["href"].split("?")[0]
    return r


def same_post(top, text):
    """프로필 최상단 글이 오늘 본문과 같은지: 본문 앞 20자(공백 정규화)가 그 글 안에 있으면 같다."""
    if not top:
        return False
    head = _norm(text)[:20]
    return bool(head) and head in _norm(top["text"])


def _click_text(page, texts, scope=None):
    """글자가 정확히 같은 버튼 1개만 누른다. 금지어가 섞인 요소는 후보에서 제외."""
    root = scope or page
    for t in texts:
        loc = root.get_by_role("button", name=t, exact=True)
        for i in range(loc.count()):
            el = loc.nth(i)
            try:
                if not el.is_visible():
                    continue
                full = ((el.text_content() or "") + " " + (el.get_attribute("aria-label") or "")).lower()
                if any(b in full for b in NO_CLICK):
                    continue
                el.click()
                return t
            except Exception:
                continue
        loc = root.locator(f"a[aria-label='{t}'], [role=link][aria-label='{t}']")
        if loc.count() and loc.first.is_visible():
            loc.first.click()
            return t
    return None


def _composer(page, timeout=15):
    for _ in range(timeout * 2):
        box = page.locator("[role=dialog] [contenteditable=true][role=textbox], [role=dialog] [contenteditable=true]")
        if box.count() and box.first.is_visible():
            return box.first
        time.sleep(0.5)
    return None


def type_lines(page, text):
    """줄바꿈은 Shift+Enter — Enter 는 쓰지 않는다."""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line:
            page.keyboard.type(line, delay=40)
        if i < len(lines) - 1:
            page.keyboard.press("Shift+Enter")


def post(page, text, check_text, log):
    """작성창 열기 → 입력 → 규칙 재확인 → 게시 1회 → 확인. 반환: permalink. 불확실하면 ChromeUnsure."""
    if not _click_text(page, COMPOSE_TEXTS):
        raise RuntimeError("작성 버튼을 못 찾음")
    box = _composer(page)
    if box is None:
        raise RuntimeError("작성창이 15초 안에 뜨지 않음")
    box.click()
    type_lines(page, text)
    time.sleep(1.5 + (time.time() % 1.5))
    typed = page.evaluate("""() => { const b = document.querySelector('[role=dialog] [contenteditable=true]');
                                     return b ? b.innerText : ''; }""")
    errs = check_text(typed.strip())
    if errs:
        raise ValueError("입력된 본문이 규칙 위반: " + "; ".join(errs))
    if _norm(typed) != _norm(text):
        raise ValueError(f"입력된 본문이 큐와 다름({len(typed)}자/{len(text)}자) — 게시하지 않음")
    before = shot(page, "threads_before")
    dlg = page.locator("[role=dialog]").last
    hit = _click_text(page, POST_TEXTS, scope=dlg)
    if not hit:
        raise RuntimeError("게시 버튼을 못 찾음(아직 누르지 않음)")
    log(f"  게시 클릭 1회({hit}) · 클릭 전 스크린샷 {before}")
    return before


def confirm(page, handle, text, wait=30):
    """작성창이 닫히고 프로필 최상단 글 앞 20자가 본문과 같으면 성공."""
    t0 = time.time()
    while time.time() - t0 < wait:
        if not page.locator("[role=dialog] [contenteditable=true]").count():
            break
        time.sleep(1)
    time.sleep(3)
    top = top_post(page, handle)
    if same_post(top, text):
        return top["permalink"]
    return None


def reply(page, permalink, text, log):
    """지정한 글(permalink)에 댓글 1개. 대표님이 직접 부를 때·first_comment 모드에서만."""
    page.goto(permalink, wait_until="domcontentloaded")
    time.sleep(5)
    if not _click_text(page, ["답글", "댓글", "Reply"]):
        raise RuntimeError("댓글 버튼을 못 찾음")
    box = _composer(page)
    if box is None:
        raise RuntimeError("댓글 작성창이 뜨지 않음")
    box.click()
    type_lines(page, text)
    time.sleep(1.5)
    dlg = page.locator("[role=dialog]").last
    if not _click_text(page, POST_TEXTS, scope=dlg):
        raise RuntimeError("댓글 게시 버튼을 못 찾음")
    time.sleep(6)
    return shot(page, "threads_reply")
