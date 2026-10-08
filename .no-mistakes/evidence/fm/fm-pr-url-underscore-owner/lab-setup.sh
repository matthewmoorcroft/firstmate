#!/usr/bin/env bash
# Phase 0: mint the disposable lab home, private tmux dir, read-only gh guard, and base-commit scripts.
set -eu
WT=/Users/matthew.moorcroft/.no-mistakes/worktrees/638bed71b7da/01M4EQY740JGE1MK2YQ5YCT43Z
EVD=/Users/matthew.moorcroft/.no-mistakes/evidence/01M4EQY740JGE1MK2YQ5YCT43Z
cd "$WT"
LAB=$(mktemp -d "${TMPDIR:-/tmp}/fm-lab.XXXXXX")
bin/fm-lab-home.sh create "$LAB" >/dev/null
TMUXD=$(bin/fm-lab-home.sh tmux-dir "$LAB")
SCR=$(mktemp -d "${TMPDIR:-/tmp}/fm-emu-scratch.XXXXXX")
mkdir -p "$SCR/guard" "$SCR/base"
git archive 19fcbbde12c4e916e0d5faa60c399d2fd2845740 bin | tar -x -C "$SCR/base"
cat > "$SCR/guard/gh" <<'GH'
#!/usr/bin/env bash
# Lab guard: forward read-only gh calls to the real gh; refuse anything that could write to GitHub.
real=/opt/homebrew/bin/gh
printf '%s\n' "$*" >> "$GH_CALL_LOG"
refuse() { printf 'REFUSED %s\n' "$*" >> "$GH_CALL_LOG"; echo "fm-lab gh guard: refused non-read gh call: $*" >&2; exit 97; }
case "${1:-} ${2:-}" in
  "pr view"|"pr checks"|"pr list"|"pr status") exec "$real" "$@" ;;
esac
if [ "${1:-}" = api ]; then
  if [ "${2:-}" = graphql ]; then
    case "$*" in *mutation*) refuse "$@" ;; esac
    exec "$real" "$@"
  fi
  method= fields=0 prev=
  for a in "${@:2}"; do
    case "$prev" in -X|--method) method=$a ;; esac
    case "$a" in
      -X?*) method=${a#-X} ;;
      --method=*) method=${a#--method=} ;;
      -f|-F|--field|--raw-field|--input|-f?*|-F?*|--field=*|--raw-field=*|--input=*) fields=1 ;;
    esac
    prev=$a
  done
  case "$method" in GET|get) exec "$real" "$@" ;; '') [ "$fields" = 0 ] && exec "$real" "$@" ;; esac
fi
refuse "$@"
GH
chmod +x "$SCR/guard/gh"
git init -q "$LAB/wt"
printf 'LAB=%s\nTMUXD=%s\nSCR=%s\n' "$LAB" "$TMUXD" "$SCR" > "$EVD/lab-paths.env"
cat "$EVD/lab-paths.env"
ls -la "$LAB"
