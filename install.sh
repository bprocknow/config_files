#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC_SNIPPET="$ROOT_DIR/bash/bashrc"

link_file() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.bak"
    fi

    ln -sfn "$src" "$dest"
}

ensure_bashrc() {
    local bashrc="$HOME/.bashrc"
    local has_rg=0

    if [ ! -f "$bashrc" ]; then
        touch "$bashrc"
    fi

    if command -v rg >/dev/null 2>&1; then
        has_rg=1
    fi

    if [ "$has_rg" -eq 1 ]; then
        if rg --quiet "config_files" "$bashrc"; then
            return 0
        fi
    else
        if grep -q "config_files" "$bashrc"; then
            return 0
        fi
    fi

    if [ "$has_rg" -eq 1 ]; then
        if rg --quiet '^[[:space:]]*unset[[:space:]]+rc' "$bashrc"; then
            awk -v snippet_file="$BASHRC_SNIPPET" '
                function print_snippet() {
                    while ((getline line < snippet_file) > 0) {
                        print line
                    }
                    close(snippet_file)
                }
                /^[[:space:]]*unset[[:space:]]+rc/ && !inserted {
                    print_snippet()
                    inserted = 1
                }
                { print }
                END {
                    if (!inserted) {
                        print_snippet()
                    }
                }
            ' "$bashrc" > "${bashrc}.tmp"
        else
            cat "$bashrc" "$BASHRC_SNIPPET" > "${bashrc}.tmp"
        fi
    else
        if grep -q '^[[:space:]]*unset[[:space:]]\+rc' "$bashrc"; then
            awk -v snippet_file="$BASHRC_SNIPPET" '
                function print_snippet() {
                    while ((getline line < snippet_file) > 0) {
                        print line
                    }
                    close(snippet_file)
                }
                /^[[:space:]]*unset[[:space:]]+rc/ && !inserted {
                    print_snippet()
                    inserted = 1
                }
                { print }
                END {
                    if (!inserted) {
                        print_snippet()
                    }
                }
            ' "$bashrc" > "${bashrc}.tmp"
        else
            cat "$bashrc" "$BASHRC_SNIPPET" > "${bashrc}.tmp"
        fi
    fi

    mv "${bashrc}.tmp" "$bashrc"
}

main() {
    ensure_bashrc

    link_file "$ROOT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
    link_file "$ROOT_DIR/vim/vimrc" "$HOME/.vimrc"

    mkdir -p "$HOME/bin"
    for script in "$ROOT_DIR/bin"/*; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            link_file "$script" "$HOME/bin/$(basename "$script")"
        fi
    done

    if [ -f "$ROOT_DIR/desktop/FreeCAD.desktop" ]; then
        link_file "$ROOT_DIR/desktop/FreeCAD.desktop" "$HOME/.local/share/applications/FreeCAD.desktop"
    fi

    echo "dnf install tmux vim npm"
    echo "npm install @openai/codex"
    echo "Install complete. Restart your shell to pick up bashrc changes."
}

main "$@"
