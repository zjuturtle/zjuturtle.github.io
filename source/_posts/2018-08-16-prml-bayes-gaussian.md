---
title: PRML笔记 - 高斯分布的贝叶斯共轭先验
date: 2018-08-16 15:36:25
categories:
 - Algorithm
tags:
 - PRML
 - Bayes
 - Gaussian
---

这篇是关于贝叶斯的第三部分，讲讲高斯分布和贝叶斯先验的内容。

<!--more-->

## 方差已知均值未知

考虑一个一元高斯随机变量 $x$，假设方差 $\sigma^2$ 已知，我们需要从一组 $N$ 次的观测 $\mathsf{x}={x_1,...x_N}$ 中推断均值 $\mu$。那么它关于 $\mu$ 的似然函数如下

$$p(\mathsf{x}|\mu)=\frac{1}{(2 \pi \sigma^2)^{N/2}}\exp\{-\frac1{2 \sigma^2}\sum^N_{n=1}(x_n-\mu)^2\}$$

关于 $\mu$ 的共轭先验也是高斯分布

$$p(\mu)=\mathscr{N}(\mu | \mu_0,\sigma_0^2)$$

后验分布为

$$p(\mu|\mathsf{x}) \propto p(\mathsf{x}|\mu)p(\mu)$$

$$p(\mu|\mathsf{x}) = \mathscr{N}(\mu|\mu_N, \sigma_N^2)$$

$$ \begin{split} \mu_N&=\frac{\sigma^2}{N\sigma_0^2+\sigma^2} \mu_0 + \frac{N\sigma^2}{N\sigma_0^2+\sigma^2}\mu_{ML}  \\ \frac1{\sigma^2_N}&=\frac1{\sigma_0^2}+\frac{N}{\sigma^2} \end{split}$$

## 方差未知均值已知

现在我们假设均值已知，但需要估计模型的方差。为了方便计算，我们定义精度 $\lambda=1/{\sigma^2}$。那么似然函数为

$$p(\mathsf{x}|\lambda)=\prod^N_{n=1} \mathscr{N}(x_n|\mu,\lambda^{-1}) \propto \lambda^{\frac N 2}\exp{\{-\frac{\lambda}{2}\sum^N_{n=1}(x_n-\mu)^2 \}}$$

其对应的共轭先验为 Gamma 分布

$$Gam(\lambda|a,b)=\frac 1 {\Gamma(a)}b^a\lambda^{a-1}\exp(-b\lambda)$$

$$\Gamma(a)= \int^{\infty}_0{\mu}^{a-1}e^{-u}du$$

后验分布为

$$p(\lambda | \mathsf{x}) \propto \lambda^{a_0-1}\lambda^{\frac N 2}\exp\left\{-b_0\lambda-\frac{\lambda}{2}\sum^N_{n=1} (x_n-\mu)^2\right\}$$

可以看成是 Gamma 分布 $Gam(\lambda|a_N,b_N)$

$$\begin{split} a_N&=a_0+\frac N 2 \\b_N&=b_0+\frac 1 2 \sum^N_{n=1}(x_n-\mu)^2=b_0+\frac N 2 {\sigma}^2_{ML} \end{split}$$

## 方差均值均未知

如果方差和均值都不知道，那么似然函数对 $\mu$ 和 $\lambda$ 的依赖为

$$p(\mathsf{x}|\mu,\lambda)=\prod^N_{n=1} (\frac \lambda {2 \pi })^{\frac 1 2} \exp \left\{ -\frac{\lambda}{2}(x_n-\mu)^2 \right\}$$

$$\propto \left[ \lambda^{\frac 1 2} \exp \left(- \frac{\lambda {\mu}^2}{2} \right) \right]^N \exp \left\{ \lambda\mu \sum^N_{n=1}x_n-\frac{\lambda}{2} \sum^N_{n=1}x_n^2\right\}$$

共轭先验为

$$p(\mu,\lambda)= \mathscr{N} (\mu | {\mu}_0,(\beta \lambda)^{-1})Gam(\lambda|a,b)$$
