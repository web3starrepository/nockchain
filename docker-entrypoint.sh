#!/bin/bash
set -e

# ========= 防伪验证段 =========
# 混淆的脚本验证签名（不要修改此区域）
_V3R1FY_(){
  local _s="QMFeWdZFv8iKJ2CKFzXBYeTdLPwGnAh5pDsHt9RyE7NoU6jg"
  local _k=($(od -An -tx1 -v <<< "web3starrepository" | tr -d ' '))
  local _h=$(head -n 90 "$0" | grep -v "# _V3R1FY_SIGNATURE_" | sha256sum 2>/dev/null | cut -d' ' -f1)
  [ -z "$_h" ] && _h=$(head -n 90 "$0" | grep -v "# _V3R1FY_SIGNATURE_" | shasum -a 256 2>/dev/null | cut -d' ' -f1)
  local _c="e67d404c2edcf2fbf4858e20204b75a4cf02b693cbd73ad4b419a4ffc4df85d2"
  local _v="${_h:0:8}${_h:56:8}"
  
  # 简单检查是否被篡改
  if [ "${_v}" != "${_c:0:8}${_c:56:8}" ]; then
    if [ -t 1 ]; then  # 只在交互式终端显示警告
      echo -e "\033[1;33m警告: 脚本可能已被修改 [${_v}!=${_c:0:8}${_c:56:8}]\033[0m"
      sleep 1
    fi
  fi
  
  # 混淆返回值
  return $(( ${#_s} % 32 ))
}
# _V3R1FY_SIGNATURE_: d107b55e9a8f0ccdd3577736b899a09f9f27a776c9c5c7d1d02ad42b98ef12b0

# 运行防伪验证
_V3R1FY_ || :

# ========= 色彩定义 =========
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC=$RESET

# 过滤空字节函数
clean_output() {
  tr -d '\000'
}

# ========= 环境初始化 =========
setup_rust_env() {
  echo -e "${BLUE}🔧 配置 Rust 环境...${NC}"
  
  # 设置 Rust 环境变量
  export PATH="/root/.cargo/bin:/app/nockchain/target/release:$PATH"
  
  # 加载 cargo 环境
  if [ -f "/root/.cargo/env" ]; then
    source /root/.cargo/env
    echo -e "${GREEN}✅ 已加载 Rust 环境${NC}"
  fi
  
  # 检查环境
  if command -v cargo >/dev/null 2>&1; then
    echo -e "${GREEN}✅ cargo 命令可用: $(cargo --version)${NC}"
  else
    echo -e "${YELLOW}⚠️ cargo 命令不可用，将使用预编译二进制文件${NC}"
  fi
}

# ========= 横幅 =========
function show_banner() {
  # 使用BASE64混淆的横幅内容
  local _d=$(which base64)
  local _b="LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAgICAgICAgTm9ja2NoYWluIERvY2tlciDlrqLlnKgKLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KSDog55SxIHdlYjNzdGFycmVwb3NpdG9yeSDmj5DkvpwKVEc6IGh0dHBzOi8vdC5tZS93ZWIzdW0KdHdpdHRlcjogaHR0cHM6Ly94LmNvbS9tN3JpY2tzCi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCg=="
  local _c="\033[1;34m" # Blue color with Bold
  local _r="\033[0m"    # Reset color

  # 打印颜色开始
  echo -e "${_c}"
  
  # 解码并打印横幅
  if [ -x "$_d" ]; then
    echo -e "$($_d -d <<< "$_b")"
  else
    # 备用方案：写死的横幅
    echo "==============================================="
    echo "         Nockchain Docker 容器"
    echo "==============================================="
    echo "📌 由web3starrepository 提供"
    echo "TG: https://t.me/web3um"
    echo "twitter: https://x.com/m7ricks"
    echo "-----------------------------------------------"
  fi
  
  echo ""
  # 打印颜色结束
  echo -e "${_r}"
}

# 检查二进制文件函数
check_binary() {
  local binary_path="$1"
  local binary_name="$2"
  
  if [ ! -f "$binary_path" ]; then
    echo -e "${RED}❌ 错误: 未找到$binary_name: $binary_path${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✅ 找到$binary_name: $binary_path${NC}"
  return 0
}

# 显示帮助信息
show_help() {
  echo -e "${BLUE}Nockchain Docker 使用说明${NC}"
  echo -e "可用命令:"
  echo -e "  ${GREEN}leader${NC}     - 启动 leader 节点"
  echo -e "  ${GREEN}follower${NC}   - 启动 follower 节点"
  echo -e "  ${GREEN}genWallet${NC}  - 生成新钱包"
  echo -e "  ${GREEN}setKey${NC}     - 设置挖矿公钥 (setKey <公钥>)"
  echo -e "  ${GREEN}info${NC}       - 显示配置信息"
  echo -e "  ${GREEN}bash${NC}       - 启动终端"
  echo -e "  ${GREEN}help${NC}       - 显示此帮助"
}

# 生成钱包函数
generate_wallet() {
  echo -e "${BLUE}🔐 生成钱包...${NC}"
  
  # 检查钱包工具
  WALLET_CMD="/app/nockchain/target/release/nockchain-wallet"
  check_binary "$WALLET_CMD" "钱包工具" || exit 1
  
  # 生成钱包
  echo -e "[*] 运行钱包生成命令..."
  SEED_OUTPUT=$("$WALLET_CMD" keygen 2>&1 | clean_output)
  echo "$SEED_OUTPUT"
  
  # 提取密钥
  # 尝试提取助记词
  SEED_PHRASE=$(echo "$SEED_OUTPUT" | grep -iE "seed phrase" | sed 's/.*: //' | clean_output)
  
  # 提取私钥
  MASTER_PRIVKEY=""
  if [ -z "$SEED_PHRASE" ]; then
    # 直接模式: 从输出提取私钥 (修复错误的模式匹配)
    MASTER_PRIVKEY=$(echo "$SEED_OUTPUT" | grep -A1 "New Private Key" | tail -1 | sed 's/^[^"]*"//;s/".*$//' | clean_output)
    
    # 如果上面方法失败，尝试其他模式
    if [ -z "$MASTER_PRIVKEY" ]; then
      MASTER_PRIVKEY=$(echo "$SEED_OUTPUT" | grep -i "Private Key" | awk '{print $NF}' | tr -d '"' | clean_output)
    fi
  else
    # 助记词模式: 从助记词派生私钥
    echo -e "${GREEN}🧠 助记词：${NC}$SEED_PHRASE"
    echo -e "${BLUE}🔑 派生私钥...${NC}"
    MASTER_PRIVKEY=$("$WALLET_CMD" gen-master-privkey --seedphrase "$SEED_PHRASE" 2>&1 | grep -i "private key" | awk '{print $NF}' | clean_output)
  fi
  
  # 提取或生成公钥
  MASTER_PUBKEY=""
  if [ -z "$SEED_PHRASE" ]; then
    # 直接模式: 从输出提取公钥 (修复错误的模式匹配)
    # 提取多行公钥，处理可能跨越多行的情况
    MASTER_PUBKEY=$(echo "$SEED_OUTPUT" | grep -A3 "New Public Key" | grep -v "New Public Key" | grep '"' | sed 's/^[^"]*"//;s/".*$//' | tr -d '\n' | clean_output)
    
    # 如果上面方法失败，尝试其他模式
    if [ -z "$MASTER_PUBKEY" ]; then
      MASTER_PUBKEY=$(echo "$SEED_OUTPUT" | grep -i "Public Key" | awk '{print $NF}' | tr -d '"' | clean_output)
    fi
  else
    # 助记词模式: 从私钥派生公钥
    echo -e "${BLUE}📬 派生公钥...${NC}"
    MASTER_PUBKEY=$("$WALLET_CMD" gen-master-pubkey --master-privkey "$MASTER_PRIVKEY" 2>&1 | grep -i "public key" | awk '{print $NF}' | clean_output)
  fi
  
  # 验证密钥是否成功提取
  if [ -z "$MASTER_PRIVKEY" ] || [ -z "$MASTER_PUBKEY" ]; then
    echo -e "${RED}❌ 错误: 无法提取密钥${NC}"
    echo -e "${YELLOW}尝试处理原始格式...${NC}"
    
    # 最后的备选方案：直接原样保存行
    MASTER_PRIVKEY=$(echo "$SEED_OUTPUT" | grep -i "New Private Key" | clean_output)
    MASTER_PUBKEY=$(echo "$SEED_OUTPUT" | grep -i "New Public Key" | clean_output)
    
    # 仍然无法提取时退出
    if [ -z "$MASTER_PRIVKEY" ] || [ -z "$MASTER_PUBKEY" ]; then
      echo -e "${RED}❌ 无法识别的钱包输出格式${NC}"
      exit 1
    fi
  fi
  
  # 显示和保存密钥
  echo -e "${GREEN}🔑 私钥: ${NC}$MASTER_PRIVKEY"
  echo -e "${GREEN}📬 公钥: ${NC}$MASTER_PUBKEY"
  
  # 保存到持久化存储
  mkdir -p /app/data
  [ ! -z "$SEED_PHRASE" ] && echo "$SEED_PHRASE" > /app/data/seed_phrase.txt
  echo "$MASTER_PRIVKEY" > /app/data/master_privkey.txt
  echo "$MASTER_PUBKEY" > /app/data/master_pubkey.txt
  
  # 设置挖矿公钥
  # 如果公钥还包含标识文本，提取实际的公钥部分
  MINING_PUBKEY="$MASTER_PUBKEY"
  if [[ "$MINING_PUBKEY" == *"Public Key"* ]]; then
    MINING_PUBKEY=$(echo "$MASTER_PUBKEY" | grep -o '".*"' | tr -d '"')
  fi
  
  set_mining_pubkey "$MINING_PUBKEY"
  
  echo -e "${GREEN}✅ 钱包已保存到 /app/data 目录${NC}"
}

# 设置挖矿公钥函数
set_mining_pubkey() {
  if [ -z "$1" ]; then
    echo -e "${RED}❌ 错误: 未提供公钥${NC}"
    exit 1
  fi
  
  MINING_PUBKEY="$1"
  echo -e "${BLUE}📄 设置挖矿公钥...${NC}"
  
  # 检查 Makefile
  if [ ! -f "/app/nockchain/Makefile" ]; then
    echo -e "${RED}❌ 错误: 未找到 Makefile${NC}"
    exit 1
  fi
  
  # 更新 Makefile
  sed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $MINING_PUBKEY|" /app/nockchain/Makefile
  
  # 保存公钥
  mkdir -p /app/data
  echo "$MINING_PUBKEY" > /app/data/mining_pubkey.txt
  
  echo -e "${GREEN}✅ 挖矿公钥已设置: ${NC}$MINING_PUBKEY"
}

# 显示配置信息
show_info() {
  echo -e "${BLUE}Nockchain 配置信息${NC}"
  
  # 检查二进制文件
  echo -e "${BLUE}二进制文件:${NC}"
  check_binary "/app/nockchain/target/release/nockchain-wallet" "钱包工具" && \
    echo -e "${GREEN}版本: ${NC}$(/app/nockchain/target/release/nockchain-wallet --version 2>/dev/null | clean_output || echo "未知")"
  
  check_binary "/app/nockchain/target/release/nockchain" "节点程序" && \
    echo -e "${GREEN}版本: ${NC}$(/app/nockchain/target/release/nockchain --version 2>/dev/null | clean_output || echo "未知")"
  
  check_binary "/app/nockchain/target/release/hoonc" "hoonc 工具"
  
  
  # 1. 首先检查 Makefile 中的公钥
  MAKEFILE_PUBKEY=""
  if [ -f "/app/nockchain/Makefile" ]; then
    MAKEFILE_PUBKEY=$(grep "MINING_PUBKEY :=" /app/nockchain/Makefile | sed 's/.*MINING_PUBKEY := //' | clean_output)
    echo -e "${GREEN}Makefile 中的公钥: ${NC}$MAKEFILE_PUBKEY"
  else
    echo -e "${YELLOW}⚠️ 未找到 Makefile${NC}"
  fi
  
  # 2. 再检查持久化存储中的公钥
  DATA_PUBKEY=""
  if [ -f "/app/data/mining_pubkey.txt" ]; then
    DATA_PUBKEY=$(cat /app/data/mining_pubkey.txt | clean_output)
    echo -e "${GREEN}数据目录中的公钥: ${NC}$DATA_PUBKEY"
    
    # 3. 比较两个公钥是否一致
    if [ ! -z "$MAKEFILE_PUBKEY" ] && [ ! -z "$DATA_PUBKEY" ] && [ "$MAKEFILE_PUBKEY" != "$DATA_PUBKEY" ]; then
      echo -e "${YELLOW}⚠️ 警告: Makefile 中的公钥与数据目录中的不一致${NC}"
      # 自动更新 Makefile 中的公钥
      read -p "是否更新 Makefile 中的公钥? (y/n): " update_pubkey
      if [[ "$update_pubkey" == "y" || "$update_pubkey" == "Y" ]]; then
        set_mining_pubkey "$DATA_PUBKEY"
      fi
    fi
  else
    echo -e "${YELLOW}⚠️ 未在数据目录找到挖矿公钥${NC}"
    
    # 如果 Makefile 中有公钥但数据目录没有，则保存到数据目录
    if [ ! -z "$MAKEFILE_PUBKEY" ]; then
      echo -e "${YELLOW}将 Makefile 中的公钥保存到数据目录...${NC}"
      mkdir -p /app/data
      echo "$MAKEFILE_PUBKEY" > /app/data/mining_pubkey.txt
      echo -e "${GREEN}✅ 已保存${NC}"
    fi
  fi
  
  # 如果两处都没有公钥
  if [ -z "$MAKEFILE_PUBKEY" ] && [ -z "$DATA_PUBKEY" ]; then
    echo -e "${RED}❌ 未设置挖矿公钥，需要生成钱包或设置挖矿公钥${NC}"
  fi
  
  # 系统信息
  echo -e "${BLUE}系统:${NC}"
  echo -e "${GREEN}CPU: ${NC}$(nproc)核"
  echo -e "${GREEN}内存: ${NC}$(free -h | grep "Mem" | awk '{print $2}')"
  
  # Rust 环境信息
  echo -e "${BLUE}Rust 环境:${NC}"
  if command -v cargo >/dev/null 2>&1; then
    echo -e "${GREEN}cargo 版本: ${NC}$(cargo --version 2>/dev/null || echo "无法获取版本")"
    echo -e "${GREEN}rustc 版本: ${NC}$(rustc --version 2>/dev/null || echo "无法获取版本")"
  else
    echo -e "${YELLOW}cargo 未安装或不在PATH中${NC}"
  fi
}

# 初始化 hoon 环境
initialize_hoon() {
  echo -e "${BLUE}🌀 初始化 hoon 环境...${NC}"
  
  mkdir -p /app/nockchain/hoon /app/nockchain/assets
  echo "%trivial" > /app/nockchain/hoon/trivial.hoon
  
  if [ -f "/app/nockchain/target/release/choo" ]; then
    echo -e "${GREEN}执行 choo 初始化...${NC}"
    /app/nockchain/target/release/choo --new --arbitrary /app/nockchain/hoon/trivial.hoon 2>&1 | clean_output
    echo -e "${GREEN}✅ 初始化完成${NC}"
  else
    echo -e "${YELLOW}⚠️ choo 工具未找到${NC}"
  fi
}

# 启动节点函数
start_node() {
  local node_type="$1"
  
  # 检查二进制文件
  NOCKCHAIN_BIN="/app/nockchain/bin/nockchain"
  if [ ! -f "$NOCKCHAIN_BIN" ]; then
    NOCKCHAIN_BIN="/app/nockchain/target/release/nockchain"
  fi
  
  if [ ! -f "$NOCKCHAIN_BIN" ]; then
    echo -e "${RED}❌ 错误: 未找到节点程序二进制文件${NC}"
    echo -e "${YELLOW}尝试从 PATH 中查找 nockchain 命令...${NC}"
    NOCKCHAIN_BIN=$(which nockchain 2>/dev/null)
    
    if [ -z "$NOCKCHAIN_BIN" ]; then
      echo -e "${RED}❌ 致命错误: 找不到 nockchain 可执行文件${NC}"
      exit 1
    fi
  fi
  
  echo -e "${GREEN}✅ 找到节点程序: $NOCKCHAIN_BIN${NC}"
  
  # 检查挖矿公钥
  if [ ! -f "/app/data/mining_pubkey.txt" ]; then
    echo -e "${YELLOW}⚠️ 未设置挖矿公钥，生成新钱包...${NC}"
    generate_wallet
  else
    MINING_PUBKEY=$(cat /app/data/mining_pubkey.txt | clean_output)
    set_mining_pubkey "$MINING_PUBKEY"
  fi
  
  # 获取当前挖矿公钥
  MINING_PUBKEY=$(cat /app/data/mining_pubkey.txt | clean_output)
  
  # 启动节点
  echo -e "${BLUE}🚀 启动 $node_type 节点...${NC}"
  
  if [ "$node_type" = "leader" ]; then
    # 创建并进入工作目录
    mkdir -p /app/data/leader && cd /app/data/leader
    # 删除旧的socket文件
    rm -f nockchain.sock
    
    echo -e "${GREEN}执行命令: $NOCKCHAIN_BIN --fakenet --genesis-leader --npc-socket nockchain.sock --mining-pubkey $MINING_PUBKEY...${NC}"
    
    # 直接执行二进制文件
    exec "$NOCKCHAIN_BIN" \
      --fakenet \
      --genesis-leader \
      --npc-socket nockchain.sock \
      --mining-pubkey "$MINING_PUBKEY" \
      --bind /ip4/0.0.0.0/udp/3005/quic-v1 \
      --peer /ip4/127.0.0.1/udp/3006/quic-v1 \
      --new-peer-id \
      --no-default-peers
  else
    # 创建并进入工作目录
    mkdir -p /app/data/follower && cd /app/data/follower
    # 删除旧的socket文件
    rm -f nockchain.sock
    
    echo -e "${GREEN}执行命令: $NOCKCHAIN_BIN --fakenet --npc-socket nockchain.sock --mining-pubkey $MINING_PUBKEY...${NC}"
    
    # 直接执行二进制文件
    exec "$NOCKCHAIN_BIN" \
      --fakenet \
      --npc-socket nockchain.sock \
      --mining-pubkey "$MINING_PUBKEY" \
      --bind /ip4/0.0.0.0/udp/3006/quic-v1 \
      --peer /ip4/127.0.0.1/udp/3005/quic-v1 \
      --new-peer-id \
      --no-default-peers
  fi
}

# 主函数
main() {
  show_banner
  echo -e "${BLUE}Nockchain Docker 容器启动...${NC}"
  
  # 设置 Rust 环境
  setup_rust_env
  
  # 创建数据目录
  mkdir -p /app/data
  
  # 解析命令
  case "$1" in
    leader)
      start_node "leader"
      ;;
    follower)
      start_node "follower"
      ;;
    genWallet)
      generate_wallet
      ;;
    setKey)
      set_mining_pubkey "$2"
      ;;
    info)
      show_info
      ;;
    initHoon)
      initialize_hoon
      ;;
    bash)
      exec bash
      ;;
    help|*)
      [ "$1" != "help" ] && echo -e "${YELLOW}⚠️ 未知命令: $1${NC}"
      show_help
      [ "$1" != "help" ] && exit 1
      ;;
  esac
}

# 执行主函数
main "$@" 