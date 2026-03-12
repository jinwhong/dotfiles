#!/bin/bash
# =============================================================================
# dotfiles install script
# 사용법: git clone https://github.com/jinwhong/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_VERSION="3.5a"
OS="$(uname)"
IS_WSL=false
if [ "$OS" = "Linux" ] && grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

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

# --- Ghostty 설정 ---
echo ""
echo "[ghostty] 설정 파일"
mkdir -p "$HOME/.config/ghostty"
link_file "$DOTFILES_DIR/.config/ghostty/config" "$HOME/.config/ghostty/config"

# --- Claude Code 전체 설정 ---
echo ""
echo "[claude] 설정 파일"
mkdir -p "$HOME/.claude"

# settings.json은 머신별 상태가 추가되므로 심볼릭 링크가 아닌 복사
if [ ! -f "$HOME/.claude/settings.json" ]; then
    cp "$DOTFILES_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
    echo "  복사: settings.json (최초 설치)"
else
    echo "  settings.json 이미 존재 — 건너뜀 (수동 병합 필요 시: diff $DOTFILES_DIR/.claude/settings.json $HOME/.claude/settings.json)"
fi

echo ""
echo "[claude] 키바인딩"
link_file "$DOTFILES_DIR/.claude/keybindings.json" "$HOME/.claude/keybindings.json"

echo ""
echo "[claude] CLAUDE.md (글로벌 지침)"
link_file "$DOTFILES_DIR/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo ""
echo "[claude] Hooks (자동화 스크립트)"
mkdir -p "$HOME/.claude/hooks"
for hook_script in "$DOTFILES_DIR/.claude/hooks/"*.sh; do
    if [ -f "$hook_script" ]; then
        link_file "$hook_script" "$HOME/.claude/hooks/$(basename "$hook_script")"
        chmod +x "$HOME/.claude/hooks/$(basename "$hook_script")"
    fi
done

echo ""
echo "[claude] 스킬"
link_file "$DOTFILES_DIR/.claude/skills" "$HOME/.claude/skills"

# --- Claude Code Memory (프로젝트별) ---
echo ""
echo "[claude] Memory 템플릿"
if [ -d "$DOTFILES_DIR/.claude/memory" ]; then
    echo "  memory 템플릿이 dotfiles에 있습니다."
    echo "  프로젝트별 memory를 설정하려면:"
    echo "    1. Claude Code에서 프로젝트를 열면 자동으로 memory 경로가 생성됩니다"
    echo "    2. 템플릿 복사: cp $DOTFILES_DIR/.claude/memory/*.md ~/.claude/projects/<project-path>/memory/"
    echo "    3. 또는 Claude Code에서 '내 memory 복원해줘'라고 요청하세요"
fi

# --- Nerd Font 설치 ---
echo ""
echo "[font] JetBrainsMono Nerd Font"
FONT_NAME="JetBrainsMono"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    echo "  이미 설치됨"
else
    read -p "  JetBrainsMono Nerd Font 설치? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$OS" == "Darwin" ]]; then
            echo "  macOS: brew install..."
            brew install --cask font-jetbrains-mono-nerd-font
        else
            echo "  Linux: 직접 다운로드..."
            FONT_DIR="$HOME/.local/share/fonts"
            mkdir -p "$FONT_DIR"
            FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.tar.xz"
            curl -sL "$FONT_URL" | tar xJ -C "$FONT_DIR"
            fc-cache -f "$FONT_DIR"
        fi
        echo "  설치 완료"
    else
        echo "  건너뜀 (Ghostty에서 폰트가 표시되지 않을 수 있음)"
    fi
fi

# --- 클립보드 도구 확인 (Linux) ---
if [[ "$OS" == "Linux" ]] && [ "$IS_WSL" = false ]; then
    echo ""
    echo "[clipboard] xclip 확인"
    if command -v xclip &>/dev/null; then
        echo "  xclip OK"
    else
        echo "  ⚠ xclip 미설치 — tmux 복사가 시스템 클립보드에 연결되지 않음"
        echo "  설치: sudo apt install xclip"
    fi
fi

echo ""
echo "=== 완료! ==="
echo ""
echo "참고:"
echo "  - tmux 서버 재시작 필요: tmux kill-server && tmux new -s main"
echo "  - 세션 저장: prefix + Ctrl-s"
echo "  - 세션 복원: prefix + Ctrl-r"
echo "  - 윈도우 전환: Ctrl+Shift+←/→"
echo ""
echo "Claude Code:"
echo "  - 설정 완료: settings, keybindings, CLAUDE.md, hooks, skills"
echo "  - Memory 복원: Claude Code에서 '내 memory 복원해줘'라고 요청"
echo "  - 단축키: Ctrl+M(모델 전환), Ctrl+S(프롬프트 저장), Ctrl+B(백그라운드)"
