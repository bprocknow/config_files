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
#   Windows:
#     1. application (no startup command)
#     2. codex (startup command: codex)
#     3. Editor (three panes)
#     4. terminal (no startup command)

set -euo pipefail

# ------------------- STATIC CONFIG HERE -------------------

# Session name (can be overridden by first CLI argument)
SESSION_NAME="${1:-$(basename "$PWD")}"

# Project root (working directory for all panes/windows)
PROJECT_ROOT="$PWD"

# ------------------- END STATIC CONFIG -------------------

# If session already exists, just attach to it
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Attaching to existing tmux session: $SESSION_NAME"
    exec tmux attach -t "$SESSION_NAME"
fi

echo "Creating new tmux session: $SESSION_NAME in $PROJECT_ROOT"

# 1) application window (no startup command)
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_ROOT" -n application

# 2) codex window (startup command: codex)
tmux new-window -t "$SESSION_NAME" -n codex -c "$PROJECT_ROOT"
tmux send-keys  -t "$SESSION_NAME:codex" codex C-m

# 3) Editor window with three panes
tmux new-window -t "$SESSION_NAME" -n Editor -c "$PROJECT_ROOT"
tmux split-window -h -t "$SESSION_NAME:Editor.0" -c "$PROJECT_ROOT"
tmux split-window -v -t "$SESSION_NAME:Editor.1" -c "$PROJECT_ROOT"

# 4) terminal window (no startup command)
tmux new-window -t "$SESSION_NAME" -n terminal -c "$PROJECT_ROOT"

# Focus back to the Editor window, first (left) pane
tmux select-window -t "$SESSION_NAME:Editor"
tmux select-pane   -t "$SESSION_NAME:Editor.0"


# Attach to session
tmux attach -t "$SESSION_NAME"
