---
title: 数据科学：时间序列（一）—— ETS 预估 DAU
date: 2020-06-12 17:01:09
tags: 
    - 数据科学
categories:
    - 数据科学
---


```python
import itertools
import warnings

import pandas as pd
import numpy as np
import seaborn as sns
from matplotlib import cm
import matplotlib as mpl
import matplotlib.pyplot as plt
import datetime
from matplotlib.ticker import FuncFormatter
from dateutil.parser import parse
from statsmodels.tsa.arima_model import ARIMA
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.stattools import adfuller
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.stats.diagnostic import acorr_ljungbox
import statsmodels.tsa.stattools as ts
import statsmodels.api as sm
from sklearn.metrics import mean_squared_error
from statsmodels.tsa.api import ExponentialSmoothing
from mpl_toolkits.mplot3d import Axes3D
from datetime import datetime, timedelta
warnings.filterwarnings("ignore") 
# register the converters
from pandas.plotting import register_matplotlib_converters
register_matplotlib_converters()
# 打印图像
%matplotlib inline 
# 定义种子
np.random.seed(sum(map(ord,"aesthetics")))  
# 取消科学计数
pd.set_option('display.float_format',lambda x : '%.2f' % x)
# 显示中文
mpl.rcParams['font.sans-serif'] = ['SimHei']
mpl.rcParams['font.serif'] = ['SimHei']
mpl.rcParams['axes.formatter.useoffset'] = False
# 解决保存图像是负号'-'显示为方块的问题
plt.rcParams['axes.unicode_minus'] = False
# 解决Seaborn中文显示问题并调整字体大小
sns.set_style("darkgrid",{"font.sans-serif":['SimHei', 'Arial']})
# 设置图片分辨率
plt.rcParams['savefig.dpi'] = 150 
plt.rcParams['figure.dpi'] = 150 

# plt.gcf().autofmt_xdate()
```


```python
def plot_2d(data, title, figsize=(18,5)):
    plt.figure(figsize=figsize)
    plt.title(title)
    data.plot()
    
def plot_3d_surface(X, Y, Z, figsize=(18,10)):
    fig = plt.figure(figsize=figsize)
    ax = Axes3D(fig)
    # 选色带 https://matplotlib.org/3.2.1/tutorials/colors/colormaps.html
    # cmap: rainbow  coolwarm jet PiYG
    surf = ax.plot_surface(X, Y, Z * 100,
                           rstride=1, cstride=1,
                           cmap='coolwarm',
                           linewidth=0.1,
                           shade=True,
                           alpha=0.8,
                           norm=mpl.colors.Normalize(vmin=-1., vmax=40)
                           )
    # ax.contourf(X, Y, Z*100, zdir='y', offset=121, cmap=cm.coolwarm)
    # ax.set_xlim(-10, 120)

    ax.set_xlabel('N days')
    ax.set_ylabel('date')
    ax.set_zlabel('ratio(%)')
    # ax.set_title('Retention rate of new users')
    fig.colorbar(surf, shrink=0.6, aspect=6)
    plt.show()

def df_show(df, m=5, n=5):
    print('shape={}'.format(df.shape))
    return pd.concat([df.head(m),df.tail(n)])
    
```

## 原理

$$
\begin{align*}
DAU_0 &=  \sum_{k=0}^{\infty }(DAU_{k}^{new}\times r_k)\\
& = DAU_0^{new} \times r_0 + \sum_{k=1}^{K-1} DAU_k^{new}  \times r_K +DAU_K^{new} \times r_K\\
& = DAU_0^{new} + \sum_{k=1}^{K-1} DAU_k^{new}  \times r_k +DAU_K \times r_K\\
\end{align*}
$$

- $k$：k 天前
- $r_k$：k 天前新用户第 k 日留存
- $s_k$：k 天前新用户占比
- $K$：历史新老用户分解线，比如将2019年前所有用户当做老用户，之后的新用户看做是新用户



## 数据


```python
def get_dau(path='./data/0610_dau.xlsx', usecols=['f_date', 'dau'], index_col=0, parse_dates=['f_date']):
    data = pd.read_excel(io=path, usecols=usecols, index_col=index_col, parse_dates=parse_dates).dau * 10000
    data.index = pd.DatetimeIndex(data.index, freq='D')
    return data.astype(int)

def get_dau_arima(path='./data/0610_dau_arima.xlsx', usecols=['f_date', 'DAU'], index_col=0, parse_dates=['f_date']):
    data = pd.read_excel(io=path, usecols=usecols, index_col=index_col, parse_dates=parse_dates).DAU
    data.index = pd.DatetimeIndex(data.index, freq='D')
    return data.astype(int)

def get_dau_new(path='./data/0610_dau_new.xlsx', usecols=['f_date', 'f_dau_new'], index_col=0, parse_dates=['f_date']):
    data = pd.read_excel(io=path, usecols=usecols, index_col=index_col, parse_dates=parse_dates).f_dau_new
    data.index = pd.DatetimeIndex(data.index, freq='D')
    return data


def get_retention_new(path='./data/0610_retention_new.xlsx',
                      usecols=['f_visit_day', 'f_remain_days', 'f_ratio'],
                      parse_dates=['f_visit_day']):
    data = pd.read_excel(io=path, usecols=usecols, parse_dates=parse_dates)
    data = data.drop_duplicates(['f_visit_day', 'f_remain_days'], keep='last') \
        .set_index(['f_visit_day', 'f_remain_days']) \
        .unstack() \
        .sort_index() \
        .f_ratio
    data.index = pd.DatetimeIndex(data.index, freq='D')
    # pd.to_datetime(datetime.date.today() - datetime.timedelta(121))
    data = data.loc['2020-01-01':]
    return data


def get_retention_old(path='./data/0610_retention_old.xlsx', usecols=['f_date', 'f_ratio'],
                      index_col=0, parse_dates=['f_date']):
    data = pd.read_excel(io=path, usecols=usecols, index_col=index_col, parse_dates=parse_dates).f_ratio
    data.index = pd.DatetimeIndex(data.index, freq='D')
    return data
```

### 小程序 DAU


```python
dau = get_dau()
plot_2d(dau.loc['2020-03-01':], u'DAU')
```


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_5_0.png)



```python
df_show(dau, 10, 10)
```

    shape=(524,)

    f_date
    2019-01-04       2960
    2019-01-05       2318
    2019-01-06       2274
    2019-01-07       2601
    2019-01-08       2520
    2019-01-09       2514
    2019-01-10       2315
    2019-01-11       2179
    2019-01-12       1947
    2019-01-13       1813
    2020-06-01    3994272
    2020-06-02    3546456
    2020-06-03    3248834
    2020-06-04    3129509
    2020-06-05    3216982
    2020-06-06    2895258
    2020-06-07    2926685
    2020-06-08    3023940
    2020-06-09    2911481
    2020-06-10    2737987
    Name: dau, dtype: int64



