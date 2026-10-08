#!/usr/bin/env bash
# Scenario 4: fm-pr-merge.sh on a real (already merged) EMU PR - base refuses the URL, the fix reaches
# the live forge preflight. The read-only gh guard would refuse any `gh pr merge`; none is attempted.
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
URL13=https://github.com/matthew-moorcroft_data/personal_management/pull/13
( umask 077; printf '%s\n' "window=fm-lab:fm-task-c" "endpoint_task_id=task-c" "worktree=$LAB/wt" \
    "project=$LAB/projects/personal_management" kind=ship mode=no-mistakes > "$LAB/state/task-c.meta" )
printf -- '- [ ] task-c - Merge vault PR %s (repo: personal_management) (kind: ship)\n' "$URL13" >> "$LAB/data/backlog.md"
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
echo "--- state/task-c.meta after merge preflight ---"; cat "$LAB/state/task-c.meta"
