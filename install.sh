#!/bin/bash

# 颜色定义
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

banner() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║                                                          ║"
  echo "║  ███╗   ██╗ ██████╗  ██████╗██╗  ██╗ ██████╗██╗  ██╗   ║"
  echo "║  ████╗  ██║██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██║ ██╔╝   ║"
  echo "║  ██╔██╗ ██║██║   ██║██║     █████╔╝ ██║     █████╔╝    ║"
  echo "║  ██║╚██╗██║██║   ██║██║     ██╔═██╗ ██║     ██╔═██╗    ║"
  echo "║  ██║ ╚████║╚██████╔╝╚██████╗██║  ██╗╚██████╗██║  ██╗   ║"
  echo "║  ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ║"
  echo "║                                                          ║"
  echo "║  ${BOLD}🚀 矿工程序 BY m7ricks 🚀${RESET}${CYAN}                          ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║  ${BOLD}📢 社区信息${RESET}${CYAN}                                        ║"
  echo "║  🔗 推特:  ${BOLD}https://x.com/m7ricks${RESET}${CYAN}                   ║"
  echo "║  💬 电报:  ${BOLD}https://t.me/Web3um${RESET}${CYAN}                    ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

check_success() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 发生错误。正在退出。${RESET}"
    exit 1
  fi
}

prompt_continue() {
  read -rp "$(echo -e "${YELLOW}➡️  $1 (y/n): ${RESET}")" answer
  case "$answer" in
    [Yy]*) return 0 ;;
    [Nn]*) echo -e "${RED}❌ 正在退出...${RESET}"; exit 1 ;;
    *) echo -e "${RED}❗ 请输入 y 或 n。${RESET}"; prompt_continue "$1" ;;
  esac
}

# 显示横幅
clear
banner
echo -e "${YELLOW}⏳ 请稍等... 7秒后开始设置环境...${RESET}"
sleep 7

# 安装依赖
echo -e "${CYAN}📦 正在更新系统并安装必要的包...${RESET}"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev llvm-dev screen -y
check_success

# 安装 Rust
echo -e "${CYAN}🦀 正在安装 Rust...${RESET}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
check_success

# 清理和克隆
echo -e "${CYAN}🧹 正在清理并克隆 Nockchain 仓库...${RESET}"
rm -rf nockchain ~/.nockapp
git clone https://github.com/zorp-corp/nockchain
cd nockchain || exit
cp .env_example .env
check_success

# 构建步骤
echo -e "${CYAN}⚙️ 正在构建项目... 这可能需要 30-40 分钟。${RESET}"
make install-hoonc
make build
make install-nockchain-wallet
make install-nockchain
export PATH="$PATH:$(pwd)/target/release"
check_success

# 生成钱包
echo -e "${CYAN}🔐 正在生成新钱包...${RESET}"
nockchain-wallet keygen
check_success

prompt_continue "您是否已安全保存了钱包密钥和助记词？"

# 替换公钥
read -rp "$(echo -e "${YELLOW}🔑 请输入您的公钥以更新 .env 文件: ${RESET}")" pubkey
sed -i "s|MINING_PUBKEY=.*|MINING_PUBKEY=$pubkey|" .env
echo -e "${GREEN}✅ .env 文件已使用您的公钥更新。${RESET}"

# 最终启动提示
read -rp "$(echo -e "${YELLOW}🚀 请重新输入您的公钥以启动矿工: ${RESET}")" start_pubkey

echo -e "${GREEN}🚀 正在启动 Nockchain 矿工...${RESET}"
RUST_LOG=info,nockchain=info,nockchain_libp2p_io=info,libp2p=info,libp2p_quic=info
MINIMAL_LOG_FORMAT=true

nockchain --mining-pubkey "$start_pubkey" --mine \
--peer /ip4/95.216.102.60/udp/3006/quic-v1 \
--peer /ip4/65.108.123.225/udp/3006/quic-v1 \
--peer /ip4/65.109.156.108/udp/3006/quic-v1 \
--peer /ip4/65.21.67.175/udp/3006/quic-v1 \
--peer /ip4/65.109.156.172/udp/3006/quic-v1 \
--peer /ip4/34.174.22.166/udp/3006/quic-v1 \
--peer /ip4/34.95.155.151/udp/30000/quic-v1 \
--peer /ip4/34.18.98.38/udp/30000/quic-v1 \
--peer /ip4/96.230.252.205/udp/3006/quic-v1 \
--peer /ip4/94.205.40.29/udp/3006/quic-v1 \
--peer /ip4/159.112.204.186/udp/3006/quic-v1 \
--peer /ip4/217.14.223.78/udp/3006/quic-v1


echo -e "${GREEN}🎉 您的节点已启动并开始挖矿！关注我获取更新: https://x.com/m7ricks${RESET}"
