#!/usr/bin/env bash
set -e

warn() { echo -e "\033[0;33m[WARN]\033[0m $1"; }

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
  # Make brew available in this shell session immediately after install
  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed"
}

# ── Section 2: CLI tools ──────────────────────────────────────────────────────
install_cli_tools() {
  info "Section 2 — CLI tools: autojump, fzf, lazygit, gh, hub, nvm"
  brew install autojump fzf lazygit gh hub nvm
  if [[ ! -f "$HOME/.fzf.zsh" ]]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
  fi
  success "CLI tools installed"
}

# ── Section 3: ZSH plugins ────────────────────────────────────────────────────
install_zsh_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  info "Section 3 — oh-my-zsh + ZSH plugins: zsh-autosuggestions, zsh-syntax-highlighting, powerlevel10k"

  if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended
  else
    success "oh-my-zsh already installed — skipping"
  fi

  if [[ ! -d "$custom/plugins/zsh-autosuggestions/.git" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$custom/plugins/zsh-autosuggestions"
  else
    success "zsh-autosuggestions already present — skipping"
  fi

  if [[ ! -d "$custom/plugins/zsh-syntax-highlighting/.git" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom/plugins/zsh-syntax-highlighting"
  else
    success "zsh-syntax-highlighting already present — skipping"
  fi

  if [[ ! -d "$custom/themes/powerlevel10k/.git" ]]; then
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
  echo "║  2) CLI tools  (autojump · fzf · lazygit · gh · hub · nvm) ║"
  echo "║  3) ZSH plugins (autosuggestions · syntax · p10k)     ║"
  echo "║  4) Dotfiles   (rsync to ~/)                          ║"
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
    *) warn "Unknown section: $1" ;;
  esac
}

main() {
  if [[ "$(uname -m)" != "arm64" ]]; then
    echo "Error: this installer targets Apple Silicon (arm64). Detected: $(uname -m)." >&2
    exit 1
  fi

  # Non-interactive: --force / -f runs everything
  if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    install_brew; install_cli_tools; install_zsh_plugins; install_dotfiles
    return
  fi

  while true; do
    show_menu
    read -rp "Enter choice: " choice
    case "$choice" in
      1|2|3|4) (set -e; run_section "$choice") || warn "Section $choice failed — continuing" ;;
      a|A)
        (set -e; install_brew)        || warn "Homebrew failed"
        (set -e; install_cli_tools)   || warn "CLI tools failed"
        (set -e; install_zsh_plugins) || warn "ZSH plugins failed"
        (set -e; install_dotfiles)    || warn "Dotfiles failed"
        break ;;
      q|Q) echo "Bye."; break ;;
      *) echo "Unknown option — try 1–4, a, or q." ;;
    esac
  done
}

main "$@"
