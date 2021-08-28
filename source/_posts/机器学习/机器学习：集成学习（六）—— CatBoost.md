---
title: 机器学习：集成学习（六）—— CatBoost
date: 2018-10-20 20:23:53
tags: 
    - 机器学习
categories:
    - 机器学习
---

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/01-34-50.jpg" width="70%" heigh="55%"></img>
</div>

[CatBoost](https://tech.yandex.com/catboost/)是由Yandex发布的梯度提升库。在Yandex提供的基准测试中，CatBoost的表现超过了XGBoost和LightGBM。

## 安装
```
pip install catboost
```

## 使用
CatBoost的接口基本上和大部分sklearn分类器差不多，所以，如果你用过sklearn，那你使用CatBoost不会遇到什么麻烦。CatBoost可以处理缺失的特征以及类别特征，你只需告知分类器哪些维度是类别维度。

### 模型
#### 模型参数
下面以CatBoostClassifier为例介绍catboost模型的常用参数把手，更多参数可参见[文档](https://tech.yandex.com/catboost/doc/dg/concepts/python-reference_parameters-list-docpage/#python-reference_parameters-list)。但如果关注的是模型表现的话，并不需要调整更多参数。

参数	|描述
:---|:---
iterations=500	|最大决策树数目。可以使用较小的值。
learning_rate=0.03	|影响训练的总时长：值越小，训练所需的迭代次数就越高。
depth=6	|树的深度。可能是任何不大于32的整数。推荐值：1-10
l2_leaf_reg=3	|L2正则子参数。任何正值都可以。
loss_function='Logloss'|string，object，损失函数。二元分类问题使用LogLoss或CrossEntropy。多分类使用MultiClass。
eval_metric|string，性能指标，对回归问题是RMSE，二分类可用Logloss
bootstrap_type|自助采样类型，对样本采样的方式，默认Bayesian，可选Bernoulli
subsample|bagging的比例，仅在bootstrap_type取Bernoulli或Poisson可用
rsm|特征抽取比例，取值于(0,1]，默认为1
nan_mode|string，缺失值处理方式，“Forbidden” 输入数据中不允许缺失值，“Min”或“Max”
one_hot_max_size|将所有特征取值个数小于该值的特征转化为one-hot编码
border_count=32	|数值特征分割数。整数1至255（含）。
ctr_border_count=50|	类别特征分割数。整数1至255（含）
random_seed|seed，用于训练的随机种子


```python
Class CatBoostClassifier(iterations=None,
                         learning_rate=None,
                         
                         depth=None,
                         l2_leaf_reg=None,
                         model_size_reg=None,
                         rsm=None,
                         loss_function='Logloss',
                         border_count=None,
                         feature_border_type=None,
                         fold_permutation_block_size=None,
                         od_pval=None,
                         od_wait=None,
                         od_type=None,
                         nan_mode=None,
                         counter_calc_method=None,
                         leaf_estimation_iterations=None,
                         leaf_estimation_method=None,
                         thread_count=None,
                         random_seed=None,
                         use_best_model=None,
                         verbose=None,
                         logging_level=None,
                         metric_period=None,
                         ctr_leaf_count_limit=None,
                         store_all_simple_ctr=None,
                         max_ctr_complexity=None,
                         has_time=None,
                         classes_count=None,
                         class_weights=None,
                         one_hot_max_size=None,
                         random_strength=None,
                         name=None,
                         ignored_features=None,
                         train_dir=None,
                         custom_loss=None,
                         custom_metric=None,
                         eval_metric=None,
                         bagging_temperature=None,
                         save_snapshot=None,
                         snapshot_file=None,
                         fold_len_multiplier=None,
                         used_ram_limit=None,
                         gpu_ram_part=None,
                         allow_writing_files=None,
                         approx_on_full_history=None,
                         boosting_type=None,
                         simple_ctr=None,                         
                         combinations_ctr=None,
                         per_feature_ctr=None,
                         ctr_description=None,
                         task_type=None,
                         device_config=None,
                         devices=None,
                         bootstrap_type=None,
                         subsample=None,
                         max_depth=None,
                         n_estimators=None,
                         num_boost_round=None,
                         num_trees=None,
                         colsample_bylevel=None,
                         random_state=None,
                         reg_lambda=None,
                         objective=None,
                         eta=None,
                         max_bin=None,
                         scale_pos_weight=None,
                         gpu_cat_features_storage=None)
```

#### 模型方法
- 训练

```python
# cat_features指定类别特征
fit(X, y=None,
    cat_features=None,
    sample_weight=None,
    baseline=None,
    use_best_model=None,
    eval_set=None,
    verbose=None, 
    logging_level=None
    plot=False)
```

- 预测

```python
predict(data, 
        prediction_type='Class', 
        ntree_start=0, 
        ntree_end=0, 
        thread_count=-1,
        verbose=None)
        
predict_proba(data, 
              ntree_start=0, 
              ntree_end=0, 
              thread_count=-1, 
              verbose=None)
```

### 交叉验证

```python
cv(pool=None, 
   params=None, 
   dtrain=None, 
   iterations=None, 
   num_boost_round=None,
   fold_count=3, 
   nfold=None,
   inverted=False,
   partition_random_seed=0,
   seed=None, 
   shuffle=True, 
   logging_level=None, 
   stratified=False,
   as_pandas=True)
```

示例：

```python
pool = Pool(x_train, y_train)
params = {
          'iterations': 100, 
          'depth': 2, 
          'loss_function': 'MultiClass', 
          'classes_count': 3, 
          'logging_level': 'Silent'
          }
scores = cv(params, pool)
```

### 网格搜索

调优参数后我们得到的最终分数实际上和调优之前一样！看起来我做的调优没能超越默认值。这体现了CatBoost分类器的质量，默认值是精心挑选的（至少就这一问题而言）。增加交叉验证的n_splits，通过多次运行分类器减少得到的噪声可能会有帮助，不过这样的话网格搜索的耗时会更长。如果你想要测试更多参数或不同的组合，那么上面的代码很容易修改。

## 预防过拟合
CatBoost提供了预防过拟合的良好设施。如果你把iterations设得很高，分类器会使用许多树创建最终的分类器，会有过拟合的风险。如果初始化的时候设置了use_best_model=True和eval_metric='Accuracy'，接着设置eval_set（验证集），那么CatBoost不会使用所有迭代，它将返回在验证集上达到最佳精确度的迭代。这和神经网络的及早停止（early stopping）很像。如果你碰到过拟合问题，试一下这个会是个好主意。不过我没能在这一数据集上看到任何改善，大概是因为有这么多训练数据点，很难过拟合。

## CatBoost集成
集成指组合某种基础分类器的多个实例（或不同类型的分类器）为一个分类器。在CatBoost中，这意味着多次运行CatBoostClassify（比如10次），然后选择10个分类器中最常见的预测作为最终分类标签。一般而言，组成集成的每个分类器需要有一些差异——每个分类器犯的错不相关时我们能得到最好的结果，也就是说，分类器尽可能地不一样。

使用不同参数的CatBoost能给我们带来一些多样性。在网格搜索过程中，我们保存了我们测试的所有参数，以及相应的分数，这意味着，得到最佳的10个参数组合是一件轻而易举的事情。一旦我们具备了10个最佳参数组合，我们直接构建分类器集成，并选取结果的众数作为结果。对这一具体问题而言，我发现组合10个糟糕的参数设定，能够改善原本糟糕的结果，但集成看起来在调优过的设定上起不了多少作用。不过，由于大多数kaggle竞赛的冠军使用集成，一般而言，使用集成明显会有好处。


## 参考
[使用网格搜索优化CatBoost参数](https://www.jqr.com/article/000136)
[Yandex](https://tech.yandex.com/catboost/doc/dg/concepts/python-reference_train-docpage/)