### 新增用户


```python
s_dau_new = get_dau_new()
df_show(s_dau_new)
```

    shape=(161,)





    f_date
    2020-01-01    183431
    2020-01-02    175389
    2020-01-03    172991
    2020-01-04    157629
    2020-01-05    158287
    2020-06-05    440420
    2020-06-06    419283
    2020-06-07    409955
    2020-06-08    422092
    2020-06-09    412235
    Name: f_dau_new, dtype: int64




```python
# '2020-03-01':
plot_2d(s_dau_new.loc[:], u'新增用户')
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_9_0.png)


### 新用户留存


```python
df_ret_new = get_retention_new()
df_show(df_ret_new)
```

    shape=(160, 120)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th>f_remain_days</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>10</th>
      <th>...</th>
      <th>111</th>
      <th>112</th>
      <th>113</th>
      <th>114</th>
      <th>115</th>
      <th>116</th>
      <th>117</th>
      <th>118</th>
      <th>119</th>
      <th>120</th>
    </tr>
    <tr>
      <th>f_visit_day</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-01-01</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-02</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-03</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-04</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-05</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>0.03</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>0.04</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
<p>10 rows × 120 columns</p>
</div>




```python
df_ret_new_plot = df_ret_new.loc['2020-02-10':]
X = df_ret_new_plot.columns
Y = (df_ret_new_plot.index - df_ret_new_plot.index.min()).map(lambda x: x.days)
X, Y = np.meshgrid(X,Y)
Z = df_ret_new_plot.values.astype(np.double)

plot_3d_surface(X, Y, Z, figsize=(18, 8))
```


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_12_0.png)


### 老用户留存


```python
s_ret_old = get_retention_old()
df_show(s_ret_old)
```

    shape=(101,)





    f_date
    2020-03-01   0.05
    2020-03-02   0.05
    2020-03-03   0.04
    2020-03-04   0.04
    2020-03-05   0.04
    2020-06-05   0.01
    2020-06-06   0.01
    2020-06-07   0.01
    2020-06-08   0.01
    2020-06-09   0.01
    Name: f_ratio, dtype: float64




```python
plot_2d(s_ret_old,u'老用户留存')
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_15_0.png)

## 模型


