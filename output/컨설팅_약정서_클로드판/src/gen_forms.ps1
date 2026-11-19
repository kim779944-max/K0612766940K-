# 측정_원자료/screen_sky.json(실제 PNG를 뽑은 그 배치의 DOM 실측) → forms_consult.js + 좌표표(fields_table.md)
# % 좌표 = css px × S / PNG 픽셀(1489×2105) × 100, 좌상단 기준, 소수 3자리
$ErrorActionPreference = 'Stop'
$OUT = (Resolve-Path "$PSScriptRoot\..").Path
$RAW = Join-Path $OUT '측정_원자료'
$o = [IO.File]::ReadAllText((Join-Path $RAW 'screen_sky.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$S = [double]$o.S
# id | 라벨 | grp | type | sec | 추가 속성(JS 조각)  — 원문.md 3장 인벤토리 그대로
$META = @(
 'a_name|성명(상호)|a|text|제1조 계약 당사자 — 갑 (의뢰인)|',
 'a_rrn|주민(법인)등록번호|a|text|제1조 계약 당사자 — 갑 (의뢰인)|',
 'a_addr|주소|a|text|제1조 계약 당사자 — 갑 (의뢰인)|',
 'a_tel|연락처|a|text|제1조 계약 당사자 — 갑 (의뢰인)|',
 'a_sign|서명 또는 인|a|text|제1조 계약 당사자 — 갑 (의뢰인)|',
 'b_name|성명(상호)|b|text|제1조 계약 당사자 — 을 (피의뢰인)|',
 'b_rrn|주민(법인)등록번호|b|text|제1조 계약 당사자 — 을 (피의뢰인)|',
 'b_addr|주소|b|text|제1조 계약 당사자 — 을 (피의뢰인)|',
 'b_tel|연락처|b|text|제1조 계약 당사자 — 을 (피의뢰인)|',
 'b_sign|서명 또는 인|b|text|제1조 계약 당사자 — 을 (피의뢰인)|',
 'o_target|대상물의 표시|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|',
 'o_term|계약(의뢰) 기간|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|',
 'o_deposit|보증금(매매가)|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|"money":1',
 'o_rent|월 차임|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|"money":1',
 'o_scope|목적물의 범위 및 주요 조건|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|',
 'o_note|비고(기타 조건)|x|text|제3조 의뢰 목적물의 표시 및 거래 조건|',
 'o_lease_note|제4조 ① 내용|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|',
 'o_months|전속 약정기간(개월)|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"al":"c"',
 't_from_y|기간 시작 년|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"y","dg":"기간","al":"c"',
 't_from_m|기간 시작 월|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"m","dg":"기간","al":"c"',
 't_from_d|기간 시작 일|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"d","dg":"기간","al":"c"',
 't_to_y|기간 끝 년|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"y","dg":"기간끝","al":"c"',
 't_to_m|기간 끝 월|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"m","dg":"기간끝","al":"c"',
 't_to_d|기간 끝 일|x|text|제4조 컨설팅 전속거래의 진행과 약정기간|"dp":"d","dg":"기간끝","al":"c"',
 'f_total|총 컨설팅 용역비용|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"money":1,"al":"c"',
 'f_r1|① 약정 시 비율|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"al":"c"',
 'f_m1|① 약정 시 금액|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"money":1,"al":"c"',
 'f_r2|② 권리계약 시 비율|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"al":"c"',
 'f_m2|② 권리계약 시 금액|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"money":1,"al":"c"',
 'f_r3|③ 본계약 시 비율|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"al":"c"',
 'f_m3|③ 본계약 시 금액|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"money":1,"al":"c"',
 'f_r4|④ 잔금 시 비율|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"al":"c"',
 'f_m4|④ 잔금 시 금액|x|text|특약사항 컨설팅･용역 약정금액 및 지급 시기|"money":1,"al":"c"',
 'f_etc|기타 특약사항|s|text|특약사항 기타 특약사항|"multi":1,"top":1,"shrink":1',
 'date_y|작성일 년|x|text|작성일|"dp":"y","dg":"작성일","al":"c"',
 'date_m|작성일 월|x|text|작성일|"dp":"m","dg":"작성일","al":"c"',
 'date_d|작성일 일|x|text|작성일|"dp":"d","dg":"작성일","al":"c"',
 's_a_name|갑 성 명|a|text|서명·날인|',
 's_a_in|갑 (인)|a|sign|서명·날인|',
 's_b_name|을 상호･성명|b|text|서명·날인|',
 's_b_in|을 (인)|b|sign|서명·날인|'
)
function R3([double]$v) { return [math]::Round($v, 3).ToString('0.000', [Globalization.CultureInfo]::InvariantCulture) }
function Q([string]$s) { return [char]34 + $s.Replace([string][char]92, [string][char]92 + [char]92).Replace([string][char]34, [string][char]92 + [char]34) + [char]34 }
$byId = @{}; foreach ($f in $o.fields) { $byId[$f.id] = $f }
$pagesJs = @{ 1 = @(); 2 = @() }
$rows = @('| # | id | 라벨 | grp | type | 쪽 | x | y | w | h |', '|---|---|---|---|---|---|---|---|---|---|')
$n = 0
foreach ($m in $META) {
  $n++
  $a = $m.Split('|')
  $f = $byId[$a[0]]; if (-not $f) { throw "실측에 없는 필드: $($a[0])" }
  $x = $f.r.x * $S / 1489 * 100; $y = $f.r.y * $S / 2105 * 100; $w = $f.r.w * $S / 1489 * 100; $h = $f.r.h * $S / 2105 * 100
  $js = '{"sec":' + (Q $a[4]) + ',"id":' + (Q $a[0]) + ',"grp":' + (Q $a[2]) + ',"label":' + (Q $a[1]) + ',"type":' + (Q $a[3]) + ',"x":' + (R3 $x) + ',"y":' + (R3 $y) + ',"w":' + (R3 $w) + ',"h":' + (R3 $h) + $(if ($a[5]) { ',' + $a[5] } else { '' }) + '}'
  $pagesJs[[int]$f.page] += $js
  $rows += "| $n | ``$($a[0])`` | $($a[1]) | $($a[2]) | $($a[3]) | $($f.page) | $(R3 $x) | $(R3 $y) | $(R3 $w) | $(R3 $h) |"
}
$p1 = ($pagesJs[1] -join ",`n      "); $p2 = ($pagesJs[2] -join ",`n      ")
$js = @"
/* 부동산 컨설팅 전속 거래 약정서 — 더계약서(contract/forms.js) 호환 양식 객체 · 2페이지
   만든 곳: output/컨설팅_약정서_클로드판/src/gen_forms.ps1 (consult.html 실측 → % 좌표, PNG 1489×2105 기준)
   ※ 실서비스에 아직 넣지 않았습니다. 넣는 방법·되돌리는 방법은 같은 폴더 연동_노트.md
   · bg 는 테마 접미사 없는 기본(하늘색) 이름. 테마를 바꿀 때는 THEMES 값으로 _mono/_sky/_green/_gray 를 붙여 갈아끼웁니다.
   · 금액 7칸(o_deposit·o_rent·f_total·f_m1~4)은 money:1 — 숫자만 받아 콤마로 그립니다(원문의 '금 … 원정' 글자는 배경에 그대로).
   · 불러오면 window.KC_FORMS 에 추가되고, 기존 화면 코드용으로 fields(41개, page 번호 포함)·bg(1쪽)를 펼쳐 둡니다. */
(function(){
  var FORM = {
    "id":"consult", "name":"부동산 컨설팅 전속 거래 약정서",
    "roleA":"의뢰인(갑)", "roleB":"피의뢰인(을)", "roleC":"",
    "legal":"본 서식은 부동산 컨설팅 전속 거래 약정서 표준 빈 양식입니다(원문 문구 그대로). 약정 내용·금액은 당사자가 확인하고, 세무·법률 판단은 전문가 확인을 권합니다.",
    "specials":[],
    "themes":["mono","sky","green","gray"], "theme":"sky",
    "pages":[
     { "bg":"tpl_consult_p1.png", "fields":[
      $p1
     ] },
     { "bg":"tpl_consult_p2.png", "fields":[
      $p2
     ] }
    ]
  };
  FORM.bgOf = function(page, theme){ var b = FORM.pages[(page || 1) - 1].bg; return theme ? b.replace(/\.png$/, '_' + theme + '.png') : b; };
  FORM.bg = FORM.pages[0].bg;
  FORM.fields = [];
  FORM.pages.forEach(function(p, i){ p.fields.forEach(function(f){ var c = {}; for (var k in f) c[k] = f[k]; c.page = i + 1; FORM.fields.push(c); }); });
  window.KC_FORM_CONSULT = FORM;
  if (Array.isArray(window.KC_FORMS) && !window.KC_FORMS.some(function(f){ return f.id === FORM.id; })) window.KC_FORMS.push(FORM);
})();
"@
[IO.File]::WriteAllText((Join-Path $OUT 'forms_consult.js'), $js, (New-Object Text.UTF8Encoding $false))
[IO.File]::WriteAllText((Join-Path $RAW 'fields_table.md'), ($rows -join "`n") + "`n", (New-Object Text.UTF8Encoding $false))
"forms_consult.js: p1=$($pagesJs[1].Count) p2=$($pagesJs[2].Count) total=$n"
