#!/bin/bash
# approve-all-pending.sh - 批准所有待处理的设备配对请求

echo "检查 pending 设备配对请求..."

# 获取所有 pending requestId
REQUEST_IDS=$(openclaw devices list --json | jq -r '.pending[].requestId')

if [ -z "$REQUEST_IDS" ]; then
    echo "没有找到 pending 的配对请求"
    exit 0
fi

# 逐个批准
echo "$REQUEST_IDS" | while read -r REQUEST_ID; do
    if [ -n "$REQUEST_ID" ]; then
        echo "批准请求: $REQUEST_ID"
        openclaw devices approve "$REQUEST_ID"
        
        if [ $? -eq 0 ]; then
            echo "✓ 已批准"
        else
            echo "✗ 批准失败"
        fi
    fi
done

# 显示最终状态
echo -e "\n更新后的设备列表:"
openclaw devices list