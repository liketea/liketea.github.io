---
title: Spark 指南：Spark SQL（三）—— 结构化类型
date: 2020-11-06 21:16:46
tags: 
   - Spark
categories: 
   - Spark
---

## Spark Types
### Spark-Scala 数据类型
Spark SQL 具有大量内部类型表示形式，下表列出了 Scala 绑定的类型信息：

| id   | Data Type     | Value type in Scala          | API to create a data Type                          |
|----|---------------|------------------------------|----------------------------------------------------|
| 1  | ByteType      | Byte                         | ByteType                                           |
| 2  | ShortType     | Short                        | ShortType                                          |
| 3  | IntegerType   | Int                          | IntegerType                                        |
| 4  | LongType      | Long                         | LongType                                           |
| 5  | FloatType     | Float                        | FloatType                                          |
| 6  | DoubleType    | Double                       | DoubleType                                         |
| 7  | DecimalType   | java\.math\.BigDecimal       | DecimalType                                        |
| 8  | StringType    | String                       | StringType                                         |
| 9  | BinaryType    | Array\[Byte\]                | BinaryType                                         |
| 10 | BooleanType   | Boolean                      | BooleanType                                        |
| 11 | TimestampType | java\.Timestamp              | TimestampType                                      |
| 12 | DateType      | java\.sql\.Date              | DateType                                           |
| 13 | ArrayType     | scala\.collection\.Seq       | ArrayType\(<br>elementType,<br>\[containsNull\]\)                                          |
| 14 | MapType       | scala\.collection\.Map       | MapType\(<br>keyType,<br>valueType,<br>\[valueContainsNull\]\)          |
| 15 | StructType    | org\.apache\.spark\.sql\.Row | tructType(<br>fields: Array[StructField])|
| 16 | StructField   | Scala中此字段的数据类型的值类型   | StructField\(<br>name,dataType,\[nullable\]\)          |

在 Scala 中，要使用 Spark 类型，需要先导入 `org.apache.spark.sql.types._`：

```scala
import org.apache.spark.sql.types._
import org.apache.spark.sql.functions._

val data = Seq(
      Row(Row("James ","","Smith"),"36636","M","3000"),
      Row(Row("Michael ","Rose",""),"40288","M","4000"),
      Row(Row("Robert ","","Williams"),"42114","M","4000"),
      Row(Row("Maria ","Anne","Jones"),"39192","F","4000"),
      Row(Row("Jen","Mary","Brown"),"","F","-1")
)

val schema = new StructType()
      .add("name",new StructType()
          .add("firstname",StringType)
          .add("middlename",StringType)
          .add("lastname",StringType)
      )  
      .add("dob",StringType)
      .add("gender",StringType)
      .add("salary",StringType)

val df = spark.createDataFrame(spark.sparkContext.parallelize(data),schema)
df.show()
df.printSchema

+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|   [James , , Smith]|36636|     M|  3000|
|  [Michael , Rose, ]|40288|     M|  4000|
|[Robert , , Willi...|42114|     M|  4000|
|[Maria , Anne, Jo...|39192|     F|  4000|
|  [Jen, Mary, Brown]|     |     F|    -1|
+--------------------+-----+------+------+

root
 |-- name: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- dob: string (nullable = true)
 |-- gender: string (nullable = true)
 |-- salary: string (nullable = true)
```

### 数据类型转换
#### 本地类型 & Spark 类型
我们经常需要在本地类型和 Spark 类型之间进行转换，以利用各自在数据处理不同方面的优势，在转化过程中本地类型和 Spark 类型要符合上表中列出的对应关系，如果无法进行隐式转换就会报错：

1. 本地类型 -> Spark 类型：
    1. 通过本地对象创建 DataFrame：`toDF()`、`createDataFrame()`；
    2. 将本地基本类型转化为 Spark 基本类型：`lit()`；
    3. udf 返回值会被隐式地转化为 Spark 对应的类型；
2. Spark 类型 -> 本地类型：
    1. 将 DataFrame 收集到 driver端：`collect()`；
    2. 向 udf 传递参数时，会将 Spark 类型隐式地转化为对应的本地类型；

```scala
import org.apache.spark.sql.functions.lit
df.select(lit(5).as("f_integer"), lit("five").as("f_string"), lit(5.0).as("f_double"))
```

需要注意的是，如果传给 `lit()` 的参数本身就是 `Column` 对象，`lit()` 将原样返回该 `Column` 对象：

```scala
  /**
   * Creates a [[Column]] of literal value.
   *
   * The passed in object is returned directly if it is already a [[Column]].
   * If the object is a Scala Symbol, it is converted into a [[Column]] also.
   * Otherwise, a new [[Column]] is created to represent the literal value.
   *
   * @group normal_funcs
   * @since 1.3.0
   */
  def lit(literal: Any): Column = {
    literal match {
      case c: Column => return c
      case s: Symbol => return new ColumnName(literal.asInstanceOf[Symbol].name)
      case _ =>  // continue
    }

    val literalExpr = Literal(literal)
    Column(literalExpr)
  }
```

#### Spark 类型 & Spark 类型
将 DataFrame 列类型从一种类型转换到另一种类型有很多种方法：`withColumn()`、`cast()`、`selectExpr`、SQL 表达式，需要注意的是目标类型必须是 DataType 的子类。

```scala
// 示例数据
import org.apache.spark.sql.Row
import org.apache.spark.sql.types._

val simpleData = Seq(Row("James",34,"2006-01-01","true","M",3000.60),
    Row("Michael",33,"1980-01-10","true","F",3300.80),
    Row("Robert",37,"06-01-1992","false","M",5000.50)
  )

val simpleSchema = StructType(Array(
    StructField("firstName",StringType,true),
    StructField("age",IntegerType,true),
    StructField("jobStartDate",StringType,true),
    StructField("isGraduated", StringType, true),
    StructField("gender", StringType, true),
    StructField("salary", DoubleType, true)
))

val df = spark.createDataFrame(spark.sparkContext.parallelize(simpleData),simpleSchema)
df.printSchema()
df.show(false)
root
 |-- firstName: string (nullable = true)
 |-- age: integer (nullable = true)
 |-- jobStartDate: string (nullable = true)
 |-- isGraduated: string (nullable = true)
 |-- gender: string (nullable = true)
 |-- salary: double (nullable = true)

+---------+---+------------+-----------+------+------+
|firstName|age|jobStartDate|isGraduated|gender|salary|
+---------+---+------------+-----------+------+------+
|James    |34 |2006-01-01  |true       |M     |3000.6|
|Michael  |33 |1980-01-10  |true       |F     |3300.8|
|Robert   |37 |06-01-1992  |false      |M     |5000.5|
+---------+---+------------+-----------+------+------+
```