```python

class MyEts:
    def __init__(self, s_dau_new, df_ret_new, s_ret_old, base_date, pred_start_date,
                 n_forcast=7, dau_old=273385370, n_train=90):
        """
        Args:
            s_dau_new: pd.Series 新增用户DAU
            df_ret_new: pd.DataFrame 新用户留存矩阵
            s_ret_old: pd.Series 老用户留存率
            base_date: String 新老用户边界日期，新用户最早日期
            pred_start_date: String 开始预测日期
            n_forcast: int 预测天数
            dau_old: 老用户总数
            n_train: 训练集容量
        """
        self.base_date = pd.to_datetime(base_date)
        self.pred_start_date_origin = pd.to_datetime(pred_start_date)
        self.pred_end_date_origin = self.pred_start_date_origin + timedelta(n_forcast - 1)

        # 数据末端对齐, 重新定义开始预估日期和预估长度
        max_dau_new_date = s_dau_new.index.max()
        max_ret_new_date = df_ret_new.index.max() + timedelta(1)
        max_ret_old_date = s_ret_old.index.max()
        end_date = min(max_dau_new_date, max_ret_new_date, max_ret_old_date, self.pred_start_date_origin - timedelta(1))

        self.s_dau_new = s_dau_new.loc[: end_date]
        self.df_ret_new = df_ret_new.loc[: end_date - timedelta(1)]
        self.s_ret_old = s_ret_old.loc[: end_date]
        self.pred_start_date = end_date + timedelta(1)
        self.pred_end_date = self.pred_end_date_origin
        self.n_forcast = (self.pred_end_date - self.pred_start_date).days + 1

        self.n_train = n_train
        self.n_offset = (self.pred_start_date - self.base_date).days
        self.n_forcast = n_forcast

        self.dau_old = dau_old
        self.ratio_matrix = None
        self.dau_matrix = None
        self.df_result = pd.DataFrame(index=pd.date_range(self.pred_start_date, self.pred_end_date))

    def ets(self, s_train, trend='add', seasonal='add', seasonal_periods=7, damped=False,
            smoothing_level=None, smoothing_slope=None, smoothing_seasonal=None, damping_slope=None,
            use_boxcox=False, remove_bias=False):
        """
        指数平滑，返回未来 n_forcast 天的预估值构成的Series
        :s_train 训练集 Series
        :n_forcast 预测天数
        :trend 趋势类型
        :seasonal 季节类型
        :seasonal_periods 季节周期
        """
        model = ExponentialSmoothing(s_train,
                                     trend=trend,
                                     seasonal=seasonal,
                                     seasonal_periods=seasonal_periods,
                                     damped=damped).fit(smoothing_level=smoothing_level,
                                                        smoothing_slope=smoothing_slope,
                                                        smoothing_seasonal=smoothing_seasonal,
                                                        damping_slope=damping_slope,
                                                        use_boxcox=use_boxcox,
                                                        remove_bias=remove_bias)
        pred_result = model.forecast(self.n_forcast)
        return pred_result

    def arima(self, train, pdq, pdqs, trend):
        """
        arima 模型: 输入训练集和预测未来天数，返回预测结果Series
        """
        train_log = np.log(train.loc[self.base_date:])
        model = sm.tsa.statespace.SARIMAX(train_log,
                                          order=pdq,
                                          seasonal_order=pdqs,
                                          trend=trend,
                                          measurement_error=False,
                                          time_varying_regression=False,
                                          mle_regression=True,
                                          simple_differencing=False,
                                          enforce_stationarity=True,
                                          enforce_invertibility=True,
                                          hamilton_representation=False,
                                          concentrate_scale=False
                                          ).fit()

        pred_result = model.predict(self.pred_start_date, self.pred_end_date, dynamic=True, typ='levels')
        return np.exp(pred_result)

    def pred_dau_new(self, trend=None, seasonal='add', seasonal_periods=7, damped=False, use_boxcox=False, model='ets',
                     smoothing_level=None, smoothing_slope=None, smoothing_seasonal=None, damping_slope=None):
        """
        预测新用户 DAU，返回Series；
        将 base_date 之前的老用户 DAU 算作第零天 DAU
        """
        s_train_data = self.s_dau_new
        if model == 'ets':
            s_pred_data = self.ets(s_train_data,
                                   trend=trend,
                                   seasonal=seasonal,
                                   seasonal_periods=seasonal_periods,
                                   damped=damped,
                                   use_boxcox=use_boxcox,
                                   smoothing_level=smoothing_level,
                                   smoothing_slope=smoothing_slope,
                                   smoothing_seasonal=smoothing_seasonal,
                                   damping_slope=damping_slope,
                                   remove_bias=True)
        elif model == 'arima':
            s_pred_data = self.arima(s_train_data, pdq=[1, 2, 0], pdqs=[3, 0, 2, 7], trend='c')
        else:
            raise Exception('请输入正确的model: ets 或者 arima')
        s_pred_data = pd.concat([s_train_data, s_pred_data]).loc[self.base_date: self.pred_end_date]
        s_pred_data[pd.to_datetime(self.base_date) - timedelta(1)] = self.dau_old
        s_pred_data = s_pred_data.sort_index()
        return s_pred_data

    def pred_ret_new(self, trend='add', seasonal='add', seasonal_periods=7, damped=False, use_boxcox=False,
                     smoothing_level=None, smoothing_slope=None, smoothing_seasonal=None, damping_slope=None):
        """
        预测新用户第 N 日留存率，返回 DataFrame shape=(self.n_offset + self.n_forcast, self.n_offset + self.n_forcast)
        加上第 0 日留存的一列
        """
        pred_matrix = pd.DataFrame(index=pd.date_range(self.base_date, self.pred_end_date))

        # todo 数据源数据不全检查 for n in range(98,100):
        for n in range(self.n_offset + self.n_forcast):
            if not n:
                pred_matrix[n] = 1
            else:
                train_start_date = min(self.pred_start_date - timedelta(n + self.n_train), self.base_date)
                train_end_date = self.pred_start_date - timedelta(n + 1)
                s_train_data = self.df_ret_new.loc[train_start_date:train_end_date, n]
                s_pred_data = self.ets(s_train_data,
                                       trend=trend,
                                       seasonal=seasonal,
                                       seasonal_periods=seasonal_periods,
                                       damped=damped,
                                       use_boxcox=use_boxcox,
                                       smoothing_level=smoothing_level,
                                       smoothing_slope=smoothing_slope,
                                       smoothing_seasonal=smoothing_seasonal,
                                       damping_slope=damping_slope,
                                       remove_bias=True)
                pred_matrix[n] = pd.concat([s_train_data, s_pred_data]).sort_index()
        pred_matrix.sort_index(axis=1)
        return pred_matrix

    def pred_ret_old(self, trend='add', seasonal='add', seasonal_periods=7, damped=False, use_boxcox=False,
                     smoothing_level=0.5, smoothing_slope=None, smoothing_seasonal=None, damping_slope=None):
        """
        预测老用户第 N 日留存率，返回时间序列 DataFrame
        转化为和新用户留存率矩阵行的形式，并加上第0日留存率=1
        """
        s_train_data = self.s_ret_old.copy()
        s_pred_data = self.ets(s_train_data,
                               trend=trend,
                               seasonal=seasonal,
                               seasonal_periods=seasonal_periods,
                               damped=damped,
                               use_boxcox=use_boxcox,
                               smoothing_level=smoothing_level,
                               smoothing_slope=smoothing_slope,
                               smoothing_seasonal=smoothing_seasonal,
                               damping_slope=damping_slope,
                               remove_bias=True)
        min_index = pd.to_datetime(self.base_date) - timedelta(1)
        s_train_data[min_index] = 1
        result = pd.concat([s_train_data, s_pred_data]).sort_index()
        result = result.loc[min_index: self.pred_end_date].to_frame('ratio')
        result['date'] = min_index
        result['offset'] = (result.index - min_index).map(lambda x: x.days)
        result = result.pivot(index='date', columns='offset', values='ratio').rename_axis(index=None, columns=None)
        result = result.sort_index().sort_index(axis=1)
        return result

    def predict(self):
        """
        综合预测未来DAU
        """
        df_dau_new = self.pred_dau_new(trend='add',
                                       seasonal='add',
                                       seasonal_periods=7,
                                       damped=True,
                                       use_boxcox=False,
                                       model='ets',
                                       smoothing_level=0.8,
                                       smoothing_slope=0.9,
                                       smoothing_seasonal=None,
                                       damping_slope=0.85)
        df_ratio_new = self.pred_ret_new(trend='add',
                                         seasonal='add',
                                         seasonal_periods=7,
                                         damped=False,
                                         use_boxcox=False,
                                         smoothing_level=0.9,
                                         smoothing_slope=0.7,
                                         smoothing_seasonal=None,
                                         damping_slope=0.75)

        df_ratio_old = self.pred_ret_old()

        self.ratio_matrix = pd.concat([df_ratio_old, df_ratio_new]).sort_index().sort_index(axis=1)
        self.dau_matrix = self.ratio_matrix.mul(df_dau_new, axis='index')

        self.df_result['total_dau'] = [np.sum(np.diag(np.fliplr(np.array(self.dau_matrix)), d)) for d in
                                       range(self.n_forcast - 1, -1, -1)]
        return self.df_result

    @classmethod
    def rmse(cls, predictions, targets):
        """
        计算序列 predictions 和 targets 的均方根误差率
        Args:
            predictions:
            targets:

        Returns:
        """
        return np.sqrt((((predictions - targets) / targets) ** 2).mean())

    @classmethod
    def predict_compare(cls, predictions, targets, title):
        """
        计算误差率，绘制图形
        """
        pred_index = targets.index
        compare = pd.concat([targets, predictions], axis=1)
        colname_origin, colname_predict = '{}_origin'.format(targets.name), '{}_predict'.format(targets.name)
        compare.columns = [colname_origin, colname_predict]
        compare['{}_diff'.format(targets.name)] = compare[colname_predict] - compare[colname_origin]
        compare['{}_rate'.format(targets.name)] = compare['{}_diff'.format(targets.name)] / compare[colname_origin]

        fig = plt.figure(figsize=(18, 8))
        plt.plot(compare.index, compare[colname_origin], label=colname_origin)
        plt.plot(compare.index, compare[colname_predict], label=colname_predict)
        plt.legend()
        plt.title(u'预估效果对比:{}'.format(title))
        plt.xticks(rotation=30)
        rmse_rate = cls.rmse(predictions, targets[predictions.index])
        print('RMSE={}'.format(rmse_rate))
        return compare
```


```python
base_date, pred_start_date = pd.to_datetime('2020-03-01'), pd.to_datetime('2020-06-01')
n_forcast = 10
pred_end_date = pred_start_date + timedelta(n_forcast-1)
myets = MyEts(s_dau_new, df_ret_new, s_ret_old, 
              base_date=base_date, pred_start_date=pred_start_date, n_forcast=n_forcast)
pred_start_date, pred_end_date
```




    (Timestamp('2020-06-01 00:00:00'), Timestamp('2020-06-10 00:00:00'))



