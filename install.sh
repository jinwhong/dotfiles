#!/bin/bash
# =============================================================================
# dotfiles install script
# 사용법: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# 심볼릭 링크 생성 함수
link_file() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
        echo "  기존 파일 백업: $dst → $backup"
        mv "$dst" "$backup"
    fi

    ln -sf "$src" "$dst"
    echo "  연결: $src → $dst"
}

echo "=== dotfiles 설치 ==="
echo ""

# --- tmux ---
echo "[tmux]"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# --- 새 dotfile 추가 시 여기에 ---
# echo "[bash]"
# link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
#
# echo "[vim]"
# link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

echo ""
echo "=== 완료! ==="
echo ""

# tmux가 실행 중이면 리로드
if command -v tmux &>/dev/null && [ -n "$TMUX" ]; then
    tmux source-file ~/.tmux.conf
    echo "tmux 설정 리로드됨"
elif command -v tmux &>/dev/null; then
    echo "tmux 설정 적용하려면: tmux source-file ~/.tmux.conf"
fi
