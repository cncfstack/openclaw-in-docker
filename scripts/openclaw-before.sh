#!/bin/bash
# MIT License

# Copyright (c) 2026 藏云阁

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

CONFIG_DIR="${HOME}/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"

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
    cat > "$CONFIG_FILE" <<EOF
{
    "gateway": {
        "controlUi": {
            "allowedOrigins": [
                "${OPENCLAW_WEB_URL:-https://localhost}"
            ]
        }
    },
    "tools": {
        "profile": "full"
    }
}
EOF
    
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