### 新增用户

#### ARIMA

##### 平稳性检验


```python
def judge_stationarity(data_sanya_one):
    """
    平稳性检验
    """
    dftest = ts.adfuller(data_sanya_one)
    print(dftest)
    dfoutput = pd.Series(dftest[0:4], index=['Test Statistic','p-value','#Lags Used','Number of Observations Used'])
    stationarity = 1
    for key, value in dftest[4].items():
        dfoutput['Critical Value (%s)'%key] = value 
        if dftest[0] > value:
            stationarity = 0
    print(dfoutput)
    print("数据是否平稳(1/0): %d" %(stationarity))
    return stationarity

def season_resolve(data):
    """
    季节性分解：observed = trend + seasonal + residual
    """
    decomposition = seasonal_decompose(data)
    trend = decomposition.trend
    seasonal = decomposition.seasonal
    residual = decomposition.resid
    
    fig = decomposition.plot()
    fig.set_size_inches(6, 4)
    print("test: p={}".format(ts.adfuller(seasonal)[1]))
    # 残差是否平稳
    stationarity = judge_stationarity(residual.dropna())

s_dau_new_log = np.log(myets.s_dau_new.loc['2020-03-01':])
s_dau_new_log_diff = s_dau_new_log.diff().dropna()
s_dau_new_log_diff2 = s_dau_new_log_diff.diff().dropna()
season_resolve(s_dau_new_log)
```

    test: p=0.0
    (-3.387682117502709, 0.01138602363842863, 11, 74, {'5%': -2.9014701097664504, '1%': -3.5219803175527606, '10%': -2.58807215485756}, -100.45009341551648)
    Test Statistic                -3.39
    p-value                        0.01
    #Lags Used                    11.00
    Number of Observations Used   74.00
    Critical Value (5%)           -2.90
    Critical Value (1%)           -3.52
    Critical Value (10%)          -2.59
    dtype: float64
    数据是否平稳(1/0): 0


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_22_1.png)



```python
season_resolve(s_dau_new_log_diff)
```

    test: p=0.0
    (-5.650643581278351, 9.878845977099614e-07, 9, 75, {'5%': -2.9009249540740742, '1%': -3.520713130074074, '10%': -2.5877813777777776}, -88.7065598940126)
    Test Statistic                -5.65
    p-value                        0.00
    #Lags Used                     9.00
    Number of Observations Used   75.00
    Critical Value (5%)           -2.90
    Critical Value (1%)           -3.52
    Critical Value (10%)          -2.59
    dtype: float64
    数据是否平稳(1/0): 1


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_23_1.png)

```python
season_resolve(s_dau_new_log_diff2)
```

    test: p=0.0
    (-5.898783625957804, 2.8100827285187457e-07, 11, 72, {'5%': -2.9026070739026064, '1%': -3.524624466842421, '10%': -2.5886785262345677}, -68.75760108315257)
    Test Statistic                -5.90
    p-value                        0.00
    #Lags Used                    11.00
    Number of Observations Used   72.00
    Critical Value (5%)           -2.90
    Critical Value (1%)           -3.52
    Critical Value (10%)          -2.59
    dtype: float64
    数据是否平稳(1/0): 1



![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_24_1.png)


##### 自相关图


```python
def plot_acf_pacf(df_list):
    """
    绘制自相关图，偏自相关图
    """
    n = len(df_list)
    base_num = 100 * n + 20
    plt.figure(figsize=(16, 3 * n)) 
    plt.subplots_adjust(wspace =0.1, hspace =0.3)
    for i in range(n):
        tmp = base_num + 2 * i + 1
        one_1 = plot_acf(df_list[i], lags=40, title= u'ACF', ax=plt.subplot(tmp))
        one_2 = plot_pacf(df_list[i], lags=40, title= u'PACF', ax=plt.subplot(tmp+1))
    
```


```python
plot_acf_pacf([s_dau_new_log, s_dau_new_log_diff])
```


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_27_0.png)

##### 网格搜索


```python
def parameter_selection(df, ps=[0,1,2], ds=[2], qs=[0,1,2]):
    """
    通过网格搜索对模型p,d,q进行定阶，取损失最小
    """
    pdqs = [(x[0], x[1], x[2]) for x in itertools.product(ps, ds, qs)]
    best_bic = 1000000.0
    best_pdqs = None
    for param in pdqs:
        p, d, q = param
        try:
            model = ARIMA(df, (p, d, q))
            results = model.fit()
            bic = results.aic
            print('{} - BIC:{}'.format(param, bic))
            if bic < best_bic:
                best_bic = bic
                best_pdqs = param
        except Exception as e:
            pass
#             print 'error:{}'.format(e)
    print '最优参数：x{} - AIC:{}'.format(best_pdqs, best_bic)
    return best_pdqs, best_bic
    
```


```python
matrix = parameter_selection(s_dau_new_log, ps=range(4), qs=range(4))
```

    (0, 2, 0) - BIC:15.5504937045
    (0, 2, 1) - BIC:-3.90439313959
    (0, 2, 2) - BIC:-16.7008738132
    (1, 2, 0) - BIC:13.7741898435
    (1, 2, 1) - BIC:-13.1288961798
    (1, 2, 2) - BIC:-14.7089870806
    (1, 2, 3) - BIC:-13.2074940281
    (2, 2, 0) - BIC:0.12566262446
    (2, 2, 1) - BIC:-14.3782928385
    (2, 2, 2) - BIC:-13.0656053424
    (2, 2, 3) - BIC:-13.1196434498
    (3, 2, 0) - BIC:-1.77302826664
    (3, 2, 1) - BIC:-13.5275309286
    (3, 2, 2) - BIC:-10.9182600295
    (3, 2, 3) - BIC:-10.6767970671
    最优参数：x(0, 2, 2) - AIC:-16.7008738132



```python
def max_node(p, d, q, P, D, Q, s):
    return d + D * s + max(3 * q + 1, 3 * Q * s + 1, p, P * s) + 1 
def get_arima_params(data, pdq, ps=[0,1,2], ds=[0,1,2], qs=[0,1,2], m=7):
    """
    通过网格搜索确定季节ARIMA的最优参数
    @data: 用于拟合的数据源
    @pdq: 最优非季节性参数元组(p, d, q)
    @季节性周期
    """
    p, d, q = pdq
    seasonal_pdq = [(x[0], x[1], x[2], m) for x in list(itertools.product(ps, ds, qs))]
    score_aic = 1000000.0
    warnings.filterwarnings("ignore") 
    for param_seasonal in seasonal_pdq:
        P, D, Q, s = param_seasonal
        try:
            mod = sm.tsa.statespace.SARIMAX(data,
                                            order=pdq,
                                            seasonal_order=param_seasonal,
                                            enforce_stationarity=False,
                                            enforce_invertibility=False)
            results = mod.fit()
            print('x{} - AIC:{} need {} observations'.format(param_seasonal, results.aic, max_node(p, d, q, P, D, Q, s)))
            if results.aic < score_aic:
                score_aic = results.aic
                params = param_seasonal, results.aic
        except Exception as e:
            print 'error:{}'.format(e)
            pass
    param_seasonal, results.aic = params
    print('最优参数：x{} - AIC:{}'.format(param_seasonal, results.aic))
```


