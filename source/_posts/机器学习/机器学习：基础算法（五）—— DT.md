---
title: 机器学习：基础算法（五）—— DT
date: 2018-10-20 20:19:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

决策树（decision tree）是一种基本的分类和回归方法。决策树模型是一个树状结构（二叉树或非二叉树），每个内部节点表示在某个特征上的测试，根据测试结果将样本划分到不同子节点，样本最终会落在某个叶子节点中，每个叶子节点的输出值代表了该样本的类别或值。一般通过模型叶子节点中样本集的加权经验熵（分类）或平方误差（回归）作为损失函数。其算法主要包括特征选择、决策树生成和决策树剪枝三个环节。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/dt.png" width="60%" heigh="60%"></img>
</div>

常见的决策树算法有 ID3、C4.5 和 CART，他们的模型一致，只是学习算法的三个过程有所不同：

类型|特征选择|决策树生成|决策树剪枝|特征类型|输出值|是否二叉树|问题类型
---|:---|:---|:---|:---|:---|:---|:---
ID3|每次选择能够带来最大信息增益的特征作为最优切分特征|按切分特征的不同取值划分出多颗子树|按照叶节点上的经验熵在剪枝前后的变化决定是否剪枝|离散|类别众数|否|分类
C4.5|每次选择能够带来最大信息增益比的特征作为最优切分特征|按切分特征的不同取值划分出多颗子树|按照叶节点上的经验熵在剪枝前后的变化决定是否剪枝|离散|类别众数|否|分类
分类CART|每次选择条件基尼指数最小的特征和切分点为最优切分特征和最优切分点|按切分特征和切分点划分为两颗子树|通过交叉验证在子树序列中选最优子树|离散/连续|类别众数|是|分类
回归CART|每次选择平方误差最小的特征和切分点为最优切分特征和最优切分点|按切分特征和切分点划分为两颗子树|通过交叉验证在子树序列中选最优子树|离散/连续|子集均值|是|回归
    
不同种类的决策树均可形式化表示为以下统一模型：

$$
T(x,c_j,R_j) = \sum_{i=1}^{J}c_jI(x \in R_j)
$$

- $J$：决策树叶节点数；
- $R_j$：第 j 个叶节点对应的特征空间区域；
- $c_j$：第 j 个叶节点的输出值；

模型的不同视角：叶节点（树） = if-then规则（逻辑） = 方块区域（空间）

- 决策树是**if-then规则**的集合：每条路径或叶节点都对应了特征集上的一组if-then规则，这些规则互斥且完备；
- 决策树是特征空间不同**区域上的条件概率分布**：每条路径相当于对特征空间进行区域划分（区域边界垂直于特征轴），每个叶节点对应了特征空间中一个互斥且完备的方块区域，叶节点中的值代表了该区域上的类别或值；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/01-11-52.jpg)

决策树学习本质上是从训练集中归纳出一组分类规则，与训练数据集不相矛盾的决策树可能有多个也可能一个也没有，我们需要的是一个与训练数据矛盾较小同时具有很好泛化能力的决策树。

从所有可能的决策树中选择最优决策树是NP完全问题，通常采用启发式的**贪心算法**，递归地选择当前最优的特征，根据该特征对训练集进行划分，直至子集能够被基本正确划分，则构建叶子节点，将子集中的占多数的类别或者子集均值作为叶子节点的输出，这个过程叫做**决策树的生成**。

决策树的生成过程每次只考虑局部最优，最终会**自上而下**产生一棵完全生长的树，很可能导致过拟合，我们需要对已生成的树**自下而上**进行剪枝，决策树剪枝需要考虑全局最优，递归地去掉过于细分的叶节点，使其回退到其父节点，直至损失函数（带正则项）不再下降。

## ID3
### 特征选择——最大信息增益
信息增益（information gain）又称互信息（mutual imformation）表示在得知特征X的信息后而使类Y的不确定性减少的程度，记做 $g(D|A)$。

