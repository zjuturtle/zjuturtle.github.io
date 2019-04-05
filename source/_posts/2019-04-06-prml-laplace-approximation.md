---
title: PRML笔记 - Laplace Approximation
date: 2019-04-06 00:07:36
categories:
 - Algorithm
tags: 
 - PRML
 - Laplace Approximation
 - 概率分布函数
---

时隔近半年的更新来了（我是罪人）。其实已经写好了两篇，还有一篇讲核方法以及随笔写到一半），所以今天就一次性放出两篇博客。博客所依赖的库之类的也多半过时了，一并升级了下。

好了言归正传，PRML 里面介绍了一种糙但是管用的近似方法，称为 Laplace Approximation 。它可以用于近似条件概率的概率分布函数，可以说是一种很粗暴很简单的方法了。它仅适用于连续变量，用于近似的函数为高斯函数。

<!--more-->

## 简介

考虑单个变量 $w$，$D$ 是观察到的变量，$Z$ 是归一化变量

$$p(w|D)= \frac1Zp(w,D)=\frac1Zp(D|w)p(w)=\frac1Zf(w)$$

注意这里有

$$Z=\int p(w,D)\;dw=\int f(w)\;\mathrm{d}w$$

我们需要找到 $w_0$ 和 $A$ 使得

$$p(w|D) \approx N(w|w_0,A^{-1})$$

## 计算方法

首先找到一个 $f(w)$ 的极大值 $w_0$，有

$$\frac{\mathrm{d} f(w)}{\mathrm{d} w}=0$$

接下来对 $\ln f(w)$ 在 $w_0$ 附近进行二阶泰勒展开有

$$\ln f(w) \approx \ln f(w_0)+\frac12A{(w-w_0)}^2$$

其中

$$A=-\frac{d^2}{dw^2}\ln f(w)$$

然后将 $\ln$ 符号去掉，可以得到

$$f(w) \approx f(w_0)\exp{\left[\frac 12A(w-w_0)^2\right]}$$

$$p(w|D)\approx \frac1Zf(w_0)\exp{\left[\frac 12A(w-w_0)^2\right]}$$

注意到高斯分布的形式 $g(x)=\frac1{\sqrt{2 \pi \sigma}} \exp \left[-\frac{(x-\mu)^2}{2 {\sigma}^2} \right]$ 与 $p(w|D)$ 十分相似。可以作出如下近似（即 Laplace Approximation）

$$p(w|D) \approx N(w|w_0, A^{-1})$$

值得注意的是，我们并没有计算 $f(w_0)$ 或者 $Z$ 值本身，实际上我们仅通过 $f(w)$ 的指数项进行了近似。

## 多维推广

推广到多维的情况，我们有

$$\ln f(\mathbf{z}) \approx \ln f(\mathbf{z_0})-\frac12(\mathbf{z}-\mathbf{z_0})^T\mathbf{A}(\mathbf{z}-\mathbf{z_0})$$

其中

$$\mathbf{A}=-\nabla\nabla\ln f(\mathbf{z})|_{\mathbf{z}=\mathbf{z_0}}$$

那么就有

$$f(\mathbf{z}) \approx f(\mathbf{z_0})\exp{\left\{ -\frac12(\mathbf{z}-\mathbf{z_0})^T\mathbf{A}(\mathbf{z}-\mathbf{z_0})\right\}}$$

最后就有

$$q(\mathbf{z})=N(\mathbf{z}|\mathbf{z_0},\mathbf{A}^{-1})$$
