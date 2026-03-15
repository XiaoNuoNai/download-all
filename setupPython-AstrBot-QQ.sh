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
        info "检测到 Python ${PYTHON_VERSION} 已安装，跳过编译安装"
        info "Python 路径: $(which python3.12)"
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

# ===================== 4. 配置环境变量 =====================
info "配置 python/pip 默认 3.12"
PATH_CONFIG='export PATH="/usr/local/bin:$PATH"'
ALIAS_PY='alias python="python3.12"'
ALIAS_PIP='alias pip="pip3.12"'

for f in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -qxF "${PATH_CONFIG}" "$f" || echo "${PATH_CONFIG}" >> "$f"
  grep -qxF "${ALIAS_PY}" "$f" || echo "${ALIAS_PY}" >> "$f"
  grep -qxF "${ALIAS_PIP}" "$f" || echo "${ALIAS_PIP}" >> "$f"
done

# 立即生效
export PATH="/usr/local/bin:$PATH"

# ===================== 5. 安装 uv =====================
info "安装 uv..."
pip3.12 install uv

# ===================== 6. 安装 AstrBot =====================
info "安装 AstrBot..."
cd "$HOME"
uv tool install astrbot && astrbot init

# ===================== 7. 安装 NapCat =====================
info "安装 NapCat..."
  # 安装sudo
    apt-get install -y sudo
cd "$HOME"
curl -o \
napcat.sh \
https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh \
&& bash napcat.sh \
--tui

# =================== 额外变量 ===================
# 定义要添加的内容
TIMEZONE_CONFIG='export TZ="Asia/Shanghai"'
UV_LINK_CONFIG='export UV_LINK_MODE=copy'
ASTRBOT_AUTOSTART='astrbot &'

# 检查并添加配置（避免重复）
for config in "$TIMEZONE_CONFIG" "$UV_LINK_CONFIG" "$ASTRBOT_AUTOSTART"; do
    if ! grep -qF "$config" ~/.bashrc; then
        echo "$config" >> ~/.bashrc
        info "已添加: $config"
    else
        info "已存在，跳过: $config"
    fi
done


# ===================== 完成 =====================
info "===================================================="
info "✅ 全自动安装完成！"
info "Python 3.12.12 + uv + AstrBot + NapCat 已全部部署"
info "请执行：source ~/.bashrc  使环境完全生效"
info "===================================================="
