FROM ubuntu:22.04 AS builder

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ENV RUST_LOG=info
ENV MINIMAL_LOG_FORMAT=true

# 安装必要的构建依赖，精简依赖列表
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    make \
    gcc \
    pkg-config \
    libssl-dev \
    libleveldb-dev \
    ca-certificates \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup default stable

# 配置 Cargo 源
RUN mkdir -p ~/.cargo \
    && echo '[source.crates-io]' > ~/.cargo/config \
    && echo 'replace-with = "ustc"' >> ~/.cargo/config \
    && echo '[source.ustc]' >> ~/.cargo/config \
    && echo 'registry = "git://mirrors.ustc.edu.cn/crates.io-index"' >> ~/.cargo/config \
    && echo '[http]' >> ~/.cargo/config \
    && echo 'check-revoke = false' >> ~/.cargo/config

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

# 编译核心组件 - 精简编译命令并移除中间产物
RUN make install-hoonc || true && \
    make build || true && \
    make install-nockchain-wallet || true && \
    make install-nockchain || true && \
    # 清除编译缓存和中间文件
    rm -rf target/debug target/release/build target/release/deps target/release/.fingerprint

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
ENV PATH="/app/nockchain/bin:/app/nockchain/target/release:${PATH}"

# 安装运行时必须的依赖，极度精简
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    libssl3 \
    libleveldb1d \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 准备目录
WORKDIR /app
RUN mkdir -p /app/nockchain/target/release /app/nockchain/bin /app/data /app/nockchain/hoon /app/nockchain/assets

# 复制 Makefile
COPY --from=builder /root/nockchain/Makefile /app/nockchain/

# 复制所有必要的二进制文件
COPY --from=builder /root/nockchain/bin_backup/ /app/nockchain/bin/
RUN ln -sf /app/nockchain/bin/* /app/nockchain/target/release/

# 复制必要的资源文件
COPY --from=builder /root/nockchain/hoon/ /app/nockchain/hoon/
COPY --from=builder /root/nockchain/assets/ /app/nockchain/assets/

# 创建数据卷
VOLUME /app/data

# 复制入口脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 设置入口点
ENTRYPOINT ["docker-entrypoint.sh"]

# 默认命令
CMD ["leader"] 