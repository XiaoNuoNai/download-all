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

# ===================== 1. 安装系统依赖 =====================
info "更新系统并安装编译依赖..."
apt install -y \
  build-essential wget curl git libssl-dev libbz2-dev libreadline-dev \
  libsqlite3-dev libffi-dev zlib1g-dev libncurses5-dev libgdbm-dev \
  libnss3-dev lzma liblzma-dev ca-certificates

# ===================== 2. 下载并解压Python源码 =====================
if [ ! -d "${PYTHON_DIR}" ]; then
  info "下载 Python ${PYTHON_VERSION} 源码..."
  wget -q "${PYTHON_SRC_URL}" -P "$HOME"
  info "解压源码..."
  tar -xf "$HOME/Python-${PYTHON_VERSION}.tar.xz" -C "$HOME"
else
  info "检测到 Python 源码目录已存在: ${PYTHON_DIR}"
fi

# ===================== 3. 编译安装Python（重复编译检测） =====================
# 检查Python是否已安装
if command -v python3.12 >/dev/null 2>&1; then
    INSTALLED_VERSION=$(python3.12 --version 2>&1 | awk '{print $2}')
    if [ "$INSTALLED_VERSION" = "$PYTHON_VERSION" ]; then
        info "✅ 检测到 Python ${PYTHON_VERSION} 已安装，跳过编译安装"
        info "Python 路径: $(which python3.12)"
        NEED_COMPILE=false
    else
        info "检测到不同版本的 Python (${INSTALLED_VERSION})，继续安装 ${PYTHON_VERSION}"
        NEED_COMPILE=true
    fi
else
    info "未检测到 Python 3.12，开始编译安装"
    NEED_COMPILE=true
fi

# 如果需要编译，则执行编译安装
if [ "${NEED_COMPILE:-false}" = true ]; then
    info "开始编译安装 Python ${PYTHON_VERSION}（高优化版）"
    cd "${PYTHON_DIR}"
    make clean >/dev/null 2>&1 || true

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
      --disable-test-modules

    info "多线程编译..."
    make -j$(nproc) PROFILE_TASK="-m test.regrtest --pgo -j$(nproc)"

    info "安装 Python..."
    make install

    info "更新动态链接库..."
    ldconfig "${INSTALL_PREFIX}/lib"
else
    info "✅ 跳过 Python 编译安装"
fi

# 删除源码
rm -rf /root/Python-3.12.12

# ==================== 4. 配置环境变量 =====================
info "配置 python/pip 默认 3.12"

PATH_CONFIG='export PATH="/usr/local/bin:$PATH"'
ALIAS_PY='alias python="python3.12"'
ALIAS_PIP='alias pip="pip3.12"'
LOCAL_BIN='export PATH="$HOME/.local/bin:$PATH"'

for f in "$HOME/.bashrc" "$HOME/.profile"; do
    [ -f "$f" ] || continue
    grep -qxF "${PATH_CONFIG}" "$f" || echo "${PATH_CONFIG}" >> "$f"
    grep -qxF "${ALIAS_PY}" "$f" || echo "${ALIAS_PY}" >> "$f"
    grep -qxF "${ALIAS_PIP}" "$f" || echo "${ALIAS_PIP}" >> "$f"
    grep -qxF "${LOCAL_BIN}" "$f" || echo "${LOCAL_BIN}" >> "$f"
done

# 立即生效
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
alias python="python3.12" 2>/dev/null || true
alias pip="pip3.12" 2>/dev/null || true

# ===================== 5. 安装 uv =====================
info "检查 uv 安装状态..."
if command -v uv >/dev/null 2>&1; then
    UV_VERSION=$(uv --version 2>&1 | head -n1)
    info "✅ 检测到 uv 已安装: $UV_VERSION"
    info "uv 路径: $(which uv)"
else
    info "未检测到 uv，开始安装..."
    pip3.12 install uv
    if command -v uv >/dev/null 2>&1; then
        info "✅ uv 安装成功"
    else
        error "uv 安装失败"
    fi
fi

export UV_LINK_MODE=copy

# ===================== 6. 安装 AstrBot =====================

info "检查 AstrBot 安装状态..."
ASTRBOT_DIR="$HOME/AstrBot"
ASTRBOT_INSTALLED_FLAG="$ASTRBOT_DIR/.installation_complete"

if [ -f "$ASTRBOT_INSTALLED_FLAG" ]; then
    info "✅ 检测到 AstrBot 已完成安装"
