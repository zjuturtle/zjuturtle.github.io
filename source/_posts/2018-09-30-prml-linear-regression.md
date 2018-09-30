---
title: PRML - 线性回归
date: 2018-09-30 11:38:31
categories:
 - Algorithm
tags:
 - PRML
 - 贝叶斯
---

这次记录一下线性回归相关的内容。

<!--more-->

## 基本模型

最简单的线性回归模型为

$$y(\boldsymbol{x},\boldsymbol{w})=w_0 +w_1x_1+...+w_Dx_D$$

一般来说，我们会套一个基函数 $\phi_j(x)$，这样能拟合的函数就多了

$$y(\boldsymbol{x},\boldsymbol{w})=w_0 + \sum_{j=1}^{M-1}w_j\phi_j(\boldsymbol{x})$$

这样这个回归模型就会有 $M$ 个参数，为了方便起见，我们会定义个 $\phi_0(\boldsymbol{x})=0$，然后就会变成

$$y(\boldsymbol{x},\boldsymbol{w})=\boldsymbol{w}^T \boldsymbol{\phi}(\mathbf{x})$$

这里 $\boldsymbol{w}=(w_0,...,w_{M-1})^T$，$\boldsymbol{\phi}=(\phi_0,...,\phi_{M-1})^T$

对于 $\boldsymbol{\phi}$，有很多种选择，比如可以选 $\phi_j(x)=x^j$，这样就变成了多项式拟合。又比如可以使用 $\phi_j(x)=\exp\{-\frac{(x-\mu_j)^2}{2s^2}\}$，就是高斯基函数。

## 极大似然法和最小平方

假设目标变量 $t$ 由确定的函数 $y(\boldsymbol{x},\boldsymbol{w})$ 加噪声给出，则

$$t=y(\boldsymbol{x},\boldsymbol{w})+\varepsilon$$

那么我们有

$$p(t|\boldsymbol{x},\boldsymbol{w},\beta)=\mathscr{N}(t|y(\boldsymbol{x},\boldsymbol{w}), {\beta}^{-1})$$

对于观测数据 $\boldsymbol{X}={x_1,...,x_N}$，其对应的目标值为 $\boldsymbol{t}={t_1,...,t_N}$，那么可以写出似然函数

$$p(\boldsymbol{t}|\boldsymbol{X},\boldsymbol{w},\beta)= \prod_{n=1}^{N} \mathscr{N}(t_n|w^T\boldsymbol{\phi}(x_n),{\beta}^{-1})$$

两边取对数（下面省略了 $x$）

$$\begin{split}\ln p(\boldsymbol{t}|\boldsymbol{w},\beta) &= \sum_{n=1}^{N} \ln \mathscr{N}(t_n|w^T \boldsymbol{\phi}(x_n),{\beta}^{-1}) \\
&= \frac N 2 \ln \beta- \frac N 2 \ln(2 \pi) -\beta E_D(\boldsymbol{w}) \\
E_D(\boldsymbol{w}) &= \frac 1 2 \sum^N_{n=1}\{t_n - \boldsymbol{w}^T \boldsymbol{\phi}(x_n)\}^2\end{split}$$

接下来就是对似然函数算梯度

$$ \nabla \ln p(\boldsymbol{t}|\boldsymbol{w},\beta) = \beta \sum_{n=1}^{N}\{t_n-\boldsymbol{w}^T \boldsymbol{\phi}(x_n) \} \boldsymbol{\phi}(x_n)^T $$

老规矩，将梯度设为 0，得到如下

$$0= \sum^N_{n=1}t_n \boldsymbol{\phi}(x_n)^T-\boldsymbol{w}^T\left(  \sum_{n=1}^N \boldsymbol{\phi}(x_n)\boldsymbol{\phi}(x_n)^T \right)$$

这样通过极大似然就有

$$\boldsymbol{w}_{ML}=(\boldsymbol{\Phi}^T\boldsymbol{\Phi})^{-1}\boldsymbol{\Phi}^T$$

其中的 $\boldsymbol{\Phi}$ 就是设计矩阵，定义如下

$$\boldsymbol{\Phi}= \begin {pmatrix} 
\phi_0(x_1) & \phi_1(x_1) & ... & \phi_{M-1}(x_1) \\
\phi_0(x_2) & \phi_1(x_2) & ... & \phi_{M-1}(x_2) \\
... & ...& \ddots &... \\
\phi_0(x_N) & \phi_1(x_N) & ... & \phi_{M-1}(x_N)
 \end{pmatrix}$$
 
 这里还引申出一个重要的量叫伪逆，某种意义上它可以看作是方阵的逆在非方阵上的推广。
 
 $$ \boldsymbol{\Phi}^{\dagger}=(\boldsymbol{\Phi}^T\boldsymbol{\Phi})^{-1}\boldsymbol{\Phi}^T $$

## 高斯变量的贝叶斯定理

这里略去证明直接给出定义。假定我们有高斯分布的边缘分布和条件分布如下

$$\begin{split}p(x)&=\mathscr{N}(x|\mu, \Lambda ^{-1})\\
p(y|x)&=\mathscr{N}(y|Ax+b,L^{-1})\end{split}$$

那么我们就有

$$\begin{split}p(y) &= \mathscr{N}(y|A\mu+b,L^{-1}+A\Lambda^{-1}A^T)\\
p(x|y) &= \mathscr{N}(x|\Sigma\{A^TL(y-b)+\Lambda \mu\},\Sigma)\end{split}$$

其中

$$\Sigma = (\Lambda+A^TLA)^{-1}$$

## 参数分布

接下来阐述参数分布。假设我们的先验分布如下

$$p(\boldsymbol{w})=\mathscr{N}(\boldsymbol{w}|,\boldsymbol{m}_0,\boldsymbol{S}_0)$$

我们的后验分布则为

$$p(\boldsymbol{w}|\boldsymbol{t})=\mathscr{N}(\boldsymbol{w}|\boldsymbol{m}_N,\boldsymbol{S}_N)$$

其中

$$\boldsymbol{m}_N=\boldsymbol{S}_N({\boldsymbol{S}_0}^{-1}\boldsymbol{m}_0+\beta \boldsymbol{\Phi}^T\boldsymbol{t})$$

$$\boldsymbol{S}_N^{-1}=\boldsymbol{S}_0^{-1}+\beta\boldsymbol{\Phi}^T\boldsymbol{\Phi}$$

## 预测分布

实际应用中，通常我们对新的 $x$ 值预测出的 $t$ 值感兴趣。这就需要计算预测分布(这里简略了输入量 $\boldsymbol{x}$)

$$p(t|\boldsymbol{t},\alpha,\beta)=\int p(\boldsymbol{w},\beta)p(\boldsymbol{w},\alpha, \beta)$$

，在线性模型下，其预测分布也是高斯的

$$p(t|\boldsymbol{x},\boldsymbol{t},\alpha,\beta) = \mathscr{N}(t|\boldsymbol{m}_N^T \boldsymbol{\phi}(\boldsymbol{x}), \sigma^2_N(\boldsymbol{x}))$$

其中

$$\sigma^2_N(\boldsymbol{x})=\frac 1 {\beta}+\phi(\boldsymbol{x})^T\boldsymbol{S}_N\boldsymbol{\phi}(x)$$

其中第一项表示了数据中的噪声，而第二项则反映了参数 $\boldsymbol{w}$ 关联的不确定性。

