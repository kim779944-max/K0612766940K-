import io, sys
p = sys.argv[1]
s = io.open(p, encoding='utf-8', newline='').read()
CRLF = '\r\n' in s
s = s.replace('\r\n', '\n')


def rep(a, b, n=1):
    global s
    assert s.count(a) == n, (a[:80], s.count(a)); s = s.replace(a, b)


rep('그림 16장 · 10문항 · 무료.">', '그림 16장 · 6문항 · 무료.">')
rep('<small>v2.0 · 그림 16 · 10문항</small>', '<small>v3 · 그림 16 · <span class="nq">6</span>문항</small>')
rep('그림 16장 · 10문항 · 무료</span>', '그림 16장 · <span class="nq">6</span>문항 · 무료</span>')
rep('id="btnStart" type="button" disabled>시작하기 — 10문항</button>', 'id="btnStart" type="button" disabled>시작하기 — 6문항</button>')
rep('<div class="pnum" id="pnum">1 / 10</div><div class="bar"><i id="pbar" style="width:10%"></i></div>',
    '<div class="pnum" id="pnum">1 / 6</div><div class="bar"><i id="pbar" style="width:17%"></i></div>')
rep('''    <div id="ogrid"></div>
    <div class="qfoot">
      <button class="btn ghost sm" id="btnPrev" type="button">← 이전 문항</button>
    </div>''', '''    <div class="qmulti" id="qmulti">해당하는 것을 <b>모두</b> 고르세요 · 1~3개 <span id="qsel">0 / 3</span></div>
    <div id="ogrid"></div>
    <div class="qmax" id="qmax" aria-live="polite"></div>
    <div class="qfoot">
      <button class="btn main" id="btnNext" type="button" disabled>다음 →</button>
      <button class="btn ghost sm" id="btnPrev" type="button">← 이전 문항</button>
    </div>''')
rep('나도 해 보기 — 그림 고르고 10문항</button>', '나도 해 보기 — 그림 고르고 <span class="nq">6</span>문항</button>')
rep("? '시작하기 — 10문항' : '그림을 골라야 시작합니다';", "? '시작하기 — ' + APP.TOTAL + '문항' : '그림을 골라야 시작합니다';")
rep("evi.appendChild(el('span', null, '10문항 교차'));", "evi.appendChild(el('span', null, (res.total || APP.TOTAL) + '문항 · 고른 보기 ' + res.answers + '개'));")
rep("res.lead * 2 >= res.answers ? res.lead + '문항 같은 결' : '두 결이 함께 보임'", "res.lead * 2 >= res.answers ? '보기 ' + res.lead + '개 같은 결' : '두 결이 함께 보임'")
rep("x.fillText('그림 16 · 10문항 · ' + r.ctx.dateKo, 72, 152);", "x.fillText('그림 16 · ' + (r.total || APP.TOTAL) + '문항 · ' + r.ctx.dateKo, 72, 152);")
rep("x.fillText('그림 16장 · 10문항 스무고개', 72, 1216);", "x.fillText('그림 16장 · ' + (r.total || APP.TOTAL) + '문항 · 복수 체크', 72, 1216);")
rep("+ '— 그림 16장 · 10문항 1분: ' + SHOP;", "+ '— 그림 16장 · ' + APP.TOTAL + '문항 1분: ' + SHOP;")
rep("+ '② ' + v.read + '\\n'", "+ '② ' + (v.inner || v.read) + '\\n'")
# 저장 이미지: 해설(read) 대신 단정 문장, ①과 같은 줄은 한 번만
rep("""    y = wrapText(x, v.read, 72, y, 936, 44) + 30;""", """    y = wrapText(x, v.inner || v.read, 72, y, 936, 44) + 30;""")
rep("""    y = wrapText(x, v.declare, 72, y, 936, 42) + 16;""", """    if (v.declare !== v.teaser) y = wrapText(x, v.declare, 72, y, 936, 42) + 16;""")

# CSS — 복수 체크
rep(""".qfoot{display:grid;grid-template-columns:1fr;gap:8px;margin-top:16px}""",
    """.qfoot{display:grid;grid-template-columns:1fr;gap:8px;margin-top:16px}
/* 153번: 복수 체크(1~3개) · [다음]으로만 진행 */
.qmulti{font-size:12px;font-weight:800;color:#C9D6E6;margin:10px 0 0;display:flex;align-items:center;gap:6px}
.qmulti b{color:var(--or2)}
.qmulti span{margin-left:auto;font-size:11px;font-weight:900;color:var(--on);background:var(--or2);border-radius:999px;padding:2px 8px}
.opt{min-height:44px}
.opt .ck{position:absolute;right:7px;top:7px;width:24px;height:24px;border-radius:7px;background:rgba(10,18,36,.85);
  border:1.5px solid rgba(255,255,255,.45);display:grid;place-items:center;font-size:14px;font-weight:900;color:transparent}
.opt.on .ck{background:var(--or);border-color:var(--or);color:var(--on)}
.opt.on{border-width:2px}
.opt.lock{opacity:.45}
.qmax{min-height:18px;font-size:11.5px;font-weight:800;color:#FFB27A;margin-top:8px;text-align:center}
#btnNext:disabled{opacity:.45;box-shadow:none}""")

# 렌더 — 체크 표시
rep("""      b.appendChild(el('span', 'no', String(i + 1)));""",
    """      b.appendChild(el('span', 'no', String(i + 1)));
      b.appendChild(el('span', 'ck', '✓'));
      b.setAttribute('role', 'checkbox'); b.setAttribute('aria-checked', 'false');""")
