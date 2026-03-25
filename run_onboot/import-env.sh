#!/bin/sh

# 将系统的环境变量写入文件中，用于 systemd 服务启动时，将环境变量导入
ENV_CMD=`which env`
$ENV_CMD > /root/.env