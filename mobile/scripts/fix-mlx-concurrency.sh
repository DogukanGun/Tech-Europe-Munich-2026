#!/usr/bin/env bash
#
# Works around a Swift 6 strict-concurrency error in mlx-swift-lm 3.31.3 when
# building with Xcode 16.x. The dependency declares swift-tools-version 6.1 and
# expects a current SDK in which CIContext is Sendable; on the older Xcode 16.x
# SDK it is not, so this file-private global trips strict-concurrency:
#
#   Libraries/MLXVLM/MediaProcessing.swift:  private let context = CIContext()
#
# CIContext is documented thread-safe, so marking it nonisolated(unsafe) is the
# correct fix. NOT needed on a current Xcode.
#
# Run this AFTER Swift packages have been resolved (after `xcodegen generate` +
# a first build attempt, or after opening the project in Xcode). The patch lives
# in the resolved checkout and is lost on "Reset Package Caches" — just re-run.
# This script is idempotent and self-repairing.
set -euo pipefail

found=0
while IFS= read -r f; do
  found=1
  # 1) Repair a doubled-parens line from an earlier buggy patch: CIContext()() -> CIContext()
  sed -i '' 's/CIContext()()/CIContext()/g' "$f"
  # 2) Add the nonisolated(unsafe) marker if it isn't there yet.
  #    NOTE: basic (non-extended) regex — parentheses are literal here, so ()
  #    matches the real "()" instead of being an empty group.
  sed -i '' 's/^private let context = CIContext()/nonisolated(unsafe) private let context = CIContext()/' "$f"

  if grep -q '^nonisolated(unsafe) private let context = CIContext()$' "$f"; then
    echo "ok: $f"
  else
    echo "WARN: line 16 of $f is not what was expected:"
    sed -n '16p' "$f"
  fi
done < <(find "$HOME/Library/Developer/Xcode/DerivedData" \
              -path '*mlx-swift-lm/Libraries/MLXVLM/MediaProcessing.swift' 2>/dev/null)

[ "$found" -eq 1 ] || echo "Nothing found — packages not resolved yet?"