```python
pdq = [0, 2, 2]
get_arima_params(s_dau_new_log, pdq, range(4),range(3), range(3), 7)
```

    x(0, 0, 0, 7) - AIC:-15.9235194034 need 10 observations
    x(0, 0, 1, 7) - AIC:-14.7113328488 need 25 observations
    x(0, 0, 2, 7) - AIC:-29.4064147183 need 46 observations
    x(0, 1, 0, 7) - AIC:63.48723362 need 17 observations
    x(0, 1, 1, 7) - AIC:-2.14367734565 need 32 observations
    x(0, 1, 2, 7) - AIC:-11.8848525187 need 53 observations
    x(0, 2, 0, 7) - AIC:141.898368919 need 24 observations
    x(0, 2, 1, 7) - AIC:39.8814708492 need 39 observations
    x(0, 2, 2, 7) - AIC:2.67172770386 need 60 observations
    x(1, 0, 0, 7) - AIC:-13.7461303101 need 10 observations
    x(1, 0, 1, 7) - AIC:-13.4284053199 need 25 observations
    x(1, 0, 2, 7) - AIC:-30.6083506043 need 46 observations
    x(1, 1, 0, 7) - AIC:26.5931599614 need 17 observations
    x(1, 1, 1, 7) - AIC:11.54952856 need 32 observations
    x(1, 1, 2, 7) - AIC:-11.5907261101 need 53 observations
    x(1, 2, 0, 7) - AIC:79.078108805 need 24 observations
    x(1, 2, 1, 7) - AIC:47.7740298619 need 39 observations
    x(1, 2, 2, 7) - AIC:6.90057268677 need 60 observations
    x(2, 0, 0, 7) - AIC:-41.7769269787 need 17 observations
    x(2, 0, 1, 7) - AIC:-40.1960951619 need 25 observations
    x(2, 0, 2, 7) - AIC:-37.2401608236 need 46 observations
    x(2, 1, 0, 7) - AIC:-9.33829251277 need 24 observations
    x(2, 1, 1, 7) - AIC:-19.2066580221 need 32 observations
    x(2, 1, 2, 7) - AIC:-22.4909020767 need 53 observations
    x(2, 2, 0, 7) - AIC:25.240615073 need 31 observations
    x(2, 2, 1, 7) - AIC:18.7858056712 need 39 observations
    x(2, 2, 2, 7) - AIC:11.9538869508 need 60 observations
    x(3, 0, 0, 7) - AIC:-38.0001167775 need 24 observations
    x(3, 0, 1, 7) - AIC:-45.2099169457 need 25 observations
    x(3, 0, 2, 7) - AIC:-49.2523157208 need 46 observations
    x(3, 1, 0, 7) - AIC:-32.9888239169 need 31 observations
    x(3, 1, 1, 7) - AIC:-31.4343836764 need 32 observations
    x(3, 1, 2, 7) - AIC:-30.8665326957 need 53 observations
    x(3, 2, 0, 7) - AIC:8.55482266627 need 38 observations
    x(3, 2, 1, 7) - AIC:-4.72304771546 need 39 observations
    x(3, 2, 2, 7) - AIC:-3.35845958847 need 60 observations
    最优参数：x(3, 0, 2, 7) - AIC:-49.2523157208



```python
pred_dau_arima = myets.arima(train=myets.s_dau_new, 
                             pdq=[0,2,2], 
                             pdqs=[3, 0, 2, 7],
                             trend='t'
                            )
pred_dau_arima_diff = myets.predict_compare(pred_dau_arima.loc[pred_start_date: pred_end_date], 
                                          s_dau_new.loc['2020-03-01':], u'新用户第N日留存率-ARIMA')
```

    RMSE=0.078732475591



![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_33_1.png)



```python
df_show(pred_dau_arima_diff.loc[pred_start_date: pred_end_date], 0, 14).dropna()
```

    shape=(10, 4)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>f_dau_new_origin</th>
      <th>f_dau_new_predict</th>
      <th>f_dau_new_diff</th>
      <th>f_dau_new_rate</th>
    </tr>
    <tr>
      <th>f_date</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-06-01</th>
      <td>588936.00</td>
      <td>566249.56</td>
      <td>-22686.44</td>
      <td>-0.04</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>507322.00</td>
      <td>529802.47</td>
      <td>22480.47</td>
      <td>0.04</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>459898.00</td>
      <td>516113.69</td>
      <td>56215.69</td>
      <td>0.12</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>434520.00</td>
      <td>486794.93</td>
      <td>52274.93</td>
      <td>0.12</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>440420.00</td>
      <td>451129.71</td>
      <td>10709.71</td>
      <td>0.02</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>419283.00</td>
      <td>455463.38</td>
      <td>36180.38</td>
      <td>0.09</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>409955.00</td>
      <td>433574.34</td>
      <td>23619.34</td>
      <td>0.06</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>422092.00</td>
      <td>398749.40</td>
      <td>-23342.60</td>
      <td>-0.06</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>412235.00</td>
      <td>374202.33</td>
      <td>-38032.67</td>
      <td>-0.09</td>
    </tr>
  </tbody>
</table>
</div>



#### ETS


```python
pred_dau_new = myets.pred_dau_new(trend='add',
                                  seasonal='add', 
                                  seasonal_periods=7, 
                                  damped=True, 
                                  use_boxcox=False, 
                                  model='ets',
                                  smoothing_level=0.8, 
                                  smoothing_slope=0.9, 
                                  smoothing_seasonal=None, 
                                  damping_slope=0.85)
pred_dau_new_diff = myets.predict_compare(pred_dau_new.loc[pred_start_date: pred_end_date], 
                                          s_dau_new.loc['2020-03-01':], u'新用户第N日留存率-ETS')


```

    RMSE=0.0654776482142


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_36_1.png)



