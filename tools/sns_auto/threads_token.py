#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""쓰레드 토큰 발급·갱신 — 대표님 1분 설정용
   py -3 threads_token.py                     (앱 ID → 앱 시크릿 → code 순서로 물어봄)
   py -3 threads_token.py --code "복사한코드"
   py -3 threads_token.py --refresh
앱 시크릿은 키보드 입력으로만 받고 어디에도 저장하지 않는다. 화면 표시는 mask() 만.
"""
import argparse, datetime, getpass, json, os, sys, urllib.error, urllib.parse, urllib.request
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

BASE = "https://graph.threads.net"
ENV = Path(__file__).resolve().parent / ".env.local"
_SECRETS: list = []


def mask(t):
    return (t[:6] + "…" + t[-4:]) if t and len(t) > 12 else "(없음)"


def scrub(s):
    s = str(s)
    for v in _SECRETS:
        if v and len(v) > 4:
            s = s.replace(v, mask(v))
    return s


def get_json(url):
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        print(scrub(f"[실패] HTTP {e.code} {e.read().decode('utf-8', 'replace')[:300]}"))
        sys.exit(1)
    except urllib.error.URLError as e:
        print(scrub(f"[실패] 연결: {e.reason}"))
        sys.exit(1)


def save_env(pairs: dict):
    lines = ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []
    out = []
    for raw in lines:
        k = raw.split("=", 1)[0].strip()
        out.append(raw if k not in pairs else f"{k}={pairs[k]}")
    have = {l.split("=", 1)[0].strip() for l in out if "=" in l}
    for k, v in pairs.items():
        if k not in have:
            out.append(f"{k}={v}")
    tmp = ENV.with_suffix(".tmp")
    tmp.write_text("\n".join(out) + "\n", encoding="utf-8")
    os.replace(tmp, ENV)


def clean_code(c: str) -> str:
    """주소창 통째로 붙여 넣어도 code 값만 뽑는다. 끝의 '#_' 도 뗀다."""
    c = c.strip().strip('"').strip("'")
    if "code=" in c:
        c = urllib.parse.parse_qs(urllib.parse.urlsplit(c).query or c.split("?", 1)[-1]).get("code", [c])[0]
    return c.split("#", 1)[0].strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--code", help="승인 화면 주소창의 code= 값")
    ap.add_argument("--redirect-uri", default="https://localhost/")
    ap.add_argument("--refresh", action="store_true")
    a = ap.parse_args()

    if a.refresh:
        cur = {}
        for raw in (ENV.read_text(encoding="utf-8-sig").splitlines() if ENV.exists() else []):
            if "=" in raw and not raw.strip().startswith("#"):
                k, v = raw.split("=", 1)
                cur[k.strip()] = v.strip().strip('"').strip("'")
        tok = cur.get("THREADS_ACCESS_TOKEN", "")
        if not tok:
            print("[실패] .env.local 에 THREADS_ACCESS_TOKEN 이 없습니다.")
            return 1
        _SECRETS.append(tok)
        url = (f"{BASE}/refresh_access_token?" + urllib.parse.urlencode(
            {"grant_type": "th_refresh_token", "access_token": tok}))
        r = get_json(url)
        _SECRETS.append(r["access_token"])
        save_env({"THREADS_ACCESS_TOKEN": r["access_token"],
                  "THREADS_TOKEN_ISSUED": f"{datetime.date.today():%Y-%m-%d}"})
        print(f"[OK] 갱신 완료 {mask(r['access_token'])} · 앞으로 60일")
        return 0

    app_id = input("Meta 앱 ID(App ID)를 붙여넣고 Enter: ").strip()
    app_secret = getpass.getpass("Meta 앱 시크릿(App secret)을 붙여넣고 Enter (화면에 안 보입니다): ").strip()
    if not app_id or not app_secret:
        print("[실패] 앱 ID/시크릿이 비었습니다.")
        return 1
    _SECRETS.append(app_secret)
    code = a.code or input("주소창의 code 값(또는 주소 전체)을 붙여넣고 Enter: ")
    code = clean_code(code)
    if not code:
        print("[실패] code 가 비었습니다.")
        return 1
    _SECRETS.append(code)

    # 1) code → 단기 토큰
    body = urllib.parse.urlencode({"client_id": app_id, "client_secret": app_secret,
                                   "grant_type": "authorization_code",
                                   "redirect_uri": a.redirect_uri, "code": code}).encode()
    req = urllib.request.Request(f"{BASE}/oauth/access_token", data=body, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            short = json.loads(r.read().decode("utf-8"))["access_token"]
    except urllib.error.HTTPError as e:
        print(scrub(f"[실패] 코드 교환 HTTP {e.code} {e.read().decode('utf-8', 'replace')[:300]}"))
        print("→ 코드는 한 번만 쓸 수 있고 10분 안에 써야 합니다. 승인 화면을 다시 열어 새 코드를 받으세요.")
        return 1
    except urllib.error.URLError as e:
        print(f"[실패] 연결: {e.reason}")
        return 1
    _SECRETS.append(short)
    print(f"[1/3] 단기 토큰 {mask(short)}")

    # 2) 단기 → 장기(60일)
    url = (f"{BASE}/access_token?" + urllib.parse.urlencode(
        {"grant_type": "th_exchange_token", "client_secret": app_secret, "access_token": short}))
    long_tok = get_json(url)["access_token"]
    _SECRETS.append(long_tok)
    print(f"[2/3] 장기 토큰 {mask(long_tok)} · 60일")

    # 3) 내 Threads 사용자 ID
    me = get_json(f"{BASE}/v1.0/me?" + urllib.parse.urlencode(
        {"fields": "id,username", "access_token": long_tok}))
    print(f"[3/3] 계정 @{me.get('username')} · id={me.get('id')}")

    save_env({"THREADS_ACCESS_TOKEN": long_tok, "THREADS_USER_ID": str(me["id"]),
              "THREADS_TOKEN_ISSUED": f"{datetime.date.today():%Y-%m-%d}"})
    print("[OK] .env.local 저장 완료. 이제 --dry-run 으로 확인하세요.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
