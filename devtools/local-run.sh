#!/bin/bash -x

VER=${1:-dev}
cd ~
docker stop openclaw-in-docker-dev
docker rm openclaw-in-docker-dev
rm -fr ./data/openclaw-dev
docker volume rm openclaw-storage-dev
docker run -itd \
  --name openclaw-in-docker-dev \
  --hostname openclaw-in-docker-dev \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v openclaw-storage-dev:/var \
  -v ./data/openclaw-dev:/root/.openclaw \
  -p 443:443 -p 80:80 \
  --pull always \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:${VER}
sleep 3
docker logs  openclaw-in-docker-dev

