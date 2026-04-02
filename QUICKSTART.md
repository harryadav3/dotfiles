# Quick Start Guide

## For SSH/Remote Servers

```bash
# Clone and run
git clone https://github.com/harryadav3/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x setup-new.sh
./setup-new.sh --ssh
```

**What you get**: zsh + vim + neovim + tmux + ranger + fzf + ripgrep + bat

---

## For Desktop with i3

```bash
# Clone and run
git clone https://github.com/harryadav3/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x setup-new.sh
./setup-new.sh --desktop
```

**What you get**: Everything from SSH setup + i3 + kitty + dunst + desktop environment

---

## After Installation

1. **Logout and login** (for zsh to activate)
2. **Install vim plugins**: `vim +PlugInstall +qall`
3. **Install nvim plugins**: `nvim +PlugInstall +qall`
4. **Install tmux plugins**: Open tmux, press `Ctrl+b` then `Shift+I`

---

## Commands

```bash
./setup-new.sh --ssh      # Minimal setup
./setup-new.sh --desktop  # Full desktop setup
./setup-new.sh --list     # List all packages
./setup-new.sh --help     # Show help
```

---

## Supported Systems

✅ Ubuntu / Debian  
✅ Arch Linux / Manjaro

---

## Files Location

- Configs: `~/.dotfiles/`
- Backups: `~/.dotfiles_backup_TIMESTAMP/`
- Package definitions: `scripts/packages.sh`
- Common functions: `scripts/common.sh`
