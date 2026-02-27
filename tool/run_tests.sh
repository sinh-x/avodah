#!/usr/bin/env bash
# Runs mcp dart tests and outputs a clean summary.
# Exit code matches dart test exit code.
set -euo pipefail

cd "$(dirname "$0")/../mcp"

OUTPUT=$(dart test --reporter json 2>&1) || true
EXIT_CODE=${PIPESTATUS[0]:-$?}

# Parse JSON reporter output for summary
PASSED=$(echo "$OUTPUT" | grep -c '"result":"success"' || true)
FAILED=$(echo "$OUTPUT" | grep -c '"result":"error"' || true)

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "All $PASSED tests passed."
else
  echo "FAILED: $PASSED passed, $FAILED failed."
  # Show failure details
  echo "$OUTPUT" | grep -A2 '"result":"error"' | head -30
  exit 1
fi
