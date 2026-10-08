# Shared setup for the live EMU-owner lab drive. Sourced by each phase.
# Paths only; the EMU token is read per call with `gh auth token --user` and never written to disk.
WT=/Users/matthew.moorcroft/.no-mistakes/worktrees/638bed71b7da/01M4EQY740JGE1MK2YQ5YCT43Z
EVD=/Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z
. "$EVD/lab-paths.env"
EMU_URL=https://github.com/matthew-moorcroft_data/personal_management/pull/9
GHTOK=$(/opt/homebrew/bin/gh auth token --user matthew-moorcroft_data)
GHLOG="$SCR/gh-calls.log"
# Run a firstmate entrypoint in the lab: runbook env scrub, lab FM_HOME, private
# tmux socket dir, EMU token for this child only, read-only gh guard first on PATH.
labrun() {
  env -u NO_MISTAKES_GATE -u FM_GATE_REFUSE_BYPASS -u FM_ROOT_OVERRIDE -u FM_STATE_OVERRIDE \
    -u FM_DATA_OVERRIDE -u FM_CONFIG_OVERRIDE -u FM_PROJECTS_OVERRIDE -u TMUX \
    TMUX_TMPDIR="$TMUXD" FM_HOME="$LAB" GH_TOKEN="$GHTOK" GH_CALL_LOG="$GHLOG" \
    PATH="$SCR/guard:$PATH" "$@"
}
show() { printf '\n$ %s\n' "$*"; }
