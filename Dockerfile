FROM registry.cncfstack.com/cncfstack/csvm:dev2

LABEL org.opencontainers.image.base.name="registry.cnfstack.com/cncfstack/csvm:dev" \
  org.opencontainers.image.source="https://cncfstack.com" \
  org.opencontainers.image.url="https://cncfstack.com" \
  org.opencontainers.image.documentation="https://cncfstack.com" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.title="OpenClaw In Docker" \
  org.opencontainers.image.description="OpenClaw In Docker"

WORKDIR /app

ENV OPENCLAW_VERSION=v2026.3.2

# install openclaw
#RUN git clone https://gh-proxy.com/https://github.com/openclaw/openclaw.git /app
RUN git clone -b ${OPENCLAW_VERSION} https://github.com/openclaw/openclaw.git .

#RUN chown -R node:node /app
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