---
title: 机器学习：集成学习（三）—— GBDT
date: 2018-10-20 20:23:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20-18-28.jpg)

> GBDT（Gradient Boosted Decision Tree，梯度提升决策树，常被戏称为 “广播电台”），又叫MART（Multiple Additive Regression Tree，多重累加回归树），是通过回归树不断拟合当前模型的残差，并将所得到的残差不断累加至当前模型来得到最终模型的boosting方法。

GBDT 是老牌 ensemble 模型，在10年前那个属于ensemble的年代，它既在学术界掀起了研究热点，也在工业界甚至比赛界都有广泛的应用。

## 原理篇
我们可以从机器学习的三个要素出发来考察GBDT方法：
1. 模型（假设空间）：是由一组含参数的函数所组成的函数空间，其中每个函数以特征为输入，以标签为输出；
2. 策略（损失函数）：如何在假设空间中寻找最优函数；
3. 算法（计算方法）：参数的具体求解过程；

```
GBDT = 提升树 + 梯度提升算法 
     = (决策树加法模型 + 经验风险最小化 + 前向分步算法) + 梯度提升算法
```

### 提升树（boosting tree）
提升树 = 决策树加法模型 + 经验风险最小化 + 前向分步算法

#### 加法模型（additive model）
**加法模型**：是由多个基学习器通过线性组合得到最终预测值的一种集成学习方法，本质上是一种特征转换方法

$$
f(x) = \sum_{m=1}^{M}\beta _mb(x;\gamma _m)
$$

- $b(x;\gamma _m)$：基学习器；
- $\beta _m$：基学习器的系数；

**决策树加法模型**：基学习器是决策树的加法模型

$$
\begin{align*}
f_M(x) &= \sum_{m=1}^{M}T(x;\gamma _m)\\
T(x;\gamma)&= \sum_{j=1}^{J}c_j[x \in R_j]
\end{align*}
$$

- $f_M(x)$: 第M次迭代后的集成模型；
- $T(x;\gamma_m)$：第m次迭代的基模型（决策树），对分类问题是二叉分类树，对回归问题是二叉回归树，以下以回归树为例;
- $\gamma$：{$(R_1,c_1),(R_2,c_2),...,(R_J,c_J)$}表示树的区域划分和各区域上的预测值，J是回归树的复杂度即叶子节点数；

#### 经验风险最小化（ERM）
在给定训练数据及损失函数$L(y,f(x))$的前提下，学习加法模型$f(x)$成为**经验风险最小化**问题：

$$
\underset{\beta _m,\gamma _m,m=1,2,..,M}{argmin} \sum_{i=1}^{N} L(y_i, \sum_{m=1}^{M}\beta _mb(x_i;\gamma _m))
$$

如果采用平方差损失函数：

$$
L(y_i,f(x_i))=(y_i - \sum_{m=1}^{M}\beta _mb(x_i;\gamma _m))^2
$$

#### 前向分步算法（forward stagewise algorithm）
上述经验风险最小化问题通常是一个很复杂的优化问题，前向分步算法是一种简便的近似迭代求解方法：
1. 首先初始化目标函数；
2. 然后从前向后，每一步只学习一个基学习器，用来拟合上一步得到的目标函数与真实值的残差；
3. 将当前基学习器与上一步得到的目标函数相加得到新的目标函数；
4. 迭代2、3，逐步逼近最终的目标函数$f(x)$。

