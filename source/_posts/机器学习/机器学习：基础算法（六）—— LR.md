---
title: 机器学习：基础算法（六）—— LR
date: 2018-10-20 20:18:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/2017-06-14-14972714947069.jpg" width="60%" heigh="60%"></img>
</div>

逻辑回归（Logistic Regression, LR）是统计学习中经典的分类方法，被广泛应用于计算广告学、社会学、生物统计学、临床、数量心理学、计量经济学、市场营销等众多领域。逻辑回归模型是在线性模型的基础上加上sigmoid激活函数的广义线性模型，它以对数似然（等价于交叉熵）为损失函数，通过梯度下降及拟牛顿法进行求解。

## 模型
如果将正例标签取做1，负例标签取做0，则二项逻辑回归模型的后验概率分布可表示为：

$$
\begin{align*}
p(y=1|x)&=\sigma (z)\\ 
p(y=0|x)&=\sigma (-z)
\end{align*}
$$

$p(y \mid x)$ 服从伯努利分布，可统一表示为:

$$
p(Y=y|x)=\sigma (z)^y \sigma (-z)^{1-y} 
$$

- $z=wx$：x的仿射变换；
- $\sigma(z)$：sigmoid函数$\sigma(z)=\frac{1}{1+e^{-z}}$


关于sigmoid函数，应该记住以下常用性质(加乘除)：

$$
\begin{align*}
&\sigma (z)+\sigma (-z)=1\\ 
&\frac{\sigma(z)}{\sigma(-z)}=e^{z}\\
&\sigma(z)\cdot \sigma(-z)=\sigma ^‘(z)
\end{align*}
$$

## 策略
学习逻辑回归模型时，可以应用极大似然策略（最小化p(y)与p(y|x)的交叉熵）来估计模型参数：

- 极大似然函数：

$$
MLE(w,b)=\prod_{i=1}^{N}p(y_i|x_i)=\prod_{i=1}^{N} \sigma (z_i)^{y_i} \sigma (-z_i)^{1-y_i}
$$

- 负对数似然损失函数：

$$
\begin{align*} 
L(w,b)&=-lg\ MLE(w,b)\\
&=-\sum_{i=1}^{N}lgp(y_i|x_i)\\
&=-\sum_{i=1}^{N}y_ilg\sigma (z_i)+(1-y_i)lg\sigma (-z_i)\\
&=-\sum_{i=1}^{N}y_ilg\frac{\sigma (z_i)}{\sigma (-z_i)}+lg\sigma (-z_i)\\
&=-\sum_{i=1}^{N}[y_iz_i+lg\sigma (-z_i)]\\
\end{align*}
$$

## 算法
逻辑回归通常采用梯度下降和拟牛顿法来求解，以下以极速梯度下降法为例：

（1）令 $g(y_i,z_i,w)=y_iz_i+lg\sigma (-z_i)$

（2）求损失函数偏导：

$$
\begin{align*} 
\frac{\partial g_i}{\partial w^j}&=\frac{\partial g_i}{\partial z_i}\frac{\partial z_i}{\partial w^j}\\
&=(y_i-\frac{\sigma (-z_i)\sigma (z_i)}{\sigma (-z_i)})x_i^j\\
&=(y_i-\sigma (z_i))x_i^j\\
\end{align*}
$$
（3）极速下降：

$$
w\leftarrow w+\eta \sum_{i=1}^{N}(y_i-\sigma (z_i))x_i
$$

## 0-1 表示与 ±1 表示对比
有时将正例标签记做+1，将负例标签记做-1，推导过程基本一致，只是细节有些不同：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/lr.jpg" width="80%" heigh="80%"></img>
</div>

## 逻辑回归应用于多分类问题
逻辑回归只能用于二分类问题，要想实现k分类必须改进逻辑回归，通常有两种方式：

1. 建立k个二分类逻辑回归：对每一分类建立一个二分类器，该类别被标记为1，其他类别被标记为0，这样我们就可以得到k个普通的逻辑回归分类器，最后选择概率最大的类别作为预测类别；
2. softmax回归：可以看做是逻辑回归在多分类问题上的推广，其概率模型为

$$
p(y=c_k|x)=\sigma_k(w_kx+b_k),\  k=1,2,..,K
$$

