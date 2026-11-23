# -*- coding: utf-8 -*-
"""스마트에디터 ONE 조판 — naver_blog_draft.py 가 쓰는 블록 렌더러(문구는 손대지 않고 서식만 입힌다).

블록 규칙(post_queue.json 의 blog.format v2):
  '■ ' 줄 → 소제목(문단 서식 '소제목' + 굵게) · format.quotes 와 글자까지 같은 줄 → 인용구 박스
  '[사진N]' → 사진 · format.hr_before 로 시작하는 소제목 바로 앞 → 구분선(글당 최대 2)
  그 외 → 본문 문단(목록·링크 줄 포함, 기호 그대로) · 끝 → 빈 문단 2 + 구분선 + '#태그' 한 줄
여백: 소제목·인용구·사진·구분선 앞뒤 빈 문단 1개, 연속 빈 문단 최대 2, 글 시작에 빈 문단 없음.

셀렉터는 2026-11-23 --probe 실측값을 상수로 고정했다(매 실행 탐색하지 않음). 에디터 개편으로
안 맞으면 `naver_blog_draft.py --probe` 덤프를 보고 SEL 만 고치면 된다.
"""
import re
import time

# ---- 2026-11-23 프로브 실측(툴바 data-name / data-value) ----
SEL = {
    "text_format": "button[data-name='text-format']",                       # 문단 서식(본문 ▾)
    "fmt_heading": "button[data-name='text-format'][data-value='sectionTitle']",  # '소제목'(=제목2 자리)
    "fmt_text": "button[data-name='text-format'][data-value='text']",
    "bold": "button[data-name='bold']",
    "quote": "button.se-document-toolbar-icon-select-button[data-name='quotation'][data-value='default']",
    "hr": "button.se-document-toolbar-icon-select-button[data-name='horizontal-line'][data-value='default']",
    "image": "button[data-name='image']",
    "line_height": "button[data-name='line-height']",
}
QUOTE_DOM = "blockquote, [class*='quotation']"
HR_DOM = "hr, [class*='horizontal']"
HR_TEXT = "──────────"
MAX_HR = 2
MAX_PHOTOS = 3
HEAD_MIN_PX = 20
HEAD_MIN_WEIGHT = 600
NOISE = ["삭제", "삭제하기", "delete", "로그아웃", "log out", "발행", "publish"]   # 서식 버튼 후보에서 제외할 글자

PHOTO_RE = re.compile(r"^\[사진(\d)\]\s*$")


# ================================================================ 계획(브라우저 없이)

def tag_line(blog):
    tags = [t for t in blog.get("tags", [])][:12]
    return " ".join("#" + t.replace(" ", "") for t in tags)


def plan_blocks(blog, with_tags=True):
    """본문 → [(종류, 값)]. 종류: para·blank·heading·quote·hr·photo·link·list·tags.
    문구는 바꾸지 않는다(소제목의 '■ ' 만 뗀다). 두 번째 값은 계획 보고서."""
    fmt = blog.get("format") or {}
    quotes = list(fmt.get("quotes") or [])
    hr_before = list(fmt.get("hr_before") or [])
    raw = []
    rep = {"headings": 0, "quotes_matched": 0, "quotes_total": len(quotes), "hrs": 0, "photos": [],
           "links": 0, "unmatched_quotes": [], "lines": 0}
    matched = set()
    for line in blog["body"].split("\n"):
        s = line.rstrip()
        if not s.strip():
            raw.append(("blank", ""))
            continue
        rep["lines"] += 1
        m = PHOTO_RE.match(s.strip())
        if m:
            raw.append(("photo", int(m.group(1))))
            rep["photos"].append(int(m.group(1)))
        elif s.startswith("■"):
            if any(s.startswith(h) for h in hr_before) and rep["hrs"] < MAX_HR:
                raw.append(("hr", ""))
                rep["hrs"] += 1
            raw.append(("heading", re.sub(r"^■\s*", "", s)))
            rep["headings"] += 1
        elif s in quotes:
            raw.append(("quote", s))
            matched.add(s)
        elif s.startswith("http"):
            raw.append(("link", s))
            rep["links"] += 1
        elif s.startswith("- ") or re.match(r"^\d+\.\s", s):
            raw.append(("list", s))
        else:
            raw.append(("para", s))
    rep["quotes_matched"] = len(matched)
    rep["unmatched_quotes"] = [q for q in quotes if q not in matched]

    # 여백 규칙 적용: 특수 블록 앞뒤 빈 문단 1개, 연속 빈 문단은 1개로(태그 앞만 2개), 시작 빈 문단 없음
    special = {"heading", "quote", "photo", "hr"}
    out = []
    for kind, val in raw:
        if kind == "blank":
            if out and out[-1][0] != "blank":
                out.append(("blank", ""))
            continue
        if kind in special and out and out[-1][0] != "blank":
            out.append(("blank", ""))
        out.append((kind, val))
        if kind in special:
            out.append(("blank", ""))
    # hr 바로 뒤 heading 사이에 빈 문단 하나는 유지(위 규칙으로 이미 1개), 끝 빈 문단 정리
    while out and out[-1][0] == "blank":
        out.pop()
    if with_tags and blog.get("tags"):
        out += [("blank", ""), ("blank", ""), ("hr", "tag"), ("tags", tag_line(blog))]
    return out, rep