**前向分步算法：**
1. 输入：训练数据集$ T = \{ (x_1,y_1),(x_2,y_2),...,(x_N,y_N) \} $；损失函数$L(y,f(x)$;基学习器${b(x;\gamma)}$
2. 输出：加法模型$f(x)$
3. 步骤：
    1. 初始化目标函数：$f_0(x)=0$;
    2. 对$m=1,2,...,M$
        1. $f_m(x)=f_{m-1}(x)+\beta _mb(x;\gamma _m)$
        2. 极小化损失函数，得到$\beta _m,\gamma _m$
$$
\begin{align*}
\beta _m,\gamma _m &=  arg \underset{\beta,\gamma}{min}\sum_{i=1}^{N}L(y_i,f_m(x))\\
&= arg \underset{\beta,\gamma}{min}\sum_{i=1}^{N}L(y_i,f_{m-1}(x_i) + \beta b(x_i;\gamma))
\end{align*}
$$              
    3. 得到加法模型
    $$
    f(x) = f_M(x) =  \sum_{m=1}^{M}\beta _mb(x;\gamma _m)
    $$

**回归树**：对回归问题的提升树算法来说，只需简单地拟合当前模型的残差：

$$
\begin{align*}
&f_0(x)=0\\
&f_m(x)=f_{m-1}(x)+T(x;\gamma _m)\\
&\gamma _m = arg \underset{\gamma _m}{min} \sum_{i=1}^{N} L(y_i,f_{m-1}(x)+T(x;\gamma_m))= arg \underset{\gamma _m}{min} \sum_{i=1}^{N}( y_i-f_{m-1}(x)-T(x;\gamma_m))^2\\
&f_M(x)=\sum_{m=1}^{M}T(x; \gamma _m)\\
\end{align*}
$$

**分类树**: GBDT 最初用来解决回归问题，但只需稍加转换就可以用它来解决多分类问题，核心是将分类问题转化为回归问题。

在多分类问题中，假设有k个类别，那么每一轮迭代实质是构建了k棵树，对某个样本x的预测值为：

$$
f_1(x),f_2(x),...,f_k(x)
$$

在这里我们仿照多分类的逻辑回归，使用softmax来产生概率，则属于某个类别c的概率为:

$$
p_c = exp(f_c(x))/\sum_{k}^{K}exp(f_k(x))
$$

此时该样本的loss即可以用logitloss来表示，并对f1~fk都可以算出一个梯度，f1~fk便可以计算出当前轮的残差，供下一轮迭代学习。

最终做预测时，输入的x会得到k个输出值，然后通过softmax获得其属于各类别的概率即可。

### 梯度提升（gradient boosting）
当损失函数是平方损失或者指数损失时，求解较简单，但对一般损失函数并不那么容易，Freidman提出了梯度提升算法，它的基本思想是：**用损失函数在当前模型的负梯度(函数空间)作为残差的近似值来拟合决策树**。对于平方损失函数，它就是通常所说的残差。

$$
T(x;\gamma_m)=f_m(x)-f_{m-1}(x)=-\left [ \frac{\partial L(y,f(x_i))}{\partial f(x_i)} \right ]_{f(x)=f_{m-1}(x)}
$$

**梯度提升算法**

1. 输入：训练数据集T={$(x_1,y_1),(x_2,y_2),...,(x_N,y_N)$}，损失函数$L(y,f(x))$
2. 输出：回归树$\hat{f}(x)$
3. 算法：
    1. 初始化：$f_0(x)=arg \underset{c}{min}\sum_{i=1}^{N}L(y_i,c)$
    2. 对m=1,2,...,M
        1. 对i=1,2,...,N，计算
$$
r_{mi}=-\left [ \frac{\partial L(y,f(x_i))}{\partial f(x_i)} \right ]_{f(x)=f_{m-1}(x)}
$$
        2. 对 $r_{mi}$ 拟合一个回归树，得到第m棵树的叶节点区域$R_{mj},j=1,2,...,J$
        3. 对 $j=1,2,...,J$，计算每个叶节点区域的输出值：$c_{mj}=arg \underset{c}{min}\sum_{x \in R_{mj}}L(y_i,f_{m-1}(x_i)+c)$
        4. 更新模型 $f_m(x)=f_{m-1}(x)+\sum_{j=1}^{J}c_{mj}[x \in R_{mj}]$
    3. 得到回归树: $\hat{f}(x)=\sum_{m=1}^{M}\sum_{j=1}^{J}c_{mj}[x \in R_{mj}]$


## 应用篇
在sacikit-learn中，GradientBoostingClassifier为GBDT的分类类， 而GradientBoostingRegressor为GBDT的回归类。两者的参数类型完全相同，当然有些参数比如损失函数loss的可选择项并不相同。这些参数中，类似于Adaboost，我们把重要参数分为两类，第一类是Boosting框架的重要参数，第二类是弱学习器即CART回归树的重要参数。

```python
# 分类树
class sklearn.ensemble.GradientBoostingClassifier(loss=’deviance’, 
                                                  learning_rate=0.1, 
                                                  n_estimators=100, 
                                                  subsample=1.0, 
                                                  
                                                  criterion=’friedman_mse’,
                                                  min_samples_split=2, 
                                                  min_samples_leaf=1, 
                                                  min_weight_fraction_leaf=0.0, 
                                                  max_depth=3, 
                                                  min_impurity_decrease=0.0, 
                                                  min_impurity_split=None, 
                                                  init=None, 
                                                  random_state=None, 
                                                  max_features=None, 
                                                  verbose=0, 
                                                  max_leaf_nodes=None, 
                                                  warm_start=False, 
                                                  presort=’auto’)
# 回归树
class sklearn.ensemble.GradientBoostingRegressor(loss=’ls’, 
                                                 learning_rate=0.1, 
                                                 n_estimators=100, 
                                                 subsample=1.0, 
                                                 
                                                 criterion=’friedman_mse’, 
                                                 min_samples_split=2, 
                                                 min_samples_leaf=1, 
                                                 min_weight_fraction_leaf=0.0, 
                                                 max_depth=3, 
                                                 min_impurity_decrease=0.0, 
                                                 min_impurity_split=None, 
                                                 init=None, 
                                                 random_state=None, 
                                                 max_features=None, 
                                                 alpha=0.9, 
                                                 verbose=0, 
                                                 max_leaf_nodes=None, 
                                                 warm_start=False, 
                                                 presort=’auto’)
```
### boosting框架参数
参数|说明|调参
---|---|---
loss|损失函数|对于分类树，默认为对数似然函数："deviance"。一般来说，推荐使用默认的"deviance"。它对二元分离和多元分类各自都有比较好的优化。而指数损失函数"deviance"等于把我们带到了Adaboost算法。
learning_rate|学习率|fk(x)=fk−1(x)+νhk(x)，ν的取值范围为0<ν≤1，默认为1，较小的ν意味着我们需要更多的弱学习器的迭代次数，n_estimators和learning_rate要一起调参
n_estimators|最大迭代次数|默认100，越大越容易过拟合
subsample|无放回样本采样|推荐在[0.5, 0.8]之间，默认是1.0，即不使用子采样，越小方差越小偏差越大
alpha|分位数|这个参数只有GradientBoostingRegressor有，当我们使用Huber损失"huber"和分位数损失“quantile”时，需要指定分位数的值。默认是0.9，如果噪音点较多，可以适当降低这个分位数的值。

### 基学习器参数
由于GBDT使用了CART回归决策树，因此它的参数基本来源于决策树类，也就是说，和DecisionTreeClassifier和DecisionTreeRegressor的参数基本类似。

参数|说明|调参
---|---|---
max_depth|决策树最大深度|数据少或者特征少的时候可以不管这个值。如果模型样本量多，特征也多的情况下，推荐限制这个最大深度，具体的取值取决于数据的分布。常用的可以取值10-100之间
max_features|划分时考虑的最大特征数|可以使用很多种类型的值，默认是"None",意味着划分时考虑所有的特征数；如果是"log2"意味着划分时最多考虑log2N个特征；如果是"sqrt"或者"auto"意味着划分时最多考虑N‾‾√个特征。如果是整数，代表考虑的特征绝对数。如果是浮点数，代表考虑特征百分比，即考虑（百分比xN）取整后的特征数。其中N为样本总特征数。一般来说，如果样本特征数不多，比如小于50，我们用默认的"None"就可以了，如果特征数非常多，我们可以灵活使用刚才描述的其他取值来控制划分时考虑的最大特征数，以控制决策树的生成时间。
min_samples_split|内部节点再划分所需最小样本数| 这个值限制了子树继续划分的条件，如果某节点的样本数少于min_samples_split，则不会继续再尝试选择最优特征来进行划分，默认为2，如果样本量不大，不需要管这个值。如果样本量数量级非常大，则推荐增大这个值。
min_samples_leaf|叶子节点最少样本数|默认为1，如果某叶子节点数目小于样本数，则会和兄弟节点一起被剪枝，如果样本量不大，不需要管这个值。如果样本量数量级非常大，则推荐增大这个值。
min_weight_fraction_leaf|叶子节点最小的样本权重和|这个值限制了叶子节点所有样本权重和的最小值，如果小于这个值，则会和兄弟节点一起被剪枝。 默认是0，就是不考虑权重问题。一般来说，如果我们有较多样本有缺失值，或者分类树样本的分布类别偏差很大，就会引入样本权重，这时我们就要注意这个值了
max_leaf_nodes|最大叶子节点数|通过限制最大叶子节点数，可以防止过拟合，默认是"None”，即不限制最大的叶子节点数。如果加了限制，算法会建立在最大叶子节点数内最优的决策树。如果特征不多，可以不考虑这个值，但是如果特征分成多的话，可以加以限制，具体的值可以通过交叉验证得到。
min_impurity_split|节点划分最小不纯度|这个值限制了决策树的增长，如果某节点的不纯度(基于基尼系数，均方差)小于这个阈值，则该节点不再生成子节点。即为叶子节点 。一般不推荐改动默认值1e-7

## 总结篇
优点：

1. 不需要做过多的数据预处理，特征可以是离散的或者连续的，不需要处理缺失值和异常值；
2. 相当于是一种非线性的特征变换，表达能力强（叶节点对应路径上的节点相当于特征选择，叶节点位置相当于特征组合）；
3. 模型解释性好；

缺点：

1. GBDT是一个串行过程，不容易并行化，计算复杂度高；
2. 同时其不太适合高维稀疏特征；

## 参考
1. [GBDT详解上 + 下 + 后补](http://www.flickering.cn/machine_learning/2016/08/gbdt%E8%AF%A6%E8%A7%A3%E4%B8%8A-%E7%90%86%E8%AE%BA/)
2. 《统计学习方法》
3. [GBDT如何应用于二分类问题？具体如何使用logitloss？](https://www.zhihu.com/question/55379008)
4. [scikit-learn 梯度提升树(GBDT)调参小结](http://www.cnblogs.com/pinard/p/6143927.html)