- 通过 `withColumn()`、`cast()`：

```scala
val df2 = df
    .withColumn("age",col("age").cast(StringType))
    .withColumn("isGraduated",col("isGraduated").cast(BooleanType))
    .withColumn("jobStartDate",col("jobStartDate").cast(DateType))
df2.printSchema()
root
 |-- firstName: string (nullable = true)
 |-- age: string (nullable = true)
 |-- jobStartDate: date (nullable = true)
 |-- isGraduated: boolean (nullable = true)
 |-- gender: string (nullable = true)
 |-- salary: double (nullable = true)
```

- 通过 `select`：

```scala
val cast_df = df.select(df.columns.map {
    case column@"age" =>
      col(column).cast("String").as(column)
    case column@"salary" =>
      col(column).cast("String").as(column)
    case column =>
      col(column)
  }: _*)

cast_df.printSchema()
root
 |-- firstName: string (nullable = true)
 |-- age: string (nullable = true)
 |-- jobStartDate: string (nullable = true)
 |-- isGraduated: string (nullable = true)
 |-- gender: string (nullable = true)
 |-- salary: string (nullable = true)
```

- 通过 `selectExpr`：

```scala
val df3 = df2.selectExpr("cast(age as int) age",
    "cast(isGraduated as string) isGraduated",
    "cast(jobStartDate as string) jobStartDate")
df3.printSchema()
df3.show(false)
```

## 布尔类型
布尔类型是所有过滤的基础：

```scala
df.where(col("salary") < 4000).show()
+------------------+-----+------+------+
|              name|  dob|gender|salary|
+------------------+-----+------+------+
| [James , , Smith]|36636|     M|  3000|
|[Jen, Mary, Brown]|     |     F|    -1|
+------------------+-----+------+------+

// Scala 中判断列是否相等使用 ===，=!=
df.where(col("salary") === 4000).show()
+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|  [Michael , Rose, ]|40288|     M|  4000|
|[Robert , , Willi...|42114|     M|  4000|
|[Maria , Anne, Jo...|39192|     F|  4000|
+--------------------+-----+------+------+
df.where(col("salary") =!= 4000).show()
+------------------+-----+------+------+
|              name|  dob|gender|salary|
+------------------+-----+------+------+
| [James , , Smith]|36636|     M|  3000|
|[Jen, Mary, Brown]|     |     F|    -1|
+------------------+-----+------+------+
df.select((col("salary") =!= 4000).as("equal_400")).show()
+---------+
|equal_400|
+---------+
|     true|
|    false|
|    false|
|    false|
|     true|
+---------+

df.select((col("salary") =!= 4000).as("equal_400")).printSchema
root
 |-- equal_400: boolean (nullable = true)

// 布尔表达式更简洁的表达方式是使用 SQL 表达式
df.where("salary=4000 and gender='M'").show()
```

## 数字类型
### 摘要

```scala
df.describe().show()
+-------+------------------+------+------------------+
|summary|               dob|gender|            salary|
+-------+------------------+------+------------------+
|  count|                 5|     5|                 5|
|   mean|           39557.5|  null|            2999.8|
| stddev|2290.4202671125668|  null|1732.4838238783068|
|    min|                  |     F|                -1|
|    max|             42114|     M|              4000|
+-------+------------------+------+------------------+
```

### 运算

```scala
val df2 = df.withColumn("f_diff", (col("dob") - col("salary"))/col("salary"))
    .withColumn("f_round", round(col("f_diff"),2))
    .withColumn("f_pow", pow(col("salary"), 2))
df2.show()

+--------------------+-----+------+------+------+-------+---------+
|                name|  dob|gender|salary|f_diff|f_round|    f_pow|
+--------------------+-----+------+------+------+-------+---------+
|   [James , , Smith]|36636|     M|  3000|11.212|  11.21|9000000.0|
|  [Michael , Rose, ]|40288|     M|  4000| 9.072|   9.07|    1.6E7|
|[Robert , , Willi...|42114|     M|  4000|9.5285|   9.53|    1.6E7|
|[Maria , Anne, Jo...|39192|     F|  4000| 8.798|    8.8|    1.6E7|
|  [Jen, Mary, Brown]|     |     F|    -1|  null|   null|      1.0|
+--------------------+-----+------+------+------+-------+---------+
// 计算两列的协方差
df2.select(corr("salary","f_pow")).show()
+-------------------+
|corr(salary, f_pow)|
+-------------------+
| 0.9817491111765669|
+-------------------+
```

### 统计
StatFunctions 程序包中提供了许多统计功能，可以通过 `df.stat` 访问。

```scala
// 交叉表
df.stat.crosstab("gender", "salary").show()
+-------------+---+----+----+
|gender_salary| -1|3000|4000|
+-------------+---+----+----+
|            M|  0|   1|   2|
|            F|  1|   0|   1|
+-------------+---+----+----+
// 频次最高的值
df.stat.freqItems(Seq("gender", "salary")).show()
+----------------+----------------+
|gender_freqItems|salary_freqItems|
+----------------+----------------+
|          [M, F]|[3000, 4000, -1]|
+----------------+----------------+
```

### 自增 ID
monotonically_increasing_id 生成一个单调递增并且是唯一的 ID。

```scala
df.withColumn("f_id", monotonically_increasing_id()).show()
```

## 字符串类型
### 截取

```scala
// 语法：pos 从 1 开始
substring(str: Column, pos: Int, len: Int)
// 示例
df.withColumn("f_substring", substring(col("dob"), 2, 3)).show()
+--------------------+-----+------+------+-----------+
|                name|  dob|gender|salary|f_substring|
+--------------------+-----+------+------+-----------+
|   [James , , Smith]|36636|     M|  3000|        663|
|  [Michael , Rose, ]|40288|     M|  4000|        028|
|[Robert , , Willi...|42114|     M|  4000|        211|
|[Maria , Anne, Jo...|39192|     F|  4000|        919|
|  [Jen, Mary, Brown]|     |     F|    -1|           |
+--------------------+-----+------+------+-----------+
```

### 拆分

```scala
// 语法：pattern 是一个正则表达式，返回一个 Array
split(str: Column, pattern: String)
// 示例
df.withColumn("f_split", split(col("dob"), "6")).show()
+--------------------+-----+------+------+----------+
|                name|  dob|gender|salary|   f_split|
+--------------------+-----+------+------+----------+
|   [James , , Smith]|36636|     M|  3000|[3, , 3, ]|
|  [Michael , Rose, ]|40288|     M|  4000|   [40288]|
|[Robert , , Willi...|42114|     M|  4000|   [42114]|
|[Maria , Anne, Jo...|39192|     F|  4000|   [39192]|
|  [Jen, Mary, Brown]|     |     F|    -1|        []|
+--------------------+-----+------+------+----------+
```