def expected_lines(blog, with_tags=True):
    """에디터에 들어가야 할 '글자 있는 문단'을 순서대로(서식 외 변경 0 검사용)."""
    blocks, _ = plan_blocks(blog, with_tags)
    return [v for k, v in blocks if k in ("para", "heading", "quote", "link", "list", "tags")]


# ================================================================ 에디터 조작

def _norm(s):
    return (s or "").replace(" ", " ").replace("​", "").replace("﻿", "").strip()


def _safe_click(fr, sel, wait=0.6):
    """셀렉터로 찾은 버튼이 금지어를 품고 있으면 누르지 않는다."""
    loc = fr.locator(sel).first
    if not loc.count() or not loc.is_visible():
        return False
    txt = ((loc.text_content() or "") + " " + (loc.get_attribute("class") or "")).lower()
    if any(b in txt for b in NOISE):
        raise RuntimeError(f"서식 버튼 후보에 금지어가 섞임: {sel}")
    loc.click()
    time.sleep(wait)
    return True


def last_component_kind(fr):
    return fr.evaluate("""() => { const c = [...document.querySelectorAll('.se-component')].pop();
                                  return c ? (c.className || '') : ''; }""")


def anchor_end(page, fr):
    """맨 끝 텍스트 문단으로 커서를 옮긴다(우리는 항상 글 끝에 이어 붙인다)."""
    last = fr.locator(".se-component").last
    if "se-text" not in last_component_kind(fr) or "se-documentTitle" in last_component_kind(fr):
        page.keyboard.press("End")
        page.keyboard.press("Enter")
        time.sleep(0.3)
        last = fr.locator(".se-component").last
    last.locator(".se-text-paragraph").last.click()
    page.keyboard.press("End")


def insert_paragraph(page, line):
    """일반 문단(빈 문단 = ""). 자동 목록 변환을 피하려고 키 입력 대신 insertText 를 쓴다."""
    if line:
        page.keyboard.insert_text(line)
    page.keyboard.press("Enter")
    time.sleep(0.05)


def _make_tail(page):
    """현재 빈 문단 뒤에 빈 문단 하나를 만들어 두고 커서는 원래 문단으로(컴포넌트가 이 문단을 대신한다)."""
    page.keyboard.press("Enter")
    page.keyboard.press("ArrowUp")
    time.sleep(0.1)


def _heading_style(fr):
    """마지막 소제목 컴포넌트의 계산된 글자 크기·굵기."""
    return fr.evaluate("""() => {
      const c = [...document.querySelectorAll('.se-component.se-sectionTitle')].pop();
      if (!c) return null;
      const w = document.createTreeWalker(c, NodeFilter.SHOW_TEXT); const t = w.nextNode();
      const el = t ? t.parentElement : c; const s = getComputedStyle(el);
      return {size: parseFloat(s.fontSize), weight: parseInt(s.fontWeight, 10) || (s.fontWeight === 'bold' ? 700 : 400),
              text: (c.textContent || '').trim()};
    }""")


