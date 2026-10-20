FROM registry.cncfstack.com/cncfstack/csvm:v0.2.1-bookworm AS builder

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:v0.2.0-bookworm" \
  org.opencontainers.image.source="https://github.com/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.url="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.documentation="https://cncfstack.com/images/cncfstack/openclaw-in-docker" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker 提供一个类似虚拟机的环境，一键运行 OpenClaw 服务，并提供安全的用户登录与 HTTPS 访问 OpenClaw 能力，使其可以便捷、安全的运行开放在互联网上。"

ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN useradd -m -s /bin/bash openclaw-in-docker
USER openclaw-in-docker

RUN sudo curl -fsSL https://deb.nodesource.com/setup_26.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

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

# 安装 openclaw，不初始化
RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
RUN openclaw gateway install
 
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
