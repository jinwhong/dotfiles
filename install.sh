#!/bin/bash
# =============================================================================
# dotfiles install script
# 사용법: git clone <repo> ~/dotfiles && cd ~/dotfiles && ./install.sh
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

# --- tmux 버전 확인 및 빌드 ---
echo ""
echo "[tmux] 버전 확인"
CURRENT_TMUX=$(tmux -V 2>/dev/null | grep -oP '[\d.]+[a-z]?' || echo "없음")
echo "  현재: $CURRENT_TMUX / 필요: $TMUX_VERSION+"

if [ "$CURRENT_TMUX" != "$TMUX_VERSION" ]; then
    read -p "  tmux $TMUX_VERSION 소스 빌드 설치? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  빌드 의존성 설치..."
        sudo apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config

        echo "  tmux $TMUX_VERSION 다운로드 및 빌드..."
        cd /tmp
        rm -rf "tmux-${TMUX_VERSION}"*
        curl -sLO "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
        tar xzf "tmux-${TMUX_VERSION}.tar.gz"
        cd "tmux-${TMUX_VERSION}"
        ./configure --prefix=/usr/local
        make -j"$(nproc)"
        sudo make install

        echo "  tmux $TMUX_VERSION 설치 완료: $(tmux -V)"
        cd "$DOTFILES_DIR"
    else
        echo "  건너뜀 (일부 기능이 동작하지 않을 수 있음)"
    fi
else
    echo "  OK"
fi

# --- TPM (Tmux Plugin Manager) ---
echo ""
echo "[tmux] 플러그인"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  TPM 설치 중..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo "  TPM 이미 설치됨"
fi

# 플러그인 설치 (tmux 세션 밖에서도 동작)
echo "  플러그인 설치 중 (resurrect, continuum)..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

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
