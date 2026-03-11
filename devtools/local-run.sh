#!/bin/bash

cd ~
docker stop openclaw-in-docker 
docker rm openclaw-in-docker
docker volume rm openclaw-storage
docker run -itd \
  --name openclaw-in-docker \
  --hostname openclaw-in-docker \
  --privileged \
  -v /lib/modules:/lib/modules:ro \
  -v openclaw-storage:/var \
  -v ./data/rootopenclaw5:/root/.openclaw \
  -p 443:443 \
  --pull always \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:dev
docker logs  openclaw-in-docker

