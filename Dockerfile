FROM alpine:3.20

ARG SINGBOX_VERSION=v1.14.3
ARG CADDY_VERSION=v2.11.7

RUN apk add --no-cache ca-certificates gcompat && \
    wget -qO- https://github.com/SagerNet/sing-box/releases/download/${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION#v}-linux-amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box && \
    wget -qO- https://github.com/caddyserver/caddy/releases/download/${CADDY_VERSION}/caddy_${CADDY_VERSION#v}_linux_amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/caddy /usr/local/bin/caddy && \
    chmod +x /usr/local/bin/sing-box /usr/local/bin/caddy && \
    rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Back4app Containers 按 Dockerfile 的 EXPOSE 声明把公网流量路由到该端口，
# 并在平台侧终结 TLS（容器内只跑明文 HTTP/WS）。
# entrypoint.sh 的 PORT 默认值与此处保持一致（8080）；若平台注入 PORT 环境变量，
# entrypoint 会优先用注入值——改端口时 EXPOSE / ENV / PORT 三处须同步。
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
