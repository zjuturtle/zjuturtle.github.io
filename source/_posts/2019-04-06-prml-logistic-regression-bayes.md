---
title: PRML笔记 - Logistic Regression 的贝叶斯方法
date: 2019-04-06 00:14:20
categories:
 - Algorithm
tags: 
 - PRML
 - Logistic Regression
 - 贝叶斯方法
 - Bayes
---

实际上对于 Logistic Regression 也是可以应用贝叶斯方法的。但直接应用非常困难。因为在贝叶斯框架下计算后验概率，我们需要对其做归一化的操作。而在 Logistic Regression 中，假设我们有 N 个数据点，那么在似然函数中就会有 N 个 sigmoid 函数连乘。这在归一化时会很麻烦，基本告别解析计算。

<!--more-->

## 后验分布

因此，我们在 Logistic Regression 中使用贝叶斯框架时会使用一定的近似，这里以之前阐述的 Laplace Approximation 为例。首先我们有参数 $\mathbf{w}$ 的高斯先验分布

$$p(\mathbf{w})=N(\mathbf{w}|\mathbf{m_0},\mathbf{S_0})$$

我们可以写出后验分布如下

$$p(\mathbf{w}|\mathbf{t}) \propto p(\mathbf{w})p(\mathbf{t}|\mathbf{w})$$

其中，$\mathbf{t}=(t_1,...,t_N)^T$，即是训练数据的0-1正确标签，$p(\mathbf{t}|\mathbf{w})=\prod_{n=1}^Ny_n^{t_n}(1-y_n)^{1-t_n}$ 为似然函数，$y_n=\sigma(\mathbf{w}^T\phi_n)$。那么两边取对数有

$$\ln p(\mathbf{w}|\mathbf{t})=-\frac12(\mathbf{w}-\mathbf{m_0})^T\mathbf{S_0}^{-1}(\mathbf{w}-\mathbf{m_0})+\sum_{n=1}^{N}\left[t_n \ln y_n+(1-t_n)\ln(1-y_n) \right]+const$$

对 $p(\mathbf{w}|\mathbf{t})$ 使用 Laplace Approximation。首先我们对 $p(\mathbf{w}|\mathbf{t})$ 使用极大似然法，取其梯度为 0 的地方得到 $\mathbf{w_{MAP}}$，作为 Laplace Approximation 的均值。同时根据公式我们可以得到 Laplace Approximation 的方差为

$$\mathbf{S_N}=-\nabla \nabla \ln p(\mathbf{w}|\mathbf{t})=\mathbf{S_0}^{-1}+\sum_{n=1}^Ny_n(1-y_n)\phi_n\phi_n^T$$

所以使用 Laplace Approximation 近似得到的结果为

$$p(\mathbf{w}|\mathbf{t}) \approx q(\mathbf{w})=\mathcal{N}(\mathbf{w}|\mathbf{w_{MAP}},\mathbf{S_N})$$

## 预测分布

当然我们仅有  $q(\mathbf{w})$ 是不够的，我们更感兴趣的是类别的预测分布。给定一个特征向量 $\phi(x)$，它的预测分布如下

$$p(C_1|\phi, \mathbf{t})=\int p(C_1|\phi,w)p(w|\mathbf{t}) \mathrm{d} \mathbf{w} \approx \int \sigma(\mathbf{w}^T \phi)q(\mathbf{w})\ \mathrm{d} \mathbf{w}$$

对于二分类问题， $p(C_2|\phi, \mathbf{t})=1- p(C_1|\phi, \mathbf{t})$。为了计算预测分布，我们首先注意到函数 $\sigma(\mathbf{w}^T\phi)$ 对于 $\mathbf{w}$ 的依赖只通过它在 $\phi$ 上的投影实现。为了简便，我们记 $a=\mathbf{w}^T \phi$，然后改写如下

$$\sigma(\mathbf{w}^T \phi)=\int \delta(a-\mathbf{w}^T\phi)\sigma(a)\ \mathrm{d}a $$

我们记$\delta(.)$ 为 delta 函数，即只在 0 处为非零值，且在整个实数域上的积分为1。对于 $p(a)$ ，我们可以认为 delta 函数给 $\mathbf{w}$ 施加了一个线性限制，因此在所有与 $\phi$ 正交的方向上积分，就得到了联合概率分布 $q(\mathbf{w})$ 的边缘分布。（没理解Orz）

$$p(a)=\int \delta(a-\mathbf{w}^T \phi)q(\mathbf{w})\ \mathrm{d}\mathbf{w}$$

则有

$$\int\sigma(\mathbf{w}^T\phi)q(\mathbf{w})\mathrm{d}\mathbf{w}=\int\sigma(a)p(a)\ \mathrm{d}a$$

显然（显然个屁，不懂） $a$ 也是满足高斯分布的，我们有

$$ \mu_a=\int p(a)a\ \mathrm{d}a=\int q(\mathbf{w}) \mathbf{w}^T \phi\ \mathrm{d} \mathbf{w}= \mathbf{w}^T_{MAP}\phi $$

$$\begin{aligned} \sigma_a^2&=\mathrm{var}[a]=\int p(a)\{a^2-\mu_a^2\}\ \mathrm{d}a \\
&= \phi^T  \mathbf{S_N}\phi\end{aligned}$$

所以最后就是

$$p(C_1|\mathbf{t})=\int \sigma(a) p(a)\ \mathrm{d}a=\int\sigma(a)\mathcal{N}(a|\mu_a,\sigma_a^2)\ \mathrm{d}a$$

