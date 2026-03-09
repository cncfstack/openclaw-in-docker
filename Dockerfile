FROM registry.cncfstack.com/docker.io/kicbase/stable:v0.0.48

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:dev" \
  org.opencontainers.image.source="https://cncfstack.com" \
  org.opencontainers.image.url="https://cncfstack.com" \
  org.opencontainers.image.documentation="https://cncfstack.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker"

WORKDIR /app

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


# Install playwright
RUN  clean-install  xvfb && \
          mkdir -p /home/node/.cache/ms-playwright && \
          PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
          node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
          chown -R node:node /home/node/.cache/ms-playwright
#Xvfb :1 -screen 0 1280x800x24 -ac -nolisten tcp &

# Install chromium
RUN  clean-install  chromium websockify  x11vnc novnc
      

# 下载并安装 nodejs
RUN   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \      
      && \. "$HOME/.nvm/nvm.sh" \
      && nvm install 22 \
      && node -v

# Install Bun (required for build scripts)
#RUN GITHUB='https://gh-proxy.com/https://github.com' curl -fsSL https://bun.sh/install | bash
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"
RUN corepack enable

# install openclaw
#RUN git clone https://gh-proxy.com/https://github.com/openclaw/openclaw.git /app
RUN git clone -b v2026.3.2 https://github.com/openclaw/openclaw.git .

RUN chown -R node:node /app
#RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile  --registry https://registry.npmmirror.com
RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile

RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

# Expose the CLI binary without requiring npm global writes as non-root.
RUN ln -sf /app/openclaw.mjs /usr/local/bin/openclaw && chmod 755 /app/openclaw.mjs 


COPY scripts/openclaw-before.sh /usr/local/bin/openclaw-before.sh
COPY scripts/openclaw-after.sh  /usr/local/bin/openclaw-after.sh
COPY openclaw.service /usr/lib/systemd/system/openclaw.service
RUN chmod +x /usr/local/bin/openclaw-before.sh /usr/local/bin/openclaw-after.sh \
    && systemctl enable openclaw.service

ENV NODE_ENV=production
