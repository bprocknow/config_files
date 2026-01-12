# config_files

Setup for a new machine's shell/editor/tmux config plus helper scripts.

## Install

```bash
./install.sh
```

## Notes

- `install.sh` appends `bash/bashrc` into `~/.bashrc` before any `unset rc` line when present.
- `bin/` scripts are symlinked into `~/bin` so updates from `git pull` are picked up automatically.
- `tmux/tmux_setup.sh` runs on interactive shell startup (when not already inside tmux).
