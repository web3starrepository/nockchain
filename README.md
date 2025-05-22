# NockChain 安装和使用教程

## 项目信息
- ✈️ Telegram: https://t.me/Web3um
- 🐦 Twitter: https://x.com/m7ricks

## 系统要求
- Linux 或 macOS 系统
- 至少 64GB RAM
- 至少 50GB 可用磁盘空间
- 稳定的网络连接

## 快速开始

### 1. 下载安装脚本
```bash
wget https://raw.githubusercontent.com/zorp-corp/nockchain/main/install.sh
chmod +x install.sh
```

### 2. 运行安装脚本
```bash
sudo ./install.sh
```

## 安装选项说明

脚本提供以下功能选项：

1. 🚀 设置中国Rust镜像
   - 配置 Rust 和 Cargo 使用中国镜像源
   - 加速依赖下载和编译过程

2. 💻 安装部署nock (Linux)
   - 自动安装所需依赖
   - 配置系统环境
   - 编译和安装 NockChain

3. 🍎 安装部署nock (macOS)
   - 自动安装 Homebrew 和依赖
   - 配置系统环境
   - 编译和安装 NockChain

4. 🔑 备份密钥
   - 导出和备份钱包密钥
   - 生成格式化的密钥信息文件

## 编译优化

安装过程中会提示设置编译线程数：
- 建议设置为 CPU 核心数的 1-2 倍
- 直接回车将使用系统默认值（CPU核心数）
- 自动启用 CPU 特定优化

## 重要文件说明

安装完成后会生成以下文件：
- `wallet_keys.txt`: 原始钱包密钥信息
- `wallet_info.txt`: 格式化的钱包信息
- `miner.log`: 挖矿节点运行日志
- `miner_error.log`: 错误日志（如果发生）

## 注意事项

1. 🔐 安全提示
   - 请妥善保管钱包密钥文件
   - 不要泄露私钥和助记词
   - 建议定期备份密钥

2. ⚠️ 系统要求
   - 确保端口 3005 和 3006 未被占用
   - 保持系统时间同步
   - 确保网络连接稳定

3. 🔧 故障排除
   - 如果编译失败，检查系统依赖是否完整
   - 如果节点无法启动，检查端口占用情况
   - 查看 miner.log 获取详细错误信息

## 更新说明

- 支持 Linux 和 macOS 系统
- 自动检测系统类型并适配
- 优化编译性能
- 提供友好的中文界面
- 支持中国镜像加速

## 免责声明

本项目仅供学习和研究使用，使用本脚本产生的任何后果由用户自行承担。
