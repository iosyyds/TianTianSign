#!/usr/bin/env bash
# resign.sh — 在 macOS / Linux 上用 zsign 命令行重签一个 IPA
# 用法: ./scripts/resign.sh input.ipa cert.p12 123456 profile.mobileprovision [new.bundle.id]
set -euo pipefail

IN="${1:?usage: $0 in.ipa cert.p12 p12pass profile.mobileprovision [bundleid]}"
P12="${2:?need p12}"
PASS="${3:?need p12 password}"
PROF="${4:?need mobileprovision}"
BID="${5:-}"

OUT="resigned-$(date +%s).ipa"

ARGS=( -a "$IN" -k "$P12" -p "$PASS" -m "$PROF" -o "$OUT" )
if [[ -n "$BID" ]]; then
  ARGS+=( -b "$BID" )
fi

echo "🍩 TianTianSign CLI → zsign ${ARGS[*]}"
zsign "${ARGS[@]}"

echo "✅ done: $OUT"