def _bold_on(fr):
    cls = fr.locator(SEL["bold"]).first.get_attribute("class") or ""
    return "se-is-selected" in cls or "se-is-activated" in cls or "se-is-on" in cls


def insert_heading(page, fr, text, stats):
    """사다리: ① 문단서식 '소제목' + 굵게 → 입력 ② (실패) 본문 입력 후 그 문단에 '소제목' ③ 굵게만."""
    n0 = fr.locator(".se-component.se-sectionTitle").count()
    try:
        if _safe_click(fr, SEL["text_format"]) and _safe_click(fr, SEL["fmt_heading"]):
            _safe_click(fr, SEL["bold"], 0.3)
            page.keyboard.insert_text(text)
            st = _heading_style(fr)
            ok = (fr.locator(".se-component.se-sectionTitle").count() == n0 + 1 and st
                  and _norm(st["text"]) == _norm(text))
            if ok and st["weight"] < HEAD_MIN_WEIGHT:          # 굵게가 안 먹었으면 문단 전체 선택 후 한 번 더
                page.keyboard.press("Shift+Home")
                _safe_click(fr, SEL["bold"], 0.3)
                page.keyboard.press("End")
                st = _heading_style(fr)
            if ok and st["size"] >= HEAD_MIN_PX and st["weight"] >= HEAD_MIN_WEIGHT:
                page.keyboard.press("Enter")
                time.sleep(0.3)
                if _bold_on(fr):                                 # 다음 문단으로 굵게가 넘어오지 않게
                    _safe_click(fr, SEL["bold"], 0.2)
                stats["headings"] += 1
                return "sectionTitle"
            if ok:                                               # 서식은 들어갔지만 검증 실패 → 굵게 대체로 기록
                page.keyboard.press("Enter")
                stats["heading_fallback"] += 1
                stats["log"].append(f"heading=style-check-fail({st})")
                return "sectionTitle-unverified"
    except Exception as e:
        stats["log"].append(f"heading ladder1 실패: {str(e)[:120]}")
    # ③ 굵게 대체(이미 글자가 들어갔다면 다시 넣지 않는다)
    cur = fr.evaluate("""() => { const s = getSelection(); const n = s && s.anchorNode;
                                 const p = n && (n.nodeType === 1 ? n : n.parentElement).closest('.se-text-paragraph');
                                 return p ? p.textContent : null; }""")
    if _norm(cur) != _norm(text):
        _safe_click(fr, SEL["bold"], 0.2)
        page.keyboard.insert_text(text)
        _safe_click(fr, SEL["bold"], 0.2)
    page.keyboard.press("Enter")
    stats["heading_fallback"] += 1
    stats["log"].append("heading=bold-fallback")
    return "bold-fallback"


def insert_quote(page, fr, text, stats):
    n0 = fr.locator(QUOTE_DOM).count()
    c0 = fr.locator(".se-component.se-quotation").count()
    _make_tail(page)
    try:
        if _safe_click(fr, SEL["quote"], 0.8) and fr.locator(".se-component.se-quotation").count() == c0 + 1:
            page.keyboard.insert_text(text)
            time.sleep(0.2)
            anchor_end(page, fr)
            if fr.locator(QUOTE_DOM).count() > n0:
                stats["quotes"] += 1
                return "quotation"
    except Exception as e:
        stats["log"].append(f"quote 실패: {str(e)[:120]}")
    # 대체: 평문(앞뒤 빈 줄은 계획에 이미 있음)
    anchor_end(page, fr)
    insert_paragraph(page, text)
    stats["log"].append("quote=fallback-plain")
    return "fallback-plain"


