# socat-proxy

Light container to proxy some remote host. UDP/TCP supported with port mapping.

Run it via docker-compose.yaml
```dockerfile
services:
  socat-proxy:
    image: piciuok/socat-proxy:latest
    container_name: socat-proxy
    restart: unless-stopped
    environment:
      TARGET_HOST: "1.2.3.4"
      TCP_PORT_MAP: "101:10001"
      UDP_PORT_MAP: "101:10001,102:10002"
    ports:
      - "9101:101/tcp"
      - "9101:101/udp"
      - "9102:102/udp"
```

or with docker run

```shell
docker run -d \
  --name socat_proxy \
  -e TARGET_HOST="1.2.3.4" \
  -e UDP_PORT_MAP="101:10001,102:10002" \
  -e TCP_PORT_MAP="101:10001" \
  -p 9101:101/tcp \
  -p 9101:101/udp \
  -p 9102:102/udp \
  piciuok/socat-proxy
```
