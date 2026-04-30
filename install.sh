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
  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed"
}

# ── Section 2: CLI tools ──────────────────────────────────────────────────────
install_brews() {
  info "Section 2 — CLI brews: autojump, fzf, lazygit, gh, hub, nvm, vim, kubectl"
  brew install autojump fzf lazygit gh hub nvm vim kubectl
  if [[ ! -f "$HOME/.fzf.zsh" ]]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
  fi
  success "CLI brews installed"
}

# ── Section 3: GUI apps (casks) ───────────────────────────────────────────────
install_casks() {
  info "Section 3 — GUI apps (casks): iterm2, kdiff3, docker"
  for cask in iterm2 kdiff3 docker; do
    if brew list --cask "$cask" &>/dev/null; then
      brew upgrade --cask "$cask" || warn "$cask upgrade failed (may need GUI sudo) — skipping"
    else
      brew install --cask "$cask" || warn "$cask install failed (may need GUI sudo) — skipping"
    fi
  done
  success "Casks done"
}

# ── Section 4: ZSH plugins ────────────────────────────────────────────────────
install_zsh_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  info "Section 4 — oh-my-zsh + ZSH plugins: zsh-autosuggestions, zsh-syntax-highlighting, powerlevel10k"

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

# ── Section 5: Dotfiles ───────────────────────────────────────────────────────
install_dotfiles() {
  info "Section 5 — Syncing dotfiles to $HOME"
  rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude "install.sh" \
        --exclude "docs/" \
        --exclude "scripts/" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        -avh --no-perms "$DOTFILES_DIR/" "$HOME/"

  if [[ ! -f "$HOME/.shellrc-custom" ]]; then
    cat > "$HOME/.shellrc-custom" <<'EOF'
# Machine-local shell config — never committed to git.
# Add aliases, env vars, or overrides specific to this machine here.
# This file is sourced at the end of ~/.shellrc so anything here takes precedence.
#
# Examples:
#   export SOME_SECRET="..."
#   alias work="cd ~/Work/my-company"
EOF
  fi
  success ".shellrc-custom — edit it with: vim ~/.shellrc-custom"

  if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  vim +PlugInstall +qall

  success "Dotfiles synced and vim plugins installed"
}

# ── Menu ──────────────────────────────────────────────────────────────────────
show_menu() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║           dotfiles installer — choose a section             ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  1) Homebrew                                                 ║"
  echo "║  2) CLI brews  (autojump · fzf · lazygit · gh · hub · nvm   ║"
  echo "║                 vim · kubectl)                               ║"
  echo "║  3) GUI apps   (iterm2 · kdiff3 · docker)                   ║"
  echo "║  4) ZSH plugins (autosuggestions · syntax · p10k)           ║"
  echo "║  5) Dotfiles   (rsync to ~/ + vim-plug install)             ║"
  echo "║  a) All of the above                                        ║"
  echo "║  q) Quit                                                    ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

run_section() {
  case "$1" in
    1) install_brew ;;
    2) install_brews ;;
    3) install_casks ;;
    4) install_zsh_plugins ;;
    5) install_dotfiles ;;
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
    (set -e; install_brew)        || warn "Homebrew failed"
    (set -e; install_brews)       || warn "CLI brews failed"
    (set -e; install_casks)       || warn "Casks failed"
    (set -e; install_zsh_plugins) || warn "ZSH plugins failed"
    (set -e; install_dotfiles)    || warn "Dotfiles failed"
    return
  fi

  while true; do
    show_menu
    read -rp "Enter choice: " choice
    case "$choice" in
      1|2|3|4|5) (set -e; run_section "$choice") || warn "Section $choice failed — continuing" ;;
      a|A)
        (set -e; install_brew)        || warn "Homebrew failed"
        (set -e; install_brews)       || warn "CLI brews failed"
        (set -e; install_casks)       || warn "Casks failed"
        (set -e; install_zsh_plugins) || warn "ZSH plugins failed"
        (set -e; install_dotfiles)    || warn "Dotfiles failed"
        break ;;
      q|Q) echo "Bye."; break ;;
      *) echo "Unknown option — try 1–5, a, or q." ;;
    esac
  done
}

main "$@"
