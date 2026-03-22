#!/bin/sh

# 使用 '#' 作为分隔符，避免 URL 中的 '/' 导致报错
# 注意：替换变量时，不需要在变量值两边手动加引号，除非原文件中就有引号且你需要保留

# 1. 更新 openresty.service (用户名和密码)
# 假设原文件内容是 Environment="OPENCLAW_USER=..."
sed -i \
    -e "s#Environment=\"OPENCLAW_USER=.*#Environment=\"OPENCLAW_USER=${OPENCLAW_USER}\"#g" \
    -e "s#Environment=\"OPENCLAW_PASSWORD=.*#Environment=\"OPENCLAW_PASSWORD=${OPENCLAW_PASSWORD}\"#g" \
     /lib/systemd/system/openresty.service

# 2. 更新 openclaw.service (Web URL)
sed -i \
    -e "s#Environment=\"OPENCLAW_WEB_URL=.*#Environment=\"OPENCLAW_WEB_URL=${OPENCLAW_WEB_URL}\"#g" \
     /lib/systemd/system/openclaw.service