### 拼接

```scala
// 语法
concat(exprs: Column*)
concat_ws(sep: String, exprs: Column*)
// 示例，第二个参数是变长参数，可以接收一个 array() 或者多个 Column
df.withColumn("f_concat", concat(col("gender"), lit("-"), col("dob")))
  .withColumn("f_concat_ws1", concat_ws("~", col("gender"), col("dob")))
  .withColumn("f_concat_ws2", concat_ws("~", array(col("gender"), col("dob"))))
  .show()
+--------------------+-----+------+------+--------+------------+------------+
|                name|  dob|gender|salary|f_concat|f_concat_ws1|f_concat_ws2|
+--------------------+-----+------+------+--------+------------+------------+
|   [James , , Smith]|36636|     M|  3000| M-36636|     M~36636|     M~36636|
|  [Michael , Rose, ]|40288|     M|  4000| M-40288|     M~40288|     M~40288|
|[Robert , , Willi...|42114|     M|  4000| M-42114|     M~42114|     M~42114|
|[Maria , Anne, Jo...|39192|     F|  4000| F-39192|     F~39192|     F~39192|
|  [Jen, Mary, Brown]|     |     F|    -1|      F-|          F~|          F~|
+--------------------+-----+------+------+--------+------------+------------+
```

### 增删两侧

```scala
// 语法
trim(e: Column)
trim(e: Column, trimString: String)
// 示例
df.select(
    ltrim(lit("  HELLO  ")).as("f_ltrim"),
    rtrim(lit("  HELLO  ")).as("f_rtrim"),
    trim(lit("---HELLO+++"), "+").as("f_trim"),
    lpad(lit("HELLO"), 10, "+").as("f_lpad"),
    rpad(lit("HELLO"), 10, "+").as("f_rpad")
).show(1)
+-------+-------+--------+----------+----------+
|f_ltrim|f_rtrim|  f_trim|    f_lpad|    f_rpad|
+-------+-------+--------+----------+----------+
|HELLO  |  HELLO|---HELLO|+++++HELLO|HELLO+++++|
+-------+-------+--------+----------+----------+
``` 

### 字符替换

```scala
df.withColumn("f_translate", translate(col("dob"), "36", "+-")).show()
+--------------------+-----+------+------+-----------+
|                name|  dob|gender|salary|f_translate|
+--------------------+-----+------+------+-----------+
|   [James , , Smith]|36636|     M|  3000|      +--+-|
|  [Michael , Rose, ]|40288|     M|  4000|      40288|
|[Robert , , Willi...|42114|     M|  4000|      42114|
|[Maria , Anne, Jo...|39192|     F|  4000|      +9192|
|  [Jen, Mary, Brown]|     |     F|    -1|           |
+--------------------+-----+------+------+-----------+
```
### 子串查询

```scala
// 语法，other 可以是 Column 对象，将逐行判断
contains(other: Any)
// 示例
df.withColumn("f_contain", col("dob").contains(66)).show()
+--------------------+-----+------+------+---------+
|                name|  dob|gender|salary|f_contain|
+--------------------+-----+------+------+---------+
|   [James , , Smith]|36636|     M|  3000|     true|
|  [Michael , Rose, ]|40288|     M|  4000|    false|
|[Robert , , Willi...|42114|     M|  4000|    false|
|[Maria , Anne, Jo...|39192|     F|  4000|    false|
|  [Jen, Mary, Brown]|     |     F|    -1|    false|
+--------------------+-----+------+------+---------+
```