rep("""    $('#btnPrev').textContent = lv === 1 ? '← 처음 그림으로' : '← 이전 문항';
    window.scrollTo(0, 0);
  }""", """    $('#btnPrev').textContent = lv === 1 ? '← 처음 그림으로' : '← 이전 문항';
    $('#btnNext').textContent = lv >= APP.TOTAL ? '결과 보기 →' : '다음 →';
    /* 되돌아온 문항이면 고른 것 그대로 */
    var had = ST.picks[lv - 1];
    ST.sel = (had && had.map) ? had.map(function(k){ return k.idx; }) : (had ? [had.idx] : []);
    ST.unpick = false;
    paintSel();
    window.scrollTo(0, 0);
  }

  /* 153번: 1~3개 복수 체크 — 0개면 [다음] 잠금, 3개면 나머지 잠금 + 안내 */
  var MAXSEL = 3;
  function paintSel(){
    var n = ST.sel.length;
    [].forEach.call(document.querySelectorAll('#ogrid .opt'), function(b){
      var on = ST.sel.indexOf(+b.dataset.idx) !== -1;
      b.classList.toggle('on', on); b.setAttribute('aria-checked', on ? 'true' : 'false');
      b.classList.toggle('lock', !on && n >= MAXSEL);
    });
    $('#qsel').textContent = n + ' / ' + MAXSEL;
    $('#btnNext').disabled = n === 0;
    if (n < MAXSEL) $('#qmax').textContent = '';
  }""")
rep("""  function tapOpt(o, idx, node){
    if (ST.locked) return;
    ST.taps++;
    var prev = ST.picks[ST.lv - 1];
    var repick = !!(prev && prev.idx !== idx);
    ST.picks[ST.lv - 1] = {
      lv:ST.lv, idx:idx, l:o.l, t:o.t, t2:o.t2, p:o.p,
      setKey: 'L' + ST.lv
    };
    ST.hesit[ST.lv - 1] = {
      repick: repick, slow: (Date.now() - ST.qStart) > 9000
    };
    ST.picks = ST.picks.slice(0, ST.lv);
    ST.hesit = ST.hesit.slice(0, ST.lv);
    ST.locked = true;
    [].forEach.call(document.querySelectorAll('#ogrid .opt'), function(n){ n.classList.remove('on'); });
    node.classList.add('on');
    setTimeout(function(){
      if (ST.lv >= APP.TOTAL){ toCalc(); return; }
      ST.lv += 1; renderQ();
    }, 300);
  }""", """  function tapOpt(o, idx, node){
    if (ST.locked) return;
    ST.taps++;
    var at = ST.sel.indexOf(idx);
    if (at !== -1){ ST.sel.splice(at, 1); ST.unpick = true; }
    else if (ST.sel.length >= MAXSEL){ $('#qmax').textContent = '최대 3개까지 고를 수 있습니다 — 하나를 빼고 고르세요'; return; }
    else ST.sel.push(idx);
    paintSel();
  }

  /* [다음] — 고른 보기 전부를 이 문항의 답(배열)으로 저장하고 넘어간다 (자동 진행 없음) */
  $('#btnNext').addEventListener('click', function(){
    if (ST.locked || !ST.sel.length) return;
    var set = ST.q, lv = ST.lv;
    ST.picks[lv - 1] = ST.sel.slice().sort(function(a, b){ return a - b; }).map(function(i){
      var o = set.opts[i];
      return { lv:lv, idx:i, l:o.l, t:o.t, t2:o.t2, p:o.p, s:o.s || '', setKey:'L' + lv };
    });
    ST.hesit[lv - 1] = { repick: !!ST.unpick, slow: (Date.now() - ST.qStart) > 15000 };
    ST.picks = ST.picks.slice(0, lv);
    ST.hesit = ST.hesit.slice(0, lv);
    if (lv >= APP.TOTAL){ ST.locked = true; toCalc(); return; }
    ST.lv += 1; renderQ();
  });""")
rep("""    if (ST.lv === 1){ show('sIntro'); return; }
    ST.lv -= 1;
    ST.picks = ST.picks.slice(0, ST.lv - 1);
    ST.hesit = ST.hesit.slice(0, ST.lv - 1);
    renderQ();""", """    if (ST.lv === 1){ show('sIntro'); return; }
    ST.lv -= 1;
    ST.picks = ST.picks.slice(0, ST.lv);          /* 돌아간 문항의 고른 것은 남겨 다시 보여 준다 */
    ST.hesit = ST.hesit.slice(0, ST.lv - 1);
    renderQ();""")
rep("""      var rep = window.LINT.checkResult(body, ST.picks, ST.pics);""",
    """      var rep = window.LINT.checkResult(body, APP.flatPicks(ST.picks), ST.pics);""")
# 스크립트
rep('<script src="js/data.pool.js?v=3"></script>', '<script src="js/data.pool.js?v=3"></script>\n<script src="js/data.pool.v3.js?v=1"></script>\n<script src="js/data.voice.js?v=1"></script>')
rep('<script src="js/engine.js?v=8"></script>', '<script src="js/engine.js?v=9"></script>')
rep('<script src="js/data.subs.js?v=7"></script>', '<script src="js/data.subs.js?v=8"></script>')
# 문항 수 표기(심화면 10)
rep("""  today();
  paintPics();""", """  [].forEach.call(document.querySelectorAll('.nq'), function(n){ n.textContent = String(APP.TOTAL); });
  ST.sel = [];
  today();
  paintPics();""")
rep('<script src="../helper.js?v=20261122a"></script>', '<script src="../helper.js?v=20261123a"></script>')
io.open(p, 'w', encoding='utf-8', newline='').write(s.replace('\n', '\r\n') if CRLF else s)
print('ok')