def insert_hr(page, fr, stats):
    c0 = fr.locator(".se-component.se-horizontalLine").count()
    _make_tail(page)
    try:
        if _safe_click(fr, SEL["hr"], 0.8) and fr.locator(".se-component.se-horizontalLine").count() == c0 + 1:
            anchor_end(page, fr)
            stats["hrs"] += 1
            return "hr"
    except Exception as e:
        stats["log"].append(f"hr 실패: {str(e)[:120]}")
    anchor_end(page, fr)
    insert_paragraph(page, HR_TEXT)
    stats["log"].append("hr=text-fallback")
    return "text-fallback"


def insert_photo(page, fr, path, uploader, stats):
    """기존 upload_photo 래퍼. 성공 후 6초 대기 → 끝 문단으로."""
    c0 = fr.locator(".se-component.se-image").count()
    _make_tail(page)
    how = uploader(page, fr, path)
    time.sleep(6)
    for _ in range(6):
        if fr.locator(".se-component.se-image").count() > c0:
            break
        time.sleep(1.5)
    ok = fr.locator(".se-component.se-image").count() > c0
    anchor_end(page, fr)
    if ok:
        stats["photos"] += 1
    return how if ok else None


def apply_line_height(fr, stats):
    """줄간격: 기본이 이미 180%(넓음)라 바꾸지 않는다 — 버튼 존재만 기록(치명 아님)."""
    stats["line_height"] = "기본 180% 유지" if fr.locator(SEL["line_height"]).count() else "버튼 없음(건너뜀)"


def render(page, fr, blocks, photo_path, uploader, log, budget=150):
    """블록 계획대로 입력한다. budget 초를 넘기면 남은 블록은 서식 없이 문구만 넣고 format_timeout 표시."""
    stats = {"headings": 0, "heading_fallback": 0, "quotes": 0, "hrs": 0, "photos": 0, "photo_fail": [],
             "format_timeout": False, "log": []}
    t0 = time.time()
    apply_line_height(fr, stats)
    for kind, val in blocks:
        plain = time.time() - t0 > budget
        if plain and not stats["format_timeout"]:
            stats["format_timeout"] = True
            log(f"  [주의] 조판 {budget}초 초과 → 남은 블록은 문구만 입력(format_timeout)")
        if kind in ("para", "list", "tags"):
            insert_paragraph(page, val)
        elif kind == "blank":
            insert_paragraph(page, "")
        elif kind == "link":
            insert_paragraph(page, val)
            time.sleep(2.5)              # 자동 링크 처리 중 커서가 튀는 것 방지
            anchor_end(page, fr)
        elif kind == "heading":
            if plain:
                insert_paragraph(page, val)
            else:
                insert_heading(page, fr, val, stats)
        elif kind == "quote":
            if plain:
                insert_paragraph(page, val)
            else:
                insert_quote(page, fr, val, stats)
        elif kind == "hr":
            if not plain:
                insert_hr(page, fr, stats)
        elif kind == "photo":
            p = photo_path(val)
            if not p or not p.exists():
                stats["photo_fail"].append(val)
                log(f"  [주의] [사진{val}] 파일 없음")
                continue
            try:
                how = insert_photo(page, fr, p, uploader, stats)
                if how:
                    log(f"  사진{val} 업로드({how}) {p.name}")
                else:
                    stats["photo_fail"].append(val)
                    log(f"  [주의] 사진{val} 삽입 확인 실패({p.name})")
            except Exception as e:
                stats["photo_fail"].append(val)
                log(f"  [주의] 사진{val} 업로드 실패({p.name}): {str(e)[:160]}")
                try:
                    anchor_end(page, fr)
                except Exception:
                    pass
    stats["seconds"] = round(time.time() - t0, 1)
    return stats


# ================================================================ 저장 후 실측

