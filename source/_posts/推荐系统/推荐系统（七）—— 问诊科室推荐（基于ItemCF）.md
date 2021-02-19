---
title: 推荐系统（七）—— 问诊科室推荐（基于ItemCF）
date: 2021-02-05 20:13:53
tags: 
    - 推荐系统
categories:
    - 推荐系统
---

## 问题定义：TOP-N 推荐
2020 年 11 月初腾讯健康上线了一个新首页版本，首页新增“健康推荐”区域，支持为用户个性化推荐不同工具和内容。当前健康推荐区域共提供 9 个推荐位，分多个 tab 页进行展示，每个 tab 页展示两个推荐位。当前推荐位排序依赖于用户历史行为和规则设定进行刷新。

当前问诊服务占据了其中一个推荐位，用户点击问诊服务即进入相应科室的医生列表。问诊科室众多，但对于每个用户来说，问诊推荐处只能展示一个科室的内容，如何将合适的科室推荐给合适的用户显得尤为重要：一方面可以帮助用户发现他们可能感兴趣的科室，另一方面也能将问诊科室推送给对它们感兴趣的用户。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210104152748.png" width="40%" heigh="55%"></img>
</div>

设 $U$ 代表腾讯健康所有潜在用户，$I$ 代表腾讯健康当前所有可访问的问诊科室，$f(u,i)$ 代表将科室 $i$ 推荐给用户 $u$ 所带来的效用，则腾讯健康问诊科室推荐问题可以被形式化定义为：

$$
\forall u \in U, {i}'=\underset{i\in I}{argmax}f(u,i)
$$

我们的核心目的是提高用户在问诊推荐模块的点击率，可以将用户 $u$ 对科室 $i$ 的点击倾向或兴趣度作为效用函数 $f(u,i)$。

## 问题求解：ItemCF
由于问诊场景的特殊性，我们一般认为用户的问诊行为主要取决于用户的内在需要，而和其他用户的行为无关。即使和用户 $u$ 相似的其他用户访问了某个科室 $i$，也并不会增加用户 $u$ 访问科室 $i$ 的可能性，UserCF 方法在此场景下的应用受限。因此，本文尝试使用基于内容的协同过滤算法来为每位用户生成 TOP-1 的最佳推荐，该方法基于以下理念：

> 为用户推荐那些和他历史行为最相关的科室；

基于 ItemCF 进行科室推荐的困难在于对腾讯健康所提供“商品”缺乏明确的实体定义，腾讯健康提供的“商品”更多的是一系列不同质的虚拟服务，比如资讯、挂号、问诊、绑卡等，如何定义出和问诊科室相关的“商品”是解决问题的关键。事实上，商品实体存在与否无关紧要，可观测、可区分的行为集合才是重要的。可以将“科室相关的行为集合”看做是问诊科室推荐问题中的“商品”，其中，直接用于衡量用户对科室兴趣度的行为集合称为“推荐/目标商品”，间接影响用户对“目标商品”兴趣度的行为集合称为“辅助商品”。

### 收集 User-Item 反馈数据
腾讯健康可观测到的科室相关行为整理如下：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210107150212.png" width="50%" heigh="55%"></img>
</div>

