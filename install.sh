#!/bin/bash

# 颜色定义
RED='\033[0;31m'          # 红色
GREEN='\033[0;32m'        # 绿色
YELLOW='\033[1;33m'       # 黄色
BLUE='\033[0;34m'         # 蓝色
PURPLE='\033[0;35m'       # 紫色
CYAN='\033[0;36m'         # 青色
WHITE='\033[1;37m'        # 白色
NC='\033[0m'              # 无颜色

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请以 root 权限运行此脚本 (sudo)${NC}"
    exit 1
fi

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo -e "${CYAN}================================================================"
        echo -e "${WHITE}🐦 推特: ${BLUE}https://x.com/m7ricks"
        echo -e "${WHITE}✈️ TG: ${BLUE}https://t.me/Web3um"
        echo -e "${CYAN}================================================================"
        echo -e "${RED}❌ 退出脚本，请按键盘 Ctrl + C"
        echo -e "${WHITE}📝 请选择要执行的操作:"
        echo -e "${GREEN}1. 🚀 设置中国Rust镜像"
        echo -e "${GREEN}2. 💻 安装部署nock (Linux)"
        echo -e "${GREEN}3. 🍎 安装部署nock (macOS)"
        echo -e "${GREEN}4. 🔑 备份密钥"
        echo -e "${WHITE}请输入选项 (1-4):${NC}"
        read -r choice
        case $choice in
            1)
                setup_china_rust_mirror
                ;;
            2)
                install_nock "linux"
                ;;
            3)
                install_nock "macos"
                ;;
            4)
                backup_keys
                ;;
            *)
                echo -e "${RED}无效选项，请输入 1-4${NC}"
                sleep 2
                ;;
        esac
    done
}

