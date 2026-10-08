#!/usr/bin/env bash
# Scenario 4b: guarded merge in a second, clean lab home that records no captain calls (no backlog file),
# so the hold check is "absent, not held" without needing tasks-axi >= 0.2.6 (installed: 0.2.5).
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
LAB=$(mktemp -d "${TMPDIR:-/tmp}/fm-lab.XXXXXX"); bin/fm-lab-home.sh create "$LAB" >/dev/null
TMUXD=$(bin/fm-lab-home.sh tmux-dir "$LAB")
printf 'LAB2=%s\nTMUXD2=%s\n' "$LAB" "$TMUXD" >> "$EVD/lab-paths.env"
git init -q "$LAB/wt"
URL13=https://github.com/matthew-moorcroft_data/personal_management/pull/13
( umask 077; printf '%s\n' "window=fm-lab:fm-task-c" "endpoint_task_id=task-c" "worktree=$LAB/wt" \
    "project=$LAB/projects/personal_management" kind=ship mode=no-mistakes > "$LAB/state/task-c.meta" )
: > "$GHLOG"
echo "=== BASE 19fcbbd: guarded merge of the approved EMU PR ==="
show "bin/fm-pr-merge.sh task-c $URL13 -- --merge   # base scripts"
labrun "$SCR/base/bin/fm-pr-merge.sh" task-c "$URL13" -- --merge; echo "exit=$?"
echo "gh calls made by base: $(wc -l < "$GHLOG" | tr -d ' ')"
echo
echo "=== TARGET 807866a: guarded merge of the same EMU PR ==="
: > "$GHLOG"
show "bin/fm-pr-merge.sh task-c $URL13 -- --merge"
labrun bin/fm-pr-merge.sh task-c "$URL13" -- --merge 2>&1 | grep -v '^●'; echo "exit=${PIPESTATUS[0]}"
echo "--- real gh calls (via read-only guard) ---"; cat "$GHLOG"
echo "--- any merge attempted or refused by the guard? ---"
grep -E '^(pr merge|REFUSED)' "$GHLOG" || echo "none: no gh pr merge was issued"
echo "--- state/task-c.meta ---"; cat "$LAB/state/task-c.meta"
