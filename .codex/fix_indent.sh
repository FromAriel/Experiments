#!/usr/bin/env bash
###############################################################################
# fix_indent.sh – format changed *.gd files with gdformat
# Usage:  fix_indent.sh <file> ...
# Exits 0 on success, 1 on any gdformat failure or timeout
###############################################################################
set -euo pipefail

TIMEOUT_SEC=20

# -----------------------------------------------------------------------------
# Gather .gd files from arguments
# -----------------------------------------------------------------------------
files=()
for f in "$@"; do
    [[ $f == *.gd ]] && files+=("$f")
done

[[ ${#files[@]} -eq 0 ]] && exit 0   # nothing to format

# -----------------------------------------------------------------------------
# Build gdformat args
# -----------------------------------------------------------------------------
GD_ARGS=(--use-spaces --indent-width 4)

# -----------------------------------------------------------------------------
# Run formatter with timeout, capture output
# -----------------------------------------------------------------------------
LOG_FILE="$(mktemp /tmp/gdformat.XXXXXX.log)"
if ! timeout "${TIMEOUT_SEC}s" gdformat "${GD_ARGS[@]}" "${files[@]}" &> "$LOG_FILE"; then
    {
        echo "⚠️  gdformat failed or exceeded ${TIMEOUT_SEC}s."
        echo "    Commit or task aborted. See detailed logs below."
        echo "CODEX: ❌ gdformat failed or timed out after ${TIMEOUT_SEC}s"
        echo "CODEX: 📄 log available at $LOG_FILE"
        echo "──── gdformat log excerpt ────"
        tail -n 20 "$LOG_FILE"
        echo "──── (full log in $LOG_FILE) ────"
    } >&2
    exit 1
fi

exit 0
