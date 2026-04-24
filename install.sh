#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[ OK ]${NC} $1"; }

# ── Section 1: Homebrew ───────────────────────────────────────────────────────
install_brew() {
  info "Section 1 — Homebrew"
  if command -v brew &>/dev/null; then
    success "Homebrew already installed — skipping"
    return
  fi
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  success "Homebrew installed"
}

# ── Section 2: CLI tools ──────────────────────────────────────────────────────
install_cli_tools() {
  info "Section 2 — CLI tools: autojump, fzf, lazygit, gh, hub"
  brew install autojump fzf lazygit gh hub
  if [[ ! -f "$HOME/.fzf.zsh" ]]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
  fi
  success "CLI tools installed"
}

# ── Section 3: ZSH plugins ────────────────────────────────────────────────────
install_zsh_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  info "Section 3 — ZSH plugins: zsh-autosuggestions, zsh-syntax-highlighting, powerlevel10k"

  if [[ ! -d "$custom/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$custom/plugins/zsh-autosuggestions"
  else
    success "zsh-autosuggestions already present — skipping"
  fi

  if [[ ! -d "$custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom/plugins/zsh-syntax-highlighting"
  else
    success "zsh-syntax-highlighting already present — skipping"
  fi

  if [[ ! -d "$custom/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$custom/themes/powerlevel10k"
  else
    success "powerlevel10k already present — skipping"
  fi

  success "ZSH plugins and theme installed"
}

# ── Section 4: Dotfiles ───────────────────────────────────────────────────────
install_dotfiles() {
  info "Section 4 — Syncing dotfiles to $HOME"
  rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude "bootstrap.sh" \
        --exclude "install.sh" \
        --exclude "docs/" \
        --exclude "scripts/" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        --exclude "Brewfile" \
        -avh --no-perms "$DOTFILES_DIR/" "$HOME/"
  success "Dotfiles synced to $HOME"
}

# ── Menu ──────────────────────────────────────────────────────────────────────
show_menu() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║         dotfiles installer — choose a section         ║"
  echo "╠═══════════════════════════════════════════════════════╣"
  echo "║  1) Homebrew                                          ║"
  echo "║  2) CLI tools  (autojump · fzf · lazygit · gh)       ║"
  echo "║  3) ZSH plugins (autosuggestions · syntax · p10k)    ║"
  echo "║  4) Dotfiles   (rsync to ~/)                         ║"
  echo "║  a) All of the above                                  ║"
  echo "║  q) Quit                                              ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
}

run_section() {
  case "$1" in
    1) install_brew ;;
    2) install_cli_tools ;;
    3) install_zsh_plugins ;;
    4) install_dotfiles ;;
  esac
}

main() {
  # Non-interactive: --force / -f runs everything
  if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    install_brew; install_cli_tools; install_zsh_plugins; install_dotfiles
    return
  fi

  while true; do
    show_menu
    read -rp "Enter choice: " choice
    case "$choice" in
      1|2|3|4) run_section "$choice" ;;
      a|A)
        install_brew; install_cli_tools; install_zsh_plugins; install_dotfiles
        break ;;
      q|Q) echo "Bye."; break ;;
      *) echo "Unknown option — try 1–4, a, or q." ;;
    esac
  done
}

main "$@"
