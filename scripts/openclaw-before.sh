#!/bin/bash
# openclaw-init.sh - 初始化 OpenClaw 配置文件

CONFIG_DIR="${HOME}/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"

# 默认配置文件内容
DEFAULT_CONFIG='{
    "gateway": {
        "controlUi": {
            "dangerouslyAllowHostHeaderOriginFallback": true,
            "allowInsecureAuth": true
        }
    }
}'

# 检查配置目录是否存在，不存在则创建
if [ ! -d "$CONFIG_DIR" ]; then
    echo "创建配置目录: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    # 设置目录权限 (755 = rwxr-xr-x)
    chmod 755 "$CONFIG_DIR"
fi

# 检查配置文件是否存在，不存在则创建
if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在，正在创建默认配置文件: $CONFIG_FILE"
    
    # 写入默认配置
    echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
    
    # 设置文件权限 (644 = rw-r--r--)
    chmod 644 "$CONFIG_FILE"
    
    echo "配置文件创建成功"
else
    echo "配置文件已存在: $CONFIG_FILE"
    # 可选：显示文件内容的前几行用于验证
    echo "当前配置文件内容预览:"
    head -5 "$CONFIG_FILE"
fi

# 验证配置文件是否可读
if [ -r "$CONFIG_FILE" ]; then
    echo "配置文件权限正确，可正常读取"
else
    echo "错误：配置文件不可读"
    exit 1
fi

exit 0