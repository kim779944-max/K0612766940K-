# 앱별 검증식 (cap.ps1에서 읽음). 각 식은 async 함수 본문이며 return 값이 로그에 그대로 찍힘
$CHECKS = @{}
$CHECKS['themenu'] = @{ input = '#menu'; checks = @(
  @('menu / langs / QR', 'return CUR.items.length+" items, langs="+(1+CUR.L.length)+", QR v"+CUR.q.version+" "+CUR.q.ecl+" "+CUR.q.bytes+"B"'),
  @('page has 2 langs', 'return "ko="+CUR.html.includes("김치찌개")+" en="+CUR.html.includes("Kimchi Stew")+" zh(not selected)="+CUR.html.includes("泡菜汤")'),
  @('price edit -> QR rebuilt', 'const u=CUR.url; const i=document.querySelector("#list input"); i.value="9500"; i.dispatchEvent(new Event("change")); await new Promise(r=>setTimeout(r,300)); return "changed="+(CUR.url!==u)+" price0="+CUR.items[0].price+" pageHas 9,500원="+CUR.html.includes("9,500원")'),
  @('no guessed price', '$("#menu").value="김밥 |  | Gimbap"; run(); const r="price="+CUR.items[0].price+" page shows - ="+CUR.html.includes(">-<"); $("#sampleBtn").click(); run(); return r'),
  @('preview iframe', 'return String(document.querySelector("#pv").srcdoc.length)+" chars"'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['stampcard'] = @{ input = '#in'; copy = '#stampBtn'; checks = @(
  @('customers', 'return S.custs.map(c=>c.id+":"+c.n+"/"+S.need).join(", ")'),
  @('stamp to 10 -> reward', 'SEL=1; render(); document.querySelector("#stampBtn").click(); await new Promise(r=>setTimeout(r,100)); return "n="+S.custs[1].n+" reward shown="+!!document.querySelector(".reward")'),
  @('use reward -> stats', 'document.querySelector("#useBtn").click(); return "n="+S.custs[1].n+" done="+S.custs[1].done+" 이번달 도장="+$("#sG").textContent+" 사용="+$("#sU").textContent'),
  @('undo', 'SEL=0; render(); document.querySelector("#stampBtn").click(); const a=S.custs[0].n; document.querySelector("#undoBtn").click(); return a+" -> "+S.custs[0].n'),
  @('share QR + ?c= view', 'const u=window.__share; return "qr="+!!document.querySelector("#qr svg")+" url len="+u.length+" param ok="+(JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(u.split("?c=")[1]),c=>c.charCodeAt(0)))).k===S.custs[0].n)'),
  @('persist', 'return LS.get("kts_stampcard_v1",{}).custs.length+" custs saved"'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['closeshop'] = @{ input = '#in'; checks = @(
  @('ex1 items', 'return CUR.items.length+" items: "+[...new Set(CUR.items.map(x=>x.st))].join(" > ")'),
  @('deadlines', 'return CUR.items.slice(4,9).map(x=>x.t.slice(0,12)+"="+ymd(x.due)+"(D"+x.dd+")").join(" | ")'),
  @('ex2 items', '$("#s2").click(); run(); const r=CUR.items.length+" items (법인 양도)"; $("#sampleBtn").click(); run(); return r'),
  @('check persist', 'document.querySelector("#list input").click(); return "done="+$("#sDone").textContent'),
  @('fixed line', 'return document.querySelectorAll(".fixnote").length+" fixnotes"'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['payroll'] = @{ input = '#rows'; checks = @(
  @('pay', 'return CUR.E.map(e=>e.name+": base "+e.base+" 주휴 "+e.ju+" ot "+e.otPay+" gross "+e.gross+" ded "+e.ded+" net "+e.net).join(" | ")'),
  @('hand check 김하늘', 'const e=CUR.E[0]; const base=Math.round(10320*40*4.345), ju=Math.round(8*10320*4.345); return "base="+(e.base===base)+" ju="+(e.ju===ju)+" np="+(e.np===Math.floor(e.gross*0.0475/10)*10)'),
  @('60+ pension excluded', 'return "박서윤 np="+CUR.E[2].np'),
  @('rates editable', '$("#rNP").value="4.5"; run(); const a=CUR.E[0].np; $("#rNP").value="4.75"; run(); return "np@4.5="+a+" np@4.75="+CUR.E[0].np'),
  @('5인 미만 ot', '$("#size").value="5dn"; run(); const a=CUR.E[1].otPay; $("#size").value="5up"; run(); return "5dn="+a+" 5up="+CUR.E[1].otPay'),
  @('employer', 'return $("#sEr").textContent'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['docnum'] = @{ input = '#in'; copy = '#csvBtn'; checks = @(
  @('issued', 'return D.rows.map(r=>r.no+" "+r.cli).join(", ")'),
  @('dup warning shown', 'return "dupBox="+!!document.querySelector(".dup")+" rows still="+D.rows.length'),
  @('force issue', 'document.querySelector("#forceBtn").click(); return D.rows.length+" rows, last="+D.rows[D.rows.length-1].no'),
  @('undo once', 'window.__undoAnswer=D.rows[D.rows.length-1].no; document.querySelector("#undoBtn").click(); const a=D.rows.length; window.__undoAnswer=D.rows[D.rows.length-1].no; document.querySelector("#undoBtn").click(); return "after undo="+a+" second undo blocked rows="+D.rows.length'),
  @('gap detect', 'D.rows.splice(1,1); save(); render(); const g=gaps(); return "gaps="+g.join(",")'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['rights1p'] = @{ input = '#src'; checks = @(
  @('ex1 signals', 'const f=g=>CUR.P[g].filter(e=>e.col&&!e.gone&&!e.kill).map(e=>e.kind).join("+"); return "갑구 "+f("gap")+" | 을구 "+f("eul")+" | max합 "+CUR.sumMax+"만 dep "+CUR.sumDep+"만 net "+(CUR.price-CUR.sumMax-CUR.sumDep)'),
  @('3 examples', 'const r=[];for(let i=0;i<3;i++){setEx(i);run();const g=CUR.P.gap.filter(e=>e.col&&!e.gone&&!e.kill).length,u=CUR.P.eul.filter(e=>e.col&&!e.gone&&!e.kill).length;r.push((i+1)+": 갑"+g+" 을"+u+" max="+CUR.sumMax+" clear="+CUR.toClear.length)}setEx(0);run();return r.join(" | ")'),
  @('말소 처리 (ex3)', 'setEx(2);run();const r=CUR.P.eul.map(e=>e.no+e.kind+(e.gone?"(gone)":"")+(e.kill?"(kill)":"")).join(", "); setEx(0); run(); return r'),
  @('no invented entries', 'return "entries="+(CUR.P.gap.length+CUR.P.eul.length)+" lines numbered in src="+($("#src").value.split("\n").filter(l=>/^\d+\s/.test(l)).length-1)'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['pricegap'] = @{ input = '#rows'; checks = @(
  @('stats', 'return "n="+CUR.ok.length+" sample="+CUR.S.length+" med="+Math.round(CUR.med)+" avg="+Math.round(CUR.avg)+" askPpy="+Math.round(CUR.askPpy)+" gap="+(CUR.gap*100).toFixed(1)+"% pubX="+CUR.pubX.toFixed(2)'),
  @('outliers', 'return CUR.ok.filter(r=>r.out).map(r=>r.addr+" "+r.v+" dev "+(r.dev*100).toFixed(0)+"%").join(" | ")'),
  @('hand check ppy row0', 'const r=CUR.ok[0]; return r.v+"/("+r.a.m2+"/3.3058)="+(r.v/(r.a.m2/3.3058)).toFixed(1)+" vs "+r.ppy.toFixed(1)'),
  @('표본 부족 경고', 'const o=$("#rows").value; $("#rows").value=o.split("\n").slice(0,3).join("\n"); run(); const w=$("#warn").textContent.slice(0,20); $("#rows").value=o; run(); return w'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['leaseccompare'] = @{ input = '#rows'; checks = @(
  @('order', 'return CUR.C.map(c=>c.nm.split(" ")[0]+" 월"+c.tot.toFixed(1)+" 4년"+Math.round(c.y4)+" 평당"+c.ppy.toFixed(2)).join(" | ")'),
  @('hand check A', 'const c=CUR.C.find(x=>/^A/.test(x.nm)); return (380+35+5000*0.04/12+4000/60).toFixed(3)+" vs "+c.tot.toFixed(3)'),
  @('cards', 'return CUR.C.map(c=>c.nm.split(" ")[0]+":"+c.weak.join(",")).join(" ")+" / asks="+document.querySelectorAll(".ask").length'),
  @('rate edit', '$("#rate").value="6"; run(); const a=CUR.C.find(x=>/^A/.test(x.nm)).tot.toFixed(2); $("#rate").value="4"; run(); return "A tot@6%="+a'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['yieldcalc'] = @{ input = '#in'; checks = @(
  @('ex1', 'return "gross "+(CUR.gross*100).toFixed(2)+"% net "+(CUR.net*100).toFixed(2)+"% roe "+(CUR.roe*100).toFixed(2)+"% cf "+Math.round(CUR.cur.cf)+" be "+(CUR.be*100).toFixed(1)+"% eq "+CUR.eq'),
  @('hand check NOI', 'return (380*12*0.95-30*12-220).toFixed(1)+" vs "+CUR.noi.toFixed(1)'),
  @('3 methods', 'return ["eq","pr","io"].map(h=>h+": it "+Math.round(CUR.S[h].it)+" pr "+Math.round(CUR.S[h].pr)+" cf "+Math.round(CUR.S[h].cf)).join(" | ")'),
  @('10y cum', 'return CUR.ten.map(t=>Math.round(t.cum)).join(",")'),
  @('ex2', '$("#s2").click(); run(); const r="gross "+(CUR.gross*100).toFixed(2)+"% cf "+Math.round(CUR.cur.cf)+" be "+(CUR.be*100).toFixed(1)+"%"; $("#sampleBtn").click(); run(); return r'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['swapcheck'] = @{ input = '#in'; copy = '#copyBtn'; checks = @(
  @('ex1', 'return CUR.g+" "+CUR.avg.toFixed(1)+" | net A "+CUR.A.net+" B "+CUR.B.net+" d "+CUR.d+" | "+CUR.ax.map(a=>a[1]+a[2]).join(" ")'),
  @('top3 + fixes', 'return CUR.low.map(x=>x[1]).join(", ")+" / fixes="+document.querySelectorAll("#block .fix").length'),
  @('ex2', '$("#s2").click(); run(); const r=CUR.g+" "+CUR.avg.toFixed(1)+" | "+CUR.low.map(x=>x[1]+x[2]).join(", "); $("#sampleBtn").click(); run(); return r'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['bidcompare'] = @{ input = '#src'; checks = @(
  @('totals', 'return CUR.V.map(v=>v.nm+" "+v.total+" ("+v.items.length+"항목)").join(" | ")'),
  @('over 50%', 'return "rows="+CUR.rows.length+" over="+CUR.over.map(o=>o.v+":"+o.name+" x"+o.x.toFixed(2)).join(", ")'),
  @('missing', 'return CUR.miss.map(m=>m.v+":"+(m.list.join("/")||"-")).join(" | ")'),
  @('확인 필요(자동 확정 안 함)', 'return CUR.amb.length+" pairs: "+CUR.amb.map(a=>a[0]+"↔"+a[1]).join(", ")'),
  @('questions', 'return CUR.qs.length+" qs"'),
  @('no guessed unit', '$("#src").value="X\n바닥, 1, , \n벽, 1, 100, 100\n\nY\n바닥, 1, 200, 200\n벽, 1, 120, 120"; run(); const r="blank unit="+CUR.V[0].items[0].unit+" amt="+CUR.V[0].items[0].amt; $("#sampleBtn").click(); run(); return r'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['taxsim'] = @{ input = '#in'; checks = @(
  @('ex1 house', 'return "acq "+Math.round(CUR.acq.sum)+" gain "+Math.round(CUR.gain)+" base "+Math.round(CUR.taxBase)+" cg "+Math.round(CUR.cg)+" local "+Math.round(CUR.cgLocal)+" prop "+Math.round(CUR.prop)+" jong "+Math.round(CUR.jong)+" all "+Math.round(CUR.all)'),
  @('hand check gain', 'return (92000-58000-1800)+" vs "+CUR.gain'),
  @('3 examples', 'const r=[];for(let i=0;i<3;i++){load(i);run();r.push(CUR.v.kind+": all "+Math.round(CUR.all)+" net "+Math.round(CUR.net)+" 직접확인 "+CUR.chk.length)}load(0);run();return r.join(" | ")'),
  @('rate editable', 'const a=Math.round(CUR.acq.base); $("#rAcq").value="3"; run(); const b=Math.round(CUR.acq.base); load(0); run(); return "acq base "+a+" -> @3% "+b'),
  @('bracket table open', 'return ($$("#brk tr").length-1)+" bracket rows, editable inputs="+$$("#brk input").length'),
  @('fixed line', 'return document.querySelectorAll(".fixnote").length+" fixnotes"'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['sitecheck'] = @{ input = '#in'; copy = '#copyBtn'; checks = @(
  @('photos', 'return P.length+" photos, areas="+uniq(P.map(p=>p.area)).join("/")'),
  @('bad / warn', 'return "불량="+$("#sBad").textContent+" 주의="+$("#sWarn").textContent+" bad cards="+$$("#bads .item").length'),
  @('priority top3', 'return $$("#prio tr").slice(1,4).map(tr=>[...tr.cells].slice(1,4).map(c=>c.textContent).join(" ")).join(" | ")'),
  @('state tap + persist', 'const b=$$(".tri button").find(x=>x.dataset.s==="불량"&&!x.classList.contains("on")); b.click(); return "saved keys="+Object.keys(LS.get(KEY,{})).length+" 불량="+$("#sBad").textContent'),
  @('mosaic', 'mosaic(P[0].id,.5,.5); await new Promise(r=>setTimeout(r,600)); return "masked="+P[0].masked'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['notice'] = @{ input = '#in'; copy = '#copyBtn'; checks = @(
  @('ex1', 'return CUR.v.ty+" req "+CUR.req.filter(r=>r[1]).length+"/"+CUR.req.length+" tones="+CUR.d.length+" len="+CUR.d.map(d=>d.length).join("/")'),
  @('3 examples', 'const r=[];for(let i=0;i<3;i++){load(i);run();r.push(CUR.v.ty+" req "+CUR.req.filter(x=>x[1]).length+"/"+CUR.req.length)}load(0);run();return r.join(" | ")'),
  @('missing field detect', '$("#tel").value=""; run(); const r="빠짐="+CUR.req.filter(x=>!x[1]).map(x=>x[0]).join(",")+" shown="+$$("#req .n").length; load(0); run(); return r'),
  @('tone switch', '$$("#toneC button")[2].click(); const v=$$(".tone").filter(t=>!t.classList.contains("hide")).map(t=>t.dataset.i).join(); $$("#toneC button")[0].click(); return "visible tone="+v'),
  @('send guide', 'return "3단계="+document.querySelectorAll("ol.g li").length+" fixnotes="+document.querySelectorAll(".fixnote").length'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['fieldreport'] = @{ input = '#src'; checks = @(
  @('scores', 'return CUR.S.map(s=>s.nm.split(" ")[0]+" 총"+sc(s.tot)+" 유동"+sc(s.sFlow)+" 경쟁"+sc(s.sComp)+" 주차"+s.sPark).join(" | ")'),
  @('hand check A avg', 'return ((85+210+120+260+140)/5)+" vs "+CUR.S[0].avg'),
  @('risks', 'return CUR.S.map(s=>s.nm.split(" ")[0]+":"+(s.risks.map(r=>r[0]).join("+")||"-")).join(" | ")'),
  @('hours table', 'return "hours="+CUR.H.join(",")+" rows="+$$("#hours tr").length+" comps="+CUR.S.map(s=>s.comps.length).join("/")'),
  @('cards', 'return $$(".fc").length+" cards, bars="+$$(".fc .bar").length'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['ledger'] = @{ input = '#rows'; checks = @(
  @('rows / io', 'return CUR.R.length+" rows · 매출 "+CUR.R.filter(r=>r.io==="매출").length+" 매입 "+CUR.R.filter(r=>r.io==="매입").length+" 기타(확인) "+CUR.R.filter(r=>r.q).length'),
  @('vat summary', 'return CUR.V.map(x=>x.v+" s"+x.s+" b"+x.b).join(" | ")'),
  @('hand check 과세 매출', 'return CUR.R.filter(r=>r.io==="매출"&&r.vat==="과세").reduce((a,r)=>a+r.amt,0)+" = "+[1284000,864000,356000,1098000,412000,1342000,902000,298000,1156000,389000].reduce((a,b)=>a+b,0)'),
  @('month / quarter', 'return CUR.per.map(p=>p.k+" "+p.s+"/"+p.b).join(" | ")'),
  @('증빙 없는 지출', 'return CUR.R.filter(r=>r.noev).map(r=>r.who).join(", ")'),
  @('card masked', 'return "cards="+uniq(CUR.R.map(r=>r.card).filter(Boolean)).join(",")+" fullNumberInDom="+/9410-1234-5678/.test($("#result").innerHTML)'),
  @('manual reclass learned', 'const s=$$("#tbl select")[2]; s.value="소모품"; s.dispatchEvent(new Event("change")); const r=CUR.R[2]; const out=r.who+" -> "+r.acct+" ("+r.rule+") learned="+Object.keys(LS.get(LKEY,{})).length; LEARN={}; LS.set(LKEY,{}); run(); return out'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['bundle100'] = @{ input = '#list'; checks = @(
  @('months', 'return CUR.G.map(g=>g.k+": "+g.n+"건 합계 "+g.sum+" 금액없음 "+g.noAmt).join(" | ")'),
  @('hand check 9월 합계', 'return (152000+438000+49500+168000+84000+66000)+" vs "+CUR.G[0].sum'),
  @('reorder', 'const a=F[0].name; $$("[data-dn]")[0].click(); const r="first was "+a.slice(0,8)+" now "+F[0].name.slice(0,8)+" second="+F[1].name.slice(0,8); $$("[data-up]")[1].click(); return r+" restored="+(F[0].name===a)'),
  @('delete + amount blank', 'const n=F.length; F[11].amt=NaN; run(); const r="noAmt(10월)="+CUR.G[1].noAmt+" sum="+CUR.G[1].sum; $$("[data-rm]")[11].click(); return r+" | delete "+n+"->"+F.length'),
  @('restore sample', '$("#sampleBtn").click(); run(); return F.length+" files"'),
  @('book pages', 'const h=book(); return "page divs="+(h.match(/break-after:page/g)||[]).length+" covers="+(h.match(/표지/g)||[]).length'),
  @('rule names', 'return $("#names").textContent.split("\n").length+" lines, first: "+$("#names").textContent.split("\n")[0]'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['official'] = @{ input = '#in'; checks = @(
  @('ex1 format', 'return "no="+CUR.no+" att="+CUR.att.length+" paras="+(CUR.body.match(/^\d\. /gm)||[]).length+" 근거빈칸="+CUR.body.includes("[근거: 직접 입력]")'),
  @('honorific check ex1', 'return CUR.chk.map(c=>(c.i+1)+":"+(c.bad.length?c.bad.join("/"):"ok")+(c.end?"":" 끝확인")).join(" | ")'),
  @('ex2', '$$("[data-e]")[0].click(); run(); const r="to="+CUR.v.to+" 귀사="+CUR.body.includes("귀 사")+" ref="+CUR.body.includes("구매-2026-118")+" bad="+CUR.chk.filter(c=>c.bad.length||!c.end).length; $("#sampleBtn").click(); run(); return r'),
  @('facts kept', 'return "기한="+CUR.body.includes("2026. 12. 4.")+" 붙임끝="+/끝\.$/.test(CUR.body)'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['bilingual'] = @{ input = '#in'; checks = @(
  @('pairs', 'return "rows="+CUR.R.length+" ko="+CUR.nK+" en="+CUR.nE'),
  @('missing', 'return CUR.R.filter(r=>r.flags.some(f=>f[0]==="miss")).map(r=>"제"+r.n+"조").join(", ")'),
  @('number mismatch', 'return CUR.R.filter(r=>r.flags.some(f=>f[0]==="num")).map(r=>"제"+r.n+"조 "+r.flags.find(f=>f[0]==="num")[1]).join(" | ")'),
  @('term check', 'return CUR.R.filter(r=>r.flags.some(f=>f[0]==="term")).map(r=>"제"+r.n+"조 "+r.flags.filter(f=>f[0]==="term").map(f=>f[1]).join(",")).join(" | ")'),
  @('highlight', 'return $$("#tbl mark").map(m=>m.textContent).join(" / ")'),
  @('glossary editable', 'const g=$("#gl").value; $("#gl").value=g.replace("해제, Rescission","해제, terminate"); run(); const n=CUR.R.filter(r=>r.flags.some(f=>f[0]==="term")).length; $("#gl").value=g; run(); return "term flags after edit="+n'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['weeklog'] = @{ input = '#memo'; checks = @(
  @('split', 'return CUR.D.map(d=>d.h+":"+d.L.length).join(" ")+" total="+CUR.L.length'),
  @('4 classes', 'return ["완료","진행","보류","막힘","확인"].map(s=>s+" "+CUR.L.filter(x=>x.s===s).length).join(" · ")'),
  @('last-word rule', 'return ["호스팅 결제 문제 해결 완료","결제 오류로 막힘","재협상 다음 주로 연기"].map(t=>t+"→"+status(t)).join(" | ")'),
  @('progress', 'return CUR.pl.map(p=>p.p+" "+p.show+"% ("+(p.explicit!=null&&p.last.pct!=null?"explicit":p.how)+")").join(" | ")'),
  @('next week', 'return CUR.next.length+": "+CUR.next.map(x=>x.t.slice(0,18)).join(" / ")'),
  @('no invented', 'return "result lines="+$$("#days .ln").length+" = input lines "+$("#memo").value.split("\n").filter(l=>l.trim()&&!DH.test(l)).length'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['sopset'] = @{ input = '#steps'; checks = @(
  @('ex1', 'return CUR.S.length+" steps · groups "+CUR.groups.map(g=>FQ[g.f]+g.S.length).join("/")+" · 매일 합계 "+CUR.tot+"분 · 실수방지 "+CUR.mis.length'),
  @('parse step 1', 'const s=CUR.S[0]; return "t="+s.t+" | prep="+s.prep+" | min="+s.min+" | warn="+s.warn'),
  @('no invented steps', 'return "steps="+CUR.S.length+" input lines="+$("#steps").value.split("\n").filter(l=>l.trim()).length'),
  @('ex2 monthly', '$$("[data-e]")[0].click(); run(); const r=CUR.S.length+" steps · groups "+CUR.groups.map(g=>FQ[g.f]+g.S.length).join("/")+" · 매월 합계 "+CUR.tot+"분 · 실수방지 "+CUR.mis.length+" (주의 2개뿐 안내="+/주의.*2개뿐/.test($("#mis").textContent)+")"; $("#sampleBtn").click(); run(); return r'),
  @('template save', '$("#saveBtn").click(); return "templates="+Object.keys(LS.get(TK,{})).length+" options="+$$("#tpl option").length'),
  @('check persist', '$$("#cks input")[0].click(); return "checked saved="+Object.keys(LS.get(CKK,{})).length'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['tagmaker'] = @{ input = '#feat'; print = $false; checks = @(
  @('titles', 'return CUR.titles.map(t=>t[0]+" "+t[2].length+"/"+t[1]).join(" | ")'),
  @('title 1', 'return CUR.titles[0][2]'),
  @('keywords', 'return CUR.K.length+" unique="+uniq(CUR.K.map(k=>k.split(" ").sort().join(""))).length+" · "+CUR.K.slice(0,6).join(", ")'),
  @('removed', 'return CUR.W.map(w=>w[0]+":"+w[1]).join(", ")'),
  @('no hype/TM in output', 'const o=CUR.titles.map(t=>t[2]).concat(CUR.K).join(" "); return "hype="+HYPE.filter(w=>o.includes(w)).join(",")+" tm="+TM.filter(w=>o.includes(w)).join(",")'),
  @('only input words', 'const src=[$("#pn").value,$("#feat").value,$("#cat").value,$("#tg").value,$("#sit").value].join(" "); const bad=uniq(CUR.K.flatMap(k=>k.split(" "))).filter(w=>!src.includes(w)&&w!=="선물"); return "words not in input="+JSON.stringify(bad)'),
  @('limit edit', '$("#lC").value="20"; run(); const r=CUR.titles[0][2]+" ("+CUR.titles[0][2].length+")"; $("#lC").value="50"; run(); return r'),
  @('ex2', '$$("[data-e]")[0].click(); run(); const r=CUR.K.length+" kw · removed "+CUR.W.map(w=>w[1]).join(",")+" · "+CUR.titles[1][2]; $("#sampleBtn").click(); run(); return r'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['reviewsum'] = @{ input = '#rv'; checks = @(
  @('sentiment', 'return CUR.R.length+" reviews · "+["긍정","부정","중립","섞임"].map(s=>s+" "+CUR.R.filter(r=>r.sent===s).length).join(" · ")'),
  @('pros top5', 'return CUR.pros.map(x=>x.a+x.n).join(", ")'),
  @('cons top5', 'return CUR.cons.map(x=>x.a+x.n).join(", ")'),
  @('quotes verbatim', 'const q=CUR.pros.concat(CUR.cons).flatMap(x=>x.q); return q.length+" quotes, all in source="+q.every(x=>$("#rv").value.includes(x.s))'),
  @('actions', 'return CUR.cons.length+" actions: "+CUR.cons.map(c=>c.a).join("/")'),
  @('stars', 'return "avg "+CUR.avg.toFixed(2)+" · "+CUR.dist.map(d=>d.s+":"+d.n).join(" ")'),
  @('no stars -> hide dist', 'const o=$("#rv").value; $("#rv").value=o.split("\n").map(l=>l.replace(/^\d\|/,"")).join("\n"); run(); const r="hidden="+$("#distW").classList.contains("hide")+" pos="+CUR.R.filter(x=>x.sent==="긍정").length; $("#rv").value=o; run(); return r'),
  @('replies', 'return $$("#reps .item").length+" templates"'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['secondhand'] = @{ input = '#in'; print = $false; checks = @(
  @('ex1', 'return "titles="+CUR.T.length+" defects in body="+CUR.inBody+" warns="+CUR.W.length+" | "+CUR.T[0]'),
  @('price basis', 'return CUR.why'),
  @('ups / checklist', 'return CUR.ups.length+" ups · "+CUR.CL.map(c=>(c[1]?"O":"X")+c[0].slice(0,8)).join(" ")'),
  @('ex2 soft words', '$$("[data-e]")[0].click(); run(); const r=CUR.W.map(w=>w[0]).join(" / ")+" · inBody="+CUR.inBody; $("#sampleBtn").click(); run(); return r'),
  @('empty defects warn', 'const d=$("#def").value; $("#def").value=""; $("#cond").value="사용감 있음"; run(); const r=CUR.W.map(w=>w[0]).join(" / "); $("#sampleBtn").click(); run(); return r'),
  @('region toggle', '$("#useReg").checked=false; run(); const r=CUR.T[0]; $("#useReg").checked=true; run(); return r+" -> "+CUR.T[0]'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['launcher'] = @{ input = '#q'; print = $false; checks = @(
  @('reads products.js', 'return "PRODUCTS="+PRODUCTS.length+" listed(all tab)="+$$("#all .pc").length+" live="+P().filter(live).length+" soon="+P().filter(p=>!live(p)).length'),
  @('search 월세', 'return window.__res.length+": "+window.__res.map(p=>p.k).join(",")'),
  @('search 등기 / 폐업', 'const r=[]; for(const q of ["등기","폐업","영수증"]){$("#q").value=q; Q=q; render(); r.push(q+"="+window.__res.map(p=>p.k).slice(0,4).join("/"))} $("#q").value="월세"; Q="월세"; render(); return r.join(" | ")'),
  @('recent', 'document.addEventListener("click",e=>e.preventDefault(),{once:true,capture:true}); $("#res [data-go]").click(); await new Promise(r=>setTimeout(r,100)); return "recent="+JSON.stringify(recents())+" shown="+$$("#recent .pc").length'),
  @('favorite', '$("#res .fav").click(); return "favs="+JSON.stringify(favs())+" shown="+$$("#fav .pc").length'),
  @('new product auto', 'PRODUCTS.push({k:"zz_test",nm:"테스트 신상품",sub:"",line:"자동 반영 확인",status:"live",cat:"etc",link:"#"}); render(); const a=$("#all").textContent.includes("테스트 신상품"); PRODUCTS.pop(); render(); return "appeared="+a+" removed="+!$("#all").textContent.includes("테스트 신상품")'),
  @('soon not clickable', 'CAT="soon"; render(); const r=$$("#all .pc.soon").length+" soon cards, links="+$$("#all .pc.soon[href]").length; CAT="all"; render(); return r'),
  @('industry', 'const r=[]; for(let i=0;i<IND.length;i++){INDI=i; render(); r.push(IND[i][0]+" "+$$("#indList .pc").length)} INDI=0; render(); return r.join(" · ")'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