其中,Softmax函数，或称归一化指数函数，是sigmoid函数的一种推广。它能将一个含任意实数的K维的向量 $z$  的“压缩”到另一个K维实向量  $\sigma (\mathbf {z} )$中，使得每一个元素的范围都在 $ (0,1)$之间，并且所有元素的和为1。该函数的形式通常按下面的式子给出：

$$
\begin{bmatrix}
y_1\\ 
y_2\\ 
\vdots\\
y_K
\end{bmatrix}=softmax(\begin{bmatrix}
z_1\\ 
z_2\\ 
\vdots\\
z_K
\end{bmatrix})
$$

对于每一个分量：

$$
\begin{align*} 
y_k=\sigma_k(z)&=\frac{e^{z_k}}{\sum_{j=1}^{K}e^{z_j}}\\
&=\frac{1}{1+\sum_{j\neq k}e^{z_j-z_k}}, \ \ k = 1,2...,K
\end{align*}
$$

事实上我们可以将其中一个类别的非归一化概率定为1来减少参数的数量，此时softmax回归模型可以简化为:

$$
\begin{align*} 
p(y=K|x)&=\frac{1}{1+\sum_{k=1}^{K-1}e^{w_kx+b_k}}\\
p(y=k|x)&=\frac{e^{w_kx+b_k}}{1+\sum_{k=1}^{K-1}e^{w_kx+b_k}},\ \ k=1,2,...,K-1
\end{align*}
$$

## 为什么后验概率可以表示为仿射变换的 sigmoid 函数

对二分类问题，类别$c_1$的后验概率可以通过贝叶斯公式表示为：

$$
\begin{align*} 
p(c_1|x)&=\frac{p(c_1)p(x|c_1)}{p(c_1)p(x|c_1)+p(c_2)p(x|c_2)}\\
&=\frac{1}{1+\frac{p(c_2)p(x|c_2)}{p(c_1)p(x|c_1)}}\\
&=\frac{1}{1+e^{-z(x)}}
\end{align*} 
$$

其中：

$$
z(x)=ln\frac{p(c_1)p(x|c_1)}{p(c_2)p(x|c_2)}
$$

接下来，只需要证明$z(x)$是$x$的线性函数即可。我们假设所有类条件概率为协方差相同的高斯函数：

$$
p(x|c_k)=\frac{1}{(2\pi)^{\frac{D}{2}}}\frac{1}{\left | \Sigma  \right |^{\frac{1}{2}}}exp(-\frac{1}{2}(x-\mu _k)^T\Sigma\ ^{-1}(x-\mu _k))
$$

代入 $z(x)$ 化简:

$$
\begin{align*} 
z(x)&=ln\frac{p(c_1)p(x|c_1)}{p(c_2)p(x|c_2)}\\
&=ln\left [\frac{p(c_1)}{p(c_2)}\cdot exp(\frac{1}{2}(x-\mu_2)^T\Sigma\ ^{-1}(x-\mu_2)) -\frac{1}{2} (x-\mu_1)^T\Sigma^{-1}(x-\mu_1)) \right ]\\
&=ln\frac{p(c_1)}{p(c_2)} + \frac{1}{2} [ x^T \Sigma\ ^{-1}x -x^T\Sigma^{-1}\mu_2-\mu_2^T\Sigma^{-1}x+\mu_2^T\Sigma^{-1}\mu_2- x^T \Sigma\ ^{-1}x \\
&\ \ \ +x^T\Sigma^{-1}\mu_1+\mu_1^T\Sigma^{-1}x-\mu_1^T\Sigma^{-1}\mu_1]\\
&=ln\frac{p(c_1)}{p(c_2)} +\frac{1}{2}\left [  2x^T\Sigma^{-1}(\mu_1-\mu_2) +\mu_2^T\Sigma^{-1}\mu_2-\mu_1^T\Sigma^{-1}\mu_1 \right ]\\
&=(\Sigma^{-1}(\mu_1-\mu_2) )^Tx+\frac{1}{2}\mu_2^T\Sigma^{-1}\mu_2-\frac{1}{2}\mu_1^T\Sigma^{-1}\mu_1+ln\frac{p(c_1)}{p(c_2)}
\end{align*} 
$$

