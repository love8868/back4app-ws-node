#!/usr/bin/env python3
"""用法: python3 make-sub.py <域名> <UUID> <WS_PATH>
例:   python3 make-sub.py xxxx.b4a.app <UUID> /ws
输出同目录: vless.txt(单链接) sub.yaml(Clash订阅) sub.txt(base64订阅) qr.png(二维码,需 qrcode 库时)"""
import sys, base64, os
host, uuid, path = sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv)>3 else "/ws"
link = f"vless://{uuid}@{host}:443?path={path}&security=tls&encryption=none&sni={host}&type=ws#back4app-ws"
d = os.path.dirname(os.path.abspath(__file__))
open(os.path.join(d,"vless.txt"),"w").write(link+"\n")
yaml = f"""proxies:
  - name: back4app-ws
    type: vless
    server: {host}
    port: 443
    uuid: {uuid}
    udp: true
    tls: true
    servername: {host}
    network: ws
    ws-opts:
      path: {path}
      headers:
        Host: {host}
proxy-groups:
  - name: PROXY
    type: select
    proxies: [back4app-ws, DIRECT]
rules:
  - MATCH,PROXY
"""
open(os.path.join(d,"sub.yaml"),"w").write(yaml)
# 订阅(base64)版,部分客户端用
open(os.path.join(d,"sub.txt"),"w").write(base64.b64encode(link.encode()).decode()+"\n")
print(link)
try:
    import qrcode
    qrcode.make(link).save(os.path.join(d,"qr.png"))
    print("QR -> qr.png")
except ImportError:
    print("无 qrcode 库,跳过二维码(pip install qrcode pillow)")