```python
df_show(pred_dau_new_diff.loc[pred_start_date: pred_end_date],0,14).dropna()
```

    shape=(10, 4)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>f_dau_new_origin</th>
      <th>f_dau_new_predict</th>
      <th>f_dau_new_diff</th>
      <th>f_dau_new_rate</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-06-01</th>
      <td>588936.00</td>
      <td>563557.69</td>
      <td>-25378.31</td>
      <td>-0.04</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>507322.00</td>
      <td>518941.51</td>
      <td>11619.51</td>
      <td>0.02</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>459898.00</td>
      <td>517735.65</td>
      <td>57837.65</td>
      <td>0.13</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>434520.00</td>
      <td>486268.62</td>
      <td>51748.62</td>
      <td>0.12</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>440420.00</td>
      <td>463959.35</td>
      <td>23539.35</td>
      <td>0.05</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>419283.00</td>
      <td>431672.77</td>
      <td>12389.77</td>
      <td>0.03</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>409955.00</td>
      <td>417944.87</td>
      <td>7989.87</td>
      <td>0.02</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>422092.00</td>
      <td>416701.86</td>
      <td>-5390.14</td>
      <td>-0.01</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>412235.00</td>
      <td>394114.05</td>
      <td>-18120.95</td>
      <td>-0.04</td>
    </tr>
  </tbody>
</table>
</div>



### 新用户留存


```python
df_show(df_ret_new,3,10)
```

    shape=(160, 120)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th>f_remain_days</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>10</th>
      <th>...</th>
      <th>111</th>
      <th>112</th>
      <th>113</th>
      <th>114</th>
      <th>115</th>
      <th>116</th>
      <th>117</th>
      <th>118</th>
      <th>119</th>
      <th>120</th>
    </tr>
    <tr>
      <th>f_visit_day</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-01-01</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-02</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-01-03</th>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-05-30</th>
      <td>0.11</td>
      <td>0.05</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-31</th>
      <td>0.07</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>0.05</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>0.05</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>0.03</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>0.04</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
<p>13 rows × 120 columns</p>
</div>



#### 新用户第 N 日留存预估


```python
def predict_ret_new_n(n):
    train_start_date = myets.pred_start_date - timedelta(n + myets.n_train)
    train_end_date = myets.pred_start_date - timedelta(n + 1)
    s_train_data = myets.df_ret_new.loc[train_start_date:train_end_date, n]
    s_pred_data = myets.ets(s_train_data,
                           trend='add',
                           seasonal='add',
                           seasonal_periods=7,
                           damped=True, 
                           use_boxcox=False,
                           smoothing_level=0.8, 
                           smoothing_slope=0.75, 
                           smoothing_seasonal=None, 
                           damping_slope=0.76)
    return s_pred_data

# n = 18
for n in range(1,3):
    s_ret_new_n = df_ret_new.loc[:, n].dropna()
    pred_ret_new_n = predict_ret_new_n(n)
    pred_dau_new_diff = myets.predict_compare(pred_ret_new_n, s_ret_new_n.loc['2020-03-01':],n)



```

    RMSE=0.227393637754
    RMSE=1.19606960639



![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_41_1.png)


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_41_2.png)


#### 新用户第 N 日留存预估矩阵


```python
pred_ret_new_ratio = myets.pred_ret_new(trend=None,
                                 seasonal='add',
                                 seasonal_periods=7,
                                 damped=False,
                                 use_boxcox=False,
                                 smoothing_level=0.9,
                                 smoothing_slope=0.7,
                                 smoothing_seasonal=None,
                                 damping_slope=0.75)
```


```python
df_show(pred_ret_new_ratio,3,15)
```

    shape=(102, 102)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>0</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>...</th>
      <th>92</th>
      <th>93</th>
      <th>94</th>
      <th>95</th>
      <th>96</th>
      <th>97</th>
      <th>98</th>
      <th>99</th>
      <th>100</th>
      <th>101</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-03-01</th>
      <td>1</td>
      <td>0.14</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-03-02</th>
      <td>1</td>
      <td>0.10</td>
      <td>0.05</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-03</th>
      <td>1</td>
      <td>0.08</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-27</th>
      <td>1</td>
      <td>0.18</td>
      <td>0.08</td>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-28</th>
      <td>1</td>
      <td>0.17</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-29</th>
      <td>1</td>
      <td>0.14</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-30</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.07</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-31</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>1</td>
      <td>0.12</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.07</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>1</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>1</td>
      <td>0.11</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>1</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
<p>18 rows × 102 columns</p>
</div>



### 老用户留存

#### 老用户第 N 日留存率预估


```python
# 转置
s_pred_data = myets.ets(myets.s_ret_old,
                       trend='add', 
                       seasonal='add', 
                       seasonal_periods=7, 
                       damped=False, 
                       use_boxcox=False,
                       smoothing_level=0.5, 
                       smoothing_slope=None, 
                       smoothing_seasonal=None, 
                       damping_slope=None)
pred_ret_old_result = myets.predict_compare(s_pred_data, 
                                            s_ret_old.loc['2020-03-01':],
                                            u'老用户第N日留存-ETS')
```

    RMSE=0.127854181665



![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_47_1.png)


```python
df_show(pred_ret_old_result,0,15)
```

    shape=(102, 4)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>f_ratio_origin</th>
      <th>f_ratio_predict</th>
      <th>f_ratio_diff</th>
      <th>f_ratio_rate</th>
    </tr>
    <tr>
      <th>f_date</th>
      <th></th>
      <th></th>
      <th></th>
      <th></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-05-27</th>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-28</th>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-29</th>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-30</th>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-05-31</th>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.12</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.17</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.23</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.12</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.13</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.08</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.06</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.11</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>nan</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
</div>



#### 新老用户留存率矩阵