得证，令：

$$
\begin{align*} 
w&=\Sigma^{-1}(\mu_1-\mu_2)\\
b&=\frac{1}{2}\mu_2^T\Sigma^{-1}\mu_2-\frac{1}{2}\mu_1^T\Sigma^{-1}\mu_1+ln\frac{p(c_1)}{p(c_2)}
\end{align*} 
$$

则:

$$
p(c_1|x)=\frac{1}{1+e^{-(wx+b)}}
$$

对softmax回归也有类似推导，可用一维高斯分布做启发式推导。

## 实战
以下使用sklearn.linear_model.LogisticRegression()来解决一个三分类问题。

官方API：

```python
LogisticRegression(penalty='l2', 
                   dual=False, 
                   tol=0.0001, 
                   C=1.0, 
                   fit_intercept=True, 
                   intercept_scaling=1, 
                   class_weight=None, 
                   random_state=None, 
                   solver='liblinear', 
                   max_iter=100, 
                   multi_class='ovr', 
                   verbose=0, 
                   warm_start=False, 
                   n_jobs=1)
```

参数|名称|说明
:---|:---|:---
penalty|正则化选择参数|‘l1’or ‘l2’, default: ‘l2’
dual|对偶|bool, default: False，对偶或者原始方法。Dual只适用于正则化相为l2 liblinear的情况，通常样本数大于特征数的情况下，默认为False
C|正则化系数λ的倒数|默认为1
fit_intercept|是否存在截距| bool, default: True
solver|优化算法|{牛顿法‘newton-cg’, 拟牛顿法‘lbfgs’, 梯度下降‘liblinear’, 随机梯度下降‘sag’}, default: ‘liblinear’
multi_class|分类方式|处理多元分类的方式，str, {‘ovr’, ‘multinomial’}, default:‘ovr’，ovr(one vs rest)会训练多个二分类的逻辑回归，multinomial会使用softmax回归
class_weight|类别权重|用于解决样本不均衡问题，dictor ‘balanced’, default: None
sample_weight|采样权重|用于解决样本不均衡问题的另一种方式，如果上面两种方法都用到了，那么样本的真正权重是class_weight*sample_weight.
max_iter|算法收敛最大迭代次数|仅在正则化优化算法为newton-cg, sag and lbfgs 才有用
tol|迭代终止判据的误差范围|float, default: 1e-4


```python
import numpy as np
import matplotlib.pyplot as plt
from sklearn import linear_model, datasets

# import some data to play with
iris = datasets.load_iris()
X = iris.data[:, :2]  # we only take the first two features.
Y = iris.target

h = .02  # step size in the mesh

logreg = linear_model.LogisticRegression(C=1e5)

# we create an instance of Neighbours Classifier and fit the data.
logreg.fit(X, Y)

# Plot the decision boundary. For that, we will assign a color to each
# point in the mesh [x_min, x_max]x[y_min, y_max].
x_min, x_max = X[:, 0].min() - .5, X[:, 0].max() + .5
y_min, y_max = X[:, 1].min() - .5, X[:, 1].max() + .5
xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
Z = logreg.predict(np.c_[xx.ravel(), yy.ravel()])

# Put the result into a color plot
Z = Z.reshape(xx.shape)
plt.figure(1, figsize=(10, 6))
plt.pcolormesh(xx, yy, Z, cmap=plt.cm.Paired)

# Plot also the training points
plt.scatter(X[:, 0], X[:, 1], c=Y, edgecolors='k', cmap=plt.cm.Paired)
plt.xlabel('Sepal length')
plt.ylabel('Sepal width')

plt.xlim(xx.min(), xx.max())
plt.ylim(yy.min(), yy.max())
plt.xticks(())
plt.yticks(())

plt.show()
```

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/02-41-36.png" width="60%" heigh="60%"></img>
</div>


## 评价
- 优点:
    1. 实现简单
    2. 速度快，存储资源低
    3. 可解释性强
    4. 输出后验概率，方便后续分析
- 缺点:
    1. 容易欠拟合，一般准确率较低
    2. 对数据质量要求高，需要手动处理缺失值、非线性特征

    