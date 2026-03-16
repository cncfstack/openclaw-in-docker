# OpenClaw In Docker

OpenClaw In Docker 提供一个类似虚拟机的环境，一键运行 OpenClaw 服务，并提供安全的用户登录与 HTTPS 访问 OpenClaw 能力，使其可以便捷、安全的运行开放在互联网上。

OpenClaw In Docker 特点：

- **运行在一个类虚拟机的隔离容器中**：这个类虚拟机基于 [csvm](https://github.com/cncfstack/csvm) 项目，提供 systemd 系统服务。
- **用户登录功能**：基于OpenResty+Lua提供用户登录认证功能，用户登录成功后才能访问 OpenClaw 页面。
- **提供安全的 HTTPS 访问能力**：必须使用HTTPS访问，默认使用 OpenSSL 自签证书。
- **容器启动默认运行基础服务**：openclaw、openrestry、docker、cron、systemd、ssh 等。
- **容器默认安装的工具**: chromium playwright 等。

## 快速开始

在运行 OpenClaw 之前，请确保已经安装 Docker。国内用户可参考 [Docker资源库-部署升级](https://cncfstack.com/p/docker/docs/300.%E9%83%A8%E7%BD%B2%E5%8D%87%E7%BA%A7/) 安装Docker。

运行如下命令，拉取 OpenClaw 镜像并启动容器：

```bash
docker run -itd \
  --name openclaw-in-docker \
  --hostname openclaw-in-docker \
  --privileged \
  --restart always \
  -p 443:443 -p 80:80 \
  -v /lib/modules:/lib/modules:ro \
  -v openclaw-storage:/var \
  -v ./data/openclaw01:/root/.openclaw \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:v2026.3.13-1-v0.1.2
```

运行成功后，访问 [https://localhost](https://localhost) 输入用户名 `openclaw` 和密码 `openclaw` 进行登录。

OpenClaw 网关连接 WebSocket URL 为 `wss://localhost`（注意是 `wss://`）。 网关令牌位于挂载路径的 openclaw.json 配置文件文件中。令牌 Token 查询命令

```bash
cat ./data/rootopenclaw/openclaw.json |grep 'token'|grep -v mode

输出:
      "token": "f64687a164a25e500000000c658b3e488660001dc600c273"
```

命令说明:

- `--privileged` 主要是在容器中又运行docker，需要挂载一些内核路径。（TODO：权限在逐渐梳理收缩中，目标是移除该参数）
- `--restart always` 设置该容器在 docker 启动时自动重启。可人工停止 `docker stop openclaw`。
- `-v openclaw-storage:/var ` 给容器内容 `/var` 目录单独挂载一个 Docker Volume，注意这里不是挂载目录，不要以 `./` 或 `/` 开头，docker会自动创建该名称的 Docker volume，可以通过 `docker volume` 命令管理。该选项也是为了解决容器内运行Docker的问题。
- `-v ./data/rootopenclaw:/root/.openclaw` 这是 OpenClaw 运行的主要配置文件，可以根据需求自行修改。
- `OPENCLAW_WEB_URL`: 是指定 OpenClaw 的 Web 地址，用于登录，证书制作与配置，以及OpenClaw的 `allowedOrigins` 配置 。
- `OPENCLAW_WEB_URL`与`OPENCLAW_PASSWORD`: 是登录的账号密码，默认账号密码都是 `openclaw`

## 镜像 Tag 版本的说明

镜像Tag命令如下

```
registry.cncfstack.com/cncfstack/openclaw-in-docker:v2026.3.13-1-v0.1.2
```

镜像的 Tag 详情与列表 [https://cncfstack.com/i/cncfstack/openclaw-in-docker](https://cncfstack.com/i/cncfstack/openclaw-in-docker)

Tag 中  `v2026.3.13-1` 是 OpenClaw 的版本号，`v0.1.2` 是指当前项目（OpenClaw-In-Docker）的版本号。

## 证书配置

OpenClaw In Docker 限制必须使用 HTTPS 访问，如果没有指定证书，默认会自签名证书使用。

对于有合法证书的域名，配置方法如下

1. 启动命令配置与证书匹配的域名 `-e OPENCLAW_WEB_URL="https://localhost" `
1. 将证书复制到挂载的目录的ssl目录下 `./data/rootopenclaw/ssl/`，并且修改证书和私钥为固定名称 `cert.pem` 和 `cert.key`。
1. 重启容器 `docker restart openclaw-in-docker`

## OpenClaw 管理

管理 OpenClaw 时，除了通过 Web UI，也可以通过命令行进行管理。

```bash
docker exec -it openclaw-in-docker /bin/bash
```

进入容器后就是 debian 的系统环境了，当前的路径 `/app` 是 OpenClaw 的源码。

配置文件在默认 `/root/.openclaw/` 路径

执行 `openclaw` 相关命令进行管理。

## 设备审批

在输入 Token 连接网关后。

为保障安全，新的浏览器或电脑等客户端在访问 OpenClaw 时会收到如下提示

```
pairing required
此设备需要网关主机的配对批准。
openclaw devices list
openclaw devices approve <requestId>
在手机上？从桌面运行 openclaw dashboard --no-open 复制完整 URL（包括 #token=...）。
Docs: Device pairing
```

可以通过提示的命令进行审批（推荐）

页可以通过如下命令进行手动审批，该脚本会审批所有的设备，请确保你的 OpenClaw 是被可信的人访问。

```bash
docker exec -i openclaw-in-docker bash -- /usr/local/bin/openclaw-autoapprove-devices.sh
```

## 默认配置

**tools 配置**

当前项目是在容器内运行，安全性可控，tools 工具调用能力默认设置为 `full` 开放。

```json
    "tools": {
        "profile": "full"
    }
```


## 版本升级

版本升级之需要使用新版本镜像启动即可。

升级步骤：

```bash
docker stop openclaw-in-docker
docker rm openclaw-in-docker
docker run -itd \ ## 上文的运行命令，将镜像tag更新为新版本即可
```

## FAQ

### origin not allowed

**问题错误信息如下：**

```bash
origin not allowed (open the Control UI from the gateway host or allow it in gateway.controlUi.allowedOrigins)
```

**问题原因：**

在执行 `docker run` 命令时，运行的端口和浏览器的端口不一致。

```bash
  -p 10443:443 -p 10080:80 \
  -e OPENCLAW_WEB_URL="https://localhost:10443" \
```

这会自动调整 openclaw.json 的配置

```json
  "gateway": {
    "controlUi": {
      "allowedOrigins": [
        "https://localhost:10443"
      ]
    },
```

然后等待30秒左右，刷新页面 `https://localhost:10443`。或者重启openclaw或容器