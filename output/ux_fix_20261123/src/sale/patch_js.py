import io, os, re, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8', newline='').read()
CRLF = chr(13) + chr(10) in s
s = s.replace(chr(13) + chr(10), chr(10))
new = io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'new_render.js'), encoding='utf-8').read()

a = s.index("  var state = { cat:'food', filter:'all', sel:{} };")
b = s.index("  function selected(){")
s = s[:a] + new + s[b:]


def rep(x, y):
    global s
    assert s.count(x) == 1, (x[:70], s.count(x)); s = s.replace(x, y)


# 발주서: 정가 합계 → 특가 합계
rep("""    var total = 0, save = 0, count = 0;""", """    var total = 0, save = 0, count = 0, orgTotal = 0, noOrg = 0;""")
rep("""        if (typeof o.o === 'number' && o.o > p) save += (o.o - p) * x.qty;
        lines.push(' · ' + x.g.item + ' × ' + x.qty + ' — ' + won(amount));""",
    """        if (typeof o.o === 'number' && o.o > p) { save += (o.o - p) * x.qty; orgTotal += o.o * x.qty; }
        else { orgTotal += amount; noOrg++; }
        lines.push(' · ' + x.g.item + ' × ' + x.qty + ' — ' + won(amount) +
                   ((typeof o.o === 'number' && o.o > p) ? ' (정가 ' + won(o.o * x.qty) + ', −' + Math.round((1 - p / o.o) * 100) + '%)' : ' (특가)'));""")
rep("""    lines.push('총 ' + count + '개 · 예상 ' + won(total) + (save ? ' (정가 대비 ' + won(save) + ' 아낌)' : ''));""",
    """    lines.push('정가 합계 ' + won(orgTotal) + ' → 특가 합계 ' + won(total) + (save ? ' (' + won(save) + ' 아낌)' : ''));
    if (noOrg) lines.push('※ 정가가 확인 안 된 ' + noOrg + '개 품목은 정가 합계에 특가 그대로 넣었습니다.');
    lines.push('총 ' + count + '개 · 예상 ' + won(total));""")

# CSS
css = """
/* ---------- (160번) 정가→특가 · 도매 특가 블록 ---------- */
.tabs button b small{font-size:10px;font-weight:800;opacity:.8}
.row .st{display:none}
.row .org{font-size:10.5px;font-weight:700;color:#8FA0B8;line-height:1.2}
.row .org s{color:#8FA0B8;text-decoration-thickness:1.5px}
.row .pr{display:flex;align-items:center;flex-wrap:wrap;gap:5px;white-space:normal}
.row .pr .now{font-size:16px;font-weight:900;color:#FF8A2B;letter-spacing:-.4px}
.row .pr .pct{font-size:10.5px;font-weight:900;color:#fff;background:#E5484D;border-radius:999px;padding:2px 6px}
.row .pr .spc{font-size:9.5px;font-weight:900;color:#20180A;background:#FFA24D;border-radius:999px;padding:2px 6px}
.row .pr small{font-size:9.5px;font-weight:700;color:var(--gray)}
.row .pr .best{margin-left:0}
.store{font-size:9px;color:#6F809B;margin-top:2px;word-break:break-all}
.store b{color:#B9C6D8;font-weight:800}
.gh .tg.wh{color:#fff;background:linear-gradient(90deg,#2F6FED,#4C8DFF)}
.gh .tg.dd{color:#fff;background:linear-gradient(90deg,#E5484D,#FF6B6B)}
.whb{margin-top:14px;border:1px solid rgba(255,107,0,.55);border-radius:17px;padding:12px 10px 10px;
  background:linear-gradient(180deg,rgba(255,107,0,.13),rgba(255,255,255,.015) 140px)}
.whh b{display:block;font-size:16px;font-weight:900;letter-spacing:-.5px}
.whh b em{font-style:normal;color:var(--or2)}
.whh span{display:block;font-size:10.5px;color:var(--ink2);margin-top:2px}
.whs{margin-top:10px}
.whsh{display:flex;align-items:baseline;gap:7px;margin:0 2px}
.whsh b{font-size:12.5px;font-weight:900;color:#fff}
.whsh b small{font-size:10.5px;color:var(--or2)}
.whsh span{font-size:10px;color:var(--gray)}
"""
rep("\n.toast.on{opacity:1}\n</style>", "\n.toast.on{opacity:1}\n" + css + "</style>")
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace(chr(10), chr(13) + chr(10)) if CRLF else s)
print('ok')
