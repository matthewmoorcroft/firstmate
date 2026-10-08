#!/usr/bin/env bash
# Scenario 5: malformed underscore owners are refused by fm-pr-check.sh, fm-pr-merge.sh and the armed
# static poll before any forge read; the 3/8-char short code and 39-char boundaries are still accepted.
# Runs under a UTF-8 locale so locale-sensitive bracket ranges are exercised too.
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
( umask 077; printf '%s\n' "window=fm-lab:fm-task-b" "endpoint_task_id=task-b" "worktree=$LAB/wt" \
    "project=$LAB/projects/personal_management" kind=ship mode=no-mistakes > "$LAB/state/task-b.meta" )
before=$(shasum -a 256 "$LAB/state/task-b.meta" | cut -d' ' -f1)
a35=$(printf 'a%.0s' $(seq 35)); a34=$(printf 'a%.0s' $(seq 34))
BAD=(_owner owner_ _ owner__data owner_data_x owner-_data owner_-data owner_da-ta -owner_data owner--x_data
     a_b ab_1 owner_ab owner_abcdefghi "${a35}_data" "ownér_data" "owner_dätä" "owner_da%5Fta" "owner_data/../x")
echo "=== fm-pr-check.sh refuses malformed underscore owners (LC_ALL=$LC_ALL) ==="
printf '%-44s %-5s %-6s %s\n' OWNER EXIT GHCALL STDERR
fails=0
for o in "${BAD[@]}"; do
  : > "$GHLOG"
  err=$(labrun bin/fm-pr-check.sh task-b "https://github.com/$o/personal_management/pull/9" 2>&1 >/dev/null); rc=$?
  n=$(wc -l < "$GHLOG" | tr -d ' ')
  printf '%-44s %-5s %-6s %s\n' "$o" "$rc" "$n" "$err"
  [ "$rc" = 2 ] && [ "$n" = 0 ] && [ "$err" = "error: invalid PR check request" ] || fails=$((fails+1))
done
after=$(shasum -a 256 "$LAB/state/task-b.meta" | cut -d' ' -f1)
[ "$before" = "$after" ] && echo "task-b.meta unchanged after all refusals" || { echo "task-b.meta CHANGED"; fails=$((fails+1)); }
[ ! -e "$LAB/state/task-b.check.sh" ] && echo "no poll armed for task-b" || { echo "poll ARMED for task-b"; fails=$((fails+1)); }

echo
echo "=== fm-pr-merge.sh refuses malformed underscore owners ==="
for o in owner__data a_b owner_abcdefghi "${a35}_data"; do
  : > "$GHLOG"
  err=$(labrun bin/fm-pr-merge.sh task-b "https://github.com/$o/personal_management/pull/9" -- --merge 2>&1 >/dev/null); rc=$?
  n=$(wc -l < "$GHLOG" | tr -d ' ')
  printf '%-44s %-5s %-6s %s\n' "$o" "$rc" "$n" "$err"
  [ "$rc" = 2 ] && [ "$n" = 0 ] || fails=$((fails+1))
done

echo
echo "=== armed static poll (byte-identical bin/fm-pr-poll.sh) revalidates a doctored sidecar ==="
echo "(accepted owners reach real gh, which 404s for these placeholder repos and the poll stays silent;"
echo " refused owners exit before any gh call)"
P="$LAB2/state/task-c.check.sh"; S="$LAB2/state/task-c.pr-poll"; cp "$S" "$SCR/task-c.pr-poll.orig"
printf '%-44s %-9s %-6s %s\n' OWNER EXPECT GHCALL STDOUT
for spec in "a_abc:accept" "a-b_ABCD1234:accept" "${a34}_data:accept" "matthew-moorcroft_data:accept" \
            "owner_:refuse" "owner__data:refuse" "owner_data_x:refuse" "owner-_data:refuse" "owner_-data:refuse" \
            "owner_da-ta:refuse" "a_b:refuse" "ab_1:refuse" "owner_ab:refuse" "owner_abcdefghi:refuse" \
            "${a35}_data:refuse" "ownér_data:refuse"; do
  o=${spec%:*}; want=${spec##*:}
  repo=r; [ "$o" = matthew-moorcroft_data ] && repo=personal_management
  num=1;  [ "$o" = matthew-moorcroft_data ] && num=13
  printf '%s\n%s\n%s\n%s\n%s\n' github "https://github.com/$o/$repo/pull/$num" github.com "$o/$repo" "$num" > "$S"
  : > "$GHLOG"
  out=$(TMUX_TMPDIR="$TMUXD2" FM_HOME="$LAB2" GH_TOKEN="$GHTOK" GH_CALL_LOG="$GHLOG" PATH="$SCR/guard:$PATH" bash "$P" 2>/dev/null)
  n=$(wc -l < "$GHLOG" | tr -d ' ')
  printf '%-44s %-9s %-6s %s\n' "$o" "$want" "$n" "${out:-<silent>}"
  case "$want" in
    accept) [ "$n" -ge 1 ] || fails=$((fails+1)) ;;
    refuse) [ "$n" = 0 ] && [ -z "$out" ] || fails=$((fails+1)) ;;
  esac
done
cp "$SCR/task-c.pr-poll.orig" "$S"
echo
echo "adversarial mismatches: $fails"
