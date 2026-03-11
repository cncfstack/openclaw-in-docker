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

while true; do
    echo "检查 pending 设备配对请求..."

    # 获取所有 pending requestId
    REQUEST_IDS=$(openclaw devices list --json | jq -r '.pending[].requestId')

    if [ -z "$REQUEST_IDS" ] || [ "$REQUEST_IDS" = "" ]; then
        echo "没有找到 pending 的配对请求，验证设备列表中所有项目都不是pending状态..."
        
        # 检查总的设备数量来确认是否处理完毕
        ALL_DEVICES_JSON=$(openclaw devices list --json)
        PENDING_COUNT=$(echo "$ALL_DEVICES_JSON" | jq -r '[.pending[]] | length')
        
        if [[ "$PENDING_COUNT" -eq 0 ]]; then
            echo "设备列表中没有pending请求 - 脚本退出"
            break
        fi
    else
        # 将REQUEST_IDS转换为数组处理
        while IFS= read -r REQUEST_ID; do
            if [ -n "$REQUEST_ID" ] && [ "$REQUEST_ID" != "" ]; then
                echo "批准请求: $REQUEST_ID"
                openclaw devices approve "$REQUEST_ID"
                
                if [ $? -eq 0 ]; then
                    echo "✓ 已批准"
                else
                    echo "✗ 批准失败"
                fi
            fi
        done <<< "$(echo "$REQUEST_IDS")"
    fi

    # 等待10秒后再次检查
    echo "等待10秒后重新检查..."
    sleep 10
    
    # 显示当前设备状态
    echo -e "\n当前设备列表:"
    openclaw devices list
    echo -e "---\n"
done

echo "所有设备配对请求已处理完成。" > /tmp/openclaw-autoapprove-devices.log
exit 0