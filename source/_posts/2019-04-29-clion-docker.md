---
title: 使用 Clion 调试 Docker 内的 C++ 代码
date: 2019-04-29 22:37:46
categories:
 - C++Altar
tags:
 - C++
 - Clion
 - Docker
 - GDB
---

我们经常会遇到本地开发，但最终需要部署到服务器的情况。对于服务器部署，我们会选择使用 Docker 部署，但对于本地开发而言就略微有点不爽了。因为我们的本地环境（比如 Mac ）和 Docker 内的环境（一般是各种版本的 Linux）不一致，导致我们没办法很好地使用 IDE 的一些功能。

<!--more-->

这一点在 C++ 开发上显得尤为明显。本机的 Mac 环境和 Docker 内的环境很多头文件/库文件所在的路径和版本都不一致，导致在 Mac 下开发比较痛苦——IDE 基本沦为文本编辑器，无法编译/调试。好在 Clion 提供了 remote 模式，可以通过 ssh 的方式远程进入 Docker。这就相当于把 Clion 直接在 Docker 内环境进行编译/调试等操作，也能够正确进行代码跳转/提示。

## Docker 准备

一般而言我们会有一个 Docker 的编译环境镜像，我们需要对这个镜像进行一定的修改，使得其能对外提供 ssh 服务。不同的 Linux 系统略微有些差别， Dockerfile 大致需要以下内容，参考[这里](https://docs.docker.com/engine/examples/running_ssh_service/)

```Dockerfile
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:THE_PASSWORD_YOU_CREATED' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```
在执行 `docker run` 之后，能够直接通过 `ssh -p XXXX root@localhost` 进入就算大功告成。注意这里需要把 container 内的 22 端口映射到外部。

### 环境变量设定

还需要注意的一点是在 Dockerfile 内设定的环境变量，不会出现在 ssh 进入的环境里。具体原因在  [stackoverflow](https://stackoverflow.com/questions/34630571/docker-env-variables-not-set-while-log-via-shell) 里有说明，可以认为是 Docker 和 SSH 的特性。因此我们需要在 Dockerfile 里面加如下内容

~~~Dockerfile
RUN env | grep _ >> /etc/environment && env | grep PATH >> /etc/environment
~~~

### GDB 设定

为了能够在 Docker 内实现 GDB 功能，我们还需要一点设置，参考这个 [docker-compose.yml](https://github.com/shuhaoliu/docker-clion-dev/blob/master/docker-compose.yml)。

最终，我们的 Docker 启动命令如下

~~~bash
docker run -idt -p 7002:22 --security-opt seccomp=unconfined,apparmor=unconfined YOUR_ENV_IMAGE
~~~

## Clion 准备

Clion 这边的准备就比较容易了，都是一些点点的工作。在 Clion 的官网上有很详尽的[文档](https://www.jetbrains.com/help/clion/remote-development.html)，这里只简单说明一些注意事项

1. Clion 实际上是把本地的代码同步到 container 内进行编译
2. 有些时候本地的源码和 contianer 的源码可能不同步，需要手动 sync。甚至需要修改本地文件后再触发 sync

## 参考资料

[Dockerize an SSH service](https://docs.docker.com/engine/examples/running_ssh_service/)

[Debugging C++ in a Docker Container with CLion](https://github.com/shuhaoliu/docker-clion-dev)

[CLion Remote Development](https://www.jetbrains.com/help/clion/remote-development.html)

