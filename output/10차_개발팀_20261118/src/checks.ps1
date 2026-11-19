# 앱별 검증식 (cap.ps1에서 읽음). 각 식은 async 함수 본문이며 return 값이 로그에 그대로 찍힘
$CHECKS = @{}
$CHECKS['pdf1p'] = @{ input = '#src'; checks = @(
  @('top5 (원문 인용 여부)', 'const S=$("#src").value; return CUR.top.length+"줄, 모두 원문 포함="+CUR.top.every(x=>S.includes(x.s.replace(/^\d+\.\s*/,"")))'),
  @('numbers', 'return CUR.nums.length+"건: "+CUR.nums.slice(0,8).map(n=>n.k+"="+n.v).join(", ")'),
  @('decisions', 'return CUR.decs.length+"건"'),
  @('terms', 'return CUR.terms.join(", ")'),
  @('3 examples', 'const r=[];for(const k of ["meeting","press","contract"]){setEx(k);run();r.push(k+": top="+CUR.top.length+" nums="+CUR.nums.length+" decs="+CUR.decs.length)} setEx("meeting");run();return r.join(" | ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+"자, 첫줄="+window.__lastCopy.split("\n")[0]'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('pdf text reader (uncompressed PDF)', 'const p="%PDF-1.4\n1 0 obj<</Length 99>>stream\nBT /F1 12 Tf (Meeting minutes: revenue 48,200,000 won rose 12.5%.) Tj T* (We will hire one more staff from 2026-12-01.) Tj ET\nendstream endobj"; const t=await readPdf(new TextEncoder().encode(p).buffer); return t.replace(/\n/g," / ")'),
  @('ai button hidden (no key)', 'return String($("#aiBtn").classList.contains("hide"))')
)}
$CHECKS['refstyle'] = @{ input = '#form'; checks = @(
  @('5 items x 4 styles', 'return LIST.length+" items, rows="+document.querySelectorAll(".fmt").length'),
  @('APA all', 'return sorted().map(r=>fmt(r).apa).join(" || ")'),
  @('KCI 3+ authors', 'return fmt(LIST[0]).kci'),
  @('MLA et al / short cite', 'return fmt(LIST[0]).mla+" / "+fmt(LIST[0]).cite.apa+" / "+fmt(LIST[1]).cite.mla'),
  @('missing value shown not guessed', 'return fmt({ty:"book",au:"",yr:"",ti:"제목만",co:""}).apa+" | "+fmt({ty:"book",au:"",yr:"",ti:"제목만",co:""}).kci'),
  @('sort ko', 'return sorted().map(r=>fmt(r).key).join(" < ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['feedbacksoft'] = @{ input = '#raw'; checks = @(
  @('bans', 'return CUR.bans.map(b=>b[0]+":"+b[1].join("/")).join(" | ")'),
  @('normal tone', 'return toneText(1).replace(/\n/g," ⏎ ")'),
  @('facts kept (4번·25분)', 'return String(/4번/.test(toneText(1))&&/25분/.test(toneText(1)))'),
  @('no invented praise (ex1 격려 placeholder)', 'return CUR.tones[1].parts[3][1].slice(0,30)'),
  @('5 examples', 'const r=[];for(let i=0;i<5;i++){setEx(i);run();r.push((i+1)+":bans="+CUR.bans.length+",격려="+(CUR.tones[1].parts[3][1][0]==="["?"빈칸":"원문"))}return r.join(" ")'),
  @('history saved', 'return LS.get("kts_feedbacksoft_v1",[]).length+" (max 20)"'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+"자"')
)}
$CHECKS['sopmaker'] = @{ input = '#memo'; checks = @(
  @('steps / amb / refs', 'return CUR.steps.length+" steps / 확인 필요 "+CUR.steps.filter(s=>s.amb).map(s=>s.t).join(",")+" / 참고 "+CUR.refs.join(",")'),
  @('no invented step', 'const L=$("#memo").value.split("\n").map(s=>s.trim()); return String(CUR.steps.every(s=>L.includes(s.t)))'),
  @('checkbox persist', 'document.querySelector("#steps input").click(); document.querySelectorAll("#steps input")[1].click(); return JSON.stringify(LS.get(CK(),{}))'),
  @('training log', '$("#tName").value="신입A"; $("#tBy").value="점장"; $("#tAdd").click(); return document.querySelectorAll("#tlog tr").length-1+" rows"'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n")[0]+" / "+window.__lastCopy.length+"자"')
)}
$CHECKS['compwatch'] = @{ input = '#la'; copy = '#csvBtn'; checks = @(
  @('set1', 'return $("#sRate").textContent+" match / 인상 "+$("#sUp").textContent+" 인하 "+$("#sDn").textContent+" 신규 "+$("#sNew").textContent+" 단종 "+$("#sGone").textContent+" 확인 "+$("#sAmb").textContent'),
  @('summary', 'return CUR.sum.join(" ⏎ ")'),
  @('amb pairs', 'return CUR.amb.map(m=>m.a.name+"↔"+m.b.name).join(", ")'),
  @('set2', '$("#s2").click(); run(); return $("#sRate").textContent+" match / 인상 "+$("#sUp").textContent+" 인하 "+$("#sDn").textContent+" 신규 "+$("#sNew").textContent+" 단종 "+$("#sGone").textContent+" 확인 "+CUR.amb.map(m=>m.a.name+"↔"+m.b.name).join(",")'),
  @('manual merge', 'document.querySelector("[data-m]").click(); return "after merge: "+$("#sRate").textContent+" 확인 "+$("#sAmb").textContent'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['listingcompare'] = @{ input = '#rows'; checks = @(
  @('all parsed', 'return ALL.length+" rows, bad="+ALL.filter(x=>x.bad).length'),
  @('평 환산·평당가 (84.5㎡ 9억5000)', 'const x=ALL[0]; return x.a.py.toFixed(2)+"평 / 평당가 "+Math.round(x.ppy)+"만원 (검산 95000/(84.5/3.3058)="+Math.round(95000/(84.5/3.3058))+")"'),
  @('sorted by ppy', 'return CUR.L.map(x=>Math.round(x.ppy)).join(" < ")'),
  @('filter 가격≤90000 면적≥20평 상가', '$("#fMax").value="90000";$("#fMin").value="20";$("#fUse").value="상가";run(); return CUR.L.length+"건: "+CUR.L.map(x=>x.addr.split(" ").slice(-2).join(" ")+" "+Math.round(x.ppy)).join(", ")'),
  @('gap', 'return CUR.L.map(x=>x.reg+" "+(x.gap===0?"최저":"+"+(x.gap*100).toFixed(1)+"%")).join(", ")'),
  @('PII removed from table', '$("#fMax").value="";$("#fMin").value="";$("#fUse").value="";run(); const t=document.querySelector("#list").textContent; return "phone="+/010-/.test(t)+" 김철수="+/김철수/.test(t)+" 박영희="+/박영희/.test(t)'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['newssentiment'] = @{ input = '#news'; checks = @(
  @('articles / sentences', 'return CUR.arts.length+" arts / "+CUR.all.length+" sents"'),
  @('ticker table', 'return CUR.T.map(t=>t.tk+" +"+t.pos+"/-"+t.neg+"/="+t.neu).join(" | ")'),
  @('negative sentences', 'return CUR.all.filter(s=>s.k==="neg").length+": "+CUR.all.filter(s=>s.k==="neg").slice(0,3).map(s=>s.s).join(" / ")'),
  @('denial -> neutral', 'return CUR.all.filter(s=>/확인되지 않/.test(s.s)).map(s=>s.k).join(",")'),
  @('no buy/sell advice', 'return "매수/매도/목표가 in result text: "+/매수하|매도하|목표가는|사야|팔아야/.test(document.querySelector("#result").textContent.replace("매수·매도 판단이나 목표가를 제시하지 않습니다",""))'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").slice(0,3).join(" / ")')
)}
$CHECKS['jobfit'] = @{ input = '#posts'; checks = @(
  @('parsed', 'return CUR.P.map(p=>p.title.split(" · ")[0]+" D"+(p.dleft==null?"?":p.dleft)).join(" → ")'),
  @('compare', 'return CUR.P.map(p=>p.cmp.map(r=>r[0]+":"+r[1]).join("/")).join(" | ")'),
  @('pay as original', 'return CUR.P.map(p=>p.pay).join(" | ")'),
  @('fix sentences', 'return document.querySelectorAll(".fix").length+": "+[...document.querySelectorAll(".fix")].slice(0,2).map(e=>e.textContent).join(" / ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['hashtagreport'] = @{ input = '#in'; checks = @(
  @('counts', 'return CUR.all.map(a=>a[0]+"="+a[1].length+"(uniq "+new Set(a[1]).size+")").join(" ")+" crossDup="+(CUR.all.flatMap(a=>a[1]).length-new Set(CUR.all.flatMap(a=>a[1])).size)'),
  @('sets', 'return CUR.sets.map(s=>s[0]+":"+s[1].length).join(" | ")'),
  @('flagged', 'return CUR.flagged.map(f=>f[1]+"("+f[2][1]+")").join(", ")'),
  @('narrow sample', 'return CUR.all[2][1].slice(0,8).join(" ")'),
  @('3 examples', 'const r=[];for(let i=0;i<3;i++){setEx(i);run();r.push((i+1)+":"+CUR.all.map(a=>a[1].length).join("/")+" flag="+CUR.flagged.length)}setEx(0);run();return r.join(" | ")'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['surveyclassify'] = @{ input = '#csv'; checks = @(
  @('types', 'return CUR.Q.map(q=>q.h+"="+q.type).join(", ")'),
  @('scale', 'return CUR.Q.filter(q=>q.type==="scale").map(q=>q.h+" mean "+q.mean.toFixed(2)+" med "+q.med).join(" | ")'),
  @('keyword groups', 'return CUR.Q.filter(q=>q.type==="text").map(q=>q.groups.map(g=>g.w+g.c).join(",")).join(" | ")'),
  @('masking (screen)', 'const t=document.querySelector("#result").textContent; return "full phone="+/010-0000-\d{4}/.test(t)+" 김민수="+/김민수/.test(t)+" 7777 masked="+/010-\*\*\*\*-7777/.test(t)'),
  @('bad responses', 'return CUR.bad.length'),
  @('summary', 'return CUR.sum.join(" ⏎ ")'),
  @('csv masked', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['seasontrend'] = @{ input = '#in'; copy = '#csvBtn'; checks = @(
  @('count / groups', 'return total()+" = 구매 "+CUR.out.구매의도.length+" + 정보 "+CUR.out.정보탐색.length+" + 지역 "+CUR.out.지역.length'),
  @('unique', 'const a=Object.values(CUR.out).flat(); return "dup="+(a.length-new Set(a.map(k=>k.replace(/\s/g,""))).size)'),
  @('sample', 'return CUR.out.구매의도.slice(0,4).concat(CUR.out.정보탐색.slice(0,3),CUR.out.지역.slice(0,3)).join(" | ")'),
  @('exclusion works', '$("#seed").value="허리 치료, 다이슨 청소기, 전기요"; run(); return "seedBad="+JSON.stringify(CUR.seedBad)+" total="+total()+" contains 치료/다이슨="+Object.values(CUR.out).flat().some(k=>/치료|다이슨/.test(k)); '),
  @('restore + csv', '$("#sampleBtn").click(); run(); $("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n").length+" lines"')
)}
$CHECKS['b2blist'] = @{ input = '#in'; copy = '#csvBtn'; checks = @(
  @('segments', 'return CUR.segs.length+": "+CUR.segs.slice(0,4).map(s=>s.ind+"/"+s.z+"="+s.score).join(", ")'),
  @('openings', 'return document.querySelectorAll("#opens .say").length+" openings"'),
  @('objections', 'return document.querySelectorAll("#objs .item").length'),
  @('no fake company/phone', 'return "phone="+/0\d{1,2}-\d{3,4}-\d{4}/.test(document.querySelector("#result").textContent)+" (주)="+/\(주\)/.test(document.querySelector("#result").textContent)'),
  @('csv', '$("#csvBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+"자"')
)}
$CHECKS['ghtrend'] = @{ input = '#src'; checks = @(
  @('repos', 'return CUR.R.map(r=>r.name+"("+(r.lic||"없음")+","+r.age+"d)").join(", ")'),
  @('this week changes', 'return CUR.R.filter(r=>r.week.length).map(r=>r.name+":"+r.week.length).join(", ")'),
  @('warnings', 'return CUR.R.map(r=>r.warn.length).join(",")+" | "+CUR.R[3].warn.join(" / ")'),
  @('license never asserted ok', 'return String(document.querySelectorAll("#tbl .pill.b").length)+" 확인 필요 pills"'),
  @('use 3', 'return CUR.use.join(" || ")'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.length+"자"')
)}
$CHECKS['icsmaker'] = @{ input = '#rows'; copy = '#dlBtn'; checks = @(
  @('events', 'return CUR.ev.length+" ev, alarms="+$("#sA").textContent+", err="+CUR.err.length'),
  @('required fields', 'const t=CUR.ics; return ["BEGIN:VCALENDAR","VERSION:2.0","BEGIN:VEVENT","UID:","DTSTAMP:","DTSTART","DTEND","SUMMARY:","LOCATION:","DESCRIPTION:","END:VCALENDAR","TZID:Asia/Seoul","BEGIN:VALARM"].map(k=>k+"="+(t.split(k).length-1)).join(" ")'),
  @('CRLF only', 'const t=CUR.ics; return "CRLF="+(t.match(/\r\n/g)||[]).length+" bareLF="+(t.replace(/\r\n/g,"").match(/\n/g)||[]).length'),
  @('line <=75 bytes', 'const enc=new TextEncoder(); return "maxLineBytes="+Math.max(...CUR.ics.split("\r\n").map(l=>enc.encode(l).length))'),
  @('allday + timed', 'return CUR.ics.split("\r\n").filter(l=>/^DTSTART/.test(l)).join(" | ")'),
  @('bad line rejected', '$("#rows").value="잘못된 줄 | 12월 3일 | 10시"; run(); const e=CUR.err.join(" / "); $("#sampleBtn").click(); run(); return e'),
  @('download', '$("#dlBtn").click(); return JSON.stringify(window.__lastDownload)')
)}
$CHECKS['memotask'] = @{ input = '#memo'; copy = '#icsBtn'; checks = @(
  @('split', 'return "일정 "+$("#sE").textContent+" / 할 일 "+$("#sT").textContent+" / 기타 "+$("#sX").textContent'),
  @('interpretations', 'return CUR.R.map(r=>r.k[0]+":"+interp(r)).join(" | ")'),
  @('places / people', 'return CUR.R.filter(r=>r.place||r.ppl.length).map(r=>(r.place||"-")+"/"+(r.ppl.join("+")||"-")).join(", ")'),
  @('ambiguous kept undated', 'return CUR.R.filter(r=>r.amb).map(r=>r.s+" → "+(r.d?"날짜 지정됨(오류)":"날짜 없음")).join(", ")'),
  @('ics', '$("#icsBtn").click(); return JSON.stringify(window.__lastDownload)'),
  @('todo check persist', 'document.querySelector("#tds input").click(); return JSON.stringify(LS.get("kts_memotask_done",{}))'),
  @('copy', '$("#copyBtn").click(); await new Promise(r=>setTimeout(r,200)); return window.__lastCopy.split("\n")[0]+" ... "+window.__lastCopy.length+"자"')
)}
