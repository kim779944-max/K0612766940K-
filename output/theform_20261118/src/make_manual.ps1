# 사용설명서(HTML → PDF): 390px 실제 캡처 위에, 캡처 때 기록한 누르는 자리(marks.json)에 손가락·원 표시
param([ValidateSet('theform', 'contract')][string]$app = 'theform')
. "$PSScriptRoot\lib.ps1"
$base = (Resolve-Path "$PSScriptRoot\..\..").Path
if ($app -eq 'theform') {
  $dir = Join-Path $base 'theform_20261118'
  $title = '더양식 사용설명서'
  $lead = '종이·사진 양식을 한 번 등록해 두고, 다음부터는 값만 채워 한글(.hwpx)·엑셀(.xlsx)·PDF로 뽑습니다. 사진·양식·값은 이 기기 브라우저 안에만 저장됩니다.'
  $steps = @(
    @('01_home', '1. 시작', '[양식 사진 찍기 · 고르기]를 누릅니다. 기본 양식 5종(거래명세서·견적서·근로계약서·개인정보 동의서·신청서)은 아래 목록에서 바로 [열기]로 씁니다.'),
    @('02_auto_fix_after', '2. 자동 보정', '사진을 고르면 종이 네 귀퉁이를 찾아 기울기와 테두리를 바로잡고, 바탕을 하얗게 정리해 배경으로 깝니다.'),
    @('02b_auto_fix_before', '2-1. 보정 전과 비교', '[보정 전]을 누르면 찍은 원본을 봅니다. [보정 후]로 돌아와 [빈칸 지정으로]를 누릅니다.'),
    @('03_fields_tap', '3. 빈칸 찍기', '채울 자리를 누르면 칸이 생깁니다. 칸을 끌어 옮기고, 파란 점을 끌어 크기를 맞춥니다. [+] 칸 추가, [−] 칸 삭제, [되돌리기]는 10단계 넘게 돌아갑니다.'),
    @('03b_field_label_type', '3-1. 이름표와 성격', '칸마다 이름표(성명·금액·날짜)와 성격(글자·숫자·날짜·서명)을 정합니다. 숫자는 쉼표, 날짜는 "2026년 11월 20일"로 바뀌어 들어갑니다.'),
    @('03c_form_name', '3-2. 내 양식으로 저장', '양식 이름을 적고 [내 양식으로 저장]을 누르면 이 기기에 보관됩니다. 다음부터는 목록에서 바로 엽니다.'),
    @('06_my_list', '4. 내 양식 목록', '[열기]로 값 입력, [복제]로 비슷한 양식 만들기, [삭제]로 지우기. 기본 양식도 [복제]하면 칸 위치를 고칠 수 있습니다.'),
    @('04_custom_values', '5. 값 입력', '칸을 누르고 값을 칩니다. [음성 메모로 넣기]는 누른 칸에 말로 넣습니다. 입력값은 자동 저장됩니다.'),
    @('04b_custom_sign', '5-1. 손가락 서명', '서명 칸에는 손가락으로 서명합니다. 종이 위에는 서명 잉크만 얹힙니다.'),
    @('05_custom_preview', '6. 미리보기', '종이 위에 값이 얹힌 모습 그대로입니다. 인쇄·PDF도 이 모습으로 나갑니다.'),
    @('05b_custom_export', '7. 내보내기', '[한글 파일(.hwpx)] · [엑셀 파일(.xlsx)] · [인쇄 · PDF] 중에 고릅니다. 파일은 이 기기 안에서 만들어집니다.'),
    @('07_trade_values', '8. 기본 양식: 자동 계산', '거래명세서·견적서는 수량 × 단가 = 금액, 합계·부가세·총액이 자동으로 채워집니다. [손글씨 사진 읽기]는 내 제미나이 무료 열쇠가 있을 때만 씁니다.'),
    @('08_trade_preview', '8-1. 기본 양식 미리보기', '기본 양식은 A4 한 장 그대로 나옵니다.'),
    @('open_거래명세서_기본_hwpx', '9. 저장한 파일 확인', '저장한 파일은 더뷰(viewer.html)로 바로 열어 값이 들어갔는지 확인할 수 있습니다.'),
    @('12_key_sheet', '10. AI 열쇠(선택)', '손글씨 판독·빈칸 자동 인식을 쓸 때만 내 제미나이 무료 열쇠를 넣습니다. 열쇠는 이 기기에만 저장되고, 없어도 모든 기본 기능이 됩니다.'),
    @('11_inquiry', '11. 60초 문의', '이름·연락처·문의를 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.')
  )
} else {
  $dir = Join-Path $base 'contract_20261118'
  $title = '계약서 1초 생성기 사용설명서'
  $lead = '부동산 매매계약서 · 주택 임대차계약서(전세·월세) · 상가건물 임대차계약서를 조건만 넣어 바로 만듭니다. 본 서식은 작성 보조용이며, 법적 효력·특약 검토는 공인중개사 및 법률 전문가 확인이 필요합니다.'
  $steps = @(
    @('01_start', '1. 종류 고르기', '매매 · 주택 임대차 · 상가건물 임대차 중 하나를 누릅니다. 위쪽 고지문은 항상 고정되어 보입니다.'),
    @('sale_1_party', '2. 당사자 입력', '갑(매도인·임대인)과 을(매수인·임차인)의 성명·주민번호 앞자리·주소·연락처를 넣습니다. 입력값은 이 기기에 자동 저장되어 이어 쓸 수 있습니다.'),
    @('sale_2_money', '3. 금액', '숫자만 넣으면 쉼표와 한글 금액(예: 금 팔억오천만 원정)이 자동으로 붙습니다. 잔금은 전체 − 계약금 − 중도금으로 자동 계산됩니다.'),
    @('sale_2b_dates', '3-1. 날짜(D+n)', '계약일로부터 며칠 뒤인지 넣거나 [D+30] 같은 단추를 누르면 실제 날짜와 요일이 바로 나옵니다.'),
    @('sale_3_specials', '4. 특약사항', '자주 쓰는 특약 10종 중 고르고, 필요한 내용은 직접 적습니다(줄마다 한 항목).'),
    @('sale_3b_output', '5. 부수 선택과 출력', '갑용·을용·중개사용 중 인쇄할 부수를 고르고 [인쇄 · PDF] 또는 [한글(.hwpx) 저장]을 누릅니다. 각 부 오른쪽 위에 보관용 표시가 붙고, 1부가 A4 한 장입니다.'),
    @('sale_4_preview', '6. 계약서 미리보기', '조문 형태 그대로 미리 봅니다. 맨 아래에는 작성 보조용 고지가 함께 인쇄됩니다.'),
    @('02_missing_box', '7. 미입력 확인', '빠진 항목이 있으면 단계 옆에 개수가, 아래에 목록이 빨갛게 나옵니다. 그대로 출력하면 그 자리는 빈칸(____)으로 나갑니다.'),
    @('02b_missing_red', '7-1. 빨간 칸', '빠진 칸은 빨간 테두리로 보입니다. 채우면 바로 사라집니다.'),
    @('house_2_money', '8. 주택 임대차', '월세는 차임 칸이 생기고, 전세를 고르면 차임 줄 없이 보증금만 나옵니다. 임대 기간(개월)을 넣으면 시작·끝 날짜가 자동으로 붙습니다.'),
    @('shop_2_money', '9. 상가건물 임대차', '상가는 차임과 관리비를 함께 적고, 상가 전용 특약(부가세·권리금·원상복구 등)을 고를 수 있습니다.'),
    @('open_매매계약서_샘플_hwpx', '10. 저장한 한글 파일 확인', '저장한 .hwpx 파일은 더뷰(viewer.html)나 한글에서 그대로 열립니다.'),
    @('90_inquiry', '11. 60초 문의', '필요한 서식·특약 문구를 남기면 답장 초안이 바로 만들어집니다. 실제 발송은 담당자가 확인한 뒤에만 합니다.')
  )
}
$marksPath = Join-Path $dir 'marks.json'
$marks = if (Test-Path $marksPath) { [IO.File]::ReadAllText($marksPath, [Text.Encoding]::UTF8) } else { '[]' }
$stepsJson = ConvertTo-Json -InputObject @($steps | ForEach-Object { , @($_) }) -Depth 4 -Compress
$printPng = if ($app -eq 'contract') { 'print_layout_house.png' } else { '' }
$html = @"
<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>$title</title>
<style>
@page{size:A4;margin:12mm}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:"Malgun Gothic","Apple SD Gothic Neo",sans-serif;color:#111;font-size:11pt;line-height:1.55}
.cover{background:#0A1128;color:#fff;border-radius:10px;padding:22px 24px;margin-bottom:14px}
.cover h1{font-size:22pt;letter-spacing:-1px}.cover h1 b{color:#FF6B00}
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
.wide img{width:100%;border:1px solid #999}
.foot{font-size:8.5pt;color:#666;margin-top:8px}
</style></head><body>
<div class="cover"><h1>$title</h1><p>$lead</p><p>화면은 실제 앱을 390px 휴대폰 크기로 연 그대로의 캡처입니다.</p></div>
<div class="legend"><span><svg width="18" height="18"><circle cx="9" cy="9" r="7" fill="rgba(255,107,0,.35)" stroke="#FF6B00" stroke-width="3"/></svg>여기를 누르세요(손가락)</span><span><svg width="22" height="16"><rect x="2" y="2" width="18" height="12" rx="4" fill="none" stroke="#FF6B00" stroke-width="3"/></svg>여기를 보세요(원)</span></div>
<div id="list"></div>
$(if ($printPng) { "<div class='wide'><div class='txt'><h2>부록. 인쇄되는 계약서 1부(주택 임대차 월세 예시)</h2><p>A4 한 장에 조문·금액·특약·서명란·고지가 모두 들어갑니다. 3부를 고르면 갑·을·중개사 보관용이 한 장씩 나옵니다.</p></div><img src='$printPng'></div>" })
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
    if (m.kind === 'tap'){ const cx = (m.x + m.w / 2) * S, cy = (m.y + m.h / 2) * S;
      ov += '<div class="tap" style="left:' + cx + 'px;top:' + cy + 'px"></div><div style="position:absolute;left:' + cx + 'px;top:' + cy + 'px">' + fing + '</div>'; }
    else { const pd = 3; ov += '<div class="ring" style="left:' + (m.x * S - pd) + 'px;top:' + (m.y * S - pd) + 'px;width:' + (m.w * S + pd * 2) + 'px;height:' + (m.h * S + pd * 2) + 'px"></div>'; }
    if (m.note) ov += '<div class="lbl" style="left:' + Math.max(2, Math.min(80, m.x * S)) + 'px;top:' + Math.max(2, m.y * S - 14) + 'px">' + m.note + '</div>';
  });
  return '<div class="st"><div class="shot"><img src="' + shot + '.png">' + ov + '</div><div class="txt"><h2>' + h + '</h2><p>' + p + '</p></div></div>';
};
let html = ''; for (let i = 0; i < STEPS.length; i += 2) html += '<div class="pair">' + card(STEPS[i]) + (STEPS[i + 1] ? card(STEPS[i + 1]) : '<div class="st"></div>') + '</div>';
document.getElementById('list').innerHTML = html;
</script></body></html>
"@
$htmlPath = Join-Path $dir '사용설명서.html'
[IO.File]::WriteAllText($htmlPath, $html, (New-Object Text.UTF8Encoding($false)))
Start-CdpChrome 9345 | Out-Null
try {
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl $htmlPath) } | Out-Null
  Start-Sleep -Milliseconds 2500
  $missing = Invoke-Js "JSON.stringify([...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.getAttribute('src')))"
  $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
  $pdf = Join-Path $dir '사용설명서.pdf'
  [IO.File]::WriteAllBytes($pdf, [Convert]::FromBase64String($r['data']))
  $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf))
  Write-Output ("$app manual: pages=" + ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count + " bytes=" + (Get-Item $pdf).Length + " brokenImages=" + $missing)
} finally { Stop-CdpChrome }
