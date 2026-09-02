#!/usr/bin/env bash
# Wipe the production Isar database so the next Linux desktop launch is
# first-run (Welcome). Execute this script; do not rewrite it per walk.
#
# Stop the running gym_app process first (kill by PID, not pkill -f).
# Isar.open uses getApplicationDocumentsDirectory().

set -euo pipefail

candidates=()
if command -v xdg-user-dir >/dev/null 2>&1; then
  candidates+=("$(xdg-user-dir DOCUMENTS)")
fi
candidates+=("${HOME}/Documents")
candidates+=("${XDG_DATA_HOME:-$HOME/.local/share}")
candidates+=("${HOME}/.local/share")

found=0
seen=""
for dir in "${candidates[@]}"; do
  [ -n "${dir}" ] && [ -d "${dir}" ] || continue
  case " ${seen} " in
    *" ${dir} "*) continue ;;
  esac
  seen="${seen} ${dir}"
  while IFS= read -r -d '' f; do
    echo "removing ${f}"
    rm -f "${f}"
    found=1
  done < <(find "${dir}" -maxdepth 4 \( -name 'default.isar' -o -name 'default.isar.lock' \) -print0 2>/dev/null || true)
done

if [ "${found}" -eq 0 ]; then
  echo "no default.isar found under:${seen}"
  echo "next launch is already a first run, or the app has not been run yet"
fi
