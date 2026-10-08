#!/usr/bin/env bash
# Scenario 1: record the real EMU PR with fm-pr-check.sh (fixed) vs the base commit's scripts.
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
write_meta() { # id
  ( umask 077; printf '%s\n' "window=fm-lab:fm-$1" "endpoint_task_id=$1" "worktree=$LAB/wt" \
      "project=$LAB/projects/personal_management" kind=ship mode=no-mistakes > "$LAB/state/$1.meta" )
}
printf '# Backlog\n\n## Queued\n- [ ] task-a - Merge vault PR %s (repo: personal_management) (kind: ship)\n' "$EMU_URL" > "$LAB/data/backlog.md"
write_meta task-a
: > "$GHLOG"

echo "=== BASE commit 19fcbbd (before the fix): fm-pr-check.sh on the EMU URL ==="
show "bin/fm-pr-check.sh task-a $EMU_URL   # base scripts"
labrun "$SCR/base/bin/fm-pr-check.sh" task-a "$EMU_URL"; echo "exit=$?"
echo "gh calls made by base: $(wc -l < "$GHLOG" | tr -d ' ')"
echo "meta pr= after base: $(grep -c '^pr=' "$LAB/state/task-a.meta")"

echo
echo "=== TARGET commit 807866a (the fix): fm-pr-check.sh on the EMU URL ==="
show "bin/fm-pr-check.sh task-a $EMU_URL"
labrun bin/fm-pr-check.sh task-a "$EMU_URL"; echo "exit=$?"
echo
echo "--- real gh calls (via read-only guard) ---"; cat "$GHLOG"
echo "--- state/task-a.meta ---"; cat "$LAB/state/task-a.meta"
echo "--- state/task-a.pr-poll (sidecar) ---"; cat "$LAB/state/task-a.pr-poll"
echo "--- armed check is byte-identical to bin/fm-pr-poll.sh? ---"
cmp "$LAB/state/task-a.check.sh" bin/fm-pr-poll.sh && echo "yes: cmp identical"
ls -l "$LAB/state/" | sed 1d
