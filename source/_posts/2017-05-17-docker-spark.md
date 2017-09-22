---
title: Docker 部署 Spark
date: 2017-05-17 16:22:09
categories:
 - TechChatter
tags:
 - Docker
 - Spark
---


公司需要一个离线的分析系统，我打算直接在阿里云上开N台按量付费的机子然后一起跑。整个系统打算使用 Docker、Spark 来搞。即在阿里云的机子上先搭一层 Docker ，然后在 Docker 的基础上搭建 Spark 的集群。

<!--more-->

## Docker

讲真 Docker 是好东西，拿来批量部署简直爽。

由于众所周知的原因，从国外网站拖东西是很慢的，需要一些梯子。Docker for Mac自带一个代理设置，不过这个代理简直了。我的 Surge 的 HTTP 代理默认挂在127.0.0.1上面，但是Docker总是搞不清楚127.0.0.1指的是自己还是指的本机。瞎几把折腾了一段时间姑且有了一个临时的解决方案。

参考[文档](https://docs.docker.com/docker-for-mac/networking/#there-is-no-docker0-bridge-on-macos)，Docker for mac 的实现有些不太一样，它的 host 其实是在 mac 上的一个虚拟机，而不是 mac 本身。理论上只要让 Docker 能分清楚自己（作为虚拟机的 host ）和本机的区别就可以，因此我做了以下操作：

* 将 Surge 的`HTTP_PROXY`设成一个不用的IP地址（比如10.200.10.1:6152），可能需要重启Surge
* sudo ifconfig lo0 alias 10.200.10.1
* 将 Docker 的代理设置为10.200.10.1:6152

这样 Docker 就会走10.200.10.1的代理，然后10.200.10.1是本机的别名，同时 Surge 的代理也是如此，因此解决了127.0.0.1的重名问题

唯一的遗留问题是如果真的有某个倒霉的设备IP地址是10.200.10.1。恩...这种事情一定不会发生的，对吧？

## Spark

我打算以一个 Ubuntu 的 images 为基础，在上面搭上环境，再 docker save 出来，不知道有没有更好的方法，不过先这么着吧。

其实 Docker 提供的 Ubuntu 镜像很小，也就意味着它毛都没有。因此需要自己动手装 python、gcc、make、vim 之类的软件（谢天谢地 apt 它还是有的）。

整一个 Dockerfile 如下，注意包里直接包含了 jdk 和 spark

~~~
FROM ubuntu:16.04
WORKDIR /app
ADD . /app
RUN mkdir local
RUN tar -zxf jdk-8u131-linux-x64.tar.gz && rm jdk-8u131-linux-x64.tar.gz && mv jdk1.8.0_131 local/jdk
RUN tar -zxf spark-2.1.0-bin-hadoop2.7.tgz && rm spark-2.1.0-bin-hadoop2.7.tgz && mv spark-2.1.0-bin-hadoop2.7 local/spark
RUN unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY
RUN apt-get update && apt-get install -y \
        python3 \
        gcc \
        make \
        vim
ENV JAVA_HOME=/app/local/jdk
ENV PATH $JAVA_HOME/bin:$PATH
ENV PYSPARK_PYTHON=python3
~~~

Spark 的 Master 启动脚本`start-master.sh`如下

~~~bash
#! /bin/bash
# start-master.sh

# start spark master
/app/local/spark/sbin/start-master.sh>/dev/null

# show log file
logFileList=($(find /app/local/spark/logs -name "*.out"))
if [ ${#logFileList[*]} -gt 1 ];then 
    echo '[WARN]logfile is not unique'
fi
if [ ${#logFileList[*]} -eq 0 ];then
    echo '[WARN]logfile not exits'
    exit 1
fi
logFile=${logFileList[0]}
tail -f ${logFile}
~~~

Spark 的 Slave 启动脚本`start-slave.sh`如下

~~~bash
#! /bin/bash
# start-slave.sh

# start spark master
/app/local/spark/sbin/start-slave.sh $1>/dev/null

# show log file
logFileList=($(find /app/local/spark/logs -name "*.out"))
if [ ${#logFileList[*]} -gt 1 ];then 
    echo '[WARN]logfile is not unique'
fi
if [ ${#logFileList[*]} -eq 0 ];then
    echo '[WARN]logfile not exits'
    exit 1
fi
logFile=${logFileList[0]}
tail -f ${logFile}
~~~

启动脚本的最后一行是`tail -f ${logFile}`，也就是说会把日志丢到 container 的 STDOUT 中。用`docker logs [containerID]`就可以查看日志啦

在 docker 下的启动命令：


~~~bash
docker run -d -p 8088:8088 -p 4040:4040 -p 7077:7077 -p 8080:8080 -p 6066:6066 --name=sparkMaster local/sparkcluster /app/start-master.sh
~~~

~~~bash
docker run -d --name=sparkSlave local/sparkcluster /app/start-slave.sh [IP:port]
~~~

## Docker 网络

其实关于 Docker 的 network 部分我捣鼓了好久，也没有什么特别好的解决方案。对于 Docker 而言，一个 container 可以根据 --network 参数指定它的 network 类型。默认情况下网络类型是 bridge，其余还有 host 和 none 两种。参照 Docker 的[文档](https://docs.docker.com/engine/reference/run/#network-settings)，理想情况下为了提升性能应该使用 host 模式，注意这里的措辞是 significantly.

> Compared to the default bridge mode, the host mode gives significantly better networking performance since it uses the host’s native networking stack whereas the bridge has to go through one level of virtualization through the docker daemon. It is recommended to run containers in this mode when their networking performance is critical, for example, a production Load Balancer or a High Performance Web Server.

但在我那高贵的 mac 上，指定 `network=host` 好像是不行的。详细的原因是 Docker for Mac 的 Docker 的 host 其实是在一个 HyperKit 虚拟机上，而不是直接在 mac 上。相当于mac上首先架设了一个虚拟机，再在这个虚拟机上运行了 docker ，也就是说这里指定的 host 其实相当于 HyperKit 虚拟机。关于这个问题，可以参考 github 上的 [issue1031](https://github.com/docker/for-mac/issues/1031) 和 [issue68](https://github.com/docker/for-mac/issues/68) 

不得已，只能使用默认的 bridge 模式。

## 部署

在我的本地 Mac 上，通过`docker run`可以直接跑起来，也能够访问`localhost:8080`看到 Spark 的控制面板。

讲道理的话，在阿里云的 ECS 集群上部署还是有点麻烦。因为国内网络的问题，Docker Store 是指望不上了。我的想法其实是把整个 export 出来的镜像放到 OSS 上，然后写一个脚本安装部署。

远程部署 python 脚本`deploy.py`，实际的使用中，填好 `config.json` 直接在本地跑就可以

设置样例`config.example.json`

~~~json
{
  "master":{"IP":"","password":""},
  "workers":[{"IP":"","password":""}],
  "end_point":"",
  "bucket_name":"",
  "access_key_id":"",
  "access_key_secret":"",
  "oss_docker_image_name":"sparkCluster.tar"
}
~~~

docker 部署脚本`deploy.py` ，注意该部署脚本使用了 threading 模块和 Event 来同时部署多台机器

~~~python
import paramiko
import json
import os
import threading

# 载入外部设置
with open('config.json', 'r') as f:
    config_data = json.load(f)
MASTER = config_data['master']
WORKERS = config_data['workers']
with open('config.json.tmp', 'w') as outfile:
    data = dict()
    data['end_point'] = config_data['end_point']
    data['bucket_name'] = config_data['bucket_name']
    data['access_key_id'] = config_data['access_key_id']
    data['access_key_secret'] = config_data['access_key_secret']
    data['oss_docker_image_name'] = config_data['oss_docker_image_name']
    json.dump(data, outfile)


def docker_spark_start(ip, password, name, run_cmd, event=None):
    with open('docker_install.sh') as fo:
        docker_install_cmd = fo.read().splitlines()
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=ip, port=22, username='root', password=password)
    sftp = ssh.open_sftp()
    sftp.put('get_docker_image.py', 'get_docker_image.py')

    sftp.put('config.json.tmp', 'config.json')
    for cmd in docker_install_cmd:
        stdin, stdout, stderr = ssh.exec_command(cmd)
        for line in iter(lambda: stdout.readline(2048), ""):
            print('[REMOTE-' + name + '][INFO]' + str(line), end='')
        for line in iter(lambda: stderr.readline(2048), ""):
            print('[REMOT-' + name + '][ERROR]' + str(line), end='')
    print('[INFO]'+name+' install docker spark finish')
    # 使用Event保证Master部署完毕才启动Slave
    if event is not None:
        event.wait()
    stdin, stdout, stderr = ssh.exec_command(run_cmd)
    for line in iter(lambda: stdout.readline(2048), ""):
        print('[REMOTE-' + name + '][INFO]' + str(line), end='')
    for line in iter(lambda: stderr.readline(2048), ""):
        print('[REMOTE-' + name + '][ERROR]' + str(line), end='')


def start_worker(current_worker, worker_index, master_addr, event):
    docker_spark_start(current_worker['IP'], current_worker['password'], 'WORKER-'+str(worker_index),
                       'docker run -d -p 8088:8088 -p 4040:4040 -p 7077:7077 -p 8080:8080 '
                       '-p 6066:6066 --name=sparkWorker' + str(worker_index) +
                       ' local/sparkcluster /app/start-slave.sh ' + master_addr,
                       event)


event = threading.Event()
index = 0
worker_threads = []
for worker in WORKERS:
    t = threading.Thread(target=start_worker, name='WORKER'+str(index),
                         args=(worker, index, MASTER['innerIP']+':7077', event))
    t.daemon = True
    t.start()
    worker_threads.append(t)
    index += 1
docker_spark_start(MASTER['IP'], MASTER['password'], 'MASTER',
                   'docker run -d -p 8088:8088 -p 4040:4040 -p 7077:7077 -p 8080:8080 '
                   '-p 6066:6066 --name=sparkMaster local/sparkcluster /app/start-master.sh')

event.set()
print('[INFO]Deploy spark master finish')

for t in worker_threads:
    t.join()
os.remove('config.json.tmp')
print('[INFO]Deploy spark workers finish')
~~~

docker 安装脚本`docker_install.sh`

~~~bash
#! /bin/bash
# docker_install.sh for ubuntu16.04
apt update
apt install python3 -y
apt install vim -y
apt install apt-transport-https -y
apt install ca-certificates -y
apt install curl -y
apt install software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install docker-ce -y
apt install python3 -y
apt install python3-pip -y
pip3 install --upgrade pip
pip3 install oss2
python3 get_docker_image.py
rm config.json
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
docker load --input dockerImage.tar
rm dockerImage.tar
rm get_docker_image.py 
~~~

镜像获取`get_docker_image.py`

~~~python
import oss2
import sys
import json

with open('config.json', 'r') as f:
    config_data = json.load(f)
OSS_END_POINT = config_data['end_point']
OSS_BUCKET_NAME = config_data['bucket_name']
OSS_ACCESS_ID = config_data['access_key_id']
OSS_ACCESS_SECRET = config_data['access_key_secret']
OSS_DOCKER_IMAGE_NAME = config_data['oss_docker_image_name']

print('start get docker image from oss')
sys.stdout.flush()
auth = oss2.Auth(OSS_ACCESS_ID, OSS_ACCESS_SECRET)
bucket = oss2.Bucket(auth, OSS_END_POINT, OSS_BUCKET_NAME)


def percentage(consumed_bytes, total_bytes):
    if total_bytes:
        rate = int(100 * (float(consumed_bytes) / float(total_bytes)))
        if percentage.last_rate != rate:
            print('{0}% -- {1:.1f}mb/{2:.1f}mb'.format(rate, consumed_bytes/1024/1024, total_bytes/1024/1024))
            sys.stdout.flush()
            percentage.last_rate = rate

percentage.last_rate = 0
bucket.get_object_to_file(OSS_DOCKER_IMAGE_NAME, 'dockerImage.tar', progress_callback=percentage)
~~~


## 总结

回头想想，似乎 docker 的使用也没有那么必要。只是装了一层皮，相对的部署环境会更加统一和无脑。唯一的麻烦就是为了保证最新版本，过段时间就要更新一下那个 spark 的 docker 镜像，同时 `docker_install.sh`脚本因为涉及到`apt install`命令，其实也需要常常查看有什么幺蛾子。