# 设置中国Rust镜像函数
function setup_china_rust_mirror() {
    clear
    echo -e "${CYAN}🔄 正在设置中国Rust镜像...${NC}"
    
    # 询问用户是否要设置中国镜像
    echo -e "${YELLOW}❓ 是否要设置为中国Rust镜像？[Y/n]${NC}"
    read -r use_china_mirror
    use_china_mirror=${use_china_mirror:-y}  # 默认值为 y
    
    if [[ ! "$use_china_mirror" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏭️ 已跳过中国镜像设置。${NC}"
        echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
        read -r
        return
    fi
    
    # 设置 Rustup 镜像
    echo -e "${CYAN}🔄 正在设置 Rustup 镜像...${NC}"
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "export RUSTUP_DIST_SERVER=" "$HOME/.bashrc"; then
            echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> "$HOME/.bashrc"
            echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> "$HOME/.bashrc"
        else
            sed -i 's|^export RUSTUP_DIST_SERVER=.*|export RUSTUP_DIST_SERVER="https://rsproxy.cn"|' "$HOME/.bashrc"
            sed -i 's|^export RUSTUP_UPDATE_ROOT=.*|export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"|' "$HOME/.bashrc"
        fi
        source "$HOME/.bashrc"
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "export RUSTUP_DIST_SERVER=" "$HOME/.zshrc"; then
            echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> "$HOME/.zshrc"
            echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> "$HOME/.zshrc"
        else
            sed -i 's|^export RUSTUP_DIST_SERVER=.*|export RUSTUP_DIST_SERVER="https://rsproxy.cn"|' "$HOME/.zshrc"
            sed -i 's|^export RUSTUP_UPDATE_ROOT=.*|export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"|' "$HOME/.zshrc"
        fi
        source "$HOME/.zshrc"
    fi
    
    # 设置 crates.io 镜像
    echo "正在设置 crates.io 镜像..."
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config" <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF
    
    echo -e "${GREEN}✅ 中国Rust镜像设置完成！${NC}"
    echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
    read -r
}

# 安装部署nock 函数
function install_nock() {
    local os_type=$1
    # 设置错误处理：任何命令失败时退出
    set -e

    # 询问是否使用中国镜像
    echo -e "${YELLOW}❓ 是否要使用中国镜像加速安装？[Y/n]${NC}"
    read -r use_china_mirror
    use_china_mirror=${use_china_mirror:-y}  # 默认值为 y

    # 根据操作系统类型执行不同的安装步骤
    if [ "$os_type" = "macos" ]; then
        # macOS 特定的安装步骤
        echo -e "${CYAN}🍎 正在安装 macOS 依赖...${NC}"
        if ! command -v brew >/dev/null 2>&1; then
            echo -e "${YELLOW}🍺 正在安装 Homebrew...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        echo -e "${CYAN}📦 正在安装必要的软件包...${NC}"
        brew install curl git wget lz4 jq make gcc automake autoconf tmux htop pkg-config openssl leveldb clang ncdu unzip screen
    else
        # Linux 特定的安装步骤
        # 更新系统并升级软件包
        echo -e "${CYAN}🔄 正在更新系统并升级软件包...${NC}"
        if [[ "$use_china_mirror" =~ ^[Yy]$ ]]; then
            # 使用中国镜像源
            echo -e "${YELLOW}🌐 正在配置中国APT镜像源...${NC}"
            sed -i 's|http://.*archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list
            sed -i 's|http://.*security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list
        fi
        
        apt-get update && apt-get upgrade -y

        # 安装必要的软件包
        echo -e "${CYAN}📦 正在安装必要的软件包...${NC}"
        apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev screen -y
    fi

    # 安装 Rust（统一安装步骤）
    echo -e "${CYAN}🦀 正在安装 Rust...${NC}"
    if [[ "$use_china_mirror" =~ ^[Yy]$ ]]; then
        # 使用中国镜像安装Rust
        export RUSTUP_DIST_SERVER="https://rsproxy.cn"
        export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
        curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
    else
        # 使用官方源安装Rust
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    # 配置环境变量（Cargo 路径）
    echo -e "${CYAN}⚙️ 正在配置 Cargo 环境变量...${NC}"
    source $HOME/.cargo/env || { echo -e "${RED}错误：无法 source $HOME/.cargo/env，请检查 Rust 安装${NC}"; exit 1; }

    # 设置编译线程数
    echo -e "${YELLOW}❓ 请输入编译线程数（建议设置为 CPU 核心数的 1-2 倍，直接回车将使用默认值）：${NC}"
    read -r thread_count
    if [ -z "$thread_count" ]; then
        # 如果没有输入，使用 CPU 核心数
        thread_count=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    fi
    
    # 设置环境变量
    export RUSTFLAGS="-C target-cpu=native"
    export CARGO_BUILD_JOBS=$thread_count
    export MAKEFLAGS="-j$thread_count"
    
    echo -e "${GREEN}✅ 已设置编译线程数为：${BLUE}$thread_count${NC}"
    echo -e "${CYAN}🔄 正在使用优化的编译设置...${NC}"

    # 克隆 nockchain 仓库并进入目录
    echo -e "${CYAN}🧹 正在清理旧的 nockchain 和 .nockapp 目录...${NC}"
    rm -rf nockchain .nockapp
    echo -e "${CYAN}📥 正在克隆 nockchain 仓库...${NC}"
    git clone https://github.com/zorp-corp/nockchain
    cd nockchain || { echo -e "${RED}无法进入 nockchain 目录，克隆可能失败${NC}"; exit 1; }

    # 执行 make install-hoonc
    echo -e "${CYAN}🔧 正在执行 make install-hoonc...${NC}"
    make install-hoonc || { echo -e "${RED}执行 make install-hoonc 失败，请检查 nockchain 仓库的 Makefile 或依赖${NC}"; exit 1; }

    # 验证 hoonc 安装
    echo -e "${GREEN}✅ hoonc 安装成功，可用命令：hoonc${NC}"

    # 安装节点二进制文件
    echo -e "${CYAN}📦 正在安装节点二进制文件...${NC}"
    make build || { echo -e "${RED}执行 make build 失败，请检查 nockchain 仓库的 Makefile 或依赖${NC}"; exit 1; }

    # 安装钱包二进制文件
    echo -e "${CYAN}👛 正在安装钱包二进制文件...${NC}"
    make install-nockchain-wallet || { echo -e "${RED}执行 make install-nockchain-wallet 失败，请检查 nockchain 仓库的 Makefile 或依赖${NC}"; exit 1; }

    # 安装 Nockchain
    echo -e "${CYAN}🚀 正在安装 Nockchain...${NC}"
    make install-nockchain || { echo -e "${RED}执行 make install-nockchain 失败，请检查 nockchain 仓库的 Makefile 或依赖${NC}"; exit 1; }

    # 询问用户是否创建钱包，默认继续（y）
    echo "❓ 构建完毕，是否创建钱包？[Y/n]"
    read -r create_wallet
    create_wallet=${create_wallet:-y}  # 默认值为 y
    if [[ ! "$create_wallet" =~ ^[Yy]$ ]]; then
        echo "⏭️ 已跳过钱包创建。"
    else
        echo "👛 正在自动创建钱包..."
        # 执行 nockchain-wallet keygen
        if ! command -v nockchain-wallet >/dev/null 2>&1; then
            echo "❌ 错误：nockchain-wallet 命令不可用，请检查 target/release 目录或构建过程。"
            exit 1
        fi
        
        # 创建钱包并保存输出
        nockchain-wallet keygen > wallet_keys.txt || { echo "错误：nockchain-wallet keygen 执行失败"; exit 1; }
        
        # 提取并格式化保存关键信息
        echo "📝 正在提取并保存钱包信息..."
        {
            echo "================================================================"
            echo "🔐 钱包信息 - 请妥善保管！"
            echo "================================================================"
            echo "🔑 公钥 (Public Key):"
            grep -A 1 "New Public Key" wallet_keys.txt | tail -n 1 | tr -d '"' | tr -d ' '
            echo ""
            echo "🔒 私钥 (Private Key):"
            grep -A 1 "New Private Key" wallet_keys.txt | tail -n 1 | tr -d '"' | tr -d ' '
            echo ""
            echo "⛓️ 链码 (Chain Code):"
            grep -A 1 "Chain Code" wallet_keys.txt | tail -n 1 | tr -d '"' | tr -d ' '
            echo ""
            echo "🌱 助记词 (Seed Phrase):"
            grep -A 1 "Seed Phrase" wallet_keys.txt | tail -n 1 | tr -d "'" | tr -d ' '
            echo "================================================================"
            echo "⚠️ 警告：请妥善保管以上信息，特别是私钥和助记词！"
            echo "================================================================"
        } > wallet_info.txt
        
        echo "📝 钱包密钥已保存到 wallet_keys.txt（原始输出）"
        echo "📋 格式化后的钱包信息已保存到 wallet_info.txt，请妥善保管！"
    fi

    # 持久化 nockchain 的 target/release 到 PATH
    echo "⚙️ 正在将 $(pwd)/target/release 添加到 PATH..."
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "export PATH=\"\$PATH:$(pwd)/target/release\"" "$HOME/.bashrc"; then
            echo "export PATH=\"\$PATH:$(pwd)/target/release\"" >> "$HOME/.bashrc"
            source "$HOME/.bashrc"
        fi
    elif [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "export PATH=\"\$PATH:$(pwd)/target/release\"" "$HOME/.zshrc"; then
            echo "export PATH=\"\$PATH:$(pwd)/target/release\"" >> "$HOME/.zshrc"
            source "$HOME/.zshrc"
        fi
    else
        echo "未找到 ~/.bashrc 或 ~/.zshrc，请手动添加：export PATH=\"\$PATH:$(pwd)/target/release\""
    fi

    # 复制 .env_example 到 .env
    echo "📋 正在复制 .env_example 到 .env..."
    if [ -f ".env" ]; then
        cp .env .env.bak
        echo ".env 已备份为 .env.bak"
    fi
    if [ ! -f ".env_example" ]; then
        echo "错误：.env_example 文件不存在，请检查 nockchain 仓库。"
        exit 1
    fi
    cp .env_example .env || { echo "错误：无法复制 .env_example 到 .env"; exit 1; }

    # 提示用户输入 MINING_PUBKEY 用于 .env 和运行 nockchain
    echo "🔑 请输入您的 MINING_PUBKEY（用于 .env 文件和运行 nockchain）："
    read -r public_key
    if [ -z "$public_key" ]; then
        echo "错误：未提供 MINING_PUBKEY，请重新运行脚本并输入有效的公钥。"
        exit 1
    fi

    # 更新 .env 文件中的 MINING_PUBKEY
    echo "📝 正在更新 .env 文件中的 MINING_PUBKEY..."
    if ! grep -q "^MINING_PUBKEY=" .env; then
        echo "MINING_PUBKEY=$public_key" >> .env
    else
        if [ "$os_type" = "macos" ]; then
            # macOS 使用不同的 sed 语法
            sed -i '' "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$public_key|" .env || {
                echo "错误：无法更新 .env 文件中的 MINING_PUBKEY。"
                exit 1
            }
        else
            sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$public_key|" .env || {
                echo "错误：无法更新 .env 文件中的 MINING_PUBKEY。"
                exit 1
            }
        fi
    fi

    # 验证 .env 更新
    if grep -q "^MINING_PUBKEY=$public_key$" .env; then
        echo "✅ .env 文件更新成功！"
    else
        echo "错误：.env 文件更新失败，请检查文件内容。"
        exit 1
    fi

    # 检查端口 3005 和 3006 是否被占用
    echo "🔍 正在检查端口 3005 和 3006 是否被占用..."
    LEADER_PORT=3005
    FOLLOWER_PORT=3006
    if [ "$os_type" = "macos" ]; then
        # macOS 使用 lsof 检查端口
        if lsof -i :$LEADER_PORT >/dev/null 2>&1; then
            echo "错误：端口 $LEADER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
            exit 1
        fi
        if lsof -i :$FOLLOWER_PORT >/dev/null 2>&1; then
            echo "错误：端口 $FOLLOWER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
            exit 1
        fi
    else
        # Linux 使用 ss 或 netstat 检查端口
        if command -v ss >/dev/null 2>&1; then
            if ss -tuln | grep -q ":$LEADER_PORT "; then
                echo "错误：端口 $LEADER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
                exit 1
            fi
            if ss -tuln | grep -q ":$FOLLOWER_PORT "; then
                echo "错误：端口 $FOLLOWER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
                exit 1
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -tuln | grep -q ":$LEADER_PORT "; then
                echo "错误：端口 $LEADER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
                exit 1
            fi
            if netstat -tuln | grep -q ":$FOLLOWER_PORT "; then
                echo "错误：端口 $FOLLOWER_PORT 已被占用，请释放该端口或选择其他端口后重试。"
                exit 1
            fi
        else
            echo "错误：未找到 ss 或 netstat 命令，无法检查端口占用。"
            exit 1
        fi
    fi
    echo "✅ 端口 $LEADER_PORT 和 $FOLLOWER_PORT 未被占用，可继续执行。"

    # 验证 nockchain 命令是否可用
    echo "🔍 正在验证 nockchain 命令..."
    if ! command -v nockchain >/dev/null 2>&1; then
        echo "错误：nockchain 命令不可用，请检查 target/release 目录或构建过程。"
        exit 1
    fi

    # 清理现有的 miner screen 会话（避免冲突）
    echo "🧹 正在清理现有的 miner screen 会话..."
    screen -ls | grep -q "miner" && screen -X -S miner quit

    # 启动 screen 会话运行 nockchain --mining-pubkey <public_key> --mine
    echo "🚀 正在启动 screen 会话 'miner' 并运行 nockchain..."
    screen -dmS miner bash -c "nockchain --mining-pubkey \"$public_key\" --mine > miner.log 2>&1 || echo 'nockchain 运行失败' >> miner_error.log; exec bash"
    if [ $? -eq 0 ]; then
        echo "✅ screen 会话 'miner' 已启动，日志输出到 miner.log，可使用 'screen -r miner' 查看。"
    else
        echo "错误：无法启动 screen 会话 'miner'。"
        exit 1
    fi

    # 最终成功信息
    echo -e "${GREEN}✅ 所有步骤已成功完成！${NC}"
    echo -e "${WHITE}📂 当前目录：${BLUE}$(pwd)${NC}"
    echo -e "${WHITE}🔑 MINING_PUBKEY 已设置为：${BLUE}$public_key${NC}"
    echo -e "${WHITE}🌐 Leader 端口：${BLUE}$LEADER_PORT${NC}"
    echo -e "${WHITE}🌐 Follower 端口：${BLUE}$FOLLOWER_PORT${NC}"
    echo -e "${WHITE}📝 BTC 主网 RPC 调用结果已保存到 ${BLUE}btc_index_info.json${NC}"
    echo -e "${WHITE}🖥️ Nockchain 节点运行在 screen 会话 'miner' 中，日志在 ${BLUE}miner.log${NC}，可使用 'screen -r miner' 查看。"
    if [[ "$create_wallet" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔐 请妥善保存 wallet_keys.txt 中的密钥信息！${NC}"
    fi
    echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
    read -r
}

# 备份密钥函数
function backup_keys() {
    # 检查 nockchain-wallet 是否可用
    if ! command -v nockchain-wallet >/dev/null 2>&1; then
        echo -e "${RED}❌ 错误：nockchain-wallet 命令不可用，请先运行选项 1 安装部署nock。${NC}"
        echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
        read -r
        return
    fi

    # 检查 nockchain 目录是否存在
    if [ ! -d "nockchain" ]; then
        echo -e "${RED}❌ 错误：nockchain 目录不存在，请先运行选项 1 安装部署nock。${NC}"
        echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
        read -r
        return
    fi

    # 进入 nockchain 目录
    cd nockchain || { echo -e "${RED}❌ 错误：无法进入 nockchain 目录${NC}"; exit 1; }

    # 执行 nockchain-wallet export-keys
    echo -e "${CYAN}🔐 正在备份密钥...${NC}"
    nockchain-wallet export-keys > nockchain_keys_backup.txt 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 密钥备份成功！已保存到 ${BLUE}$(pwd)/nockchain_keys_backup.txt${NC}"
        echo -e "${YELLOW}⚠️ 请妥善保管该文件，切勿泄露！${NC}"
    else
        echo -e "${RED}❌ 错误：密钥备份失败，请检查 nockchain-wallet export-keys 命令输出。${NC}"
        echo -e "${WHITE}📝 详细信息见 ${BLUE}$(pwd)/nockchain_keys_backup.txt${NC}"
    fi

    echo -e "${WHITE}⏎ 按 Enter 键返回主菜单...${NC}"
    read -r
}

# 启动主菜单
main_menu