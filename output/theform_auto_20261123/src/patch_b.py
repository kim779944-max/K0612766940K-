import io, os
OC = os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', 'oneclick')
p = os.path.join(OC, 'theform', 'index.html')
s = io.open(p, encoding='utf-8', newline='').read(); nl = '\r\n'
def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:60], s.count(old)); s = s.replace(old, new)
a = "$('#valList').addEventListener('click', e => { const b = e.target.closest('[data-sigclr]'); if (!b) return; const f = CUR.fields[+b.dataset.sigclr]; delete VALS[f.label]; saveVals(); renderInputs(); });"
blk = io.open(os.path.join(os.path.dirname(__file__), 'next_block.js'), encoding='utf-8').read().replace('\r\n', '\n').replace('\n', nl)
rep(a, a + nl + blk.rstrip())
rep("  $$('#valList canvas[data-sig]').forEach(cv => bindSig(cv, CUR.fields[+cv.dataset.sig]));" + nl + "}",
    "  $$('#valList canvas[data-sig]').forEach(cv => bindSig(cv, CUR.fields[+cv.dataset.sig]));" + nl + "  updNavPos(-1);" + nl + "}")
rep("get UNDO(){ return UNDO; }, drawEditor, runCalc, saveVals, renderInputs};",
    "get UNDO(){ return UNDO; }, drawEditor, runCalc, saveVals, renderInputs," + nl + "  autoDetectFields, runAutoDetect, nextField, prevField, navIdx, savePreset, loadPreset, myPresets, get BG(){ return BG; }, set BG(v){ BG = v; }, set CUR(v){ CUR = v; }};")
io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('ok')
