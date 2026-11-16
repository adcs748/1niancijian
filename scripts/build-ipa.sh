#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="EnglishCoach.xcodeproj"
TARGET="EnglishCoach"

echo "==> 清理旧的打包目录"
rm -rf build

echo "==> 构建（不签名）"
xcodebuild \
  -project "$PROJECT" \
  -target "$TARGET" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$(find "$ROOT/build" -name "EnglishCoach.app" -path "*Release-iphoneos*" | head -n 1)"
if [ -z "$APP_PATH" ]; then
  echo "未找到构建产物，请检查上面的报错。"
  exit 1
fi

echo "==> 打包 IPA"
mkdir -p build/Payload
cp -R "$APP_PATH" build/Payload/
(
  cd build
  zip -r -q EnglishCoach-unsigned.ipa Payload
)

echo "==> 完成：$ROOT/build/EnglishCoach-unsigned.ipa"
echo "请用 Sideloadly / AltStore 自签安装到 iPhone。"