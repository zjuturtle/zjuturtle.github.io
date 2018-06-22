---
title: Lempel-Ziv complexity 详解
date: 2018-06-22 17:42:37
categories:
 - Algorithm
tags: 
 - EEG
 - feature
---

这其实是一个相对独立的知识点，介绍一下 Lempel-Ziv complexity 。这个概念最开始是在 __On the Complexity of Finite Sequences (IEEE Trans. On IT-22,1 1976)__ 提出的。Lempel-Ziv complexity 可以用于衡量 0-1 序列或者文本序列的自身重复程度。

<!--more-->

## 理论

首先我们假设 $S$ 是一个 0-1 序列（读取顺序为从左往右），其 Lempel-Ziv complexity 记为 $C(S)$。

想象我们有一个在读取过程中从左到右移动的分隔符。在初始状态下这个分隔符在第一个元素和第二个元素中间，且确定该位置为第一个分隔符位置，记录为起始位置。然后我们定义前缀序列为分隔符之前的序列舍去最后一个元素，注意此时前缀序列为空。接下来尝试将分隔符向右移动一个元素，定义起始位置和当前位置之间的序列为当前序列。如果当前序列为前缀序列的一个子串，则继续将分隔符向右移动一个元素，直到条件不满足。当条件不满足时，再次将此时的分隔符位置记录为起始位置，如此循环。复杂度即为起始位置设置的次数

## 例子

说起来真是拗口，其实我在翻资料的时候也着实理解了半天。比如我们现在有一串序列 `BAABBBBABBAAAABA`，需要计算它的 Lempel-Ziv complexity。我们用 `|` 表示记录的起始位置，用 `,` 正在移动的分隔符。


| 步骤 | 序列 | 前缀 | 当前序列 |  备注 |
| --- | --- | --- | --- | --- | --- |
| 0 | B\|AABBBBABBAAAABA | B | - |初始状态 |
| 1 | B\|A,ABBBBABBAAAABA | B | A | 分隔符右移 |
| 2 | B\|A\|ABBBBABBAAAABA | BA | - | 记录为起始位置 |
| 3 | B\|A\|A,BBBBABBAAAABA | BA | A | 分隔符右移 |
| 4 | B\|A\|AB,BBBABBAAAABA | BAA | AB | 分隔符右移 |
| 5 | B\|A\|AB\|BBBABBAAAABA | BAAB | - | 记录为起始位置 |
| 6 | B\|A\|AB\|B,BBABBAAAABA | BAAB | B | 分隔符右移 |
| 7 | B\|A\|AB\|BB,BABBAAAABA | BAABB | BB | 分隔符右移 |
| 8 | B\|A\|AB\|BBB,ABBAAAABA | BAABBB | BBB | 分隔符右移 |
| 9 | B\|A\|AB\|BBBA,BBAAAABA | BAABBBB | BBBA | 分隔符右移 |
| 10 | B\|A\|AB\|BBBA\|BBAAAABA | BAABBBB | - | 记录为起始位置 |
| 11 | B\|A\|AB\|BBBA\|B,BAAAABA | BAABBBBA | B | 分隔符右移 |
| 12 | B\|A\|AB\|BBBA\|BB,AAAABA | BAABBBBAB | BB | 分隔符右移 |
| 13 | B\|A\|AB\|BBBA\|BBA,AAABA | BAABBBBABB | BBA | 分隔符右移 |
| 14 | B\|A\|AB\|BBBA\|BBAA,AABA | BAABBBBABBA | BBBA | 分隔符右移 |
| 15 | B\|A\|AB\|BBBA\|BBAA\|AABA | BAABBBBABBAA | - | 记录为起始位置 |
| 16 | B\|A\|AB\|BBBA\|BBAA\|A,ABA | BAABBBBABBAA | A | 分隔符右移 |
| 17 | B\|A\|AB\|BBBA\|BBAA\|AA,BA | BAABBBBABBAAA | AA | 分隔符右移 |
| 18 | B\|A\|AB\|BBBA\|BBAA\|AAB,A | BAABBBBABBAAAA | AAB | 分隔符右移 |
| 19 | B\|A\|AB\|BBBA\|BBAA\|AABA | BAABBBBABBAAAAB | AABA | 分隔符右移 |

这里特别注意，第 3 步到第 4 步前缀的变化。随着分隔符的移动，我们的前缀也在增长。


## 在 EEG 上的应用

首先我们的脑电数据是一个非平稳信号，要应用 Lempel-Ziv complexity 则需要先对它进行二值化。二值化的方法其实特别简单粗暴。对于一段脑波序列 $X={x[0], x[1], x[2], ... , x[n]}$，按以下公式二值化。

$$ y[i]=\begin{cases}
1,  & \text{if $ x[i] < m$} \\
0, & \text{otherwise}
\end{cases} $$

