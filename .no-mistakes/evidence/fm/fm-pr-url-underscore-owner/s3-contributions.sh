#!/usr/bin/env bash
# Scenario 3: the EMU PR the watcher observed counts as a measured contribution (fixed) and not at base.
set -u
. /Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z/lab-common.sh
cd "$WT"
echo "=== durable record the real contribution poll wrote: data/task-a/contributions.json ==="
jq '{schema,task,records:[.records[]|{url,kind,checked_at,error,observation:{state:.observation.state,head:.observation.head,draft:.observation.draft,review_decision:.observation.review_decision,checks:(.observation.checks|length)}}]}' "$LAB/data/task-a/contributions.json"
show "bin/fm-fleet-snapshot.sh --contribution-input > input.json"
labrun bin/fm-fleet-snapshot.sh --contribution-input > "$SCR/contrib-input.json"; echo "exit=$?"
jq -c '{backlog_present:.backlog.present,tasks:[.tasks[]|{id,pr:.pr.url}]}' "$SCR/contrib-input.json" 2>/dev/null || head -c 600 "$SCR/contrib-input.json"
echo
echo "=== TARGET: fm-contributions.sh snapshot (fixed canonical_url) ==="
show "bin/fm-contributions.sh snapshot input.json --all"
labrun bin/fm-contributions.sh snapshot "$SCR/contrib-input.json" --all | tee "$SCR/snap-fixed.json" | jq '{known,checked,complete,counts,rows:[(.rows//[])[]|{task,url,state,actor}]}' 2>/dev/null || cat "$SCR/snap-fixed.json"
echo
echo "=== BASE 19fcbbd: same read-only snapshot over the same saved record ==="
show "base bin/fm-contributions.sh snapshot input.json --all"
labrun "$SCR/base/bin/fm-contributions.sh" snapshot "$SCR/contrib-input.json" --all | tee "$SCR/snap-base.json" | jq '{known,checked,complete,counts,rows:[(.rows//[])[]|{task,url,state,actor}]}' 2>/dev/null || cat "$SCR/snap-base.json"