else
    if [ -d "$ASTRBOT_DIR" ]; then
        info "检测到不完整的安装（目录存在但未完成），重新安装..."
        rm -rf "$ASTRBOT_DIR"
    else
        info "未检测到 AstrBot，开始安装..."
    fi
    
    # 创建目录并安装
    cd "$HOME"
    mkdir -p AstrBot
    cd AstrBot
    
    # 执行安装
    if uv tool install astrbot && echo -e "y\ny\n" | astrbot init; then
        # 创建安装完成标记文件
        touch "$ASTRBOT_INSTALLED_FLAG"
        info "✅ AstrBot 安装成功"
    else
        error "AstrBot 安装失败"
    fi
fi

# ===================== 7. 安装 NapCat =====================

info "检查 NapCat 安装状态..."
NAPCAT_DIR="/root/Napcat"
NAPCAT_SCRIPT="napcat.sh"
NAPCAT_INSTALLED_FLAG="$NAPCAT_DIR/.installation_complete"

if [ -f "$NAPCAT_INSTALLED_FLAG" ]; then
    info "✅ 检测到 NapCat 已完成安装"
else
    if [ -d "$NAPCAT_DIR" ]; then
        info "检测到不完整的安装（目录存在但未完成），重新安装..."
        rm -rf "$NAPCAT_DIR"
    else
        info "未检测到 NapCat，开始安装..."
    fi
    
    # 安装sudo（如果未安装）
    apt-get install -y sudo
    cd "$HOME"
    
    # 下载并执行安装脚本
    if curl -o "$NAPCAT_SCRIPT" "https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh" && bash "$NAPCAT_SCRIPT" --cli n; then
        # 创建安装完成标记文件
        mkdir -p "$NAPCAT_DIR"
        touch "$NAPCAT_INSTALLED_FLAG"
        info "✅ 猫猫框架安装成功"
    else
        error "NapCat 安装失败"
    fi
fi
  # 启动应用
    xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox &
    alias astrbot="cd $HOME/AstrBot && astrbot run &"
    astrbot run > /dev/null &
    info "瞌睡猫正在赶来喵~"
    sleep 1
    info "AstrBot-core正在启动..."
    sleep 4

  # =================== 额外变量 ===================
# 定义要添加的内容
TIMEZONE_CONFIG='export TZ="Asia/Shanghai"'
UV_LINK_CONFIG='export UV_LINK_MODE=copy'
ASTRBOT_STARTLINK='alias astrbot="cd $HOME/AstrBot && astrbot run &"'
ASTRBOT_AUTOSTART='astrbot'
NAPCAT_AUTOSTART='alias napcat="xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox &"'
# 检查并添加配置（避免重复）
for config in "$TIMEZONE_CONFIG" "$UV_LINK_CONFIG" "$ASTRBOT_STARTLINK" "$NAPCAT_AUTOSTART" "$ASTRBOT_AUTOSTART"; do
    if ! grep -qF "$config" ~/.bashrc; then
        echo "$config" >> ~/.bashrc
        info "已添加: $config"
    else
        info "已存在，跳过: $config"
      fi
  done
# ===================== 用户交互：打开链接 =====================
export PATH="$PATH:/data/data/com.termux/files/usr/bin/"

# 构建完整URL
NAPCAT_TOKEN="$(sed -n 's/.*"token": *"\([^"]*\)".*/\1/p' /root/Napcat/opt/QQ/resources/app/app_launcher/napcat/config/webui.json)"
NAPCAT_URL="http://127.0.0.1:6099/webui?token=${NAPCAT_TOKEN}"
ASTRBOT_URL="http://127.0.0.1:6185"

# 询问是否打开NapCat面板
echo ""
read -p "要去看看猫猫面板吗？输入(y/n): " open_napcat
if [[ $open_napcat == "y" || $open_napcat == "Y" ]]; 键，然后
    info "好喵..."
    if command -v termux-open >/dev/null 2>&1; then
        termux-open "$NAPCAT_URL"
        info "✅ NapCat面板已打开"
    else
        info "termux-open命令不可用，请手动打开链接："
        echo "$NAPCAT_URL"
    fi
else
    info "跳过打开NapCat面板"
fi

# 询问是否打开AstrBot面板
echo ""
read -p "要看看Bot面板吗？输入(y/n): " open_astrbot
if [[ $open_astrbot == "y" || $open_astrbot == "Y" ]]; 键，然后
    info "正在打开Bot管理面板..."
    if command -v termux-open >/dev/null 2>&1; then
        termux-open "$ASTRBOT_URL"
        info "✅ Bot打开啦˙"
    else
        info "termux-open命令不可用，请手动打开链接："
        echo "$ASTRBOT_URL"
    fi
else
    info "跳过打开AstrBot面板"
fi

# ===================== 最终提示 =====================
echo ""
info "=================================================="
info "🎉 安装流程全部完成！"
info "以后要重新打开面板 地址是这两个："
info "猫猫面板: $NAPCAT_URL"
  echo "猫猫令牌:$NAPCAT_TOKEN"
info "AstrBot: $ASTRBOT_URL"
info "=================================================="
