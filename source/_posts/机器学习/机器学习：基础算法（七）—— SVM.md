---
title: 机器学习：基础算法（七）—— SVM
date: 2018-10-20 20:17:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20-20-27.jpg" width="70%" heigh="70%"></img>
</div>

支持向量机（support vector machines,SVM）是一种二分类模型，其模型为分离超平面 $wx+b=0$ 及决策函数 $f(x)=sign(wx+b)$，其学习策略为间隔最大化，其学习算法为凸二次规划。

在二分类问题上，SVM 包含以下几种由简到繁的模型：

1. 线性可分 SVM：基于硬间隔最大化（hard margin maximization）
2. 近似线性可分 SVM：基于软间隔最大化（soft margin maximization）
3. 非线性可分 SVM：基于核方法（kernel trick）和软间隔最大化

SVM也可用于回归问题和异常值检测问题，本文只涉及SVM二分类模型。

## 线性可分SVM——硬间隔最大化
线性可分：如果存在某个超平面可以将数据集中所有实例正确划分到两侧，则称该数据集是线性可分的。

### 模型
与感知机模型类似：

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

### 策略
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

与感知机模型不同，SVM不仅仅满足于将数据集正确划分（这样的超平面有无数个），还要求有尽可能大的划分确信度，即**间隔最大化策略**：找到使得最小几何间隔（在所有点中）最大的超平面。

（1）该问题可以形式化表示为以下约束优化问题：

