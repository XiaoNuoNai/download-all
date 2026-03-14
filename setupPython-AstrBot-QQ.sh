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

# ===================== 猫猫编译框 =====================
# 保存布局到变量
CAT_FRAME=$(cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║     🐱 猫猫量子编译引擎 - Python 3.12.12 优化版         ║
╠══════════════════════════════════════════════════════════╣
║  [编译代码]                                               ║
║  CFLAGS="-O3 -march=native -pipe"                        ║
║  ./configure --enable-optimizations --with-lto=full      ║
║  make -j$(nproc)                                          ║
╠══════════════════════════════════════════════════════════╣
║  [编译进度]                                               ║
║  [                    ] 0%                                ║
║  🐱 猫猫状态: 准备就绪                                     ║
╚══════════════════════════════════════════════════════════╝
EOF
)

# 显示猫猫框
show_cat_frame() {
    clear
    echo "$CAT_FRAME"
    # 记录行数，后面要用
    FRAME_LINES=$(echo "$CAT_FRAME" | wc -l)
}

# 更新进度条 (第11行是进度条，第12行是猫猫状态)
update_progress() {
    local percent=$1
    local status=$2
    local bar_len=20
    local filled=$((percent * bar_len / 100))
    
    # 构建进度条
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=filled; i<bar_len; i++)); do bar="${bar} "; done
    
    # 更新进度条行 (第11行)
    echo -ne "\033[11;1H\033[K"
    echo -n "║  [$bar] $percent%                                ║"
    
    # 更新猫猫状态行 (第12行)
    echo -ne "\033[12;1H\033[K"
    printf "║  🐱 猫猫状态: %-30s ║" "$status"
}

# 在框内输出编译信息（第5-8行之间）
output_compile_info() {
    local line=$1
    local text=$2
    echo -ne "\033[$((4+line));1H\033[K"
    echo -n "║  $text"
    # 补齐边框
    local current_col=$(echo -n "$text" | wc -m)
    local padding=$((45 - current_col))
    printf "%${padding}s ║" ""
}

# ===================== 1. 安装系统依赖 =====================
show_cat_frame
output_compile_info 1 "📦 步骤1/6: 安装系统依赖..."
update_progress 5 "下载依赖包中..."

info "更新系统并安装编译依赖..."
apt install -y \
  build-essential wget curl git libssl-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libffi-dev zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev lzma liblzma-dev ca-certificates > /dev/null 2>&1

# ===================== 2. 下载Python源码 =====================
output_compile_info 2 "📦 步骤2/6: 下载Python源码..."
update_progress 15 "猫猫在下载Python..."

if [ ! -d "${PYTHON_DIR}" ]; then
  output_compile_info 3 "  正在下载 Python ${PYTHON_VERSION}..."
  wget -q "${PYTHON_SRC_URL}" -P "$HOME"
  output_compile_info 3 "  解压源码中..."
  tar -xf "$HOME/Python-${PYTHON_VERSION}.tar.xz" -C "$HOME"
  output_compile_info 3 "  ✅ 下载完成"
fi

# ===================== 3. 编译安装Python =====================
output_compile_info 1 "📦 步骤3/6: 编译Python (最耗时)..."
update_progress 25 "猫猫开始编译..."

cd "${PYTHON_DIR}"
make clean >/dev/null 2>&1 || true

output_compile_info 2 "  配置编译参数..."
update_progress 30 "配置中..."

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
  --disable-test-modules > compile.log 2>&1

output_compile_info 3 "  多线程编译中..."
update_progress 40 "猫猫在写代码..."

# 编译过程中动态更新进度
(
  make -j$(nproc) PROFILE_TASK="-m test.regrtest --pgo -j$(nproc)" > compile.log 2>&1 &
  MAKE_PID=$!
  
  # 伪进度更新 (40% -> 80%)
  progress=40
  cat_states=(
    "猫猫在写代码..."
    "猫猫在找bug..."
    "猫猫在优化..."
    "猫猫在喝咖啡..."
    "猫猫在摸鱼..."
    "猫猫在量子叠加..."
  )
  
  while kill -0 $MAKE_PID 2>/dev/null; do
    progress=$((progress + 1))
    if [ $progress -gt 80 ]; then
      progress=80
    fi
    
    rand_state=${cat_states[$RANDOM % ${#cat_states[@]}]}
    update_progress $progress "$rand_state"
    sleep 2
  done
)

update_progress 85 "猫猫编译完成，准备安装..."
output_compile_info 4 "  ✅ 编译完成，开始安装..."

make install > install.log 2>&1
ldconfig "${INSTALL_PREFIX}/lib"

# ===================== 4. 配置环境变量 =====================
output_compile_info 1 "📦 步骤4/6: 配置环境变量..."
update_progress 90 "猫猫在设置环境..."

PATH_CONFIG='export PATH="/usr/local/bin:$PATH"'
ALIAS_PY='alias python="python3.12"'
ALIAS_PIP='alias pip="pip3.12"'

for f in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -qxF "${PATH_CONFIG}" "$f" || echo "${PATH_CONFIG}" >> "$f"
  grep -qxF "${ALIAS_PY}" "$f" || echo "${ALIAS_PY}" >> "$f"
  grep -qxF "${ALIAS_PIP}" "$f" || echo "${ALIAS_PIP}" >> "$f" 2>/dev/null
done

export PATH="/usr/local/bin:$PATH"

# ===================== 5. 安装 uv =====================
output_compile_info 1 "📦 步骤5/6: 安装 uv..."
update_progress 93 "猫猫安装uv中..."

pip install uv > /dev/null 2>&1

# ===================== 6. 安装 AstrBot =====================
output_compile_info 1 "📦 步骤6/6: 安装 AstrBot..."
update_progress 95 "猫猫克隆代码..."

cd "$HOME"
git clone https://github.com/Soulter/AstrBot.git > /dev/null 2>&1 || true
cd AstrBot

update_progress 98 "猫猫启动服务..."
uv run main.py &

# ===================== 7. 安装 NapCat =====================
output_compile_info 1 "📦 额外: 安装 NapCat..."
update_progress 99 "猫猫安装猫猫框架..."

cd "$HOME"
curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh \
  && bash napcat.sh --tui > /dev/null 2>&1 &

# =================== 额外变量 ===================
echo "export TZ='Asia/Shanghai'
export UV_LINK_MODE=copy
cd AstrBot && uv run main.py &" >> ~/.bashrc

# ===================== 完成 =====================
# 清除猫猫框，显示完成信息
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║     ✨ 恭喜！猫猫量子编译引擎 完成任务！ ✨            ║
╠══════════════════════════════════════════════════════════╣
║  ✅ Python 3.12.12 优化版编译完成                        ║
║  ✅ uv 安装完成                                           ║
║  ✅ AstrBot 部署完成                                      ║
║  ✅ NapCat 猫猫框架安装中                                 ║
╠══════════════════════════════════════════════════════════╣
║  📱 下次打开 Termux 自动进入机器人环境                   ║
║  🐱 猫猫感谢你的耐心等待！                                ║
║  ✨ 执行: source ~/.bashrc 使配置生效                     ║
╚══════════════════════════════════════════════════════════╝
EOF

info "===================================================="
info "✅ 全自动安装完成！"
info "Python 3.12.12 + uv + AstrBot + NapCat 已全部部署"
info "请执行：source ~/.bashrc  使环境完全生效"
info "===================================================="
