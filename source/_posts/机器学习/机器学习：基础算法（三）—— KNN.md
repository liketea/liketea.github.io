---
title: 机器学习：基础算法（三）—— KNN
date: 2018-10-20 20:21:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

K 邻近法（k-nearist neighbor,k-NN）是一种可用于分类和回归问题的非参数估计方法。对于分类问题，KNN 模型通过在训练集中寻找距离输入实例最近的前k个实例，将 k 个实例中数量最多的类别（多数表决）作为输出。knn 没有显式的训练过程，k 的选择、距离度量、分类决策是其三要素。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/22-30-10.png" width="80%" heigh="80%"></img>
</div>

## 模型

$$
y = arg\ \underset{c_j}{max}\ \sum_{x_i \in N_k}I(y_i = c_j),\ \ j=1,2,..k
$$

k值的选取会对knn算法的结果产生重大影响： k较小时，只有较小邻域内的点才会被考虑，训练误差小，但对邻域内的点很敏感，意味着模型复杂度高，容易过拟合，当$k=1$时，称为最邻近算法。通常采用交叉验证来确定最佳的k值。

## 策略
**多数表决**策略等价于0-1损失下的经验风险最小化。假设涵盖$N_k(x)$的区域的类别被预测为$c_j$，则0-1平均损失可以写作：

$$
L(k,c_j) = \frac{1}{k} \sum_{x_i \in N_k(x)}I(y_i\neq c_j)=1-\frac{1}{k} \sum_{x_i \in N_k(x)}I(y_i= c_j)
$$

可见，平均损失最小等价于多数表决。

关于向量间距离的度量，常用的是$L_p$距离，即差向量$(x_i-x_j)$的p范数。

$$
L_p(x_i,x_j)=\left ( \sum_{d=1}^{D}|x_i^d-x_j^d|^p \right )^{\frac{1}{p}}
$$

- $p=1$:称曼哈顿距离
- $p=2$:欧氏距离
- $p=\infty$:坐标距离的最大值$max|x_i^d-x_j^d|$

## 算法
当特征空间维数很大及训练样本很多时，通过线性扫描来寻找k邻近十分耗时，kd树（这里的k指的是特征空间维数k dimention）是一种更高效的搜索k邻近的方法。kd树包含构建kd树、在kd树中搜索两个步骤，下面以**最邻近**为例来说明这两个过程。

### 构建kd树
构建kd树的过程是一个递归地选择切分点对特征空间进行划分的过程。

输入：k维空间数据集T={$x_1,x_2,...,x_N$}，其中$x_i=(x_i^1,x_i^2,...,x_i^k)$
输出：kd树
（1）如果T为空则返回None
（2）定义kd树初始深度h=0
（2）创建新节点root，将所有实例按照第$l=h\%k+1$维坐标的中位数切分为左右两个区域$T_l,T_r$，将切分点实例保存在root节点中。然后令$h=h+1$，分别递归地以$T_l,T_r$为输入，构建root节点的左右子kd树$kd_l,kd_r$
（3）返回root

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/23-50-19.jpg" width="80%" heigh="80%"></img>
</div>

构建kd树的平均时间复杂度为$O(nlgn)$。

### 搜索kd树

输入：kd树，目标点x
输出：x的最邻近
（1）从根节点出发递归地**自上向下**找到x的叶节点：若x当前维的坐标小于切分点的坐标则移动到左节点，反之则移动到右节点，直至到达叶节点，将该叶节点作为当前最近点；
（2）从叶节点出发递归地**自下而上**地回退至根节点：
    （a）如果当前节点距离目标点更近，则以该节点作为当前最近点；
    （b）检查当前节点的另一个子节点对应的区域是否有更近的点：检查以目标点为圆心，以目标点与当前最近点间的距离为半径的超球体是否与另一子节点区域相交，如果相交则递归的在另一个子树中进行最邻近搜索，如果不相交，继续向上回退；
（3）当退回到根节点时，搜索结束，将最后的备选解作为x的最邻近；

kd树搜索的平均时间复杂度为$O(lgn)$，当空间维数接近样本数时，它的效率会迅速下降，几乎接近线性扫描。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/00-09-47.jpg" width="80%" heigh="80%"></img>
</div>

## 示例
```python
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from sklearn import neighbors, datasets

n_neighbors = 15

# import some data to play with
iris = datasets.load_iris()

# we only take the first two features. We could avoid this ugly
# slicing by using a two-dim dataset
X = iris.data[:, :2]
y = iris.target

h = .02  # step size in the mesh

# Create color maps
cmap_light = ListedColormap(['#FFAAAA', '#AAFFAA', '#AAAAFF'])
cmap_bold = ListedColormap(['#FF0000', '#00FF00', '#0000FF'])

plt.figure(figsize=(16,8))
i=1
for n_neighbors in range(1,41,5):
    # we create an instance of Neighbours Classifier and fit the data.
    clf = neighbors.KNeighborsClassifier(n_neighbors, weights=weights)
    clf.fit(X, y)

    # Plot the decision boundary. For that, we will assign a color to each
    # point in the mesh [x_min, x_max]x[y_min, y_max].
    x_min, x_max = X[:, 0].min() - 1, X[:, 0].max() + 1
    y_min, y_max = X[:, 1].min() - 1, X[:, 1].max() + 1
    xx, yy = np.meshgrid(np.arange(x_min, x_max, h),
                         np.arange(y_min, y_max, h))
    Z = clf.predict(np.c_[xx.ravel(), yy.ravel()])
    
    plt.subplot(2,4,i)
    i += 1
    # Put the result into a color plot
    Z = Z.reshape(xx.shape)
    plt.pcolormesh(xx, yy, Z, cmap=cmap_light)

    # Plot also the training points
    plt.scatter(X[:, 0], X[:, 1], c=y, cmap=cmap_bold,
                edgecolor='k', s=20)
    plt.xlim(xx.min(), xx.max())
    plt.ylim(yy.min(), yy.max())
    plt.title("k = %i"% (n_neighbors))
    
plt.show()
```


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/00-18-42.png)

## 评价
- 优点:
    1. 可分类可回归
    2. 实现简单
    3. 可解释性强
    4. 对异常值不敏感
- 缺点:
    1. 计算复杂度高
    2. 将所有特征看做同等重要，无法得到特征重要度