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
#USER root
RUN ln -sf /app/openclaw.mjs /usr/local/bin/openclaw \
 && chmod 755 /app/openclaw.mjs

COPY openclaw-in-docker.service /usr/lib/systemd/system/openclaw-in-docker.service
RUN systemctl enable openclaw-in-docker.service

COPY openclaw.json /root/.openclaw/openclaw.json

ENV NODE_ENV=production
#ENV OPENAI_API_KEY=fdsafdsafdsafds22rfdsa

RUN mkdir -p /root/.openclaw/workspace


# Optionally install Chromium and Xvfb for browser automation.
# Build with: docker build --build-arg OPENCLAW_INSTALL_BROWSER=1 ...
# Adds ~300MB but eliminates the 60-90s Playwright install on every container start.
# Must run after pnpm install so playwright-core is available in node_modules.
# USER root
# ARG OPENCLAW_INSTALL_BROWSER="1"
# RUN if [ -n "$OPENCLAW_INSTALL_BROWSER" ]; then \
#       apt-get update && \
#       DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
#       mkdir -p /home/node/.cache/ms-playwright && \
#       PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
#       node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
#       chown -R node:node /home/node/.cache/ms-playwright && \
#       apt-get clean && \
#       rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
#     fi

RUN clean-install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    fail2ban \
    vim \
    nano \
    git \
    git-lfs \
    curl \
    wget \
    netcat-openbsd \
    net-tools \
    dnsutils \
    iputils-ping \
    traceroute \
    tcpdump \
    nmap \
    socat \
    telnet \
    strace \
    lsof \
    gdb \
    htop \
    iotop \
    iftop \
    sysstat \
    procps \
    tmux \
    tree \
    jq \
    unzip \
    rsync \
    less \
    build-essential \
    file \
    procps \
    hostname \
    openssl