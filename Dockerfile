FROM ubuntu:22.04 AS builder

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV RUST_LOG=info
ENV MINIMAL_LOG_FORMAT=true
ENV CARGO_BUILD_JOBS=8
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true


# 安装必要的构建依赖，精简依赖列表
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    iptables \
    git \
    lz4 \
    jq \
    libclang-dev \
    make \
    automake \
    ncdu \
    autoconf \
    tmux \
    htop \
    nvme-cli \
    libgbm1 \
    bsdmainutils \
    pkg-config \
    libssl-dev \
    libleveldb-dev \
    ca-certificates \
    build-essential \
    clang \
    llvm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# 安装 Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup default stable

# 配置 Cargo 源
RUN mkdir -p ~/.cargo \
    && echo '[build]' > ~/.cargo/config \
    && echo 'jobs = 8' >> ~/.cargo/config \
    && echo '[net]' >> ~/.cargo/config \
    && echo 'git-fetch-with-cli = true' >> ~/.cargo/config \
    && echo 'retry = 3' >> ~/.cargo/config

# 克隆项目并立即裁剪不必要的目录
WORKDIR /root
RUN git clone --depth=1 https://github.com/zorp-corp/nockchain && \
    cd nockchain && \
    rm -rf .git

# 切换到 nockchain 目录
WORKDIR /root/nockchain

# 创建必要的目录和文件
RUN mkdir -p hoon assets
RUN echo "%trivial" > hoon/trivial.hoon

# 编译 hoonc
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/nockchain/target \
    make install-hoonc

# 编译主项目
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/nockchain/target \
    make build

# 安装钱包
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/nockchain/target \
    make install-nockchain-wallet

# 安装主程序
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/nockchain/target \
    make install-nockchain

# 创建包含所有必要二进制文件的目录
RUN mkdir -p /root/nockchain/bin_backup && \
    find /root/.cargo/bin /root/nockchain/target/release -name "nockchain*" -o -name "hoonc" -o -name "choo" | xargs -I{} cp -f {} /root/nockchain/bin_backup/ 2>/dev/null || true

# ==== 第二阶段：最小化运行镜像 ====
FROM ubuntu:22.04 AS runner

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV RUST_LOG=info
ENV MINIMAL_LOG_FORMAT=true
ENV RUST_BACKTRACE=1
ENV RUST_LOG=debug
ENV PATH="/app/nockchain/bin:/app/nockchain/target/release:${PATH}"

# 安装运行时必须的依赖，极度精简
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    libssl3 \
    libleveldb1d \
    ca-certificates \
    libclang-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 准备目录
WORKDIR /app
RUN mkdir -p /app/nockchain/target/release /app/nockchain/bin /app/data /app/nockchain/hoon /app/nockchain/assets && \
    chmod -R 755 /app/nockchain

# 复制 Makefile
COPY --from=builder /root/nockchain/Makefile /app/nockchain/

# 复制所有必要的二进制文件
COPY --from=builder /root/nockchain/bin_backup/ /app/nockchain/bin/
RUN chmod +x /app/nockchain/bin/* && \
    ln -sf /app/nockchain/bin/* /app/nockchain/target/release/

# 复制必要的资源文件
COPY --from=builder /root/nockchain/hoon/ /app/nockchain/hoon/
COPY --from=builder /root/nockchain/assets/ /app/nockchain/assets/

# 创建数据卷并设置权限
VOLUME /app/data
RUN chmod 777 /app/data

# 复制入口脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 设置入口点
ENTRYPOINT ["docker-entrypoint.sh"]

# 默认命令
CMD ["leader"] 