$$
\left\{\begin{matrix}
\begin{align*}
&\underset{w,b}{max}\ \frac{\hat{\gamma }}{\left \| w \right \|}\\ 
&y_i(wx_i+b)\geqslant \hat{\gamma }
\end{align*}
\end{matrix}\right.
$$

（2）对参数进行放缩$w=\frac{w}{\hat{\gamma }},b=\frac{b}{\hat{\gamma }}$，原优化问题可简化为：

$$
\left\{\begin{matrix}
\begin{align*}
&\underset{w,b}{min}\ \frac{1}{2}\left \| w \right \|^2\\ 
&1-y_i(wx_i+b)\leqslant 0,i=1,2,...,n
\end{align*}
\end{matrix}\right.
$$

（3）由拉格朗日乘数法可将原问题转化为拉格朗日极小极大无约束优化问题:

$$
\left\{\begin{matrix}
\begin{align*}
&\underset{w,b}{min}\ \underset{\alpha_i\geqslant 0}{max}\ L(w,b,\alpha)\\ 
&L(w,b,\alpha)=\frac{1}{2}\left \| w \right \|^2+\sum_{i=1}^{n}\alpha_i(1-y_i(wx_i+b))
\end{align*}
\end{matrix}\right.
$$

- $L(w,b,\alpha)$：拉格朗日函数
- $\alpha_i$：拉格朗日乘子

（4）进一步地，可将拉格朗日极小极大问题转化为拉格朗日极大极小问题（对偶问题），前提是满足KKT条件，KKT条件由参数梯度条件、约束条件、乘子非负条件和对偶互补条件组成（不等式乘子和不等式左侧至少有一个为0）：

$$
\left\{\begin{matrix}
\begin{align*}
&\nabla_w L=0\\
&\nabla_b L=0\\
&\nabla_{\alpha} L=0\\
&\alpha_i\geqslant 0,\ i=1,2,...,n\\
&1-y_i(wx_i+b)\leqslant 0,\ i=1,2,...,n\\
&\alpha_i * (1-y_i(wx_i+b)) = 0,\ i=1,2,...,n\\
\end{align*}
\end{matrix}\right.
$$

转化为对偶问题:

$$
\left\{\begin{matrix}
\begin{align*}
&\underset{\alpha_i\geqslant 0}{max}\ \underset{w,b}{min}\ \ L(w,b,\alpha)\\ 
&L(w,b,\alpha)=\frac{1}{2}\left \| w \right \|^2+\sum_{i=1}^{n}\alpha_i(1-y_i(wx_i+b))
\end{align*}
\end{matrix}\right.
$$

（5）化简对偶形式：

首先求解极小问题：

$$
\left\{\begin{matrix}
\begin{align*}
&\nabla_w L=0\\
&\nabla_b L=0\\
\end{align*}
\end{matrix}\right.
$$

$$
\Rightarrow 
\left\{\begin{matrix}
\begin{align*}
&w=\sum_{i=1}^{n}\alpha_iy_ix_i\\
&\sum_{i=1}^{n}\alpha_iy_i = 0
\end{align*}
\end{matrix}\right.
$$

化简极大极小问题:

$$
\begin{align*}
&\underset{\alpha_i\geqslant 0}{max}\ \frac{1}{2} w^Tw-\sum_{i=1}^{n}\alpha_iy_i(wx_i+b)+\sum_{i=1}^{n}\alpha_i\\
=\ &\underset{\alpha_i\geqslant 0}{max}\  \frac{1}{2}(\sum_{i=1}^{n}\alpha_iy_ix_i)^T(\sum_{j=1}^{n}\alpha_jy_jx_j)-\sum_{i=1}^{n}\alpha_iy_i(\sum_{j=1}^{n}\alpha_jy_jx_jx_i+b)+\sum_{i=1}^{n}\alpha_i\\
=\ &\underset{\alpha_i\geqslant 0}{max}\ \frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n}\alpha_i\alpha_jy_iy_jx_ix_j - \sum_{i=1}^{n}\sum_{j=1}^{n}\alpha_i\alpha_jy_iy_jx_ix_j -b\sum_{i=1}^{n}\alpha_iy_i+\sum_{i=1}^{n}\alpha_i\\
=\ &\underset{\alpha_i\geqslant 0}{max}\ -\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n}\alpha_i\alpha_jy_iy_jx_ix_j  + \sum_{i=1}^{n}\alpha_i\\
=\ &\underset{\alpha_i\geqslant 0}{min}\ \frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n}\alpha_i\alpha_jy_iy_jx_ix_j  - \sum_{i=1}^{n}\alpha_i
\end{align*}
$$

最终原问题的对偶形式最终可以表示为:

$$
\left\{\begin{matrix}
\begin{align*}
\underset{\alpha_i\geqslant 0}{min}\ &\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n}\alpha_i\alpha_jy_iy_jx_ix_j  - \sum_{i=1}^{n}\alpha_i\\
s.t.&\\
& \sum_{i=1}^{n}\alpha_iy_i=0\\
& \alpha_i\geqslant 0,\ i = 1,2,...,n\\
& \alpha_i(1-y_i(wx_i+b))=0,\ i = 1,2,...,n
\end{align*}
\end{matrix}\right.
$$

（6）通过序列最小最优化算法（SMO）求解以上对偶问题，假设拉格朗日乘子最优解为:

$$
\alpha^*=(\alpha_1^{*},\alpha_2^*,\dots,\alpha_n^*),\ \alpha_i^*\geqslant 0
$$

因为数据集线性可分，必存在$\alpha_i^*> 0$，由KKT对偶互补条件:

$$
\left\{\begin{matrix}
\begin{align*}
&\exists \alpha_i^*>0\\ 
&\alpha_i(1-y_i(w^*x_i+b^*))=0
\end{align*}
\end{matrix}\right. 
\Rightarrow 
\exists (x_i,y_i),y_i=w^*x_i+b^*
$$

可得：

$$
\left\{\begin{matrix}
\begin{align*}
&w^*=\sum_{i=1}^{n}\alpha_i^*y_ix_i\\
&b^*=y_i-\sum_{j=1}^{n}\alpha_j^*y_jx_jx_i
\end{align*}
\end{matrix}\right.
$$

对于线性可分数据集，以上问题最优解存在且唯一。

### 算法
1998年，Microsoft Research的John C. Platt在论文《Sequential Minimal Optimization：A Fast Algorithm for Training Support Vector Machines》中提出针对上述问题的解法：SMO算法，它很快便成为最快的二次规划优化算法，特别是在针对线性SVM和数据稀疏时性能更优。

SMO算法的基本思想是将Vapnik在1982年提出的Chunking方法推到极致，SMO算法每次迭代只选出两个分量ai和aj进行调整，其它分量则保持固定不变，在得到解ai和aj之后，再用ai和aj改进其它分量。与通常的分解算法比较，尽管它可能需要更多的迭代次数，但每次迭代的计算量比较小，所以该算法表现出较好的快速收敛性，且不需要存储核矩阵，也没有矩阵运算

（1）初始化 $\alpha^{(0)}=0$，$k=0$

（2）选取优化变量 $\alpha^{(k)}_1,\alpha^{(k)}_2$

- 先“扫描”所有乘子，把第一个违反KKT条件的作为更新对象，令为 $\alpha^{(k)}_1$
- 在所有不违反KKT条件的乘子中，选择使 |$E_1-E_2$| 最大的 $\alpha^{(k)}_2$

（3）解析求解两个变量的最优解$\alpha^{(k+1)}_1,\alpha^{(k+1)}_2$，更新$\alpha$

（4）若在精度范围内满足以下停机条件则终止，否则令$k=k+1$，转（2）

$$
\begin{align*}
&\sum_{i=1}^{N}\alpha_iy_i=0\\
&0\leqslant \alpha_i\leqslant C,i=1,2...,N\\
&y_i (\sum_{j=1}^{N}\alpha_jy_jK(x_j,x_i)+b)=\left\{\begin{matrix}
\geqslant 1 & , \left \{x_i|\alpha_i=0  \right \} \\
= 1 & , \left \{x_i|0<\alpha_i<C  \right \} \\ 
\leqslant  1 & , \left \{x_i|\alpha_i=C  \right \} 
\end{matrix}\right.
\end{align*}
$$

假设最优解$\alpha^*$，则模型可表示为:

$$
f(x) = sign(\sum_{i=1}^{N}\alpha_i^* y_i x_i x + b)
$$

### 支持向量
<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/02-20-36.jpg" width="50%" heigh="50%"></img>
</div>

1. $\alpha^*_i=0$: 非支持向量，margin以外的点（大多数点）；
2. $\alpha^*_i>0$：支持向量，margin上的点
    1. $y_i=+1$: 支持向量在超平面$wx+b=1$上
    2. $y_i=-1$: 支持向量在超平面$wx+b=-1$上
    
## 近似线性可分SVM——软间隔最大化
现实中的数据集往往是线性不可分的，这意味着某些特异点（outlier）不能满足函数间隔大于1的约束，此时硬间隔最大化的原则不再适用，一种思路是适当放宽约束条件，只要每个样本点$(x_i,y_i)$的函数间隔大于等于$1-\xi_i$即可（$\xi_i$被称为关于点$(x_i,y_i)$的松弛变量）。

### 模型不变
$$
f(x) = sign(wx+b)
$$

### 策略
软间隔最大化：使间隔尽可能大的同时，使松弛变量尽可能小。C是对误分类点数的惩罚参数，通过调节C可以使得间隔最大化和误分类点数达到平衡。C越大，说明对误分点数惩罚越大，越少的点会被误分，偏差变小，方差增大，C越大越容易过拟合。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/IMG_1119.jpg" width="80%" heigh="80%"></img>
</div>

### SMO 算法
同硬间隔最大化，假设最优解$\alpha^*$，则模型可表示为:

$$
f(x) = sign(\sum_{i=1}^{N}\alpha_i^* y_i x_i x + b)
$$

### 支持向量
条件:

$$
\left\{\begin{matrix}
&C>0\\
&C\geqslant \alpha_i^*\geqslant0\\
&C\geqslant \mu^*\geqslant0\\
&C=\alpha^*_i+\mu^*_i\\
&\mu^*_i*\xi_i^*=0\\
&y_i(w^*x_i+b^*)-1+\xi_i^*\geqslant 0\\
&\alpha^*_i(y_i(w^*x_i+b^*)-1+\xi_i^*)=0
\end{matrix}\right.
$$

支持向量：

- $\alpha^*_i=0$: $(x_i,y_i)$为普通点，位于margin外侧；

$$
\alpha ^*_i=0\Rightarrow \mu_i^*=C>0\Rightarrow \xi_i^*=0\Rightarrow y_i(w^*x_i+b^*)\geqslant 1
$$

- $C>\alpha^*_i>0$: $(x_i,y_i)$为支持向量，位于margin上（记住这一条，其他的也就方便记忆了）；

$$
C>\alpha^*_i>0\Rightarrow \mu_i^*>0\Rightarrow \xi_i^*=0\Rightarrow y_i(w^*x_i+b^*)= 1
$$

- $\alpha^*_i=C$: $(x_i,y_i)$为支持向量，$\xi_i$衡量点向内偏离margin的距离；
    - $1>\xi^*_i>0$：$(x_i,y_i)$在margin和超平面之间；
    - $\xi^*_i=1$：$(x_i,y_i)$在超平面上；
    - $\xi^*_i>1$：$(x_i,y_i)$在被超平面误分一侧；

支持向量示意图：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/支持向量.png" width="60%" heigh="60%"></img>
</div>

### 合页损失函数
软间隔最大支持向量机的损失函数等价于带正则的合页损失函数(hinge loss function)：

$$
L(w,b)=\sum_{i=1}^{N}[1-y_i(wx_i+b)]_+ + \lambda \left \| w \right \|^2
$$

其中合页函数：

$$
[z]_+=\left\{\begin{matrix}
z, &z>0 \\ 
 0,& z\leqslant 0
\end{matrix}\right.
$$

只需令 $[1-y_i(wx_i+b)]_+=\xi_i$，$\lambda = \frac{1}{2C }$ 即可得证:

$$
L(w,b)=\sum_{i=1}^{N}[1-y_i(wx_i+b)]_+ + \lambda \left \| w \right \|^2=\frac{1}{C}(\frac{1}{2} \left \| w \right \|^2+C\sum_{i=1}^{N}\xi_i )
$$ 

二分类问题中常见的6种损失函数对比：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/loss.png" width="60%" heigh="60%"></img>
</div>

令$z=y\cdot f(x)$，其中$y$代表实例的观测标签（$+1,-1$），$f(x)$代表某个判别函数，满足当$f(x)>0$时判别为+1类，当$f(x)<0$时判别为-1类；z的符号代表预测正确性（正代表正确预测），z的绝对值代表预测确信度（值越大，确信度越高）。

- 0-1损失：$l(z)=[z<0]$
- 感知机损失函数：$l(z)=[-z]_+$
- SVM损失函数：$l(z)=[1-z]_+$，合页损失函数不仅要分类正确，而且确信度足够高时损失才为0
- 平方损失：$l(z)=(z-1)^2$
- sigmoid交叉熵（对数似然）：$l(z)=-\frac{1 }{\sqrt{2}} lg\sigma(z)$
- sigmoid平方损失；$l(z)=(\sigma (z)-1)^2$


## 非线性可分SVM——核技巧
线性SVM无法解决线性不可分的分类问题，此时如果数据集是（近似）非线性可分的，那么可以通过核方法来求解。

非线性可分：如果能用$R^n$空间中的一个超曲面将数据集中的正负例正确分开，则称该数据集是非线性可分的。如下图中的数据集：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/19-57-51.png" width="40%" heigh="40%"></img>
</div>

解决非线性可分问题的基本思路:

1. 通过一个非线性变换将原始输入空间映射到新的线性可分的特征空间；
2. 在新的特征空间中训练线性分类模型；

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1364952814_3505.gif" width="50%" heigh="50%"></img>
</div>

### 模型
非线性可分SVM分类模型先对输入进行非线性转化再由线性模型求解：

$$
f(x)=sign(w \cdot \phi (x)+b)
$$

对应的对偶形式:

$$
f(x) = sign(\sum_{i=1}^{N}\alpha_iy_i \phi(x_i) \phi(x) + b)
$$

### 策略
非线性可分的间隔最大化可表述为以下约束优化问题：
 
$$
\begin{align*} 
\underset{\alpha}{min} &\frac{1}{2}\sum_{i=1}^{N}\sum_{j=1}^{N}\alpha_i \alpha_jy_i y_j \phi(x_i) \phi(x_j) - \sum_{i=1}^{N} \alpha_i\\
s.t. & \sum_{i=1}^{N} \alpha_i y_i=0\\
& \alpha_i \geqslant 0
\end{align*}
$$

核技巧:

- 基函数：从输入空间到特征空间的映射$\phi(x):\chi \rightarrow  \Psi$；
- 核函数：对所有$x,z \in \chi$满足$K(x,z)=\phi(x) \cdot \phi(z)$的$K(x,z)$；
- 核方法：只定义核函数$K(x,z)$而不显式定义基函数$\phi(x)$，相当于“隐式”地对原始输入空间进行了非线性转化，节省了基函数计算的额外开销。
- 正定核：通常所说的核函数就是正定核函数，正定核的等价定义是$K(x,z)$对应的Gram矩阵$[K(x_i,x_j)]_{N*N}$是半正定矩阵。核正定能够确保拉格朗日函数有上界。

使用核方法来重新定义原问题:

- 模型：

$$
f(x) = sign(\sum_{i=1}^{N}\alpha_iy_i K(x_i,x) + b)
$$

- 核技巧+间隔最大化：

$$
\begin{align*} 
\underset{\alpha}{min} &\frac{1}{2}\sum_{i=1}^{N}\sum_{j=1}^{N}\alpha_i \alpha_jy_i y_j K(x_i,x_j) - \sum_{i=1}^{N} \alpha_i\\
s.t. & \sum_{i=1}^{N} \alpha_i y_i=0\\
& \alpha_i \geqslant 0
\end{align*}
$$

### 选择核函数
[常用的核函数](http://blog.csdn.net/chlele0105/article/details/17068949):

（1） 线性核函数(Linear Kernel)：线性核是最简单的核函数。它由内积<x，y>加上一个可选的常量c给出。使用线性核的核算法通常等同于它们的非内核对应，即具有线性内核的KPCA与标准PCA相同。

$$
k(x, y) = x^T y + c
$$

（2） 多项式核函数( Polynomial Kernel): 多项式核函数可以实现将低维的输入空间映射到高纬的特征空间，但是多项式核函数的参数多，当多项式的阶数比较高的时候，核矩阵的元素值将趋于无穷大或者无穷小（不稳定核），计算复杂度会大到无法计算，使用多项式核需要先对数据进行标准化。

$$
k(x, y) = (\alpha x^T y + c)^p
$$

（3） sigmoid/双曲核函数(Hyperbolic Tangent (Sigmoid) Kernel):

$$
k(x, y) = \tanh (\alpha x^T y + c)
$$

（4） 高斯核函数(Gaussian Kernel): 高斯核函数是径向基函数(radial basis function,RBF)的一个实例，（另外两个比较常用的径向基函数：幂指数核，拉普拉斯核）。径向基函数是指取值仅仅依赖于特定点距离的实值函数，也就是$\Phi (x,y) = \Phi (\left \| x-y \right \|)$。高斯核是使用最广泛的核函数，参数少好调节；可以通过$\sigma$来调节核的表现（sk-learn中通过调节方差倒数$\gamma =\frac{1}{\sigma ^2}$），如果估计过高，则指数将几乎呈线性变化，高维投影将开始失去其非线性功效（欠拟合）。另一方面，如果低估，该函数将缺乏正则化（只有附近的点起作用），并且决策边界将对训练数据中的噪声高度敏感（过拟合）。方差越小越容易过拟合。

$$
k(x, y) = \exp\left(-\frac{ \lVert x-y \rVert ^2}{2\sigma^2}\right)
$$

（5） 指数核函数(Exponential Kernel):

$$
k(x, y) = \exp\left(-\frac{ \lVert x-y \rVert }{2\sigma^2}\right)
$$

（6） 拉普拉斯核函数(Laplacian Kernel)：

$$
k(x, y) = \exp\left(- \frac{\lVert x-y \rVert }{\sigma}\right)
$$

选用核函数时，可以通过对数据的先验知识选择合适的核函数，或者通过交叉验证选择性能最好的核函数，也可以将多个核函数结合起来构成混合核函数，具体的有以下经验法则:

1. 一般用线性核和高斯核，线性核可以看做是高斯核的特殊情况，sigmoid核在某些参数下和RBF很像；
2. polynomial kernel的参数比RBF多，而参数越多模型越复杂
3. 如果特征数很多，选用线性kernel就好了；
4. 如果特征数较少，选用高斯核；
5. 如果特征很少，则考虑增加特征；

### SMO算法
同硬间隔最大化，假设最优解$\alpha^*$，则模型可表示为:

$$
f(x) = sign(\sum_{i=1}^{N}\alpha_i^* y_i K(x_i, x) + b)
$$

## SVM进阶问题
### SVM用于多分类问题
SVM 用于 K 分类问题时一般会转化为二分类问题：

1. 一对剩余(one-Versus-rest)：使用来自$c_k$的样本作为正例，剩余样本作为负例构建K个独立的SVM。缺点：① 一个样本可能会被分配到0或多个类别；② 人为造成数据偏斜；
2. 一对一：针对每两个类别的样本训练一个SVM，总共需要构建K(K-1)/2个分类器，然后通过多数投票确定样本类别。缺点：① K比较大时比第一种方法花费更多的训练时间；
3. DAGSVM：仍然是一对一的方式，需要训练K(K-1)/2个分类器，但是在对新的测试点分类时，只需要K-1对分类器进行计算，根据DAG中的路径确定样本最终分类。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/19-43-49.jpg" width="40%" heigh="40%"></img>
</div>

### SVM用于回归问题
类比 SVM 分类器的损失函数，可以将SVM应用于回归问题时的损失函数定义为:

$$
L(w)=\frac{1}{2}\left \| w \right \|^2+C\sum_{i=1}^{n}[\left | f(x_i)-y_i \right |- \varepsilon ]_+
$$

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/19-55-40.jpg" width="80%" heigh="80%"></img>
</div>

按照惯例，称C为惩罚参数，通过引入松弛变量可以重新定义最优化问题：

$$
\begin{align*}
arg\ \underset{w}{min}\ &\frac{1}{2}\left \| w \right \|^2+C\sum_{i=1}^{n}(\xi _i+\hat{\xi _i})\\
s.t.\ &\xi _i\geqslant 0\\
&\hat{\xi _i}\geqslant 0\\
&\xi_i\geqslant f(x_i)-y_i- \varepsilon \\
&\hat{\xi _i} \geqslant y_i-f(x_i)- \varepsilon 
\end{align*}
$$

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/19-56-13.jpg" width="80%" heigh="80%"></img>
</div>

### SVM 用于不平衡数据
数据集偏斜（unbalanced）指的是参与分类的两个类别（也可以指多个类别）样本数量差异很大。比如说正类有10，000个样本，而负类只给了100个，这会引起的问题显而易见，可以看看下面的图：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/19-58-42.jpg" width="50%" heigh="50%"></img>
</div>

现在由于偏斜的现象存在，使得数量多的正类可以把分类面向负类的方向“推”，因而影响了结果的准确性。真实的原因并不是父类样本少而是负类的样本分布的不够广。

对付数据集偏斜问题的方法之一就是在惩罚因子上作文章，想必大家也猜到了，那就是给样本数量少的负类更大的惩罚因子(一般通过正负例比例来调整正负惩罚因子的比例)，表示我们重视这部分样本（本来数量就少，再抛弃一些，那人家负类还活不活了），因此我们的目标函数中因松弛变量而损失的部分就变成了：

$$
\begin{align*}
C_+\sum_{i=1}^{p}\xi _i+C_-\sum_{j=p+1}^{p+q}\xi _j\\
C_+*N_+=C_-*N_-
\end{align*}
$$

### SVM 的训练-预测时间复杂度
SVM训练过程：

- 二次规划问题求解通常的时间复杂度为 $O(n^3)$，n为变量个数(对偶问题中样本个数等于变两个数,PRML)
- SMO最坏最坏时间复杂度 $O(n^3)$ (维基)
- 求得解析解的时间复杂度最坏可以达到$O(Nsv^3)$，其中Nsv是支持向量的个数
- 数值解:一个具体的算法，Bunch-Kaufman训练算法，典型的时间复杂度在O(Nsv3+LNsv2+dLNsv)和O(dL2)之间，其中Nsv是支持向量的个数，L是训练集样本的个数，d是每个样本的维数

SVM预测过程：SVM保存了支持向量，$O(Nsv)$

## LR 和 SVM 的异同
1. 相同点:
    1. 都可以作为分类模型；
    2. 都是线性判别模型；
2. 不同点：
    1. 损失函数不同：LR是交叉熵，SVM是最大间隔，合页损失；
    2. LR可得到后验概率；
    3. SVM基于距离度量；
    4. SVM待正则项；
    5. SVM更适合小规模数据集；

## 评价
- 优点:
    1. 在**小样本训练集**上也能够得到很好的结果：SVM本身是基于小样本统计理论的；
    2. 可以解决**高维问题**：通过核函数避开高维空间的复杂性；
    3. 可以解决**非线性问题**：通过核技巧和软间隔最大化可以应用于非线性可分问题
    4. **泛化能力**较好：间隔最大化是一种结构化风险最小化策略；
- 缺点:
    1. 对缺失数据比较敏感；
    2. 不提供后验概率；
    3. 对非线性问题没有太好方式确定核函数；
    4. 求解二次规划问题，需要占用大量存储空间存储Gram矩阵；
    4. 如果数据量较大，效率上不及SVM比LR和朴素贝叶斯；