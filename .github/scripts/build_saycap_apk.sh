#!/usr/bin/env bash
# ============================================================
#  KTS 세이캡 — debug APK 빌드 (Gradle 없이)
#  aapt2 -> javac -> d8 -> zipalign -> apksigner
#  바꾸는 것은 AndroidManifest.xml 의 versionCode/versionName 두 값뿐입니다.
#  사용: VC=14 VN=1.4 bash .github/scripts/build_saycap_apk.sh
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/app_saycap"

VC="${VC:-14}"
VN="${VN:-1.4}"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
BT="$SDK/build-tools/34.0.0"
PLAT="$SDK/platforms/android-34/android.jar"

echo "== SDK      : $SDK"
echo "== version  : $VC / $VN"
[ -x "$BT/aapt2" ] || { echo "aapt2 없음: $BT"; exit 1; }
[ -f "$PLAT" ] || { echo "android.jar 없음: $PLAT"; exit 1; }

# ---- 1) 버전 두 값만 변경 ----
sed -i -E 's/android:versionCode="[0-9]+"/android:versionCode="'"$VC"'"/; s/android:versionName="[^"]*"/android:versionName="'"$VN"'"/' AndroidManifest.xml
grep -nE 'android:versionCode|android:versionName' AndroidManifest.xml

# ---- 2) 빌드 ----
rm -rf build
mkdir -p build/gen build/classes build/dex

echo "== aapt2 compile"
"$BT/aapt2" compile --dir res -o build/res.zip

echo "== aapt2 link"
"$BT/aapt2" link -o build/base.apk -I "$PLAT" --manifest AndroidManifest.xml -A assets build/res.zip \
  --java build/gen --min-sdk-version 24 --target-sdk-version 34 --version-code "$VC" --version-name "$VN"

echo "== javac"
javac -source 8 -target 8 -encoding UTF-8 -classpath "$PLAT" -d build/classes \
  $(find src -name '*.java') $(find build/gen -name '*.java')

echo "== d8"
"$BT/d8" --release --lib "$PLAT" --min-api 24 --output build/dex $(find build/classes -name '*.class')

echo "== pack classes.dex"
cp build/base.apk build/unsigned.apk
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import zipfile
with zipfile.ZipFile('build/unsigned.apk', 'a', zipfile.ZIP_DEFLATED) as z:
    z.write('build/dex/classes.dex', 'classes.dex')
PY
else
  ( cd build/dex && zip -q ../unsigned.apk classes.dex )
fi
"$BT/zipalign" -f -p 4 build/unsigned.apk build/aligned.apk

# ---- 3) debug 서명 ----
echo "== debug sign"
KS="${RUNNER_TEMP:-/tmp}/debug.keystore"
mkdir -p "$(dirname "$KS")"
rm -f "$KS"
keytool -genkeypair -keystore "$KS" -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"

mkdir -p "$ROOT/output/apk_20261117"
OUT="$ROOT/output/apk_20261117/KTS_saycap_v${VN}_debug.apk"
"$BT/apksigner" sign --ks "$KS" --ks-pass pass:android --key-pass pass:android \
  --min-sdk-version 24 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --out "$OUT" build/aligned.apk

# ---- 4) 검증 ----
echo "== verify"
"$BT/apksigner" verify -v --print-certs "$OUT" | tee build/verify.txt
"$BT/aapt2" dump badging "$OUT" | head -3 | tee build/badging.txt

SIZE=$(stat -c %s "$OUT")
SHA=$(sha256sum "$OUT" | cut -d' ' -f1)

# ---- 5) 결과 문서 ----
cd "$ROOT"
{
  echo "# 세이캡 v${VN} debug APK — GitHub Actions 빌드 결과"
  echo
  echo "- 빌드 시각(UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
  echo "- 실행: GitHub Actions \`.github/workflows/apk-saycap.yml\` (커밋 \`${GITHUB_SHA:-local}\`)"
  echo "- Java: $(javac -version 2>&1)"
  echo "- Android SDK: \`$SDK\` · build-tools 34.0.0 · platforms/android-34"
  echo
  echo "## 산출물"
  echo "- 파일: \`output/apk_20261117/$(basename "$OUT")\`"
  echo "- **상품 APK는 공개 저장소에 커밋하지 않습니다.** 이 파일은 빌드한 기계에만 남고, Actions 실행 화면에는 \`saycap-apk\` 산출물로 올라갑니다."
  echo "- 크기: **${SIZE} bytes**"
  echo "- SHA256: \`${SHA}\`"
  echo "- 패키지: \`com.kts.saycap\` · versionCode **${VC}** · versionName **${VN}**"
  echo
  echo "## 서명 검증 (apksigner)"
  echo '```'
  sed -n '1,8p' app_saycap/build/verify.txt 2>/dev/null || true
  echo '```'
  echo
  echo "## badging"
  echo '```'
  cat app_saycap/build/badging.txt 2>/dev/null || true
  echo '```'
  echo
  echo "## 변경된 것"
  echo "- \`app_saycap/AndroidManifest.xml\` 의 \`android:versionCode\` / \`android:versionName\` **두 값만**."
  echo "- 앱 소스(\`src/\`)\`·UI(\`assets/\`)\`·아이콘(\`res/\`)은 손대지 않았습니다."
  echo
  echo "## 설치 안내"
  echo "- 이 APK는 **debug 서명**입니다. 정식 키로 서명한 기존 설치본(v1.3) 위에는 덮어 설치되지 않으니, 폰에서 기존 세이캡을 **삭제한 뒤** 설치해야 합니다."
  echo "- 빌드마다 debug 키가 새로 만들어지므로, 다른 빌드로 갈아탈 때도 삭제 후 설치가 필요합니다."
} > CLAUDE_RESULT_APK_20261117.md

echo
echo "APK    : $OUT"
echo "SIZE   : $SIZE bytes"
echo "SHA256 : $SHA"
echo "BUILD OK"
