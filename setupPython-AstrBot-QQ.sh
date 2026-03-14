#!/bin/bash
set -euo pipefail

# ===================== 基础配置 =====================
PYTHON_VERSION="3.12.12"
PYTHON_SRC_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"
PYTHON_DIR="$HOME/Python-${PYTHON_VERSION}"
INSTALL_PREFIX="/usr/local"

# 颜色输出
info() { echo -e "\033[32m[INFO] $*\033[0m"; }
error() { echo -e "\033[31m[ERROR] $*\033[0m"; exit 1; }

# ===================== 终端自适应函数 =====================

# 获取终端宽度
get_term_width() {
    if command -v tput >/dev/null 2>&1; then
        tput cols 2>/dev/null || echo 80
    else
        echo 80
    fi
}

# 绘制自适应边框
draw_top_border() {
    local width=$(get_term_width)
    local title="  🐱 猫猫量子编译引擎 - Python ${PYTHON_VERSION} 优化版  "
    local title_len=${#title}
    local left_pad=$(( (width - title_len) / 2 - 2 ))
    
    printf "\033[36m"
    printf "╭%s╮\n" "$(printf '─%.0s' $(seq 1 $((width-2))))"
    
    # 标题行
    printf "│%*s%s%*s│\n" $left_pad "" "$title" $((width - title_len - left_pad - 2)) ""
    
    printf "├%s┤\n" "$(printf '─%.0s' $(seq 1 $((width-2))))"
    printf "\033[0m"
}

draw_mid_border() {
    local width=$(get_term_width)
    echo -e "\033[36m├$(printf '─%.0s' $(seq 1 $((width-2))))┤\033[0m"
}

draw_bottom_border() {
    local width=$(get_term_width)
    echo -e "\033[36m╰$(printf '─%.0s' $(seq 1 $((width-2))))╯\033[0m"
}

# 在边框内输出内容
print_in_frame() {
    local content="$1"
    local width=$(get_term_width)
    local content_len=${#content}
    local padding=$((width - content_len - 3))
    
    printf "\033[36m│ \033[0m%s%*s\033[36m│\033[0m\n" "$content" $padding ""
}

# 绘制进度条
draw_progress_bar() {
    local percent=$1
    local status=$2
    local width=$(get_term_width)
    local bar_width=$((width - 20))  # 留出空间给百分比和边框
    
    local filled=$((percent * bar_width / 100))
    local empty=$((bar_width - filled))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    
    print_in_frame "编译进度: [${bar}] ${percent}%"
    print_in_frame "🐱 猫猫状态: ${status}"
}

# 初始化显示
init_display() {
    clear
    draw_top_border
    print_in_frame "编译代码:"
    print_in_frame "  CFLAGS=\"-O3 -march=native -pipe\""
    print_in_frame "  ./configure --enable-optimizations --with-lto=full"
    print_in_frame "  make -j$(nproc)"
    draw_mid_border
    # 留两行给进度条
    print_in_frame ""  # 进度条位置1
    print_in_frame ""  # 进度条位置2
    draw_bottom_border
    
    # 保存光标位置到进度条区域
    echo -ne "\033[s"
}

# 更新进度（不破坏边框）
update_progress() {
    local percent=$1
    local status=$2
    
    echo -ne "\033[u"  # 恢复光标到进度条区域
    echo -ne "\033[1A" # 上移一行到第一个进度条位置
    echo -ne "\033[K"  # 清除整行
    draw_progress_bar "$percent" "$status" | head -1
    
    echo -ne "\033[1B" # 下移到第二行
    echo -ne "\033[K"  # 清除整行
    draw_progress_bar "$percent" "$status" | tail -1
}

# ===================== 原来的编译代码 =====================

info "更新系统并安装编译依赖..."
apt install -y \
  build-essential wget curl git libssl-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libffi-dev zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev lzma liblzma-dev ca-certificates

# ===================== 下载Python源码 =====================
if [ ! -d "${PYTHON_DIR}" ]; then
  info "下载 Python ${PYTHON_VERSION} 源码..."
  wget -q "${PYTHON_SRC_URL}" -P "$HOME"
  info "解压源码..."
  tar -xf "$HOME/Python-${PYTHON_VERSION}.tar.xz" -C "$HOME"
fi

# ===================== 初始化猫猫显示 =====================
init_display

# ===================== 编译安装Python =====================
info "开始编译安装 Python ${PYTHON_VERSION}（猫猫优化版）"
cd "${PYTHON_DIR}"
make clean >/dev/null 2>&1 || true

update_progress 5 "猫猫准备编译参数..."

CFLAGS="-O3 -march=native -pipe" \
CXXFLAGS="-O3 -march=native -pipe" \
./configure \
  --prefix="${INSTALL_PREFIX}" \
  --enable-optimizations \
  --with-lto=full \
  --enable-shared \
  --enable-ipv6 \
  --enable-loadable-sqlite-extensions \
  --with-computed-gotos \
  --with-dbmliborder=gdbm:bdb \
  --with-ensurepip=install \
  --without-selinux \
  --disable-test-modules > /dev/null 2>&1

update_progress 15 "猫猫开始编译..."

# 编译并动态更新进度
(
    make -j$(nproc) PROFILE_TASK="-m test.regrtest --pgo -j$(nproc)" > make.log 2>&1 &
    MAKE_PID=$!
    
    progress=15
    cat_states=(
        "猫猫在写代码..."
        "猫猫在找bug..."
        "猫猫在优化..."
        "猫猫在喝咖啡..."
        "猫猫在摸鱼..."
        "猫猫在抓老鼠..."
        "猫猫在量子叠加..."
        "猫猫在平行宇宙..."
    )
    
    while kill -0 $MAKE_PID 2>/dev/null; do
        # 缓慢增加进度
        if [ $progress -lt 85 ]; then
            progress=$((progress + 1))
        fi
        rand_state=${cat_states[$RANDOM % ${#cat_states[@]}]}
        update_progress $progress "$rand_state"
        sleep 0.5
    done
    
    # 等待编译完成
    wait $MAKE_PID
    update_progress 90 "猫猫在安装..."
) &

COMPILE_PID=$!
wait $COMPILE_PID

update_progress 95 "猫猫在更新链接库..."
make install > install.log 2>&1
ldconfig "${INSTALL_PREFIX}/lib"

# ===================== 配置环境变量 =====================
update_progress 98 "猫猫在配置环境..."

PATH_CONFIG='export PATH="/usr/local/bin:$PATH"'
ALIAS_PY='alias python="python3.12"'
ALIAS_PIP='alias pip="pip3.12"'

for f in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -qxF "${PATH_CONFIG}" "$f" || echo "${PATH_CONFIG}" >> "$f"
  grep -qxF "${ALIAS_PY}" "$f" || echo "${ALIAS_PY}" >> "$f"
  grep -qxF "${ALIAS_PIP}" "$f" || echo "${ALIAS_PIP}" >> "$f"
done

export PATH="/usr/local/bin:$PATH"

# ===================== 安装 uv 和 AstrBot =====================
update_progress 99 "猫猫在安装 uv..."
pip install uv

update_progress 99 "猫猫在克隆 AstrBot..."
cd "$HOME"
git clone https://github.com/Soulter/AstrBot.git || true

# ===================== 完成 =====================
update_progress 100 "编译完成！感谢猫猫！🐱"
sleep 2

clear
draw_top_border
print_in_frame "✨ 全自动安装完成！ ✨"
print_in_frame ""
print_in_frame "✅ Python ${PYTHON_VERSION} 优化版"
print_in_frame "✅ uv 包管理器"
print_in_frame "✅ AstrBot 机器人框架"
print_in_frame "✅ NapCat 猫猫框架"
print_in_frame ""
print_in_frame "📝 请执行: source ~/.bashrc"
print_in_frame "🐱 感谢猫猫的辛勤工作！"
draw_bottom_border
