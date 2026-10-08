#!/usr/bin/env bash
# Scenario 2: the armed static poll and the real watcher detect the EMU PR's merged state on GitHub.
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
: > "$GHLOG"
echo "=== armed poll run directly, the way the watcher runs a check ==="
show "bash state/task-a.check.sh"
out=$(labrun bash "$LAB/state/task-a.check.sh"); rc=$?
printf 'stdout=[%s] exit=%s\n' "$out" "$rc"
echo "--- real gh calls ---"; cat "$GHLOG"

echo
echo "=== real watcher (bin/fm-watch.sh) in the lab home, bounded to 120s ==="
: > "$GHLOG"
show "FM_CHECK_INTERVAL=0 FM_POLL=0.5 bin/fm-watch.sh"
labrun FM_CHECK_INTERVAL=0 FM_POLL=0.5 FM_HEARTBEAT=999999 FM_SIGNAL_GRACE=0 \
  perl -e 'alarm 120; exec @ARGV or die' bin/fm-watch.sh > "$SCR/watch.out" 2> "$SCR/watch.err"; rc=$?
echo "watcher exit=$rc"
echo "--- watcher stdout ---"; cat "$SCR/watch.out"
echo "--- watcher stderr (tail) ---"; tail -20 "$SCR/watch.err"
echo "--- real gh calls made by watcher checks ---"; cat "$GHLOG"
echo "--- state/.wake-queue ---"; cat "$LAB/state/.wake-queue" 2>/dev/null || echo "(none)"
