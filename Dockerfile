FROM registry.cncfstack.com/cncfstack/csvm:v0.2.1-bookworm AS builder
# ============================================
# 阶段 1: Builder - 编译和构建
# ============================================

WORKDIR /build

# 安装构建工具
ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 安装 Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
# 安装 Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && DEBIAN_FRONTEND=noninteractive clean-install nodejs \
    && node --version && npm --version
    
# 安装 pnpm 和 bun
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


# Clone openclaw
ARG OPENCLAW_VERSION
ENV OPENCLAW_VERSION=${OPENCLAW_VERSION}
RUN git clone -b v${OPENCLAW_VERSION} https://github.com/openclaw/openclaw.git .

# 安装所有依赖（包括 devDependencies）
RUN --mount=type=cache,id=pnpm-store-build,target=/root/.local/share/pnpm/store,sharing=locked \
    NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile

# 处理 A2UI bundle（允许失败）
# A2UI bundle may fail under QEMU cross-compilation (e.g. building amd64
# on Apple Silicon). CI builds natively per-arch so this is a no-op there.
# Stub it so local cross-arch builds still succeed.
RUN pnpm canvas:a2ui:bundle || \
    (echo "A2UI bundle: creating stub (non-fatal)" && \
     mkdir -p src/canvas-host/a2ui && \
     echo "/* A2UI bundle unavailable in this build */" > src/canvas-host/a2ui/a2ui.bundle.js && \
     echo "stub" > src/canvas-host/a2ui/.bundle.hash && \
     rm -rf vendor/a2ui apps/shared/OpenClawKit/Tools/CanvasA2UI)

# 构建项目
RUN pnpm build && pnpm build:docker && pnpm ui:build

# 清理开发依赖（准备生产环境）
RUN pnpm prune --prod && \
    pnpm store prune && \
    find . -type f \( -name "*.map" -o -name "*.d.ts" -o -name "*.d.mts" \) -delete



# ============================================
# 阶段 2: Runtime - 运行环境
# ============================================
FROM registry.cncfstack.com/cncfstack/csvm:v0.2.1-bookworm AS runtime

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:v0.2.0-bookworm" \
  org.opencontainers.image.source="https://github.com/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.url="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.documentation="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker 提供一个类似虚拟机的环境，一键运行 OpenClaw 服务，并提供安全的用户登录与 HTTPS 访问 OpenClaw 能力，使其可以便捷、安全的运行开放在互联网上。"

ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WORKDIR /app

# 安装运行时必需的系统包
# 安装成功后需要删除 source.list，其他安装执行apt update时更新数据可能会导致内存OOM
RUN DEBIAN_FRONTEND=noninteractive clean-install nodejs \
        chromium \
        xvfb \
        curl \
        ca-certificates \
    && groupadd  node  \
    && useradd  --gid node --shell /bin/bash --create-home node

# Install OpenResty
# https://openresty.org/en/linux-packages.html#debian
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
    && systemctl enable openresty.service \
    && systemctl enable cron.service

# 从 builder 阶段复制构建产物
COPY --from=builder --chown=node:node /build/dist ./dist
COPY --from=builder --chown=node:node /build/node_modules ./node_modules
COPY --from=builder --chown=node:node /build/package.json .
COPY --from=builder --chown=node:node /build/openclaw.mjs .
COPY --from=builder --chown=node:node /build/ui/dist ./ui/dist
COPY --from=builder --chown=node:node /build/extensions ./extensions

# 安装 Playwright 浏览器
RUN mkdir -p /home/node/.cache/ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    node /app/node_modules/playwright-core/cli.js install chromium && \
    chown -R node:node /home/node/.cache/ms-playwright

# 设置权限和符号链接
RUN chmod +x /usr/local/bin/*.sh && \
    ln -sf /app/openclaw.mjs /usr/local/bin/openclaw && \
    chmod 755 /app/openclaw.mjs

COPY scripts/openclaw-before.sh /usr/local/bin/openclaw-before.sh
COPY scripts/openclaw-autoapprove-devices.sh  /usr/local/bin/openclaw-autoapprove-devices.sh
COPY systemd/openclaw.service /usr/lib/systemd/system/openclaw.service
RUN chmod +x /usr/local/bin/openclaw-before.sh /usr/local/bin/openclaw-autoapprove-devices.sh \
    && ln -sf /app/openclaw.mjs /usr/local/bin/openclaw \
    && chmod 755 /app/openclaw.mjs \
    && systemctl enable openclaw.service

# 切换到非 root 用户
# USER node

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "fetch('http://localhost:18789/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

EXPOSE 18789 8080

WORKDIR /app