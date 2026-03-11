# OpenClaw In Docker

OpenClaw In Docker 提供一个类似虚拟机的环境运行 OpenClaw ，并提供安全的用户登录与 HTTPS 访问能力，使其可以安全的部署开放在互联网上。

OpenClaw In Docker 特点：

- **运行在一个类虚拟机的隔离容器中**：这个类虚拟机基于 [csvm](https://github.com/csvm/csvm) 项目，提供 systemd 系统服务。
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
  -v /lib/modules:/lib/modules:ro \
  -v openclaw-storage:/var \
  -v ./data/rootopenclaw:/root/.openclaw \
  -p 443:443 \
  -p 10022:22 \
  -e OPENCLAW_WEB_URL="https://localhost" \
  -e OPENCLAW_USER="openclaw" \
  -e OPENCLAW_PASSWORD="openclaw" \
  registry.cncfstack.com/cncfstack/openclaw-in-docker:v0.1.0_v2026.3.2
```

运行成功后，访问 [https://localhost](https://localhost),输入用户名 `openclaw` 和密码 `openclaw` 进行登录。

OpenClaw 网关连接 WebSocket URL 为 `wss://localhost`（注意是 `wss://`）。 网关令牌位于挂载路径的 openclaw.json 配置文件文件中。令牌 Token 查询命令

```bash
cat ./data/rootopenclaw/openclaw.json |grep 'token'|grep -v mode
      "token": "f64687a164a25e500000000c658b3e488660001dc600c273"
```

命令说明:

- `--privileged` 主要是在容器中又运行docker，需要挂载一些一些内核路径。（TODO：权限在逐渐梳理收缩中，目标是移除该参数）
- `-v openclaw-storage:/var ` 给容器内容 `/var` 目录单独挂载一个 Docker Volume，注意这里不是挂载目录。该选项也是为了解决容器内运行Docker的问题。
- `-v ./data/rootopenclaw2:/root/.openclaw` 这是 OpenClaw 运行的主要配置文件，可以根据需求自行修改。
- `OPENCLAW_WEB_URL`: 是指定 OpenClaw 的 Web 地址，用于登录，证书制作与验证，以及OpenClaw的 `allowedOrigins` 配置 。
- `OPENCLAW_WEB_URL`与`OPENCLAW_PASSWORD`: 是登录的账号密码，默认账号密码都是 `openclaw`

关于镜像 Tag 版本的说明:

镜像Tag命令如下

```
registry.cncfstack.com/cncfstack/openclaw-in-docker:v0.1.0_v2026.3.2
```

镜像的 Tag 详情与列表 [https://cncfstack.com/i/cncfstack/openclaw-in-docker](https://cncfstack.com/i/cncfstack/openclaw-in-docker)

Tag 中 `v0.1.0` 是指当前项目的版本号， `v2026.3.2` 是 OpenClaw 的版本号。