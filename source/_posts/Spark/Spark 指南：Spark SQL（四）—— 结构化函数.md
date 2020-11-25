---
title: Spark 指南：Spark SQL（四）—— 结构化函数
date: 2020-11-07 18:51:22
tags: 
   - Spark
categories: 
   - Spark
---

Spark SQL 结构化函数一般都在 `functions` 模块，要使用这些函数，需要先导入该模块：

```scala
import org.apache.spark.sql.functions._
import org.apache.spark.sql.Row
import org.apache.spark.sql.types._
```

## 普通函数
Spark SQL 函数众多，最好的做法就是当需要某个具体功能时在以下列表中检索，或者直接百度谷歌:

- 字符串函数: [Spark SQL String Functions](https://sparkbyexamples.com/spark/usage-of-spark-sql-string-functions/)
- 日期时间函数: [Spark SQL Date and Time Functions](https://sparkbyexamples.com/spark/spark-sql-date-and-time-functions/)
- 数组函数: [Spark SQL Array functions complete list](https://sparkbyexamples.com/spark/spark-sql-array-functions/)
- 字典函数: [Spark SQL Array functions complete list](https://sparkbyexamples.com/spark/spark-sql-map-functions/)
- 排序函数: [Spark SQL Sort functions](https://sparkbyexamples.com/spark/spark-sql-sort-functions/)
- 聚合函数: [Spark SQL Aggregate Functions](https://sparkbyexamples.com/spark/spark-sql-aggregate-functions/)

## 聚合函数
在聚合中，您将指定一个分组和一个聚合函数，该函数必须为每个分组产生一个结果。Spark 的聚合功能是复杂巧妙且成熟的，具有各种不同的用例和可能性。通常，通过分组使用聚合函数去汇总数值型数据，也可以将任何类型的值聚合到 array、list 或 map 中。

Spark 支持以下分组类型，每个分组都会返回一个 `RelationalGroupedDataset`，可以在上面指定聚合函数：

1. 最简单的分组是通过在 `select` 语句中执行聚合来汇总一个完整的 DataFrame；
2. `group by` 允许指定一个或多个 key 以及一个或多个聚合函数来转换列值；
3. `window` 可以指定一个或多个 key 以及一个或多个聚合函数来转换列值，但是输入到函数的行以某种方式与当前行有关；
4. `grouping set` 可用于在多个不同级别进行聚合，`grouping set` 可以作为 SQL 原语或通过 DataFrame 中的 `rollup` 和 `cube` 使用；`group by A, B grouping sets(A, B)` 等价于 `group by A union group by B`；
5. `rollup` 可以指定一个或多个 key 以及一个或多个聚合函数来转换列值，这些列将按照层次进行聚合；`group by A,B,C with rollup` 首先会对 `A,B,C` 进行 group by，然后对 `A,B` 进行 group by，最后对 `A` 进行 group by，再对全表进行 group by，最后将结构进行 union，缺少字段补 null；
6. `cube` 可以指定一个或多个 key 以及一个或多个聚合函数来转换列值，这些列将在所有列的组合中进行聚合；`group by A,B,C with cube`，会对 `A, B, C` 的所有可能组合进行 group by，最后再将结果 union；

除了可以在 DataFrame 上或通过 `.stat` 出现的特殊情况之外，所有聚合都可用作函数，你可以在 `org.apache.spark.sql.functions` 包中找到大多数聚合函数。


### 统计聚合
- DataFrame 级聚合：

```scala
// count("*") 会显示 count(1)，但是直接写 count(1) 却会报错
// 在整个 DataFrame 上使用 count 会把结果拉回 Driver，是 action，但是用在 select 中是 transformation
df.select(count("stockCode"), count("*")).show()
+----------------+--------+
|count(stockCode)|count(1)|
+----------------+--------+
|          541909|  541914|
+----------------+--------+
// 去重，近似去重（为加速），第二个参数指定允许的最大估计误差
df.select(countDistinct("StockCode"), approx_count_distinct("StockCode", 0.05)).show()
+-------------------------+--------------------------------+
|count(DISTINCT StockCode)|approx_count_distinct(StockCode)|
+-------------------------+--------------------------------+
|                     4070|                            3804|
+-------------------------+--------------------------------+
// 第一行、最后一行
df.select(first("StockCode"), last("StockCode")).show()
+-----------------------+----------------------+
|first(StockCode, false)|last(StockCode, false)|
+-----------------------+----------------------+
|                 85123A|                  null|
+-----------------------+----------------------+
// 最大、最小值
df.select(min("Quantity"), max("Quantity")).show()
+-------------+-------------+
|min(Quantity)|max(Quantity)|
+-------------+-------------+
|       -80995|        80995|
+-------------+-------------+
// 求和、去重求和
df.select(sum("Quantity"), sumDistinct("Quantity")).show()
+-------------+----------------------+
|sum(Quantity)|sum(DISTINCT Quantity)|
+-------------+----------------------+
|      5176450|                 29310|
+-------------+----------------------+
// 均值、方差、标准差
df.select(avg("Quantity"), var_pop("Quantity"), stddev_pop("Quantity")).show()
+----------------+------------------+--------------------+
|   avg(Quantity)| var_pop(Quantity)|stddev_pop(Quantity)|
+----------------+------------------+--------------------+
|9.55224954743324|47559.303646609325|  218.08095663447858|
+----------------+------------------+--------------------+
// 偏度、峰度
df.select(skewness("Quantity"), kurtosis("Quantity")).show()
+-------------------+------------------+
| skewness(Quantity)|kurtosis(Quantity)|
+-------------------+------------------+
|-0.2640755761052948| 119768.0549553411|
+-------------------+------------------+
// 相关系数、协方差
df.select(corr("InvoiceNo", "Quantity"), covar_pop("InvoiceNo", "Quantity")).show()
+-------------------------+------------------------------+
|corr(InvoiceNo, Quantity)|covar_pop(InvoiceNo, Quantity)|
+-------------------------+------------------------------+
|     4.912186085641252E-4|            1052.7260778752557|
+-------------------------+------------------------------+
```

- 分组聚合：分组通常是针对分类数据完成的，我们先将数据按照某些列中的值进行分组，然后对被归入同一组的其他列执行聚合计算；事实上，DataFrame 级聚合只是分组聚合的一种特例；

```scala
// 分组语法
groupBy(col1: String, cols: String*)
groupBy(cols: Column*)

// 示例，RelationalGroupedDataset 对象也有 count 方法，但是和 DataFrame 的 count 方法会将结果收集到 Driver 不同，这还是一个 transformation
df.groupBy("InvoiceNo", "CustomerID").count().show(3)
+---------+----------+-----+
|InvoiceNo|CustomerID|count|
+---------+----------+-----+
|   536846|     14573|   76|
|   537026|     12395|   12|
|   537883|     14437|    5|
+---------+----------+-----+
// 分组聚合最常用的形式
df.groupBy("InvoiceNo").agg(
    count("Quantity").as("quan"),
    expr("count(Quantity)")
).show(3)
+---------+----+---------------+
|InvoiceNo|quan|count(Quantity)|
+---------+----+---------------+
|   536596|   6|              6|
|   536938|  14|             14|
|   537252|   1|              1|
+---------+----+---------------+
// map 形式
df.groupBy("InvoiceNo").agg("Quantity"->"avg", "Quantity"->"stddev_pop").show(3)
+---------+------------------+--------------------+
|InvoiceNo|     avg(Quantity)|stddev_pop(Quantity)|
+---------+------------------+--------------------+
|   536596|               1.5|  1.1180339887498947|
|   536938|33.142857142857146|  20.698023172885524|
|   537252|              31.0|                 0.0|
+---------+------------------+--------------------+
```

### 多维分析
- `grouping sets`：`group by keys grouping sets(combine1(keys), ..., combinen(keys))`，其中，`keys` 包含了所有可能用于分组的字段，`combine(keys)` 是 keys 的一个子集，聚合函数会分别基于每组 `combine(keys)` 进行聚合，最后再把所有聚合结果按字段进行 union，不同类型的分组缺失字段补 null；可以通过 null 值在各列上的分布来判断各结果行所属的聚合类型，进一步地，我们可以用 `grouping_id()` 聚合函数值来标识每一结果行的聚合类型，`grouping_id()` 首先用二进制表示各个 key 是否为 null，如 `(a, null, null)` 对应二进制 `011`，然后再将该二进制数转化为对应的十进制数（在这个例子中，十进制数为 3）得到 `grouping_id()` 的值；`grouping sets` 仅在 SQL 中可用，是 group by 子句的扩展，要在 DataFrame 中执行相同的操作，请使用 rollup 和 cube 算子；

```scala
val sql = """
select area, grade, honor, sum(value) as total_value, grouping_id() as groupId
from df 
group by area, grade, honor grouping sets(area, grade, honor)
order by 5
"""
spark.sql(sql).show()
+----+-----+-----+-----------+-------+
|area|grade|honor|total_value|groupId|
+----+-----+-----+-----------+-------+
|   a| null| null|        915|      3|
|   c| null| null|        155|      3|
|   b| null| null|        155|      3|
|null|   ac| null|        345|      5|
|null|   ab| null|        360|      5|
|null|   aa| null|        520|      5|
|null| null|  aaf|         30|      6|
|null| null|  aaa|        150|      6|
|null| null|  aah|        180|      6|
|null| null|  aac|        300|      6|
|null| null|  aad|        240|      6|
|null| null|  aae|        120|      6|
|null| null|  aab|         70|      6|
|null| null|  aag|        135|      6|
+----+-----+-----+-----------+-------+

// (area, grade) 代表按照 `area, grade` 进行 group by，() 代表在整个 DataFrame 上 group by
val sql = """
select area, grade, honor, sum(value) as total_value, grouping_id() as groupId
from df 
group by area, grade, honor grouping sets(area, grade, honor, (area, grade), ())
order by 5
"""
spark.sql(sql).show()
+----+-----+-----+-----------+-------+
|area|grade|honor|total_value|groupId|
+----+-----+-----+-----------+-------+
|   a|   aa| null|        420|      1|
|   c|   aa| null|         50|      1|
|   c|   ac| null|         45|      1|
|   a|   ab| null|        240|      1|
|   a|   ac| null|        255|      1|
|   c|   ab| null|         60|      1|
|   b|   ac| null|         45|      1|
|   b|   ab| null|         60|      1|
|   b|   aa| null|         50|      1|
|   a| null| null|        915|      3|
|   c| null| null|        155|      3|
|   b| null| null|        155|      3|
|null|   ab| null|        360|      5|
|null|   ac| null|        345|      5|
|null|   aa| null|        520|      5|
|null| null|  aaa|        150|      6|
|null| null|  aah|        180|      6|
|null| null|  aad|        240|      6|
|null| null|  aag|        135|      6|
|null| null|  aab|         70|      6|
+----+-----+-----+-----------+-------+
```

- `rollup`：`group by A,B,C with rollup` 首先会对 `A,B,C` 进行 group by，然后对 `A,B` 进行 group by，最后对 `A` 进行 group by，再对全表进行 group by，最后将结构进行 union，缺少字段补 null；

```scala
val sql = """
select area,grade,honor,sum(value) as total_value 
from df 
group by area,grade,honor with rollup
"""
spark.sql(sql)

df.rollup("area", "grade", "honor")
    .agg(grouping_id().as("groupId"), sum("value").alias("total_value"))
    .orderBy("groupId")
    .show(100)
+----+-----+-----+-------+-----------+
|area|grade|honor|groupId|total_value|
+----+-----+-----+-------+-----------+
|   c|   ab|  aad|      0|         60|
|   a|   ac|  aah|      0|        180|
|   b|   ab|  aad|      0|         60|
|   a|   ac|  aag|      0|         45|
|   a|   ac|  aaf|      0|         30|
|   a|   aa|  aaa|      0|         50|
|   b|   aa|  aaa|      0|         50|
|   c|   aa|  aaa|      0|         50|
|   a|   aa|  aab|      0|         70|
|   c|   ac|  aag|      0|         45|
|   a|   ab|  aae|      0|        120|
|   b|   ac|  aag|      0|         45|
|   a|   aa|  aac|      0|        300|
|   a|   ab|  aad|      0|        120|
|   a|   ac| null|      1|        255|
|   c|   ac| null|      1|         45|
|   c|   aa| null|      1|         50|
|   c|   ab| null|      1|         60|
|   b|   aa| null|      1|         50|
|   b|   ab| null|      1|         60|
|   b|   ac| null|      1|         45|
|   a|   ab| null|      1|        240|
|   a|   aa| null|      1|        420|
|   a| null| null|      3|        915|
|   b| null| null|      3|        155|
|   c| null| null|      3|        155|
|null| null| null|      7|       1225|
+----+-----+-----+-------+-----------+
```

- `cube`：`group by A,B,C with cube`，会对 `A, B, C` 的所有可能组合进行 group by，最后再将结果 union；

```scala
val sql = """
select area,grade,honor,sum(value) as total_value 
from df
group by area,grade,honor with cube
"""
spark.sql(sql)

df.cube("area", "grade", "honor")
    .agg(grouping_id().as("groupId"),sum("value").alias("total_value"))
    .orderBy("groupId")
    .show(100)
+----+-----+-----+-------+-----------+
|area|grade|honor|groupId|total_value|
+----+-----+-----+-------+-----------+
|   c|   ab|  aad|      0|         60|
|   a|   aa|  aab|      0|         70|
|   c|   ac|  aag|      0|         45|
|   b|   aa|  aaa|      0|         50|
|   b|   ab|  aad|      0|         60|
|   c|   aa|  aaa|      0|         50|
|   a|   aa|  aac|      0|        300|
|   b|   ac|  aag|      0|         45|
|   a|   ac|  aag|      0|         45|
|   a|   ac|  aaf|      0|         30|
|   a|   ac|  aah|      0|        180|
|   a|   ab|  aad|      0|        120|
|   a|   aa|  aaa|      0|         50|
|   a|   ab|  aae|      0|        120|
|   b|   aa| null|      1|         50|
|   a|   ab| null|      1|        240|
|   c|   ac| null|      1|         45|
|   b|   ab| null|      1|         60|
|   a|   ac| null|      1|        255|
|   c|   ab| null|      1|         60|
|   b|   ac| null|      1|         45|
|   a|   aa| null|      1|        420|
|   c|   aa| null|      1|         50|
|   a| null|  aaf|      2|         30|
|   a| null|  aag|      2|         45|
|   a| null|  aac|      2|        300|
|   a| null|  aaa|      2|         50|
|   b| null|  aad|      2|         60|
|   a| null|  aab|      2|         70|
|   a| null|  aah|      2|        180|
|   a| null|  aae|      2|        120|
|   a| null|  aad|      2|        120|
|   c| null|  aaa|      2|         50|
|   c| null|  aad|      2|         60|
|   b| null|  aag|      2|         45|
|   b| null|  aaa|      2|         50|
|   c| null|  aag|      2|         45|
|   b| null| null|      3|        155|
|   c| null| null|      3|        155|
|   a| null| null|      3|        915|
|null|   ab|  aad|      4|        240|
|null|   aa|  aab|      4|         70|
|null|   ac|  aah|      4|        180|
|null|   aa|  aaa|      4|        150|
|null|   ac|  aag|      4|        135|
|null|   ab|  aae|      4|        120|
|null|   aa|  aac|      4|        300|
|null|   ac|  aaf|      4|         30|
|null|   ab| null|      5|        360|
|null|   ac| null|      5|        345|
|null|   aa| null|      5|        520|
|null| null|  aae|      6|        120|
|null| null|  aaa|      6|        150|
|null| null|  aaf|      6|         30|
|null| null|  aad|      6|        240|
|null| null|  aac|      6|        300|
|null| null|  aab|      6|         70|
|null| null|  aah|      6|        180|
|null| null|  aag|      6|        135|
|null| null| null|      7|       1225|
+----+-----+-----+-------+-----------+
```

### 聚合为复杂类型
可以通过 `collect_list` 和 `collect_set` 收集某列中的值，前者保留原始顺序，后者不保证顺序但会去重。

```scala
val res = df.select(collect_list("Country"), collect_set("Country"))
res.show()
res.printSchema
+---------------------+--------------------+
|collect_list(Country)|collect_set(Country)|
+---------------------+--------------------+
| [United Kingdom, ...|[Portugal, Italy,...|
+---------------------+--------------------+

root
 |-- collect_list(Country): array (nullable = true)
 |    |-- element: string (containsNull = true)
 |-- collect_set(Country): array (nullable = true)
 |    |-- element: string (containsNull = true)
```

## 窗口函数
Spark 窗口函数对一组行（如frame、partition）进行操作，并为每个输入行返回一个值。窗口函数是一种特殊的聚合函数，但是输入到函数的行以某种方式与当前行有关，函数会为每一行返回一个值。Spark SQL支持三种窗口函数：

1. 排序函数：row_number() rank() dense_rank() percent_rank() ntile()
2. 分析函数: cume_dist() lag() lead()
3. 聚合函数: sum() first() last() max() min() mean() stddev()

语法：

```scala
// 定义窗口
val window = Window...
// 在窗口上应用窗口函数，返回列对象
windowFunc.over(Window)
```

示例数据：

```scala
import spark.implicits._
import org.apache.spark.sql.functions._
import org.apache.spark.sql.expressions.Window

val simpleData = Seq(("James", "Sales", 3000),
    ("Michael", "Sales", 4600),
    ("Robert", "Sales", 4100),
    ("Maria", "Finance", 3000),
    ("James", "Sales", 3000),
    ("Scott", "Finance", 3300),
    ("Jen", "Finance", 3900),
    ("Jeff", "Marketing", 3000),
    ("Kumar", "Marketing", 2000),
    ("Saif", "Sales", 4100)
    )
val df = simpleData.toDF("employee_name", "department", "salary")
df.show()

+-------------+----------+------+
|employee_name|department|salary|
+-------------+----------+------+
|        James|     Sales|  3000|
|      Michael|     Sales|  4600|
|       Robert|     Sales|  4100|
|        Maria|   Finance|  3000|
|        James|     Sales|  3000|
|        Scott|   Finance|  3300|
|          Jen|   Finance|  3900|
|         Jeff| Marketing|  3000|
|        Kumar| Marketing|  2000|
|         Saif|     Sales|  4100|
+-------------+----------+------+
```

### 排序窗口函数
用于排序的窗口定义：

```scala
// 按照指定字段分组，在分组内按照另一字段排序，得到排序窗口，如果需要降序，可以使用col("salary").desc 
val windowSpec = Window.partitionBy("department").orderBy("salary")
```

- row_number: 返回每行排序字段在窗口内的行号；

```scala
df.withColumn("row_number",row_number.over(windowSpec))
.show()

+-------------+----------+------+----------+
|employee_name|department|salary|row_number|
+-------------+----------+------+----------+
|        James|     Sales|  3000|         1|
|        James|     Sales|  3000|         2|
|       Robert|     Sales|  4100|         3|
|         Saif|     Sales|  4100|         4|
|      Michael|     Sales|  4600|         5|
|        Maria|   Finance|  3000|         1|
|        Scott|   Finance|  3300|         2|
|          Jen|   Finance|  3900|         3|
|        Kumar| Marketing|  2000|         1|
|         Jeff| Marketing|  3000|         2|
+-------------+----------+------+----------+
```

- rank: 返回每行排序字段在窗口内的排名，rank=n+1，n 代表窗口内比当前行小的行数；

```scala
df.withColumn("rank",rank().over(windowSpec))
.show()

+-------------+----------+------+----+
|employee_name|department|salary|rank|
+-------------+----------+------+----+
|        James|     Sales|  3000|   1|
|        James|     Sales|  3000|   1|
|       Robert|     Sales|  4100|   3|
|         Saif|     Sales|  4100|   3|
|      Michael|     Sales|  4600|   5|
|        Maria|   Finance|  3000|   1|
|        Scott|   Finance|  3300|   2|
|          Jen|   Finance|  3900|   3|
|        Kumar| Marketing|  2000|   1|
|         Jeff| Marketing|  3000|   2|
+-------------+----------+------+----+
```

- dense_rank: 返回每行排序字段在窗口内的稠密排名，rank=n+1，n 代表窗口内比当前行小的不同取值数；

```scala
df.withColumn("dense_rank",dense_rank().over(windowSpec))
.show()

+-------------+----------+------+----------+
|employee_name|department|salary|dense_rank|
+-------------+----------+------+----------+
|        James|     Sales|  3000|         1|
|        James|     Sales|  3000|         1|
|       Robert|     Sales|  4100|         2|
|         Saif|     Sales|  4100|         2|
|      Michael|     Sales|  4600|         3|
|        Maria|   Finance|  3000|         1|
|        Scott|   Finance|  3300|         2|
|          Jen|   Finance|  3900|         3|
|        Kumar| Marketing|  2000|         1|
|         Jeff| Marketing|  3000|         2|
+-------------+----------+------+----------+
```

- percent_rank: 返回每行排序字段在窗口内的百分位排名；

```scala
//percent_rank
df.withColumn("percent_rank",percent_rank().over(windowSpec))
.show()

+-------------+----------+------+------------+
|employee_name|department|salary|percent_rank|
+-------------+----------+------+------------+
|        James|     Sales|  3000|         0.0|
|        James|     Sales|  3000|         0.0|
|       Robert|     Sales|  4100|         0.5|
|         Saif|     Sales|  4100|         0.5|
|      Michael|     Sales|  4600|         1.0|
|        Maria|   Finance|  3000|         0.0|
|        Scott|   Finance|  3300|         0.5|
|          Jen|   Finance|  3900|         1.0|
|        Kumar| Marketing|  2000|         0.0|
|         Jeff| Marketing|  3000|         1.0|
+-------------+----------+------+------------+
```

- ntile: 返回窗口分区中结果行的相对排名，在下面的示例中，我们使用2作为ntile的参数，因此它返回介于2个值（1和2）之间的排名；

```scala
df.withColumn("ntile",ntile(2).over(windowSpec))
.show()

+-------------+----------+------+-----+
|employee_name|department|salary|ntile|
+-------------+----------+------+-----+
|        James|     Sales|  3000|    1|
|        James|     Sales|  3000|    1|
|       Robert|     Sales|  4100|    1|
|         Saif|     Sales|  4100|    2|
|      Michael|     Sales|  4600|    2|
|        Maria|   Finance|  3000|    1|
|        Scott|   Finance|  3300|    1|
|          Jen|   Finance|  3900|    2|
|        Kumar| Marketing|  2000|    1|
|         Jeff| Marketing|  3000|    2|
+-------------+----------+------+-----+
```

### 分析窗口函数

- cume_dist: 窗口函数用于获取窗口分区内值的累积分布，和 SQL 中的 DENSE_RANK 作用相同

```scala
df.withColumn("cume_dist",cume_dist().over(windowSpec)).show()

+-------------+----------+------+------------------+
|employee_name|department|salary|         cume_dist|
+-------------+----------+------+------------------+
|        James|     Sales|  3000|               0.4|
|        James|     Sales|  3000|               0.4|
|       Robert|     Sales|  4100|               0.8|
|         Saif|     Sales|  4100|               0.8|
|      Michael|     Sales|  4600|               1.0|
|        Maria|   Finance|  3000|0.3333333333333333|
|        Scott|   Finance|  3300|0.6666666666666666|
|          Jen|   Finance|  3900|               1.0|
|        Kumar| Marketing|  2000|               0.5|
|         Jeff| Marketing|  3000|               1.0|
+-------------+----------+------+------------------+
```

- lag: 和 SQL 中的 LAG 函数相同，返回值为当前行之前的 offset 行，如果当前行之前的行少于 offset，则返回“ null”。

```scala
df.withColumn("lag",lag("salary",2).over(windowSpec)).show()

+-------------+----------+------+----+
|employee_name|department|salary| lag|
+-------------+----------+------+----+
|        James|     Sales|  3000|null|
|        James|     Sales|  3000|null|
|       Robert|     Sales|  4100|3000|
|         Saif|     Sales|  4100|3000|
|      Michael|     Sales|  4600|4100|
|        Maria|   Finance|  3000|null|
|        Scott|   Finance|  3300|null|
|          Jen|   Finance|  3900|3000|
|        Kumar| Marketing|  2000|null|
|         Jeff| Marketing|  3000|null|
+-------------+----------+------+----+
```

- lead: 和 SQL 中的 LEAD 函数相同，返回值为当前行之后的 offset 行，如果当前行之后的行少于 offset，则返回“ null”。

```scala
df.withColumn("lead",lead("salary",2).over(windowSpec)).show()

+-------------+----------+------+----+
|employee_name|department|salary|lead|
+-------------+----------+------+----+
|        James|     Sales|  3000|4100|
|        James|     Sales|  3000|4100|
|       Robert|     Sales|  4100|4600|
|         Saif|     Sales|  4100|null|
|      Michael|     Sales|  4600|null|
|        Maria|   Finance|  3000|3900|
|        Scott|   Finance|  3300|null|
|          Jen|   Finance|  3900|null|
|        Kumar| Marketing|  2000|null|
|         Jeff| Marketing|  3000|null|
+-------------+----------+------+----+
```

### 聚合窗口函数
在本部分中，我将解释如何使用 Spark SQL Aggregate 窗口函数和 WindowSpec 计算每个分组的总和，最小值，最大值，使用聚合函数时，order by 子句特别重要，影响着最后聚合的具体范围。

```scala
val windowSpec = Window.partitionBy("department").orderBy("salary")
val res = df.withColumn("row",row_number.over(windowSpec))

// 不排序: 每一行都是基于全组做聚合，默认所有行有相同的次序
val windowSpecAgg  = Window.partitionBy("department")
// 通过某个字段 f 排序，每一行对全组所有 <= 当前行该字段值的做聚合
val windowSpecSalaryAgg  = Window.partitionBy("department").orderBy("salary")
// 以 row 排序，每一行对全组所有 row <= 当前 row 值的做聚合，等价于累积聚合
val windowSpecRowAgg  = Window.partitionBy("department").orderBy("row")
// 以 row 排序，每一行对附近偏移范围内的数据做聚合
val windowSpecBetweenAgg  = Window.partitionBy("department").orderBy("row").rowsBetween(-2, -1)

res.withColumn("sum", sum(col("salary")).over(windowSpecAgg))
   .withColumn("salarysum", sum(col("salary")).over(windowSpecSalaryAgg))
   .withColumn("rowsum", sum(col("salary")).over(windowSpecRowAgg))
   .withColumn("betweensum", sum(col("salary")).over(windowSpecBetweenAgg))
   .show()

+-------------+----------+------+---+-----+---------+------+----------+
|employee_name|department|salary|row|  sum|salarysum|rowsum|betweensum|
+-------------+----------+------+---+-----+---------+------+----------+
|        James|     Sales|  3000|  1|18800|     6000|  3000|      null|
|        James|     Sales|  3000|  2|18800|     6000|  6000|      3000|
|       Robert|     Sales|  4100|  3|18800|    14200| 10100|      6000|
|         Saif|     Sales|  4100|  4|18800|    14200| 14200|      7100|
|      Michael|     Sales|  4600|  5|18800|    18800| 18800|      8200|
|        Maria|   Finance|  3000|  1|10200|     3000|  3000|      null|
|        Scott|   Finance|  3300|  2|10200|     6300|  6300|      3000|
|          Jen|   Finance|  3900|  3|10200|    10200| 10200|      6300|
|        Kumar| Marketing|  2000|  1| 5000|     2000|  2000|      null|
|         Jeff| Marketing|  3000|  2| 5000|     5000|  5000|      2000|
+-------------+----------+------+---+-----+---------+------+----------+
```

## 自定义函数
自定义函数是 Spark SQL 最有用的特性之一，它扩展了 Spark 的内置函数，允许用户实现更加复杂的计算逻辑。但是，自定义函数是 Spark 的黑匣子，无法利用 Spark SQL 的优化器，自定义函数将失去 Spark 在 Dataframe / Dataset 上所做的所有优化，通常性能和安全性较差。如果可能，应尽量选用 Spark SQL 内置函数，因为这些函数提供了优化。

根据自定义函数是作用于单行还是多行，可以将其划分为两类：

1. UDF：User Defined Function，即用户自定义函数，接收一行输入并返回一个输出；
2. UDAF：User Defined Aggregate Function，即用户自定义的聚合函数，接收多行输入并返回一个输出；

### UDF
使用 UDF 的一般步骤：

1. **定义普通函数**：与定义一般函数的方式完全相同，但是需要额外注意
    1. UDF 中参数和返回值类型并不是我们可以随意定义的，因为涉及到数据的序列化和反序列化，详情参考“传递复杂数据类型”一节；
    2. `null` 值的处理，如果设计不当，UDF 很容易出错，最好的做法是在函数内部检查 `null`，而不是在外部检查 `null`；
2. **注册 UDF**：在 DataFrame API 和 SQL 表达式中使用的 UDF 注册方式有所差异
    1. 如果要在 DataFrame API 中使用：`val 函数名 = org.apache.spark.sql.functions.udf(函数值)`；
    2. 如果要在 SQL 表达式中使用：`sparkSession.udf.register(函数名, 函数值)`；
3. **应用 UDF**：与应用 Spark 内置函数的方法完全相同，只不过原始函数中的变长参数会被注册为 `ArrayType` 类型，实际传参时也要传入 `ArrayType` 类型的实参；

#### 传递简单数据类型

```scala
// 示例数据
import spark.implicits._
val columns = Seq("Seqno","Quote")
val data = Seq(("1", "Be the change that you wish to see in the world"),
    ("2", "Everyone thinks of changing the world, but no one thinks of changing himself."),
    ("3", "The purpose of our lives is to be happy.")
  )
val df = data.toDF(columns:_*)
df.show(false)

+-----+-----------------------------------------------------------------------------+
|Seqno|Quote                                                                        |
+-----+-----------------------------------------------------------------------------+
|1    |Be the change that you wish to see in the world                              |
|2    |Everyone thinks of changing the world, but no one thinks of changing himself.|
|3    |The purpose of our lives is to be happy.                                     |
+-----+-----------------------------------------------------------------------------+
```

- 创建一个普通函数:

```scala
// convertCase 是一个函数值，将句子中每个单词首字母改为大写
val convertCase =  (strQuote:String) => {
    val arr = strQuote.split(" ")
    arr.map(f=>  f.substring(0,1).toUpperCase + f.substring(1,f.length)).mkString(" ")
}
```

- 在 DataFrame 中使用 UDF:

```scala
import org.apache.spark.sql.functions.udf
// 1. 创建 Spark UDF，传给 udf 的是一个函数值，如果 x 只是一个普通函数名，则需传入 x _
val convertUDF = udf(convertCase)
convertUDF: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function1>,StringType,Some(List(StringType)))

// 2. 在 DataFrame 中使用 UDF
df.select(col("Seqno"), convertUDF(col("Quote")).as("Quote") ).show(false)

+-----+-----------------------------------------------------------------------------+
|Seqno|Quote                                                                        |
+-----+-----------------------------------------------------------------------------+
|1    |Be The Change That You Wish To See In The World                              |
|2    |Everyone Thinks Of Changing The World, But No One Thinks Of Changing Himself.|
|3    |The Purpose Of Our Lives Is To Be Happy.                                     |
```

- 在 SQL 中使用 UDF:

```scala
// 1. 注册 UDF
spark.udf.register("convertUDF", convertCase)
// 2. 在 SQL 中使用 UDF，得到同样的结果输出
df.createOrReplaceTempView("QUOTE_TABLE")
spark.sql("select Seqno, convertUDF(Quote) from QUOTE_TABLE").show(false)
```

#### 传递复杂数据类型
在 “Spark SQL 数据类型”一文曾介绍过 Spark 类型和 Scala 类型之间的对应关系，当 UDF 在 Spark 和 Scala 之间传递参数和返回值时也遵循同样的对应关系，下面列出了 Spark 中复杂类型与 Scala 本地类型之间的对应关系：

| Spark 类型 | udf 参数类型 | udf 返回值类型      |
|---------|----------|------------------|
| StructType  | Row      | Tuple/case class |
| ArrayType   | Seq      | Seq/Array/List   |
| MapType     | Map      | Map              |

本部分将使用如下示例数据来演示以上各种场景：

```scala
val data = Seq(
      Row("M", 3000, Row("James ","","Smith"), Seq(1,2), Map("1"->"a", "11"->"aa")),
      Row("M", 4000, Row("Michael ","Rose",""), Seq(3,2), Map("2"->"b", "22"->"bb")),
      Row("M", 4000, Row("Robert ","","Williams"), Seq(1,2), Map("3"->"c", "33"->"cc")),
      Row("F", 4000, Row("Maria ","Anne","Jones"), Seq(3,3), Map("4"->"d", "44"->"dd")),
      Row("F", -1, Row("Jen","Mary","Brown"), Seq(5,2), Map("5"->"e"))
    )

val schema = new StructType()
      .add("gender",StringType)
      .add("salary",IntegerType)
      .add("f_struct",
        new StructType()
          .add("firstname",StringType)
          .add("middlename",StringType)
          .add("lastname",StringType)
      )  
      .add("f_array", ArrayType(IntegerType))
      .add("f_map", MapType(StringType, StringType))

val df = spark.createDataFrame(spark.sparkContext.parallelize(data),schema)
df.show()
df.printSchema
+------+------+--------------------+-------+------------------+
|gender|salary|            f_struct|f_array|             f_map|
+------+------+--------------------+-------+------------------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|
+------+------+--------------------+-------+------------------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
```

##### StructType
如果传给 udf 的是 `StructType` 类型，udf 参数类型应该定义为 `Row`类型；如果需要 udf 返回 `StructType` 类型，udf 返回值类型应该定义为 `Tuple` 或 `case class`；

- udf 返回值类型可以是 `Tuple`：`Tuple` 返回值会被转化为 `struct`，`Tuple` 的各个元素分别对应 `struct` 的各个子域 `_1`、`_2`......

```scala
// 数据类型转化过程：Struct => Row => Tuple => Struct
def myF(gender:String, r:Row):(String, String) = {
    r match {
        case Row(firstname:String, middlename: String, lastname: String) => {
            val x = if (firstname.isEmpty) "" else (firstname + ":" + gender)
            (x, firstname)
        }
    }
}
val myUdf = udf(myF _)
// udf 签名：<function2> 代表 udf 包含两个参数；StructType(StructField(_1,StringType,true), StructField(_2,StringType,true)) 代表 udf 返回的是一个 struct，且该 struuct 包含了两个子域 _1、_2；None 是 udf 的入参类型，入参有 Row 就会变成 None，尚不清楚其中机理
myUdf: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function2>,StructType(StructField(_1,StringType,true), StructField(_2,StringType,true)),None)

val res = df.withColumn("f_udf", myUdf(col("gender"), col("f_struct")))
res.show()
res.printSchema

+------+------+--------------------+-------+------------------+--------------------+
|gender|salary|            f_struct|f_array|             f_map|               f_udf|
+------+------+--------------------+-------+------------------+--------------------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|  [James :M, James ]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|[Michael :M, Mich...|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|[Robert :M, Robert ]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|  [Maria :F, Maria ]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|        [Jen:F, Jen]|
+------+------+--------------------+-------+------------------+--------------------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_udf: struct (nullable = true)
 |    |-- _1: string (nullable = true)
 |    |-- _2: string (nullable = true)
```

- udf 的返回值可以是样例类：样例类型返回值会以一种更加自然的方式转化为 `struct`，样例类的不同属性构成了 `struct` 的各个子域；

```scala
case class P(x:String, y:Int)
def myF(gender:String, r:Row):P = {
    r match {
        case Row(firstname:String, middlename: String, lastname: String) => {
            val x = if (firstname.isEmpty) "" else (firstname + ":" + gender)
            P(x, 1)
        }
    }
}
val myUdf = udf(myF _)

myUdf: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function2>,StructType(StructField(x,StringType,true), StructField(y,IntegerType,false)),None)

val res = df.withColumn("f_udf", myUdf(col("gender"), col("f_struct")))
res.show()
res.printSchema
+------+------+--------------------+-------+------------------+---------------+
|gender|salary|            f_struct|f_array|             f_map|          f_udf|
+------+------+--------------------+-------+------------------+---------------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|  [James :M, 1]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|[Michael :M, 1]|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]| [Robert :M, 1]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|  [Maria :F, 1]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|     [Jen:F, 1]|
+------+------+--------------------+-------+------------------+---------------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_udf: struct (nullable = true)
 |    |-- x: string (nullable = true)
 |    |-- y: integer (nullable = false)
```

##### ArrayType

- 返回值类型也可以是 Seq、Array 或 List，不会影响到 udf 签名

```scala
def myF(gender:String, a:Seq[Int]):Seq[String] = a.map(x => gender * x.toInt)
def myF(gender:String, a:Seq[Int]):Array[String] = a.map(x => gender * x.toInt).toArray
def myF(gender:String, a:Seq[Int]):List[String] = a.map(x => gender * x.toInt).toList
val myUdf = udf(myF _)

myUdf: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function2>,ArrayType(StringType,true),Some(List(StringType, ArrayType(IntegerType,false))))

val res = df.withColumn("f_udf", myUdf(col("gender"), col("f_array")))
res.show()
res.printSchema
+------+------+--------------------+-------+------------------+-----------+
|gender|salary|            f_struct|f_array|             f_map|      f_udf|
+------+------+--------------------+-------+------------------+-----------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|    [M, MM]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|  [MMM, MM]|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|    [M, MM]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]| [FFF, FFF]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|[FFFFF, FF]|
+------+------+--------------------+-------+------------------+-----------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_udf: array (nullable = true)
 |    |-- element: string (containsNull = true)
```

- 参数不能是 Array 或 List，否则会报无法进行类型转换的错误

```scala
scala.collection.mutable.WrappedArray$ofRef cannot be cast to scala.collection.immutable.List`
```

- 变长参数会被注册为 ArrayType 类型：使用变长参数和使用 Seq 参数效果是一样的

```scala
def myF(gender:String, a:String *):Seq[String] = {
    a.map(x => gender * x.toInt)
}
val myUdf = udf(myF _)

myUdf: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function2>,ArrayType(StringType,true),Some(List(StringType, ArrayType(StringType,true))))

val res = df.withColumn("f_udf", myUdf(col("gender"), col("f_array")))
res.show()
res.printSchema
+------+------+--------------------+-------+------------------+-----------+
|gender|salary|            f_struct|f_array|             f_map|      f_udf|
+------+------+--------------------+-------+------------------+-----------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|    [M, MM]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|  [MMM, MM]|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|    [M, MM]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]| [FFF, FFF]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|[FFFFF, FF]|
+------+------+--------------------+-------+------------------+-----------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_udf: array (nullable = true)
 |    |-- element: string (containsNull = true)
```

##### MapType

```scala
def myF(gender:String, m:Map[String, String]):Map[String, String] = {
    m.filter(kv => kv._1.toInt < 10)
}
val myUdf = udf(myF _)

myUdf: org.apache.spark.sql.expressions.UserDefinedFunction = UserDefinedFunction(<function2>,MapType(StringType,StringType,true),Some(List(StringType, MapType(StringType,StringType,true))))

val res = df.withColumn("f_udf", myUdf(col("gender"), col("f_map")))
res.show()
res.printSchema
+------+------+--------------------+-------+------------------+--------+
|gender|salary|            f_struct|f_array|             f_map|   f_udf|
+------+------+--------------------+-------+------------------+--------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|[1 -> a]|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|[2 -> b]|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|[3 -> c]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|[4 -> d]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|[5 -> e]|
+------+------+--------------------+-------+------------------+--------+

root
 |-- gender: string (nullable = true)
 |-- salary: integer (nullable = true)
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_array: array (nullable = true)
 |    |-- element: integer (containsNull = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_udf: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
```

### UDAF
UDAF（User Defined Aggregate Function，即用户自定义的聚合函数）相比 UDF 要复杂很多，UDF 接收一行输入并产生一个输出，UDAF 则是接收一组（一般是多行）输入并产生一个输出，Spark 维护了一个 `AggregationBuffer` 来存储每组输入数据的中间结果。使用 UDAF 的一般步骤：

1. 自定义类继承 `UserDefinedAggregateFunction`，对每个阶段方法做实现；
2. 在 spark 中注册 UDAF，为其绑定一个名字；
3. 然后就可以在sql语句中使用上面绑定的名字调用；

#### 定义 UDAF 
我们通过一个计算平均值的 UDAF 实际例子来了解定义 UDAF 的过程：

```scala
import org.apache.spark.sql.Row
import org.apache.spark.sql.expressions.{MutableAggregationBuffer, UserDefinedAggregateFunction}
import org.apache.spark.sql.types._
 
object AverageUserDefinedAggregateFunction extends UserDefinedAggregateFunction {
 
  // 聚合函数的输入数据结构
  override def inputSchema: StructType = StructType(StructField("input", LongType) :: Nil)
 
  // 缓存区数据结构
  override def bufferSchema: StructType = StructType(StructField("sum", LongType) :: StructField("count", LongType) :: Nil)
 
  // 聚合函数返回值数据结构
  override def dataType: DataType = DoubleType
 
  // 聚合函数是否是幂等的，即相同输入是否总是能得到相同输出
  override def deterministic: Boolean = true
 
  // 初始化缓冲区
  override def initialize(buffer: MutableAggregationBuffer): Unit = {
    buffer(0) = 0L
    buffer(1) = 0L
  }
 
  // 给聚合函数传入一条新数据进行处理
  override def update(buffer: MutableAggregationBuffer, input: Row): Unit = {
    if (input.isNullAt(0)) return
    buffer(0) = buffer.getLong(0) + input.getLong(0)
    buffer(1) = buffer.getLong(1) + 1
  }
 
  // 合并聚合函数缓冲区
  override def merge(buffer1: MutableAggregationBuffer, buffer2: Row): Unit = {
    buffer1(0) = buffer1.getLong(0) + buffer2.getLong(0)
    buffer1(1) = buffer1.getLong(1) + buffer2.getLong(1)
  }
 
  // 计算最终结果
  override def evaluate(buffer: Row): Any = buffer.getLong(0).toDouble / buffer.getLong(1)
 
}
```

#### 注册-使用 UDAF 

```scala
import org.apache.spark.sql.SparkSession
 
object SparkSqlUDAFDemo_001 {
 
  def main(args: Array[String]): Unit = {
 
    val spark = SparkSession.builder().master("local[*]").appName("SparkStudy").getOrCreate()
    spark.read.json("data/user").createOrReplaceTempView("v_user")
    spark.udf.register("u_avg", AverageUserDefinedAggregateFunction)
    // 将整张表看做是一个分组对求所有人的平均年龄
    spark.sql("select count(1) as count, u_avg(age) as avg_age from v_user").show()
    // 按照性别分组求平均年龄
    spark.sql("select sex, count(1) as count, u_avg(age) as avg_age from v_user group by sex").show()
 
  }
 
}
```

## 参考
- 《Spark 权威指南 Chapter 7.Aggregations》