详情可参考[腾讯健康-科室相关行为](https://docs.qq.com/sheet/DZkFwdUZkS3VRSVJG)，以用户访问业务子类相关行为为例，科室信息可能以不同方式散落于扩展字段中 json 串、url 参数中：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210119194454.png" width="80%" heigh="55%"></img>
</div>

遍历近半年的用户行为日志，归纳出以下正则抽取现有各场景中出现的科室信息：

```scala
"""\W(?:departmentid|deptid|deptinnerid|seconddeptid|deptname)(?:":"|=)(\d+|[\u4e00-\u9fa5a-z/]+)\W"""
```

融合问诊订单数据、挂号订单数据、医生关注数据，得到如下“用户-科室反馈表”：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210119195227.png" width="80%" heigh="55%"></img>
</div>

我们基于时间维度（`f_date`）将“用户-科室反馈表”划分为训练集和验证集：

1. 训练集（`20200704 ≤ f_date ≤ 20201230`）：用于模型训练、生成推荐结果；
2. 验证集（`20210101 ≤ f_date ≤ 20210118`）：用于验证推荐结果

### 计算 User-Item 评分矩阵
基于 User-Item 反馈数据可以计算出每位用户 $u$ 对每个内容 $i$ 的“评分”，可以简单地用二值变量 $0-1$ 来表示用户是否对各项内容存在正反馈，也可以针对不同类型的用户反馈，给予不同的权重评分 $r_{ui}$：

$$
R = \left[
\begin{matrix}
 r_{11}      & r_{12}      & \cdots & r_{1\left | I \right |}      \\
 r_{21}      & r_{22}      & \cdots & r_{2\left | I \right |}       \\
 \vdots & \vdots & \ddots & \vdots \\
 r_{\left | U \right |1}      & r_{\left | U \right |2}      & \cdots & r_{\left | U \right |\left | I \right |}       \\
\end{matrix}
\right]
$$

其中：

$$
r_{ui}=
\left\{\begin{matrix}
0 & \mbox{用户 u 对内容 i 无正反馈}\\ 
1 & \mbox{else}
\end{matrix}\right.
$$

或：

$$
r_{ui}=
\left\{\begin{matrix}
0 & \mbox{用户 u 对内容 i 无正反馈}\\ 
w_{i} & \mbox{else}\ w_i\ \mbox{为内容 i 的权重}
\end{matrix}\right.
$$

在科室推荐问题中，我们对用户的不同行为赋以不同权值，权值越大代表该行为越能反映用户对科室的正反馈程度：

ID|类别|权值
:---:|:---:|:---:
1|访问大类|1
2|访问子类|2
3|关注医生|5
4|挂号订单|10
5|问诊订单|10

除了行为类型能够反映用户对科室的倾向值，用户的访问频次也是一个重要的因素，我们将用户在不同行为上的访问天数进行加权求和作为用户-科室评分：

$$
r_{ui} = \sum_{t=1}^{5} d_{uit} \times w_t
$$

其中：

- $d_{uit}$：用户 $u$ 在科室 $i$ 上发生第 $t$ 类行为的天数；
- $w_t$：我们所定义的第 $t$ 类行为的权重；

基于“用户-科室反馈表”（2020.07.04 ~ 2020.12.30 数据作为训练集）计算得到如下“用户-科室评分表”：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210119201724.png" width="80%" heigh="55%"></img>
</div>

### 计算 Item-Item 相似矩阵
基于用户-内容评分矩阵可以计算出内容-内容之间的相似矩阵：

$$
W = \left[
\begin{matrix}
 w_{11}      & w_{12}      & \cdots & w_{1\left | I \right |}      \\
 w_{21}      & w_{22}      & \cdots & w_{2\left | I \right |}       \\
 \vdots & \vdots & \ddots & \vdots \\
 w_{\left | I \right |1}      & w_{\left | I \right |2}      & \cdots & w_{\left | I \right |\left | I \right |}       \\
\end{matrix}
\right]
$$

其中，可以通过余弦相似度来计算不同内容间的相似性：

$$
w_{ij}=\frac{\left | N(i) \bigcap N(j) \right |}{\sqrt{\left | N(i) \right | \left | N(j) \right |}}
$$

- $N(i)$：表示对内容 $i$ 有过正反馈的用户集合

或：

$$
w_{ij}=\frac{\vec{r}_i\cdot \vec{r}_j}{\left | \vec{r}_i \right |\left | \vec{r}_j \right |}=\frac{\sum_{u \in U}r_{ui}r_{uj}}{\sqrt{\sum_{u\in U}r_{ui}^2}\sqrt{\sum_{u\in U}r_{uj}^2}}
$$

- $\vec{r}_i$：表示内容 $i$ 对应的用户评分向量

通过余弦相似度计算“科室-科室相似度”，参见[科室相似度](https://docs.qq.com/sheet/DZkFwdUZkS3VRSVJG?_t=1611056275983&tab=oxjqmz)：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210119202122.png" width="80%" heigh="55%"></img>
</div>

### 计算 User-Item 兴趣矩阵
在得到内容之间的相似度后，可以计算用户-内容的兴趣度矩阵：

$$
P = \left[
\begin{matrix}
 p_{11}      & p_{12}      & \cdots & p_{1\left | I \right |}      \\
 p_{21}      & p_{22}      & \cdots & p_{2\left | I \right |}       \\
 \vdots & \vdots & \ddots & \vdots \\
 p_{\left | U \right |1}      & p_{\left | U \right |2}      & \cdots & p_{\left | U \right |\left | I \right |}       \\
\end{matrix}
\right]
$$

其中：

$$
p(u,i)=\sum_{j \in S(i,K)\bigcap N(u)}r_{uj}w_{ji}
$$

- $S(i,K)$：和内容 $i$ 最相似的 $K$ 个内容集合（不包括 $i$）
- $N(u)$：用户 $u$ 有过正反馈的内容集合

“用户-科室兴趣度”计算结果如下：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210120193337.png" width="80%" heigh="55%"></img>
</div>

### 生成科室推荐
回到最初对问题的定义，我们基于以上 ItemCF 方法得到了一组问题的解：

$$
\forall u \in U, {i}'=\underset{i\in I}{argmax}\ p(u,i)
$$

当前推荐场景下，每次只会为用户推荐一个科室，系统优先为我推荐的科室为“口腔修复科”。事实上，我在 1 月 3 日做了智齿拔除手术，此前我曾尝试在腾讯健康预约牙医，可惜预约已满，没有预约成功。

### 冷启动处理
对于新用户或新科室冷启动问题的思考:

- 对于新用户推荐：可以通过为新用户推荐热门科室，作为兜底方案；
- 对于新科室推荐：可以根据科室信息，将科室推荐给访问过类似科室的用户；

## 代码实现
### 代码逻辑
代码实现逻辑参见工程 [SparkV3](https://git.code.oa.com/th_bigdata/SparkV3) `com.tencent.csig.healthy.model.recommend.itgdept`，其中涉及到的表 UML 参考下图：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/th_itemCF.png" width="80%" heigh="55%"></img>
</div>

### 任务调度
相关任务基于 Tesla 按天进行调度：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210120143608.png" width="80%" heigh="55%"></img>
</div>

## 效果评价
### 用户满意度
调研了几个同事对以上推荐结果的满意度，因为腾讯健康的同事多为测试用户，在腾讯健康上的行为不能代表他们的真实意图，有待调研实际场景下用户对推荐结果的看法：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210120141310.png" width="30%" heigh="55%"></img>
</div>

### 离线指标
离线指标主要关注推荐的准确率、召回率和覆盖率，$R(u)$ 代表基于训练集为用户 $u$ 生成的科室列表，$T(u)$ 是用户在测试集上实际访问的科室列表：

- 准确率（Precision）：

$$
Precision=\frac{\sum_{u \in U}\left | R(u)\bigcap T(u) \right |}{\sum_{u \in U}\left | R(u) \right |}
$$

- 召回率（Recall）：

$$
Recall=\frac{\sum_{u \in U}\left | R(u)\bigcap T(u) \right |}{\sum_{u \in U}\left | T(u) \right |}
$$

- 覆盖率（Coverage）：

$$
Coverage=\frac{\left | \bigcup _{u \in U} R(u)\right |}{\left | I \right |}
$$

- 命中率（Hit Rate）：如果测试用户 u 实际访问的 Item 出现在了系统为其推荐的 TOP-N 列表中，称为一次命中；$hits$ 为命中的测试集用户数，$\left | U \right|$ 为测试集总用户数，

$$
HR = \frac{hits}{\left | U \right |}
$$

- 加权命中率（Average Reciprocal Hit Rank）：假设 $p_{u1},...,p_{uh}$ 是 hits 的位置，即测试用户 u 实际访问的 item 在 TOP-N 推荐列表中的位置，$1\leq p_{ui}\leq N$，ARHR 衡量了一个 item 被推荐的强度

$$
ARHR = \frac{1}{\left | U \right |}\sum_{u \in U}\sum_{i=1}^{h}\frac{1}{p_{ui}}
$$

我们收集了验证集（ 2021.01.01 ~ 2021.01.18）中，有过科室反馈行为且被系统推荐的用户作为测试集，我们分别在不同的推荐列表长度（N）下，对本文所介绍的方法进行了离线验证，验证结果如下：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210120193606.png" width="80%" heigh="55%"></img>
</div>

1. 算法对科室的覆盖度都达到了 100%，所有标准科室都有机会被推荐出来；
2. 对于 TOP-1 推荐，算法的准确率和命中率有不错的表现，达到 73%；
3. 随着推荐列表长度的增大，推荐准确率逐渐下降，TOP-10推荐准确率只有14%，说明用户对推荐列表尾部科室兴趣不大；
4. 算法命中率和加权命中率无论在 TOP-1 还是 TOP-10 推荐中均有较高取值，说明推荐结果能够很好的命中用户对科室的兴趣；

### 在线指标
在线指标可以通过实施 AB 实验对比不同推荐策略对用户点击率的影响：

$$
CTR = \frac{\mbox{科室点击人数}}{\mbox{科室曝光人数}}\times 100\%
$$

## TODO
1. 定义与问诊科室访问相关的用户行为和权重；-- done
2. 用户历史行为数据清洗，关联标准问诊科室；-- done
3. 算法实现和测试；-- done
4. 离线评测与优化；-- done
5. 线上评测与优化；
6. 法务风险评估：用到了用户的文章阅读、词条点击、医生关注等数据，有潜在法务风险；

## 参考
`[1]` Sparse Linear Methods for Top-N Recommender Systems
`[2]` 之前简单整理过一些推荐系统相关的[笔记](https://liketea.xyz/%E6%8E%A8%E8%8D%90%E7%B3%BB%E7%BB%9F/%E6%8E%A8%E8%8D%90%E7%B3%BB%E7%BB%9F/%E6%8E%A8%E8%8D%90%E7%B3%BB%E7%BB%9F%EF%BC%88%E4%BA%8C%EF%BC%89%E2%80%94%E2%80%94%20%E5%9F%BA%E4%BA%8E%E7%94%A8%E6%88%B7%E8%A1%8C%E4%B8%BA%E6%8E%A8%E8%8D%90/)，可做参考