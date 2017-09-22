---
title: 服务器登录管理
date: 2017-07-12 16:03:22
categories:
- TechChatter
tags:
- Linux
---


讲道理之前还积压着好多篇博客没有写，今天写点小东西糊弄一下= =

现在手头上需要管理的服务器有点多，每次登陆的时候都需要输入密码。然后就想用 ssh key 的方式来登陆。针对每一个服务器，都生成一对公钥私钥对。

<!--more-->

## 生成公钥和私钥

在 mac 或者 linux 系统下

~~~sh
ssh-keygen -t rsa -b 4096
~~~

`-t rsa `加密方式为`RSA`方法， `-b 4096`代表加密位数为4096位

之后会要求输入生成的文件名称，假设为 zjuturtle_rsa 。同时并不需要 passphrase

然后就会生成私钥 zjuturtle_rsa 和对应的公钥 zjuturtle_rsa.pub。注意放在 ~/.ssh 文件夹下

## 上传公钥

在本机执行以下命令

~~~sh
cat ~/.ssh/zjuturtle_rsa.pub | ssh user@host "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
~~~

## 设置本地 Host

在 `~/.ssh` 文件夹下，应该有一个 `config` 文件。添加以下内容，能让 ssh 登录更加便捷

~~~
Host turtle
    HostName zjuturtle.com
    User turtle
    IdentityFile ~/.ssh/zjuturtle_rsa
~~~

这样在命令行里，运行 `ssh turtle` 就可以直接登录啦~