$$
\left\{\begin{matrix}
\begin{align*}
g(D,A)&=H(D)-H(D|A)\\ 
H(D)=&-\sum_{i=1}^{N}p(y=c_k) \cdot lgp(y=c_k)\\ 
H(D|A)&=\sum_{g=1}^{G}H(D|A=A_g) \cdot p(A=A_g)\\
&=-\sum_{g=1}^{G}\sum_{k=1}^{K}p(y=c_k|A=A_g) \cdot lgp(y=c_k|A=A_g) \cdot p(A=A_g)\\
&=-\sum_{g=1}^{G}\sum_{k=1}^{K}p(y=c_k,A=A_g) \cdot lgp(y=c_k|A=A_g)
\end{align*}
\end{matrix}\right.
$$

其中y有K个类别 $\{c_1,c_2,...,c_K\}$，特征A有G个取值 $\{A_1,A_2,...,A_G\}$

我们可以通过极大似然估计来计算各个概率：

$$
\left\{\begin{matrix}
\begin{align*}
&p(y=c_k)=\frac{N_{y=c_k}}{N}\\
&p(y=c_k|A=A_g)=\frac{N_{y=c_k,A=A_g}}{N_{A=A_g}}\\
&p(y=c_k,A=A_g)=\frac{N_{y=c_k,A=A_g}}{N}
\end{align*}
\end{matrix}\right.
$$

**选择信息增益最大的特征作为最优切分特征**：

$$
A^* = \underset{A}{max} \ g(D,A)
$$

### 决策树的生成
输入：训练数据集$D$，特征集$A$，阈值$\epsilon $

输出：决策树

（1）几种边界情况：

- 如果D为空，则T为单节点树，将父节点中实例数最大的类作为该节点的输出，返回T；
- 如果D中所有实例都属于同一类，则T为单节点树，将该类作为节点的输出，返回T；
- 如果A为空，则T为单节点树，将D中实例最数最大的类作为该节点输出，返回T；

（2）否则，计算A中各特征对D的信息增益，选择信息增益最大的特征$A_g$，如果其信息增益小于阈值$\epsilon $，则T为单节点树，将D中实例最数最大的类作为该节点输出，返回T；

（3）否则，构建节点，并按照$A_g$的每一种可能取值将D划分为若干子集$D_i$，以$D_i$为训练集，以$A-{A_g}$为特征集，递归地调用以上步骤构建子树$T_i$，由节点和子树构成数T，返回T；
    
### 决策树的剪枝
决策树的剪枝往往通过极小化整体的损失函数（等价于带正则的极大似然估计）来实现，损失函数可以通过叶节点中的加权熵来刻画：

$$
\begin{align*} 
L_\lambda(T)&=\sum_{j=1}^{J}N_j H(T_j)+\lambda J\\
&=-\sum_{j=1}^{J}N_j\sum_{k=1}^{K}p(c_k|j)lgp(c_k|j)+\lambda J\\
&=-\sum_{j=1}^{J}N_j\sum_{k=1}^{K}\frac{N_{j,k}}{N_j}lg\frac{N_{j,k}}{N_j}+\lambda J\\
&=-\sum_{j=1}^{J}\sum_{k=1}^{K}N_{j,k}lg\frac{N_{j,k}}{N_j}+\lambda J
\end{align*}
$$

- $N_j$：第j个叶节点中样本数
- $N_{j,k}$：第j个叶节点中$c_k$类的样本数
- $H(T_j)$：第j个叶节点中的熵
- $J$：叶子节点数，可以用来衡量模型复杂度
- $\lambda$：正则化项系数

决策树剪枝算法：递归地从叶节点向上回缩，如果回缩后的损失函数下降则进行剪枝，最终得到损失函数最小的子树$T_\lambda$。

## C 4.5
### 特征选择——最大信息增益比
以信息增益作为选取最优特征的标准，倾向于选择取值较多的特征，使用信息增益比(information gain ratio)可以对这一问题进行校正：

$$
\begin{align*} 
g_R(D,A)&=\frac{g(D,A)}{H(A)}\\
&=\frac{g(D,A)}{-\sum_{g=1}^{G}p(A=A_g)lgp(A=A_g)}\\
&=\frac{g(D,A)}{-\sum_{g=1}^{G} \frac{N_g}{N}lg\frac{N_g}{N}}\\
\end{align*}
$$

- $g(D,A)$：特征$A$所带来的信息增益
- $H(A)$：特征$A$本身的熵（注意不是$H(D)$）

**选择信息增益比最大的特征作为最优切分特征**：

$$
A^* = \underset{A}{max} \ g_R(D,A)
$$

C4.5与ID3的树生成和剪枝过程一样，只需要将信息增益换做信息增益比，不再赘述。
## CART
分类回归树（classification and regression tree,CART）模型由Breiman等人在1984年提出，是应用最广泛的决策树学习方法，与ID3和C4.5相比有以下几点不同:

1. 树的类型：CART决策树是二叉树，另外两种可以是非二叉树；
2. 适用范围: CART既可用于分类也可用于回归，而另外两种只用于分类；
3. 特征类型：CART特征可以是离散也可以是连续的，另外两种只能处理离散特征，对于连续特征需要先进行离散化；
4. 生成过程：CART选择具有最小基尼指数或平方误差的特征和切分点作为最优切分特征和切分点，从节点划分出两颗子树；另外两种只需要选择具有最大信息增益(比)的特征作为切分特征，从节点划分出多颗子树；
5. 剪枝过程：CART通过不断回缩能带来最小损失下降（不带正则）的分支来得到一组子树序列$T_0,T_1,...,T_n$，然后通过交叉验证选出其中最有子树$T_\lambda$

### 特征选择
#### CART 分类树——最小条件基尼指数
**基尼指数**：与熵类似，基尼指数也可以作为随机变量不纯度的度量，可定义为

$$
Gini(D)=\sum_{k=1}^{K}p(y=c_k)(1-p(y=c_k))
$$

**条件基尼指数**：在特征$A$的条件下，集合$D$的基尼指数定义为

$$
\begin{align*} 
Gini(D|A)&=\sum_{g=1}^{G}p(A=A_g)Gini(D|A=A_g)\\
&=\sum_{g=1}^{G}p(A=A_g)\sum_{k=1}^{K}p(y=c_k|A=A_g)(1-p(y=c_k|A=A_g))\\
&=\sum_{g=1}^{G}\sum_{k=1}^{K}p(y=c_k,A=A_g)(1-p(y=c_k|A=A_g))
\end{align*}
$$

**选择条件基尼指数最小的特征和切分点作为最优切分特征和切分点**：CART分类树在做节点分裂时，会在所有可能的特征A以及它们所有可能的切分点$A_g$中选择条件基尼系数最小的特征和切分点，按照每个样本在该特征上的值是否等于$A_g$来决定将其划分至左子树还是右子树。我们可以通过以下方式来计算数据集$D$关于切分特征$A$和切分点$A_g$的条件基尼指数

$$
\begin{align*} 
A^*,A_g^* =& \underset{A,A_g}{min} \ Gini(D|A,A_g)\\
=&p(A=A_g)Gini(D|A=A_g)+p(A\neq A_g)Gini(D|A\neq A_g)\\
=&p(A=A_g)\sum_{k=1}^{K}p(y=c_k|A=A_g)(1-p(y=c_k|A=A_g))+\\
&p(A\neq A_g)\sum_{k=1}^{K}p(y=c_k|A\neq A_g)(1-p(y=c_k|A\neq A_g))
\end{align*}
$$

其中各概率可以通过极大似然估计来求：

$$
\left\{\begin{matrix}
p(A=A_g)=\frac{N_g}{N}\\ 
p(A\neq A_g)=\frac{N_{\bar{g}} }{N}\\ 
p(y=c_k|A=A_g)=\frac{N_{g,k}}{N_g}\\ 
p(y=c_k|A\neq A_g)=\frac{N_{\bar{g},k}}{N_{\bar{g}}}
\end{matrix}\right.
$$

基尼系数-熵之半-分类误差率的关系:

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/18-55-34.jpg" width="50%" heigh="50%"></img>
</div>

#### 回归CART——平方误差
CART回归树一般将叶节点中所有样本的均值作为输出，在做节点分裂时，会在所有可能的特征A以及它们所有可能的切分点$A_g$中选择平方误差最小的特征和切分点，按照每个样本在该特征上的值与切分点的值比较，小于等于切分点的样本被划分到左子树，大于切分点的样本被分到右子树。我们可以通过以下方式来计算数据集$D$关于切分特征$A$和切分点$A_g$的平方误差

$$
A^*,A_g^* = \underset{A,A_g}{min} [\sum_{x_i \in R_1}(y_i-c_1)^2+\sum_{x_i \in R_2}(y_i-c_2)^2]
$$

其中:

$$
\left\{\begin{matrix}
R_1(A,A_g)=\left \{ x|x^A\leqslant A_g) \right \}\\
R_2(A,A_g)=\left \{ x|x^A> A_g) \right \}\\
c_1 = average(y_i | x_i \in R_1)\\
c_2= average(y_i | x_i \in R_2)
\end{matrix}\right.
$$

### 决策树的生成
CART决策树生成过程与ID3一致，只需将特征选择部分替换即可。

### 决策树的剪枝
回看ID3决策树的剪枝过程,是在确定了正则化系数$\lambda$后，递归地收缩叶子节点，如果收缩后损失函数下降则进行剪枝的过程。而CART决策树则是通过**交叉验证**的方式从**子树序列**中选择最优子树，相当于确定了一个最优的正则项$\lambda $来进行剪枝，具体来说，可分为两步：

1. 得到子树序列{$T_0,T_1,...,T_n$}：计算当前决策树中所有内部节点的损失函数下降(不带正则)，选择其中损失下降最小的内部节点，进行收缩剪枝，得到子树$T_1$，递归地在子树$T_1$中执行此操作最终可获取一个子树序列{$T_0,T_1,...,T_n$}；
2. 交叉验证选择最优子树$T_\lambda$：利用独立的验证数据集，测试子树序列中各棵子树的平方误差或基尼指数，平方误差或基尼指数最小的子树被认为是最优的决策树；


在剪枝过程中，子树的损失函数可表示为：

$$
L_\lambda(T)=L(T)+\lambda J
$$

Breiman等人证明：通过以上递归剪枝的方法所得到的子树序列{$T_0,T_1,...,T_n$}对应于递增的正则化系数$\lambda_0<\lambda_1<...<\lambda_n<+\infty$所产生的一系列区间$[\lambda_i,\lambda_{i+1}),i=0,1,...,n$。

具体地，从整棵树$T_0$开始剪枝，对$T_0$的任意内部节点t，以t为单节点树的损失函数为：

$$
L_\lambda(t)=L(t)+\lambda
$$

以t为根节点的子树$T_t$的损失为：

$$
L_\lambda(T_t)=L(T_t)+\lambda J_t
$$

假设通过剪枝损失函数下降了：

$$
L_\lambda(T_t)-L_\lambda(t)=L(T_t)-L(t)+\lambda (J_t-1)>0
$$

即:

$$
\frac{L(t)-L(T_t)}{J_t-1}<\lambda
$$

即是说：

- 正则化系数$\lambda$代表了决策树树生成过程中的不带正则的**最小损失函数下降**，只有节点分裂后所带来的损失下降（平摊到叶节点上的均值）超过了这个阈值，节点才应分裂；
- 反过来说，则化系数$\lambda$代表了决策树剪枝过程中的不带正则的**最大损失函数下降**，那些损失下降不足$\lambda$的分支都会被剪掉；

## 实战
以下通过sklearn.tree中的ecisionTreeClassifier决策树模型为例，通过在鸢尾花数据上的应用讨论决策树的实际用法。

```python
import numpy as np
import pandas as pd
from sklearn.datasets import load_iris
from sklearn import tree
from sklearn.tree import DecisionTreeClassifier

from itertools import product
import pydotplus 

from IPython.display import Image 
import matplotlib.pyplot as plt

%matplotlib inline
```

### 数据集


```python
# 使用鸢尾花数据
iris = load_iris()
data = pd.DataFrame(iris.data,columns=iris.feature_names)
data['target']=iris.target
data.head()
```

<div>
<style>
    .dataframe thead tr:only-child th {
        text-align: right;
    }

    .dataframe thead th {
        text-align: left;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>sepal length (cm)</th>
      <th>sepal width (cm)</th>
      <th>petal length (cm)</th>
      <th>petal width (cm)</th>
      <th>target</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>5.1</td>
      <td>3.5</td>
      <td>1.4</td>
      <td>0.2</td>
      <td>0</td>
    </tr>
    <tr>
      <th>1</th>
      <td>4.9</td>
      <td>3.0</td>
      <td>1.4</td>
      <td>0.2</td>
      <td>0</td>
    </tr>
    <tr>
      <th>2</th>
      <td>4.7</td>
      <td>3.2</td>
      <td>1.3</td>
      <td>0.2</td>
      <td>0</td>
    </tr>
    <tr>
      <th>3</th>
      <td>4.6</td>
      <td>3.1</td>
      <td>1.5</td>
      <td>0.2</td>
      <td>0</td>
    </tr>
    <tr>
      <th>4</th>
      <td>5.0</td>
      <td>3.6</td>
      <td>1.4</td>
      <td>0.2</td>
      <td>0</td>
    </tr>
  </tbody>
</table>
</div>

```python
# 多分类问题
data.target.unique(),iris.target_names
```

    (array([0, 1, 2]), array(['setosa', 'versicolor', 'virginica'], dtype='<U10'))

### 决策树模型


```python
DecisionTreeClassifier(criterion='gini', 
                      splitter='best', 
                      max_depth=None, 
                      min_samples_split=2, 
                      min_samples_leaf=1, 
                      min_weight_fraction_leaf=0.0, 
                      max_features=None, 
                      random_state=None, 
                      max_leaf_nodes=None, 
                      min_impurity_decrease=0.0, 
                      min_impurity_split=None, 
                      class_weight=None, 
                      presort=False)

```

参数|名称|说明
:---|:---|:---
criterion|特征选择标准|可以使用"gini"或者"entropy"，前者代表基尼系数，后者代表信息增益
splitter|特征划分点选择标准|可以使用"best"或者"random"。前者在特征的所有划分点中找出最优的划分点。后者是随机的在部分划分点中找局部最优的划分点
max_features|划分时考虑的最大特征数|可以使用很多种类型的值，默认是"None",意味着划分时考虑所有的特征数；如果是"log2"意味着划分时最多考虑log2N个特征；如果是"sqrt"或者"auto"意味着划分时最多考虑N‾‾√个特征。如果是整数，代表考虑的特征绝对数。如果是浮点数，代表考虑特征百分比
max_depth|决策树最大深度|决策树的最大深度，默认可以不输入，如果不输入的话，决策树在建立子树的时候不会限制子树的深度
min_samples_split|内部节点再划分所需最小样本数|限制了子树继续划分的条件，如果某节点的样本数少于min_samples_split，则不会继续再尝试选择最优特征来进行划分。 默认是2
min_samples_leaf|叶子节点最少样本数|限制了叶子节点最少的样本数，如果某叶子节点数目小于样本数，则会和兄弟节点一起被剪枝。 默认是1
min_weight_fraction_leaf|叶子节点最小的样本权重和|限制了叶子节点所有样本权重和的最小值，如果小于这个值，则会和兄弟节点一起被剪枝。 默认是0
max_leaf_nodes|最大叶子节点数|通过限制最大叶子节点数，可以防止过拟合，默认是"None”，即不限制最大的叶子节点数
class_weight|类别权重|指定样本各类别的的权重，主要是为了防止训练集某些类别的样本过多，导致训练的决策树过于偏向这些类别。这里可以自己指定各个样本的权重，或者用“balanced”，如果使用“balanced”，则算法会自己计算权重，样本量少的类别所对应的样本权重会高
min_impurity_split|节点划分最小不纯度|限制了决策树的增长，如果某节点的不纯度(基尼系数，信息增益，均方差，绝对差)小于这个阈值，则该节点不再生成子节点。即为叶子节点
presort|数据是否预排序|默认是False不排序。一般来说，如果样本量少或者限制了一个深度很小的决策树，设置为true可以让划分点选择更加快，决策树建立的更加快。如果样本量太大的话，反而没有什么好处

### 可视化

#### 绘制空间划分图


```python
# iris数据，限定两维特征
iris = load_iris()
X = iris.data[:, [0, 1]]
y = iris.target
feature_names =[f for index,f in enumerate(iris.feature_names) if index in [0,1]]

i = 1
num = 8
print_trees = {}
plt.figure(figsize=(2*num,num))

for max_depth in range(1,1+num):
    # 训练模型，限制树的最大深度4
    clf = DecisionTreeClassifier(max_depth=max_depth)
    clf = clf.fit(X, y)
    print_trees[max_depth] = print_tree(clf,feature_names=feature_names,class_names=iris.target_names)
    plt.subplot(2, 4, i)
    i += 1
    # 画图
    
    x_min, x_max = X[:, 0].min() - 1, X[:, 0].max() + 1
    y_min, y_max = X[:, 1].min() - 1, X[:, 1].max() + 1
    xx, yy = np.meshgrid(np.arange(x_min, x_max, 0.1),
                         np.arange(y_min, y_max, 0.1))

    Z = clf.predict(np.c_[xx.ravel(), yy.ravel()])
    Z = Z.reshape(xx.shape)
    plt.xlabel('max_depth=%s'%max_depth)

    plt.contourf(xx, yy, Z, alpha=0.4)
    plt.scatter(X[:, 0], X[:, 1], c=y, alpha=0.8)
plt.show()
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_9_0.png)


#### 绘制树结构


```python
def print_tree(clf,feature_names,class_names):
    """
    clf：训练好的决策树
    feature_names:特征名
    class_names：类别名
    """
    dot_data = tree.export_graphviz(clf, 
                                    out_file=None, 
                                    feature_names=feature_names,  
                                    class_names=class_names,  
                                    filled=True, 
                                    rounded=True,  
                                    special_characters=True)  

    graph = pydotplus.graph_from_dot_data(dot_data)  
    return Image(graph.create_png())
```


```python
print_trees[1]
```

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_12_0.png" width="30%" heigh="30%"></img>
</div>

```python
print_trees[3]
```

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_13_0.png" width="80%" heigh="80%"></img>
</div>

```python
print_trees[5]
```

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_14_0.png" width="80%" heigh="80%"></img>
</div>

```python
print_trees[8]
```

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_15_0.png" width="80%" heigh="80%"></img>
</div>

## 评价
- 优点：
    1. 可解释性强：决策树等价于一组if-then规则的集合，和人们自然做决策的方式相同；且易于可视化，方便对决策过程的检查；
    2. 数据准备工作简单：即可用于离散特征也可用于连续特征，对缺失值和异常值不敏感，也不需要额外地对特征进行标准化；
    3. 效率高：决策树一次构建可反复使用，每次预测时间复杂度与决策树的高度成正比
    4. 方便集成：决策树模型可以方便的扩展至复杂的集成模型如随机森林和GBDT；决策树叶子节点的位置本身代表了特征之间的任意组合，可进一步作为新的特征来训练新的模型；
- 缺点：
    1. 容易过拟合: 可通过一些正则化手段限制决策树的复杂度；
    2. 当分类类别太多时计算比较复杂
    3. 通常情况下精确度不吐其他算法