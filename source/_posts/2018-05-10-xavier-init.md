---
title: Xavier 初始化
date: 2018-05-10 14:55:53
categories:
 - Algorithm
tags: 
 - Machine Learning
 - Algorithm
---

最近在学习研究神经网络的时候，遇到一个 Xavier 初始化的问题，所以就做一个记录。

<!--more-->

## Xavier 由来

当我们在初始化网络的权重时，需要设置一个合理的随机值，避免出现 symmetry 的情况。一般我们会将其初始化为均值为 0 的随机分布（高斯或者均匀分布）。如果权重初始化过小(即选择的方差过小)，那么随着输入信号的改变，网络后端的改变也会过小。同样的，如果权重初始化过大，随着输入信号的改变，网络后端的改变则会过大。Xavier 方法提供了一个合理的方式来初始化权重。

简单来说，就是将一个神经元的初始值权重初始化为均值为0，方差为 $Var(w_i)=\frac 1 {n_{in}}$ 的随机分布（高斯或者均匀分布）。其中 $n_{in}$ 是该神经元的输入数目。

## Xavier 推导

我们不考虑激活函数（假设它不存在）。对于一个没有经过激活函数的神经元，它的输出为 $ y=\sum_{i=1}^{n_{in}}x_iw_i $。我们假设期望为 $E(x_i)=E(w_i)=0$，且各个变量互相独立，那么 $E(\sum_{i=1}^{n_{in}}x_iw_i)=0$。

因此我们可以写出方差的公式如下

$$\begin{split}Var(w_ix_i)&=[E(x_i)]^2 + [E(W_i)]^2 Var(x_i) + Var(w_i)Var(x_i) \\
&=Var(w_i)Var(x_i)\end{split}$$

假设 $wi,x_i$ 服从同一分布，那么可以得到

$$\begin{split} Var(y)&=Var(\sum_{i=1}^{n_{in}}x_iw_i) \\
&=n_{in}Var(w_i)Var(x_i) \end{split}$$

可以这么理解，对于一个神经元的输出（没有经过激活函数前），当其输入服从同一个分布时，其输出的方差为输入方差乘以输入数目。所以，如果我们希望其输出的方差同输入一致，便需要 $Var(w_i)= \frac 1 {n_{in}}$

## Xavier 变体

当使用反向传播时，同上，我们可以得到如果需要方差保持一致，需要

$$Var(w_i)= \frac 1 {n_{out}}$$

$n_{in}$ 代表输入数目，$n_{out}$ 代表输出数目。显然当且仅当 $n_{in}=n_{out}$ 时，才能保证正向和反向的方差一致。当二者不一致时，综合一下可以使用下式

$$Var(w_i) = \frac 2 {n_{in}+n_{out}}$$

在实践中，采用 $Var(w_i)= \frac 1 {n_{out}}$ 和 $Var(w_i) = \frac 2 {n_{in}+n_{out}}$ 都有，不同的神经网络库都不太一样。

## Xavier 延伸探讨

我感觉 Xavier 初始化还是用了很多“大胆”的假设。比如它没有考虑到激活函数的非线性，也假设了所有的输入都是服从同一分布。但在实践中，它的确有用，能让收敛速度加快。

实际上，我们假设了激活函数在输入为 0 附近时，其梯度为 1 。不过对于 ReLu 激活函数而言这就不成立了。因此对于使用 ReLu 激活函数，我们的初始化为

$$Var(w_i)=\frac 2 {n_{in}}$$

## 参考资料

* [Understanding the difficulty of training deep feedforward neural networks](http://proceedings.mlr.press/v9/glorot10a/glorot10a.pdf)
* [Andy's blog](http://andyljones.tumblr.com/post/110998971763/an-explanation-of-xavier-initialization)


