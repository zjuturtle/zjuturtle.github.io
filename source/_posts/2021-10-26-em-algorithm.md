---
title: EM 算法
date: 2021-10-26 21:07:20
categories:
 - Algorithm
tags:
 - Algorithm
 - EM
---

EM 算法也是很经典的算法了，记录一下

<!--more-->

假设一个统计模型的可观测数据为 $X$，不可观测数据为 $Z$，同时有一个未知参数 $\theta$。我们有似然函数 $L(\theta;X,Z)=p(X,Z|\theta)$

那么对于未知参数的极大似然估计就是最大化其边缘似然函数如下

$$L(\theta;X)=p(X|\theta)=\int p(X,Z|\theta) dZ$$

然而，这个是很难进行直接计算的。因为 $Z$ 的维度可能很大，那么对它进行积分会是十分困难的。因此就可以引入 EM 算法

## E 步骤

根据参数的假设值，给出未知变量 $Z$ 的期望估计，应用于缺失值。这个解释起来有点拗口，似然函数的期望

$$Q(\theta|\theta^t)=E_{Z|X,\theta^t}[\log L(\theta;X,Z)]$$

## M 步骤

根据未知变量的估计值，给出当前的参数 $\theta$ 的极大似然估计。

$$\theta^{t+1}=\arg\max_{\theta} Q(\theta|\theta^t)$$