```python
# 备份修改
pred_ret_old_ratio = myets.pred_ret_old(trend='add', 
                                       seasonal='add', 
                                       seasonal_periods=7, 
                                       damped=False, 
                                       use_boxcox=False,
                                       smoothing_level=0.5, 
                                       smoothing_slope=None, 
                                       smoothing_seasonal=None, 
                                       damping_slope=None)
pred_ret_old_ratio
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>0</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>...</th>
      <th>93</th>
      <th>94</th>
      <th>95</th>
      <th>96</th>
      <th>97</th>
      <th>98</th>
      <th>99</th>
      <th>100</th>
      <th>101</th>
      <th>102</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-02-29</th>
      <td>1.00</td>
      <td>0.05</td>
      <td>0.05</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
  </tbody>
</table>
<p>1 rows × 103 columns</p>
</div>




```python
ratio_matrix = pd.concat([pred_ret_old_ratio, pred_ret_new_ratio]).sort_index().sort_index(axis=1)
df_show(ratio_matrix, 10,10)
```

    shape=(103, 103)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>0</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>...</th>
      <th>93</th>
      <th>94</th>
      <th>95</th>
      <th>96</th>
      <th>97</th>
      <th>98</th>
      <th>99</th>
      <th>100</th>
      <th>101</th>
      <th>102</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-02-29</th>
      <td>1.00</td>
      <td>0.05</td>
      <td>0.05</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
    </tr>
    <tr>
      <th>2020-03-01</th>
      <td>1.00</td>
      <td>0.14</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-02</th>
      <td>1.00</td>
      <td>0.10</td>
      <td>0.05</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-03</th>
      <td>1.00</td>
      <td>0.08</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-04</th>
      <td>1.00</td>
      <td>0.07</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-05</th>
      <td>1.00</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-06</th>
      <td>1.00</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-07</th>
      <td>1.00</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-08</th>
      <td>1.00</td>
      <td>0.05</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.00</td>
      <td>0.00</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-09</th>
      <td>1.00</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>0.01</td>
      <td>0.01</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.03</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>1.00</td>
      <td>0.12</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>0.02</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.07</td>
      <td>0.04</td>
      <td>0.03</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>0.04</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>0.06</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>1.00</td>
      <td>0.11</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>1.00</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
<p>20 rows × 103 columns</p>
</div>



#### DAU留存矩阵


```python
dau_matrix = ratio_matrix.mul(pred_dau_new, axis='index')
df_show(dau_matrix, 10,10)
```

    shape=(103, 103)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>0</th>
      <th>1</th>
      <th>2</th>
      <th>3</th>
      <th>4</th>
      <th>5</th>
      <th>6</th>
      <th>7</th>
      <th>8</th>
      <th>9</th>
      <th>...</th>
      <th>93</th>
      <th>94</th>
      <th>95</th>
      <th>96</th>
      <th>97</th>
      <th>98</th>
      <th>99</th>
      <th>100</th>
      <th>101</th>
      <th>102</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-02-29</th>
      <td>273385370.00</td>
      <td>12958148.00</td>
      <td>12452616.00</td>
      <td>11797162.00</td>
      <td>11073535.00</td>
      <td>10472504.00</td>
      <td>9798707.00</td>
      <td>9117300.00</td>
      <td>8284139.00</td>
      <td>8039563.00</td>
      <td>...</td>
      <td>2699356.59</td>
      <td>2715180.35</td>
      <td>2626011.84</td>
      <td>2671154.75</td>
      <td>2519520.16</td>
      <td>2264857.58</td>
      <td>2199788.72</td>
      <td>2234150.08</td>
      <td>2249973.83</td>
      <td>2160805.32</td>
    </tr>
    <tr>
      <th>2020-03-01</th>
      <td>1475032.00</td>
      <td>204291.93</td>
      <td>94549.55</td>
      <td>58411.27</td>
      <td>43218.44</td>
      <td>34663.25</td>
      <td>29648.14</td>
      <td>25223.05</td>
      <td>22420.49</td>
      <td>20650.45</td>
      <td>...</td>
      <td>6936.95</td>
      <td>5220.64</td>
      <td>7032.82</td>
      <td>7539.64</td>
      <td>4889.92</td>
      <td>7497.01</td>
      <td>7614.17</td>
      <td>7092.76</td>
      <td>7053.06</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-02</th>
      <td>1347642.00</td>
      <td>134494.67</td>
      <td>65495.40</td>
      <td>44202.66</td>
      <td>34364.87</td>
      <td>27896.19</td>
      <td>23448.97</td>
      <td>21966.56</td>
      <td>19675.57</td>
      <td>18866.99</td>
      <td>...</td>
      <td>9554.92</td>
      <td>9098.68</td>
      <td>9092.78</td>
      <td>8151.67</td>
      <td>6763.07</td>
      <td>11073.35</td>
      <td>9959.14</td>
      <td>9417.70</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-03</th>
      <td>1112908.00</td>
      <td>87029.41</td>
      <td>47632.46</td>
      <td>33943.69</td>
      <td>26932.37</td>
      <td>21924.29</td>
      <td>20700.09</td>
      <td>18362.98</td>
      <td>17917.82</td>
      <td>16359.75</td>
      <td>...</td>
      <td>6765.79</td>
      <td>4993.47</td>
      <td>4390.72</td>
      <td>4932.99</td>
      <td>4972.60</td>
      <td>7680.72</td>
      <td>7071.00</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-04</th>
      <td>993211.00</td>
      <td>70021.38</td>
      <td>38238.62</td>
      <td>27015.34</td>
      <td>20956.75</td>
      <td>19268.29</td>
      <td>16785.27</td>
      <td>16189.34</td>
      <td>14798.84</td>
      <td>14600.20</td>
      <td>...</td>
      <td>6376.45</td>
      <td>3963.54</td>
      <td>4519.98</td>
      <td>5838.69</td>
      <td>5006.08</td>
      <td>7176.47</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-05</th>
      <td>985703.00</td>
      <td>62197.86</td>
      <td>33612.47</td>
      <td>23065.45</td>
      <td>20206.91</td>
      <td>17348.37</td>
      <td>16559.81</td>
      <td>14982.69</td>
      <td>14588.40</td>
      <td>12814.14</td>
      <td>...</td>
      <td>6147.21</td>
      <td>4536.31</td>
      <td>6059.73</td>
      <td>6628.64</td>
      <td>5874.86</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-06</th>
      <td>936955.00</td>
      <td>55655.13</td>
      <td>29139.30</td>
      <td>22955.40</td>
      <td>18739.10</td>
      <td>17146.28</td>
      <td>15272.37</td>
      <td>14991.28</td>
      <td>13304.76</td>
      <td>11993.02</td>
      <td>...</td>
      <td>4524.75</td>
      <td>3964.23</td>
      <td>4799.75</td>
      <td>5515.87</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-07</th>
      <td>889821.00</td>
      <td>49029.14</td>
      <td>28296.31</td>
      <td>20821.81</td>
      <td>17618.46</td>
      <td>15304.92</td>
      <td>14593.06</td>
      <td>13169.35</td>
      <td>11834.62</td>
      <td>11389.71</td>
      <td>...</td>
      <td>4509.68</td>
      <td>3406.76</td>
      <td>4220.58</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-08</th>
      <td>780080.00</td>
      <td>42358.34</td>
      <td>23090.37</td>
      <td>17629.81</td>
      <td>14821.52</td>
      <td>13573.39</td>
      <td>12013.23</td>
      <td>10999.13</td>
      <td>10219.05</td>
      <td>9594.98</td>
      <td>...</td>
      <td>3668.65</td>
      <td>2760.97</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-03-09</th>
      <td>727798.00</td>
      <td>42503.40</td>
      <td>23944.55</td>
      <td>17903.83</td>
      <td>15429.32</td>
      <td>12809.24</td>
      <td>11353.65</td>
      <td>11062.53</td>
      <td>10261.95</td>
      <td>9461.37</td>
      <td>...</td>
      <td>5160.16</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>563557.69</td>
      <td>62103.07</td>
      <td>35575.73</td>
      <td>20969.61</td>
      <td>14305.90</td>
      <td>10089.09</td>
      <td>7795.20</td>
      <td>6727.99</td>
      <td>5750.08</td>
      <td>5095.59</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>518941.51</td>
      <td>56246.99</td>
      <td>32305.73</td>
      <td>19031.49</td>
      <td>12288.68</td>
      <td>9177.43</td>
      <td>7599.00</td>
      <td>6267.09</td>
      <td>5469.77</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>517735.65</td>
      <td>58635.20</td>
      <td>32593.13</td>
      <td>18076.83</td>
      <td>12242.16</td>
      <td>9718.19</td>
      <td>7724.17</td>
      <td>6392.72</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>486268.62</td>
      <td>54515.05</td>
      <td>29297.18</td>
      <td>17014.05</td>
      <td>12271.39</td>
      <td>9261.54</td>
      <td>7372.38</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>463959.35</td>
      <td>54259.31</td>
      <td>28966.35</td>
      <td>17484.08</td>
      <td>11792.88</td>
      <td>8750.09</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>431672.77</td>
      <td>48169.79</td>
      <td>28347.88</td>
      <td>16167.69</td>
      <td>10923.33</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>417944.87</td>
      <td>47617.30</td>
      <td>27000.65</td>
      <td>15774.89</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>416701.86</td>
      <td>45919.82</td>
      <td>26305.16</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>394114.05</td>
      <td>42717.21</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>411632.31</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>...</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
      <td>nan</td>
    </tr>
  </tbody>
</table>
<p>20 rows × 103 columns</p>
</div>



### DAU 预估


```python
# df_result['ret_old'] = pd.Series(dau_matrix.loc[base_date-timedelta(1)].values, 
#                                             index=(base_date + timedelta(i-1) for i in dau_matrix.columns))