### 正则替换
正则详细规则参见[这里](https://www.runoob.com/regexp/regexp-tutorial.html)。

```scala
// 语法
regexp_replace(e: Column, pattern: String, replacement: String)
regexp_replace(e: Column, pattern: Column, replacement: Column)
// 示例
df.withColumn("f_regex_replace", regexp_replace(col("dob"), "6|3", "+")).show()
+--------------------+-----+------+------+---------------+
|                name|  dob|gender|salary|f_regex_replace|
+--------------------+-----+------+------+---------------+
|   [James , , Smith]|36636|     M|  3000|          +++++|
|  [Michael , Rose, ]|40288|     M|  4000|          40288|
|[Robert , , Willi...|42114|     M|  4000|          42114|
|[Maria , Anne, Jo...|39192|     F|  4000|          +9192|
|  [Jen, Mary, Brown]|     |     F|    -1|               |
+--------------------+-----+------+------+---------------+
```

### 正则抽取

```scala
// 语法
regexp_extract(e: Column, exp: String, groupIdx: Int)
// 示例：重复连续出现两次的子串，(\\d) 作为编号为 1 的分组，整体正则串默认标号为0，\\1 使用分组 1 的内容
df.withColumn("f_regex_extract", regexp_extract(col("dob"), "(\\d)\\1{1}", 0)).show()
+--------------------+-----+------+------+---------------+
|                name|  dob|gender|salary|f_regex_extract|
+--------------------+-----+------+------+---------------+
|   [James , , Smith]|36636|     M|  3000|             66|
|  [Michael , Rose, ]|40288|     M|  4000|             88|
|[Robert , , Willi...|42114|     M|  4000|             11|
|[Maria , Anne, Jo...|39192|     F|  4000|               |
|  [Jen, Mary, Brown]|     |     F|    -1|               |
+--------------------+-----+------+------+---------------+
```

## 日期类型
在 Spark 中，有四种日期相关的数据类型：

1. DateType：日期，专注于日历日期；
2. TimestampType：时间戳，包括日期和时间信息，仅支持秒级精度，如果要使用毫秒或微秒则需要进行额外处理；
3. StringType：经常将日期和时间戳存储为字符串，并在其运行时转换为日期类型；
4. LongType：Long 型时间戳，注意当通过 Spark SQL 内置函数返回整型时间戳时单位为秒；

本部分只介绍 Spark 内置的日期处理工具，更复杂的操作可以借助 `java.text.SimpleDateFormat` 和 `java.util.{Calendar, Date}` 使用 UDF 来解决。

### 日期获取
#### 获取当前日期

```scala
val df = spark.range(3)
    .withColumn("date", current_date())
    .withColumn("timestamp", current_timestamp())
    .withColumn("dateStr",lit("2020-11-07"))
    .withColumn("timestampLong", unix_timestamp())
df.show(false)
df.printSchema
+---+----------+-----------------------+----------+-------------+
|id |date      |timestamp              |dateStr   |timestampLong|
+---+----------+-----------------------+----------+-------------+
|0  |2020-11-07|2020-11-07 18:55:38.947|2020-11-07|1604746538   |
|1  |2020-11-07|2020-11-07 18:55:38.947|2020-11-07|1604746538   |
|2  |2020-11-07|2020-11-07 18:55:38.947|2020-11-07|1604746538   |
+---+----------+-----------------------+----------+-------------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
```

#### 从日期中提取字段

```scala
val tmp = spark.range(1).select(lit("2020-11-07 19:45:12").as("date"))
    .withColumn("year", year(col("date")))
    .withColumn("month", month(col("date")))
    .withColumn("day", dayofmonth(col("date")))
    .withColumn("hour", hour(col("date")))
    .withColumn("minute", minute(col("date")))
    .withColumn("second", second(col("date")))
tmp.show(1)
tmp.printSchema
+-------------------+----+-----+---+----+------+------+
|               date|year|month|day|hour|minute|second|
+-------------------+----+-----+---+----+------+------+
|2020-11-07 19:45:12|2020|   11|  7|  19|    45|    12|
+-------------------+----+-----+---+----+------+------+

root
 |-- date: string (nullable = false)
 |-- year: integer (nullable = true)
 |-- month: integer (nullable = true)
 |-- day: integer (nullable = true)
 |-- hour: integer (nullable = true)
 |-- minute: integer (nullable = true)
 |-- second: integer (nullable = true)
```

#### 获取特殊日期

```scala
val tmp = spark.range(1).select(lit("2020-11-07 19:45:12").as("date"))
    .withColumn("dayofyear", dayofyear(col("date")))
    .withColumn("dayofmonth", dayofmonth(col("date")))
    .withColumn("dayofweek", dayofweek(col("date")))
    .withColumn("weekofyear", weekofyear(col("date")))
    // date_sub 第二个参数不支持 Column 只能用表达式，解决此问题更好的方式是使用 next_day
    .withColumn("monday_expr", expr("date_sub(date, (dayofweek(date) -2) % 7)"))
    // next_day 获取相对指定日期下一周某天的日期，dayOfWeek 参数对大小写不敏感，而且接受以下简写
    // "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    .withColumn("monday", date_sub(next_day(col("date"), "monday"), 7))
    // trunc截取某部分的日期，其他部分默认为01
    .withColumn("trunc", trunc(col("date"), "MONTH"))
tmp.show(1)
tmp.printSchema
+-------------------+---------+----------+---------+----------+-----------+----------+----------+
|               date|dayofyear|dayofmonth|dayofweek|weekofyear|monday_expr|    monday|     trunc|
+-------------------+---------+----------+---------+----------+-----------+----------+----------+
|2020-11-07 19:45:12|      312|         7|        7|        45| 2020-11-02|2020-11-02|2020-11-01|
+-------------------+---------+----------+---------+----------+-----------+----------+----------+

root
 |-- date: string (nullable = false)
 |-- dayofyear: integer (nullable = true)
 |-- dayofmonth: integer (nullable = true)
 |-- dayofweek: integer (nullable = true)
 |-- weekofyear: integer (nullable = true)
 |-- monday_expr: date (nullable = true)
 |-- monday: date (nullable = true)
 |-- trunc: date (nullable = true)
```


### 类型转换
日期相关的四种数据类型之间的转换方法如下图所示，其中，格式串遵守 [Java SimpleDateFormat 标准](https://docs.oracle.com/javase/8/docs/api/java/text/SimpleDateFormat.html)。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/Spark-date.png" width="50%" heigh="50%"></img>
</div>

#### Long & String
`from_unixtime` 函数可以将 Long 型时间戳转化为 String 类型的日期，`unix_timestamp` 函数可以将 String 类型的日期转化为 Long 型时间戳。

- 语法：

```scala
// 默认返回当前秒级时间戳，在同一个查询中对 unix_timestamp 的所有调用都会返回相同值，unix_timestamp 会在查询开始时进行计算
unix_timestamp()
// 将 yyyy-MM-dd HH:mm:ss 格式的时间字符串转化为秒级时间戳，如果失败则会返回 null
unix_timestamp(s: Column)
// 按照指定格式将时间字符串转化为秒级时间戳，格式串可参考 http://docs.oracle.com/javase/tutorial/i18n/format/simpleDateFormat.html
unix_timestamp(s: Column, p: String)

// 将秒级时间戳转化为 yyyy-MM-dd HH:mm:ss 格式的时间字符串
from_unixtime(ut: Column)
// 按指定格式将秒级时间戳转化为时间字符串
from_unixtime(ut: Column, f: String)
```

- 示例：

```scala
val tmp = df.withColumn("long_string", from_unixtime(col("timestampLong")))
    .withColumn("long_string2", from_unixtime(col("timestampLong"), "yyyyMMdd"))
    .withColumn("string_long", unix_timestamp(col("dateStr"), "yyyy-MM-dd"))
    .withColumn("date_long", unix_timestamp(col("date"), "yyyy-MM-dd"))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+-------------------+------------+-----------+----------+
| id|      date|           timestamp|   dateStr|timestampLong|        long_string|long_string2|string_long| date_long|
+---+----------+--------------------+----------+-------------+-------------------+------------+-----------+----------+
|  0|2020-11-07|2020-11-07 19:10:...|2020-11-07|   1604747436|2020-11-07 19:10:36|    20201107| 1604678400|1604678400|
|  1|2020-11-07|2020-11-07 19:10:...|2020-11-07|   1604747436|2020-11-07 19:10:36|    20201107| 1604678400|1604678400|
|  2|2020-11-07|2020-11-07 19:10:...|2020-11-07|   1604747436|2020-11-07 19:10:36|    20201107| 1604678400|1604678400|
+---+----------+--------------------+----------+-------------+-------------------+------------+-----------+----------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- long_string: string (nullable = true)
 |-- long_string2: string (nullable = true)
 |-- string_long: long (nullable = true)
 |-- date_long: long (nullable = true)
```

#### String & Date
`to_date` 函数可以将时间字符串转化为 date 类型，如果不指定具体的格式串，则等价于 `cast("date")`；`date_format` 函数可以将 date/timestamp/string 类型的日期时间转化为指定格式的时间字符串，如果只是希望将他们按原样转化为字符串，也可直接通过 `cast("string")` 来实现。

- 语法：

```scala
// 等价于 col(e: Column).cast("date")
to_date(e: Column)
// 按照指定格式将时间字符串转化为date
to_date(e: Column, fmt: String)

// 将 date/timestamp/string 按照指定格式转化为时间字符串
date_format(dateExpr: Column, format: String)

```

- 示例：

```scala
val tmp = df.withColumn("date_string", date_format(col("date"), "yyyyMMdd"))
    .withColumn("string_date", to_date(col("dateStr"), "yyyy-MM-dd"))
tmp.show()
tmp.printSchema

+---+----------+--------------------+----------+-------------+-----------+-----------+
| id|      date|           timestamp|   dateStr|timestampLong|date_string|string_date|
+---+----------+--------------------+----------+-------------+-----------+-----------+
|  0|2020-11-07|2020-11-07 19:15:...|2020-11-07|   1604747711|   20201107| 2020-11-07|
|  1|2020-11-07|2020-11-07 19:15:...|2020-11-07|   1604747711|   20201107| 2020-11-07|
|  2|2020-11-07|2020-11-07 19:15:...|2020-11-07|   1604747711|   20201107| 2020-11-07|
+---+----------+--------------------+----------+-------------+-----------+-----------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- date_string: string (nullable = false)
 |-- string_date: date (nullable = true)
```

#### String & Timestamp
和 string & date 之间的转换基本一致，不再赘述，这里只通过几个示例来做说明：

```scala
val tmp = df.withColumn("timestamp_string", date_format(col("timestamp"), "yyyyMMdd"))
    .withColumn("string_timestamp", to_timestamp(col("dateStr"), "yyyy-MM-dd"))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+----------------+-------------------+
| id|      date|           timestamp|   dateStr|timestampLong|timestamp_string|   string_timestamp|
+---+----------+--------------------+----------+-------------+----------------+-------------------+
|  0|2020-11-07|2020-11-07 19:24:...|2020-11-07|   1604748297|        20201107|2020-11-07 00:00:00|
|  1|2020-11-07|2020-11-07 19:24:...|2020-11-07|   1604748297|        20201107|2020-11-07 00:00:00|
|  2|2020-11-07|2020-11-07 19:24:...|2020-11-07|   1604748297|        20201107|2020-11-07 00:00:00|
+---+----------+--------------------+----------+-------------+----------------+-------------------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- timestamp_string: string (nullable = false)
 |-- string_timestamp: timestamp (nullable = true)
```

#### Date & Timestamp
date & timestamp 之间的转换直接通过 `cast` 即可实现，无需赘言：

```scala
val tmp = df.withColumn("timestamp_date", col("timestamp").cast("date"))
    .withColumn("date_timestamp", col("date").cast("timestamp"))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+--------------+-------------------+
| id|      date|           timestamp|   dateStr|timestampLong|timestamp_date|     date_timestamp|
+---+----------+--------------------+----------+-------------+--------------+-------------------+
|  0|2020-11-07|2020-11-07 19:27:...|2020-11-07|   1604748466|    2020-11-07|2020-11-07 00:00:00|
|  1|2020-11-07|2020-11-07 19:27:...|2020-11-07|   1604748466|    2020-11-07|2020-11-07 00:00:00|
|  2|2020-11-07|2020-11-07 19:27:...|2020-11-07|   1604748466|    2020-11-07|2020-11-07 00:00:00|
+---+----------+--------------------+----------+-------------+--------------+-------------------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- timestamp_date: date (nullable = false)
 |-- date_timestamp: timestamp (nullable = false)
```

### 日期运算
用到的时候搜索 API 即可，这里还是有必要列出最常用到的：

#### 日期 ± 天数

```scala
// 原型，start 必须是date或者可以隐式地通过 cast("date") 转化为 date (timestamp 或 yyyy-MM-dd HH:ss 格式的字符串)
// 奇怪的是 days 是 int 类型，而不是 Column，导致days 参数不能传入另一列，但是 SQL 表达式可以
date_add(start: Column, days: Int)
date_sub(start: Column, days: Int)
// 示例
val tmp = df
    .withColumn("n", lit(1))
    .withColumn("date_add", date_add(col("date"), 2))
    .withColumn("timestamp_add", date_add(col("timestamp"), 2))
    .withColumn("string_add", date_add(col("dateStr"), 2))
//     .withColumn("string_sub", date_sub(col("dateStr"), col("n")))
    .withColumn("string_sub", expr("date_sub(dateStr, n)"))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+---+----------+-------------+----------+----------+
| id|      date|           timestamp|   dateStr|timestampLong|  n|  date_add|timestamp_add|string_add|string_sub|
+---+----------+--------------------+----------+-------------+---+----------+-------------+----------+----------+
|  0|2020-11-07|2020-11-07 20:14:...|2020-11-07|   1604751268|  1|2020-11-09|   2020-11-09|2020-11-09|2020-11-06|
|  1|2020-11-07|2020-11-07 20:14:...|2020-11-07|   1604751268|  1|2020-11-09|   2020-11-09|2020-11-09|2020-11-06|
|  2|2020-11-07|2020-11-07 20:14:...|2020-11-07|   1604751268|  1|2020-11-09|   2020-11-09|2020-11-09|2020-11-06|
+---+----------+--------------------+----------+-------------+---+----------+-------------+----------+----------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- n: integer (nullable = false)
 |-- date_add: date (nullable = false)
 |-- timestamp_add: date (nullable = false)
 |-- string_add: date (nullable = true)
 |-- string_sub: date (nullable = true)
```

#### 日期 - 日期

```scala
// 返回 end - start 的天数
datediff(end: Column, start: Column)

val tmp = df.withColumn("date_diff", datediff(col("date"), lit("2020-11-01")))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+---------+
| id|      date|           timestamp|   dateStr|timestampLong|date_diff|
+---+----------+--------------------+----------+-------------+---------+
|  0|2020-11-07|2020-11-07 19:39:...|2020-11-07|   1604749181|        6|
|  1|2020-11-07|2020-11-07 19:39:...|2020-11-07|   1604749181|        6|
|  2|2020-11-07|2020-11-07 19:39:...|2020-11-07|   1604749181|        6|
+---+----------+--------------------+----------+-------------+---------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- date_diff: integer (nullable = true)
```

#### 月份运算

```scala
val tmp = df.withColumn("month_diff", months_between(col("date"), lit("2020-09-01")))
    .withColumn("add_months", add_months(col("date"), 1))
tmp.show()
tmp.printSchema
+---+----------+--------------------+----------+-------------+----------+----------+
| id|      date|           timestamp|   dateStr|timestampLong|month_diff|add_months|
+---+----------+--------------------+----------+-------------+----------+----------+
|  0|2020-11-07|2020-11-07 19:41:...|2020-11-07|   1604749312|2.19354839|2020-12-07|
|  1|2020-11-07|2020-11-07 19:41:...|2020-11-07|   1604749312|2.19354839|2020-12-07|
|  2|2020-11-07|2020-11-07 19:41:...|2020-11-07|   1604749312|2.19354839|2020-12-07|
+---+----------+--------------------+----------+-------------+----------+----------+

root
 |-- id: long (nullable = false)
 |-- date: date (nullable = false)
 |-- timestamp: timestamp (nullable = false)
 |-- dateStr: string (nullable = false)
 |-- timestampLong: long (nullable = true)
 |-- month_diff: double (nullable = true)
 |-- add_months: date (nullable = false)
```

## 处理空值
最佳实践是，你应该始终使用 `null` 来表示 DataFrame 中缺失或为空的数据，与使用空字符串或其他值相比，Spark 可以优化使用 null 的工作。对于空值的处理，要么删除要么填充，与 null 交互的主要方式是在 DataFrame 上调用 `.na` 子包。

### 填充空值
- `ifnull(expr1, expr2) `：默认返回 `expr1`，如果 `expr1` 值为 null 则返回 `expr2`；只用于 SQL 表达式；`nullif(expr1, expr2) `：如果条件为真则返回 null，否则返回 `expr1`；只用于 SQL 表达式；`nvl(expr1, expr2)`：同 ifnull；`nvl2(expr1, expr2, expr3)`：如果 `expr1` 为 null 则返回 `expr2`，否则返回 `expr3`；

```sql
df.createOrReplaceTempView("df")
spark.sql("""
select
ifnull(null, 'return_value') as a,
nullif('value', 'value') as b,
nvl(null, 'return_value') as c,
nvl2('not_null', 'return_value', 'else_value') as d
from df limit 1
""").show()
+------------+----+------------+------------+
|           a|   b|           c|           d|
+------------+----+------------+------------+
|return_value|null|return_value|return_value|
+------------+----+------------+------------+
```

- `coalesce(e: Column*)`：从左向右，返回第一个不为 null 的值；

```scala
df.select(coalesce(lit(null), lit(null), lit(1)).as("coalesce")).show(1)
+--------+
|coalesce|
+--------+
|       1|
+--------+
```

- `na.fill`：用法比较灵活：只有 value 的类型和所在列的原有类型可隐式转换时才会填充
    - 如果对所有列都用相同的值填充空值，可以用 `df.na.fill(value)`；
    - 如果对几个列都用相同的值填充空值，可以用 `df.na.fill(value, Seq(cols_name*))`；
    - 如果对几个列分别用不同的值填充空值，可以用 `df.na.fill(Map(col->value))`

```scala
val df = spark.range(1).select(
    lit(null).cast("string").as("f_string1"),
    lit("x").cast("string").as("f_string2"),
    lit(null).cast("int").as("f_int"),
    lit(null).cast("double").as("f_double"),
    lit(null).cast("boolean").as("f_bool")
)

df.show()
df.printSchema
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
|     null|        x| null|    null|  null|
+---------+---------+-----+--------+------+

root
 |-- f_string1: string (nullable = true)
 |-- f_string2: string (nullable = false)
 |-- f_int: integer (nullable = true)
 |-- f_double: double (nullable = true)
 |-- f_bool: boolean (nullable = true)

df.na.fill(1).show()
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
|     null|        x|    1|     1.0|  null|
+---------+---------+-----+--------+------+

df.na.fill(1, Seq("f_int")).show()
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
|     null|        x|    1|    null|  null|
+---------+---------+-----+--------+------+

df.na.fill(Map("f_int"->1, "f_string1"->"")).show()
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
|         |        x|    1|    null|  null|
+---------+---------+-----+--------+------+
```

### 删除空值
删除空值可以分为以下几种情况：

- 删除某列为空的行：直接通过 `.where("col is not null")` 即可完成；
- 删除包含空值的行：`na.drop()`;
- 删除所有列均为空的行：`na.drop("all")` 仅当改行所有列均为 null 或 NaN 时，才会删除；

```scala
df.na.drop().show()
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
+---------+---------+-----+--------+------+

df.na.drop("all").show()
+---------+---------+-----+--------+------+
|f_string1|f_string2|f_int|f_double|f_bool|
+---------+---------+-----+--------+------+
|     null|        x| null|    null|  null|
+---------+---------+-----+--------+------+
```

## 处理复杂类型
复杂类型可以帮助你以对问题更有意义的方式组织和构造数据，Spark SQL 中复杂类型共有三种：

| id  | Data Type  |Scala Type| API to create a data Type  |
|:---:|---|---|---|
| 1 | StructType    | org\.apache\.spark\.sql\.Row | tructType(<br>fields: Array[StructField])|
| 2 | ArrayType     | scala\.collection\.Seq       | ArrayType\(<br>elementType,<br>\[containsNull\]\)                                          |
| 3| MapType       | scala\.collection\.Map       | MapType\(<br>keyType,<br>valueType,<br>\[valueContainsNull\]\)          |

示例数据：创建 DataFrame 时，显式定义 struct/array/map 类型

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

### StructType
可以将 struct 视为 DataFrame 中的 DataFrame，struct 是一个拥有命名子域的结构体。

- 基于现有列生成 struct: 在 Column 对象上使用 struct 函数，或者在表达式中使用一对括号

```scala
df.select(struct(col("gender"), col("salary")), expr("(gender, salary)")).show()
+--------------------------------------------+--------------------------------------------+
|named_struct(gender, gender, salary, salary)|named_struct(gender, gender, salary, salary)|
+--------------------------------------------+--------------------------------------------+
|                                   [M, 3000]|                                   [M, 3000]|
|                                   [M, 4000]|                                   [M, 4000]|
|                                   [M, 4000]|                                   [M, 4000]|
|                                   [F, 4000]|                                   [F, 4000]|
|                                     [F, -1]|                                     [F, -1]|
+--------------------------------------------+--------------------------------------------+
```

- 提取 struct 中的值：点操作会直接提取子域的值，列名为子域名，特别的，`.*` 可以提取 struct 中所有的子域；`getField` 方法也可以提取子域的值，但列名为完整带点号的名称

```scala
df.select(coldf.select(col("f_struct.firstname"), expr("f_struct.firstname"), col("f_struct").getField("firstname"), col("f_struct.*")).show()
+---------+---------+------------------+---------+----------+--------+
|firstname|firstname|f_struct.firstname|firstname|middlename|lastname|
+---------+---------+------------------+---------+----------+--------+
|   James |   James |            James |   James |          |   Smith|
| Michael | Michael |          Michael | Michael |      Rose|        |
|  Robert |  Robert |           Robert |  Robert |          |Williams|
|   Maria |   Maria |            Maria |   Maria |      Anne|   Jones|
|      Jen|      Jen|               Jen|      Jen|      Mary|   Brown|
+---------+---------+------------------+---------+----------+--------+
```

### ArrayType
- 基于现有列生成 array：列对象和表达式用法相同，都是在多列外使用 `array` 函数；`split`、`collect_list` 等函数也会返回 array；

```scala
df.select(array(col("gender"), col("salary")), expr("array(gender, salary)")).show()
+---------------------+-------------------------------------+
|array(gender, salary)|array(gender, CAST(salary AS STRING))|
+---------------------+-------------------------------------+
|            [M, 3000]|                            [M, 3000]|
|            [M, 4000]|                            [M, 4000]|
|            [M, 4000]|                            [M, 4000]|
|            [F, 4000]|                            [F, 4000]|
|              [F, -1]|                              [F, -1]|
+---------------------+-------------------------------------+

df.groupBy().agg(collect_list(col("gender")).as("collect_list")).show()
+---------------+
|   collect_list|
+---------------+
|[M, M, M, F, F]|
+---------------+
```

- 提取 array 中的元素：通过 `[index]` 按索引提取数组中的值；

```scala
df.select(col("f_array").getItem(0), expr("f_array[0]")).show()
+----------+----------+
|f_array[0]|f_array[0]|
+----------+----------+
|         1|         1|
|         3|         3|
|         1|         1|
|         3|         3|
|         5|         5|
+----------+----------+
```

- 处理 array 的函数：参考 [`org.apache.spark.functions`](http://spark.apache.org/docs/latest/api/scala/org/apache/spark/sql/functions$.html)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/11082009.png)

```scala
df.select(
    size(col("f_array")).as("f_array_size"),
    array_contains(col("f_array"), 1).as("f_array_contain"),
    array_max(col("f_array")).as("f_array_max"),
    array_distinct(col("f_array")).as("f_array_distinct"),
    array_position(col("f_array"), 3).as("f_array_pos"),
    array_sort(col("f_array")).as("f_array_sort"),
    array_remove(col("f_array"), 2).as("f_array_remove")
).show()
+------------+---------------+-----------+----------------+-----------+------------+--------------+
|f_array_size|f_array_contain|f_array_max|f_array_distinct|f_array_pos|f_array_sort|f_array_remove|
+------------+---------------+-----------+----------------+-----------+------------+--------------+
|           2|           true|          2|          [1, 2]|          0|      [1, 2]|           [1]|
|           2|          false|          3|          [3, 2]|          1|      [2, 3]|           [3]|
|           2|           true|          2|          [1, 2]|          0|      [1, 2]|           [1]|
|           2|          false|          3|             [3]|          1|      [3, 3]|        [3, 3]|
|           2|          false|          5|          [5, 2]|          0|      [2, 5]|           [5]|
+------------+---------------+-----------+----------------+-----------+------------+--------------+

// explode 会将数组中的所有元素取出，为每个值创建一个行，其他字段保持原样不变，默认忽略空数组
df.withColumn("f_array_val", explode(col("f_array"))).show()
+------+------+--------------------+-------+------------------+-----------+
|gender|salary|            f_struct|f_array|             f_map|f_array_val|
+------+------+--------------------+-------+------------------+-----------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|          1|
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|          2|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|          3|
|     M|  4000|  [Michael , Rose, ]| [3, 2]|[2 -> b, 22 -> bb]|          2|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|          1|
|     M|  4000|[Robert , , Willi...| [1, 2]|[3 -> c, 33 -> cc]|          2|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|          3|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|          3|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|          5|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|          2|
+------+------+--------------------+-------+------------------+-----------+
```

### MapType

- 基于现有列生成 map：Column 和表达式用法相同，`map(key1, value1, key2, value2, ...)`；其中，输入列必须可以被分组为 `key-value` 对，所有 key 列必须具有相同类型且不能为 null，value 列也必须具有相同类型（或者可以通过 cast 转化为相同类型）；

```scala
val dfmap = df.select(
    map(col("gender"), lit(1), col("salary"), lit("2")),
    expr("map(gender, 1, salary, 2)")
)
dfmap.show()
dfmap.printSchema
+-------------------------+-----------------------------------------+
|map(gender, 1, salary, 2)|map(gender, 1, CAST(salary AS STRING), 2)|
+-------------------------+-----------------------------------------+
|      [M -> 1, 3000 -> 2]|                      [M -> 1, 3000 -> 2]|
|      [M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|
|      [M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|
|      [F -> 1, 4000 -> 2]|                      [F -> 1, 4000 -> 2]|
|        [F -> 1, -1 -> 2]|                        [F -> 1, -1 -> 2]|
+-------------------------+-----------------------------------------+

root
 |-- map(gender, 1, salary, 2): map (nullable = false)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = false)
 |-- map(gender, 1, CAST(salary AS STRING), 2): map (nullable = false)
 |    |-- key: string
 |    |-- value: integer (valueContainsNull = false)
```

- 处理 map 的函数：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/202011082030.png)

```scala
dfmap
    .withColumn("map_keys", map_keys(col("f_map")))
    .withColumn("map_values", map_values(col("f_map")))
    // 返回 map 中指定 key 对应的 value，如果没有找到对应的 key 则返回 null 
    .withColumn("f_value", expr("f_map['M']"))
    .show()
+-------------------+-----------------------------------------+---------+----------+-------+
|              f_map|map(gender, 1, CAST(salary AS STRING), 2)| map_keys|map_values|f_value|
+-------------------+-----------------------------------------+---------+----------+-------+
|[M -> 1, 3000 -> 2]|                      [M -> 1, 3000 -> 2]|[M, 3000]|    [1, 2]|      1|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|[M, 4000]|    [1, 2]|      1|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|[M, 4000]|    [1, 2]|      1|
|[F -> 1, 4000 -> 2]|                      [F -> 1, 4000 -> 2]|[F, 4000]|    [1, 2]|   null|
|  [F -> 1, -1 -> 2]|                        [F -> 1, -1 -> 2]|  [F, -1]|    [1, 2]|   null|
+-------------------+-----------------------------------------+---------+----------+-------+

dfmap.select(col("*"), explode(col("f_map"))).show()
+-------------------+-----------------------------------------+----+-----+
|              f_map|map(gender, 1, CAST(salary AS STRING), 2)| key|value|
+-------------------+-----------------------------------------+----+-----+
|[M -> 1, 3000 -> 2]|                      [M -> 1, 3000 -> 2]|   M|    1|
|[M -> 1, 3000 -> 2]|                      [M -> 1, 3000 -> 2]|3000|    2|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|   M|    1|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|4000|    2|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|   M|    1|
|[M -> 1, 4000 -> 2]|                      [M -> 1, 4000 -> 2]|4000|    2|
|[F -> 1, 4000 -> 2]|                      [F -> 1, 4000 -> 2]|   F|    1|
|[F -> 1, 4000 -> 2]|                      [F -> 1, 4000 -> 2]|4000|    2|
|  [F -> 1, -1 -> 2]|                        [F -> 1, -1 -> 2]|   F|    1|
|  [F -> 1, -1 -> 2]|                        [F -> 1, -1 -> 2]|  -1|    2|
+-------------------+-----------------------------------------+----+-----+
```

## 处理 JSON
Spark 对 JSON 数据提供了一些独特的支持，可以直接在 Spark 中对 JSON 字符串进行处理，并从 JSON 字符串解析或提取 JSON 对象（返回字符串）。

- 创建一个 JSON 列：

```scala
val df = spark.range(1).selectExpr("""
    '{"myJSONKey": {"myJSONValue": [1,2,3]}}' as f_json
""")
df.show(false)
df.printSchema
```

- 提取 JSON 字符串中的值：可以使用 `get_json_object` 内联查询 JSON 对象，如果只有一层嵌套，也可以使用 `json_tuple`

```scala
val res = df
    .withColumn("f_myJSONKey", get_json_object(col("f_json"), "$.myJSONKey"))
    .withColumn("f_myJSONKey2", json_tuple(col("f_json"), "myJSONKey"))
    .withColumn("myJSONValue", get_json_object(col("f_json"), "$.myJSONKey.myJSONValue"))
    .withColumn("f_value", get_json_object(col("f_json"), "$.myJSONKey.myJSONValue[0]"))

res.show(false)
res.printSchema

+---------------------------------------+-----------------------+-----------------------+-----------+-------+
|f_json                                 |f_myJSONKey            |f_myJSONKey2           |myJSONValue|f_value|
+---------------------------------------+-----------------------+-----------------------+-----------+-------+
|{"myJSONKey": {"myJSONValue": [1,2,3]}}|{"myJSONValue":[1,2,3]}|{"myJSONValue":[1,2,3]}|[1,2,3]    |1      |
+---------------------------------------+-----------------------+-----------------------+-----------+-------+

root
 |-- f_json: string (nullable = false)
 |-- f_myJSONKey: string (nullable = true)
 |-- f_myJSONKey2: string (nullable = true)
 |-- myJSONValue: string (nullable = true)
 |-- f_value: string (nullable = true)

```

- 将 struct/map 列转化为 json 列：`to_json` 函数可以将 `StructType` 或 `MapType` 列转化为 JSON 字符串；

```scala
val dfjson = df.select("f_struct", "f_map")
    .withColumn("f_struct_json", to_json(col("f_struct")))
    .withColumn("f_map_json", to_json(col("f_map")))
dfjson.show(false)
dfjson.printSchema
+---------------------+------------------+-------------------------------------------------------------+-------------------+
|f_struct             |f_map             |f_struct_json                                                |f_map_json         |
+---------------------+------------------+-------------------------------------------------------------+-------------------+
|[James , , Smith]    |[1 -> a, 11 -> aa]|{"firstname":"James ","middlename":"","lastname":"Smith"}    |{"1":"a","11":"aa"}|
|[Michael , Rose, ]   |[2 -> b, 22 -> bb]|{"firstname":"Michael ","middlename":"Rose","lastname":""}   |{"2":"b","22":"bb"}|
|[Robert , , Williams]|[3 -> c, 33 -> cc]|{"firstname":"Robert ","middlename":"","lastname":"Williams"}|{"3":"c","33":"cc"}|
|[Maria , Anne, Jones]|[4 -> d, 44 -> dd]|{"firstname":"Maria ","middlename":"Anne","lastname":"Jones"}|{"4":"d","44":"dd"}|
|[Jen, Mary, Brown]   |[5 -> e]          |{"firstname":"Jen","middlename":"Mary","lastname":"Brown"}   |{"5":"e"}          |
+---------------------+------------------+-------------------------------------------------------------+-------------------+

root
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_struct_json: string (nullable = true)
 |-- f_map_json: string (nullable = true)
```

- 将 json 列解析回 struct/map 列：`from_json` 函数可以将 json 列解析回 struct/map 列，但是要求制定一个 Schema

```scala
val structSchema = new StructType()
    .add("firstname",StringType)
    .add("middlename",StringType)
    .add("lastname",StringType)

val mapSchema = MapType(StringType, StringType)

val dffromjson = dfjson
    .withColumn("json_strcut", from_json(col("f_struct_json"), structSchema))
    .withColumn("json_map", from_json(col("f_map_json"), mapSchema))

dffromjson.show()
dffromjson.printSchema

+--------------------+------------------+--------------------+-------------------+--------------------+------------------+
|            f_struct|             f_map|       f_struct_json|         f_map_json|         json_strcut|          json_map|
+--------------------+------------------+--------------------+-------------------+--------------------+------------------+
|   [James , , Smith]|[1 -> a, 11 -> aa]|{"firstname":"Jam...|{"1":"a","11":"aa"}|   [James , , Smith]|[1 -> a, 11 -> aa]|
|  [Michael , Rose, ]|[2 -> b, 22 -> bb]|{"firstname":"Mic...|{"2":"b","22":"bb"}|  [Michael , Rose, ]|[2 -> b, 22 -> bb]|
|[Robert , , Willi...|[3 -> c, 33 -> cc]|{"firstname":"Rob...|{"3":"c","33":"cc"}|[Robert , , Willi...|[3 -> c, 33 -> cc]|
|[Maria , Anne, Jo...|[4 -> d, 44 -> dd]|{"firstname":"Mar...|{"4":"d","44":"dd"}|[Maria , Anne, Jo...|[4 -> d, 44 -> dd]|
|  [Jen, Mary, Brown]|          [5 -> e]|{"firstname":"Jen...|          {"5":"e"}|  [Jen, Mary, Brown]|          [5 -> e]|
+--------------------+------------------+--------------------+-------------------+--------------------+------------------+

root
 |-- f_struct: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- f_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
 |-- f_struct_json: string (nullable = true)
 |-- f_map_json: string (nullable = true)
 |-- json_strcut: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- json_map: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)
```

## 参考
- [《Spark 权威指南 Chapter 6》](https://snaildove.github.io/2019/08/05/Chapter6_Working-with-Different-Types-of-Data(SparkTheDefinitiveGuide)_online/)
- [`org.apache.spark.functions`](http://spark.apache.org/docs/latest/api/scala/org/apache/spark/sql/functions$.html)

