MEASURE_JS = r"""() => {
  const norm = s => (s || '').replace(/ /g, ' ').replace(/[​﻿]/g, '').trim();
  const comps = [...document.querySelectorAll('.se-component')].filter(c => !c.classList.contains('se-documentTitle'));
  const kind = c => ['se-sectionTitle','se-quotation','se-horizontalLine','se-image','se-text','se-oglink']
                      .find(k => c.classList.contains(k)) || (c.className || '').split(' ')[1] || '?';
  const paras = c => [...c.querySelectorAll('.se-text-paragraph')]
                      .filter(p => !p.querySelector('.se-placeholder') && !p.closest('.se-caption, .se-module-text.__se-unit.se-caption'))
                      .map(p => norm(p.textContent));
  const out = {components: [], lines: [], headings: [], quotes: [], hrs: 0, photos: 0, spacing_bad: []};
  comps.forEach((c, i) => {
    const k = kind(c);
    out.components.push(k);
    if (k === 'se-image') { out.photos++; return; }
    if (k === 'se-horizontalLine') { out.hrs++; }
    const ps = paras(c);
    if (k === 'se-sectionTitle') {
      const w = document.createTreeWalker(c, NodeFilter.SHOW_TEXT); const t = w.nextNode();
      const s = getComputedStyle(t ? t.parentElement : c);
      out.headings.push({text: norm(c.textContent), size: parseFloat(s.fontSize), weight: parseInt(s.fontWeight, 10) || 400});
    }
    if (k === 'se-quotation') out.quotes.push(ps[0] || '');
    if (['se-sectionTitle', 'se-quotation', 'se-horizontalLine', 'se-image'].includes(k)) {
      const prev = comps[i - 1], next = comps[i + 1];
      const lastP = prev ? paras(prev).slice(-1)[0] : null, firstP = next ? paras(next)[0] : null;
      const prevOk = !prev || (kind(prev) === 'se-text' && lastP === '');
      // 태그 블록(빈 문단 2 → 구분선 → #태그 줄)은 구분선 바로 뒤가 태그 줄이 정상
      const nextOk = !next || (kind(next) === 'se-text' && (firstP === '' || (k === 'se-horizontalLine' && (firstP || '').startsWith('#'))));
      if (!prevOk || !nextOk) out.spacing_bad.push(k + '#' + i + (prevOk ? '' : ' 앞') + (nextOk ? '' : ' 뒤'));
    }
    ps.forEach(t => { if (t) out.lines.push(t); });
  });
  return out;
}"""


def measure(fr):
    return fr.evaluate(MEASURE_JS)


def judge(blog, m, with_tags=True):
    """§6 합격 기준 판정. (ok, 사유 목록)"""
    why = []
    hs = m["headings"]
    if len(hs) < 6:
        why.append(f"소제목 {len(hs)}개(<6)")
    weak = [h["text"][:12] for h in hs if h["size"] < HEAD_MIN_PX or h["weight"] < HEAD_MIN_WEIGHT]
    if weak:
        why.append(f"소제목 서식 약함 {weak}")
    quotes = (blog.get("format") or {}).get("quotes") or []
    if len(m["quotes"]) != 2 or sorted(m["quotes"]) != sorted(quotes):
        why.append(f"인용구 {len(m['quotes'])}개/문장 불일치")
    hr_need = 1 + (1 if with_tags else 0)
    if m["hrs"] < hr_need:
        why.append(f"구분선 {m['hrs']}개")
    if not (2 <= m["photos"] <= 3):
        why.append(f"사진 {m['photos']}장")
    exp = expected_lines(blog, with_tags)
    if m["lines"] != [_norm(x) for x in exp]:
        diff = next((i for i, (a, b) in enumerate(zip(m["lines"], exp)) if a != _norm(b)), min(len(m["lines"]), len(exp)))
        why.append(f"문구 불일치(문단 {diff}: 실제 {m['lines'][diff][:20] if diff < len(m['lines']) else '-'!r} / "
                   f"기대 {exp[diff][:20] if diff < len(exp) else '-'!r}, 줄 수 {len(m['lines'])}/{len(exp)})")
    if with_tags:
        tl = m["lines"][-1] if m["lines"] else ""
        tags = tl.split()
        if not tl.startswith("#") or len(tags) != 12 or len(set(tags)) != 12:
            why.append(f"태그 줄 이상({len(tags)}개)")
    if m["spacing_bad"]:
        why.append(f"여백 부족 {m['spacing_bad'][:4]}")
    return (not why), why
