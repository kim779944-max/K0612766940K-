# 사용설명서(HTML → PDF): 390px 실제 캡처 위에, 캡처 때 기록한 실제 누른 자리(marks.json)에 손가락·오렌지 원 표시
param([ValidateSet('riskcheck', 'expense', 'quote', 'letter')][string]$app = 'riskcheck')
. "$PSScriptRoot\pmlib.ps1"
$dir = Join-Path $global:PM2 $app
$C = @{
 riskcheck = @{ title = '독소조항 1초 검토기 사용설명서'; lead = '받은 계약서의 조항을 붙여 넣으면 자동 연장·일방 해지·과도한 위약금·책임 면제 같은 위험 조항을 표로 짚고, 상대에게 보낼 수정 요청 문구까지 만들어 드립니다. 본 검토는 작성 보조용이며 법률 자문이 아닙니다. 효력 판단은 변호사·공인중개사 확인이 필요합니다.';
  steps = @(
   @('01_start', '1. 시작', '처음이면 [부동산 매매 · 주택 임대차 · 상가건물 임대차] 예시 단추로 먼저 해 보세요. 위쪽 고지문은 항상 고정되어 보입니다.'),
   @('02_typed', '2. 조항 붙여넣기', '받은 계약서 조항을 그대로 붙여 넣으면 제1조·1)·①·[특약] 번호를 찾아 조항별로 자르고, 몇 개로 잘랐는지 바로 알려 줍니다.'),
   @('03_sample_sale', '2-1. 계약서 이름과 내 입장', '계약서 이름은 요약지 머리글이 됩니다. 내 입장(을: 매수인·임차인 / 갑: 매도인·임대인)을 고르면 그쪽에 불리한 조항을 찾습니다.'),
   @('04_review_sale', '3. 검토 결과', '[다음: 검토]를 누르면 위험 등급별 개수(높음·보통·낮음)가 나옵니다. 높음은 서명 전에 꼭 바꿔 달라고 하세요.'),
   @('05_table_sale', '3-1. 검토표', '조항 번호 · 원문 발췌(걸린 말은 주황 표시) · 위험 등급 · 왜 위험한지 · 바꿔 쓸 문구가 한 칸씩 나옵니다. 체크한 조항만 수정 요청에 들어갑니다.'),
   @('06_ai_nokey', '3-2. AI 쉽게 풀기(선택)', '내 제미나이 무료 열쇠가 있을 때만 해설을 더 쉽게 풀고, 기준표에 없는 조항의 위험도를 추정합니다. 열쇠가 없으면 안내만 나오고 나머지는 그대로 됩니다.'),
   @('07_request', '4. 수정 요청 문구', '상대에게 보낼 문구가 자동으로 만들어집니다. 칸에서 바로 고친 뒤 [복사]를 눌러 문자·메신저에 붙여 넣으세요. 앱이 직접 보내지는 않습니다.'),
   @('08_summary_preview', '5. 검토 요약 1장', '[요약 인쇄 · PDF]를 누르면 검토 결과가 A4 한 장으로 나옵니다. 계약 자리에 들고 가세요.'),
   @('04_review_house', '6. 주택 임대차 예시', '자동 연장, 중도 해지 금지, 입주 당시 그대로 원상복구, 새 세입자가 들어와야 보증금 반환 — 네 곳이 높음으로 잡힙니다.'),
   @('05_table_shop', '7. 상가 임대차 예시', '계약 종료 후 5년 경업 금지, 민·형사상 책임 면제, 보증금 2배 위약금 등이 잡힙니다.'),
   @('09_contract_html_house', '8. 계약서 생성기와 함께', '계약서 1초 생성기(contract.html)로 만든 계약서를 붙여 넣어도 검토됩니다. 공정한 기본 조항은 대부분 걸리지 않고, 원상복구처럼 확인할 곳만 보통으로 나옵니다.'),
   @('90_inquiry', '9. 60초 문의', '필요한 계약서 종류를 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.'));
  wide = @(@('print_layout_sale.png', '부록. 인쇄되는 검토 요약 1장(매매 예시)', 'A4 한 장에 계약서 이름·검토일·내 입장·등급별 개수와 검토표, 다음 할 일, 고지문이 들어갑니다.')) }
 expense = @{ title = '지출결의서 1초 정리 사용설명서'; lead = '봉투에 모아 둔 영수증·세금계산서를 사진으로 넣으면 장마다 한 줄로 정리되고, 합계·부가세가 자동으로 검산된 지출결의서 엑셀(.xlsx)과 인쇄용 PDF가 바로 나옵니다. 사진과 값은 이 기기 브라우저 안에만 저장됩니다.';
  steps = @(
   @('01_start', '1. 영수증 사진 넣기', '[영수증 사진 넣기]를 누르고 사진을 한 번에 여러 장 고르세요. 사진 글자 읽기는 내 제미나이 무료 열쇠가 있을 때만 되고, 없으면 직접 넣습니다.'),
   @('02_cards_empty', '2. 사진 1장 = 1줄', '사진마다 한 줄(카드)이 생깁니다. 왼쪽 사진을 보면서 일자·증빙·거래처·합계·용도를 넣으세요.'),
   @('03_cards_filled', '3. 부가세 자동', '합계(결제액)를 넣으면 부가세가 1/11로 자동 계산되고(간이영수증은 0원), 줄마다 "공급가액 + 부가세 = 합계" 검산이 바로 보입니다.'),
   @('04_fix_total', '4. 고치기 · 전체 검산', '[다음: 고치기]에서 전체 공급가액·부가세·총합계와 "검산 일치"를 확인합니다.'),
   @('05_dup', '4-1. 중복 의심', '같은 날·같은 거래처·같은 금액이 두 번 들어가면 노란 테두리와 [중복 의심] 표시가 나옵니다. [삭제]로 지우세요.'),
   @('06_missing', '4-2. 빠진 값', '빠진 칸은 빨간 테두리로 보이고, 단계 이름 옆에 빠진 칸 수가 나옵니다.'),
   @('07_vat_check', '4-3. 부가세 확인', '과세 증빙인데 부가세가 1/11과 다르면 [부가세 확인] 표시가 나옵니다. [1/11]을 누르면 다시 계산합니다(면세 품목이면 그대로 두세요).'),
   @('08_check_ok', '4-4. 검산 일치', '공급가액 합계 + 부가세 합계 = 총 지출 합계가 맞으면 초록색 "검산 일치"가 나옵니다.'),
   @('09_form_general', '5. 결의서 서식 3종', '일반 · 출장 · 접대 중 고르고 결의 제목·작성자·부서·작성일을 넣습니다.'),
   @('12_form_trip', '5-1. 출장 서식', '출장지 · 출장 기간 · 출장 목적 칸이 더 생깁니다.'),
   @('12_form_ent', '5-2. 접대 서식', '접대 상대 · 인원 · 접대 목적 칸이 더 생깁니다.'),
   @('10_export', '6. 내보내기', '[엑셀(.xlsx) 저장]은 공급가액·합계 줄에 수식이 들어간 파일을, [인쇄 · PDF]는 A4 한 장 결의서를 만듭니다. [증빙 사진 목록도 인쇄]를 켜면 사진 목록이 붙임으로 한 장 더 나옵니다.'),
   @('11_preview_general', '6-1. 결의서 미리보기', '결재란(담당·팀장·대표), 지출 내역, 합계, 작성자 서명란이 인쇄 모양 그대로 보입니다.'),
   @('open_지출결의서_11월영업팀경비_20261118_xlsx', '7. 저장한 엑셀 확인', '저장한 파일은 더뷰(viewer.html)나 엑셀에서 바로 열립니다. 숫자 칸은 43,636처럼 쉼표가 붙어 보입니다.'),
   @('90_inquiry', '8. 60초 문의', '필요한 서식을 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.'));
  wide = @(@('print_layout_general.png', '부록. 인쇄되는 지출결의서(일반 서식)', '영수증 3장 예시: 공급가액 179,436 + 부가세 16,364 = 합계 195,800원. A4 한 장에 결재란·내역·합계·서명란이 들어갑니다.')) }
 quote = @{ title = '견적서 1초 발행 사용설명서'; lead = '내 정보는 한 번만 저장하고, 고객과 품목만 넣으면 2026-0001 같은 번호가 붙은 A4 한 장 견적서가 인쇄(PDF)·한글(.hwpx)로 바로 나옵니다. 번호는 이 기기의 발행 대장에 기록되어 같은 번호가 다시 나오지 않습니다.';
  steps = @(
   @('01_me_empty', '1. 내 정보(처음 1번)', '상호·대표자·사업자등록번호·주소·연락처를 넣습니다. 이메일·입금 계좌는 넣으면 견적서에 함께 나옵니다.'),
   @('02_me_filled', '1-1. 내 정보 저장', '[내 정보 저장]을 누르면 이 기기에 보관되고, 다음 견적부터는 바로 품목 단계에서 시작합니다.'),
   @('03_cond', '2. 고객과 조건', '고객명·견적일을 넣고 유효기간은 [D+30] 같은 단추로 고릅니다. 부가세 별도/포함, 결제조건, 비고를 정합니다.'),
   @('04_items', '3. 품목', '품명·규격·수량·단가를 넣으면 금액이 자동으로 나옵니다. [+ 품목]으로 줄을 늘리고 [−]로 지웁니다. 아래에 공급가액·부가세·합계와 한글 금액이 나옵니다.'),
   @('08_vat_included', '3-1. 부가세 포함', '[부가세 포함]을 고르면 합계 110,000원 → 공급가액 100,000 + 부가세 10,000으로 거꾸로 나눕니다.'),
   @('05_before_issue', '4. 발행 전', '미리보기에는 "발행 전(다음 2026-0001)"으로 보입니다. [발행(번호 받기)]을 누를 때 번호가 확정됩니다.'),
   @('06_issued', '4-1. 발행', '번호가 확정되면 [인쇄 · PDF]와 [한글(.hwpx)]이 그 번호로 나옵니다. [인쇄]만 눌러도 번호를 자동으로 받습니다.'),
   @('07_preview', '5. 견적서 미리보기', 'A4 한 장에 견적번호·견적일·유효기간·고객·공급자·합계금액(한글)·품목·결제조건이 들어갑니다.'),
   @('09_ledger', '6. 발행 대장', '발행한 견적이 번호·고객·금액으로 쌓입니다. 같은 견적에 [발행]을 다시 눌러도 번호가 늘지 않습니다.'),
   @('10_edited_after_issue', '6-1. 발행 뒤 고치면', '발행한 뒤 내용을 고치면 이미 쓴 번호를 다시 쓰지 않고 새 번호로 발행하도록 안내합니다.'),
   @('open_견적서_2026-0001_hwpx', '7. 저장한 한글 파일 확인', '저장한 .hwpx 파일은 더뷰(viewer.html)나 한글에서 그대로 열립니다.'),
   @('90_inquiry', '8. 60초 문의', '원하는 기능을 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.'));
  wide = @(@('print_layout_quote1.png', '부록. 인쇄되는 견적서(2026-0001)', '공급가액 1,955,000 + 부가세 195,500 = 합계 2,150,500원(일금 이백일십오만오백원정). A4 한 장입니다.')) }
 letter = @{ title = '민원·내용증명 초안 1초 작성 사용설명서'; lead = '사건 개요만 넣으면 수신·제목·본문·붙임·작성일 규격을 갖춘 내용증명·민원신청서·이의신청서·사실확인서 초안이 나옵니다. 초안 작성 보조용이며 법률 자문이 아닙니다. 발송·제출은 본인이 직접 하십시오(이 앱은 우편·문자·메일을 보내지 않습니다).';
  steps = @(
   @('01_kinds', '1. 종류 고르기', '내용증명 · 민원신청서 · 이의신청서 · 사실확인서 중 하나를 누르면 바로 다음 단계로 넘어갑니다.'),
   @('02_notice_empty', '2. 사건 개요', '누가·언제·무엇을·어떻게·무엇을 요구하는지 짧게 적습니다. 처음이면 [예시 넣기]로 모양을 먼저 보세요.'),
   @('03_notice_typed', '2-1. 금액·날짜 자동 병기', '금액은 "금 1,200,000원(금 일백이십만 원)", 날짜는 "2026년 12월 2일(수)"처럼 숫자와 한글로 함께 적힙니다. 기한은 [D+14] 단추로 고릅니다.'),
   @('04_notice_draft', '3. 초안 확인·고치기', '본문 칸에서 바로 고치면 인쇄·복사에 그대로 들어갑니다. [자동 초안으로 되돌리기]로 처음 초안을 다시 부를 수 있습니다.'),
   @('05_notice_preview', '3-1. 내용증명 미리보기', '수신(귀하)·발신·제목·번호 매긴 본문·요구사항 목록·붙임·작성일·발신인(인)이 A4 한 장에 들어갑니다.'),
   @('06_civil_input', '4. 민원신청서', '민원 분야와 처리 기관을 넣으면 신청인 소개 → 발생 경위 → 불편·피해 → 요청 사항 → 회신 방법 순서로 만듭니다.'),
   @('07_civil_preview', '4-1. 민원신청서 초안', '요청 사항은 번호 목록으로, 회신받을 연락처는 맨 끝에 들어갑니다.'),
   @('08_objection_input', '5. 이의신청서', '처분명·처분일·통지 받은 날을 넣으면 작성일 기준으로 며칠 지났는지도 함께 적습니다.'),
   @('09_objection_preview', '5-1. 이의신청서 초안', '대상 처분 → 사실관계 → 이의 이유 → 신청 취지 → 증빙 안내 순서입니다.'),
   @('11_fact_preview', '6. 사실확인서', '확인자·확인 사항·"사실과 다름이 없음을 확인합니다"·제출처와 용도가 들어갑니다.'),
   @('12_missing', '7. 빈 칸 표시', '빈 칸이 있으면 빨간 테두리로 보이고, 그대로 초안을 보면 그 자리는 밑줄(____)로 나갑니다.'),
   @('90_inquiry', '8. 60초 문의', '필요한 서식을 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.'));
  wide = @(@('print_layout_notice.png', '부록. 인쇄되는 내용증명 초안', 'A4 한 장. 내용증명은 같은 글 3부(보내는 사람·받는 사람·우체국 보관용)를 인쇄해 우체국 창구에서 직접 접수합니다.')) }
}[$app]
$marksPath = Join-Path $dir 'marks.json'
$marks = if (Test-Path $marksPath) { [IO.File]::ReadAllText($marksPath, [Text.Encoding]::UTF8) } else { '[]' }
$stepsJson = ConvertTo-Json -InputObject @($C.steps | ForEach-Object { , @($_) }) -Depth 4 -Compress
$wideHtml = ($C.wide | Where-Object { Test-Path (Join-Path $dir $_[0]) } | ForEach-Object { "<div class='wide'><div class='txt'><h2>$($_[1])</h2><p>$($_[2])</p></div><img src='$($_[0])'></div>" }) -join ''
$html = @"
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>$($C.title)</title>
<style>
@page{size:A4;margin:12mm}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Malgun Gothic","Apple SD Gothic Neo",sans-serif;color:#111;font-size:11pt;line-height:1.55}
.cover{background:#0A1128;color:#fff;border-radius:10px;padding:22px 24px;margin-bottom:14px}
.cover h1{font-size:21pt;letter-spacing:-1px}
.cover p{color:#C9D3E3;margin-top:8px;font-size:10.5pt}
.legend{display:flex;gap:18px;font-size:9.5pt;color:#444;margin:0 0 10px}
.legend span{display:flex;align-items:center;gap:6px}
.pair{display:flex;gap:16px;page-break-inside:avoid;margin-bottom:14px}
.st{flex:1;display:flex;gap:12px;page-break-inside:avoid}
.shot{position:relative;width:180px;flex:0 0 180px;border-radius:12px;overflow:hidden;border:2px solid #0A1128;align-self:flex-start}
.shot img{display:block;width:180px}
.txt h2{font-size:11.5pt;color:#0A1128;border-left:4px solid #FF6B00;padding-left:7px;margin-bottom:5px;letter-spacing:-.4px}
.txt p{font-size:9.6pt;color:#333}
.ring{position:absolute;border:3px solid #FF6B00;border-radius:12px;box-shadow:0 0 0 2px rgba(255,255,255,.85)}
.tap{position:absolute;width:30px;height:30px;margin:-15px 0 0 -15px;border-radius:50%;background:rgba(255,107,0,.35);border:3px solid #FF6B00}
.fing{position:absolute;width:30px;height:36px;margin:2px 0 0 -4px}
.lbl{position:absolute;font-size:7.5pt;font-weight:700;color:#fff;background:#FF6B00;border-radius:4px;padding:0 4px;white-space:nowrap}
.wide{page-break-before:always}
.wide img{max-width:100%;max-height:235mm;border:1px solid #999;margin-top:8px}
.foot{font-size:8.5pt;color:#666;margin-top:8px}
</style></head><body>
<div class="cover"><h1>$($C.title)</h1><p>$($C.lead)</p><p>화면은 실제 앱을 390px 휴대폰 크기로 연 그대로의 캡처이고, 손가락·원은 캡처할 때 실제로 누른 자리입니다.</p></div>
<div class="legend"><span><svg width="18" height="18"><circle cx="9" cy="9" r="7" fill="rgba(255,107,0,.35)" stroke="#FF6B00" stroke-width="3"/></svg>여기를 누르세요(손가락)</span><span><svg width="22" height="16"><rect x="2" y="2" width="18" height="12" rx="4" fill="none" stroke="#FF6B00" stroke-width="3"/></svg>여기를 보세요(원)</span></div>
<div id="list"></div>
$wideHtml
<p class="foot">KTS 원클릭 · 서버 0 · 유료 API 0 · 외부 발송 0 · 모든 처리는 손님 기기 안에서만 합니다.</p>
<script>
const MARKS = $marks;
const STEPS = $stepsJson;
const S = 180 / 390;
const fing = '<svg class="fing" viewBox="0 0 30 36"><path d="M9 3c1.7 0 3 1.3 3 3v10l1-.2V12c0-1.6 1.3-2.8 2.8-2.8S18.6 10.4 18.6 12v4l.8-.1c1.5 0 2.7 1.2 2.7 2.7v1l.6-.1c1.5 0 2.8 1.2 2.8 2.8V26c0 4.4-3.6 8-8 8h-3.3c-2.6 0-5-1.3-6.4-3.4L3.3 24c-.9-1.3-.6-3 .7-3.9 1.2-.8 2.8-.6 3.7.5L6 21V6c0-1.7 1.3-3 3-3z" fill="#fff" stroke="#0A1128" stroke-width="1.6"/></svg>';
const byShot = {}; (Array.isArray(MARKS) ? MARKS : [MARKS]).forEach(m => byShot[m.shot] = m.marks || []);
const card = s => {
  const [shot, h, p] = s; let ov = '';
  (byShot[shot] || []).forEach(m => {
    if (!m) return;
    if (m.y > 844 || m.y + m.h < 0) return;
    if (m.kind === 'tap'){ const cx = (m.x + m.w / 2) * S, cy = (m.y + m.h / 2) * S;
      ov += '<div class="tap" style="left:' + cx + 'px;top:' + cy + 'px"></div><div style="position:absolute;left:' + cx + 'px;top:' + cy + 'px">' + fing + '</div>'; }
    else { const pd = 3, y0 = Math.max(0, m.y), y1 = Math.min(844, m.y + m.h); ov += '<div class="ring" style="left:' + (m.x * S - pd) + 'px;top:' + (y0 * S - pd) + 'px;width:' + (m.w * S + pd * 2) + 'px;height:' + ((y1 - y0) * S + pd * 2) + 'px"></div>'; }
    if (m.note) ov += '<div class="lbl" style="left:' + Math.max(2, Math.min(80, m.x * S)) + 'px;top:' + Math.max(2, Math.min(370, Math.max(0, m.y) * S - 14)) + 'px">' + m.note + '</div>';
  });
  return '<div class="st"><div class="shot"><img src="' + shot + '.png">' + ov + '</div><div class="txt"><h2>' + h + '</h2><p>' + p + '</p></div></div>';
};
let html = ''; for (let i = 0; i < STEPS.length; i += 2) html += '<div class="pair">' + card(STEPS[i]) + (STEPS[i + 1] ? card(STEPS[i + 1]) : '<div class="st"></div>') + '</div>';
document.getElementById('list').innerHTML = html;
</script></body></html>
"@
$htmlPath = Join-Path $dir '사용설명서.html'
[IO.File]::WriteAllText($htmlPath, $html, (New-Object Text.UTF8Encoding($false)))
Start-CdpChrome 9360 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $htmlPath) } | Out-Null
  Start-Sleep -Milliseconds 2500
  $missing = Invoke-Js "JSON.stringify([...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.getAttribute('src')))"
  $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
  $pdf = Join-Path $dir '사용설명서.pdf'
  [IO.File]::WriteAllBytes($pdf, [Convert]::FromBase64String($r['data']))
  Write-Output ("$app manual: pages=" + (Pages $pdf) + " bytes=" + (Get-Item $pdf).Length + " steps=" + $C.steps.Count + " brokenImages=" + $missing)
} finally { Stop-CdpChrome }
