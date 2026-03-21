#!/bin/sh

# 在修改密码后，需要重新设置用户名密码
sed -i \
    -e "s/SED_USER/${OPENCLAW_USER}/g" \
    -e "s/SED_PASSWORD/${OPENCLAW_PASSWORD}/g" \
     /lib/systemd/system/openresty.service