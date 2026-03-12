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

    cp ${OPENCLAW_WEB_ADDRESS}.crt /root/.openclaw/ssl/cert.pem
    cp ${OPENCLAW_WEB_ADDRESS}.key /root/.openclaw/ssl/cert.key
fi

exit 0