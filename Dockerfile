FROM registry.cncfstack.com/cncfstack/csvm:dev

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:dev" \
  org.opencontainers.image.source="https://cncfstack.com" \
  org.opencontainers.image.url="https://cncfstack.com" \
  org.opencontainers.image.documentation="https://cncfstack.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker"

WORKDIR /app

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

COPY openclaw.json /root/.openclaw/openclaw.json
COPY openclaw.service /usr/lib/systemd/system/openclaw.service
RUN systemctl enable openclaw-in-docker.service

ENV NODE_ENV=production


# RUN clean-install \
#     ca-certificates openssl curl wget telnet  gnupg hostname lsb-release  bash build-essential \
#     netcat-openbsd \
#     net-tools \
#     openssh  tmux \
#     fonts-liberation \
#     fonts-noto-color-emoji

# # Install File Management Tools
# RUN clean-install vim nano file unzip rsync less tree

# # Install Dev Ops tools
# RUN clean-install procps iotop iftop sysstat procps htop gdb strace nmap socat tcpdump traceroute dnsutils iputils-ping lsof

# # Install playwright
# RUN  clean-install  xvfb && \
#           mkdir -p /home/node/.cache/ms-playwright && \
#           PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
#           node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
#           chown -R node:node /home/node/.cache/ms-playwright
##Xvfb :1 -screen 0 1280x800x24 -ac -nolisten tcp &

# # Install chromium
# RUN  clean-install  chromium websockify  x11vnc novnc

# # Install Git
# RUN clean-install git git-lfs

# # Install data processing tools
# RUN clean-install jq python3