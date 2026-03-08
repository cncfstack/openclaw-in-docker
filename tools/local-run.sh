#!/bin/bash




docker stop openclaw-in-docker ; docker rm openclaw-in-docker ; docker run -itd --name openclaw-in-docker --privileged -p 18789:18789 -p 18790:18790 openclaw-in-docker;docker logs openclaw-in-docker

ExecStart=/usr/local/bin/node /app/openclaw.mjs gateway --allow-unconfigured

Updated ~/.openclaw/openclaw.json
Workspace OK: ~/.openclaw/workspace
Sessions OK: ~/.openclaw/agents/main/sessions

