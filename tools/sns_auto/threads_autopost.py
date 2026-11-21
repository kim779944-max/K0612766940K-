#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""KTS 쓰레드 자동 포스팅 — 하루 1건 (Meta Threads API v1.0)
   python threads_autopost.py [--list|--dry-run|--live|--refresh|--resolve]
   인자 없음 = --live 와 같음(단, SNS_DAILY_ENABLED=0 이면 아무것도 하지 않음)

종료 코드: 0 정상/할 일 없음 · 1 오류 · 2 확인 필요(중복 위험) · 3 설정 없음 · 4 한도 초과
"""
import argparse, datetime, json, os, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

BASE = "https://graph.threads.net/v1.0"
ROOT = Path(__file__).resolve().parent
QUEUE = ROOT / "post_queue.json"
ENV = ROOT / ".env.local"
LOGDIR = ROOT / "logs"
MAX_TEXT = 500             # Threads 본문 한도(넘으면 자르지 않고 실패)
MAX_LINES = 3              # 우리 규칙: 2~3줄 훅
IMAGE_WAIT_TRIES = 5       # 1분 간격 5회 = 최대 5분

_SECRETS: list = []        # 로그에서 가릴 값들(토큰 등)


class LimitError(RuntimeError):
    """게시 한도 초과(종료 4)."""


def mask(t: str) -> str:
    if not t:
        return "(없음)"
    return t[:6] + "…" + t[-4:] if len(t) > 12 else "…"


def scrub(s: str) -> str:
    """문자열 안의 비밀값을 mask() 로 바꾼다. 로그·예외 메시지는 반드시 이걸 거친다."""
    s = str(s)
    for v in _SECRETS:
        if v and len(v) > 4:
            s = s.replace(v, mask(v))
    return s


def log(msg: str) -> None:
    LOGDIR.mkdir(exist_ok=True)
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {scrub(msg)}"
    print(line)
    with open(LOGDIR / f"threads_{datetime.date.today():%Y-%m-%d}.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_env() -> dict:
    cfg = {}
    if ENV.exists():
        for raw in ENV.read_text(encoding="utf-8-sig").splitlines():
            s = raw.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            k, v = s.split("=", 1)
            cfg[k.strip()] = v.strip().strip('"').strip("'")
    for k in ("THREADS_ACCESS_TOKEN", "THREADS_USER_ID"):
        if not cfg.get(k) and os.environ.get(k):
            cfg[k] = os.environ[k]
    if cfg.get("THREADS_ACCESS_TOKEN"):
        _SECRETS.append(cfg["THREADS_ACCESS_TOKEN"])
    return cfg


def save_env_key(key: str, value: str) -> None:
    """기존 .env.local 의 다른 줄은 건드리지 않고 key 한 줄만 바꾼다."""
    lines = ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []
    out, done = [], False
    for raw in lines:
        if raw.strip().startswith(key + "="):
            out.append(f"{key}={value}")
            done = True
        else:
            out.append(raw)
    if not done:
        out.append(f"{key}={value}")
    tmp = ENV.with_suffix(".tmp")
    tmp.write_text("\n".join(out) + "\n", encoding="utf-8")
    os.replace(tmp, ENV)


def _http_error(e: urllib.error.HTTPError) -> RuntimeError:
    body = e.read().decode("utf-8", "replace")[:400]
    msg = scrub(f"HTTP {e.code} {body}")
    low = body.lower()
    if e.code == 429 or "limit" in low or "throttl" in low:
        return LimitError(msg)
    return RuntimeError(msg)


def api_get(path: str, params: dict) -> dict:
    url = f"{BASE}/{path}?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise _http_error(e) from None
    except urllib.error.URLError as e:
        raise RuntimeError(scrub(f"연결 실패: {e.reason}")) from None


def api_post(path: str, data: dict) -> dict:
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(f"{BASE}/{path}", data=body, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise _http_error(e) from None
    except urllib.error.URLError as e:
        raise RuntimeError(scrub(f"연결 실패: {e.reason}")) from None


def url_ok(url: str) -> bool:
    try:
        req = urllib.request.Request(url, method="HEAD")
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status == 200 and r.headers.get("Content-Type", "").startswith("image/")
    except Exception:
        return False


def load_queue() -> dict:
    return json.loads(QUEUE.read_text(encoding="utf-8"))


def save_queue(q: dict) -> None:
    tmp = QUEUE.with_suffix(".tmp")
    tmp.write_text(json.dumps(q, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, QUEUE)


def ordered(q: dict) -> list:
    return sorted(q.get("items", []), key=lambda it: it.get("order", 10 ** 6))


def blocking_item(q: dict):
    """publishing(중간에 죽음) 또는 error(실패) 항목이 있으면 그걸 돌려준다 → 사람 확인 전에는 진행 금지."""
    for it in ordered(q):
        if it.get("status") in ("publishing", "error"):
            return it
    return None


def pick_item(q: dict):
    for it in ordered(q):
        if it.get("status", "pending") == "pending":
            return it
    return None


def check_text(text: str) -> list:
    """본문 규칙 위반 목록(빈 목록이면 통과)."""
    errs = []
    if len(text) > MAX_TEXT:
        errs.append(f"본문이 {len(text)}자로 한도({MAX_TEXT})를 넘습니다. 문구를 줄여야 합니다")
    if "http" in text.lower() or "www." in text.lower():
        errs.append("본문에 링크가 있습니다. 링크는 첫 댓글에만 넣습니다")
    n = len([l for l in text.split("\n") if l.strip()])
    if n > MAX_LINES:
        errs.append(f"본문이 {n}줄입니다(규칙: {MAX_LINES}줄 이내)")
    return errs


def create_container(uid, token, media_type, text, image_url=None, reply_to=None) -> str:
    data = {"media_type": media_type, "text": text, "access_token": token}
    if image_url:
        data["image_url"] = image_url
    if reply_to:
        data["reply_to_id"] = reply_to
    return api_post(f"{uid}/threads", data)["id"]


def wait_ready(cid: str, token: str) -> None:
    for i in range(IMAGE_WAIT_TRIES):
        time.sleep(60 if i else 30)
        st = api_get(cid, {"fields": "status,error_message", "access_token": token})
        status = st.get("status")
        if status == "FINISHED":
            return
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"컨테이너 {status}: {st.get('error_message', '')}")
        log(f"  컨테이너 준비 중… ({status}, {i + 1}/{IMAGE_WAIT_TRIES})")
    raise RuntimeError("컨테이너 준비 시간 초과(5분)")


def publish(uid: str, token: str, cid: str) -> str:
    return api_post(f"{uid}/threads_publish", {"creation_id": cid, "access_token": token})["id"]


def do_refresh(cfg: dict) -> str:
    r = api_get("refresh_access_token", {"grant_type": "th_refresh_token",
                                         "access_token": cfg["THREADS_ACCESS_TOKEN"]})
    new = r["access_token"]
    _SECRETS.append(new)
    save_env_key("THREADS_ACCESS_TOKEN", new)
    save_env_key("THREADS_TOKEN_ISSUED", f"{datetime.date.today():%Y-%m-%d}")
    cfg["THREADS_ACCESS_TOKEN"] = new
    log(f"토큰 갱신 완료 ({mask(new)}, {r.get('expires_in')}초)")
    return new


def maybe_refresh(cfg: dict) -> None:
    issued = cfg.get("THREADS_TOKEN_ISSUED", "")
    if not issued or not cfg.get("THREADS_ACCESS_TOKEN"):
        return
    try:
        age = (datetime.date.today() - datetime.date.fromisoformat(issued)).days
    except ValueError:
        log(f"[주의] THREADS_TOKEN_ISSUED 형식 오류: {issued}")
        return
    if age < 45:
        return
    log(f"토큰 나이 {age}일 → 갱신 시도")
    try:
        do_refresh(cfg)
    except RuntimeError as e:
        log(f"[주의] 토큰 갱신 실패(기존 토큰으로 계속): {e}")


def main() -> int:
    ap = argparse.ArgumentParser(description="KTS 쓰레드 하루 1건 자동 게시")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--list", action="store_true", help="큐 상태 보기")
    g.add_argument("--dry-run", action="store_true", help="오늘 올릴 글을 화면에만 출력(네트워크 0건)")
    g.add_argument("--live", action="store_true", help="실제 게시")
    g.add_argument("--refresh", action="store_true", help="토큰 갱신만")
    g.add_argument("--resolve", action="store_true", help="publishing/error 항목을 사람 확인 후 pending 으로")
    a = ap.parse_args()
    scheduled = not (a.list or a.dry_run or a.live or a.refresh or a.resolve)

    cfg = load_env()

    if a.list:
        q = load_queue()
        for it in ordered(q):
            n = len(it.get("threads", {}).get("text", ""))
            log(f"{it['id']:<26} {it.get('status', 'pending'):<10} {n:>3}자  {it.get('topic', '')}")
        return 0

    if a.resolve:
        q = load_queue()
        hit = 0
        for it in q["items"]:
            if it.get("status") in ("publishing", "error"):
                log(f"[RESOLVE] {it['id']} ({it.get('status')}) → pending · 이전 오류: {it.get('error', '')}")
                it["status"] = "pending"
                it["note"] = f"{datetime.date.today()} 사람 확인 후 pending 복구"
                hit += 1
        save_queue(q)
        log(f"[RESOLVE] {hit}건 정리")
        return 0

    if a.refresh:
        if not cfg.get("THREADS_ACCESS_TOKEN"):
            log("[SKIP] 토큰 없음")
            return 3
        try:
            do_refresh(cfg)
        except RuntimeError as e:
            log(f"[실패] 토큰 갱신: {e}")
            return 1
        return 0

    q = load_queue()

    if a.dry_run:
        blk = blocking_item(q)
        if blk:
            log(f"[DRY] 주의: {blk['id']} 가 {blk.get('status')} 상태 — 실제 실행이면 종료 2(확인필요)")
        item = pick_item(q)
        if item is None:
            log("[DRY] 큐에 남은 글이 없습니다")
            return 0
        t = item["threads"]
        text = t["text"]
        log(f"[DRY] 항목 {item['id']} · 주제 {item.get('topic', '')}")
        log(f"[DRY] 본문 {len(text)}자 / 한도 {MAX_TEXT}자 · {len(text.splitlines())}줄")
        log(f"[DRY] 이미지 {t.get('image_url') or '(없음)'}  (드라이런: URL 확인 생략)")
        log(f"[DRY] 첫 댓글 {t.get('first_comment') or '(없음)'}")
        for e in check_text(text):
            log(f"[DRY] 규칙 위반: {e}")
        print("[DRY] ---- 본문 ----")
        print(text)
        print("[DRY] ---- 끝 ----")
        return 1 if check_text(text) else 0

    # ---- 여기부터 실제 실행(--live 또는 스케줄러) ----
    if cfg.get("SNS_DAILY_ENABLED", "1") == "0":
        log("[SKIP] SNS_DAILY_ENABLED=0 (비상 정지)")
        return 0
    if not cfg.get("THREADS_ACCESS_TOKEN") or not cfg.get("THREADS_USER_ID"):
        log("[SKIP] 토큰/사용자ID 없음 — threads_token.py 를 먼저 실행하세요")
        return 3

    blk = blocking_item(q)
    if blk:
        log(f"[확인필요] {blk['id']} 가 {blk.get('status')} 상태입니다. 쓰레드에서 실제로 올라갔는지 확인하고 "
            f"--resolve 로 정리한 뒤 다시 실행하세요")
        return 2

    today = f"{datetime.date.today():%Y-%m-%d}"
    if scheduled and any(str(it.get("posted_at", "")).startswith(today) for it in q["items"]):
        log("[SKIP] 오늘 이미 1건 게시했습니다(하루 1건)")
        return 0

    item = pick_item(q)
    if item is None:
        log("[SKIP] 큐에 남은 글이 없습니다")
        return 0

    text = item["threads"]["text"]
    first_comment = item["threads"].get("first_comment", "")
    image_url = item["threads"].get("image_url", "")

    errs = check_text(text)
    if errs:
        for e in errs:
            log(f"[실패] {item['id']}: {e}")
        return 1

    maybe_refresh(cfg)
    token, uid = cfg["THREADS_ACCESS_TOKEN"], cfg["THREADS_USER_ID"]

    try:
        lim = api_get(f"{uid}/threads_publishing_limit", {"fields": "quota_usage,config", "access_token": token})
        d = (lim.get("data") or [{}])[0]
        total = (d.get("config") or {}).get("quota_total")
        log(f"  게시 한도 사용 {d.get('quota_usage')}/{total}")
        if total and d.get("quota_usage", 0) >= total:
            log("[한도] 24시간 게시 한도 초과")
            return 4
    except RuntimeError as e:
        log(f"  (한도 확인 생략: {e})")

    item["status"] = "publishing"
    item["attempt_at"] = f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}"
    save_queue(q)
    log(f"[시작] {item['id']} · {len(text)}자")

    try:
        use_image = bool(image_url) and url_ok(image_url)
        if image_url and not use_image:
            log(f"[주의] 이미지 생략 — URL 응답 없음/이미지 아님 → 텍스트로만 게시: {image_url}")
        cid = create_container(uid, token, "IMAGE" if use_image else "TEXT", text,
                               image_url if use_image else None)
        log(f"  컨테이너 {cid} ({'IMAGE' if use_image else 'TEXT'})")
        if use_image:
            wait_ready(cid, token)
        post_id = publish(uid, token, cid)
        # 본문은 올라갔다 → 이 아래에서 무슨 일이 생겨도 error 로 돌리지 않는다(재게시 방지)
        item.update({"status": "posted", "posted_at": f"{datetime.datetime.now():%Y-%m-%dT%H:%M:%S}",
                     "post_id": post_id})
        save_queue(q)
        log(f"[OK] 게시 완료 post_id={post_id}")
    except LimitError as e:
        item.update({"status": "pending", "error": str(e)[:400]})
        save_queue(q)
        log(f"[한도] {e}")
        return 4
    except RuntimeError as e:
        item.update({"status": "error", "error": str(e)[:400]})
        save_queue(q)
        log(f"[실패] {e}")
        return 1

    reply_id = ""
    if first_comment:
        time.sleep(10)
        try:
            rcid = create_container(uid, token, "TEXT", first_comment, reply_to=post_id)
            time.sleep(5)
            reply_id = publish(uid, token, rcid)
            log(f"[OK] 첫 댓글 reply_id={reply_id}")
        except RuntimeError as e:
            log(f"[주의] 첫 댓글 실패(본문은 게시됨 — 댓글은 손으로 다세요): {e}")

    try:
        permalink = api_get(post_id, {"fields": "permalink", "access_token": token}).get("permalink", "")
    except RuntimeError:
        permalink = ""
    item.update({"reply_id": reply_id, "permalink": permalink})
    save_queue(q)
    log(f"[완료] {item['id']} {permalink}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
