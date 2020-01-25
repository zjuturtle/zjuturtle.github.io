---
title: 使用 Intellij 调试 Docker 内的 Java 代码
date: 2020-01-25 18:57:09
categories:
 - TechChatter
tags:
 - Java
 - Intellij
 - Docker
---

上一次讲了 C++ 的，这一次因为遇到了 JNI 的需求，所以又有类似的需求。一般而言 Java 跨平台性很好，正常不需要远程调试，不过摊上了 JNI 就不太行了，C++ 总是有一些平台特有的库。实际上 Jetbrains 全家桶都支持 Docker 化的调试编译，我没有仔细去研究，但看上去像只是把 docker 的基本功能包装了一下，功能比较弱，基本的用处在于部署而不是调试。所以这里我还是使用 remote debug 的方式实现，这个方法不仅适用于 Docker 也可以适用于远程服务器。

<!--more-->

和 C++ 不同，java 自带远程调试功能。我个人写了一个小脚本负责编译运行，在 Intellij里面开 remote debug 等着。这样一运行脚本，java 程序就开始等待 attach remote debug。

## Docker 准备

Dockerfile 其实没啥好说的，没有特别需要修改的地方，记得将工程映射到 container 内部。可以直接 mount，也可以直接在 docker-compose.yml 文件里修改。

我倾向于使用 docker-compose.yml 文件。下面的 docker-compose.yml 文件将系统的当前目录映射至 container 内的 /app 目录下，方便源代码同步。在工程目录的根目录下运行 `docker-compose up -d` 就可以启动 docker 了。

```
services:
  buildEnv:
    image: java_environment_local:latest
    container_name: java_env
    volumes:
      - .:/app
```

## Intellij 设置

Intellij 打开工程后，需要增加一个运行选项。在运行的地方（右上角，锤子符号旁边）点下拉框，点击 Edit Configurations...，就可以进入到 Run/Debug Configuration。接着点击左上角的 + 号，增加一个 remote。

接下来的设置需要注意了。Debugger mode 我们选择Listen to remote JVM，host 填写 localhost 就可以，port 则选择 5005。这里的意思是我们的 Intellij 会监听 5005 端口，等待 remote jvm 来远程通知。连接的方向是 remote jvm 去连接 Intellij 的 debugger，所以这里是不需要在 docker 中额外开辟端口，只要不冲突就可以（冲突的话 Intellij 会提示 Address already in use）

然后下面的 Command line arguments for remote JVM 的内容需要拷贝出来

```bash
-agentlib:jdwp=transport=dt_socket,server=n,address=30.5.49.165:5015,suspend=y,onthrow=<FQ exception class name>,onuncaught=<y/n>
```

有两个地方需要注意，address 意思是 docker 内部的 java 程序启动的时候主动去连接的remote debugger 地址，这里需要填写本机的 IP而不是localhost。如果是 localhost 则会尝试去连接container 内部的 5005 端口；填写本机 IP, container 内部发起的程序才能主动连接到外部（即本机的 Intellij）。具体的可以参考我之前的博客[Docker 网络详解](https://zjuturtle.com/2017/11/22/docker-network/)

另外 onthrow=<FQ exception class name>,onuncaught=<y/n> 需要去掉，似乎没用，我没有仔细去调研这个。


## 编译/运行脚本

在工程的根目录下可以写一个简单的脚本，用于自动编译和运行

```bash
#!/bin/bash
javac [JAVA_FILE_LIST]
java -agentlib:jdwp=transport=dt_socket,server=n,address=30.5.49.165:5005,suspend=y -classpath [YOUR_JAVA_CLASS_PATH] [JAVA_PROGRAM_LIKE{com.example.xxx}]
```

脚本很简单，一行编译，一行运行。运行增加的参数就是上文中从 Intellij 里拷贝出来的。

## 调试

在调试的时候，先打开 Intellij，打上断点后点击右上角的虫子符号，再在 docker 内部运行刚刚的脚本。Java 程序运行的时候会自动去连接 30.5.49.165:5005 的 remote debugger，这样就能进入 debug 模式了。



