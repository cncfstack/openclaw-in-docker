FROM registry.cncfstack.com/cncfstack/csvm:v0.1.0-bookworm-20260223

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:dev" \
  org.opencontainers.image.source="https://cncfstack.com" \
  org.opencontainers.image.url="https://cncfstack.com" \
  org.opencontainers.image.documentation="https://cncfstack.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker"

WORKDIR /app

# Install some packages
# Action:
# 1. bun --> unzip
RUN echo "Ensuring scripts are executable ..." \
    && chmod +x /usr/local/bin/clean-install /usr/local/bin/entrypoint \
    && echo "Installing Packages ..." \
    && DEBIAN_FRONTEND=noninteractive clean-install \
        systemd dbus \
        conntrack iptables iproute2 ethtool socat util-linux mount ebtables udev kmod \
        libseccomp2 pigz \
        bash ca-certificates curl rsync \
        nfs-common \
        iputils-ping netcat-openbsd  \
        openssl  wget telnet  gnupg hostname lsb-release   build-essential \
        net-tools \
        openssh-server tmux \
        vim nano file unzip  less tree \
        procps iotop iftop sysstat  htop gdb strace nmap  tcpdump traceroute dnsutils lsof \
        git git-lfs \
        jq python3 \
        lz4 \
        sudo

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 
RUN clean-install nodejs \
    && groupadd  node \
    && useradd  --gid node --shell /bin/bash --create-home node \
    && node --version \
    && npm --version \
    && rm -f /usr/share/keyrings/nodesource.gpg \
    && rm -f /etc/apt/sources.list.d/nodesource.list \
    && rm -f /etc/apt/sources.list.d/nodesource.sources

# Install Bun (required for build scripts)
#RUN GITHUB='https://gh-proxy.com/https://github.com' curl -fsSL https://bun.sh/install | bash
RUN curl -fsSL https://bun.sh/install | bash
RUN corepack enable

ENV PATH="/root/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"


ENV OPENCLAW_VERSION=v2026.3.2

# install openclaw
#RUN git clone https://gh-proxy.com/https://github.com/openclaw/openclaw.git /app
RUN git clone -b ${OPENCLAW_VERSION} https://github.com/openclaw/openclaw.git .

RUN chown -R node:node /app
#RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile  --registry https://registry.npmmirror.com
#RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile
RUN pnpm config set ignore-workspace-root-check true && pnpm add vite -w && pnpm install --frozen-lockfile
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

# Expose the CLI binary without requiring npm global writes as non-root.
RUN ln -sf /app/openclaw.mjs /usr/local/bin/openclaw && chmod 755 /app/openclaw.mjs 

COPY scripts/openclaw-before.sh /usr/local/bin/openclaw-before.sh
COPY scripts/openclaw-autoapprove-devices.sh  /etc/init.d/openclaw-autoapprove-devices.sh
COPY openclaw.service /usr/lib/systemd/system/openclaw.service
RUN chmod +x /usr/local/bin/openclaw-before.sh /etc/init.d/openclaw-autoapprove-devices.sh \
    && systemctl enable openclaw.service


# Install chromium
RUN  DEBIAN_FRONTEND=noninteractive clean-install  chromium websockify  x11vnc novnc

# Install playwright
# 依赖 openclaw package.json 安装后才能执行
RUN DEBIAN_FRONTEND=noninteractive clean-install  xvfb && \
    mkdir -p /home/node/.cache/ms-playwright && \
    PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
    chown -R node:node /home/node/.cache/ms-playwright
#Xvfb :1 -screen 0 1280x800x24 -ac -nolisten tcp &


# Install OpenResty
# https://openresty.org/en/linux-packages.html#debian
COPY apt.d/openresty-*.sources /tmp/
RUN case "$TARGETARCH" in \
        amd64) cp /tmp/openresty-amd64.sources /etc/apt/sources.list.d/openresty.sources ;; \
        arm64) cp /tmp/openresty-arm64.sources /etc/apt/sources.list.d/openresty.sources ;; \
    esac && rm /tmp/openresty-*.sources \
    && wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg \
    && echo $TARGETARCH \
    && ls /tmp/ \
    && ls /etc/apt/sources.list.d/ \
    && clean-install openresty