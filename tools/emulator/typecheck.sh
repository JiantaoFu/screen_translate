#!/usr/bin/env bash
# Usage: typecheck.sh [runs]   (default 2)
# Game dialogue typed out character by character: the final translation must
# cover all three dialogue lines (y ~2080..2270) with at most two boxes,
# not a stack of fragments.
source "$(dirname "$0")/common.sh"
runs=${1:-2}; ok=0; bad=0
for r in $(seq 1 "$runs"); do
  harness game --ei page $(((r + 1) % 2))
  sleep 8
  $A logcat -c
  harness typewriter --ei page $((r % 2))
  sleep 22
  wins=$(overlay_windows | tr '\n' ' ')
  v=$($PY - "$wins" <<'EOF'
import re, sys
ws = [tuple(map(int, m)) for m in re.findall(r"\((-?\d+),(-?\d+)\)\((\d+)x(\d+)\)", sys.argv[1])]
top = min((w[1] for w in ws), default=9999)
bottom = max((w[1] + w[3] for w in ws), default=0)
print("OK" if ws and top <= 2085 and bottom >= 2265 and len(ws) <= 2 else "BAD")
EOF
)
  echo "  run $r: $v boxes=[$wins]"
  [ "$v" = OK ] && ok=$((ok + 1)) || bad=$((bad + 1))
done
if [ $bad -gt 0 ]; then echo "FAIL typewriter: ok=$ok bad=$bad"; exit 1; fi
echo "PASS typewriter: $ok/$runs runs"
