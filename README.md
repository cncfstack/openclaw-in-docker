# OpenClaw In Docker

OpenClaw In Docker 提供一个类似虚拟机的环境，一键运行 OpenClaw 服务，并提供安全的用户登录与 HTTPS 访问 OpenClaw 能力，使其可以便捷、安全的运行开放在互联网上。

OpenClaw In Docker 特点：

1. **隔离式类虚拟机运行环境**：基于 [csvm](https://github.com/cncfstack/csvm) 项目构建类虚拟机容器。系统内集成了 `systemd/docker/cron/sshd` 等独立服务，支持多服务运行、开机启动逻辑等功能。
1. **提供用户登录功能**：增强OpenClaw安全，内置基于 OpenResty + Lua 的认证层。所有用户请求均需经过登录验证，确保了 OpenClaw 控制面板的访问安全性。
1. **强制实施 HTTPS 访问**：系统默认预配置 OpenSSL 自签名证书，支持开箱即用的加密通信能力。
1. **OpenClaw源码构建+OpenResty代理**：基于最新的 OpenClaw 源码构建，并使用 OpenResty 代理。
1. **智能化套件工具**: 预集成 Chromium 浏览器与 Playwright 自动化框架，支持复杂的网页抓取、UI 自动化测试及无头浏览器任务流。


适合的场景：

1. 为保障宿主机安全，需要OpenClaw运行在隔离的 Docker 容器中场景。
1. 在服务器上进行7x24不停机运行OpenClaw场景。
1. 通过互联网访问Web页面进行配置管理和沟通交流场景（官方的默认不建议在网络上开放页面）。
1. 期望容器版本OpenClaw也能实现类似机器上运行的能力，如使用Docker沙箱、配置系统 Crontab 任务。（官方Docker方案不支持）


历史版本：

1. 镜像 Tag 详情与列表 [https://cncfstack.com/i/cncfstack/openclaw-in-docker](https://cncfstack.com/i/cncfstack/openclaw-in-docker)


## 快速开始

搭建OpenClaw只需要3步： 1.运行OpenClaw、2.获取令牌Token、3.设备审批。

### 1. 运行OpenClaw

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
  -v ./data/openclaw:/root/.openclaw \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:v2026.4.1-v0.2.2
```

运行成功后，访问 [https://localhost](https://localhost) 输入用户名 `openclaw` 和密码 `openclaw` 进行登录。

OpenClaw 网关连接 WebSocket URL 为 `wss://localhost`（注意是 `wss://`）。 

命令说明:

- `--privileged` 主要是在容器中又运行docker，需要挂载一些内核路径。（TODO：权限在逐渐梳理收缩中，目标是移除该参数）
- `--restart always` 设置该容器在 docker 启动时自动重启。可人工停止 `docker stop openclaw`。
- `-v openclaw-storage:/var ` 给容器内容 `/var` 目录单独挂载一个 Docker Volume，注意这里不是挂载目录，不要以 `./` 或 `/` 开头，docker会自动创建该名称的 Docker volume，可以通过 `docker volume` 命令管理。该选项也是为了解决容器内运行Docker的问题。
- `-v ./data/openclaw:/root/.openclaw` 这是 OpenClaw 运行的主要配置文件，可以根据需求自行修改。
- `OPENCLAW_WEB_URL`: 是指定 OpenClaw 的 Web 地址，用于登录，证书制作与配置，以及OpenClaw的 `allowedOrigins` 配置 。
- `OPENCLAW_WEB_URL`与`OPENCLAW_PASSWORD`: 是登录的账号密码，默认账号密码都是 `openclaw`

## 2. 获取令牌Token

OpenClaw 默认启动时会自动生成一个网关连接的Token，存在 OpenClaw 配置文件 `openclaw.json` 中。

可以通过如下命令获取 Token

```bash
docker exec -i openclaw-in-docker cat /root/.openclaw/openclaw.json |grep token|grep -v mode
```

或者

```bash
cat ./data/openclaw/openclaw.json |grep 'token'|grep -v mode
```


输出参考:

```
      "token": "f64687a164a25e5000xxxxxxxx58b3e488660001dc600c273"
```

## 3. 设备审批

在输入 Token 连接网关后。为保障安全，新的浏览器或电脑等客户端在访问 OpenClaw 时会收到如下提示

```bash
pairing required
此设备需要网关主机的配对批准。
openclaw devices list
openclaw devices approve <requestId>
在手机上？从桌面运行 openclaw dashboard --no-open 复制完整 URL（包括 #token=...）。
Docs: Device pairing
```

可以通过提示的命令进行审批（推荐）

也可以通过如下命令进行手动审批，该脚本会审批所有的设备，请确保你的 OpenClaw 是被可信的人访问。

```bash
docker exec -i openclaw-in-docker bash -- /usr/local/bin/openclaw-autoapprove-devices.sh
```


## OpenClaw 管理

### 镜像 Tag 版本的说明

镜像Tag格式如下 `vY.M.D-vx.y.z`

Tag 中  `vY.M.D` 是 OpenClaw 的版本号，`vx.y.z` 是指当前项目（OpenClaw-In-Docker）的版本号。

### 证书配置

OpenClaw In Docker 限制必须使用 HTTPS 访问，如果没有指定证书，默认会自签名证书使用。

对于有合法证书的域名，配置方法如下

1. 启动命令配置与证书匹配的域名 `-e OPENCLAW_WEB_URL="https://localhost" `
1. 将证书复制到挂载的目录的ssl目录下 `./data/openclaw/ssl/`，并且修改证书和私钥为固定名称 `cert.pem` 和 `cert.key`。
1. 重启容器 `docker restart openclaw-in-docker`

### OpenClaw命令

管理 OpenClaw 时，除了通过 Web UI，也可以通过命令行进行管理。

```bash
docker exec -it openclaw-in-docker /bin/bash
```

进入容器后就是 debian 的系统环境了，当前的路径 `/app` 是 OpenClaw 的源码。

配置文件在默认 `/root/.openclaw/` 路径

执行 `openclaw` 相关命令进行管理。


### 默认配置

**tools 配置**

当前项目是在容器内运行，安全性可控，tools 工具调用能力默认设置为 `full` 开放。

```json
    "tools": {
        "profile": "full"
    }
```


### 版本升级

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

在 `v0.1.2` 版本有个Bug，该bug会导致无法更换域名，只能使用 localhost 访问，这是因为 systemd 启动的进程使用的环境变量需要单独传入，无法直接使用系统的环境变量导致，该问题已经在 `v0.2.0+` 版本修复，请升级到 `v0.2.0+` 版本。

如果已经部署运行后，已经存在了 `openclaw.json` 配置文件了，可以在配置文件中添加一条 `allowedOrigins` 配置项，如：`https://new-domain.com:10443`

```bash
  -p 10443:443 -p 10080:80 \
  -e OPENCLAW_WEB_URL="https://localhost:10443" \
```

这会自动调整 openclaw.json 的配置

```json
  "gateway": {
    "controlUi": {
      "allowedOrigins": [
        "https://localhost:10443",
        "https://new-domain.com:10443"
      ]
    },
```

然后等待30秒左右，刷新页面 `https://localhost:10443`。或者重启openclaw或容器。

### 浏览器打开报错 TSTS ，没有继续访按钮

如果使用自签名证书在互联网上运行时，可能会收到如下提示。这是浏览器限制的

您必须手动清除浏览器的 HSTS 缓存：

- 在浏览器地址栏输入：chrome://net-internals/#hsts (Edge 浏览器也是这个地址)。
- 找到页面底部的 "Delete domain security policies"。
- 在输入框中输入您的域名：openclaw.cncfstack.com。
- 点击 "Delete" 按钮。 完成这一步后，重新访问网站即可生效。

## 联系方式

欢迎提交建议和沟通交流学习，通过邮件或添加微信交流：

**邮箱:**  <zhaowenyu@cncfstack.com>

**微信:**

![微信二维码](https://cncfstack.com/zhaowenyu-wx.png)