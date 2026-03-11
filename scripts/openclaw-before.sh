#!/bin/bash
# openclaw-init.sh - 初始化 OpenClaw 配置文件

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
                ${OPENCLAW_WEB_URL:-"http://localhost"}
            ],
            "dangerouslyAllowHostHeaderOriginFallback": true,
            "allowInsecureAuth": true
        }
    }
}'
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

# 为了保证安全，必须使用HTTPS加密。如果没有合法证书，默认使用自签名证书
# OPENCLAW_WEB_ADDRESS 是通过环境变量传递的值

# OPENCLAW_WEB_ADDRESS 通过 OPENCLAW_WEB_URL 环境变量传递，
# 需要对OPENCLAW_WEB_URL中的字符串进行处理，删除端口号和协议
OPENCLAW_WEB_ADDRESS=$(echo ${OPENCLAW_WEB_URL:-localhost} | sed 's/https:\/\///g' | sed 's/http:\/\///g' | sed 's/:.*//g')
if [ ! -f /root/.openclaw/ssl/cert.pem  -a ! -f /root/.openclaw/ssl/cert.key ];then

    echo "没有发现证书文件 /root/.openclaw/ssl/cert.pem 和 /root/.openclaw/ssl/cert.key, 开始自签名创建证书..."
    mkdir -p ~/.openclaw/ssl/autossl
    cd ~/.openclaw/ssl/autossl

    echo "  (1/6)创建CA的私钥"
    openssl genrsa -out ca.key 2048

    echo "  (2/6)创建CA的证书请求文件"
    openssl req -new -key ca.key \
                -subj "/C=CN/ST=ZJ/L=HZ/O=testca.com/OU=testca/CN=testca.com/emailAddress=admin@testca.com" \
                -out ca.csr

    echo "  (3/6)CA自签证书"
    openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt -days 36500

    echo "  (4/6)创建用户域名的私钥"
    openssl genrsa -out ${OPENCLAW_WEB_ADDRESS}.key 2048

    echo "  (5/6)创建域名证书请求文件"
    openssl req -new -key ${OPENCLAW_WEB_ADDRESS}.key \
        -subj "/C=CN/ST=ZJ/L=HZ/O=test.com/OU=test/CN=*.${OPENCLAW_WEB_ADDRESS}/emailAddress=pritest@test.com" \
        -addext "subjectAltName = DNS:*.${OPENCLAW_WEB_ADDRESS}, DNS:${OPENCLAW_WEB_ADDRESS}" \
        -out ${OPENCLAW_WEB_ADDRESS}.csr

    echo "  (6/6)使用CA证书给域名的请求文件添加数字签名制作用户证书"
    openssl x509 -req -CA ca.crt  -CAkey ca.key  -CAcreateserial -in ${OPENCLAW_WEB_ADDRESS}.csr -out ${OPENCLAW_WEB_ADDRESS}.crt -days 36500

    cp ${OPENCLAW_WEB_ADDRESS}.crt ~/.openclaw/ssl/cert.pem
    cp ${OPENCLAW_WEB_ADDRESS}.key ~/.openclaw/ssl/cert.key
fi

exit 0