---
title: 使用 VSCode 调试远程服务器内的 docker
date: 2021-10-26 21:09:14
categories:
 - TechChatter
tags:
 - VSCode
 - Docker
---

通过 VSCode 的远程插件和 Docker 插件，我们就可以用它来调试服务端 Docker 内的程序啦。个人认为是蛮实用的，比直接对着 terminal 的黑框框用 vim 要强不少。

<!--more-->

## 准备工作

我是在 Mac 上测试的，Windows/Linux 应该差不多。首先需要安装 VSCode 和 Docker Desktop。对于 VSCode，还需要安装 [Docker 插件](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) 和 [Remote 插件](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)。不同的程序会需要不同的运行插件，比如 [C/C++ 插件](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)

## 设置

### Docker Host 设置

在默认情况下，VSCode 的 Docker 插件使用的是本地的 Docker Host。我们首先需要修改它的默认 Docker Host。打开 setting.json，增加以下json字段

```json
"docker.host": "ssh://[SERVER_USER_NAME]@[SERVER_ADDR]"
```

注意，这里的设置不支持用户名/密码方式登录，而只支持通过 SSH-key 的方式登录。因此需要在服务器端设置好 SSH，并在本地（Mac端）将私钥添加至 key-chain

```
$ ssh-add [YOUR_PRIVATE_KEY]
```

验证的方式也很简单，如果在 terminal 中执行 `ssh [SERVER_USER_NAME]@[SERVER_ADDR]` 能够直接登录服务器，便说明设置 OK了

### Attach Docker Container

我们可以在服务器上预先启动 container，一般可以执行以下命令 

```bash
$ docker run -itd -v /[PATH_IN_SERVER]:/[PATH_IN_CONTAINER] --name [CONTAINER_NAME] [IMAGE_NAME]
```

一般我们会将宿主机（远程服务器）上的某部分目录映射到 Docker 的 Container 内，这样子就可以比较方便地在宿主机和 Container 内交换文件。

回到 VSCode 中，如下图，我们可以看到在 Docker 侧栏中已经有了我们刚启动的 container，只要右击 container 并选择 Attach Visual Studio Code 就可以用 VSCode 进入 container 啦，记得要打开 container 内的目录。(PS. 第一次启动会需要一些时间)

{% asset_img vscode.png %}


### 设置 Run&Debug

在左边的 Run&Debug 侧栏选择新建一个 configuration（其实就是编辑 lauch.json）。根据自己的需要可以直接选择 C/C++ 的模版，然后编辑相关的设置。具体可以参考[文档](https://code.visualstudio.com/docs/editor/debugging)

Python 等其他语言同理。

## 参考资料

[VSCode Remote](https://code.visualstudio.com/docs/remote/remote-overview)
[VSCode Debugging](https://code.visualstudio.com/docs/editor/debugging)