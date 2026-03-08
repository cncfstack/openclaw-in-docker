#!/bin/bash

docker stop openclaw-in-docker 
docker rm openclaw-in-docker
docker run -itd --name openclaw-in-docker -p 18789:18789 --privileged --pull always \
 -v ./data/rootopenclaw:/root/.openclaw \
 registry.cncfstack.com/cncfstack/openclaw-in-docker:dev
docker logs -f openclaw-in-docker





# ExecStart=/usr/local/bin/node /app/openclaw.mjs gateway --allow-unconfigured

# Updated ~/.openclaw/openclaw.json
# Workspace OK: ~/.openclaw/workspace
# Sessions OK: ~/.openclaw/agents/main/sessions

docker run -itd --name testos --privileged registry.cncfstack.com/cncfstack/csvm:dev