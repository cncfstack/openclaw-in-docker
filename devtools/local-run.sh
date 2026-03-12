#!/bin/bash -x

VER=${1:-dev}
cd ~
docker stop openclaw-in-docker 
docker rm openclaw-in-docker
rm -fr ./data/rootopenclaw_dev
docker volume rm openclaw-storage
docker run -itd \
  --name openclaw-in-docker \
  --hostname openclaw-in-docker \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v openclaw-storage:/var \
  -v ./data/rootopenclaw_dev:/root/.openclaw \
  -p 443:443 \
  --pull always \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:${VER}
sleep 3
docker logs  openclaw-in-docker

