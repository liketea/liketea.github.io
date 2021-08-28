---
title: 机器学习：基础算法（二）—— PLA
date: 2018-10-20 20:22:53
tags: 
    - 机器学习
categories:
    - 机器学习
---


感知器算法（Perceptron Learning Algorithm,PLA）的最初概念可以追溯到[Warren McCulloch和Walter Pitts在1943年的研究](http://www.cse.chalmers.se/~coquand/AUTOMATA/mcp.pdf)，他们将生物神经元类比成带有二值输出的简单逻辑门，输入信号在神经细胞体内聚集，当聚集的信号强度超过一定的阈值，就会产生一个输出信号，并被树突传递下去。后来，Frank Rosenblatt 1957年发表了一篇论文《The perceptron, a perceiving and recognizing automaton Project Para》，基于神经元定义了感知机算法的概念，并说明了，感知机算法的目的，就是针对多维特征的样本集合，学习一个权值向量 ，使得乘以输入特征向量之后，基于乘积可以判断一个神经元是否被激活。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/00-41-56.jpg" width="80%" heigh="80%"></img>
</div>

感知机是一个基于判别函数的线性二分类模型，其输入为实例的特征向量，通过分离超平面将实例划分为正负类。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/00-45-58.jpg" width="80%" heigh="80%"></img>
</div>

感知机是神经网络和支持向量机的基础。

## 模型
感知机通过以下判别函数对输入实例进行分类：

$$
f(x) = sign(wx+b)
$$

- w:权值向量
- b:偏置
- sign:阶跃函数

$$
sign(x)=\left\{\begin{matrix}
+1 &,x\geqslant 0 \\ 
-1 & ,x< 0
\end{matrix}\right.
$$

感知机的几何解释：$wx+b=0$对应于特征空间$\mathbb{R}^n$中的一个超平面S；$w$对应超平面的法向量；$b$对应超平面的截距。该超平面将特征空间划分为两个部分，与法向量同向的被分为正类，反向的分为负类，因此S又称为分离超平面。

线性可分：如果存在某个超平面可以将数据集中所有实例正确划分到两侧，则称该数据集是线性可分的。

## 策略

函数间隔：点$(x_i,y_i)$到超平面的函数间隔定义为

$$
\hat{\gamma}_i =y_i (wx_i+b)
$$

几何间隔：点$(x_i,y_i)$到超平面的距离

$$
\gamma_i =\frac{y_i( wx_i+b)}{\left \| w \right \|}
$$

- 几何间隔的正负：表示分类预测的正确性；为正说明点被正确分类，为负说明点被错误分类，为零说明点在超平面上；
- 几何间隔的绝对值：表示分类预测的确信度；

损失函数最直接的选择是误分类点数，但是这样的损失函数不是参数的可导函数，不易优化，因此提出了另外的代理损失函数：误分类点几何间隔之和最小化，这被称为**感知机准则**。

$$
L(w,b) = -\frac{1}{\left \| w \right \|}\sum_{y_i(wx_i+b)\leqslant 0}y_i(wx_i+b)
$$

通过参数缩放可使得$\left \| w \right \|=1$:

$$
L(w,b) = -\sum_{x_i \in M}y_i(wx_i+b\\
M=\left \{ (x_i,y_i)|y_i(wx_i+b)<0 \right \}
$$


## 算法
感知机学习算法有原始形式和对偶形式

### 原始形式
损失函数可导，可通过随机梯度下降法来求出最优解：

$$
\left\{\begin{matrix}
\bigtriangledown _w L(w,b)=-\sum_{x_i \in M}y_i x_i\\ 
\bigtriangledown _b L(w,b)=-\sum_{x_i \in M}y_i 
\end{matrix}\right.
$$

每次随机取一个误分类点 $(x_i,y_i)$，对w,b进行更新，直至训练集中没有误分类点：

$$
\left\{\begin{matrix}
w\leftarrow w+\eta y_ix_i\\ 
b\leftarrow b+ \eta y_i
\end{matrix}\right.
$$

感知机收敛定理：如果数据集线性可分则感知机算法可在有限步内找到最优解。

对于不同的初始值和选点顺序，最优解可能不同。

### 对偶形式
假设w,b关于 $(x_i,y_i)$ 更新了 $n_i$ 次，令 $\alpha_i=n_i * \eta$，则：

$$
\left\{\begin{matrix}
w=\sum_{i=1}^{N}\alpha_iy_ix_i\\ 
b=\sum_{i=1}^{N}\alpha_iy_i
\end{matrix}\right.
$$

我们可以重写感知机模型：

$$
f(x)=\sum_{j=1}^{N}\alpha_jy_j(x_j\cdot x)+b
$$

感知机学习算法：

1、初始化 $\alpha=0,b=0$
2、在训练集中选取$(x_i,y_i)$，如果$y_i(\sum_{j=1}^{N}\alpha_jy_j(x_j\cdot x)+b)\leqslant 0$

$$
\left\{\begin{matrix}
\alpha_i\leftarrow \alpha_i+\eta \\ 
b\leftarrow b+ \eta y_i
\end{matrix}\right.
$$

3、直至没有误分类点

对偶形式中训练数据仅以内积形式出现，可预先将训练集中的实例间的内积计算出来以矩阵形式存储，即Gram矩阵：

$$
G=[x_i,x_j]_{N*N}
$$

使用核技巧将实例内积$x_i\cdot x_j$替换为核函数$k(x_i,x_j)=\phi (x_i) \cdot \phi(x_j)$可以处理非线性可分情况，相当于将实例进行特征转化后进行线性划分。

### 感知机模型的袋式算法
感知机算法收敛的一个基本条件就是：样本是线性可分的。如果这个条件不成立的话，那么感知机算法就无法收敛。为了在样本线性不可分的情况下，感知机也可以收敛于一个相对理想的解，这里提出感知机袋式算法（Pocket algorithm）。

这个算法分为两个步骤： 
1. 随机的初始化权值向量$w_0$, 定义一个存储权值向量的袋子$P$，并为这个袋子设计一个计数器$P_c$，计数器初始化为0。 
2. 在第t次迭代的时候，根据感知机算法计算出其更新的权值。用更新后的权值$w_{t+1}$测试分类的效果，分类正确的样本数为h，如果$h>P_c$，那么用$w_{t+1}$更新$w_{t}$ ，否则放弃当前更新。

## 算法实现
```python
import os
 
# An example in that book, the training set and parameters' sizes are fixed
training_set = [[(3, 3), 1], [(4, 3), 1], [(1, 1), -1]]
 
w = [0, 0]
b = 0
 
# update parameters using stochastic gradient descent
def update(item):
    global w, b
    w[0] = w[0] + 1 * item[1] * item[0][0]
    w[1] = w[1] + 1 * item[1] * item[0][1]
    b = b + 1 * item[1]
    # print w, b # you can uncomment this line to check the process of stochastic gradient descent
 
# calculate the functional distance between 'item' an the dicision surface
def cal(item):
    global w, b
    res = 0
    for i in range(len(item[0])):
        res += item[0][i] * w[i]
    res += b
    res *= item[1]
    return res
 
# check if the hyperplane can classify the examples correctly
def check():
    flag = False
    for item in training_set:
        if cal(item) <= 0:
            flag = True
            update(item)
    if not flag:
        print "RESULT: w: " + str(w) + " b: "+ str(b)
        os._exit(0)
    flag = False
 
if __name__=="__main__":
    for i in range(1000):
        check()
    print "The training_set is not linear separable. "
```

## 评价
- 优点：简单
- 缺点：
    - 对线性不可分的数据集，永远无法收敛
    - 无法提供概率形式输出
    - 无法直接推广到多分类问题
    - 基于固定基函数的线性组合