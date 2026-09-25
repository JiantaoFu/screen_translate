#!/usr/bin/env bash
# Usage: fdprobe.sh [mode]   (default video)
# Report only, no pass/fail: samples the app's open file descriptors every
# 10s for 60s while live translation runs over a harness screen, then shows
# the most common fd targets. Image.getPlanes() leaks a sync_file fd per
# frame on the emulator; capture reads are throttled to limit it. Compare the
# growth against earlier runs when touching the capture pipeline.
source "$(dirname "$0")/common.sh"
harness "${1:-video}"
pid=$(app_pid)
fds() { $A shell run-as $PKG ls /proc/$pid/fd 2>/dev/null | wc -l | tr -d ' '; }
start=$(fds)
for i in 1 2 3 4 5 6; do sleep 10; echo "  +$((i * 10))s fds=$(fds)"; done
end=$(fds)
$A shell run-as $PKG ls -l /proc/$pid/fd 2>/dev/null | awk '{print $NF}' \
  | sed -E 's/[0-9]+/N/g' | sort | uniq -c | sort -rn | head -3
echo "INFO fd growth: $start -> $end in 60s ($(( (end - start) / 60 ))/s)"
