---
title: Hive 函数篇：日期函数
date: 2019-10-22 22:29:09
tags:
categories:
---

Hive日期函数主要是在时间戳&字符串&日期之间进行转换：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022191911.png)


### from_unixtime——时间戳转换为字符串

> 一般格式：from_unixtime(bigint unix_time [,string format]) -> string
> 功能：将UNIX时间戳（从1970-01-01 00:00:00 UTC到指定时间的秒数）转化为指定格式时间字符串

```
hive>   select from_unixtime(1323308943,'yyyy-MM-dd HH:mm:ss');
2011-12-08 09:49:03
hive>   select from_unixtime(1323308943,'yyyyMMdd');
20111208
hive>   select from_unixtime(1323308943,'yyyy-MM-dd');
2011-12-08
hive> select from_unixtime(1323308943,'yyyy-MM');
2011-12
```
   
### unix_timestamp——字符串转换为时间戳

> 一般格式：unix_timestamp([string date][,string pattern]) -> bigint
> 功能：获取当前时区的UNIX时间戳，或者将指定格式的字符串日期转换为对应的UNIX时间戳；

具体来说，有三种用法：

- unix_timestamp()：获取当前时区的UNIX时间戳

```
spark-sql> select unix_timestamp();
unix_timestamp(current_timestamp(), yyyy-MM-dd HH:mm:ss)
1571729830
```

- unix_timestamp(string date)：转换格式为"yyyy-MM-dd HH:mm:ss“的日期到UNIX时间戳，如果转化失败，则返回NULL

```
spark-sql> select unix_timestamp('2019-10-20');
unix_timestamp(2019-10-20, yyyy-MM-dd HH:mm:ss)
NULL
Time taken: 0.232 seconds, Fetched 1 row(s)
spark-sql> select unix_timestamp('2019-10-20 10:30');
unix_timestamp(2019-10-20 10:30, yyyy-MM-dd HH:mm:ss)
NULL
Time taken: 0.22 seconds, Fetched 1 row(s)
spark-sql> select unix_timestamp('2019-10-20 10:30:00');
unix_timestamp(2019-10-20 10:30:00, yyyy-MM-dd HH:mm:ss)
1571538600
Time taken: 0.23 seconds, Fetched 1 row(s)
```
   
- unix_timestamp(string date, string pattern)：转换pattern格式的日期到UNIX时间戳。如果转化失败，则返回NULL

```
spark-sql> select unix_timestamp('2011-12-07 13:05','yyyy-MM-dd HH:mm');
unix_timestamp(2011-12-07 13:05, yyyy-MM-dd HH:mm)
1323234300
Time taken: 0.235 seconds, Fetched 1 row(s)
spark-sql> select unix_timestamp('2011-12','yyyy-MM');
unix_timestamp(2011-12, yyyy-MM)
1322668800
Time taken: 0.239 seconds, Fetched 1 row(s)
spark-sql> select unix_timestamp('201112','yyyyMM');
unix_timestamp(201112, yyyyMM)
1322668800
Time taken: 0.218 seconds, Fetched 1 row(s)
```
   
### to_date——字符串转化为日期

> 一般格式：to_date(date_str[, fmt]) -> string
> 功能：Parses the `date_str` expression with the `fmt` expression to a date. Returns null with invalid input. By default, it follows casting rules to a date if the `fmt` is omitted.

```
spark-sql> select to_date('2019');
to_date('2019')
2019-01-01
spark-sql> select to_date('2019-10');
to_date('2019-10')
2019-10-01
Time taken: 0.251 seconds, Fetched 1 row(s)
spark-sql> select to_date('2019-10-01');
to_date('2019-10-01')
2019-10-01
Time taken: 0.225 seconds, Fetched 1 row(s)
spark-sql> select to_date('2019-10-01 10');
to_date('2019-10-01 10')
2019-10-01
Time taken: 0.23 seconds, Fetched 1 row(s)
spark-sql> select to_date('2019-10-01 10:00');
to_date('2019-10-01 10:00')
2019-10-01
Time taken: 0.233 seconds, Fetched 1 row(s)
spark-sql> select to_date('2019-10-01 10:00:00');
to_date('2019-10-01 10:00:00')
2019-10-01
Time taken: 0.23 seconds, Fetched 1 row(s)
spark-sql> select to_date('20101201','yyyyMMdd');
to_date('20101201', 'yyyyMMdd')
2010-12-01
Time taken: 0.236 seconds, Fetched 1 row(s)
```
   
