#!/bin/bash
# =============================================================================
# dotfiles install script
# 사용법: git clone https://github.com/jinwhong/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_VERSION="3.5a"

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

# --- tmux.conf 심볼릭 링크 ---
echo "[tmux] 설정 파일"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# --- tmux 버전 확인 및 설치 ---
echo ""
echo "[tmux] 버전 확인"
CURRENT_TMUX=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+[a-z]?' || echo "없음")
echo "  현재: $CURRENT_TMUX / 필요: $TMUX_VERSION+"

if [ "$CURRENT_TMUX" != "$TMUX_VERSION" ]; then
    read -p "  tmux $TMUX_VERSION 설치? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            echo "  macOS: brew install tmux..."
            brew install tmux
        else
            echo "  Linux: 소스 빌드..."
            sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config
            cd /tmp
            rm -rf "tmux-${TMUX_VERSION}"*
            curl -sLO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
            tar xzf "tmux-${TMUX_VERSION}.tar.gz"
            cd "tmux-${TMUX_VERSION}"
            ./configure --prefix=/usr/local
            make -j"$(nproc)"
            sudo make install
            cd "$DOTFILES_DIR"
        fi
        echo "  tmux 설치 완료: $(tmux -V)"
    else
        echo "  건너뜀 (일부 기능이 동작하지 않을 수 있음)"
    fi
else
    echo "  OK"
fi

# --- TPM (Tmux Plugin Manager) ---
echo ""
echo "[tmux] 플러그인 매니저"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  TPM 설치 중..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo "  TPM 이미 설치됨"
fi

# --- Dracula 테마 (TPM 경로 충돌 방지를 위해 직접 설치) ---
echo ""
echo "[tmux] Dracula 테마"
if [ ! -d "$HOME/.tmux/plugins/tmux-dracula" ]; then
    echo "  Dracula 설치 중..."
    git clone https://github.com/dracula/tmux.git "$HOME/.tmux/plugins/tmux-dracula"
else
    echo "  Dracula 이미 설치됨"
fi

# --- TPM 플러그인 설치 (resurrect, continuum) ---
echo ""
echo "[tmux] TPM 플러그인"
"$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true

# --- 새 dotfile 추가 시 여기에 ---
# echo "[bash]"
# link_file "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"

echo ""
echo "=== 완료! ==="
echo ""
echo "참고:"
echo "  - tmux 서버 재시작 필요: tmux kill-server && tmux new -s main"
echo "  - 세션 저장: prefix + Ctrl-s"
echo "  - 세션 복원: prefix + Ctrl-r"
echo "  - 윈도우 전환: Ctrl+Shift+←/→"
