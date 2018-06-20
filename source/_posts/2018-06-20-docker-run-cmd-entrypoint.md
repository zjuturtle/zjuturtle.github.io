---
title: Docker 中 RUN/CMD/ENTRYPOINT 详解
date: 2018-06-20 17:42:37
categories:
 - TechChatter
tags: 
 - Docker
 - Linux
---

又有一段时间没有写博客了。这一次我在 AWS 的 SageMaker 上去部署训练算法。SageMaker 的 train 和 host 都是在容器内实现的。我个人认为训练的任务放在容器里执行还是很科学的。在较低配置的机器上启动 Juypter Notebook 用于开发，然后在较高配置的集群上使用 Docker 训练算法，计算资源不闲置，用户也省钱。

本文参(chao)考(xi)了 [Docker — 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/)

<!--more-->

## RUN 指令

这个指令用于构建镜像，其实是在 `Dockerfile` 里面执行命令行命令。有两种写法

* shell 格式 `RUN <COMMAND>`。例如

~~~docker
RUN apt-get update
~~~

* exec 格式 `RUN ["executable", "param1", "param2"]`。例如

~~~docker
RUN ["apt-get", "update"]
~~~

但要注意，我们最好将命令写在同一个 `RUN` 命令里面，否则会造成镜像臃肿（因为每运行一次 `RUN` 就会新建一层）。

所以最好这么写

~~~docker
RUN buildDeps='gcc libc6-dev make' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps
~~~

`RUN` 指令在容器构建过程中起作用，和容器的运行无关。

## CMD 指令

`CMD` 指令用于指定默认的容器主建成的启动命令。在一个镜像里面仅有一个 `CMD` 指令会起作用。比如下面这个 Dockerfile

~~~docker
FROM ubuntu:16.04
CMD ["echo", "first"]
CMD ["echo", "second"]
~~~

第一个 `CMD` 指令会被忽略。如果运行这个 image，只会输出 `second`

~~~bash
$ docker build -t test .
$ docker run test
# echo second
second
~~~

## ENTRYPOINT 指令

如果我们需要在容器运行时传一些参数，就需要 `ENTRYPOINT` 指令了。当存在 `ENTRYPOINT` 时，`CMD` 的含义就发生了改变，不再是直接的运行其命令，而是将 `CMD` 的内容作为参数传给 `ENTRYPOINT` 指令，换句话说实际执行时，将变为 

~~~bash
<ENTRYPOINT> "<CMD>"
~~~

举个栗子，下面这个镜像可以得知当前的公网 IP。

~~~docker
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
CMD [ "curl", "-s", "http://ip.cn" ]
~~~

我们可以直接运行

~~~bash
$ docker build -t myip .
$ docker run myip
## 显示当前 IP ##
~~~

但如果我们希望显示 HTTP 头信息，就需要加上 `-i` 参数。但我们不可以直接加 `-i` 参数给 `docker run myip` 。因为 `docker run myip -i` 实际上会用 `-i` 来覆盖原有的默认 `CMD` 命令 `curl -s http://ip.cn`，而 `-i` 完全不是个命令。因此我们只能这么用

~~~bash
$ docker run myip curl -s http://ip.cn -i
~~~

很蠢，所以 `ENTRYPOINT` 指令就派上用场了。现在我们将 Dockerfile 改写如下

~~~docker
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
ENTRYPOINT [ "curl", "-s", "http://ip.cn" ]
~~~

这样，当我们运行 `docker run myip -i` 时， `CMD` 命令为 `-i`。再加上 `ENTRYPOINT`，本质上执行的命令就变成了 `curl -s http://ip.cn -i`


P.S. 上面栗子来自[Docker — 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/image/dockerfile/entrypoint.html)

## 总结

* 使用 RUN 指令安装应用和软件包，构建镜像。
* 如果 Docker 镜像的用途是运行应用程序或服务，比如运行一个 MySQL，应该优先使用 Exec 格式的 ENTRYPOINT 指令。CMD 可为 ENTRYPOINT 提供额外的默认参数，同时可利用 docker run 命令行替换默认参数。
* 如果想为容器设置默认的启动命令，可使用 CMD 指令。用户可在 docker run 命令行中替换此默认命令。




