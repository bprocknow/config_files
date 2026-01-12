#!/usr/bin/env bash
#
# tmux_project_layout.sh
#
# Usage:
#   ./tmux_project_layout.sh [session-name]
#
# If no session-name is passed, uses the current directory name.
#
# Layout:
#   One main window with up to 3 panes:
#     Pane 1 (EDITOR): left half
#     Pane 2 (codex):  top right
#     Pane 3 (mcp-server): bottom right
#   Optional 4th entry -> separate tmux window.

set -euo pipefail

# ------------------- STATIC CONFIG HERE -------------------

# Session name (can be overridden by first CLI argument)
SESSION_NAME="${1:-$(basename "$PWD")}"

# Project root (working directory for all panes/windows)
PROJECT_ROOT="$PWD"

# Define up to 4 "windows" (entries).
# First 3 are used as panes in the main window.
# 4th, if present, becomes an additional tmux window.

WINDOW_NAMES=(
  "EDITOR"
  "codex"
  "mcp-server"
  # "extra"       # <- optional 4th name; uncomment/add if needed
)

WINDOW_CMDS=(
  "bash"
  "codex"
  "ssh mcp@mcp"
  # "top"         # <- matching command for 4th entry, if used
)

# ------------------- END STATIC CONFIG -------------------

# Sanity check
if [ "${#WINDOW_NAMES[@]}" -ne "${#WINDOW_CMDS[@]}" ]; then
    echo "Error: WINDOW_NAMES and WINDOW_CMDS must have the same length." >&2
    exit 1
fi

ENTRY_COUNT="${#WINDOW_NAMES[@]}"

if [ "$ENTRY_COUNT" -lt 1 ]; then
    echo "Error: Define at least one entry in WINDOW_NAMES/CMDS." >&2
    exit 1
fi

# If session already exists, just attach to it
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Attaching to existing tmux session: $SESSION_NAME"
    exec tmux attach -t "$SESSION_NAME"
fi

echo "Creating new tmux session: $SESSION_NAME in $PROJECT_ROOT"

# 1) Create session with first entry as a single pane
FIRST_NAME="${WINDOW_NAMES[0]}"
FIRST_CMD="${WINDOW_CMDS[0]}"

tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_ROOT" -n "$FIRST_NAME"
tmux send-keys -t "$SESSION_NAME:0.0" "$FIRST_CMD" C-m

# 2) If we have a 2nd entry, create right column and pane 2
if [ "$ENTRY_COUNT" -ge 2 ]; then
    SECOND_NAME="${WINDOW_NAMES[1]}"
    SECOND_CMD="${WINDOW_CMDS[1]}"

    # Split the original pane horizontally to create a right pane
    # Result: left pane (0) and right pane (1)
    tmux split-window -h -t "$SESSION_NAME:0.0" -c "$PROJECT_ROOT"

    # Run command in right pane
    tmux send-keys -t "$SESSION_NAME:0.1" "$SECOND_CMD" C-m

    # Rename window to the first name explicitly (optional but clear)
    tmux rename-window -t "$SESSION_NAME:0" "$FIRST_NAME"
fi

# 3) If we have a 3rd entry, split the right pane vertically
#    into top-right (pane 1) and bottom-right (pane 2).
if [ "$ENTRY_COUNT" -ge 3 ]; then
    THIRD_NAME="${WINDOW_NAMES[2]}"
    THIRD_CMD="${WINDOW_CMDS[2]}"

    # Split the right pane (currently pane 1) vertically (top/bottom)
    tmux split-window -v -t "$SESSION_NAME:0.1" -c "$PROJECT_ROOT"

    # After split:
    #   Left pane      -> 0
    #   Top-right pane -> 1
    #   Bottom-right   -> 2
    # Pane 1 keeps SECOND_CMD; run THIRD_CMD in pane 2.
    tmux send-keys -t "$SESSION_NAME:0.2" "$THIRD_CMD" C-m
fi

# 4) If we have a 4th entry, create it as a separate window
if [ "$ENTRY_COUNT" -ge 4 ]; then
    FOURTH_NAME="${WINDOW_NAMES[3]}"
    FOURTH_CMD="${WINDOW_CMDS[3]}"

    tmux new-window -t "$SESSION_NAME:" -n "$FOURTH_NAME" -c "$PROJECT_ROOT"
    tmux send-keys  -t "$SESSION_NAME:$FOURTH_NAME" "$FOURTH_CMD" C-m
fi

# Focus back to the main window, first (left) pane
tmux select-window -t "$SESSION_NAME:0"
tmux select-pane   -t "$SESSION_NAME:0.0"

# Attach to session
tmux attach -t "$SESSION_NAME"
