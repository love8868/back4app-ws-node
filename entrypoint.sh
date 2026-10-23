#!/bin/sh
# 通用 WS 节点容器入口：sing-box(VLESS+WS) 跑在 loopback，Caddy 对外做门面
# Back4app Containers：平台按 Dockerfile EXPOSE(8080) 路由并终结 TLS，容器内明文 HTTP/WS
# 环境变量：
#   PORT     对外端口（默认 8080，须与 Dockerfile 的 EXPOSE 一致；平台注入时以注入为准）
#   UUID     VLESS 用户 UUID（不给则随机生成，见启动日志）
#   WS_PATH  WebSocket 路径（默认 /ws，建议部署时改成随机路径）
#   SNI      平台分配的公网域名（仅用于打印客户端链接，不影响运行）
set -e

PORT=${PORT:-8080}
UUID=${UUID:-$(sing-box generate uuid)}
WS_PATH=${WS_PATH:-/ws}
SNI=${SNI:-example.com}

# --- sing-box: VLESS + WS，只监听 loopback ---
cat > /etc/sing-box.json <<EOF
{
  "log": {"level": "info"},
  "inbounds": [
    {
      "type": "vless",
      "listen": "127.0.0.1",
      "listen_port": 18080,
      "users": [{"uuid": "$UUID"}],
      "transport": {"type": "ws", "path": "$WS_PATH"}
    }
  ],
  "outbounds": [{"type": "direct"}]
}
EOF

# --- Caddy 门面：/healthz 给平台健康检查，/ 返回伪装页，WS 路径反代 ---
mkdir -p /srv/www
cat > /srv/www/index.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>Welcome</title></head>
<body style="font-family:sans-serif;text-align:center;padding-top:10%">
<h1>It works!</h1><p>This is the default web page.</p>
</body></html>
HTML

cat > /etc/Caddyfile <<EOF
{
  admin off
}
:$PORT {
  handle /healthz {
    respond "ok" 200
  }
  handle ${WS_PATH}* {
    reverse_proxy 127.0.0.1:18080
  }
  handle {
    root * /srv/www
    file_server
  }
}
EOF

echo "=== VLESS+WS+TLS 客户端链接（把 SNI 换成平台实际域名）==="
echo "vless://${UUID}@${SNI}:443?path=${WS_PATH}&security=tls&encryption=none&sni=${SNI}&type=ws#ws-node"
echo "=== 内部参数（已写入日志，妥善保存）==="
echo "UUID=$UUID"
echo "WS_PATH=$WS_PATH"

sing-box run -c /etc/sing-box.json &
exec caddy run --config /etc/Caddyfile --adapter caddyfile
