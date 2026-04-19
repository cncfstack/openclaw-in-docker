FROM registry.cncfstack.com/cncfstack/csvm:v0.2.1-bookworm AS builder

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:v0.2.0-bookworm" \
  org.opencontainers.image.source="https://github.com/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.url="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.documentation="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker 提供一个类似虚拟机的环境，一键运行 OpenClaw 服务，并提供安全的用户登录与 HTTPS 访问 OpenClaw 能力，使其可以便捷、安全的运行开放在互联网上。"

WORKDIR /app

ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


# ============================================
# 安装 Node JS
# OpenClaw 要求：openclaw: Node.js v22.12+ is required
# csvm 中默认有 node 18 版本，需要新增一个 v22
#  node 用户和组已经存在，不需要再创建
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
RUN DEBIAN_FRONTEND=noninteractive clean-install nodejs \
    && node --version \
    && npm --version \
    && rm -f /usr/share/keyrings/nodesource.gpg \
    && rm -f /etc/apt/sources.list.d/nodesource.list \
    && rm -f /etc/apt/sources.list.d/nodesource.sources


# ============================================
# 安装 pnpm 和 bun
# 直接安装 bun 可能会失败，需要进行多次尝试
# ============================================
RUN set -eux; \
    for attempt in 1 2 3 4 5; do \
      if curl --retry 5 --retry-all-errors --retry-delay 2 -fsSL https://bun.sh/install | bash; then \
        break; \
      fi; \
      if [ "$attempt" -eq 5 ]; then \
        exit 1; \
      fi; \
      sleep $((attempt * 2)); \
    done
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable && corepack prepare pnpm@latest --activate


# ============================================
# Install OpenResty
# https://openresty.org/en/linux-packages.html#debian
# ============================================
COPY apt.d/openresty-*.sources /tmp/
ARG TARGETARCH
RUN case "$TARGETARCH" in \
        amd64) cp /tmp/openresty-amd64.sources /etc/apt/sources.list.d/openresty.sources ;; \
        arm64) cp /tmp/openresty-arm64.sources /etc/apt/sources.list.d/openresty.sources ;; \
    esac && rm /tmp/openresty-*.sources \
    && wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg \
    && DEBIAN_FRONTEND=noninteractive clean-install openresty
# Config Login
COPY login/login.html /usr/local/openresty/nginx/html/login.html
COPY login/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY login/password.lua /usr/local/openresty/site/lualib/password.lua
COPY login/ratelimit.lua /usr/local/openresty/site/lualib/ratelimit.lua
COPY login/users.lua /usr/local/openresty/site/lualib/users.lua
COPY scripts/openclaw-make-ssl.sh /usr/local/bin/openclaw-make-ssl.sh
COPY run_onboot /scripts/scripts.d
COPY systemd/openresty.service /lib/systemd/system/openresty.service
RUN chmod +x /usr/local/bin/openclaw-make-ssl.sh \
    && systemctl enable openresty.service 


# ============================================
# 开机启动crond服务
# cond 服务是csvm中已经预置安装，但是默认没有启动
# ============================================
RUN systemctl enable cron.service


# ============================================
# 下载OpenClaw源码
# 获取源码后 .git 目录中的不需要了，删除 .git 减少镜像包大小
# docs apps assets 目录资源不影响运行，可以删除
# ============================================
ARG OPENCLAW_VERSION
ENV OPENCLAW_VERSION=${OPENCLAW_VERSION}
RUN git clone -b v${OPENCLAW_VERSION} https://github.com/openclaw/openclaw.git . \
    && rm -rf .git \
    && rm -fr docs


# ============================================
# 编译构建OpenClaw
# 1. install 依赖 vite，在 package.json 中没有声明无法自动安装，这个后续关注
# 2. 默认会安装所有依赖，包括 devDependencies，所以在后面需要清理掉dev包
# 3. 将几个构建命令合并在一个RUN，减少层，降低空间大小
# 4. pnpm prune --prod : 删除当前项目的 devDependencies	
# 5. pnpm store prune : 清理全局存储中的未引用包	
# 6. pnpm cache clean : 清理 pnpm 的下载缓存
# ============================================
ENV CI=true
RUN pnpm add vite -w \
    && NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile \
    && pnpm ui:install \
    && pnpm build \
    && pnpm ui:build \
    && pnpm prune --prod \
    && pnpm store prune \
    && pnpm cache clean \
    && find dist -type f \( -name '*.d.ts' -o -name '*.d.mts' -o -name '*.d.cts' -o -name '*.map' \) -delete

    
# ============================================
# 配置openclaw
# ============================================
COPY scripts/openclaw-before.sh /usr/local/bin/openclaw-before.sh
COPY scripts/openclaw-autoapprove-devices.sh  /usr/local/bin/openclaw-autoapprove-devices.sh
COPY systemd/openclaw.service /usr/lib/systemd/system/openclaw.service
RUN chmod +x /usr/local/bin/openclaw-before.sh /usr/local/bin/openclaw-autoapprove-devices.sh \
    && ln -sf /app/openclaw.mjs /usr/local/bin/openclaw \
    && chmod 755 /app/openclaw.mjs \
    && systemctl enable openclaw.service


# ============================================
# 启动OpenClaw
# 1. 默认用户是root，工作目录切换到 /root
# 2. 启动服务不需要任何配置，openclaw是基于 systemd 服务自动启动的，这里不需要CMD指令
# ============================================
# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "fetch('http://localhost:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

WORKDIR /root

EXPOSE 18789 80 443