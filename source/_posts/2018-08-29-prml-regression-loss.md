---
title: 回归损失函数
date: 2018-08-29 13:53:21
categories:
 - Algorithm
tags:
 - PRML
 - regression loss
--- 

这篇记录了一下回归损失函数的推导过程，主要是 PRML 的式 1.88 和式 1.90。我在 Google 上搜了过 1.88 的推导。有一些中文博客的推导，不过写的什么 J8 玩意，看着推导的时候被带到沟里去了。最后找了[stackexchange](https://math.stackexchange.com/questions/2130282/bishop-ml-and-pattern-recognition-calculus-of-variations-linear-regression-loss) 以及这里[stackexchange](https://stats.stackexchange.com/questions/228561/loss-functions-for-regression-proof) 才算得到完美解答。

<!--more-->

## 回归损失函数

我们首先给出回归损失函数的定义 $L(t,y(x))$ 。其中 $x$ 是输入，$y(x)$ 是对 $t$ 的具体估计。$t$ 可以认为是真值。函数 $L$ 可以理解为损失函数，或者是惩罚函数。那么平均损失（或者说期望损失）就是

$$E[L]=\int\int L(t,y(x))p(x,t)dx\ dt$$

我们考虑最常见的平方损失函数，定义为 $L(t,y(x))=\{y(x)-t\}^2$，那么上式就可以写为

$$E[L]= \int \int \{y(x)-t\}^2p(x,t)dx\ dt$$

关键点来了，在 PRML 的原书上只说了变分法就得到了

$$\frac{\delta E[L]}{\delta y(x)}=2 \int\{y(x)-t\}p(x,t)\ dt=0$$

我第一次看到反正是一脸懵逼。

## 式 1.88 推导

首先我们可以把式子改写如下

$$\begin{split}&\int\int[y(x)-t]^2p(x,t)dx\ dt \\
=&\int G(y(x),y'(x),x)dx\end{split}$$

$$G(y,y',x)=\int[y-t]^2p(x,t)dt$$

好了，根据变分法我们有

$$ \frac{\partial G}{\partial y}-\frac {d}{dx}\left( \frac{\partial G}{\partial y'}\right)=0$$

因为在 $G(y,y',x)$ 中没有 $y'$ 的项，所以有

$$\frac{\partial G}{\partial y}= \int2[y-t]p(x,t)dt$$

将式子变形一下，我们有

$$y(x)=\frac{\int tp(x,t)\ dt}{p(x)}=E_t[t|x]$$

这样我们就得到了 $x$ 条件下 $t$ 的均值，被称为回归函数。

## 式 1.90 推导

紧接着就是一个可以把损失函数分解为两部分的公式 1.90。这个公式会在后面用于偏置方差分解。

我们先搞个引理如下

$$\begin{split} E_{x,t}[g(x,t)]&=\int_x \int_t g(x,t)p(x,t)dx\ dt \\
&=\int_x\int_tg(x,t)p(x)p(t|x)dx\ dt \\
&=\int_xp(x)\int_tg(x,t)p(t|x)dt \ dx \\
&=\int_xE_t[g(x,t)|x]p(x)dx \\
&=E_x[E_t[g(x,t)|x]]\end{split}$$

对于 $\{y(x)-t\}^2$，我们可以做如下变化

$$\begin{split}\{y(x)-t\}^2&=\{y(x)-E_t[t|x]+E_t[t|x]-t\}^2
\\ &=\{y(x)-E_t[t|x]\}^2+2\{y(x)-E_t[t|x]\}\{E_t[t|x]-t\}+\{E_t[t|x]-t\}^2 \\
&=L_1+2L_2+L_3\end{split}$$

根据引理，我们有

$$E_{x,t}[L]=E_{x,t}[L_1]+2E_{x,t}[L_2]+E_{x,t}[L_3]$$

然后分别计算三项

$$\begin{split}E_{x,t}[L_1]&=E_{x,t}[(y(x)-E_t[t|x])^2] \\
&=E_x[(y(x)-E_t[t|x])^2] \end{split}$$

$$\begin{split}E_{x,t}[L_2]&=E_{x,t}[(y(x)-E_t[t|x])(E_t[t|x]-t)] \\
&=E_x[ E_t[\{(y(x)-E_t[t|x])(E_t[t|x]-t)\}]|x] \\
&=E_x[(y(x)-E_t[t|x])E_t[(E_t[t|x]-t)|x]]\end{split}$$

注意到 $E_t[(E_t[t|x]-t)|x]=E_t[t|x]-E_t[t|x]=0$，所以 $E_t[L_2]=0$。

$$\begin{split}E_{x,t}[L_3]&=E_{x,t}[(E_t[t|x]-t)^2] \\
&=E_x[E_t[(E_t[t|x]-t)^2|x]] \\
&=E_x[var_t[t|x]]\end{split}$$

所以（这里原版的英文书是有问题的）

$$E_{x,t}[L]=\int_x(y(x)-E_t[t|x])^2p(x)dx+\int_xvar_t[t|x]dx$$