### date_format——将时间戳/字符串/日期转换为指定格式的字符串

> 一般格式：date_format(timestamp, fmt) -> string
> 功能：将给定时间戳(或是可以通过cast转化为时间戳的类型)转化为相应格式的字符串

```
spark-sql> select date_format('2019', 'yyyy');
date_format(CAST(2019 AS TIMESTAMP), yyyy)
2019
Time taken: 0.229 seconds, Fetched 1 row(s)
spark-sql> select date_format('2019-10', 'yyyy');
date_format(CAST(2019-10 AS TIMESTAMP), yyyy)
2019
Time taken: 0.22 seconds, Fetched 1 row(s)
spark-sql> select date_format('2019-10', 'MM');
date_format(CAST(2019-10 AS TIMESTAMP), MM)
10
Time taken: 0.225 seconds, Fetched 1 row(s)
spark-sql> select date_format(date_add(to_date(from_unixtime(UNIX_TIMESTAMP(cast(20191010 as string),'yyyyMMdd'))),6),'yyyyMMdd');
date_format(CAST(date_add(to_date(from_unixtime(unix_timestamp(CAST(20191010 AS STRING), 'yyyyMMdd'), 'yyyy-MM-dd HH:mm:ss')), 6) AS TIMESTAMP), yyyyMMdd)
20191016
Time taken: 0.484 seconds, Fetched 1 row(s)
```

### 日期相关函数

- 获取日期中的年月日：

```
spark-sql> select year('2011-12-08 10:03:01');
year(CAST(2011-12-08 10:03:01 AS DATE))
2011
Time taken: 0.242 seconds, Fetched 1 row(s)
spark-sql> select month('2011-12-08 10:03:01');
month(CAST(2011-12-08 10:03:01 AS DATE))
12
Time taken: 0.235 seconds, Fetched 1 row(s)
spark-sql> select day('2011-12-08 10:03:01');
dayofmonth(CAST(2011-12-08 10:03:01 AS DATE))
8
Time taken: 0.247 seconds, Fetched 1 row(s)
spark-sql> select hour('2011-12-08 10:03:01');
hour(CAST(2011-12-08 10:03:01 AS TIMESTAMP))
10
Time taken: 0.268 seconds, Fetched 1 row(s)
spark-sql> select minute('2011-12-08 10:03:01');
minute(CAST(2011-12-08 10:03:01 AS TIMESTAMP))
3
Time taken: 0.233 seconds, Fetched 1 row(s)
spark-sql> select second('2011-12-08 10:03:01');
second(CAST(2011-12-08 10:03:01 AS TIMESTAMP))
1
```

- 日期加/减：date_add(start_date, num_days)->date，date_sub(start_date, num_days)->date，


```
spark-sql> select date_add('2012-12-08',10);
date_add(CAST(2012-12-08 AS DATE), 10)
2012-12-18
Time taken: 0.224 seconds, Fetched 1 row(s)
spark-sql> select date_sub('2012-12-08',10);
date_sub(CAST(2012-12-08 AS DATE), 10)
2012-11-28
Time taken: 0.227 seconds, Fetched 1 row(s)
```

- 日期间隔：datediff(endDate, startDate) - Returns the number of days from `startDate` to `endDate`

```
spark-sql> select datediff('2012-12-08','2012-05-09');
datediff(CAST(2012-12-08 AS DATE), CAST(2012-05-09 AS DATE))
213
```
   
- 日期转周：weekofyear(date) - Returns the week of the year of the given date. A week is considered to start on a Monday and week 1 is the first week with >3 days.将日期转化我当年的周次

```
spark-sql> select weekofyear('2019-01-01');
weekofyear(CAST(2019-01-01 AS DATE))
1
```
