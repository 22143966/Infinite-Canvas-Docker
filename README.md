# Infinite-Canvas Docker（独立打包仓）

把 [hero8152/Infinite-Canvas](https://github.com/hero8152/Infinite-Canvas)（一个支持局域网 ComfyUI / 工作流导入 / 数据服务端落盘的 AI 画图工作台）打包成 Docker 镜像，并**每天自动构建上游最新代码**，推送到 GitHub Container Registry (GHCR)。

> 本仓库**不 fork** 上游。CI 每次直接拉取上游 `main` 当构建上下文，用本仓库维护的 `Dockerfile` / `docker-entrypoint.py` 打包。好处：永远是上游最新、零 merge 冲突、上游怎么改都不影响你。

## 目录结构

```
.
├── README.md
├── Dockerfile                 # 基于 python:3.11-slim，跑 main.py（非 root + 健康检查）
├── docker-entrypoint.py       # 运行时建目录、生成默认文件、history 软链、chown、降权
├── docker-compose.yml         # 3000 端口 + 5 个数据卷 + ComfyUI 寻址（env 驱动）
├── .dockerignore              # 排除便携 python/ 等，保证镜像干净
├── .env.example               # 端口 / 镜像名 / ComfyUI 地址 示例
└── .github/workflows/build.yml# 定时拉上游最新 → 构建 → 推 GHCR（amd64+arm64）
```

## 这个镜像做了什么（相对裸跑）

- **非 root 运行**：容器内用 `appuser` 跑服务，更安全。
- **健康检查**：每 30s 打 `/api/app-info`，异常自动标记 unhealthy。
- **目录与权限自动处理**：`docker-entrypoint.py` 在启动时创建 `API/ data/ assets/ output/ workflows/custom/`、生成 `history.json` / `global_config.json` 默认值，并把 `/app/history.json` 软链到**已挂载的** `/app/data/history.json`——所以**重建容器也不会丢历史**（解决了纯卷挂载下顶层 history.json 丢失的老问题）。
- **数据全部在宿主机**：`docker-data/` 下的 5 个目录对应容器 `/app` 下对应路径，画布 / 素材 / 生成结果 / 工作流 / 密钥都落盘，镜像本身无状态。
- **多平台镜像**：同时构建 `linux/amd64` 和 `linux/arm64`（可在 NAS / Mac / 树莓派类 ARM 机器跑）。

## 在你自己的仓库怎么用

1. **把这个仓库内容上传到你自己的 GitHub 仓库**（解压后整目录上传，或 `git init` 后 push）。
2. **（仅当你 fork 到别的账号时）改镜像名**：`docker-compose.yml` 里 `image:` 已写死本仓的 `ghcr.io/22143966/infinite-canvas-docker:latest`。若你 fork 到别的 owner，把这一行改成 `ghcr.io/<你的owner>/<你的仓库>:latest`（GHCR 命名空间必须和仓库所有者一致，否则推送报权限错）。
3. **开 Actions 写权限**：仓库 **Settings → Actions → General → Workflow permissions** 改 **Read and write permissions**。
4. **启用 workflow**：普通仓库默认启用；若没跑，去 **Actions** 标签页找 `Build & Push Infinite-Canvas` 点 **Enable workflow**。
5. **手动跑一次首构建**：Actions 里 **Run workflow**，等几分钟出镜像。
6. **（可选）GHCR 可见性**：镜像默认私有；想免登录拉取，去 GitHub **Packages** 把该镜像设为 **Public**。

## 部署（任意机器）

```bash
# 直接启动（从 GHCR 拉镜像，无需 .env、无需本地 build）
docker compose up -d

# 浏览器打开
#   http://<宿主机IP>:13200
```

首次启动会在当前目录生成 `docker-data/`，所有用户数据都在里面。

## 接局域网 ComfyUI

- ComfyUI 地址**在应用内配置**：打开网页后「设置 → ComfyUI」直接填可达地址即可，无需改 compose：
  - ComfyUI 在 **Docker 宿主机**上 → 填 `host.docker.internal:8188`
  - ComfyUI 在 **另一台 LAN 机器**上（如 `192.168.2.102:8188`）→ 直接填该 LAN IP
  - 注意：容器内 `127.0.0.1` 指的是容器自己，**别填** `127.0.0.1:8188`

## 同步上游 / 实时更新

- 本仓的 `build.yml` 每天 **北京时间 12:00** 自动 `checkout` 上游最新 `main` 重新构建并推送 `latest` + `sha-xxxx` 标签。
- 你部署机下次 `docker compose pull && docker compose up -d` 即拿到最新版；数据在 `docker-data/` 不受影响。
- 想立刻更新：去 Actions 手动 **Run workflow** 触发一次构建，再在部署机 `pull`。

## 许可证提示

上游 `hero8152/Infinite-Canvas` 为 restrictive 协议（禁止商用，二次开发须开源并注明作者，允许个人 / 公司自用）。本打包仓仅提供 Docker 构建配置，镜像内容版权归上游作者所有；公开推送镜像请保留署名与开源。
