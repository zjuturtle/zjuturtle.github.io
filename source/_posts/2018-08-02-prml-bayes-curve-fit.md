---
title: PRML笔记 - 贝叶斯多项式曲线拟合
date: 2018-08-02 14:57:13
categories:
 - Algorithm
tags: 
 - PRML
 - 曲线拟合
 - 贝叶斯
---

整本 PRML 翻来覆去地讲贝叶斯思想。这里做一些与贝叶斯有关的内容的笔记。本来是做成一篇博客的，但奈何实在太长，分为3个部分来发。今天先讲贝叶斯多项式曲线拟合。

<!--more-->

## 贝叶斯概率

我们先通过一个简单的推导得到贝叶斯公式。假设有联合分布 $P(X,Y)$，我们容易有$P(X,Y)=P(X|Y)P(Y)=P(Y|X)P(X)$。因此可以推断得到贝叶斯公式如下

$$P(Y|X)=\frac{P(X|Y)P(Y)}{P(X)}$$

以上这个公式就是一切的~~万恶之源~~基石，接下来我们看看基于这个公式都能干些啥。

## 贝叶斯多项式曲线拟合

我们考虑一个多项式拟合问题。假设我们的模型为 $y(x, \boldsymbol{w})=\sum_{j=0}^{M}w_jx^j$ 。 $M$ 为多项式阶数，多项式系数 $w_0,...,w_M$ 整体记为 $\boldsymbol{w}$。假设我们有 $N$ 个带噪声的观测数据 $\boldsymbol{D}=\{t_1, ..., t_N\}$，其对应的输入为$\boldsymbol{X}=\{x_1,...,x_N\}$。我们最终需要求的是多项式系数 $\boldsymbol{w}$。

注意到贝叶斯定理可以将观测到的数据融合，来把先验概率转化为后验概率。根据贝叶斯公式，我们有

$$ p(\boldsymbol{w} | \boldsymbol{D}) = \frac{p(\boldsymbol{D} | \boldsymbol{w})p(\boldsymbol{w})}{p(\boldsymbol{D})}$$

解释一下公式里各项的含义
* $p(\boldsymbol{D})$ 即为后验概率。
* $p(\boldsymbol{w})$ 为先验概率，包含了在观测到数据前关于 $\boldsymbol{w}$ 的一些假设。
* $p(\boldsymbol{D} | \boldsymbol{w})$ 由观测数据集 $\boldsymbol{D}$，可以认为是 $\boldsymbol{w}$ 的函数，也被称为似然函数。表达了在不同 $\boldsymbol{w}$ 下，观测数据出现的可能性大小。注意它不是 $\boldsymbol{w}$ 的概率分布，因此它关于 $\boldsymbol{w}$ 的积分一般不为 1
* $p(\boldsymbol{D})$ 可以认为是一个归一化系数，确保公式右侧的积分为 1

用自然语言来表述就是：后验概率正比于似然函数与先验概率的乘积。这三者都可以认为是 $\boldsymbol{w}$ 的函数。实际上对上面公式做关于 $\boldsymbol{w}$ 的积分，我们就可以求得 $p(\boldsymbol{D})$

$$p(\boldsymbol{D}) = \int p(\boldsymbol{D} | \boldsymbol{w})p(\boldsymbol{w})d\boldsymbol{w}$$

根据后验概率 $p(\boldsymbol{w} | \boldsymbol{D})$，我们能估计在观测到 $p(\boldsymbol{D})$ 之后 $\boldsymbol{w}$ 的不确定性。

## 使用高斯模型

让我们回到多项式拟合上来。我们假设观测的噪声符合高斯分布，那么给定 $x$ 的值，对应的 $t$ 值服从高斯分布，分布的均值为 $y(x, \boldsymbol{w})$，方差为 $\beta^{-1}$。$\beta$ 为精度参数，即方差的倒数。根据以上假设，我们有

$$p(t | x, \boldsymbol{w},\beta) = \mathscr{N}(t | y(x, \boldsymbol{w},\beta^{-1})) $$

通过训练数据 $\{ \boldsymbol{X}, \boldsymbol{D}\}$，我们可以得到似然函数为

$$p(\boldsymbol{D} | \boldsymbol{X}, \boldsymbol{w}, \beta) = \prod_{n=1}^{N} \mathscr{N}(t_n | y(x_n, \boldsymbol{w}), \beta^{-1})$$

取对数有

$$ \ln p(\boldsymbol{D} | \boldsymbol{X}, \boldsymbol{w}, \beta)=-\frac{\beta}2\sum{\{y(x_n, \boldsymbol{w})-t_n \}^2} + \frac N 2 \ln \beta - \frac N 2 \ln(2 \pi )$$

考虑多项式系数的最大似然解 $\boldsymbol{w}_{ML}$，后两项以及前面的 $\frac \beta 2 $ 系数可以去掉。最大化似然函数其实就是最小化平方和误差，如下

$$ \boldsymbol{w}_{ML}=min \sum{\{y(x_n, \boldsymbol{w})-t_n \}^2} $$

也可以用最大似然方法确定高斯条件分布的精度参数 $\beta$。对其求关于 $\boldsymbol{w}$ 的偏导数，并令其导数为 0，有

$$\frac 1 {\beta_{ML}} = \frac 1 N \sum_{n=1}^N \{y(x_n, \boldsymbol{w}_{ML})-t_n \}^2$$

根据以上确定的 $\boldsymbol{w}$ 和 $\beta_{ML}$，便可以对新的 $x$ 值进行预测。其预测可以通过 $t$ 的概率分布给出

$$p(t | x, \boldsymbol{w}_{ML},\beta_{ML})=\mathscr{N}(t|y(x,\boldsymbol{w}_{ML}), {\beta_{ML}}^{-1})$$

## 考虑先验信息

但这个所谓的预测并没有考虑先验概率，我们需要把它加上。我们假设 $\boldsymbol{w}$ 的先验分布为

$$p(\boldsymbol{w} | \alpha) = \mathscr{N}(\boldsymbol{w}|\boldsymbol{0},{\alpha}^{-1} \boldsymbol{I})=(\frac{\alpha}{2 \pi})^{(M+1)/2}exp\{-\frac{\alpha}{2}\boldsymbol{w}^T\boldsymbol{w}\}$$

根据之前的表述后验概率正比于似然函数与先验概率的乘积，我们有

$$p(\boldsymbol{w}| \boldsymbol{X},\boldsymbol{D},\alpha,\beta) \propto p(\boldsymbol{D}|\boldsymbol{X},\boldsymbol{w},\beta)p(\boldsymbol{w}|\alpha)$$

最大化后验概率称为 MAP 方法。对上式取对数后再求极值，后验概率取最大意味着下面这个式子取得最小值

$$\frac{\beta}2 \sum^{N}_{n=1} {\{y(x_n, \boldsymbol{w}-t_n)\}}^2+\frac{\alpha}2 \boldsymbol{w}^T\boldsymbol{w}$$

等一下，这个式子看起来是不是特别眼熟。没错，它其实是和带了正则惩罚项的最小二乘多项式拟合是一样的。在带正则惩罚的最小二乘多项式拟合中，式子如下

$$Error(\boldsymbol{w})=\frac{1}{2} \sum^N_{n=1}{\{y(x_n, \boldsymbol{w}-t_n)\}}^2+ \frac{\lambda}2\boldsymbol{w}^T\boldsymbol{w}$$

其实将 $\lambda= \frac{\alpha}{\beta}$ 带入，可以发现二者是等价的。