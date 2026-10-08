# Live validation: GitHub Enterprise Managed User owners (`<name>_<shortcode>`)

Driven on 2026-10-08 against real github.com with the machine's existing `matthew-moorcroft_data` gh login
(token passed per child process via `GH_TOKEN`; no credential store edited), inside two disposable lab homes
minted with `bin/fm-lab-home.sh create`, private tmux socket dirs, and a read-only `gh` guard first on PATH that
forwards only read calls (`pr view`, GET `api`, non-mutation GraphQL) and refuses everything else. Labs torn down.
Base-commit comparisons ran the `bin/` tree of 19fcbbd extracted with `git archive`.

| Transcript | Scenario | Result |
|---|---|---|
| s1-record-transcript.txt | `fm-pr-check.sh` records matthew-moorcroft_data/personal_management PR 9 | base: `invalid PR check request` exit 2; fix: `pr=` + live `pr_head=169e2bd…`, poll byte-identical to bin/fm-pr-poll.sh |
| s2-poll-watch-transcript.txt | armed poll + real `bin/fm-watch.sh` detect the merged EMU PR | poll prints `merged`; watcher queues `check: merge landed: task-a …/pull/9 external` |
| s3-contributions-transcript.txt | contribution poll observation counts as measured coverage | fix: known 1 / checked 1 / complete; base: known 0 / incomplete |
| s4b-merge-transcript.txt (s4-merge-transcript.txt: first attempt) | `fm-pr-merge.sh` on approved EMU PR 13 | base: `invalid PR merge request` exit 2, no forge read; fix: live preflight reads PR, branch protection and rules, refuses only `state is "MERGED", not open`; no `gh pr merge` issued |
| s5-adversarial-transcript.txt | malformed underscore owners refused; 3/8-char short code and 39-char limit accepted | 0 mismatches across check, merge, and armed poll |

s4-merge-transcript.txt stopped at the captain-hold check because installed tasks-axi is 0.2.5 (< required 0.2.6);
s4b repeats it in a home with no backlog file (no captain calls recorded), which is a supported configuration.
