# 用 Docker 运行 Infinite-Canvas

本目录为 [hero8152/Infinite-Canvas](https://github.com/hero8152/Infinite-Canvas) 提供了一份
**最小可用的 Docker 配置**，把项目打包成容器，并**把所有用户数据持久化到宿主机**。

> 本 fork 仅新增了 Docker 相关文件（`Dockerfile` / `docker-compose.yml` / `.dockerignore` / 本文件），
> **未改动 `main.py` 源码**，因此后续同步上游非常干净。

## 文件说明

| 文件 | 作用 |
|------|------|
| `Dockerfile` | 基于 `python:3.11-slim`，只装 `requirements.txt` 里的 7 个轻量依赖（fastapi / uvicorn / requests / pydantic / python-multipart / httpx / pillow），**无 torch/tensorflow 等重 ML 库**。算力（如本地 ComfyUI）在你另一台机器上。 |
| `docker-compose.yml` | 映射 `3000:3000`，用 5 个 named volume 持久化数据，`restart: unless-stopped`。 |
| `.dockerignore` | 排除仓库里捆绑的便携 Python（`python/`）、离线包（`packages/`）、启动脚本，保持镜像干净。 |

## 快速开始

```bash
docker compose up -d --build
```

然后浏览器打开 `http://<宿主机IP>:3000`。

停止：`docker compose down`（数据不丢，named volumes 保留）。
彻底清理数据：`docker compose down -v`（⚠️ 会删除所有生成结果与画布）。

## 数据保存在哪（宿主机）

所有生成结果、画布、素材、工作流、API 密钥都在 Docker 的 named volumes 里：

```
ic-data      画布 / 对话 / 配置 JSON
ic-output    生成结果
ic-assets    素材库 / 上传 / 输入
ic-workflows ComfyUI 工作流
ic-api       API 密钥 (.env)
```

查看真实磁盘路径：

```bash
docker volume inspect infinite-canvas_ic-data
```

想改成**宿主机目录绑定**（直接落到某个文件夹，方便备份），把 `docker-compose.yml`
里对应的 named volume 改成 `./ic-data:/app/data` 等即可（文件里已给出示例注释）。

> 注：顶层的 `history.json`（生成历史日志）位于容器可写层，完整删除容器重建时会重置；
> 画布 / 素材 / 结果 / 工作流 / 密钥 这 5 类核心数据均已在 volume 中持久化。

## 同步上游更新

因为本分支只加了 Docker 文件、没碰 `main.py`，同步上游几乎零冲突：

```bash
git remote add upstream https://github.com/hero8152/Infinite-Canvas.git
git fetch upstream
git merge upstream/main        # 基本不会冲突
docker compose up -d --build   # 重建镜像，volume 里的数据不受影响
```

## 连接局域网 ComfyUI

在网页「设置 → ComfyUI」里填写你局域网地址（例如 `192.168.2.102:8188`）即可。
容器默认走 bridge 网络，可访问宿主机所在局域网，一般无需额外网络配置。

## ⚠️ 许可证提示

上游 LICENSE 为 restrict 协议：**禁止商业用途**；基于本代码二次开发**必须保持开源并注明作者**。
个人使用、公司内部使用均没有问题。
