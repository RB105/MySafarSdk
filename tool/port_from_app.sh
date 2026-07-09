#!/usr/bin/env bash
# MySafar app repo'sidagi (gitlab.cloudgate.uz/mysafar/mobile) o'zgarishlarni
# SDK'ga ko'chirish. To'g'ridan-to'g'ri git merge ISHLAMAYDI — SDK kodi appdan
# quyidagi transformatsiyalar bilan olingan:
#   lib/X                    -> lib/src/X
#   package:mysafar/         -> package:mysafar_sdk/src/
#   'assets/...              -> 'packages/mysafar_sdk/assets/...
#   easy_localization import -> sdk_localization import (.tr() drop-in mos)
#   GetStorage()             -> sdkStorage()
#   fontFamily "Gilroy"      -> "packages/mysafar_sdk/Gilroy"
# Bu skript app diff'ini olib, o'sha transformatsiyalarni patch'ga qo'llab
# SDK ustiga apply qiladi. Tushmagan hunk'lar *.rej fayllarga tushadi —
# ularni qo'lda (yoki Claude'ga berib) ko'chirasiz.
#
# Ishlatish:
#   git -C <app-clone> pull                # avval app clone'ini yangilang
#   tool/port_from_app.sh <commit>         # bitta commit
#   tool/port_from_app.sh <old>..<new>     # oraliq
#   tool/port_from_app.sh <range> lib/view/main   # faqat shu papka
#
# Eslatma: SDK'dan olib tashlangan qismlarga (splash/news/firebase/google)
# tegishli hunk'lar tabiiy ravishda rej bo'ladi — ularni e'tiborsiz qoldiring.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MARKER=".port_marker"

# App clone'ini yangilab olamiz (u gitlab.cloudgate.uz'dan tortadi), keyin fetch.
APP_DIR="$(git remote get-url app)"
git -C "$APP_DIR" pull origin home --quiet 2>/dev/null \
  || echo "⚠️  app clone'ini pull qilib bo'lmadi (offline?), lokal holat ishlatiladi"
git fetch app home --quiet

# Range berilmasa: oxirgi port qilingan joydan app/home gacha (marker fayldan).
if [ $# -eq 0 ] || [[ "${1:-}" == lib* ]] || [[ "${1:-}" == assets* ]]; then
  LAST="$(cat "$MARKER" 2>/dev/null || echo 16841ea)"
  RANGE="$LAST..app/home"
  echo "Range berilmadi — marker'dan: $RANGE"
else
  RANGE="$1"
  shift || true
fi
PATHS=("$@")
if [ ${#PATHS[@]} -eq 0 ]; then PATHS=(lib assets); fi

PATCH="$(mktemp -t sdk_port).patch"
git diff "$RANGE" -- "${PATHS[@]}" > "$PATCH.raw"

if [ ! -s "$PATCH.raw" ]; then
  echo "Diff bo'sh — berilgan oraliqda ${PATHS[*]} bo'yicha o'zgarish yo'q."
  exit 0
fi

# DIQQAT: header qoidalari bir-birini QAYTA ushlamasligi kerak (lib/src ham
# lib/ bilan boshlanadi) — shu sabab har bir header turi uchun bittadan,
# aniq anchor'li qoida.
sed \
  -e 's|^diff --git a/lib/\([^ ]*\) b/lib/.*$|diff --git a/lib/src/\1 b/lib/src/\1|' \
  -e 's|^--- a/lib/|--- a/lib/src/|' \
  -e 's|^+++ b/lib/|+++ b/lib/src/|' \
  -e 's|package:mysafar/|package:mysafar_sdk/src/|g' \
  -e "s|'assets/|'packages/mysafar_sdk/assets/|g" \
  -e 's|"assets/|"packages/mysafar_sdk/assets/|g' \
  -e "s|import 'package:easy_localization/easy_localization.dart'[^;]*;|import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';|" \
  -e 's|GetStorage()|sdkStorage()|g' \
  -e 's|fontFamily: "Gilroy"|fontFamily: "packages/mysafar_sdk/Gilroy"|g' \
  -e "s|fontFamily: 'Gilroy'|fontFamily: 'packages/mysafar_sdk/Gilroy'|g" \
  "$PATCH.raw" > "$PATCH"

echo "Patch: $PATCH"
echo "Qo'llanmoqda..."
if git apply --reject --whitespace=nowarn "$PATCH"; then
  echo "✅ To'liq qo'llandi. Endi: flutter analyze && git diff"
else
  echo ""
  echo "⚠️  Ba'zi hunk'lar tushmadi — *.rej fayllarni ko'ring:"
  find lib -name '*.rej' 2>/dev/null || true
  echo "Rej'larni qo'lda ko'chiring (yoki Claude'ga bering), keyin rm bilan o'chiring."
fi

# Keyingi safar shu nuqtadan davom etish uchun marker yangilanadi
# (rej bo'lsa ham — o'sha hunk'lar baribir qo'lda hal qilinadi).
git rev-parse app/home > "$MARKER"
echo "Marker yangilandi: $(cat "$MARKER" | head -c 8) (keyingi port shu yerdan boshlanadi)"
