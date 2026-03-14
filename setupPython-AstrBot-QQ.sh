#!/bin/bash
set -euo pipefail

# ===================== 萌猫UI引擎 =====================
CAT_UI() {
    # 获取终端宽度
    TERM_WIDTH=$(tput cols)
    TERM_HEIGHT=$(tput lines)
    
    # 自适应边框宽度
    if [ $TERM_WIDTH -lt 60 ]; then
        BAR_WIDTH=$((TERM_WIDTH - 10))
    else
        BAR_WIDTH=50
    fi
    
    # 边框生成函数
    draw_top() {
        printf "╭%s╮\n" "$(printf '─%.0s' $(seq 1 $BAR_WIDTH))"
    }
    
    draw_mid() {
        printf "├%s┤\n" "$(printf '─%.0s' $(seq 1 $BAR_WIDTH))"
    }
    
    draw_bottom() {
        printf "╰%s╯\n" "$(printf '─%.0s' $(seq 1 $BAR_WIDTH))"
    }
    
    draw_line() {
        local content=$1
        local content_len=${#content}
        local padding=$(( (BAR_WIDTH - content_len) / 2 ))
        printf "│%*s%s%*s│\n" $padding "" "$content" $((BAR_WIDTH - content_len - padding)) ""
    }
    
    draw_left() {
        local content=$1
        printf "│ %s%*s│\n" "$content" $((BAR_WIDTH - ${#content} - 1)) ""
    }
    
    # 保存整个布局
    SAVE_LAYOUT() {
        LAYOUT_LINES=()
        
        # 头部
        LAYOUT_LINES+=("$(draw_top)")
        LAYOUT_LINES+=("$(draw_line " 🐱 猫猫量子编译引擎 🐱 ")")
        LAYOUT_LINES+=("$(draw_mid)")
        
        # 代码区
        LAYOUT_LINES+=("$(draw_left " 📦 编译代码:")")
        LAYOUT_LINES+=("$(draw_left "   CFLAGS=\"-O3 -march=native -pipe\"")")
        LAYOUT_LINES+=("$(draw_left "   ./configure --enable-optimizations")")
        LAYOUT_LINES+=("$(draw_left "   make -j\$(nproc)")")
        LAYOUT_LINES+=("$(draw_mid)")
        
        # 进度区
        LAYOUT_LINES+=("$(draw_left " 📊 编译进度:")")
        LAYOUT_LINES+=("$(draw_left "   [                    ] 0%")")
        LAYOUT_LINES+=("$(draw_mid)")
        
        # 猫猫状态区
        LAYOUT_LINES+=("$(draw_left " 😺 猫猫状态: 准备就绪")")
        LAYOUT_LINES+=("$(draw_bottom)")
        
        # 保存起始行
        UI_START_LINE=1
    }
    
    # 初始绘制
    SAVE_LAYOUT
    clear
    for line in "${LAYOUT_LINES[@]}"; do
        echo "$line"
    done
    UI_END_LINE=${#LAYOUT_LINES[@]}
    
    # 更新进度条 (不破坏布局)
    update_progress() {
        local percent=$1
        local bar_len=$((BAR_WIDTH - 10))
        local filled=$((percent * bar_len / 100))
        
        # 构建进度条
        local bar=""
        for ((i=0; i<filled; i++)); do bar="${bar}█"; done
        for ((i=filled; i<bar_len; i++)); do bar="${bar}░"; done
        
        # 定位到进度条行
        echo -ne "\033[$((UI_START_LINE + 8));1H\033[K"
        draw_left "   [$bar] $percent%"
    }
    
    # 更新猫猫状态
    update_cat() {
        local status=$1
        local cat_emoji=${2:-"😺"}
        
        echo -ne "\033[$((UI_START_LINE + 10));1H\033[K"
        draw_left " $cat_emoji 猫猫状态: $status"
    }
    
    # 在底部输出日志 (不影响UI)
    log_output() {
        local msg=$1
        echo -ne "\033[$((TERM_HEIGHT - 1));1H\033[K"
        echo -e " 📝 $msg"
        # 回到UI区域
        echo -ne "\033[$((UI_START_LINE + 11));1H"
    }
}

# ===================== 萌猫状态库 =====================
CAT_STATES=(
    "😺 猫猫在研究编译参数..."
    "😸 猫猫在敲键盘..."
    "😹 猫猫发现一个bug！... 啊 是灰尘"
    "😻 猫猫在优化代码..."
    "😼 猫猫在喝咖啡提神..."
    "😽 猫猫在摸鱼..."
    "🙀 猫猫被代码吓到..."
    "😿 编译好慢 猫猫困了..."
    "😾 猫猫想抓老鼠..."
    "🫨 猫猫在量子叠加..."
    "🫥 猫猫在平行宇宙..."
    "🫠 猫猫融化了..."
)

# ===================== 原编译代码 (完全不变) =====================
PYTHON_VERSION="3.12.12"
PYTHON_SRC_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"
PYTHON_DIR="$HOME/Python-${PYTHON_VERSION}"
INSTALL_PREFIX="/usr/local"

info() { echo -e "\033[32m[INFO] $*\033[0m"; }
error() { echo -e "\033[31m[ERROR] $*\033[0m"; exit 1; }

# ===================== 启动UI =====================
CAT_UI
update_cat "启动引擎..." "🚀"
sleep 1

# ===================== 1. 安装系统依赖 =====================
update_cat "安装依赖中..." "📦"
log_output "[INFO] 更新系统并安装编译依赖..."

# 你的原代码完全不变
apt install -y \
  build-essential wget curl git libssl-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libffi-dev zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev lzma liblzma-dev ca-certificates > /dev/null 2>&1 &

# 后台运行时的萌猫动画
PID=$!
while kill -0 $PID 2>/dev/null; do
    for state in "${CAT_STATES[@]}"; do
        update_cat "$state"
        sleep 0.3
    done
done

# ===================== 2. 下载Python源码 =====================
update_cat "下载Python中..." "📥"
log_output "[INFO] 下载 Python ${PYTHON_VERSION} 源码..."

if [ ! -d "${PYTHON_DIR}" ]; then
    wget -q "${PYTHON_SRC_URL}" -P "$HOME"
    update_progress 10
    update_cat "下载完成！解压中..." "📂"
    tar -xf "$HOME/Python-${PYTHON_VERSION}.tar.xz" -C "$HOME"
fi

# ===================== 3. 编译安装Python =====================
update_cat "开始编译Python..." "⚙️"
log_output "[INFO] 开始编译安装 Python ${PYTHON_VERSION}（高优化版）"

cd "${PYTHON_DIR}"
make clean >/dev/null 2>&1 || true
update_progress 20

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

update_progress 30
update_cat "编译中 (30%)..." "⚡"

# 编译时动态更新
make -j$(nproc) PROFILE_TASK="-m test.regrtest --pgo -j$(nproc)" > /dev/null 2>&1 &
MAKE_PID=$!

progress=30
while kill -0 $MAKE_PID 2>/dev/null; do
    progress=$((progress + 1))
    if [ $progress -gt 95 ]; then
        progress=95
    fi
    update_progress $progress
    update_cat "${CAT_STATES[$((RANDOM % ${#CAT_STATES[@]}))]}"
    sleep 0.5
done

update_progress 100
update_cat "编译完成！安装中..." "📦"
make install > /dev/null 2>&1
ldconfig "${INSTALL_PREFIX}/lib"

# ===================== 4. 配置环境变量 =====================
update_cat "配置环境中..." "🔧"
PATH_CONFIG='export PATH="/usr/local/bin:$PATH"'
ALIAS_PY='alias python="python3.12"'
ALIAS_PIP='alias pip="pip3.12"'

for f in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -qxF "${PATH_CONFIG}" "$f" || echo "${PATH_CONFIG}" >> "$f"
  grep -qxF "${ALIAS_PY}" "$f" || echo "${ALIAS_PY}" >> "$f"
  grep -qxF "${ALIAS_PIP}" "$f" || echo "${ALIAS_PIP}" >> "$f"
done

export PATH="/usr/local/bin:$PATH"

# ===================== 5. 安装 uv =====================
update_cat "安装uv包管理器..." "📦"
pip install uv > /dev/null 2>&1

# ===================== 6. 安装 AstrBot =====================
update_cat "克隆AstrBot仓库..." "🐍"
cd "$HOME"
git clone https://github.com/Soulter/AstrBot.git > /dev/null 2>&1 || true
cd AstrBot
update_cat "启动AstrBot..." "🤖"
uv run main.py > /dev/null 2>&1 &

# ===================== 7. 安装 NapCat =====================
update_cat "安装猫猫框架..." "😺"
cd "$HOME"
curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh > /dev/null 2>&1
bash napcat.sh --tui > /dev/null 2>&1 &

# =================== 额外变量 ===================
echo "export TZ='Asia/Shanghai'
export UV_LINK_MODE=copy
cd AstrBot && uv run main.py &" >> ~/.bashrc

# ===================== 完成 =====================
update_cat "安装完成！" "🎉"
update_progress 100

# 最终庆祝动画
for i in {1..5}; do
    update_cat "🎊 安装成功啦！ 🎊" "🎉"
    sleep 0.3
    update_cat "✨ 感谢使用猫猫引擎 ✨" "🌟"
    sleep 0.3
done

log_output "===================================================="
log_output "✅ 全自动安装完成！"
log_output "Python 3.12.12 + uv + AstrBot + NapCat 已全部部署"
log_output "请执行：source ~/.bashrc  使环境完全生效"
log_output "===================================================="

# 保持UI到最后
echo -ne "\033[$((TERM_HEIGHT));1H"