ets_result = myets.df_result.copy()
ets_result['dau_origin'] = dau.loc[pred_start_date:pred_end_date]
ets_result['dau_sum'] = [np.sum(np.diag(np.fliplr(np.array(dau_matrix)), d)) for d in
                               range(myets.n_forcast - 1, -1, -1)]
ets_result['dau_new'] = dau_matrix[0]
ets_result['ret_old'] = dau_matrix.iloc[0, -n_forcast:].values
ets_result['ret_new'] = [np.sum(np.diag(np.fliplr(np.array(dau_matrix.iloc[1:-1,1:-1])), d)) for d in
                               range(myets.n_forcast - 1, -1, -1)]
ets_result['check'] = ets_result['dau_new'] + ets_result['ret_old'] + ets_result['ret_new'] - ets_result['dau_sum']
# df_result = df_result.astype(int)
df_show(ets_result, 10, 10)
```

    shape=(10, 6)





<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>dau_origin</th>
      <th>dau_sum</th>
      <th>dau_new</th>
      <th>ret_old</th>
      <th>ret_new</th>
      <th>check</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>2020-06-01</th>
      <td>3994272</td>
      <td>3922560.87</td>
      <td>563557.69</td>
      <td>2699356.59</td>
      <td>659646.59</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>3546456</td>
      <td>3925123.98</td>
      <td>518941.51</td>
      <td>2715180.35</td>
      <td>691002.12</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>3248834</td>
      <td>3830069.65</td>
      <td>517735.65</td>
      <td>2626011.84</td>
      <td>686322.16</td>
      <td>-0.00</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>3129509</td>
      <td>3864890.96</td>
      <td>486268.62</td>
      <td>2671154.75</td>
      <td>707467.59</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>3216982</td>
      <td>3691592.09</td>
      <td>463959.35</td>
      <td>2519520.16</td>
      <td>708112.58</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>2895258</td>
      <td>3331318.71</td>
      <td>431672.77</td>
      <td>2264857.58</td>
      <td>634788.36</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>2926685</td>
      <td>3222451.35</td>
      <td>417944.87</td>
      <td>2199788.72</td>
      <td>604717.76</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>3023940</td>
      <td>3298679.82</td>
      <td>416701.86</td>
      <td>2234150.08</td>
      <td>647827.88</td>
      <td>-0.00</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>2911481</td>
      <td>3327172.93</td>
      <td>394114.05</td>
      <td>2249973.83</td>
      <td>683085.04</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>2737987</td>
      <td>3258783.04</td>
      <td>411632.31</td>
      <td>2160805.32</td>
      <td>686345.40</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-01</th>
      <td>3994272</td>
      <td>3922560.87</td>
      <td>563557.69</td>
      <td>2699356.59</td>
      <td>659646.59</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-02</th>
      <td>3546456</td>
      <td>3925123.98</td>
      <td>518941.51</td>
      <td>2715180.35</td>
      <td>691002.12</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-03</th>
      <td>3248834</td>
      <td>3830069.65</td>
      <td>517735.65</td>
      <td>2626011.84</td>
      <td>686322.16</td>
      <td>-0.00</td>
    </tr>
    <tr>
      <th>2020-06-04</th>
      <td>3129509</td>
      <td>3864890.96</td>
      <td>486268.62</td>
      <td>2671154.75</td>
      <td>707467.59</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-05</th>
      <td>3216982</td>
      <td>3691592.09</td>
      <td>463959.35</td>
      <td>2519520.16</td>
      <td>708112.58</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-06</th>
      <td>2895258</td>
      <td>3331318.71</td>
      <td>431672.77</td>
      <td>2264857.58</td>
      <td>634788.36</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-07</th>
      <td>2926685</td>
      <td>3222451.35</td>
      <td>417944.87</td>
      <td>2199788.72</td>
      <td>604717.76</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-08</th>
      <td>3023940</td>
      <td>3298679.82</td>
      <td>416701.86</td>
      <td>2234150.08</td>
      <td>647827.88</td>
      <td>-0.00</td>
    </tr>
    <tr>
      <th>2020-06-09</th>
      <td>2911481</td>
      <td>3327172.93</td>
      <td>394114.05</td>
      <td>2249973.83</td>
      <td>683085.04</td>
      <td>0.00</td>
    </tr>
    <tr>
      <th>2020-06-10</th>
      <td>2737987</td>
      <td>3258783.04</td>
      <td>411632.31</td>
      <td>2160805.32</td>
      <td>686345.40</td>
      <td>0.00</td>
    </tr>
  </tbody>
</table>
</div>



## 验证


```python
result = myets.predict_compare(ets_result['dau_sum'], dau.loc['2020-03-01':], u'ETS-DAU')
```

    RMSE=0.147793852021



![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_57_1.png)



```python
arima_result = get_dau_arima()
result = myets.predict_compare(arima_result.loc['2020-06-01': '2020-06-10'], dau.loc['2020-03-01':], u'ETS-DAU')
```

    RMSE=0.378640685005

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/output_58_1.png)
