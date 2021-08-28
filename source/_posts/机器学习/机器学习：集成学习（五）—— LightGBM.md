---
title: 机器学习：集成学习（五）—— LightGBM
date: 2018-10-20 20:23:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

## LightGBM的安装
LightGBM CLI 版本的构建可参考[LightGBM安装指南](http://lightgbm.apachecn.org/cn/latest/Installation-Guide.html)，python版本我们只需要通过pip下载安装即可，更多python版本的安装可参见[LightGBM/python-package/](https://github.com/Microsoft/LightGBM/tree/master/python-package)。

构建普通版本：

```zsh
pip install lightgbm
```

构建GPU版本:

```zsh
pip install lightgbm --install-option=--gpu
```

## LightGBM的使用
使用LightGBM的一般流程：

1. 特征工程：尽可能多地构造新特征，再通过特征选择筛选出有价值的特征，可以交给模型训练过程自动选择也可以通过其他方式手动选择；
2. 模型选择：对于分类问题有[lightgbm.LGBMClassifier](http://lightgbm.apachecn.org/cn/latest/Python-API.html)，对于回归问题有[lightgbm.LGBMRegressor](http://lightgbm.apachecn.org/cn/latest/Python-API.html)；
3. 参数选择：迭代次数和一般超参数要分开来优化
    1. 通过“早停止”确定最优的迭代次数；
    2. 通过“网格搜索”确定最优的超参数；
4. 训练预测：使用最后的模型对全量训练集进行训练，预测测试集标签；

其中 1、2、4 步骤是一般机器学习的基本流程，步骤3才是使用LightGBM的关键所在，下面我们将详细讨论LightGBM的调参之法，并给出基于Python API的相应实例。

### 特征工程
假设我们已经通过特征工程构建了如下的数据集；

```python
import pandas as pd
import numpy as np
import lightgbm as lgb
from sklearn.model_selection import train_test_split
from sklearn.model_selection import RandomizedSearchCV

# 完整训练集和测试集
train = pd.read_csv('train.csv')
test = pd.read_csv('test.csv')

# 特征空间和标签空间
features = [c for c in train.columns if c not in ['label']]
target = 'label'

# 划分训练集、测试集、测试集
X_train, X_valid, y_train, y_valid = train_test_split(train[features],train[target],test_size=0.2,shuffle=True)
# 或者                 
ratio = int(0.8 * train.shape[0])
X_train = train[features].iloc[:ratio]
y_train = train[target].iloc[:ratio]
X_valid = train[features].ioc[ratio:]
y_valid = train[target].iloc[ratio:]
X_test = test[features]
y_test = test[target]

# 构造 Dataset 对象，可赋权重
train_lgb = lgb.Dataset(train[features], train[target], weight=w)
```

更多数据接口参见[这里](http://lightgbm.apachecn.org/cn/latest/Python-Intro.html#id2)。

### 模型选择
以回归模型[lightgbm.LGBMRegressor](http://lightgbm.readthedocs.io/en/latest/Python-API.html)为例。

#### 模型参数

```python
class lightgbm.LGBMRegressor(boosting_type='gbdt',      # 模型类型
                             objective=None, 
                             
                             num_leaves=31,             # 叶节点数和最大深度
                             max_depth=-1, 
                             
                             learning_rate=0.1,         # 学习率和迭代次数
                             n_estimators=100, 
                             
                             max_bin=255,               # 直方图方块数量
                             subsample_for_bin=200000,  # 用于构建直方图的样本数
                             class_weight=None,         # 权重
                             
                             min_split_gain=0.0,        # 分裂的最小增益
                             min_child_weight=0.001,    # 一个叶子上的最小 hessian 和
                             min_child_samples=20,      # 叶子最小样本数
                             
                             subsample=1.0,             # bagging行抽样比例
                             subsample_freq=0,          # 抽样频率
                             colsample_bytree=1.0,      # 列抽样比例
                             
                             reg_alpha=0.0,             # L1正则项系数
                             reg_lambda=0.0,            # L2正则项系数
                             
                             random_state=None,         # 随机种子
                             n_jobs=-1,                 # 线程数
                             silent=True,               # 迭代过程是否打印信息
                             **kwargs)                  # 额外参数
```

控制类型的参数：

- boosting_type='gbdt': 模型类型，default=gbdt, type=enum, options=gbdt, rf, dart, goss；
- objective=None：问题类型，default=regression, type=enum, options=regression, regression_l1, huber, fair, poisson, quantile, quantile_l2, binary, multiclass, multiclassova, xentropy, xentlambda, lambdarank；

控制学习效果的参数：

- num_leaves=31：叶节点数，这是控制树模型复杂度的主要参数，理论上, 借鉴 depth-wise 树, 我们可以设置 num_leaves = 2^(max_depth) 但是, 这种简单的转化在实际应用中表现不佳. 这是因为, 当叶子数目相同时, leaf-wise 树要比 depth-wise 树深得多, 这就有可能导致过拟合. 因此, 当我们试着调整 num_leaves 的取值时, 应该让其小于 2^(max_depth)。越大越容易过拟合；
- max_depth=-1：最大深度，虽然Leaf-wise 只需要控制num_leaves就可以间接控制树的深度，但你也可以利用 max_depth 来显式地限制树的深度。越大越容易过拟合；
- learning_rate=0.1：学习率，一般取值范围是`[0.01,0.1]`，需要和n_estimators配合使用；较小的 learning_rate 和较大的 num_iterations一般会有更好的准确率；
- n_estimators=100：迭代次数；越大越容易过拟合；
- max_bin=255：特征值的脂肪bins个数，LightGBM 将根据 max_bin 自动压缩内存。 例如, 如果 maxbin=255, 那么 LightGBM 将使用 uint8t 的特性值；越大越容易过拟合；
- subsample_for_bin=200000：用来构建直方图的样本数量，在设置更大的数据时, 会提供更好的训练效果, 但会增加数据加载时间；
- class_weight=None：样本权重，可以是dict、'balanced'或 None, dict只用于多分类任务，可以通过{class_label: weight}为每种标签设置权值；对于二分类可以使用is_unbalance or scale_pos_weight参数；'balanced'会自动根据标签比例调整样本权重；
- min_split_gain=0.0：分裂的最小增益，越大越限制节点分裂越容易欠拟合；
- min_child_weight=0.001：一个叶子上的最小 hessian 和，类似于 min_child_samples，越大越容易欠拟合；
- min_child_samples=20：叶子中的最小样本数，越大越容易欠拟合；
- subsample=1.0：行抽样比例，越大越容易过拟合；
- subsample_freq=0：抽样频率，每k次迭代进行一次采样，等于0时不采样，越大越容易过拟合；
- colsample_bytree=1.0：列抽样比例，越大越容易过拟合；
- reg_alpha=0.0：L1正则项系数，越大越不容易过拟合；
- reg_lambda=0.0：L2正则项系数，越大越不容易过拟合；

控制辅助的参数：

- random_state=None：随机种子
-  n_jobs=-1：线程数
- silent=True：迭代过程是否打印信息

其它控制的参数：

- verbose=1:int,控制日志打印级别， <0 = 致命的, =0 = 错误 (警告), >0 = 信息

完整参数和参数效果参见[参数](http://lightgbm.apachecn.org/cn/latest/Parameters.html)和[参数优化](http://lightgbm.apachecn.org/cn/latest/Parameters-Tuning.html)。

假设我们的回归模型初始化参数为：

```python
lgb_reg = lgb.LGBMRegressor(num_leaves=5,
                                max_depth=-1,

                                learning_rate=0.02,
                                n_estimators=1000,

                                max_bin=255,
                                subsample_for_bin=50000,

                                min_split_gain=0.0,
                                min_child_weight=0.001,
                                min_child_samples=5,

                                subsample=0.8,
                                subsample_freq=3,
                                colsample_bytree=0.8,

                                reg_alpha=0.0,
                                reg_lambda=1.0,

                                random_state=999,
                                n_jobs=-1,
                                silent=True,
                                verbose=-1)
```

#### 模型的属性

- n_features_:int ，特征数
- classes_：array of shape = [n_classes] ，分类标签
- n_classes_：int，分类标签数
- best_score_：dict or None，模型最好的得分
- best_iteration_：int or None，如果训练时指定了early_stopping_rounds，模型最优迭代次数
- objective_：string or callable，训练时所使用的objective_
- evals_result_：dict or None，如果训练时指定了early_stopping_rounds，评估结果
- feature_importances_：array of shape = [n_features]，特征重要度

### 早停止——确定最优迭代次数
原理：LightGBM是一种迭代的Boosting方法，我们可以在模型训练时设置验证集，通过在每轮迭代评估当前模型在验证集上的性能来监控模型训练过程，通过早停止的方式确定出在给定步长下的最优迭代次数。

早停止涉及到以下几个核心概念：

1. 步长：也称学习率`learning_rate`，最优迭代次数和步长的设置息息相关，必须先固定步长，一般取值范围为`[0.01,0.1]`;
2. 验证集：必须在模型`fit`时提供相应的验证集;
3. 评估指标：必须使用合适的评估指标`eval_metric`;


#### fit方法

```python
fit(X,                          # 特征空间
    y,                          # 标签空间
    
    sample_weight=None,         # 样本权重
    init_score=None,            # 训练数据的初始得分
    
    eval_set=None,              # 验证集
    eval_names=None,            # 验证集名称
    eval_sample_weight=None,    # 验证集样本权重
    eval_init_score=None,       # 验证集初始得分
    eval_metric='l2',           # 评估指标
    early_stopping_rounds=None, # 早停止迭代次数
    
    verbose=True,               # 是否打印详情
    feature_name='auto',        # 特征名
    categorical_feature='auto', # 类别特征
    callbacks=None)             # callback函数列表
```

- X：特征空间，array-like or sparse matrix of shape = [n_samples, n_features]，一般为ndarray或者DataFrame
- y：标签空间，array-like of shape = [n_samples],一般为ndarray或者Series
- sample_weight=None：样本权重，array-like of shape = [n_samples] or None
- init_score=None：训练数据的初始得分，array-like of shape = [n_samples] or None
- eval_set=None：验证集，为了早停止而用作验证集的(X, y) 元组列表
- eval_names=None：验证集名称，list of strings or None
- eval_sample_weight=None：验证集样本权重，list of arrays or None
- eval_init_score=None：验证集初始得分，list of arrays or None
- eval_metric='l2'：评估指标，string, list of strings, callable or None，如果为字符串，则必须是[内置的评估指标](http://lightgbm.apachecn.org/cn/latest/Parameters.html)，如l1, l2, ndcg, auc, binary_logloss, binary_error …；如果是函数，必须满足func(y_true, y_pred)，返回 (指标名eval_name, 指标得分eval_result, 是否越大越好is_bigger_better)；
- early_stopping_rounds=None：早停止迭代次数，当评估指标停止提升early_stopping_rounds多轮时，训练会提前停止；
- verbose=True：是否打印详情，bool值，且至少有一个验证集
- feature_name='auto'：特征名，当取'auto'且输入的数据为DataFrame时，会自动识别特征名；
- categorical_feature='auto'：类别特征，list of strings or int, or 'auto'，如果是字符串，特征名会被使用，如果是整型，特征索引会被使用，如果是'auto'且数据为DataFrame时，会自动识别特征名，被自动识别类别特征；
- callbacks=None：callback函数列表，函数列表中的每个函数都会在每次迭代结束时被调用，详见python的[回调函数](http://python3-cookbook.readthedocs.io/zh_CN/latest/c07/p10_carry_extra_state_with_callback_functions.html);

#### 自定义早停止中的评估函数
自定义函数遵循以下接口协议：`func(y_true, y_pred)`, `func(y_true, y_pred, weight) or func(y_true, y_pred, weight, group)`，`Returns (eval_name, eval_result, is_bigger_better) or list of (eval_name, eval_result, is_bigger_better)`。

- y_true:真实标签，array-like of shape = [n_samples]
- y_pred:预测标签，array-like of shape = [n_samples]
- weight:样本权重
- group:Group/query data, used for ranking task
- eval_name: 评估指标名称，str
- eval_result: 评估结果，float
- is_bigger_better: 是否越大代表模型越好，bool

一个将Gini系数作为评估指标的例子：

```python
def gini(actual, pred):
    """
    计算真实序列按照预测序列升序排列时的相对基尼系数，如果真实序列均为0，定义gini为1是合理的
    :param actual: 真实序列>=0
    :param pred: 预测序列
    :return: 基尼系数
    """
    n = len(pred)
    triple = np.c_[actual, pred, range(n)].astype(float)
    triple = triple[np.lexsort((triple[:, 2], triple[:, 1]))]
    cum_sum = triple[:, 0].cumsum()
    if cum_sum[-1] == 0:
        return 1
    else:
        x = cum_sum.sum() / cum_sum[-1]
        return (n + 1 - 2 * x) / n


def gini_normalized(y_true, y_pred):
    """
    自定义用于fit的eval_metric指标函数，此处为归一化的相对基尼系数
    :param y_true: 真实序列ndarray
    :param y_pred: 预测序列ndarray
    :return: eval_name, eval_result, is_bigger_better
    """
    gini_true = gini(y_true, y_true)
    gini_pred = gini(y_true, y_pred)
    # 如果真实值均匀分布，gini为0，定义此时的归一化为1是合理的
    res = gini_pred / gini_true if gini_true else 1
    return 'gini_normalized', res, True
```

#### 通过早停止确定最优迭代次数
通过早停止能够得到在当前参数下的最佳迭代次数，需要重新修正模型的迭代次数参数n_estimators，一个例子：

```python
def early_stopping(lgb_reg, X_train, y_train, X_valid, y_valid, online):
    """
    通过早停确定最优迭代次数
    :param lgb_reg: 回归模型
    :param X_train: 部分训练集特征空间
    :param y_train: 部分训练集标签空间
    :param X_valid: 验证集特征空间
    :param y_valid: 验证集标签空间
    :param online: 是否线上
    :return: 设置了最优迭代次数的模型
    """
    lgb_reg.fit(X_train, y_train,
                eval_set=[(X_valid, y_valid)],
                eval_names=['gini'],
                eval_metric=gini_normalized,
                early_stopping_rounds=100,
                verbose=[True, False][online])

    best_iteration = lgb_reg.best_iteration_
    lgb_reg.set_params(n_estimators=best_iteration)
    return lgb_reg
```

打印日志监控迭代过程：
```
[1]	gini's l2: 12.5645	gini's gini_normalized: 0.709833
Training until validation scores don't improve for 100 rounds.
[2]	gini's l2: 12.5671	gini's gini_normalized: 0.606205
[3]	gini's l2: 12.5561	gini's gini_normalized: 0.753056
[4]	gini's l2: 12.5592	gini's gini_normalized: 0.579402
[5]	gini's l2: 12.5623	gini's gini_normalized: 0.575758
[6]	gini's l2: 12.5653	gini's gini_normalized: 0.520632
[7]	gini's l2: 12.5675	gini's gini_normalized: 0.476118
[8]	gini's l2: 12.5572	gini's gini_normalized: 0.578779
[9]	gini's l2: 12.5601	gini's gini_normalized: 0.525161
[10]	gini's l2: 12.5634	gini's gini_normalized: 0.515673
......
[97]	gini's l2: 12.5506	gini's gini_normalized: 0.217889
[98]	gini's l2: 12.5534	gini's gini_normalized: 0.107637
[99]	gini's l2: 12.5552	gini's gini_normalized: 0.105389
[100]	gini's l2: 12.5425	gini's gini_normalized: 0.270766
[101]	gini's l2: 12.5458	gini's gini_normalized: 0.270766
[102]	gini's l2: 12.5492	gini's gini_normalized: 0.270766
[103]	gini's l2: 12.5511	gini's gini_normalized: 0.215826
Early stopping, best iteration is:
[3]	gini's l2: 12.5561	gini's gini_normalized: 0.753056
```

### 网格搜索
在确定了最优的迭代次数之后，需要通过网格搜索来确定其他超参数的最优取值，网格搜索包含以下几个核心：

1. 模型：用于训练的模型
2. 参数空间：由各个待调节参数的取值范围共同组成的参数空间
3. 搜索机制：参数空间的搜索或抽样机制
4. 交叉验证：通过交叉验证留出验证集来验证不同参数备选解的效果
5. 评估函数：评估模型训练效果的函数

#### 搜索机制
常用的有两种网格搜索机制：

1. 一般网格搜索:给出每个待调节的超参数的若干备选解，它们的任意组合构成很多组解，在所有的备选解空间中搜索最优参数；因为备选解空间刚好都是各轴交点，它们一起构成了一个解的网格，因此称为网格搜索；
2. 随机网格搜索:给出每个待调节的超参数的若干备选解或分布，每次从各个超参数备选解中抽样出一个值组成一组解，在有限抽样次数中寻找最优解；

关于二者的比较可以参见这篇文章[Smarter Parameter Sweeps (or Why Grid Search Is Plain Stupid)](https://medium.com/rants-on-machine-learning/smarter-parameter-sweeps-or-why-grid-search-is-plain-stupid-c17d97a0e881)。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/02-04-29.jpg" width="55%" heigh="55%"></img>
</div>

随机网格搜索更加高效，接下来将主要介绍scilit-learn提供的RandomizedSearchCV方法，GridSearchCV方法也大同小异。

```python
class sklearn.model_selection.RandomizedSearchCV(estimator, 
                                                 param_distributions, 
                                                 n_iter=10, 
                                                 scoring=None, 
                                                 fit_params=None, 
                                                 n_jobs=1, iid=True, 
                                                 refit=True, 
                                                 cv=None, 
                                                 verbose=0, 
                                                 pre_dispatch=‘2*n_jobs’, 
                                                 random_state=None, 
                                                 error_score=’raise’, 
                                                 return_train_score=’warn’)
```

参数说明:

- estimator：模型对象，模型中需要指定score方法，否则必须传递scoring参数；
- param_distributions：dict，参数名作为key，参数分布或者列表作为value；如果所有参数都以列表作为value，那么不会出现重复抽样；否则，可能出现重复抽样，参数分布必须支持rvs方法用于抽样;
- n_iter=10：抽样次数
- scoring=None：string, callable, list/tuple, dict or None，应用于验证集上的评估方法。如果是字符串，必须是内置的评估指标，如'f1'，'roc_auc'，参见[predefined values](http://scikit-learn.org/stable/modules/model_evaluation.html#scoring-parameter)；如果是函数，可以通过`sklearn.metrics.make_scorer(score_func)`方法构造一个scorer，其中`score_func(y, y_pred, **kwargs)`，return eval_result；
- fit_params=None：dict，传给fit方法的参数 
- n_jobs=1：线程数
- iid=True：是否独立同分布
- refit=True：是否使用最优参数重新在全量数据集行进行训练，refit后的模型可以使用best_estimator_返回，可以直接在该模型上应用predict方法；
- cv=None：int,cross-validation generator or an iterable，默认采用3折交叉验证。如果为整数k，采用k折交叉验证；如果为交叉验证生成器或可迭代的训练测试集划分，具体可参考[Cross-validation](http://scikit-learn.org/stable/modules/cross_validation.html#cross-validation);
- verbose=0：大于等于0的整数，控制日志打印详细程度，越大越详细；
- pre_dispatch=‘2*n_jobs’：int, or string控制线程数，默认立刻创建所有线程；
- random_state=None：随机种子；
- error_score=’raise’：fit时出错的处理机制
- return_train_score=’warn’：boolean，是否在cv_results_中包含训练集得分，默认为True；

属性:

- cv_results_:网格搜索结果，dict of numpy (masked) ndarrays（keys作为header，values作为列，可以传给DataFrame显示）。包含以下项目：
    - params:存储历次尝试的参数字典列表
    - rank_test_score：存储各次参数的得分排名
    
```python
# 包含两组备选解的搜索结果
{
{'mean_fit_time': array([0.75533938, 0.66926527]), 
 'std_fit_time': array([0.23030835, 0.06423108]), 
 'mean_score_time': array([0.00308728, 0.00117135]), 
 'std_score_time': array([2.26265789e-03, 4.74953906e-05]), 
 'param_subsample': masked_array(data=[0.7, 0.8],mask=[False, False],fill_value='?',dtype=object), 
 'param_reg_lambda': masked_array(data=[1.0, 0.5],mask=[False, False],fill_value='?',dtype=object), 
 'param_reg_alpha': masked_array(data=[1.5, 0.5],mask=[False, False],fill_value='?',dtype=object), 
 'param_num_leaves': masked_array(data=[4, 3],mask=[False, False],fill_value='?',dtype=object), 
 'param_min_child_samples': masked_array(data=[9, 4],mask=[False, False],fill_value='?',dtype=object), 
 'param_max_depth': masked_array(data=[10, 8],mask=[False, False],fill_value='?',dtype=object), 
 'param_colsample_bytree': masked_array(data=[0.9, 0.7],mask=[False, False],fill_value='?',dtype=object), 
 'params': [{'subsample': 0.7, 'reg_lambda': 1.0, 
             'reg_alpha': 1.5, 'num_leaves': 4, 
             'min_child_samples': 9, 'max_depth': 10, 
             'colsample_bytree': 0.9}, 
            {'subsample': 0.8, 'reg_lambda': 0.5, 
             'reg_alpha': 0.5, 'num_leaves': 3, 
             'min_child_samples': 4, 'max_depth': 8, 
             'colsample_bytree': 0.7}], 
 'split0_test_score': array([-0.20771241, -0.56534909]), 
 'split1_test_score': array([ 0.09806087, -0.00358756]), 
 'split2_test_score': array([0.38842062, 0.44214761]), 
 'mean_test_score': array([ 0.08991668, -0.04749387]), 
 'std_test_score': array([0.24401773, 0.41343975]), 
 'rank_test_score': array([1, 2], dtype=int32)}
```

- best_estimator_:返回最佳模型，参见refit
- best_score_:返回最佳模型的平均交叉验证得分
- best_params_：返回最佳参数
- best_index_：返回最佳参数在cv_results_[params]中的索引
- scorer_:返回所使用的评估函数
- n_splits_：int,交叉验证的折数

#### 参数空间
参数空间由字典表示，参数名为key，参数取值列表或分布(具有rvs方法的对象)作为values，一个例子：

```python
from scipy.stats import randint as sp_randint

params_dist = {'num_leaves': range(2, 300, 2),
               'max_depth': [-1, 6, 8, 10, 15],
               'min_child_samples': sp_randint(10,100),

               'subsample': [i / 10. for i in range(3, 11)],
               'colsample_bytree': [i / 10. for i in range(3, 11)],

               'reg_alpha': [0, 0.5, 1., 1.5, 2., 5., 10.],
               'reg_lambda': [0, 0.5, 1., 1.5, 2., 5., 10.]}
```

#### 自定义网格搜索中的评估函数
网格搜索自定义评估函数(可作为scoring参数)的接口协议：

```python
sklearn.metrics.make_scorer(score_func, greater_is_better=True, needs_proba=False, needs_threshold=False, **kwargs)[source]¶

score_func(y, y_pred, **kwargs)->eval_score
```

一个例子：

```python
# 首先定义一个score_func
def gini_grid(y_label, y_pred):
    """
    用于grid_search的scoring
    :param y_label: 真实序列ndarray
    :param y_pred: 预测序列ndarray
    :return: 归一化的基尼指数
    """
    return gini_normalized(y_label, y_pred)[1]
# 通过make_scorer(score_func)构建scorer
scoring = make_scorer(score_func)
```

#### 随机网格搜索确定最优超参数
一个例子：

```python
def random_search(lgb_reg, params_dist, X_train, y_train, n_iter=10, nfold=3):
    """
    随机网格搜索确定最优参数，返回使用最优参数全量refit后的模型
    :param lgb_reg: 模型
    :param params_dist: 参数网格
    :param X_train: 全部训练集的特征空间DataFrame
    :param y_train: 全部训练集的标记空间Series
    :param n_iter: 参数采样次数
    :param nfold: 交叉验证折数
    :return: refit后的模型
    """
    rs = RandomizedSearchCV(lgb_reg,
                            params_dist,
                            n_iter=n_iter,
                            scoring=make_scorer(gini_grid),
                            cv=nfold,
                            refit=True,
                            verbose=0,
                            return_train_score=False)
    rs.fit(X_train.values, y_train.values)
    report(rs.cv_results_)
    return rs.best_estimator_

def report(results, top=10):
    """
    打印网格搜索结果中排名前10的参数组合和评估性能
    :param results: 网格搜索对象的结果属性cv_results_
    :param top: 排名前几的
    :return: None
    """
    print("GridSearchCV took %d candidate parameter settings." % len(results['params']))
    for i in range(1, top + 1):
        candidates = np.flatnonzero(results['rank_test_score'] == i)
        for candidate in candidates:
            print('model rank:%s' % i)
            print("Mean validation score: {0:.3f} (std: {1:.3f})".format(
                results['mean_test_score'][candidate],
                results['std_test_score'][candidate]))
            print("Parameters: {0}".format(results['params'][candidate]))
            print("")

def report_in_dataframe(results, top=10):
    """
    以DataFrame形式打印得分topk的搜索结果：排名-参数-得分
    :param results: cv_results_
    :param top: int
    :return: DataFrame
    """
    result = pd.DataFrame(results['params'])
    result['test_score'] = results['mean_test_score']
    result['test_std'] = results['std_test_score']
    result['rank'] = results['rank_test_score']

    result = result.set_index('rank').sort_index()
    print(result[:top])
    return result[:top]
```

打印网格搜索结果：

```
GridSearchCV took 100 candidate parameter settings.
model rank:1
Mean validation score: 0.529 (std: 0.184)
Parameters: {'subsample': 1.0, 'reg_lambda': 0.5, 'reg_alpha': 10.0, 'num_leaves': 2, 'min_child_samples': 9, 'max_depth': 10, 'colsample_bytree': 0.6}

model rank:2
Mean validation score: 0.440 (std: 0.300)
Parameters: {'subsample': 1.0, 'reg_lambda': 0.2, 'reg_alpha': 0.5, 'num_leaves': 3, 'min_child_samples': 9, 'max_depth': -1, 'colsample_bytree': 0.6}

model rank:3
Mean validation score: 0.317 (std: 0.398)
Parameters: {'subsample': 1.0, 'reg_lambda': 0, 'reg_alpha': 1.0, 'num_leaves': 4, 'min_child_samples': 2, 'max_depth': 10, 'colsample_bytree': 1.0}

model rank:4
Mean validation score: 0.287 (std: 0.395)
Parameters: {'subsample': 1.0, 'reg_lambda': 10.0, 'reg_alpha': 0.5, 'num_leaves': 3, 'min_child_samples': 2, 'max_depth': -1, 'colsample_bytree': 1.0}

model rank:5
Mean validation score: 0.281 (std: 0.411)
Parameters: {'subsample': 0.9, 'reg_lambda': 20.0, 'reg_alpha': 1.5, 'num_leaves': 6, 'min_child_samples': 2, 'max_depth': -1, 'colsample_bytree': 1.0}

model rank:5
Mean validation score: 0.281 (std: 0.411)
Parameters: {'subsample': 0.9, 'reg_lambda': 10.0, 'reg_alpha': 1.0, 'num_leaves': 7, 'min_child_samples': 2, 'max_depth': 8, 'colsample_bytree': 1.0}

model rank:7
Mean validation score: 0.250 (std: 0.507)
Parameters: {'subsample': 0.9, 'reg_lambda': 5.0, 'reg_alpha': 1.0, 'num_leaves': 6, 'min_child_samples': 3, 'max_depth': 10, 'colsample_bytree': 1.0}

model rank:8
Mean validation score: 0.236 (std: 0.304)
Parameters: {'subsample': 0.9, 'reg_lambda': 0.2, 'reg_alpha': 5.0, 'num_leaves': 7, 'min_child_samples': 2, 'max_depth': 8, 'colsample_bytree': 0.5}

model rank:9
Mean validation score: 0.226 (std: 0.477)
Parameters: {'subsample': 0.9, 'reg_lambda': 2.0, 'reg_alpha': 2.0, 'num_leaves': 5, 'min_child_samples': 3, 'max_depth': 8, 'colsample_bytree': 1.0}

model rank:10
Mean validation score: 0.222 (std: 0.317)
Parameters: {'subsample': 0.9, 'reg_lambda': 0, 'reg_alpha': 10.0, 'num_leaves': 2, 'min_child_samples': 4, 'max_depth': -1, 'colsample_bytree': 0.5}
```

### 训练预测
LightGBM训练预测过程与一般机器学习无异：

```python
# lgb_reg是网格搜索refit后的最优模型
y_pred = lgb_reg.predict(test[features])
result = pd.DataFrame({'Id': test.index, 'Pred': y_pred}, columns=['Id', 'Pred'])
# 输出，注意列名和列序
result.to_csv(path_test_out, header=True, index=False)
```

### LightGBM示例完整代码

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @File     : process.py
# @Author   : Likew
# @Date     : 2018/5/18 16:14
# @Desc     : 模型选择-参数选择-预测输出
# @Solution : 调参之法（早停止确定最优迭代次数+网格搜索确定最优超参数）

import pandas as pd
import numpy as np
import lightgbm as lgb
import time
from sklearn.model_selection import RandomizedSearchCV
from sklearn.metrics import make_scorer


def gini(actual, pred):
    """
    计算真实序列按照预测序列升序排列时的相对基尼系数，如果真实序列均为0，定义gini为1是合理的
    :param actual: 真实序列>=0
    :param pred: 预测序列
    :return: 基尼系数
    """
    n = len(pred)
    triple = np.c_[actual, pred, range(n)].astype(float)
    triple = triple[np.lexsort((triple[:, 2], triple[:, 1]))]
    cum_sum = triple[:, 0].cumsum()
    if cum_sum[-1] == 0:
        return 1
    else:
        x = cum_sum.sum() / cum_sum[-1]
        return (n + 1 - 2 * x) / n


def gini_normalized(y_true, y_pred):
    """
    自定义用于fit的eval_metric指标函数，此处为归一化的相对基尼系数
    :param y_true: 真实序列ndarray
    :param y_pred: 预测序列ndarray
    :return: eval_name, eval_result, is_bigger_better
    """
    gini_true = gini(y_true, y_true)
    gini_pred = gini(y_true, y_pred)
    # 如果真实值均匀分布，gini为0，定义此时的归一化为1是合理的
    res = gini_pred / gini_true if gini_true else 1
    return 'gini_normalized', res, True


def gini_feval(y_pred, train_data):
    """
    用于cv的自定义的feval指标函数
    :param y_pred: 预测值ndarray
    :param train_data: Dataset
    :return: (eval_name:string,eval_score,higher_is_better:bool)
    """
    labels = train_data.get_label()
    return 'gini', gini_normalized(labels, y_pred), True


def gini_grid(y_label, y_pred):
    """
    用于grid_search的scoring
    :param y_label: 真实序列ndarray
    :param y_pred: 预测序列ndarray
    :return: 归一化的基尼指数
    """
    return gini_normalized(y_label, y_pred)[1]


def report(results, top=5):
    """
    打印网格搜索结果中排名前10的参数组合和评估性能
    :param results: 网格搜索对象的结果属性cv_results_
    :param top: 排名前几的
    :return: None
    """
    print("GridSearchCV took %d candidate parameter settings." % len(results['params']))
    for i in range(1, top + 1):
        candidates = np.flatnonzero(results['rank_test_score'] == i)
        for candidate in candidates:
            print('model rank:%s' % i)
            print("Mean validation score: {0:.3f} (std: {1:.3f})".format(
                results['mean_test_score'][candidate],
                results['std_test_score'][candidate]))
            print("Parameters: {0}".format(results['params'][candidate]))
            print("")


def report_in_dataframe(results, top=10):
    """
    以DataFrame形式打印得分topk的搜索结果：排名-参数-得分
    :param results: cv_results_
    :param top: int
    :return: DataFrame
    """
    result = pd.DataFrame(results['params'])
    result['test_score'] = results['mean_test_score']
    result['test_std'] = results['std_test_score']
    result['rank'] = results['rank_test_score']

    result = result.set_index('rank').sort_index()
    print(result[:top])
    return result[:top]


def early_stopping(lgb_reg, X_train, y_train, X_valid, y_valid, online):
    """
    通过早停确定最优迭代次数
    :param lgb_reg: 回归模型
    :param X_train: 部分训练集特征空间
    :param y_train: 部分训练集标签空间
    :param X_valid: 验证集特征空间
    :param y_valid: 验证集标签空间
    :param online: 是否线上
    :return: 设置了最优迭代次数的模型
    """
    lgb_reg.fit(X_train, y_train,
                eval_set=[(X_valid, y_valid)],
                eval_names=['gini'],
                eval_metric=gini_normalized,
                early_stopping_rounds=100,
                verbose=[1, 10][online])

    best_iteration = lgb_reg.best_iteration_
    lgb_reg.set_params(n_estimators=best_iteration)
    return lgb_reg


def random_search(lgb_reg, params_dist, X_train, y_train, n_iter=10, nfold=3):
    """
    随机网格搜索确定最优参数，返回使用最优参数全量refit后的模型
    :param lgb_reg: 模型
    :param params_dist: 参数网格
    :param X_train: 全部训练集的特征空间DataFrame
    :param y_train: 全部训练集的标记空间Series
    :param n_iter: 参数采样次数
    :param nfold: 交叉验证折数
    :return: refit后的模型
    """
    rs = RandomizedSearchCV(lgb_reg,
                            params_dist,
                            n_iter=n_iter,
                            scoring=make_scorer(gini_grid),
                            cv=nfold,
                            refit=True,
                            verbose=0,
                            return_train_score=False)
    rs.fit(X_train.values, y_train.values)

    report_in_dataframe(rs.cv_results_)
    return rs.best_estimator_


def process(train, test, start, online):
    """
    调参、训练、预测全过程
    :param train: 训练集DataFrame
    :param test: 测试集DataFrame
    :param start: 开始执行时间
    :param online: 是否线上
    :return: 预测结果DataFrame
    """
    # 特征和标签
    features = [c for c in train.columns if c not in ['label']]
    target = 'label'

    # 划分训练集和验证集:3:1
    ratio = int(train.shape[0] * 0.66)
    X_train = train[features].iloc[:ratio]
    y_train = train[target].iloc[:ratio]
    X_valid = train[features].iloc[ratio:]
    y_valid = train[target].iloc[ratio:]

    # 模型：leaf_wise生长策略，线上应该适当调大num_leaves，但是线下就跑不了
    if online:
        lgb_reg = lgb.LGBMRegressor(num_leaves=176,
                                    max_depth=6,

                                    learning_rate=0.01,
                                    n_estimators=1000,

                                    max_bin=255,
                                    subsample_for_bin=200000,

                                    min_split_gain=0.0,
                                    min_child_weight=0.001,
                                    min_child_samples=26,

                                    subsample=0.9,
                                    subsample_freq=3,
                                    colsample_bytree=0.5,

                                    reg_alpha=0.5,
                                    reg_lambda=5.0,

                                    random_state=999,
                                    n_jobs=-1,
                                    silent=True,
                                    verbose=-1)
    else:
        lgb_reg = lgb.LGBMRegressor(num_leaves=5,
                                    max_depth=-1,

                                    learning_rate=0.02,
                                    n_estimators=1000,

                                    max_bin=255,
                                    subsample_for_bin=50000,

                                    min_split_gain=0.0,
                                    min_child_weight=0.001,
                                    min_child_samples=5,

                                    subsample=0.8,
                                    subsample_freq=3,
                                    colsample_bytree=0.8,

                                    reg_alpha=0.0,
                                    reg_lambda=1.0,

                                    random_state=999,
                                    n_jobs=-1,
                                    silent=True,
                                    verbose=[0, -1][online])

    # 早停确定最优迭代次数
    print("\n******************* Early Stopping ***********************")
    lgb_reg = early_stopping(lgb_reg, X_train, y_train, X_valid, y_valid, online)
    print('Early Stopping Done! Time:%.3f s' % (time.time() - start))
    print('best n_estimators:%s' % lgb_reg.best_iteration_)

    # 网格搜索确定最优超参数
    print("\n******************* Random Search ***********************")
    if online:
        params_dist = {'num_leaves': range(2, 300, 2),
                       'max_depth': [-1, 6, 8, 10, 15],
                       'min_child_samples': range(2, 100, 2),

                       'subsample': [i / 10. for i in range(3, 11)],
                       'colsample_bytree': [i / 10. for i in range(3, 11)],
                       'subsample_freq': range(1, 10),

                       'reg_alpha': [0, 0.5, 1., 1.5, 2., 5., 10.],
                       'reg_lambda': [0, 0.5, 1., 1.5, 2., 5., 10.]}
    else:
        params_dist = {'num_leaves': range(2, 10),
                       'max_depth': [-1, 6, 8, 10],
                       'min_child_samples': range(2, 10),

                       'subsample': [i / 10. for i in range(5, 11)],
                       'colsample_bytree': [i / 10. for i in range(5, 11)],

                       'reg_alpha': [0, 0.2, 0.5, 1., 1.5, 2., 5., 10., 20.],
                       'reg_lambda': [0, 0.2, 0.5, 1., 1.5, 2., 5., 10., 20.]}

    lgb_reg = random_search(lgb_reg, params_dist, train[features], train[target], n_iter=200)

    print('RandomizedSearchCV Done! Time:%.3f s' % (time.time() - start))

    print('\nlast params:%s' % lgb_reg.get_params())
    print('feature importances:%s' % lgb_reg.feature_importances_)

    # 预测，注意DataFram中的列名和列序
    y_pred = lgb_reg.predict(test[features])
    result = pd.DataFrame({'Id': test.index, 'Pred': y_pred}, columns=['Id', 'Pred'])
    return result


if __name__ == '__main__':
    pass
```

## 引用
1. [LightGBM项目Github地址](https://github.com/Microsoft/LightGBM)
2. [LightGBM中文文档](http://lightgbm.apachecn.org/cn/latest/index.html)
3. [LightGBM Python API](http://lightgbm.apachecn.org/cn/latest/Python-API.html)
