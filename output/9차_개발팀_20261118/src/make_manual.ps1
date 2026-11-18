# 상품별 사용설명서 1장: 390px 실제 캡처 3장(① 누르는 곳 ② 입력 ③ 결과) 위에 캡처 때 실제로 누른 자리(marks.json) 표시
# 출력: output/9차_개발팀_20261118/{앱}_설명서.html + {앱}_설명서.md (+ 1쪽 확인용 files/{앱}_설명서.pdf)
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$C = [ordered]@{
 faqbot = @('FAQ 챗봇 설정 생성기', 'faqbot.html', '매장 정보를 넣으면 손님이 물을 질문 40개와 답변, 카톡 채널·홈페이지·DM에 붙일 설정 JSON이 나옵니다. 답변은 넣은 내용만 쓰고, 빈 칸은 "매장으로 문의" 안내로 고정됩니다.',
   '[예시 매장 넣기]를 누르세요. 내 매장이면 상호·전화와 영업시간·주차·배달·예약·환불 칸을 적습니다(모르는 칸은 비워 둡니다).',
   '채운 내용을 확인하고 [질문 40개 · 답변 만들기]를 누릅니다.',
   '질문 40개와 답변이 나옵니다. [설정 JSON 복사] · [CSV 저장] · [인쇄 · PDF] 중 하나로 가져가세요. 아래 "손님처럼 물어보기"로 답이 맞는지 시험할 수 있습니다.')
 csreply = @('CS 문의 분류 · 모범 답안', 'csreply.html', '고객 문의 글을 붙여 넣으면 유형(배송·교환/환불·결제·품질·일정)과 감정 온도를 읽고, 사과 → 사실 확인 → 다음 행동과 처리 기한 순서의 3문장 답안을 만듭니다. 보상·환불 금액은 [금액] 빈칸으로 남깁니다.',
   '예시 문의 단추(배송 지연 등)를 누르거나 받은 문의를 그대로 붙여 넣으세요.',
   '상호·담당자와 답변 톤(정중·간결·친근)을 고르고 [분류하고 답안 만들기]를 누릅니다.',
   '유형·감정·고객 이름·주문번호·처리 기한이 표시되고 답안이 나옵니다. 칸에서 고친 뒤 [답안 복사], [이력에 저장](최근 20건)을 누르세요.')
 leadscore = @('가망 고객 스코어링', 'leadscore.html', '설문·문의 응답을 넣으면 구매 의향 점수(0~100), 등급 A/B/C/D, 근거 3줄, 우선 연락 순서, 상위 10명 전화 멘트가 나옵니다. 점수 규칙(예산 25 · 시기 20 · 담당/대표 15 · 연락처 15 · 요청 2개+ 15 · 과거 문의 10)은 화면에 공개됩니다.',
   '[샘플 20건 넣기]를 누르거나 엑셀·구글시트에서 복사한 응답을 붙여 넣으세요. 한 명씩은 [폼으로 1명 추가]로 넣습니다.',
   '붙여 넣은 표를 확인하고 [점수 매기고 순서 정하기]를 누릅니다.',
   '등급별 인원과 연락 순서표가 나옵니다. [CSV 저장]으로 받고, [멘트 10개 복사]로 전화할 때 쓰세요. 아래로 내리면 고객별 근거 3줄이 있습니다.')
 kakaotalk = @('카카오톡 채널 1차 응대 시나리오', 'kakaotalk.html', '업종만 고르면 첫 인사, 자주 묻는 5가지, 예약·주문 접수 흐름, 상담원 인계 멘트, 야간 자동응답 문구가 나옵니다. 자동 발송·자동 예약 확정 문구는 만들지 않습니다(안내·접수까지만).',
   '업종 프리셋(음식점·미용실·학원·병의원·쇼핑몰) 중 하나를 누르세요. 상호·전화·영업시간·대표 상품 3개가 채워집니다.',
   '내 매장에 맞게 고치고, 카카오톡 채널 주소(pf.kakao.com)·홈페이지를 넣은 뒤 [응대 시나리오 만들기]를 누릅니다.',
   '단계별 말풍선 문구가 나옵니다. 칸마다 [복사], 전체는 [전체 복사], 문서로는 [인쇄 · PDF]. 채널 관리자센터 자동응답에 붙여 넣으세요.')
 weeksummary = @('주간 개선 요약 리포트', 'weeksummary.html', '한 주치 리뷰·설문·문의 텍스트를 줄 단위로 붙여 넣으면 반복 불만 TOP5(건수·원문 인용), 좋은 점 TOP3, 이번 주 개선 액션 3개, 다음 주 확인 지표를 만듭니다. 원문 인용은 그대로 두고, 전화·이메일만 자동으로 가립니다.',
   '[샘플 30줄 넣기]를 누르거나 리뷰·설문을 한 줄에 하나씩 붙여 넣으세요.',
   '매장 이름·기간을 확인하고 [주간 요약 만들기]를 누릅니다.',
   '불만 TOP5와 원문 인용이 나옵니다. 액션마다 담당·기한을 적고 [리포트 복사] · [CSV 저장] · [인쇄]로 가져가세요.')
 booking = @('KTS 더예약 — 예약 장부 + 노쇼 방지 문구', 'booking.html', '예약 메모·문자를 붙여 넣으면 날짜·시간·이름·연락처·인원을 시간순 표로 만들고, 전날 확인이 없거나 노쇼·취소 이력이 있는 예약을 표시합니다. 예약 확인·전날 리마인드·노쇼 안내 문구 3종을 만들고, 오늘 예약만 한 장으로 인쇄합니다.',
   '[샘플 20건 넣기]를 누르거나 예약 메모를 한 줄에 1건씩 붙여 넣으세요("오늘 저녁 7시 반 홍길동 2명 010-…").',
   '상호·매장 전화를 확인하고 [장부로 정리하기]를 누릅니다.',
   '시간순 장부와 위험 표시가 나옵니다. [오늘 예약 1장 인쇄], 줄을 눌러 고른 예약의 문구 3종을 [복사]하세요. 문자는 사장님이 직접 보냅니다.')
 visitlog = @('KTS 더방문 — 고객 방문·AS 이력 카드', 'visitlog.html', '고객별 방문·AS 기록(이름·연락처·방문일·내용·다음 연락일)을 적으면 고객 카드, 연락일이 지난 고객, 이번 달 방문 수, 오늘 연락할 5명을 보여 줍니다. 기록은 이 기기에만 저장되고 JSON 파일로 백업·복원합니다.',
   '처음이면 [샘플 고객 10명 넣기]를 누르세요.',
   '이름·내용을 적고 다음 연락일은 [+1주]·[+3달] 같은 단추로 고른 뒤 [기록 저장]을 누릅니다(같은 이름이면 연락처는 자동으로 채움).',
   '오늘 연락할 5명과 고객 카드가 나옵니다. [5명 목록 복사]·[인쇄]로 쓰고, 아래 [JSON 내보내기]로 꼭 백업하세요.')
 funnel3 = @('KTS 더퍼널 — 3단 문자 퍼널 문구', 'funnel3.html', '업종·상호·혜택·연락처를 넣으면 1차(첫 안내)·2차(3일 뒤)·3차(마지막) 문구를 만들고, 모든 문구에 (광고)·전송자·무료수신거부를 자동으로 넣습니다. 글자 수(바이트)·SMS/LMS·예상 요금을 보여 줍니다. 이 화면은 문자를 보내지 않습니다.',
   '업종 단추(음식점 등)를 누르세요. 상호·연락처·혜택·마감일이 채워집니다.',
   '혜택·수신거부 번호·받는 사람 수·건당 요금을 확인하고 [3단 문구 만들기]를 누릅니다.',
   '문구 3통과 바이트·요금, 광고 표기 확인이 나옵니다. [3통 모두 복사] 또는 [인쇄 · 승인용]으로 대표님 승인을 받은 뒤 직접 발송하세요.')
 listing = @('KTS 더매물 — 매물 A4 브리핑 시트', 'listing.html', '매물 정보(소재지·면적·가격·교환 조건)와 사진 5장을 넣으면 5대 사진 배치, 교환 포인트 3줄, 상대방 결핍 카드가 들어간 A4 한 장이 나옵니다. 실명·개인 연락처는 시트에 넣지 않고(이니셜·지역만), "권리관계는 등기부등본 확인" 문구가 고정됩니다.',
   '[샘플 매물 1건 넣기]를 누르거나 제목·유형·소재지(동까지)·면적·희망가를 적으세요.',
   '교환 포인트 3줄, 상대방 결핍 카드, 사진 5칸(전경·진입로·내부·주변·지도)을 채우고 [A4 브리핑 시트 만들기]를 누릅니다.',
   'A4 미리보기가 나옵니다. [인쇄 · PDF 저장]으로 한 장을 뽑고, [요약 문구 복사]로 메신저에 붙이세요.')
 docs = @('KTS 더제출 — 제출서류 세트 점검표', 'docs.html', '상황(사업자 등록·법인 설립·임대차·대출·폐업)을 고르면 필요한 서류, 발급처·소요시간·수수료, 빠뜨리기 쉬운 서류 3개, 진행 순서, 공식 사이트가 나옵니다. 서류 목록은 일반 안내이며 기관별로 다를 수 있습니다.',
   '내 상황 단추(사업자 등록 등)를 누르세요.',
   '준비한 서류를 체크합니다. 체크 상태는 이 기기에 저장되어 다음에 열어도 그대로입니다.',
   '남은 서류 개수가 보입니다. [오늘 준비물 1장 인쇄]로 들고 가고, [목록 복사]로 메모에 붙이세요.')
}
Start-CdpChrome 9395 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  foreach ($app in $C.Keys) {
    $d = $C[$app]; $sd = Join-Path $OUT ("shots\" + $app)
    $marks = [IO.File]::ReadAllText((Join-Path $sd 'marks.json'), [Text.Encoding]::UTF8)
    $steps = @(@('01_press', '① 누르는 곳', $d[3]), @('02_input', '② 입력', $d[4]), @('03_result', '③ 결과', $d[5]))
    $stepsJson = ConvertTo-Json -InputObject @($steps | ForEach-Object { , @($_) }) -Depth 4 -Compress
    $html = @"
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>$($d[0]) 사용설명서</title>
<style>
@page{size:A4;margin:10mm}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Malgun Gothic","Apple SD Gothic Neo",sans-serif;color:#111;font-size:10pt;line-height:1.5;max-width:760px;margin:0 auto;padding:8px;word-break:keep-all}
.cover{background:#0A1128;color:#fff;border-radius:10px;padding:14px 16px;margin-bottom:10px}
.cover h1{font-size:17pt;letter-spacing:-.8px}.cover h1 small{font-size:9.5pt;color:#FFA24D;margin-left:6px}
.cover p{color:#C9D3E3;margin-top:6px;font-size:9.5pt}
.legend{display:flex;gap:16px;font-size:9pt;color:#444;margin:0 0 8px}
.steps{display:flex;gap:10px}
.st{flex:1;min-width:0}
.st h2{font-size:12pt;color:#0A1128;border-left:4px solid #FF6B00;padding-left:7px;margin-bottom:5px}
.shot{position:relative;width:100%;border-radius:12px;overflow:hidden;border:2px solid #0A1128}
.shot img{display:block;width:100%}
.st p{font-size:9.4pt;color:#333;margin-top:6px}
.ring{position:absolute;border:3px solid #FF6B00;border-radius:10px;box-shadow:0 0 0 2px rgba(255,255,255,.85);margin:-3px 0 0 -3px;padding:3px;box-sizing:content-box}
.tap{position:absolute;width:28px;height:28px;margin:-14px 0 0 -14px;border-radius:50%;background:rgba(255,107,0,.35);border:3px solid #FF6B00}
.fing{position:absolute;width:26px;height:32px;margin:2px 0 0 -4px}
.lbl{position:absolute;font-size:7.5pt;font-weight:700;color:#fff;background:#FF6B00;border-radius:4px;padding:0 4px;white-space:nowrap}
.foot{font-size:8.5pt;color:#666;margin-top:8px;border-top:1px solid #ddd;padding-top:6px}
</style></head><body>
<div class="cover"><h1>$($d[0]) 사용설명서<small>oneclick/$($d[1])</small></h1><p>$($d[2])</p></div>
<div class="legend"><span>● 주황 원 + 손가락 = 여기를 누르세요</span><span>□ 주황 테두리 = 여기를 보세요</span><span>화면은 390px 휴대폰 실제 캡처</span></div>
<div class="steps" id="list"></div>
<p class="foot">KTS 원클릭 · 입력하신 내용은 이 기기 안에서만 처리됩니다 · 서버 0 · 외부 발송 0 · 화면 맨 아래 [60초 문의 폼 열기]로 이름·연락처·문의를 남길 수 있습니다.</p>
<script>
const MARKS = $marks;
const STEPS = $stepsJson;
const fing = '<svg class="fing" viewBox="0 0 30 36"><path d="M9 3c1.7 0 3 1.3 3 3v10l1-.2V12c0-1.6 1.3-2.8 2.8-2.8S18.6 10.4 18.6 12v4l.8-.1c1.5 0 2.7 1.2 2.7 2.7v1l.6-.1c1.5 0 2.8 1.2 2.8 2.8V26c0 4.4-3.6 8-8 8h-3.3c-2.6 0-5-1.3-6.4-3.4L3.3 24c-.9-1.3-.6-3 .7-3.9 1.2-.8 2.8-.6 3.7.5L6 21V6c0-1.7 1.3-3 3-3z" fill="#fff" stroke="#0A1128" stroke-width="1.6"/></svg>';
const byShot = {}; (Array.isArray(MARKS) ? MARKS : [MARKS]).forEach(m => byShot[m.shot] = m.marks || []);
document.getElementById('list').innerHTML = STEPS.map(([shot, h, p]) => '<div class="st"><h2>' + h + '</h2><div class="shot" data-s="' + shot + '"><img src="shots/$app/' + shot + '.png"></div><p>' + p + '</p></div>').join('');
function draw(){ document.querySelectorAll('.shot').forEach(el => {
  const X = v => (v / 390 * 100).toFixed(2) + '%', Y = v => (v / 844 * 100).toFixed(2) + '%'; let ov = '';
  (byShot[el.dataset.s] || []).forEach(m => {
    if (!m || m.y > 844 || m.y + m.h < 0) return;
    if (m.kind === 'tap'){ const cx = X(m.x + m.w / 2), cy = Y(m.y + m.h / 2); ov += '<div class="tap" style="left:' + cx + ';top:' + cy + '"></div><div style="position:absolute;left:' + cx + ';top:' + cy + '">' + fing + '</div>'; }
    else { const y0 = Math.max(0, m.y), y1 = Math.min(844, m.y + m.h); ov += '<div class="ring" style="left:' + X(m.x) + ';top:' + Y(y0) + ';width:' + X(m.w) + ';height:' + Y(y1 - y0) + '"></div>'; }
    if (m.note) ov += '<div class="lbl" style="left:' + X(Math.max(2, Math.min(300, m.x))) + ';top:calc(' + Y(Math.max(0, m.y)) + ' - 15px)">' + m.note + '</div>';
  });
  el.querySelectorAll('.ov').forEach(x => x.remove()); const d = document.createElement('div'); d.className = 'ov'; d.innerHTML = ov; el.appendChild(d); }); }
window.addEventListener('load', draw);
</script></body></html>
"@
    $hp = Join-Path $OUT ($app + '_설명서.html')
    [IO.File]::WriteAllText($hp, $html, (New-Object Text.UTF8Encoding($false)))
    $md = @"
# $($d[0]) 사용설명서

- 앱: ``oneclick/$($d[1])`` (단일 HTML · 설치 없음 · 서버 0)
- $($d[2])
- 입력하신 내용은 이 기기 안에서만 처리됩니다.

## ① 누르는 곳
![① 누르는 곳](shots/$app/01_press.png)

$($d[3])

## ② 입력
![② 입력](shots/$app/02_input.png)

$($d[4])

## ③ 결과
![③ 결과](shots/$app/03_result.png)

$($d[5])

## 60초 문의
화면 맨 아래 **[60초 문의 폼 열기]** 를 누르면 KTS 60초 접수 폼(``misa-1116/form.html``)이 열립니다. 이름·연락처·문의만 남기면 됩니다.

> 390px 실물 캡처: ``390_$app.png`` · 실제로 누른 자리 기록: ``shots/$app/marks.json`` · 검증 로그: ``shots/$app/run_log.txt``
"@
    [IO.File]::WriteAllText((Join-Path $OUT ($app + '_설명서.md')), $md, (New-Object Text.UTF8Encoding($false)))
    Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $hp) } | Out-Null; Start-Sleep -Milliseconds 1800
    $broken = Invoke-Js "JSON.stringify([...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.getAttribute('src')))"
    $nm = Invoke-Js "String(document.querySelectorAll('.tap,.ring').length)"
    $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
    $pdf = Join-Path $OUT ("files\" + $app + "_설명서.pdf"); [IO.File]::WriteAllBytes($pdf, [Convert]::FromBase64String($r['data']))
    $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf)); $pages = ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count
    Write-Output ($app + " manual: pages=" + $pages + " marks=" + $nm + " brokenImages=" + $broken)
  }
} finally { Stop-CdpChrome }
