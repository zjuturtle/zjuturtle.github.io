---
title: Docker 网络详解
date: 2017-11-22 16:34:55
categories:
 - TechChatter
tags:
 - Docker
 - DNS
 - network
---

之前在尝试运行 Hyperledger fabric 的时候经常遇到节点互相连接不上的情况，后来仔细查了查应该是和 Mac 下面的 Surge 冲突了，导致 DNS 解析失败，peer 节点找不到。遂决定好好翻一下 Docker [网络部分的文档](https://docs.docker.com/engine/userguide/networking)，做一个基本的笔记。

<!--more-->

## 网络类型

### 默认网络类型

Docker 的默认网络类型分为 3 种

* bridge
* none
* host

stackoverflow 上[这个](https://stackoverflow.com/questions/41083328/what-is-the-use-of-host-and-none-network-in-docker)回答说的很好。bridge 网络是 Docker 默认使用的网络，可以允许 container 和外部网络以及其他 container 通讯。none 浅显的理解就是无网络，Docker 不会给 container 分配 IP，因此该模式不能和外部通讯，也不能和其他 container 通讯。host 指的是使用宿主机网络，这意味着 container 与宿主机间没有网络隔离，也没有了端口映射。

在 Docker 上，可以使用 `docker network ls` 来列出当前 Docker 的所有网络，用 `docker network inspect [network_name]` 来获得某个网络的详细信息。比较有意思的是 `inspect` 指令还列出了连接到该网络的 container。不指定网络的情况下，新的 container 使用的都是默认的 bridge 网络。

**注意：默认的 bridge 网络不支持服务自动发现，也就是说没有 container 名到 IP 的映射**

让我们做个简单实验。先跑两个 [busybox](https://busybox.net) 的 container 起来，并让他们都使用默认的 bridge 网络。

~~~bash
docker run -itd --name=c1 busybox
docker run -itd --name=c2 busybox
docker attach c1
~~~

注意到里面的 `-itd` 参数，其含义如下：

* i 保持 STDIN 打开
* t 分配一个 pseudo-tty
* d 使用 [Detached 模式](https://docs.docker.com/engine/reference/run/#detached--d)

现在可以认为进入到 container 中去了。两个 container 之间可以使用 IP 地址互相 ping(这里使两个 container 的 IP 是 172.17.0.2 和 172.17.0.3)，也可以直接 ping 外网（当然宿主机需要能联网）

~~~bash
ping 172.17.0.3
...
ping zjuturtle.com
...
ping c1 #bad access
~~~

**Tip: 可以通过 `CTRL+P CTRL+Q` 来退出 container的 pseudo-tty**
 
### 自定义网络类型

自定义的网络有以下三种：

* bridge network
* overlay network
* MACVLAN network

也可以通过 `network plugin` 和 `remote network` 的方式来完全自定义网络连接。这里只讲自定义的 bridge 网络。

bridge 网络应该是最常用的了，和默认的 bridge 网络类似，但有些许特性的不同。

还是动手试试。首先创建一个网络

~~~bash
docker network create --driver bridge isolated_nw
docker run --network=isolated_nw -itd --name=c3 busybox
docker run --network=isolated_nw -itd --name=c4 busybox
docker attach c3
~~~

注意此时就可以直接通过 container 的名字来直接通讯了，这其实是通过 Docker 内嵌的 DNS 服务器来实现的，该服务器的地址是 `127.0.0.11`。同时要注意到，不同的 network 之前是不能直接互通的，即这里的 isolated_nw 和默认的 bridge 网络是互相隔离的（所以可能会出现 c1 和 c3 同 IP 的情况）

~~~bash
ping c2
ping zjuturtle.com
~~~

当然，isolated_nw 可以通过暴露端口的方式与外部（包括宿主机上其他的网络，宿主机本体以及外部网络等）通讯。大致结构就像下图一样

{% asset_img network.png %}

## Docker 网络上的 DNS 

实际上，container 连接至 default bridge 和自定义网络的 DNS 查找是不一样的。

### default bridge 网络

这里涉及到 3 个文件 `/etc/hostname`，`/etc/hosts`，`/etc/resolv.conf`。我们首先来了解一下这 3 个文件在传统的 Linux 系统中各自的用处。

`/etc/hostname` 表示在 LAN（局域网）内的唯一主机名。

`/etc/hosts` 则和 DNS 有关。可以理解为本地提供了 IP 地址与 hostname 对应的服务。Linux 系统在向 DNS 服务器发出域名解析请求前会先在这个文件里面查找相应记录，如果有就会直接使用。

`/etc/resolv.conf` 是 DNS 解析的配置文件，它指明了需要域名解析时的设置。

Docker 中这 3 个文件不是直接写死在镜像中的，而是使用文件映射的方式虚拟出来的。这样的话，Docker 就可以很方便地修改各个 container 内的设置了。为了详细说明一下，我们进到上文的 c1 中看一下。

~~~bash
docker attach c1
cat /etc/hostname
cat /etc/hosts
cat /etc/resolv.conf
~~~

三个 cat 命令分别显示

~~~bash
deb392368e24
~~~

这个就是我们 c1 container 的名字啦

~~~bash
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.19.0.2	deb392368e24
~~~

暂时不管 ipv6 相关的内容，重要的其实只有一句 `127.0.0.1 localhost`

~~~bash
nameserver 127.0.0.11
options ndots:0
~~~

`nameserver 127.0.0.11` 说明了 c1 如果需要 DNS 解析的话，会去 `127.0.0.11` 询问。

`options ndots:0` 稍微有点麻烦，我查了一些资料。如果需要查找域名是相对域名，且该域名中包含的`.` 的数目大于或等于 `option ndots:${n} `命令指定的数，则查询的仅是该域名。否则会依次往传入的域名后追加 search 列表（search 列表在这里没有，详见[search](http://dns-learning.twnic.net.tw/bind/intro4.html)）中的后缀，直到解析出ip地址，或者解析完列表中所有后缀才会停止。这里设置成 0，意思就是对于传入的相对域名，只查询该域名。

之前说过在 default bridge 网络里面是不能通过 container 名互相 ping 的，其原因就是在该网络下的 DNS 服务器 `127.0.0.11` 没有它们的记录

~~~bash
nslookup c2 # not found
~~~

当然也有有方法能够实现在 default bridge 网络下 container 使用各自的名字互相通讯的。方法就是在 `docker run` 的时候添加 `--link=CONTAINER_NAME` 或者 `--link=ID:ALIAS` 参数。这个参数会在 `/etc/hosts` 添加解析信息。

~~~bash
docker run --link=c1 -itd --name=c5 busybox
docker run --link=7bf66d2fe5f5:cc1 -itd --name=c6 busybox
~~~

这样在 c5 里就可以 `ping c1`，在 c6 里就可以 `ping c1` 或者 `ping cc1`。不过反过来在 c1 里还是不能 `ping c5`

在 `docker run` 的时候还有一个参数值得注意 `--dns=IP_ADDRESS...`。这个参数会直接修改 `/etc/resolv.conf` 文件里 `nameserver` 的信息。

### 自定义网络的 DNS

自定义 Docker 网络与默认的 default bridge 网络一个重要区别是自定义的 Docker 网络上的 container 可以通过各自的名称直接通讯，但 default bridge 不行。这和自定义 Docker 网络上的 DNS 服务有关。在自定义 Docker 网络的 DNS 服务器 `127.0.0.11` 上是有 container 名字或 ID 和 IP 对应的信息。

~~~bash
docker attach c3
nslookup c4
nslookup [c4's container ID]
~~~

使用自定义的网络，也可以在 `docker run` 的时候指定 `--dns=IP_ADDRESS...` 参数。不过这里与默认的 default bridge 网络不一样，不会修改 container 里的 `/etc/resolv.conf` 文件。而是指定当内嵌的 DNS 服务器域名解析失败时使用的 DNS 服务器。

## Docker network 指令

具体的指令可以直接参考[官方文档](https://docs.docker.com/engine/reference/commandline/network/)

创建网络 `docker network create`

连接网络 `docker network connect`

断开网络 `docker network disconnect`

显示详细信息 `docker network inspect`

列出网络 `docker network list`

删除不用的网络 `docker network prune`

删除网络 `docker network rm`






