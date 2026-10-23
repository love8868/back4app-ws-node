# Back4app Containers 部署包（VLESS+WS）

sing-box（VLESS+WebSocket）只监听容器 loopback，Caddy 在对外端口做明文 HTTP 门面；
TLS 由 Back4app 平台在边缘终结。与 Railway 版源包同构，已按 Back4app 惯例适配：
Dockerfile 用 `EXPOSE 8080` 声明路由端口、`ENV PORT=8080` 与 entrypoint 默认值对齐。

## 架构

```
客户端 --TLS(443)--> Back4app 边缘 --明文 HTTP/WS--> Caddy(:$PORT)
                                                        ├─ /healthz  → 200 "ok"（平台探活/自检）
                                                        ├─ $WS_PATH  → 反代 127.0.0.1:18080 (sing-box VLESS+WS)
                                                        └─ 其他路径  → 伪装静态页
```

## 部署步骤（Back4app Containers）

1. **建容器**：登录 Back4app → Containers → Create New App（免费层 0.25 CPU / 256MB 足够本包）。
2. **连 GitHub 仓库**：选择本仓库 `love8868/back4app-ws-node`（或你 fork 的副本），
   Root 目录指向仓库根（Dockerfile 在根目录），平台会自动按 Dockerfile 构建。
3. **设环境变量**（App Settings → Environment Variables）：
   | 变量 | 值 | 说明 |
   |---|---|---|
   | `UUID` | 随机 UUID（`sing-box generate uuid` 或在线生成） | 不设则每次启动随机生成、重启即失效，务必固定 |
   | `WS_PATH` | 随机路径，如 `/a1b2c3d4` | 默认 `/ws`，建议改随机 |
   | `SNI` | 先随便填，部署后改成平台子域名（见第 4 步） | 仅用于启动日志打印客户端链接，不影响运行 |
   | `PORT` | 不用设 | 默认 8080 且与 Dockerfile `EXPOSE` 一致；改了必须同步改 EXPOSE |
4. **部署后换 SNI**：部署成功后平台分配 `https://<app>.b4a.app` 子域名（以面板实际显示为准）。
   把环境变量 `SNI` 改成该完整子域名（去掉 `https://`），重新部署一次，
   然后在启动日志里直接抄现成的 `vless://` 客户端链接。
5. **验证**：浏览器开 `https://<app>.b4a.app/healthz` 应返回 `ok`；开根路径是伪装页。

## 客户端链接格式

```
vless://<UUID>@<app>.b4a.app:443?path=<WS_PATH>&security=tls&encryption=none&sni=<app>.b4a.app&type=ws#back4app-ws
```

或在本地生成订阅+二维码：

```bash
python3 make-sub.py <app>.b4a.app <UUID> <WS_PATH>
# 输出 vless.txt / sub.yaml(Clash) / sub.txt(base64) / qr.png
```

## 注意

- **免费 URL 会过期 + 休眠待实测**：面板明示 Free 层 "URL expires"（常开不过期是 $5/月 Starter 的卖点），
  具体过期期限、过期后是换域名还是停服、以及容器是否闲置休眠，都待真正部署后验证；
  若 URL 周期性变更，客户端链接需跟着换，本包只能当冷备，不能当常驻节点。
- 免费层流量 100GB/月，个人自用足够；内存 256MB 内 sing-box+Caddy 实测占用远低于上限。
- 个人自用、带 UUID 鉴权，不要做无认证开放代理或分发。
