# 앱별 검증식 (cap.ps1에서 읽음). 각 식은 async 함수 본문이며 return 값이 로그에 그대로 찍힘
$CHECKS = @{}
$CHECKS['mealplan'] = @{ input = '#rec'; checks = @(
  @('meals / kinds / check', 'return $("#sMeal").textContent+" meals / "+$("#sIng").textContent+" kinds / 확인 "+$("#sChk").textContent'),
  @('categories', 'const o={};CUR.items.forEach(i=>o[i.cat]=(o[i.cat]||0)+1);return JSON.stringify(o)'),
  @('unit-mismatch rows', 'return CUR.items.filter(i=>i.chk).map(i=>i.name+"("+i.u+")").join(", ")'),
  @('계란 total', 'return CUR.items.filter(i=>i.name==="계란").map(i=>i.q+i.u+(i.price!=null?" price="+i.price:"")).join(" | ")'),
  @('두부 vs 순두부 kept apart', 'return CUR.items.filter(i=>/두부/.test(i.name)).map(i=>i.name+" "+i.q+i.u).join(" | ")'),
  @('price shown only for input', 'return String(CUR.items.filter(i=>i.price!=null).map(i=>i.name).join(","))'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('check persist', 'const c=document.querySelector("#list input"); c.click(); return JSON.stringify(LS.get("kts_mealplan_chk_v1",{}))')
)}
$CHECKS['engquiz'] = @{ input = '#itr'; copy = '#copyBtn'; checks = @(
  @('bank per interest', 'return Object.keys(EQ.DB).map(k=>k+"="+EQ.DB[k].length+"(초"+EQ.DB[k].filter(x=>x.lv==="easy").length+"/중"+EQ.DB[k].filter(x=>x.lv==="mid").length+"/고"+EQ.DB[k].filter(x=>x.lv==="hard").length+", 응답쌍"+EQ.DB[k].pairs.length+")").join(" ")'),
  @('key not found in sentence', 'return String(Object.keys(EQ.DB).reduce((a,k)=>a+EQ.DB[k].filter(x=>!x.hasKey).length,0))'),
  @('15 combos x 10q', 'const r=[];for(const i of ["travel","realestate","cafe","fitness","shopping"])for(const l of ["easy","mid","hard"]){const q=EQ.build(i,l,10,"2026-11-18");const bad=q.filter(x=>!x.q||!x.ans||(x.opts&&(x.opts.length!==4||x.opts.indexOf(x.ans)<0||new Set(x.opts).size!==4))).length;r.push(i+"/"+l+":"+q.length+(bad?" BAD"+bad:""))}return r.join(" ")'),
  @('5q types', 'return EQ.build("cafe","mid",5,"2026-11-18").map(x=>x.t).join(",")'),
  @('daily different set', 'const a=EQ.build("travel","easy",10,"2026-11-18").map(x=>x.q).join("|"),b=EQ.build("travel","easy",10,"2026-11-19").map(x=>x.q).join("|"),c=EQ.build("travel","easy",10,"2026-11-18").map(x=>x.q).join("|");return "11-18 vs 11-19 different="+(a!==b)+" / same day same set="+(a===c)'),
  @('answer 10 (7 right, 3 wrong)', 'EQ.Q.forEach((q,i)=>EQ.answer(i,(i%3===1)?"__wrong__":q.ans));return $("#sScore").textContent+" streak="+$("#sStreak").textContent+" rate="+$("#sRate").textContent+" wrongSaved="+LS.get("kts_engquiz_v1",{}).wrong.length'),
  @('explanation sample', 'return [...document.querySelectorAll(".exp")].slice(0,3).map(e=>e.textContent).join(" || ")'),
  @('copy 3 sentences', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.replace(/\n/g," ⏎ ")')
); extra = {
  ScrollTo '#quiz' 'start' -64
  Shot $dir '04_answered' @((Mk 'circle' (RectNoScroll '#q0') '정답 · 해설 · 발음'))
  Nav 'oneclick\engquiz.html'
  L ('after reload: streak=' + (Js 'return $("#sStreak").textContent') + ' rate=' + (Js 'return $("#sRate").textContent') + ' wrong list=' + (Js 'return String(document.querySelectorAll("#wrong .item").length)') + ' days=' + (Js 'return JSON.stringify(Object.keys(LS.get("kts_engquiz_v1",{}).days))'))
  TapSel '#sampleBtn' | Out-Null; TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 400
}}
$CHECKS['cardbook'] = @{ input = '#sms'; copy = '#csvBtn'; checks = @(
  @('extracted', 'return $("#sN").textContent+" · "+$("#parseInfo").textContent'),
  @('by category', 'const o={};CUR.rows.forEach(r=>o[r.c]=(o[r.c]||0)+1);return JSON.stringify(o)'),
  @('fixed merchants', 'return [...new Set(CUR.rows.filter(r=>r.fixed).map(r=>r.merchant))].join(", ")'),
  @('budget over', 'return [...document.querySelectorAll(".brow.over .h b")].map(e=>e.textContent).join(" | ")'),
  @('card number masked', 'return "raw 1234-56 left="+/1234-56/.test(document.querySelector("#result").textContent)+" / last4 shown="+CUR.rows.filter(r=>r.last4).map(r=>r.last4).filter((v,i,a)=>a.indexOf(v)===i).join(",")'),
  @('manual re-class + learn', 'const i=CUR.rows.findIndex(r=>r.merchant==="미사동꽃집"); const s=document.querySelector("#txs select[data-i=\""+i+"\"]"); s.value="쇼핑"; s.dispatchEvent(new Event("change")); $("#runBtn").click(); return "꽃집 → "+CUR.rows.find(r=>r.merchant==="미사동꽃집").c+" ("+CUR.rows.find(r=>r.merchant==="미사동꽃집").why+") learn="+JSON.stringify(LS.get("kts_cardbook_learn_v1",{}))'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('fixed notice', 'return document.querySelector(".fixnote").textContent')
)}
$CHECKS['tripcourse'] = @{ input = '#places'; copy = '#printBtn'; checks = @(
  @('course', 'return $("#rTitle").textContent+" days="+CUR.D.length+" filled="+CUR.used+" blank="+CUR.blank'),
  @('slots', 'return CUR.D.map((d,i)=>(i+1)+"일차: "+d.S.map(([t,s])=>t+"="+(s?s.n:"장소 입력")).join(" / ")).join(" || ")'),
  @('only listed places used', 'const L=$("#places").value.split("\n").map(l=>l.split("|")[0].trim()); const u=CUR.D.flatMap(d=>d.S).filter(s=>s[1]&&!/이동|귀가/.test(s[1].note)).map(s=>s[1].n); return "used="+u.length+" notInList="+u.filter(n=>L.indexOf(n)<0).length'),
  @('budget', 'return CUR.B.map(b=>b[0]+" "+b[1]).join(", ")+" sum="+CUR.B.reduce((a,b)=>a+b[1],0)'),
  @('move', 'return $("#moveInfo").textContent+" | "+CUR.D[0].S[0][1].n'),
  @('kit', 'return CUR.kit.length+" items: "+CUR.kit.join(", ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").slice(0,6).join(" ⏎ ")')
)}
$CHECKS['subscribeclean'] = @{ input = '#subs'; checks = @(
  @('totals', 'return "월 "+$("#sMon").textContent+" / 연 "+$("#sYear").textContent+" / 절약 "+$("#sSave").textContent'),
  @('priority', 'return CUR.S.map(s=>s.name+":"+s.score+s.rec).join(", ")'),
  @('top why', 'return CUR.S[0].name+" ← "+CUR.S[0].why.join(", ")'),
  @('path checklists', 'return String(document.querySelectorAll("#list li").length)+" steps"'),
  @('copy msgs', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n\n").length+" msgs, first: "+window.__lastCopy.split("\n").slice(0,3).join(" ⏎ ")'),
  @('fixed line', 'return document.querySelector(".fixnote").textContent.slice(0,30)')
)}
$CHECKS['reviewpolish'] = @{ input = '#memo'; checks = @(
  @('spoiler', 'return $("#spoil").textContent'),
  @('titles', 'return CUR.titles.length+": "+CUR.titles.join(" | ")'),
  @('paragraphs', 'return CUR.P.map(p=>p.length).join("/")+" :: "+[...document.querySelectorAll("#body .para")].map(e=>e.textContent).join(" || ")'),
  @('tags', 'return CUR.tags.length+": "+CUR.tags.join(" ")'),
  @('quotes verbatim', 'const q=$("#memo").value.match(/"[^"]*"/g)||[]; const b=$("#body").textContent; return q.map(x=>x+"="+(b.indexOf(x)>=0)).join(", ")'),
  @('no invented content (every sentence traces to a memo line)', 'const m=$("#memo").value.split("\n").map(s=>s.replace(/\s/g,"")); const sents=CUR.P.flat(); return sents.length+" sentences, untraceable="+sents.filter(s=>{const k=s.replace(/\s/g,"").slice(0,6);return !m.some(l=>l.indexOf(k)>=0)}).length'),
  @('changes', 'return $("#chg").textContent'),
  @('sample2 (movie)', '$("#sample2Btn").click(); $("#runBtn").click(); return "spoil="+!!$("#spoil").textContent+" titles="+CUR.titles.length+" tags="+CUR.tags.length+" P="+CUR.P.map(p=>p.length).join("/")+" :: "+CUR.P[1].join(" ")'),
  @('tone yo', 'document.querySelector("#tone button[data-k=yo]").click(); return CUR.P.flat().slice(0,3).join(" ")'),
  @('copy', 'document.querySelector("#tone button[data-k=hapnida]").click(); $("#sampleBtn").click(); $("#runBtn").click(); $("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+" chars, head: "+window.__lastCopy.slice(0,80).replace(/\n/g," ⏎ ")')
)}
$CHECKS['fitnessweek'] = @{ input = '#log'; copy = '#copyBtn'; checks = @(
  @('weeks', 'return CUR.keys.join(", ")+" · volume "+CUR.keys.map(k=>CUR.W[k].reduce((a,r)=>a+r.vol,0)).join(" → ")+" · diff "+$("#sDiff").textContent'),
  @('parts', 'return Object.entries(CUR.cur.parts).map(([p,v])=>p+" "+Math.round(v/CUR.tot*100)+"%").join(", ")+" · cardio "+CUR.cur.cardio+"분"'),
  @('warnings', 'return CUR.warns.length+": "+CUR.warns.join(" | ")'),
  @('increase <= 5%', 'const L=CUR.plan.filter(p=>p.w); return "max="+Math.max(...L.map(p=>Math.round((p.nw/p.w-1)*1000)/10))+"% · "+L.map(p=>p.name+" "+p.w+"→"+p.nw).join(", ")'),
  @('schedule', 'return CUR.sched.map(d=>d.day+":"+d.items.map(i=>i.part).join("/")+(d.cardio?"+유산소":"")).join(" ")'),
  @('consecutive same part in plan', 'const s=CUR.sched; let bad=0; for(let i=1;i<s.length;i++){const a=new Set(s[i-1].items.map(x=>x.part)); if(s[i].items.some(x=>a.has(x.part))&&["월","화","수","목","금","토"].indexOf(s[i].day)-["월","화","수","목","금","토"].indexOf(s[i-1].day)===1)bad++} return String(bad)'),
  @('fixed note', 'return document.querySelector(".fixnote").textContent.slice(0,16)'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").slice(0,5).join(" ⏎ ")')
)}
$CHECKS['ideaboard'] = @{ input = '#capital'; checks = @(
  @('ex1 numbers', 'return $("#pl").textContent'),
  @('questions', 'return String(document.querySelectorAll("#lens li").length)+" (lens "+CUR.lens.map(l=>l[1].length).join("/")+")"'),
  @('legal list', 'return CUR.legal.length+": "+CUR.legal.join(" | ")'),
  @('7-day', 'return String(document.querySelectorAll("#week tr").length-1)'),
  @('ex2', '$("#sample2Btn").click(); $("#runBtn").click(); return "margin="+CUR.margin+" bep="+CUR.bep+" back="+CUR.back+" q="+document.querySelectorAll("#lens li").length+" legal="+CUR.legal.length+" team week0="+CUR.week[0]'),
  @('loss case', 'const p=$("#price").value; $("#price").value="4000"; $("#runBtn").click(); const r=$("#sBep").textContent+" / "+$("#pl").textContent.slice(-60); $("#sampleBtn").click(); $("#runBtn").click(); return r'),
  @('no revenue forecast words', 'return String(/예상 매출|매출 예측|월 매출 \d/.test($("#result").textContent))'),
  @('fixed note', 'return document.querySelector(".fixnote").textContent')
)}
$CHECKS['petcare'] = @{ input = '#profiles'; copy = '#icsBtn'; checks = @(
  @('profiles', 'return CUR.map(r=>r.p.type+":"+r.p.name+" items="+r.items.length).join(", ")'),
  @('schedule', 'return CUR.map(r=>r.p.name+": "+r.items.map(i=>i.n+"→"+(i.next?ymd(i.next):"상담")+(i.due?"(지남)":"")).join(", ")).join(" || ")'),
  @('basis shown', 'return [...document.querySelectorAll(".tk small")].slice(0,3).map(e=>e.textContent).join(" | ")'),
  @('stat', 'return "month="+$("#sMonth").textContent+" due="+$("#sDue").textContent'),
  @('ics', '$("#icsBtn").click(); const d=window.__lastDownload; const ev=events(); return JSON.stringify(d)+" events="+ev.length'),
  @('ics text sample', 'const b=[]; const o=window.download; let cap=""; window.download=(n,t)=>{cap=t}; icsFile("x.ics",events().slice(0,1)); window.download=o; return cap.replace(/\r\n/g," | ").slice(0,300)'),
  @('no drug/dose words', 'return String(/\d\s*(mg|ml|정|알)\b|하트가드|넥스가드|레볼루션|브라벡토|용량/.test($("#result").textContent))'),
  @('persist profiles', 'return String(LS.get("kts_petcare_v1",[]).length)')
)}
$CHECKS['dangol'] = @{ input = '#list'; checks = @(
  @('counts', 'return "n="+$("#sN").textContent+" risk="+$("#sRisk").textContent+" due="+$("#sDue").textContent+" top="+CUR.top.length'),
  @('top10', 'return CUR.top.map(c=>c.name+"("+c.risk+","+c.visits+"회,"+c.ago+"/"+c.cyc+"일)").join(", ")'),
  @('cycle basis sample', 'return CUR.C.slice(5,8).map(c=>c.name+": "+c.cyc+"일 = "+c.basis).join(" | ")'),
  @('phone masked on screen', 'return "raw 010-0000- visible="+/010-0000-\d{4}/.test($("#result").textContent)+" masked sample="+maskTel4(CUR.C[0].tel)'),
  @('3 messages', 'const r=[];for(const k of [0,1,2]){document.querySelector("#kinds button[data-k=\""+k+"\"]").click(); r.push(k+": ok="+check()+" "+$("#cnt").textContent.split(" · ").slice(0,2).join(" "))} document.querySelector("#kinds button[data-k=\"0\"]").click(); return r.join(" | ")'),
  @('copy blocked without (광고)', 'const m=$("#msg"); const o=m.value; m.value=o.replace("(광고)",""); m.dispatchEvent(new Event("input")); $("#copyBtn").click(); const t=$("#toast").textContent; m.value=o; m.dispatchEvent(new Event("input")); return t'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.replace(/\n/g," ⏎ ")'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['wonka'] = @{ input = '#menu'; copy = '#printBtn'; checks = @(
  @('menus', 'return CUR.out.map(o=>o.name+": 원가 "+Math.round(o.cost)+" / "+(o.rate*100).toFixed(1)+"% / 권장 "+o.rec.join("·")+(o.bad.length?" 확인:"+o.bad.map(b=>b.n).join("/"):"")).join(" | ")'),
  @('stat', 'return "n="+$("#sN").textContent+" avg="+$("#sAvg").textContent+" >35%="+$("#sHi").textContent'),
  @('김치찌개 hand check', 'const o=CUR.out[0]; return o.lines.map(l=>l.n+"="+Math.round(l.cost)).join(", ")+" sum="+Math.round(o.food)'),
  @('+10% simulation', 'const a=CUR.out.map(o=>o.cost); $("#upBtn").click(); const b=CUR.out.map(o=>o.cost); const r="ratio="+(b[0]/a[0]).toFixed(3)+" "+$("#info").textContent.slice(0,30)+" avg="+$("#sAvg").textContent; return r'),
  @('reset', '$("#resetBtn").click(); return $("#sAvg").textContent'),
  @('unit mismatch check', 'const m=$("#menu"); const o=m.value; m.value=o+"\n테스트(5000원): 두부 300g, 계란 2개"; $("#runBtn").click(); const t=CUR.out[CUR.out.length-1]; const r=t.bad.map(b=>b.n+" "+b.why).join(", ")+" cost="+Math.round(t.cost); m.value=o; $("#runBtn").click(); return r'),
  @('extra cost only when input', 'const before=CUR.out[0].cost; $("#extra").value="1500"; $("#dfee").value="10"; $("#runBtn").click(); const after=CUR.out[0].cost; $("#extra").value=""; $("#dfee").value=""; $("#runBtn").click(); return "before="+Math.round(before)+" with extra1500+fee10%="+Math.round(after)+" back="+Math.round(CUR.out[0].cost)'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['balju'] = @{ input = '#stock'; copy = '#printBtn'; checks = @(
  @('stat', 'return "in="+$("#sIn").textContent+" items="+$("#sItems").textContent+" low="+$("#sLow").textContent'),
  @('low items', 'return CUR.items.filter(i=>i.low).map(i=>i.name+" 재고"+i.stock+"<"+i.safe+" → 발주 "+i.order+i.unit+" ("+i.vendor+")").join(" | ")'),
  @('unit check', 'return CUR.items.filter(i=>i.chk.length).map(i=>i.name+": "+i.chk.join(",")).join(" | ")'),
  @('price change (display only)', 'return CUR.items.filter(i=>i.pd).map(i=>i.name+" "+i.base+"→"+Math.round(i.newPrice)+" ("+(i.pd*100).toFixed(1)+"%)").join(" | ")+" · stock base price unchanged="+CUR.items.filter(i=>i.pd).every(i=>$("#stock").value.indexOf(String(i.base))>=0)'),
  @('order text', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.replace(/\n/g," ⏎ ")'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['hygiene'] = @{ input = '#items'; copy = '#printBtn'; checks = @(
  @('items', 'return document.querySelectorAll("#items .hi").length+" items · tri buttons="+document.querySelectorAll("#items .tri button").length'),
  @('month', 'return $("#mTitle").textContent+" days="+$("#sDays").textContent+" ok="+$("#sOk").textContent+" warn="+$("#sWarn").textContent'),
  @('calendar cells', 'return "green="+document.querySelectorAll("#cal .g").length+" red="+document.querySelectorAll("#cal .r").length'),
  @('warn list', 'return CUR.warn.slice(0,4).map(w=>w.d.slice(5)+" "+w.t).join(" | ")'),
  @('tap test (item 3 → 주의)', 'const b=document.querySelector("#items .tri button[data-i=\"2\"][data-v=\"warn\"]"); b.click(); $("#runBtn").click(); return "today item3="+LS.get("kts_hygiene_v1",{}).rec[todayS()].v[2]'),
  @('cafe set', '$("#biz").value="cafe"; $("#biz").dispatchEvent(new Event("change")); const t=[...document.querySelectorAll("#items .hi .t")].map(e=>e.textContent); $("#biz").value="food"; $("#biz").dispatchEvent(new Event("change")); return t[6]+" / "+t[14]'),
  @('fixed note', 'return document.querySelector(".fixnote").textContent'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
); extra = {
  Nav 'oneclick\hygiene.html'
  L ('persist after reload: records=' + (Js 'return String(Object.keys(LS.get("kts_hygiene_v1",{rec:{}}).rec).length)') + ' today item3 button on=' + (Js 'return String(document.querySelector("#items .tri button[data-i=\"2\"][data-v=\"warn\"]").classList.contains("on"))'))
  TapSel '#runBtn' | Out-Null; Start-Sleep -Milliseconds 400
}}
$CHECKS['shiftpay'] = @{ input = '#emp'; copy = '#printBtn'; checks = @(
  @('5인 이상 pay', 'return CUR.E.map(e=>e.name+": 주"+(e.total/60)+"h 연장"+(e.ot/60)+"h 야간"+(e.nt/60)+"h 주휴"+(e.juhu/60)+"h → 기본"+Math.round(e.base)+" 연장"+Math.round(e.otP)+" 야간"+Math.round(e.ntP)+" 주휴"+Math.round(e.juP)+" = "+Math.round(e.week)).join(" | ")'),
  @('hand-check expected', 'const x=CUR.E.map(e=>Math.round(e.week)); return "김하늘 495360="+(x[0]===495360)+" 이도윤 296100="+(x[1]===296100)+" 박서윤 358875="+(x[2]===358875)'),
  @('grid', 'return document.querySelectorAll("#grid td.w").length+" shift cells · month cal days="+document.querySelectorAll("#mcal div b").length'),
  @('5인 미만', 'document.querySelector("#size button[data-k=\"5dn\"]").click(); const r=CUR.E.map(e=>e.name+" "+Math.round(e.week)+" (otP="+Math.round(e.otP)+",ntP="+Math.round(e.ntP)+")").join(" | "); document.querySelector("#size button[data-k=\"5up\"]").click(); return r'),
  @('min wage flag', '$("#minw").value="10500"; $("#runBtn").click(); const r=CUR.E.filter(e=>e.low).map(e=>e.name).join(","); $("#minw").value="10320"; $("#runBtn").click(); return "below 10500: "+r'),
  @('formula shown', 'return $("#rules").textContent.slice(0,80)'),
  @('note', 'return $("#note").textContent'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['settle'] = @{ input = '#rows'; copy = '#csvBtn'; checks = @(
  @('channels', 'return CUR.chs.map((c,i)=>(i+1)+"."+c.ch+" 매출"+c.sales+" 수수료율"+(c.feeRate*100).toFixed(1)+"% 실수령률"+(c.netRate*100).toFixed(1)+"% 광고"+c.ad+" 손익"+c.pl).join(" | ")'),
  @('totals', 'return $("#sSales").textContent+" / "+$("#sNet").textContent+" / "+$("#sRate").textContent'),
  @('missing fee → 확인 (no estimate)', 'return CUR.chs.map(c=>c.ch+":"+c.miss.join(",")).join(" | ")+" · 확인 pill="+document.querySelectorAll("#chs .pill.b").length'),
  @('months', 'return Object.keys(CUR.months).join(",")'),
  @('no ads → no P/L', '$("#ads").value=""; $("#runBtn").click(); const r=CUR.chs.map(c=>c.ch+" pl="+c.pl).join(", "); $("#sampleBtn").click(); $("#runBtn").click(); return r'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['sellercalc_en'] = @{ input = '#ref'; checks = @(
  @('ex1 amazon', 'return "profit="+CUR.pr.toFixed(4)+" margin="+(CUR.margin*100).toFixed(1)+"% BE="+CUR.be.toFixed(2)+" target="+CUR.tp.toFixed(2)+" krw="+$("#krw").textContent'),
  @('hand check ex1 (10.5417)', 'return String(Math.abs(CUR.pr-(24.99-24.99*0.15-24.99*0.03-(4.21+0.18+0.85+6500/1380)))<1e-9)'),
  @('3 price points', 'return [...document.querySelectorAll("#pp div")].map(e=>e.textContent).join(" | ")'),
  @('loss warning', '$("#price").value="10"; $("#runBtn").click(); const r=$("#lossBox").textContent; $("#price").value="24.99"; $("#runBtn").click(); return r+" / after reset loss box empty="+($("#lossBox").textContent==="")'),
  @('ex2 shopee', '$("#sample2Btn").click(); $("#runBtn").click(); const r="profit="+CUR.pr.toFixed(2)+" margin="+(CUR.margin*100).toFixed(1)+"% BE="+CUR.be.toFixed(2)+" order("+CUR.units+")="+(CUR.pr*CUR.units).toFixed(2)+" note="+$("#mkNote").textContent.slice(0,40); $("#sampleBtn").click(); $("#runBtn").click(); return r'),
  @('rates editable (not hardcoded)', '$("#ref").value="8"; $("#runBtn").click(); const r=CUR.ref; $("#ref").value="15"; $("#runBtn").click(); return "ref after edit="+r'),
  @('fixed line', 'return document.querySelector(".fixnote").textContent'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('english UI', 'return document.documentElement.lang+" / "+$("#runBtn").textContent+" / "+document.querySelector("#inq h2").textContent')
)}
$CHECKS['listinggen_en'] = @{ input = '#banIn'; checks = @(
  @('input flags', 'return CUR.hits.map(h=>h.w).join(", ")+" ("+CUR.hits.length+")"'),
  @('title', 'return CUR.title.length+" chars: "+CUR.title'),
  @('bullets', 'return CUR.bullets.map(b=>b.length).join("/")+" chars :: "+CUR.bullets.join(" || ")'),
  @('backend', 'return utf8Bytes(CUR.backend)+" bytes (TextEncoder) / js length "+CUR.backend.length+": "+CUR.backend'),
  @('banned words in output', 'return "leaked="+CUR.leaked+" · regex recheck="+/best|guarantee|eco-friendly|cure|heal|fda approved/i.test(Object.values(window.__parts).join(" "))'),
  @('ex2', '$("#sample2Btn").click(); $("#runBtn").click(); const r="hits="+CUR.hits.map(h=>h.w).join(",")+" title="+CUR.title.length+" bullets="+CUR.bullets.length+" backend="+utf8Bytes(CUR.backend)+"B leaked="+CUR.leaked+" b4="+(CUR.bullets[3]||""); return r'),
  @('byte limit stress (300B of keywords)', 'const o=$("#kw").value; $("#kw").value=Array.from({length:60},(_,i)=>"keyword"+i).join(", "); $("#runBtn").click(); const r=utf8Bytes(CUR.backend)+" bytes, dropped "+CUR.droppedKw; $("#kw").value=o; $("#runBtn").click(); return r'),
  @('title limit stress', 'const o=$("#name").value; $("#name").value="Very Long Product Name ".repeat(12); $("#runBtn").click(); const r=CUR.title.length; $("#name").value=o; $("#sampleBtn").click(); $("#runBtn").click(); return "title len="+r'),
  @('copy all', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+" chars"')
)}
$CHECKS['globalship'] = @{ input = '#dest'; checks = @(
  @('US', 'return $("#sDocs").textContent+" docs / "+$("#sWarn").textContent+" warnings / tax "+$("#sTax").textContent'),
  @('US warnings', 'return CUR.warns.join(" | ")'),
  @('3 countries', 'const r=[];for(const k of ["US","JP","SG"]){load(k);run();r.push(k+": docs="+$("#sDocs").textContent+" warn="+$("#sWarn").textContent+" tax="+$("#sTax").textContent)} load("US");run();return r.join(" | ")'),
  @('JP estimate table', 'load("JP");run(); const t=$("#est").textContent; load("US");run(); return t.replace(/\s+/g," ").slice(0,200)'),
  @('rates are user input (blank -> not computed)', 'const o=$("#duty").value; $("#duty").value=""; run(); const t=$("#sTax").textContent+" / "+$("#estNote").textContent.slice(0,80); $("#duty").value=o; run(); return t'),
  @('fixed lines', 'return [...document.querySelectorAll(".fixnote")].map(e=>e.textContent).join(" || ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+" chars"')
)}
$CHECKS['digitalstore_en'] = @{ input = '#in'; checks = @(
  @('blocks', 'return CUR.B.length+" blocks: "+CUR.B.map(b=>b[0].split(" ·")[0]+"("+b[1].length+")").join(", ")'),
  @('FAQ 5', 'return (CUR.B[3][1].match(/^Q\d/gm)||[]).length+" Qs"'),
  @('license / refund draft', 'return CUR.B[4][1].split("\n")[2].slice(0,120)+" ... | "+CUR.B[5][1].split("\n")[1].slice(0,100)'),
  @('short <=160', 'return CUR.B[7][1].length+" chars: "+CUR.B[7][1]'),
  @('ex2 commercial / no refund', '$("#sample2Btn").click(); run(); const r=CUR.B[4][1].split("\n")[0]+" | "+CUR.B[5][1].split("\n")[1].slice(0,90); $("#sampleBtn").click(); run(); return r'),
  @('no invented features (benefits only from input)', 'const L=$("#what").value.split("\n").map(s=>s.trim().toLowerCase()); return String(CUR.B[2][1].split("\n").every(l=>L.some(x=>l.toLowerCase().includes(x.slice(1)))))'),
  @('pro review line', 'return document.querySelectorAll(".fixnote").length+" fixed notes · seller responsible="+/seller is responsible/.test(document.querySelector("#result").textContent)'),
  @('copy all', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+" chars"')
)}
