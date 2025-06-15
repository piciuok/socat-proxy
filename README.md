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

# Reolink NVR (RLN8, RLN16m RLN36 and other)
Mainly created to resolve issue with adding remote placed cameras to local NVR. Reolink NVR make cameras unique in system by IP address and suppose that added camera is within same network as NVR:  
First camera: 192.168.1.2  
Second camera: 192.168.1.3  
Thrid camera: 192.168.1.4

If you have remote camera you probably have one IP (public) for all cameras with forwarded port (9000 -> <your_port>) like:  
```
First camera: 1.2.3.4:10001 (local network IP 192.168.100.2:9000 in remote network)  
Second camera: 1.2.3.4:10002 (local network IP 192.168.100.3:9000 in remote network)  
Thrid camera: 1.2.3.4:10003 (local network IP 192.168.100.4:9000 in remote network)
```

For single camera there's no issue - you could add camera to NVR:  
```
Protocal: IP  
Address: 1.2.3.4  
Port: 10001  
User & Password: ...
```

If you have two or more camera you won't be able to add camera to NVR. If you add first camera to channel 01, that camera will be replaced with next camera from channel 02 and so on.
To solve that issue we could "map" remote ip + port to local IP address with help of Docker.

In my case I use Unraid 7.1.3 server but you should be able to do it with any configuration (on QNAP, Synology, TrueNAS and similar).

Firstly, check for free IP address in your local adress pool (by login to router).
Next check for networks in docker:

```shell
docker network ls
```
Search for macvlan or ipvlan network driver. Some familiarity with docker networks are required. [Check docs for Docker Networks](https://docs.docker.com/engine/network/drivers/)

```
root@Tower:~# docker network ls
NETWORK ID     NAME                    DRIVER    SCOPE
2ab2dc489bf9   br0                     macvlan   local
a3f368b01a54   bridge                  bridge    local
ff8ee2e6fd7b   host                    host      local
b8b5e8194678   none                    null      local
aa2072f18de5   proxy-network           bridge    local
```
In my case results was as above - Unraid has already created br0 network that could be used for that case so I choose that for next steps.

If you don't have such a network you could easily create one:

```shell
docker network create -d macvlan --subnet=<subnet_mask> --gateway=<gateway_ip> -o parent=<main_network_interface> <network_name>
```
for example:
```shell
docker network create -d macvlan --subnet=192.168.50.0/24 --gateway=192.168.50.1 -o parent=eth0 my_macvlan_network
```


Next, create docker service (I am using docker-compose). To above docker example add:
```
service:
  socat-proxy:
  ...
  networks:
    <your_bridged_network>:
      ipv4_address: <ip_address_to_assign>
    
networks:
  <your_bridged_network>:
    name: <your_bridged_network>
    external: true
```

For example my setup for single camera:

```
services:
  socat-proxy:
    image: piciuok/socat-proxy
    restart: unless-stopped
    command: ["1.2.3.4", "10501"]
    environment:
      TARGET_HOST: "1.2.3.4"
      TCP_PORT_MAP: "10501:10501"
      UDP_PORT_MAP: "10501:10501"
    ports:
      - "10501:10501/tcp"
      - "10501:10501/udp"
    networks:
      br0:
        ipv4_address: 192.168.50.201
  
networks:
  br0:
    external: true
    name: br0
```

I have three cameras so I created 3 services with mapped ports (10501, 10502, 10503) and assigned them to 3 local ip addresses (192.168.50.201, 192.168.50.202, 192.168.50.203).
Why 3 separated services instead of one with mapped all ports? Because you are able to assign only one IP address to container from one network (within same subnet configuration). It's possible to create 3 different networks in docker with different subnet (192.168.50.0/24, 192.168.51.0/24, 192.168.52.0/24...) but probably they will be inaccessible outside Docker.

Don't be scare about running multiple services for that because usage of RAM and CPU is very small: 0.1% of CPU and around 5-6MB per container.

Happy hacking!
