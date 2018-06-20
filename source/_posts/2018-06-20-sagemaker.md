---
title: sagemaker
date: 2018-06-20 20:00:12
categories:
 - Algorithm
tags: 
 - Docker
 - SageMaker
 - Machine Learning
 - Jupyter Notebook
---

早先的时候 AWS 给了一万美刀的抵价券，所以自然而然地机器学习就放在 AWS 上了。SageMaker 其实是去年出的，我个人的感觉是不太成熟，比如默认的情况下只支持 Python2.7 (截止2018.6.7)。但某种意义上比自己手动搭显卡配环境会好一点（主要是有优惠券2333）。

<!--more-->

## SageMaker 简介

SageMaker 使用了 S3 + Jupyter Notebook + Docker 这样一个技术组合。SageMaker 大致工作流程如下：

1. 上传训练数据到 S3
2. 在 AWS 提供的 Jupyter Notebook 上清洗数据，搭建/开发模型，也可以做一些小规模的测试
3. 通过 AWS 提供的接口或手动构建 Docker 训练镜像，提交给 AWS 的训练集群训练
4. 可以将训练后的模型直接部署在 AWS 上，用于生产环境

它的计算资源分为三类，且所有的计算资源都是按小时收费，可以[参考这里](https://amazonaws-china.com/cn/sagemaker/pricing/)

* 模型搭建 -- 用于运行 Jupyter Notebook
* 模型训练 -- 用于训练模型
* 模型托管 -- 用于模型部署

实际上 SageMaker 提供了 3 种训练方式。

1. 使用 SageMaker 预置的算法，只需要提供数据就可以了。
2. 调用 SageMaker 的 API 进行训练自定义的模型，需要提供一个实现特定 API 的 python 文件。
3. 用户自己提供包含自定义模型的训练镜像。

蛋碎的一点是前两种方法目前只支持 Python2.7，且支持的 tensorflow 的版本都比较低。所以我使用的第三种方法。

## 搭建训练环境

### 使用 Juypter Notebook 进行数据清洗

根据[文档指引](https://docs.aws.amazon.com/zh_cn/sagemaker/latest/dg/gs-setup-working-env.html)，我们首先需要新建一个 Jupyter Notebook 实例。在创建过程中，我们需要指定其可访问的 S3 bucket。这样 AWS 就会自动赋予 Jupyter Notebook 合适的 IAM 权限。

在创建完 Juypter Notebook 实例后，我们就可以正式开工了。不过在开始前我们可以看看 Jupyter Notebook 内部预置了哪些东西。

如果我们仅仅使用 Juypter Notebook 进行训练，那么直接将清洗后的数据放在 Juypter Notebook 里面就可以了。但如果我们需要 AWS 提供的训练服务，就还是需要将清洗完的数据推送回 S3 上。

### 上传数据到 S3

虽然 Juypter Notebook 也可以直接访问外网从外部获取数据，但还是建议专门建立一个 Bucket 用于 SageMaker。我的脑波数据加起来估计也就几百 Mb， 这一部分我是直接从阿里云上采集数据，并使用 pickle 序列化，再丢到 S3 上去的。可以在 Juypter Notebook 直接调用 SageMaker 的函数上传至 S3。其中 `data` 文件夹下为需要上传的数据（比如一个 pickle 序列化的 `output_dict` 文件）

~~~python
import sagemaker
sagemaker_session = sagemaker.Session()
inputs = sagemaker_session.upload_data(path='data', key_prefix='data/'+algorithm_name)
~~~

### 构建训练 Docker image

训练任务本质上是以 Docker image 的形式提交给 SageMaker 运算的，一般而言在正式提交到训练集群前，我们会希望使用小数据集验证训练的可行性。因此我们会将打包出来的 Docker image，先直接在 Jupyter Notebook 的环境下直接运行，没问题后再提交给 SageMaker 进行运算。整个过程可以参考[SageMaker 例程](https://github.com/awslabs/amazon-sagemaker-examples/blob/master/advanced_functionality/scikit_bring_your_own/scikit_bring_your_own.ipynb)。我编写的结构是这样的

~~~
├── test_dir
│   ├── input
│   │   └── data
│   │       └── training
│   │           └── output_dict
│   ├── model
│   └── output
├── build_and_push.sh
├── Dockerfile
├── train
├── train.py
└── train_local.sh
~~~

#### `test_dir`

`test_dir` 储存了用于本地训练（就是直接在 Jupter notebook 里面训练）的数据。`test_dir` 里面有一些复杂的文件夹结构，稍后解释。现在只需要知道 `test_dir` 内的内容提供了本地训练的数据。

#### build_and_push.sh

`build_and_push.sh` 是一个打包 Docker 镜像并将其推送到 ECR 的脚本。ECR 是 AWS 提供的[镜像托管服务](https://amazonaws-china.com/cn/ecs/?nc2=h_m1)。这个脚本由 SageMaker 提供

~~~bash
# build_and_push.sh
#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# The argument to this script is the image name. This will be used as the image on the local
# machine and combined with the account and region to form the repository name for ECR.
image=$1

if [ "$image" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi

chmod +x train

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi


# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)
region=${region:-us-west-2}


fullname="${account}.dkr.ecr.${region}.amazonaws.com/${image}:latest"

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --repository-names "${image}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${image}" > /dev/null
fi

# Get the login command from ECR and execute it directly
$(aws ecr get-login --region ${region} --no-include-email)

# Build the docker image locally with the image name and then push it to ECR
# with the full name.

docker build  -t ${image} .
docker tag ${image} ${fullname}

docker push ${fullname}
~~~

#### `Dockerfile`

这个文件定义了我们的训练镜像。

~~~dockerfile
FROM tensorflow/tensorflow:latest-py3
MAINTAINER zjuturtle
RUN pip3 install --no-cache-dir --upgrade numpy \
    h5py\
    py-cpuinfo\
    psutil\
    keras
COPY train /usr/src/app/
COPY train.py /usr/src/app/
WORKDIR /usr/src/app
ENTRYPOINT ["/bin/bash"]
~~~

注意

* 我们只把 `train` `train.py` 两个文件打入了镜像。
* 指定了 ENTRYPOINT，方便未来扩展参数（可以参考[上一篇博客](https://zjuturtle.com/2018/06/20/docker-run-cmd-entrypoint/)）

#### `train.py`

`train.py` 则提供了真正的训练代码（包括了模型定义）。

~~~python
import tensorflow as tf
import numpy as np
from tensorflow.python.client import device_lib
from keras.models import Sequential
from keras.layers import Dense, Flatten
from keras.layers import Conv1D, MaxPooling1D, Dropout, Activation, InputLayer, Flatten
import keras
import pickle
import os
import sys
import cpuinfo
import psutil


def print_info():
    print('')
    print('****************Hardware****************')
    print('cpu info: {}'.format(cpuinfo.get_cpu_info()['brand']))
    print('cpu cores: {}'.format(psutil.cpu_count()))
    print('physical memory: {:.2f} GB'.format(psutil.virtual_memory().total / 1024 / 1024 / 1024))
    print('')
    print('****************Software****************')
    print('python info: {}'.format(sys.version))
    print('tensorflow version: {}'.format(tf.__version__))
    print('tensorflow device info:')
    for device in device_lib.list_local_devices():
        print('    [name:' + device.name + ']')


def list_files(startpath):
    for root, dirs, files in os.walk(startpath):
        level = root.replace(startpath, '').count(os.sep)
        indent = ' ' * 4 * (level)
        print('{}{}/'.format(indent, os.path.basename(root)))
        subindent = ' ' * 4 * (level + 1)
        for f in files:
            print('{}{}'.format(subindent, f))


def load_data_from_s3():
    print('')
    print('***************Load Data***************')
    with open('/opt/ml/input/data/training/output_dict', 'rb') as f:
        return pickle.load(f)


def make_model():
    model = Sequential(name='mlp')
    model.add(InputLayer([2000]))
    model.add(Dense(1024, activation='tanh'))
    model.add(Dense(512, activation='tanh'))
    model.add(Dense(256, activation='tanh', ))
    model.add(Dense(64, activation='tanh', ))
    model.add(Dense(2, activation='softmax'))
    model.compile("adam", "categorical_crossentropy", metrics=["accuracy"])
    model.summary()
    return model


def normalize(x):
    for i in range(x.shape[0]):
        x[i] = x[i] / (np.sum(x[i]))
    return x


def train():
    # print_info()
    print('')
    print('**************Model Define**************')
    model = make_model()
    print('')
    print('*************Start training*************')
    data_dict = load_data_from_s3()
    x_train = data_dict['x_train']
    y_train_one_hot = data_dict['y_train2']
    x_test = data_dict['x_test']
    y_test_one_hot = data_dict['y_test2']
    
    model.fit(fft_x, y_train_one_hot, verbose=2, validation_data=(x_test, y_test_one_hot), epochs=100)

if __name__ == '__main__':
    train()
~~~

注意到这个模型的训练数据来自于 `/opt/ml/input/data/training/output_dict`。 这个和 `test_dir` 的层级十分类似。

#### `train`

`train` 仅仅是一个简单的脚本，这个的存在和 SageMaker 调用方式有关

~~~bash
python train.py
~~~

注意到我们在打包镜像的时候并没有包括训练数据，而在这里我们直接使用了 `/opt/ml/` 下的训练数据。实际上当 SageMaker 接收到我们提交的训练任务时，它干了以下两件事

* 将 S3 上的数据映射到 `/opt/ml/` 上
* 运行 `docker run train`

我们在之前的 Dockerfile 里面定义了 `ENTRYPOINT`，那么最终的运行指令就是 

~~~bash
/bin/bash train
~~~

即会通过运行 `train` 脚本来执行训练。

#### `train_local.sh`

用于本地训练测试

~~~bash
#!/bin/sh

image=$1

mkdir -p test_dir/model
mkdir -p test_dir/output
mkdir -p test_dir/input

rm test_dir/model/*
rm test_dir/output/*
rm -r test_dir/input/*
mkdir -p test_dir/input/data/training/

cp ../data/* test_dir/input/data/training/

docker run -v $(pwd)/test_dir:/opt/ml --rm ${image} train
~~~

这里需要注意的是最后一行

~~~bash
docker run -v $(pwd)/test_dir:/opt/ml --rm ${image} train
~~~

模拟了 SageMaker 的操作方式。SageMaker 在训练时会将 S3 上的数据映射到 `/opt/ml/input/data/training/`，直接本地训练我们将将`test_dir` 映射到 `/opt/ml` 下。

## 提交训练任务

在 Jupyter Notebook 的终端里运行下面的指令，打包训练镜像并推送到 ECR 上。

~~~bash
$ ./build_and_push.sh ${ALGORITHM_NAME}
~~~

在 Jupyter Notebook 的终端里运行下面的指令，测试训练镜像。

~~~bash
$ ./train_local.sh ${ALGORITHM_NAME}
~~~

在 Jupyter Notebook 内将训练任务提交到 SageMaker 进行训练。这里的 `inputs` 是之前通过 SageMaker 的 API 上传到 S3 的返回值。

~~~python
image = '{}.dkr.ecr.{}.amazonaws.com/{}:latest'.format(account, region, algorithm_name)
network = sage.estimator.Estimator(image,
                       role, 1, 'ml.m5.large',
                       output_path="s3://{}/output".format(sess.default_bucket()),
                       sagemaker_session=sess)
network.fit(inputs)
~~~


