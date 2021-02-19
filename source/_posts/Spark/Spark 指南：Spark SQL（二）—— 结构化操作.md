
---
title: Spark 指南：Spark SQL（二）—— 结构化操作
date: 2020-11-05 14:16:46
tags: 
   - Spark
categories: 
   - Spark
---

从定义上讲，DataFrame 由一系列行和列组成，行的类型为 Row，列可以表示成每个单独行的计算表达式。Schema 定义了每个列的名称和类型，Partition 定义了整个集群中 DataFrame 的物理分布。

## Schema
Schema 定义了 DataFrame 的列名和类型，我们可以让数据源定义 Schema（schema-on-read），也可以自己明确地进行定义。对于临时分析，schema-on-read 通常效果很好，但是这也可能导致精度问题，例如在读取文件时将 Long 型错误地设置为整型，在生产环境中手动定义 Schema 通常是更好的选择，尤其是在使用 CSV 和 JSON 等无类型数据源时。

Schema 是一种 structType，由很多 StructFields 组成，每个 StructField 具有名称、类型和布尔值标识（用于指示该列是否可以为 null），最后用户可以选择指定与该列关联的元数据，元数据是一种存储有关此列的信息的方式（Spark 在其机器学习库中使用此信息）。如果数据中的类型与 Schema 不匹配，Spark 将引发错误。

```scala
import org.apache.spark.sql.types._
import org.apache.spark.sql.Row

val schema = StructType(
    Array(
        StructField("name", StringType, true),
        StructField("age", IntegerType, false)
    )
)
val data = spark.sparkContext.parallelize(Seq(
    Row("like", 18),
    Row("arya", 24)
))
val df = spark.createDataFrame(data, schema)
df.show()
+----+---+
|name|age|
+----+---+
|like| 18|
|arya| 24|
+----+---+

// 打印 DataFrame 的 Schema
df.printSchema
root
 |-- name: string (nullable = true)
 |-- age: integer (nullable = false)
```
## Columns and Expressions
**列只是表达式**（`Columns are just Expressions`）：列以及列上的转换与经过解析的表达式拥有相同的逻辑计划。这是极为重要的一点，这意味着你可以将表达式编写为 DataFrame 代码或 SQL 表达式，并获得完全相同的性能特性。

### Columns
对 Spark 而言，Columns 是一种逻辑构造，仅表示通过表达式在每条记录上所计算出来的值。这意味着要有一个列的实际值，我们就需要有一个行，要有一个行，我们就需要有一个 DataFrame，你不能在 DataFrame 上下文之外操作单个列，你必须在 DataFrame 中使用 Spark 转换来修改列的内容。

在 DataFrame 中引用列的方式有很多，以下几种语法形式是等价的：

```scala
df.columns
Array[String] = Array(name, dob, gender, salary)

df.select('dob, $"dob", df("dob"), col("dob"), df.col("dob"), expr("dob")).show()
+-----+-----+-----+-----+-----+
|  dob|  dob|  dob|  dob|  dob|
+-----+-----+-----+-----+-----+
|36636|36636|36636|36636|36636|
|40288|40288|40288|40288|40288|
|42114|42114|42114|42114|42114|
|39192|39192|39192|39192|39192|
+-----+-----+-----+-----+-----+
```

### Expressions
Expressions 是对 DataFrame 记录中一个或多个值的一组转换，可以将其视为一个函数，该函数将一个或多个列名作为输入，进行解析，然后可能应用更多表达式为数据集中每个记录创建单个值（可以是诸如 Map 或 Array 之类的复杂类型）。在最简单的情况下，通过 `expr()` 函数创建的表达式仅仅是  DataFrame 列引用，`expr("col_name")` 等价于 `col("col_name")`。

列提供了表达式功能的子集，如果使用 `col()` 并想在该列上执行转换，则必须在该列引用上执行那些转换，使用表达式时， expr 函数实际上可以解析字符串中的转换和列引用，例如：`expr("col_name - 5")` 等价于 `col("col_name") - 5`，甚至等价于 `expr("col_name") - 5`。

```scala
import org.apache.spark.sql.functions.expr
(((col("col_name") + 5) * 200) - 6) < col("other_col")
expr("(((col_name + 5) * 200) - 6) < other_col")
```

## Records and Rows
DataFrame 中的每一行都是一条记录，Spark 将此记录表示为 Row 类型的对象，Spark 使用列表达式操纵 Row 对象，以产生可用的值。Row 对象在内部表示为字节数组，但是字节数组接口从未显示给用户，因为我们仅使用列表达式来操作它们。

可以通过手动实例化具有每个列中的值的 Row 对象来创建行，但是务必注意只有 DataFrame 有 Schema，Row 本身没有模式。

```scala
import org.apache.spark.sql.Row
val myRow = Row("hello", null, 1, false)
```

访问行中的数据很容易，只需要指定位置或列名：

```scala
df.collect().foreach(row=>{
    val name = row(0).asInstanceOf[String]
    val age = row.getAs[Integer]("age")
    println(s"name:$name age:$age")
})
```

## DataFrame 转换
DataFrame 转换不会改变原有的 DataFrame，而是生成一个新的 DataFrame。很多 DataFrame 转换/函数被包含在 `org.apache.spark.sql.functions` 模块，使用前推荐先导入相关模块：

```scala
import org.apache.spark.sql.functions._
import org.apache.spark.sql.types._
import org.apache.spark.sql.Row
```

本文主要用到的示例数据：

```scala
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
```

```
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

### 列操作
#### select —— 筛选列
- 功能：`select()` 用于筛选/操作列；

- 语法：有两种语法形式，但是两种形式不能混用；

```scala
// 传入列名字符串
select(col : scala.Predef.String, cols : scala.Predef.String*) : org.apache.spark.sql.DataFrame
// 传入多个列对象
select(cols : org.apache.spark.sql.Column*) : org.apache.spark.sql.DataFrame
```

- 示例：

```scala
// 可以是列名字符串、*代表所有列、a.b 代表 struct 中的子域、不可用 as
df.select("name.firstname", "dob", "*").show()
+---------+-----+--------------------+-----+------+------+
|firstname|  dob|                name|  dob|gender|salary|
+---------+-----+--------------------+-----+------+------+
|   James |36636|   [James , , Smith]|36636|     M|  3000|
| Michael |40288|  [Michael , Rose, ]|40288|     M|  4000|
|  Robert |42114|[Robert , , Willi...|42114|     M|  4000|
|   Maria |39192|[Maria , Anne, Jo...|39192|     F|  4000|
|      Jen|     |  [Jen, Mary, Brown]|     |     F|    -1|
+---------+-----+--------------------+-----+------+------+

// 列对象有多种表示方法：$"col_name"、col("col_name")、df("col_name")
// 列可以通过.as(col_name) 起别名
// 列可以通过.cast() 改变列的类型
// 列字面量用 lit(c) 表示
df.select($"name.firstname".cast("String"), col("dob").as("f_dob"), df("*"), lit(1).as("new_col")).show()
+---------+-----+--------------------+-----+------+------+-------+
|firstname|f_dob|                name|  dob|gender|salary|new_col|
+---------+-----+--------------------+-----+------+------+-------+
|   James |36636|   [James , , Smith]|36636|     M|  3000|      1|
| Michael |40288|  [Michael , Rose, ]|40288|     M|  4000|      1|
|  Robert |42114|[Robert , , Willi...|42114|     M|  4000|      1|
|   Maria |39192|[Maria , Anne, Jo...|39192|     F|  4000|      1|
|      Jen|     |  [Jen, Mary, Brown]|     |     F|    -1|      1|
+---------+-----+--------------------+-----+------+------+-------+
```

#### selectExpr —— 通过 SQL 语句筛选列
- 功能：selectExpr 和 select 作用相同，只是 selectExpr 更加简洁、灵活、强大；
- 语法：可以通过构造任意有效的非聚合 SQL 语句来生成列（如果使用了聚合函数，则只能应用于整个 DataFrame）；这释放了 Spark 的真正力量，我们可以将 selectExpr 视为构建复杂表达式以生成新的 DataFrame 的简单方法；如果列名中包含了保留字或关键字，例如空格或破折号，可以通过反引号（`）字符引用列名；

```scala
selectExpr(exprs : scala.Predef.String*) : org.apache.spark.sql.DataFrame
select(cols : org.apache.spark.sql.Column*, expr())
```

- 示例：

```scala
df.selectExpr("name.firstname", "dob as f_dob", "*", "dob + salary as new_col").show()
df.select(col("name.firstname"), expr("dob as f_dob"), df("*"), expr("dob + salary as new_col"), lit(1).as("f_one")).show()

+---------+-----+--------------------+-----+------+------+-------+-----+
|firstname|f_dob|                name|  dob|gender|salary|new_col|f_one|
+---------+-----+--------------------+-----+------+------+-------+-----+
|   James |36636|   [James , , Smith]|36636|     M|  3000|39636.0|    1|
| Michael |40288|  [Michael , Rose, ]|40288|     M|  4000|44288.0|    1|
|  Robert |42114|[Robert , , Willi...|42114|     M|  4000|46114.0|    1|
|   Maria |39192|[Maria , Anne, Jo...|39192|     F|  4000|43192.0|    1|
|      Jen|     |  [Jen, Mary, Brown]|     |     F|    -1|   null|    1|
+---------+-----+--------------------+-----+------+------+-------+-----+

df.selectExpr("max(salary) as max_salary", "avg(salary) as `avg salary`").show()
+----------+----------+
|max_salary|avg salary|
+----------+----------+
|      4000|    2999.8|
+----------+----------+
```

selectExpr 的灵活用法使其可以替代大部分的列操作算子，但是考虑到代码的简洁性，对于一些具体的操作，往往会有更简单直接的算子。事实上，DataFrame 操作使用最多的算子是 `withColumn`，`withColumn` 算子将单列处理逻辑封装到独立的子句中，更具可读性，也方便了代码维护。

#### withColumn —— 添加或更新列
- 功能：`withColumn()` 可以用来添加新列、改变已有列的值、改变列的类型；        
- 语法：withColumn 有两个参数，列名和将为 DataFrame 各行创建值的表达式；

```scala
withColumn(colName: String, col: Column): DataFrame
```

- 示例：

```scala
// 添加新的列
df.withColumn("CopiedColumn",col("salary")* -1)
// 改变列类型
df.withColumn("salary",col("salary").cast("Integer"))
// 改变已有列的值
df.withColumn("salary",col("salary")*100)
```
#### withColumnRenamed —— 重命名列
- 功能：withColumnRenamed 用于重命名列；
- 语法：

```scala
withColumnRenamed(existingName: String, newName: String): DataFrame
```

- 示例：有多种方式可以用于重命名单个列、多个列、所有列、嵌套列

```scala
// 重命名单个列，withColumnRenamed(x, y) 将 y 列重名为 x
df.withColumnRenamed("dob","DateOfBirth")

// 重命名嵌套列，col("name").cast(schema2) 将嵌套列重命名为 schema2 中定义的列名
val schema2 = new StructType()
    .add("fname",StringType)
    .add("middlename",StringType)
    .add("lname",StringType)
df.select(col("name").cast(schema2), col("dob"), col("gender"), col("salary")).printSchema
root
 |-- name: struct (nullable = true)
 |    |-- fname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lname: string (nullable = true)
 |-- dob: string (nullable = true)
 |-- gender: string (nullable = true)
 |-- salary: string (nullable = true)

// 重命名嵌套列，col("x.y").as("z") 可以将 x 中的 y 抽离出来作为单独的列
val df4 = df.select(col("name.firstname").as("fname"),
  col("name.middlename").as("mname"),
  col("name.lastname").as("lname"),
  col("dob"),col("gender"),col("salary"))
df4.show()
+--------+-----+--------+-----+------+------+
|   fname|mname|   lname|  dob|gender|salary|
+--------+-----+--------+-----+------+------+
|  James |     |   Smith|36636|     M|  3000|
|Michael | Rose|        |40288|     M|  4000|
| Robert |     |Williams|42114|     M|  4000|
|  Maria | Anne|   Jones|39192|     F|  4000|
|     Jen| Mary|   Brown|     |     F|    -1|
+--------+-----+--------+-----+------+------+

// 重命名多列，col() 函数
val old_columns = Seq("dob","gender","salary","fname","mname","lname")
val new_columns = Seq("DateOfBirth","Sex","salary","firstName","middleName","lastName")
val columnsList = old_columns.zip(new_columns).map(f=>{col(f._1).as(f._2)})
val df5 = df4.select(columnsList:_*)
df5.show()
+-----------+---+------+---------+----------+--------+
|DateOfBirth|Sex|salary|firstName|middleName|lastName|
+-----------+---+------+---------+----------+--------+
|      36636|  M|  3000|   James |          |   Smith|
|      40288|  M|  4000| Michael |      Rose|        |
|      42114|  M|  4000|  Robert |          |Williams|
|      39192|  F|  4000|   Maria |      Anne|   Jones|
|           |  F|    -1|      Jen|      Mary|   Brown|
+-----------+---+------+---------+----------+--------+

// 重命名所有列，toDF() 方法
val newColumns = Seq("newCol1","newCol2","newCol3","newCol4")
df.toDF(newColumns:_*).show()
+--------------------+-------+-------+-------+
|             newCol1|newCol2|newCol3|newCol4|
+--------------------+-------+-------+-------+
|   [James , , Smith]|  36636|      M|   3000|
|  [Michael , Rose, ]|  40288|      M|   4000|
|[Robert , , Willi...|  42114|      M|   4000|
|[Maria , Anne, Jo...|  39192|      F|   4000|
|  [Jen, Mary, Brown]|       |      F|     -1|
+--------------------+-------+-------+-------+
```

#### drop —— 删除列
- 功能：drop() 用于删除 DataFrame 中单个或多个列，如果指定列不存在则忽略，在两个表进行 join 时通常可以利用这一点来保证两个表除了关联键之外不存在同名字段。
- 语法：

```scala
// drop 有三种不同的形式：
1) drop(colName : scala.Predef.String) : org.apache.spark.sql.DataFrame
2) drop(colNames : scala.Predef.String*) : org.apache.spark.sql.DataFrame
3) drop(col : org.apache.spark.sql.Column) : org.apache.spark.sql.DataFrame
```

- 示例：

```scala
val df = spark.range(3)
    .withColumn("today_str",lit("2020-11-04"))
    .withColumn("today", current_date())
    .withColumn("now", current_timestamp())
    .orderBy(rand())
df.show(false)
+---+----------+----------+-----------------------+
|id |today_str |today     |now                    |
+---+----------+----------+-----------------------+
|0  |2020-11-04|2020-11-04|2020-11-04 20:57:06.515|
|1  |2020-11-04|2020-11-04|2020-11-04 20:57:06.515|
|2  |2020-11-04|2020-11-04|2020-11-04 20:57:06.515|
+---+----------+----------+-----------------------+
// 删除单列
df.drop("today_str").show()
+---+----------+--------------------+
| id|     today|                 now|
+---+----------+--------------------+
|  0|2020-11-04|2020-11-04 22:19:...|
|  1|2020-11-04|2020-11-04 22:19:...|
|  2|2020-11-04|2020-11-04 22:19:...|
+---+----------+--------------------+

// 删除多列
df.drop("today_str", "today").show()
+---+--------------------+
| id|                 now|
+---+--------------------+
|  0|2020-11-04 22:19:...|
|  1|2020-11-04 22:19:...|
|  2|2020-11-04 22:19:...|
+---+--------------------+

// 删除不存在的列
df.drop("xxx").show()
+---+----------+----------+--------------------+
| id| today_str|     today|                 now|
+---+----------+----------+--------------------+
|  0|2020-11-04|2020-11-04|2020-11-04 22:19:...|
|  1|2020-11-04|2020-11-04|2020-11-04 22:19:...|
|  2|2020-11-04|2020-11-04|2020-11-04 22:19:...|
+---+----------+----------+--------------------+
```

### 行操作
#### where | filter —— 筛选行
- 功能：where 和 filter 是完全等价的，用于按照指定条件筛选 DataFrame 中满足条件的行；
- 语法：传入一个布尔表达式，过滤掉 false 所对应的行；

```scala
// 有四种形式
1) filter(condition: Column): Dataset[T]
2) filter(conditionExpr: String): Dataset[T]
3) filter(func: T => Boolean): Dataset[T]
4) filter(func: FilterFunction[T]): Dataset[T]
```

- 示例：

```scala
df.show()
+--------------------+------------------+-----+------+
|                name|         languages|state|gender|
+--------------------+------------------+-----+------+
|    [James, , Smith]|[Java, Scala, C++]|   OH|     M|
|      [Anna, Rose, ]|[Spark, Java, C++]|   NY|     F|
| [Julia, , Williams]|      [CSharp, VB]|   OH|     F|
|[Maria, Anne, Jones]|      [CSharp, VB]|   NY|     M|
|  [Jen, Mary, Brown]|      [CSharp, VB]|   NY|     M|
|[Mike, Mary, Will...|      [Python, VB]|   OH|     M|
+--------------------+------------------+-----+------+

// Column 形式表达式
df.filter(df("state") === "OH" && df("gender") === "M")
// String 形式表达式 == 和 = 等价
df.filter("gender == 'M'")
df.filter("gender = 'M'")
// Filtering on an Array column
df.filter(array_contains(df("languages"),"Java"))
// Filtering on Nested Struct columns
df.filter(df("name.lastname") === "Williams")
```
#### distinct —— 行去重
- 功能：`distinct()` 方法可以移除 DataFrame 中重复的行，`dropDuplicates()` 方法用于移除 DataFrame 中在某几个字段上重复的行（默认保留重复行中的第一行）。
- 语法：

```scala
distinct(): Dataset[T] = dropDuplicates()
dropDuplicates(colNames: Seq[String]): Dataset[T]
```
- 示例：

```scala
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

// Distinct all columns
val distinctDF = df.distinct()
println("Distinct count: "+distinctDF.count())
distinctDF.show(false)

Distinct count: 9
+-------------+----------+------+
|employee_name|department|salary|
+-------------+----------+------+
|James        |Sales     |3000  |
|Michael      |Sales     |4600  |
|Maria        |Finance   |3000  |
|Robert       |Sales     |4100  |
|Saif         |Sales     |4100  |
|Scott        |Finance   |3300  |
|Jeff         |Marketing |3000  |
|Jen          |Finance   |3900  |
|Kumar        |Marketing |2000  |
+-------------+----------+------+

// Distinct using dropDuplicates
val dropDisDF = df.dropDuplicates("department","salary")
println("Distinct count of department & salary : "+dropDisDF.count())
dropDisDF.show(false)

Distinct count of department & salary : 8
+-------------+----------+------+
|employee_name|department|salary|
+-------------+----------+------+
|Jen          |Finance   |3900  |
|Maria        |Finance   |3000  |
|Scott        |Finance   |3300  |
|Michael      |Sales     |4600  |
|Kumar        |Marketing |2000  |
|Robert       |Sales     |4100  |
|James        |Sales     |3000  |
|Jeff         |Marketing |3000  |
+-------------+----------+------+
```

#### groupBy —— 行分组
- 功能：和 SQL 中的 group by 语句类似，`groupBy()` 函数用于将 `DataFrame/Dataset` 按照指定字段分组，返回一个 `RelationalGroupedDataset` 对象
- 语法：`RelationalGroupedDataset` 对象包含以下几种聚合方法：
    - count()/max()/min()/mean()/avg()/sum(): 返回每个分组的行数/最大/最小/平均值/和；
    - agg(): 可以同时计算多个聚合；
    - pivot(): 用于行转列；

- 示例：

```scala
import spark.implicits._
val simpleData = Seq(("James","Sales","NY",90000,34,10000),
    ("Michael","Sales","NY",86000,56,20000),
    ("Robert","Sales","CA",81000,30,23000),
    ("Maria","Finance","CA",90000,24,23000),
    ("Raman","Finance","CA",99000,40,24000),
    ("Scott","Finance","NY",83000,36,19000),
    ("Jen","Finance","NY",79000,53,15000),
    ("Jeff","Marketing","CA",80000,25,18000),
    ("Kumar","Marketing","NY",91000,50,21000)
  )
val df = simpleData.toDF("employee_name","department","state","salary","age","bonus")
df.show()

+-------------+----------+-----+------+---+-----+
|employee_name|department|state|salary|age|bonus|
+-------------+----------+-----+------+---+-----+
|        James|     Sales|   NY| 90000| 34|10000|
|      Michael|     Sales|   NY| 86000| 56|20000|
|       Robert|     Sales|   CA| 81000| 30|23000|
|        Maria|   Finance|   CA| 90000| 24|23000|
|        Raman|   Finance|   CA| 99000| 40|24000|
|        Scott|   Finance|   NY| 83000| 36|19000|
|          Jen|   Finance|   NY| 79000| 53|15000|
|         Jeff| Marketing|   CA| 80000| 25|18000|
|        Kumar| Marketing|   NY| 91000| 50|21000|
+-------------+----------+-----+------+---+-----+

// 计算每个分组的行数
df.groupBy("department").count().show()
+----------+-----+
|department|count|
+----------+-----+
|     Sales|    3|
|   Finance|    4|
| Marketing|    2|
+----------+-----+

// 在某个列上聚合
df.groupBy("department").sum("salary").show(false)
+----------+-----------+
|department|sum(salary)|
+----------+-----------+
|Sales     |257000     |
|Finance   |351000     |
|Marketing |171000     |
+----------+-----------+

// 同时在多列应用相同的聚合函数
df.groupBy("department","state")
    .sum("salary","bonus")
    .show(false)

+----------+-----+-----------+----------+
|department|state|sum(salary)|sum(bonus)|
+----------+-----+-----------+----------+
|Finance   |NY   |162000     |34000     |
|Marketing |NY   |91000      |21000     |
|Sales     |CA   |81000      |23000     |
|Marketing |CA   |80000      |18000     |
|Finance   |CA   |189000     |47000     |
|Sales     |NY   |176000     |30000     |
+----------+-----+-----------+----------+

// agg() 可以同时在多个列上应用不同聚合函数，并为每个聚合结果起别名
import org.apache.spark.sql.functions._
df.groupBy("department")
    .agg(
      sum("salary").as("sum_salary"),
      avg("salary").as("avg_salary"),
      sum("bonus").as("sum_bonus"),
      max("bonus").as("max_bonus"))
    .show(false)
+----------+----------+-----------------+---------+---------+
|department|sum_salary|avg_salary       |sum_bonus|max_bonus|
+----------+----------+-----------------+---------+---------+
|Sales     |257000    |85666.66666666667|53000    |23000    |
|Finance   |351000    |87750.0          |81000    |24000    |
|Marketing |171000    |85500.0          |39000    |21000    |
+----------+----------+-----------------+---------+---------+
```

#### sort —— 行排序
- 功能：在 Spark 中，可以使用 sort() 或 orderBy() 方法来根据某几个字段的值对 DataFrame/Dataset 进行排序。
- 语法：

```scala
// sort
sort(sortCol : scala.Predef.String, sortCols : scala.Predef.String*) : Dataset[T]
sort(sortExprs : org.apache.spark.sql.Column*) : Dataset[T]
// orderBy
orderBy(sortCol : scala.Predef.String, sortCols : scala.Predef.String*) : Dataset[T]
orderBy(sortExprs : org.apache.spark.sql.Column*) : Dataset[T]
```

- 示例：

```scala
df.sort("department","state").show(false)
df.sort(col("department"),col("state")).show(false)

df.orderBy("department","state").show(false)
df.orderBy(col("department"),col("state")).show(false)

// 默认即为升序 asc
df.sort(col("department").asc,col("state").desc).show(false)
df.orderBy(col("department").asc,col("state").desc).show(false)

// Spark SQL 函数提供了 asc desc asc_nulls_first asc_nulls_last 函数
df.select($"employee_name",asc("department"),desc("state"),$"salary",$"age",$"bonus").show(false)
df.createOrReplaceTempView("EMP")
spark.sql(" select employee_name,asc('department'),desc('state'),salary,age,bonus from EMP").show(false)
```

#### map —— 映射
- 功能：map() 和 mapPartitions() 转换将函数应用于 DataFrame/Dataset 的每个元素/记录/行，并返回新的 DataFrame/Dataset，需要注意的是这两个转换都返回 Dataset[U] 而不是 DataFrame（在Spark 2.0中，DataFrame = Dataset [Row]）。
- 语法: Spark 提供了 2 个映射转换签名，一个以 scala.function1 作为参数，另一个以 Spark MapFunction 作为签名，注意到这两个函数都返回 Dataset [U]，但不返回DataFrame，即Dataset [Row]。如果希望将 DataFrame 作为输出，则需要使用 toDF() 函数将 Dataset 转换为 DataFrame。

```scala
1) map[U](func : scala.Function1[T, U])(implicit evidence$6 : org.apache.spark.sql.Encoder[U]) 
        : org.apache.spark.sql.Dataset[U]
2) map[U](func : org.apache.spark.api.java.function.MapFunction[T, U], encoder : org.apache.spark.sql.Encoder[U]) 
        : org.apache.spark.sql.Dataset[U]
```

- 示例:

```scala
// 示例数据
val structureData = Seq(
    Row("James","","Smith","36636","NewYork",3100),
    Row("Michael","Rose","","40288","California",4300),
    Row("Robert","","Williams","42114","Florida",1400),
    Row("Maria","Anne","Jones","39192","Florida",5500),
    Row("Jen","Mary","Brown","34561","NewYork",3000)
    )

val structureSchema = new StructType()
    .add("firstname",StringType)
    .add("middlename",StringType)
    .add("lastname",StringType)
    .add("id",StringType)
    .add("location",StringType)
    .add("salary",IntegerType)

val df2 = spark.createDataFrame(
    spark.sparkContext.parallelize(structureData),structureSchema)
df2.printSchema()
df2.show(false)

root
 |-- firstname: string (nullable = true)
 |-- middlename: string (nullable = true)
 |-- lastname: string (nullable = true)
 |-- id: string (nullable = true)
 |-- location: string (nullable = true)
 |-- salary: integer (nullable = true)

+---------+----------+--------+-----+----------+------+
|firstname|middlename|lastname|id   |location  |salary|
+---------+----------+--------+-----+----------+------+
|James    |          |Smith   |36636|NewYork   |3100  |
|Michael  |Rose      |        |40288|California|4300  |
|Robert   |          |Williams|42114|Florida   |1400  |
|Maria    |Anne      |Jones   |39192|Florida   |5500  |
|Jen      |Mary      |Brown   |34561|NewYork   |3000  |
+---------+----------+--------+-----+----------+------+

// 为了通过实例解释 map() 和 mapPartitions()，我们再创建一个 Util 类，这个类具有一个 combine() 方法，该方法接收三个字符串参数，通过逗号合并三个参数并输出。
class Util extends Serializable {
  def combine(fname:String,mname:String,lname:String):String = {
    fname+","+mname+","+lname
  }
}

// map 是在 worker 节点上执行的，而我们在 map 函数内部创建了 Util 实例，初始化将发生在 DataFrame 中的每一行，当您进行了大量复杂的初始化时，这会导致性能问题
import spark.implicits._
val df3 = df2.map(row=>{
    val util = new Util()
    val fullName = util.combine(row.getString(0),row.getString(1),row.getString(2))
    (fullName, row.getString(3),row.getInt(5))
})
val df3Map =  df3.toDF("fullName","id","salary")

df3Map.printSchema()
df3Map.show(false)

root
 |-- fullName: string (nullable = true)
 |-- id: string (nullable = true)
 |-- salary: integer (nullable = false)

+----------------+-----+------+
|fullName        |id   |salary|
+----------------+-----+------+
|James,,Smith    |36636|3100  |
|Michael,Rose,   |40288|4300  |
|Robert,,Williams|42114|1400  |
|Maria,Anne,Jones|39192|5500  |
|Jen,Mary,Brown  |34561|3000  |
+----------------+-----+------+

// mapPartitions() 提供了一种功能，可以对每个分区进行一次初始化（例如，数据库连接），而不是对每个行进行一次初始化，这有助于提提高效率，下面代码将得到和上例相同的结果
val df4 = df2.mapPartitions(iterator => {
    val util = new Util()
    val res = iterator.map(row=>{
        val fullName = util.combine(row.getString(0),row.getString(1),row.getString(2))
        (fullName, row.getString(3),row.getInt(5))
    })
    res
})
val df4part = df4.toDF("fullName","id","salary")
df4part.printSchema()
df4part.show(false)
```

#### foreach —— 遍历
- 功能：foreach() 方法用于在 RDD/DataFrame/Dataset 的每个元素上应用函数，主要用于操作累积器共享变量，也可以用于将 RDD/DataFrame 结果写入数据库，生产消息到 kafka topic 等。foreachPartition() 方法用于在 RDD/DataFrame/Dataset 的每个分区上应用函数，主要用于在每个分区进行复杂的初始化操作（比如连接数据库），也可以用于操作累加器变量。foreach() 和 foreachPartition() 方法都是不会返回值的 action。

- 语法:

```scala
foreachPartition(f : scala.Function1[scala.Iterator[T], scala.Unit]) : scala.Unit

```

- 示例:

```scala
// foreach 操作累加器
val longAcc = spark.sparkContext.longAccumulator("SumAccumulator")
df.foreach(f=> {
    longAcc.add(f.getInt(1))
  })
println("Accumulator value:"+longAcc.value)

// foreachPartition 写入数据
val df = spark.createDataFrame(data).toDF("Product","Amount","Country")
df.foreachPartition(partition => {
    //Initialize database connection or kafka
    partition.foreach(fun=>{
      //apply the function to insert the database 
      // or produce kafka topic
    })
    //If you have batch inserts, do here.
  })

// rdd foreach 和 DataFrame foreach 是等价的 action
val rdd2 = spark.sparkContext.parallelize(Seq(1,2,3,4,5,6,7,8,9))
val longAcc2 = spark.sparkContext.longAccumulator("SumAccumulator2")
  rdd.foreach(f=> {
    longAcc2.add(f)
  })
println("Accumulator value:"+longAcc2.value)
```
#### sample —— 随机抽样
- 功能：从 DataFrame 中抽取一些随机记录；
- 语法：

```scala
// withReplacement: 是否是有放回抽样; fraction: 抽样比例; seed: 抽样算法初始值
sample(fraction: Double)
sample(fraction: Double, seed: Long)
sample(withReplacement: Boolean, fraction: Double)
sample(withReplacement: Boolean, fraction: Double, seed: Long)
```

- 示例：

```scala
df.sample(0.2).show()
+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|[Maria , Anne, Jo...|39192|     F|  4000|
+--------------------+-----+------+------+

df.sample(0.5, 1000L).show()
+------------------+-----+------+------+
|              name|  dob|gender|salary|
+------------------+-----+------+------+
| [James , , Smith]|36636|     M|  3000|
|[Jen, Mary, Brown]|     |     F|    -1|
+------------------+-----+------+------+

df.sample(true, 0.5, 1000L).show()
+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|[Maria , Anne, Jo...|39192|     F|  4000|
|[Maria , Anne, Jo...|39192|     F|  4000|
|  [Jen, Mary, Brown]|     |     F|    -1|
+--------------------+-----+------+------+
```

#### split —— 随机分割
- 功能：将原始 DataFrame 随机拆分，这通常与机器学习算法一起使用以创建训练、验证和测试集；
- 语法：返回 Array(DataFrame)；

```scala
randomSplit(weights: Array[Double])
randomSplit(weights: Array[Double], seed: Long)
```

- 示例：

```scala
val dfs = df.randomSplit(Array(0.8, 0.2))
dfs(0).show()
dfs(1).show()
+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|   [James , , Smith]|36636|     M|  3000|
|  [Michael , Rose, ]|40288|     M|  4000|
|[Maria , Anne, Jo...|39192|     F|  4000|
+--------------------+-----+------+------+

+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|[Robert , , Willi...|42114|     M|  4000|
|  [Jen, Mary, Brown]|     |     F|    -1|
+--------------------+-----+------+------+
```

#### limit —— 限制
- 功能：限制从 DataFrame 中提取的内容，当你需要一个空的 DataFrame 但又想保留 Schema 信息时可以通过 `df.limit(0)` 来实现；
- 语法：

```scala
df.limit(n)
```

- 示例：

```scala
df.orderBy("dob").limit(3).show()
+--------------------+-----+------+------+
|                name|  dob|gender|salary|
+--------------------+-----+------+------+
|  [Jen, Mary, Brown]|     |     F|    -1|
|   [James , , Smith]|36636|     M|  3000|
|[Maria , Anne, Jo...|39192|     F|  4000|
+--------------------+-----+------+------+

df.limit(0).show()
+----+---+------+------+
|name|dob|gender|salary|
+----+---+------+------+
+----+---+------+------+
```

#### first | last —— 首行或末行
- 功能：获取某列第一行/最后一行的值

- 语法：

```scala
first(e: Column, ignoreNulls: Boolean)
first(columnName: String, ignoreNulls: Boolean)
```

- 示例：

```scala
df.select(first("name"), first("dob"), last("gender"), last("salary")).show()
+------------------+-----------------+-------------------+-------------------+
|first(name, false)|first(dob, false)|last(gender, false)|last(salary, false)|
+------------------+-----------------+-------------------+-------------------+
| [James , , Smith]|            36636|                  F|                 -1|
+------------------+-----------------+-------------------+-------------------+

```

### 表操作
#### union —— 合并
- 功能：在 Spark 中 union() 和 unionAll() 作用相同，用于合并两个 schema 相同（不会校验schema，只会校验字段数是否相同）的 DataFrame，但是都不会对结果进行去重，如果需要去重，可以通过去重算子对结果去重。
- 语法：

```scala
df.union(df2)
```
- 示例：

```scala
// 没有什么好展示的
val df5 = df.union(df2).distinct()
```

#### join —— 连接

- 功能：Spark SQL 支持传统 SQL 中可用的所有基本联接操作（这里不再赘述），尽管 Spark 核心联接在设计时不小心会产生巨大的性能问题，因为它涉及到跨网络的数据 shuffe，另一方面，Spark SQL 连接在默认情况下具有更多的优化（多亏了 DataFrames & Dataset），但是在使用时仍然会有一些性能问题需要考虑；
- 语法: 三要素为连接表、连接谓词、连接类型；

```scala
1) join(right: Dataset[_]): DataFrame

// 使用 usingColumn：join 结果中只会保留左表的 usingColumn，以及左右表其他列
2) join(right: Dataset[_], usingColumn: String): DataFrame
3) join(right: Dataset[_], usingColumns: Seq[String]): DataFrame
4) join(right: Dataset[_], usingColumns: Seq[String], joinType: String): DataFrame

// 使用 joinExprs：joinExprs 返回一个布尔型 Column，join 结果会包含两个表的所有列
5) join(right: Dataset[_], joinExprs: Column): DataFrame
6) join(right: Dataset[_], joinExprs: Column, joinType: String): DataFrame

// 笛卡尔积：将左表中的每一行与右表中的每一行进行连接
7) crossJoin(right: Dataset[_])
```

- join 类型: 对于上面语句 4 和语句 5，你可以使用 JoinType 或 Join String 中的一种，如果要使用 JoinType，应该先导入 `import org.apache.spark.sql.catalyst.plans._`，以下示例将采用上面语句 6 的形式

| JoinType        | Join String                         | Equivalent SQL Join |
|-----------------|-------------------------------------|---------------------|
| Inner\.sql      | inner                               | INNER JOIN          |
| FullOuter\.sql  | outer, full, fullouter, full\_outer | FULL OUTER JOIN     |
| LeftOuter\.sql  | left, leftouter, left\_outer        | LEFT JOIN           |
| RightOuter\.sql | right, rightouter, right\_outer     | RIGHT JOIN          |
| Cross\.sql      | cross                               | -                   |
| LeftAnti\.sql   | anti, leftanti, left\_anti          | -                   |
| LeftSemi\.sql   | semi, leftsemi, left\_semi          | -                   |

- 示例数据:

```scala
val emp = Seq((1,"Smith",-1,"2018","10","M",3000),
    (2,"Rose",1,"2010","20","M",4000),
    (3,"Williams",1,"2010","10","M",1000),
    (4,"Jones",2,"2005","10","F",2000),
    (5,"Brown",2,"2010","40","",-1),
      (6,"Brown",2,"2010","50","",-1)
  )
val empColumns = Seq("emp_id","name","superior_emp_id","year_joined",
   "emp_dept_id","gender","salary")
import spark.sqlContext.implicits._
val empDF = emp.toDF(empColumns:_*)
empDF.show(false)

+------+--------+---------------+-----------+-----------+------+------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|
+------+--------+---------------+-----------+-----------+------+------+
|1     |Smith   |-1             |2018       |10         |M     |3000  |
|2     |Rose    |1              |2010       |20         |M     |4000  |
|3     |Williams|1              |2010       |10         |M     |1000  |
|4     |Jones   |2              |2005       |10         |F     |2000  |
|5     |Brown   |2              |2010       |40         |      |-1    |
|6     |Brown   |2              |2010       |50         |      |-1    |
+------+--------+---------------+-----------+-----------+------+------+

val dept = Seq(("Finance",10),
("Marketing",20),
("Sales",30),
("IT",40)
)

val deptColumns = Seq("dept_name","dept_id")
val deptDF = dept.toDF(deptColumns:_*)
deptDF.show(false)

+---------+-------+
|dept_name|dept_id|
+---------+-------+
|Finance  |10     |
|Marketing|20     |
|Sales    |30     |
|IT       |40     |
+---------+-------+
```

##### Inner Join
Inner Join 内连接，只返回匹配成功的行。

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"inner").show(false)

+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|1     |Smith   |-1             |2018       |10         |M     |3000  |Finance  |10     |
|2     |Rose    |1              |2010       |20         |M     |4000  |Marketing|20     |
|3     |Williams|1              |2010       |10         |M     |1000  |Finance  |10     |
|4     |Jones   |2              |2005       |10         |F     |2000  |Finance  |10     |
|5     |Brown   |2              |2010       |40         |      |-1    |IT       |40     |
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
```

##### Full Join
Outer/Full,/Fullouter Join 全外连接，匹配成功的 + 左表有右表没有 + 右表有左表没有

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"outer").show(false)
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"full").show(false)
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"fullouter").show(false)

+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|2     |Rose    |1              |2010       |20         |M     |4000  |Marketing|20     |
|5     |Brown   |2              |2010       |40         |      |-1    |IT       |40     |
|1     |Smith   |-1             |2018       |10         |M     |3000  |Finance  |10     |
|3     |Williams|1              |2010       |10         |M     |1000  |Finance  |10     |
|4     |Jones   |2              |2005       |10         |F     |2000  |Finance  |10     |
|6     |Brown   |2              |2010       |50         |      |-1    |null     |null   |
|null  |null    |null           |null       |null       |null  |null  |Sales    |30     |
+------+--------+---------------+-----------+-----------+------+------+---------+-------+

```

##### Left Join
Left/Leftouter Join 左连接，匹配成功的 + 左表有右表没有的

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"left").show(false)
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"leftouter").show(false)

+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|1     |Smith   |-1             |2018       |10         |M     |3000  |Finance  |10     |
|2     |Rose    |1              |2010       |20         |M     |4000  |Marketing|20     |
|3     |Williams|1              |2010       |10         |M     |1000  |Finance  |10     |
|4     |Jones   |2              |2005       |10         |F     |2000  |Finance  |10     |
|5     |Brown   |2              |2010       |40         |      |-1    |IT       |40     |
|6     |Brown   |2              |2010       |50         |      |-1    |null     |null   |
+------+--------+---------------+-----------+-----------+------+------+---------+-------+

```

##### Right Join
Right/Rightouter Join 右连接，匹配成功的 + 右表有左表没有的

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"right").show(false)
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"rightouter").show(false)

+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|4     |Jones   |2              |2005       |10         |F     |2000  |Finance  |10     |
|3     |Williams|1              |2010       |10         |M     |1000  |Finance  |10     |
|1     |Smith   |-1             |2018       |10         |M     |3000  |Finance  |10     |
|2     |Rose    |1              |2010       |20         |M     |4000  |Marketing|20     |
|null  |null    |null           |null       |null       |null  |null  |Sales    |30     |
|5     |Brown   |2              |2010       |40         |      |-1    |IT       |40     |
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
```

##### Left Semi Join
Left Semi Join 左半连接，匹配成功的，只保留左表字段。

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"leftsemi").show(false)

+------+--------+---------------+-----------+-----------+------+------+
|emp_id|name    |superior_emp_id|year_joined|emp_dept_id|gender|salary|
+------+--------+---------------+-----------+-----------+------+------+
|1     |Smith   |-1             |2018       |10         |M     |3000  |
|2     |Rose    |1              |2010       |20         |M     |4000  |
|3     |Williams|1              |2010       |10         |M     |1000  |
|4     |Jones   |2              |2005       |10         |F     |2000  |
|5     |Brown   |2              |2010       |40         |      |-1    |
+------+--------+---------------+-----------+-----------+------+------+
```

##### Left Anti Join
Left Anti Join 反左半连接，没有匹配成功的，只返回左表字段

```scala
empDF.join(deptDF,empDF("emp_dept_id") ===  deptDF("dept_id"),"leftanti").show(false)

+------+-----+---------------+-----------+-----------+------+------+
|emp_id|name |superior_emp_id|year_joined|emp_dept_id|gender|salary|
+------+-----+---------------+-----------+-----------+------+------+
|6     |Brown|2              |2010       |50         |      |-1    |
+------+-----+---------------+-----------+-----------+------+------+

```

##### Self Join
虽然没有自连接类型，但是可以使用以上任意一种 join 类型与自己关联，但是要通过别名的方式。为DataFrame 起别名 `"a"` 后，原有字段名 `"col"` 就变成 `"a.col"`，可以通过 `"a.*"` 把原有的列“释放”出来。

```scala
empDF.as("emp1").join(empDF.as("emp2"), col("emp1.superior_emp_id") === col("emp2.emp_id"),"inner")
    .select(col("emp1.emp_id"),col("emp1.name"),
      col("emp2.emp_id").as("superior_emp_id"),
      col("emp2.name").as("superior_emp_name")
    )
    .show(false)
  
+------+--------+---------------+-----------------+
|emp_id|name    |superior_emp_id|superior_emp_name|
+------+--------+---------------+-----------------+
|2     |Rose    |1              |Smith            |
|3     |Williams|1              |Smith            |
|4     |Jones   |2              |Rose             |
|5     |Brown   |2              |Rose             |
|6     |Brown   |2              |Rose             |
+------+--------+---------------+-----------------+
```

##### Cross Join
Cross Join（笛卡尔连接、交叉连接）会将左侧 DataFrame 中的每一行与右侧 DataFrame 中的每一行进行连接，这将导致结果 DataFrame 中的行数发生绝对爆炸，仅在绝对必要时才应使用笛卡尔积，它们很危险！！！我们分几种场景来讨论和 Cross Join 相关的一些问题：

- `join` 算子中如果指定了连接谓词，那么，即使将参数 `joinType` 设置为 "cross"，实际执行的仍然是 `inner join`

```scala
empDF.join(deptDF, empDF("emp_dept_id") === deptDF("dept_id"), "cross").show()
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|    name|superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|     1|   Smith|             -1|       2018|         10|     M|  3000|  Finance|     10|
|     2|    Rose|              1|       2010|         20|     M|  4000|Marketing|     20|
|     3|Williams|              1|       2010|         10|     M|  1000|  Finance|     10|
|     4|   Jones|              2|       2005|         10|     F|  2000|  Finance|     10|
|     5|   Brown|              2|       2010|         40|      |    -1|       IT|     40|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
```

- `join` 算子中，如果将连接谓词设置为恒等式，可以实现笛卡尔积（`joinType`需同时设置为 "cross"）

```scala
empDF.join(deptDF, lit(1) === lit(1), "cross").show()
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|    name|superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|     1|   Smith|             -1|       2018|         10|     M|  3000|  Finance|     10|
|     1|   Smith|             -1|       2018|         10|     M|  3000|Marketing|     20|
|     1|   Smith|             -1|       2018|         10|     M|  3000|    Sales|     30|
|     1|   Smith|             -1|       2018|         10|     M|  3000|       IT|     40|
|     2|    Rose|              1|       2010|         20|     M|  4000|  Finance|     10|
|     2|    Rose|              1|       2010|         20|     M|  4000|Marketing|     20|
|     2|    Rose|              1|       2010|         20|     M|  4000|    Sales|     30|
|     2|    Rose|              1|       2010|         20|     M|  4000|       IT|     40|
|     3|Williams|              1|       2010|         10|     M|  1000|  Finance|     10|
|     3|Williams|              1|       2010|         10|     M|  1000|Marketing|     20|
|     3|Williams|              1|       2010|         10|     M|  1000|    Sales|     30|
|     3|Williams|              1|       2010|         10|     M|  1000|       IT|     40|
|     4|   Jones|              2|       2005|         10|     F|  2000|  Finance|     10|
|     4|   Jones|              2|       2005|         10|     F|  2000|Marketing|     20|
|     4|   Jones|              2|       2005|         10|     F|  2000|    Sales|     30|
|     4|   Jones|              2|       2005|         10|     F|  2000|       IT|     40|
|     5|   Brown|              2|       2010|         40|      |    -1|  Finance|     10|
|     5|   Brown|              2|       2010|         40|      |    -1|Marketing|     20|
|     5|   Brown|              2|       2010|         40|      |    -1|    Sales|     30|
|     5|   Brown|              2|       2010|         40|      |    -1|       IT|     40|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
```

- `join` 算子中，如果省略了连接谓词，则会报 `AnalysisException` 错误，一种解决办法是设置 `spark.conf.set("spark.sql.crossJoin.enabled",true)`，以允许笛卡尔积而不会发出警告或 Spark 不会尝试为您执行另一种连接

```scala
empDF.join(deptDF).show()
org.apache.spark.sql.AnalysisException: Detected implicit cartesian product for INNER join between logical plans
LocalRelation [emp_id#940, name#941, superior_emp_id#942, year_joined#943, emp_dept_id#944, gender#945, salary#946]
and
LocalRelation [dept_name#981, dept_id#982]
Join condition is missing or trivial.
Either: use the CROSS JOIN syntax to allow cartesian products between these
relations, or: enable implicit cartesian products by setting the configuration
variable spark.sql.crossJoin.enabled=true;

spark.conf.set("spark.sql.crossJoin.enabled",true)
empDF.join(deptDF).show()
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|    name|superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|     1|   Smith|             -1|       2018|         10|     M|  3000|  Finance|     10|
|     1|   Smith|             -1|       2018|         10|     M|  3000|Marketing|     20|
|     1|   Smith|             -1|       2018|         10|     M|  3000|    Sales|     30|
|     1|   Smith|             -1|       2018|         10|     M|  3000|       IT|     40|
|     2|    Rose|              1|       2010|         20|     M|  4000|  Finance|     10|
|     2|    Rose|              1|       2010|         20|     M|  4000|Marketing|     20|
|     2|    Rose|              1|       2010|         20|     M|  4000|    Sales|     30|
|     2|    Rose|              1|       2010|         20|     M|  4000|       IT|     40|
|     3|Williams|              1|       2010|         10|     M|  1000|  Finance|     10|
|     3|Williams|              1|       2010|         10|     M|  1000|Marketing|     20|
|     3|Williams|              1|       2010|         10|     M|  1000|    Sales|     30|
|     3|Williams|              1|       2010|         10|     M|  1000|       IT|     40|
|     4|   Jones|              2|       2005|         10|     F|  2000|  Finance|     10|
|     4|   Jones|              2|       2005|         10|     F|  2000|Marketing|     20|
|     4|   Jones|              2|       2005|         10|     F|  2000|    Sales|     30|
|     4|   Jones|              2|       2005|         10|     F|  2000|       IT|     40|
|     5|   Brown|              2|       2010|         40|      |    -1|  Finance|     10|
|     5|   Brown|              2|       2010|         40|      |    -1|Marketing|     20|
|     5|   Brown|              2|       2010|         40|      |    -1|    Sales|     30|
|     5|   Brown|              2|       2010|         40|      |    -1|       IT|     40|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
only showing top 20 rows
```

- 以上方式虽然可以实现 cross Join，但并不推荐使用，从 `spark-sql_2.11` 2.1.0 之后的版本专门提供了 `crossJoin` 算子来实现笛卡尔积，使用 `crossJoin` 不用修改配置

```scala
empDF.crossJoin(deptDF).show()
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|emp_id|    name|superior_emp_id|year_joined|emp_dept_id|gender|salary|dept_name|dept_id|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
|     1|   Smith|             -1|       2018|         10|     M|  3000|  Finance|     10|
|     1|   Smith|             -1|       2018|         10|     M|  3000|Marketing|     20|
|     1|   Smith|             -1|       2018|         10|     M|  3000|    Sales|     30|
|     1|   Smith|             -1|       2018|         10|     M|  3000|       IT|     40|
|     2|    Rose|              1|       2010|         20|     M|  4000|  Finance|     10|
|     2|    Rose|              1|       2010|         20|     M|  4000|Marketing|     20|
|     2|    Rose|              1|       2010|         20|     M|  4000|    Sales|     30|
|     2|    Rose|              1|       2010|         20|     M|  4000|       IT|     40|
|     3|Williams|              1|       2010|         10|     M|  1000|  Finance|     10|
|     3|Williams|              1|       2010|         10|     M|  1000|Marketing|     20|
|     3|Williams|              1|       2010|         10|     M|  1000|    Sales|     30|
|     3|Williams|              1|       2010|         10|     M|  1000|       IT|     40|
|     4|   Jones|              2|       2005|         10|     F|  2000|  Finance|     10|
|     4|   Jones|              2|       2005|         10|     F|  2000|Marketing|     20|
|     4|   Jones|              2|       2005|         10|     F|  2000|    Sales|     30|
|     4|   Jones|              2|       2005|         10|     F|  2000|       IT|     40|
|     5|   Brown|              2|       2010|         40|      |    -1|  Finance|     10|
|     5|   Brown|              2|       2010|         40|      |    -1|Marketing|     20|
|     5|   Brown|              2|       2010|         40|      |    -1|    Sales|     30|
|     5|   Brown|              2|       2010|         40|      |    -1|       IT|     40|
+------+--------+---------------+-----------+-----------+------+------+---------+-------+
```

##### 同源 DataFrame JOIN 陷阱
当同源 DataFrame（衍生于同一个 DataFrame ）之间进行 Join 时，可能会导致一些意想不到的错误。

```scala
var x = empDF.groupBy("superior_emp_id").agg(count("*").as("f_cnt"))
x.show()
+---------------+-----+
|superior_emp_id|f_cnt|
+---------------+-----+
|             -1|    1|
|              1|    2|
|              2|    3|
+---------------+-----+

// join 后的结果不应该为空
empDF.join(x, empDF("emp_id") === x("superior_emp_id")).show()
+------+----+---------------+-----------+-----------+------+------+---------------+-----+
|emp_id|name|superior_emp_id|year_joined|emp_dept_id|gender|salary|superior_emp_id|f_cnt|
+------+----+---------------+-----------+-----------+------+------+---------------+-----+
+------+----+---------------+-----------+-----------+------+------+---------------+-----+
```

有多种方式可以解决这个问题：

- 使用 SQL 表达式

```scala
empDF.createOrReplaceTempView("empDF")
x.createOrReplaceTempView("x")

val sql = """
select * 
from empDF join x 
on empDF.emp_id = x.superior_emp_id
"""
spark.sql(sql).show()
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|emp_id|dept_name|superior_emp_id|year_joined|dept_id|gender|salary|superior_emp_id|f_cnt|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|     1|    Smith|             -1|       2018|     10|     M|  3000|              1|    2|
|     2|     Rose|              1|       2010|     20|     M|  4000|              2|    3|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
```

- 为 DataFrame 起别名

```scala
empDF.as("a").join(x.as("b"), col("a.emp_id") === col("b.superior_emp_id")).show()
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|emp_id|dept_name|superior_emp_id|year_joined|dept_id|gender|salary|superior_emp_id|f_cnt|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|     1|    Smith|             -1|       2018|     10|     M|  3000|              1|    2|
|     2|     Rose|              1|       2010|     20|     M|  4000|              2|    3|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
```

- `withColumn` 重命名列

```scala
val x = empDF.groupBy("superior_emp_id").agg(count("*").as("f_cnt"))
    .withColumnRenamed("superior_emp_id", "superior_emp_id")
empDF.join(x, empDF("emp_id") === x("superior_emp_id")).show()
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|emp_id|dept_name|superior_emp_id|year_joined|dept_id|gender|salary|superior_emp_id|f_cnt|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+
|     1|    Smith|             -1|       2018|     10|     M|  3000|              1|    2|
|     2|     Rose|              1|       2010|     20|     M|  4000|              2|    3|
+------+---------+---------------+-----------+-------+------+------+---------------+-----+

val x = empDF.groupBy("superior_emp_id").agg(count("*").as("f_cnt"))
    .withColumn("superior_emp_id", col("superior_emp_id"))
empDF.join(x, empDF("emp_id") === x("superior_emp_id")).show()
+------+-----+---------------+-----------+-----------+------+------+---------------+-----+
|emp_id| name|superior_emp_id|year_joined|emp_dept_id|gender|salary|superior_emp_id|f_cnt|
+------+-----+---------------+-----------+-----------+------+------+---------------+-----+
|     1|Smith|             -1|       2018|         10|     M|  3000|              1|    2|
|     2| Rose|              1|       2010|         20|     M|  4000|              2|    3|
+------+-----+---------------+-----------+-----------+------+------+---------------+-----+
```

- `toDF` 重新定义其中一个 DataFrame 的 Schema：

```scala
x = x.toDF(x.columns:_*)
empDF.join(x, empDF("emp_id") === x("superior_emp_id")).show()
+------+-----+---------------+-----------+-----------+------+------+---------------+-----+
|emp_id| name|superior_emp_id|year_joined|emp_dept_id|gender|salary|superior_emp_id|f_cnt|
+------+-----+---------------+-----------+-----------+------+------+---------------+-----+
|     1|Smith|             -1|       2018|         10|     M|  3000|              1|    2|
|     2| Rose|              1|       2010|         20|     M|  4000|              2|    3|
```

##### usingColumn 陷阱
`usingColumn` 语法得到的结果 DataFrame 中会自动去除被 join DataFrame 的关联键，只保留主调 DataFrame 中的关联键，所以不能通过 `select` 或 `expr` 选择被调 DataFrame 中的关联键，但是却可以在 `filter` 中引用被调 DataFrame 中的关联键：

```scala
val x = deptDF.limit(2).select("dept_id").toDF("dept_id")
x.show()
+-------+
|dept_id|
+-------+
|     10|
|     20|
+-------+

val res = deptDF.join(x, Seq("dept_id"), "left")
res.show()
res.printSchema
+-------+---------+
|dept_id|dept_name|
+-------+---------+
|     10|  Finance|
|     20|Marketing|
|     30|    Sales|
|     40|       IT|
+-------+---------+

res.filter(x("dept_id").isNull).show()
+-------+---------+
|dept_id|dept_name|
+-------+---------+
|     30|    Sales|
|     40|       IT|
+-------+---------+

res.select(expr("x.dept_id")).show()
org.apache.spark.sql.AnalysisException: cannot resolve '`x.dept_id`' given input columns: [dept_id, dept_name]; line 1 pos 0;
'Project ['x.dept_id]
+- Project [dept_id#456, dept_name#455]
   +- Join LeftOuter, (dept_id#456 = dept_id#497)

res.select(x("dept_id")).show()
org.apache.spark.sql.AnalysisException: Cannot resolve column name "dept_id" among (superior_emp_id, f_cnt);
  at org.apache.spark.sql.Dataset$$anonfun$resolve$1.apply(Dataset.scala:223)
  at org.apache.spark.sql.Dataset$$anonfun$resolve$1.apply(Dataset.scala:223)
```

##### 处理 join 中的同名字段
如果参与 join 的两个 DataFrame 之间存在相同名称的字段，很容易在后续的转换操作中出现 `Reference is ambiguous` 的错误，整体上有两种解决思路：

1. 如果需要的字段少：那就 select 你所需要的字段就行了；
2. 如果需要的字段多：那就 drop 不需要的字段；

在 join 前中后又可以有不同的处理方式：

1. join 前：修改/删除其中一方 DataFrame 的同名字段名；
2. join 中：如果同名字段是 join 的关联键，使用 `usingColumn` 语法，join 后只会保留左表关联字段；
3. join 后：
    1. 要么通过 `select(Expr)` 明确指定需要的表字段；
    2. 要么通过 `drop` 删除不需要的表字段；
    3. 要么通过 `withColumn` 添加新的字段，此时 `withColumn` 如果用于修改已有同名字段的内容，将会同时修改所有同名字段，修改后的结果仍会保留同名字段；  

示例：

```scala
// 示例数据
val emp = Seq((1,"Smith",-1,"2018","10","M",3000),
    (2,"Rose",1,"2010","20","M",4000),
    (3,"Williams",1,"2010","10","M",1000),
    (4,"Jones",2,"2005","10","F",2000),
    (5,"Brown",2,"2010","40","",-1),
      (6,"Brown",2,"2010","50","",-1)
  )
val empColumns = Seq("emp_id","dept_name","superior_emp_id","year_joined",
   "dept_id","gender","salary")
import spark.sqlContext.implicits._
val empDF = emp.toDF(empColumns:_*)
empDF.show(false)

+------+---------+---------------+-----------+-------+------+------+
|emp_id|dept_name|superior_emp_id|year_joined|dept_id|gender|salary|
+------+---------+---------------+-----------+-------+------+------+
|1     |Smith    |-1             |2018       |10     |M     |3000  |
|2     |Rose     |1              |2010       |20     |M     |4000  |
|3     |Williams |1              |2010       |10     |M     |1000  |
|4     |Jones    |2              |2005       |10     |F     |2000  |
|5     |Brown    |2              |2010       |40     |      |-1    |
|6     |Brown    |2              |2010       |50     |      |-1    |
+------+---------+---------------+-----------+-------+------+------+

val dept = Seq(("Finance",10),
("Marketing",20),
("Sales",30),
("IT",40)
)

val deptColumns = Seq("dept_name","dept_id")
val deptDF = dept.toDF(deptColumns:_*)
deptDF.show(false)

+---------+-------+
|dept_name|dept_id|
+---------+-------+
|Finance  |10     |
|Marketing|20     |
|Sales    |30     |
|IT       |40     |
+---------+-------+

// usingColumn 会去掉右侧 DataFrame 的关联键，这里使用 deptDF("*") 会报无法找到 dept_id 的错误
res.select(deptDF("*")).show()
org.apache.spark.sql.AnalysisException: Resolved attribute(s) dept_id#477 missing from emp_id#435,salary#441,year_joined#438,gender#440,dept_name#436,dept_id#439,dept_name#476,superior_emp_id#437 in operator !Project [dept_name#476, dept_id#477]. Attribute(s) with the same name appear in the operation: dept_id. Please check if the right attribute(s) are used.;;

// 选择 empDF 中所有字段，以及 deptDF 中的 dept_name 字段
res.select(empDF("*"), deptDF("dept_name")).show()
+------+---------+---------------+-----------+-------+------+------+---------+
|emp_id|dept_name|superior_emp_id|year_joined|dept_id|gender|salary|dept_name|
+------+---------+---------------+-----------+-------+------+------+---------+
|     1|    Smith|             -1|       2018|     10|     M|  3000|  Finance|
|     2|     Rose|              1|       2010|     20|     M|  4000|Marketing|
|     3| Williams|              1|       2010|     10|     M|  1000|  Finance|
|     4|    Jones|              2|       2005|     10|     F|  2000|  Finance|
|     5|    Brown|              2|       2010|     40|      |    -1|       IT|
+------+---------+---------------+-----------+-------+------+------+---------+

// 上面结果包含了同名字段 dept_name，如果直接引用字段名则会报 ambiguous 错误
res.select(empDF("*"), deptDF("dept_name")).select("dept_name").show()
org.apache.spark.sql.AnalysisException: Reference 'dept_name' is ambiguous, could be: dept_name, dept_name.;

// 想通过先删除左表的 dept_name 再选择左表中所有字段，但 empDF("*") 仍然会包含已经删掉的字段
res.drop(empDF("dept_name")).select(empDF("*"), deptDF("dept_name")).show()
org.apache.spark.sql.AnalysisException: Resolved attribute(s) dept_name#436 missing from

// 其实只要先 select 再 drop 就可以了，但是这种方法有很大局限，一个是当用列对象参数时， drop(column) 只能删除一列，而且这一列还必须已存在，当用列名时，drop 又会把所有同名的列删除掉
res.select(empDF("*"), deptDF("dept_name")).drop(empDF("dept_name"))
.select("dept_name")
.show()
+---------+
|dept_name|
+---------+
|  Finance|
|Marketing|
|  Finance|
|  Finance|
|       IT|
+---------+

// 值得说明的是 withColumn 并不会消除同名字段的分歧，只会同时改变同名字段的值
res.withColumn("dept_name", lit(1)).show()
+-------+------+---------+---------------+-----------+------+------+---------+
|dept_id|emp_id|dept_name|superior_emp_id|year_joined|gender|salary|dept_name|
+-------+------+---------+---------------+-----------+------+------+---------+
|     10|     1|        1|             -1|       2018|     M|  3000|        1|
|     20|     2|        1|              1|       2010|     M|  4000|        1|
|     10|     3|        1|              1|       2010|     M|  1000|        1|
|     10|     4|        1|              2|       2005|     F|  2000|        1|
|     40|     5|        1|              2|       2010|      |    -1|        1|
+-------+------+---------+---------------+-----------+------+------+---------+

// 综上，比较好的做法是在join前 drop 掉最后不需要的列（如果需要对其 select("*")的话）
val res = empDF.drop("dept_name").as("a").join(deptDF.as("b"), Seq("dept_id"))
res.show()
+-------+------+---------------+-----------+------+------+---------+
|dept_id|emp_id|superior_emp_id|year_joined|gender|salary|dept_name|
+-------+------+---------------+-----------+------+------+---------+
|     10|     1|             -1|       2018|     M|  3000|  Finance|
|     20|     2|              1|       2010|     M|  4000|Marketing|
|     10|     3|              1|       2010|     M|  1000|  Finance|
|     10|     4|              2|       2005|     F|  2000|  Finance|
|     40|     5|              2|       2010|      |    -1|       IT|
+-------+------+---------------+-----------+------+------+---------+

res.select("a.*", "b.dept_name").show()
+-------+------+---------------+-----------+------+------+---------+
|dept_id|emp_id|superior_emp_id|year_joined|gender|salary|dept_name|
+-------+------+---------------+-----------+------+------+---------+
|     10|     1|             -1|       2018|     M|  3000|  Finance|
|     20|     2|              1|       2010|     M|  4000|Marketing|
|     10|     3|              1|       2010|     M|  1000|  Finance|
|     10|     4|              2|       2005|     F|  2000|  Finance|
|     40|     5|              2|       2010|      |    -1|       IT|
+-------+------+---------------+-----------+------+------+---------+

res.selectExpr("a.*", "b.dept_name as f_new_name").show()
+-------+------+---------------+-----------+------+------+----------+
|dept_id|emp_id|superior_emp_id|year_joined|gender|salary|f_new_name|
+-------+------+---------------+-----------+------+------+----------+
|     10|     1|             -1|       2018|     M|  3000|   Finance|
|     20|     2|              1|       2010|     M|  4000| Marketing|
|     10|     3|              1|       2010|     M|  1000|   Finance|
|     10|     4|              2|       2005|     F|  2000|   Finance|
|     40|     5|              2|       2010|      |    -1|        IT|
+-------+------+---------------+-----------+------+------+----------+
```

##### join 最佳实践
DataFrame API 的 JOIN 操作有诸多需要注意的地方，除了正确使用 JOIN 类型和 JOIN 语法外，经常引起困惑的地方在于如何从 JOIN 结果中选择我们需要的字段，对此，我们总结了一些最佳实践：

1. 当 DataFrame 不方便通过一个变量来引用时，可以在 JOIN 语句中为 DataFrame 起别名：
    1. 可以通过 `"表别名.字段名"` 来引用对应字段；
    2. 如果不存在同名字段，也可以省略掉表别名，直接用 `"字段名"` 来应用对应字段；
2. 当 JOIN 的两个 DataFrame 中包含同名字段时：
    1. 可以在 JOIN 前删除/重命名无用的同名字段；
    2. 如果同名字段作为关联字段，`usingColumn` 语法将只会保留左表关联字段；
    3. 可以在 JOIN 后 `select(Expr)` 需要的字段，`drop` 不需要的字段，`withColumn` 添加新的字段；
3. 同源 DataFrame 之间 JOIN，在 JOIN 前通过 `toDF()` 转化其中一个 DataFrame；

看过上面的示例，你可能会觉得 DataFrame 的 JOIN 太不方便了，还不如直接写 SQL 表达式呢！事实上，DataFrame API 更加紧凑，更便于编写结构化代码，能够帮助我们完成大部分的语法检查，如果要在 DataFrame 中穿插 SQL 表达式，就使用 expr() 或 selectExpr() 函数吧！

#### repartition —— 重分区
- 功能：repartition 会导致数据的完全随机洗牌（shuffle），这意味着通常仅应在将来的分区数大于当前的分区数时或在按一组列进行分区时重新分区；如果经常要按照某个列进行过滤，则值得按该列重新分区；
- 语法：

```scala
// 指定所需的分区数
repartition(numPartitions: Int)
// 指定按照某列进行分区
repartition(partitionExprs: Column*)
repartition(numPartitions: Int, partitionExprs: Column*)
```

- 示例：

```
df.repartition(3)
df.repartition(col("dob"))
df.repartition(5, col("dob"))
```

#### coalesce —— 分区合并
- 功能：coalesce 不会引起 full shuffle，并尝试合并分区（将来的分区数小于当前的分区数）；
- 语法：

```scala
coalesce(numPartitions: Int)
```

- 示例：

```scala
df.repartition(5, col("dob")).coalesce(2)
```

#### cache | persist —— 缓存
- 功能：虽然 Spark 提供的计算速度是传统 Map Reduce 作业的 100 倍，但是如果您没有将作业设计为重用重复计算，那么当您处理数十亿或数万亿数据时，性能会下降。使用 cache() 和 persist() 方法，每个节点将其分区的数据存储在内存/磁盘中，并在该数据集的其他操作中重用它们，真正缓存是在第一次被相关 action 调用后才缓存。Spark 在节点上的持久数据是容错的，这意味着如果数据集的任何分区丢失，它将使用创建它的原始转换自动重新计算。Spark 会自动监视您进行的每个 persist（）和cache（）调用，并检查每个节点上的使用情况，如果不再使用或通过 least-recently-used (LRU) 算法，删除持久化数据，也可以使用 unpersist（）方法手动删除。unpersist（）将数据集标记为非持久性，并立即从内存和磁盘中删除它的所有块。

- 语法:

```scala
// StorageLevel 
1) persist() : Dataset.this.type
2) persist(newLevel : org.apache.spark.storage.StorageLevel) : Dataset.this.type

// cache() 调用的也是 persist()，df.cache() 的默认存储级别为 MEMORY_AND_DISK，而RDD.chache() 的默认存储级别为 MEMORY_ONLY
def cache(): this.type = persist()

// 手动取消持久化
unpersist() : Dataset.this.type
unpersist(blocking : scala.Boolean) : Dataset.this.type
```

- 示例:

```scala
// cache
val df = spark.read.options(Map("inferSchema"->"true","delimiter"->",","header"->"true")).csv("src/main/resources/zipcodes.csv")
  
val df2 = df.where(col("State") === "PR").cache()
df2.show(false)
println(df2.count())
val df3 = df2.where(col("Zipcode") === 704)
println(df2.count())

// persist
val dfPersist = df.persist(StorageLevel.MEMORY_ONLY)
dfPersist.show(false)
// unpersist
val dfPersist = dfPersist.unpersist()
```

- StorageLevel 有以下几个级别：

| 级别                        |使用空间|CPU时间|是否内存|是否磁盘| 备注                 |
|---------------------------|------|-------|--------|--------|--------------------|
| MEMORY\_ONLY              | 高    | 低     | 是      | 否      | -                   |
| MEMORY\_ONLY\_2           | 高    | 低     | 是      | 否      | 数据存2份              |
| MEMORY\_ONLY\_SER\_2      | 低    | 高     | 是      | 否      | 数据序列化，数据存2份        |
| MEMORY\_AND\_DISK         | 高    | 中等    | 部分     | 部分     | 内存放不下，则溢写到磁盘 |
| MEMORY\_AND\_DISK\_2      | 高    | 中等    | 部分     | 部分     | 数据存2份              |
| MEMORY\_AND\_DISK\_SER    | 低    | 高     | 部分     | 部分     | -                   |
| MEMORY\_AND\_DISK\_SER\_2 | 低    | 高     | 部分     | 部分     | 数据存2份              |
| DISK\_ONLY                | 低    | 高     | 否      | 是      |                    |
| DISK\_ONLY\_2             | 低    | 高     | 否      | 是      | 数据存2份              |
| NONE                      | -     | -      | -       | -       | -                   |
| OFF\_HEAP                 | -     | -      | -       | -       | -                   |

#### collect —— 收集到 driver
- 功能：collect() 和 collectAsList() 用于将 RDD/DataFrame/Dataset 中所有的数据拉取到 Driver 节点，然后你可以在 driver 节点使用 scala 进行进一步处理，通常用于较小的数据集，如果数据集过大可能会导致内存不足，很容易使 driver 节点崩溃并时区应用程序的状态，这也很昂贵，因为是逐条处理，而不是并行计算。

- 语法：

```scala
collect() : scala.Array[T]
collectAsList() : java.util.List[T]
```

- 示例：

```scala
df.show()
+---------------------+-----+------+------+
|name                 |id   |gender|salary|
+---------------------+-----+------+------+
|[James , , Smith]    |36636|M     |3000  |
|[Michael , Rose, ]   |40288|M     |4000  |
|[Robert , , Williams]|42114|M     |4000  |
|[Maria , Anne, Jones]|39192|F     |4000  |
|[Jen, Mary, Brown]   |     |F     |-1    |
+---------------------+-----+------+------+

val colList = df.collectAsList()
val colData = df.collect()
colData.foreach(row => {
    val salary = row.getInt(3)
    val fullName:Row = row.getStruct(0) 
    val firstName = fullName.getString(0)
    val middleName = fullName.get(1).toString
    val lastName = fullName.getAs[String]("lastname")
    println(firstName+","+middleName+","+lastName+","+salary)
  })

James ,,Smith,3000
Michael ,Rose,,4000
Robert ,,Williams,4000
Maria ,Anne,Jones,4000
Jen,Mary,Brown,-1
```

### 其他操作
#### when —— 条件判断
- 功能：`when otherwise` 类似于 SQL 中的 case when 语句；
- 语法：可以由多个 when 表达式（不满足前一个 when 条件则继续匹配下一个 when 条件），也可以不带 otherwise 表达式（不满足 when 条件则返回 null）；

```scala
when(condition: Column, value: Any): Column
otherwise(value: Any): Column
```

- 示例：

```scala
df.withColumn("new_gender", when(col("gender") === "M", "Male")).show()
+--------------------+-----+------+------+----------+
|                name|  dob|gender|salary|new_gender|
+--------------------+-----+------+------+----------+
|   [James , , Smith]|36636|     M|  3000|      Male|
|  [Michael , Rose, ]|40288|     M|  4000|      Male|
|[Robert , , Willi...|42114|     M|  4000|      Male|
|[Maria , Anne, Jo...|39192|     F|  4000|      null|
|  [Jen, Mary, Brown]|     |     F|    -1|      null|
+--------------------+-----+------+------+----------+

df.withColumn("new_gender", when(col("gender") === "M", "Male").otherwise("Unknown")).show()
+--------------------+-----+------+------+----------+
|                name|  dob|gender|salary|new_gender|
+--------------------+-----+------+------+----------+
|   [James , , Smith]|36636|     M|  3000|      Male|
|  [Michael , Rose, ]|40288|     M|  4000|      Male|
|[Robert , , Willi...|42114|     M|  4000|      Male|
|[Maria , Anne, Jo...|39192|     F|  4000|   Unknown|
|  [Jen, Mary, Brown]|     |     F|    -1|   Unknown|
+--------------------+-----+------+------+----------+
df.withColumn("new_gender", 
       when(col("gender") === "M", "Male")
      .when(col("gender") === "F", "Female")
      .otherwise("Unknown"))
+--------------------+-----+------+------+----------+
|                name|  dob|gender|salary|new_gender|
+--------------------+-----+------+------+----------+
|   [James , , Smith]|36636|     M|  3000|      Male|
|  [Michael , Rose, ]|40288|     M|  4000|      Male|
|[Robert , , Willi...|42114|     M|  4000|      Male|
|[Maria , Anne, Jo...|39192|     F|  4000|    Female|
|  [Jen, Mary, Brown]|     |     F|    -1|    Female|
+--------------------+-----+------+------+----------+
```

#### flatten —— 列拆多列
- 功能：在 Spark SQL 中，扁平化 DataFrame 的嵌套结构列对于一级嵌套很简单，而对于多级嵌套和存在数百个列的情况下则很复杂。

- 扁平化嵌套 struct: 如果哦列数有限，可以通过引用列名似乎很容易解决，但是请想象一下，如果您有100多个列并在一个select中引用所有列，那么会很麻烦。可以通过创建一个递归函数 flattenStructSchema（）轻松地将数百个嵌套级别列展平。

```scala
val structureData = Seq(
    Row(Row("James ","","Smith"),Row(Row("CA","Los Angles"),Row("CA","Sandiago"))),
    Row(Row("Michael ","Rose",""),Row(Row("NY","New York"),Row("NJ","Newark"))),
    Row(Row("Robert ","","Williams"),Row(Row("DE","Newark"),Row("CA","Las Vegas"))),
    Row(Row("Maria ","Anne","Jones"),Row(Row("PA","Harrisburg"),Row("CA","Sandiago"))),
    Row(Row("Jen","Mary","Brown"),Row(Row("CA","Los Angles"),Row("NJ","Newark")))
  )

val structureSchema = new StructType()
    .add("name",new StructType()
      .add("firstname",StringType)
      .add("middlename",StringType)
      .add("lastname",StringType))
    .add("address",new StructType()
      .add("current",new StructType()
        .add("state",StringType)
        .add("city",StringType))
      .add("previous",new StructType()
        .add("state",StringType)
        .add("city",StringType)))

val df = spark.createDataFrame(
    spark.sparkContext.parallelize(structureData),structureSchema)
df.printSchema()

root
 |-- name: struct (nullable = true)
 |    |-- firstname: string (nullable = true)
 |    |-- middlename: string (nullable = true)
 |    |-- lastname: string (nullable = true)
 |-- address: struct (nullable = true)
 |    |-- current: struct (nullable = true)
 |    |    |-- state: string (nullable = true)
 |    |    |-- city: string (nullable = true)
 |    |-- previous: struct (nullable = true)
 |    |    |-- state: string (nullable = true)
 |    |    |-- city: string (nullable = true)
 
df.show(false)
+---------------------+----------------------------------+
|name                 |address                           |
+---------------------+----------------------------------+
|[James , , Smith]    |[[CA, Los Angles], [CA, Sandiago]]|
|[Michael , Rose, ]   |[[NY, New York], [NJ, Newark]]    |
|[Robert , , Williams]|[[DE, Newark], [CA, Las Vegas]]   |
|[Maria , Anne, Jones]|[[PA, Harrisburg], [CA, Sandiago]]|
|[Jen, Mary, Brown]   |[[CA, Los Angles], [NJ, Newark]]  |
+---------------------+----------------------------------+

// 可以通过使用点符号（parentColumn.childColumn）来引用嵌套结构列，一种将嵌套结构打平的简单方法如下:
val df2 = df.select(col("name.*"),
    col("address.current.*"),
    col("address.previous.*"))
val df2Flatten = df2.toDF("fname","mename","lname","currAddState",
    "currAddCity","prevAddState","prevAddCity")
df2Flatten.printSchema()
df2Flatten.show(false)

root
 |-- name_firstname: string (nullable = true)
 |-- name_middlename: string (nullable = true)
 |-- name_lastname: string (nullable = true)
 |-- address_current_state: string (nullable = true)
 |-- address_current_city: string (nullable = true)
 |-- address_previous_state: string (nullable = true)
 |-- address_previous_city: string (nullable = true)

+--------+------+--------+------------+-----------+------------+-----------+
|fname   |mename|lname   |currAddState|currAddCity|prevAddState|prevAddCity|
+--------+------+--------+------------+-----------+------------+-----------+
|James   |      |Smith   |CA          |Los Angles |CA          |Sandiago   |
|Michael |Rose  |        |NY          |New York   |NJ          |Newark     |
|Robert  |      |Williams|DE          |Newark     |CA          |Las Vegas  |
|Maria   |Anne  |Jones   |PA          |Harrisburg |CA          |Sandiago   |
|Jen     |Mary  |Brown   |CA          |Los Angles |NJ          |Newark     |
+--------+------+--------+------------+-----------+------------+-----------+

def flattenStructSchema(schema: StructType, prefix: String = null) : Array[Column] = {
    schema.fields.flatMap(f => {
      val columnName = if (prefix == null) f.name else (prefix + "." + f.name)

      f.dataType match {
        case st: StructType => flattenStructSchema(st, columnName)
        case _ => Array(col(columnName).as(columnName.replace(".","_")))
      }
    })
  }
  
val df3 = df.select(flattenStructSchema(df.schema):_*)
df3.printSchema()
df3.show(false)

+--------------+---------------+-------------+---------------------+--------------------+----------------------+---------------------+
|name.firstname|name.middlename|name.lastname|address.current.state|address.current.city|address.previous.state|address.previous.city|
+--------------+---------------+-------------+---------------------+--------------------+----------------------+---------------------+
|James         |               |Smith        |CA                   |Los Angles          |CA                    |Sandiago             |
|Michael       |Rose           |             |NY                   |New York            |NJ                    |Newark               |
|Robert        |               |Williams     |DE                   |Newark              |CA                    |Las Vegas            |
|Maria         |Anne           |Jones        |PA                   |Harrisburg          |CA                    |Sandiago             |
|Jen           |Mary           |Brown        |CA                   |Los Angles          |NJ                    |Newark               |
+--------------+---------------+-------------+---------------------+--------------------+----------------------+---------------------+
```
- 扁平化嵌套 Array: 上个示例展示了如何打平嵌套 Row，对于嵌套 Array 则可以通过 flatten() 方法除去嵌套数组第一层嵌套。

```scala
val arrayArrayData = Seq(
    Row("James",List(List("Java","Scala","C++"),List("Spark","Java"))),
    Row("Michael",List(List("Spark","Java","C++"),List("Spark","Java"))),
    Row("Robert",List(List("CSharp","VB"),List("Spark","Python")))
  )

val arrayArraySchema = new StructType().add("name",StringType)
    .add("subjects",ArrayType(ArrayType(StringType)))

val df = spark.createDataFrame(
     spark.sparkContext.parallelize(arrayArrayData),arrayArraySchema)
df.printSchema()
df.show()

root
 |-- name: string (nullable = true)
 |-- subjects: array (nullable = true)
 |    |-- element: array (containsNull = true)
 |    |    |-- element: string (containsNull = true)


+-------+-----------------------------------+
|name   |subjects                           |
+-------+-----------------------------------+
|James  |[[Java, Scala, C++], [Spark, Java]]|
|Michael|[[Spark, Java, C++], [Spark, Java]]|
|Robert |[[CSharp, VB], [Spark, Python]]    |
+-------+-----------------------------------+

df.select($"name",flatten($"subjects")).show(false)
+-------+-------------------------------+
|name   |flatten(subjects)              |
+-------+-------------------------------+
|James  |[Java, Scala, C++, Spark, Java]|
|Michael|[Spark, Java, C++, Spark, Java]|
|Robert |[CSharp, VB, Spark, Python]    |
+-------+-------------------------------+
```

#### explode —— 行拆多行
- 功能：在处理 JSON，Parquet，Avro 和 XML 等结构化文件时，我们通常需要从数组、列表和字典等集合中获取数据。在这种情况下，explode 函数（explode，explorer_outer，posexplode，posexplode_outer）对于将集合列转换为行以便有效地在 Spark 中进行处理很有用。
- 语法：

- 示例：

```scala
// 示例数据
import spark.implicits._

val arrayData = Seq(
    Row("James",List("Java","Scala"),Map("hair"->"black","eye"->"brown")),
    Row("Michael",List("Spark","Java",null),Map("hair"->"brown","eye"->null)),
    Row("Robert",List("CSharp",""),Map("hair"->"red","eye"->"")),
    Row("Washington",null,null),
    Row("Jefferson",List(),Map())
)

val arraySchema = new StructType()
    .add("name",StringType)
    .add("knownLanguages", ArrayType(StringType))
    .add("properties", MapType(StringType,StringType))

val df = spark.createDataFrame(spark.sparkContext.parallelize(arrayData),arraySchema)
df.printSchema()
df.show(false)

root
 |-- name: string (nullable = true)
 |-- knownLanguages: array (nullable = true)
 |    |-- element: string (containsNull = true)
 |-- properties: map (nullable = true)
 |    |-- key: string
 |    |-- value: string (valueContainsNull = true)

+----------+--------------+-----------------------------+
|name      |knownLanguages|properties                   |
+----------+--------------+-----------------------------+
|James     |[Java, Scala] |[hair -> black, eye -> brown]|
|Michael   |[Spark, Java,]|[hair -> brown, eye ->]      |
|Robert    |[CSharp, ]    |[hair -> red, eye -> ]       |
|Washington|null          |null                         |
|Jefferson |[]            |[]                           |
+----------+--------------+-----------------------------+

// 将数组爆炸成行，爆炸后的列名默认为 "col"，如果数组为 null 或空则会被跳过，值为null则会返回 null
df.select($"name",explode($"knownLanguages")).show(false)
+-------+------+
|name   |col   |
+-------+------+
|James  |Java  |
|James  |Scala |
|Michael|Spark |
|Michael|Java  |
|Michael|null  |
|Robert |CSharp|
|Robert |      |
+-------+------+

// 将字典爆炸成行，爆炸后键列默认列名为 "key"，值列默认为 "value"
df.select($"name",explode($"properties")).show(false)
+-------+----+-----+
|name   |key |value|
+-------+----+-----+
|James  |hair|black|
|James  |eye |brown|
|Michael|hair|brown|
|Michael|eye |null |
|Robert |hair|red  |
|Robert |eye |     |
+-------+----+-----+

// explode_outer 遇到 null 或空的数组、字典将返回 null
df.select($"name",explode_outer($"knownLanguages")).show(false)
+----------+------+
|name      |col   |
+----------+------+
|James     |Java  |
|James     |Scala |
|Michael   |Spark |
|Michael   |Java  |
|Michael   |null  |
|Robert    |CSharp|
|Robert    |      |
|Washington|null  |
|Jeferson  |null  |
+----------+------+

df.select($"name",explode_outer($"properties")).show(false)
+----------+----+-----+
|name      |key |value|
+----------+----+-----+
|James     |hair|black|
|James     |eye |brown|
|Michael   |hair|brown|
|Michael   |eye |null |
|Robert    |hair|red  |
|Robert    |eye |     |
|Washington|null|null |
|Jeferson  |null|null |
+----------+----+-----+

// posexplode 会在 explode 基础上添加位置列 "pos"
df.select($"name",posexplode($"knownLanguages")).show(false)
+-------+---+------+
|name   |pos|col   |
+-------+---+------+
|James  |0  |Java  |
|James  |1  |Scala |
|Michael|0  |Spark |
|Michael|1  |Java  |
|Michael|2  |null  |
|Robert |0  |CSharp|
|Robert |1  |      |
+-------+---+------+

df.select($"name",posexplode($"properties")).show(false)
+-------+---+----+-----+
|name   |pos|key |value|
+-------+---+----+-----+
|James  |0  |hair|black|
|James  |1  |eye |brown|
|Michael|0  |hair|brown|
|Michael|1  |eye |null |
|Robert |0  |hair|red  |
|Robert |1  |eye |     |
+-------+---+----+-----+

// posexplode_outer 会在 explode_outer 的基础上添加位置列 "pos"
df.select($"name",posexplode_outer($"knownLanguages")).show(false)
+----------+----+------+
|name      |pos |col   |
+----------+----+------+
|James     |0   |Java  |
|James     |1   |Scala |
|Michael   |0   |Spark |
|Michael   |1   |Java  |
|Michael   |2   |null  |
|Robert    |0   |CSharp|
|Robert    |1   |      |
|Washington|null|null  |
|Jeferson  |null|null  |
+----------+----+------+

df.select($"name",posexplode_outer($"properties")).show(false)
+----------+----+----+-----+
|name      |pos |key |value|
+----------+----+----+-----+
|James     |0   |hair|black|
|James     |1   |eye |brown|
|Michael   |0   |hair|brown|
|Michael   |1   |eye |null |
|Robert    |0   |hair|red  |
|Robert    |1   |eye |     |
|Washington|null|null|null |
|Jeferson  |null|null|null |
+----------+----+----+-----+
```

#### pivot | stack —— 行转列 | 列转行
- 功能：
    - pivot() 是一种聚合方法（类似于 Excel 中的数据透视表），用于将 DataFrame/Dataset 的行转列，该过程可以被分为三个步骤，① 按 x 列分组，x 的不同取值作为行向标签 ② 将 y 列的不同取值作为列向标签 ③ 将行列标签 (x,y) 对应 z 的聚合结果作为值，如果源表没有 (x,y) 对应的数据则补 null；
    - stack() 方法可以将 DataFrame/Dataset 的列转行，注意 Spark 没有 unpivot 方法；

- 语法：

```scala
groupBy(x).pivot(y).sum(z)  // x 列不同值作为行标签，y 列不同值作为列标签，z 列的聚合作为值
stack(n, expr1, ..., exprk) // 会将 expr1, ..., exprk 折叠为 n 行
```

- 示例：

```scala
// 创建一个 DataFrame
val data = Seq(("Banana",1000,"USA"), ("Carrots",1500,"USA"), ("Beans",1600,"USA"),
      ("Orange",2000,"USA"),("Orange",2000,"USA"),("Banana",400,"China"),
      ("Carrots",1200,"China"),("Beans",1500,"China"),("Orange",4000,"China"),
      ("Banana",2000,"Canada"),("Carrots",2000,"Canada"),("Beans",2000,"Mexico"))

import spark.sqlContext.implicits._
val df = data.toDF("Product","Amount","Country")
df.show()

+-------+------+-------+
|Product|Amount|Country|
+-------+------+-------+
| Banana|  1000|    USA|
|Carrots|  1500|    USA|
|  Beans|  1600|    USA|
| Orange|  2000|    USA|
| Orange|  2000|    USA|
| Banana|   400|  China|
|Carrots|  1200|  China|
|  Beans|  1500|  China|
| Orange|  4000|  China|
| Banana|  2000| Canada|
|Carrots|  2000| Canada|
|  Beans|  2000| Mexico|
+-------+-----+-------+

// 行转列：不同 Product、不同 Country 下，Amount 的和
val pivotDF = df.groupBy("Product").pivot("Country").sum("Amount")
pivotDF.show()

+-------+------+-----+------+----+
|Product|Canada|China|Mexico| USA|
+-------+------+-----+------+----+
| Orange|  null| 4000|  null|4000|
|  Beans|  null| 1500|  2000|1600|
| Banana|  2000|  400|  null|1000|
|Carrots|  2000| 1200|  null|1500|
+-------+------+-----+------+----+

// pivot 是一个非常耗时的操作，Spark 2.0 以后的版本对 pivot 的性能进行了优化，如果使用的是更低的版本，可以通过传递一个列值参数来加速计算过程
val pivotDF = df.groupBy("Product").pivot("Country", Seq("USA","China")).sum("Amount")
pivotDF.show()

+-------+----+-----+
|Product| USA|China|
+-------+----+-----+
| Orange|4000| 4000|
|  Beans|1600| 1500|
| Banana|1000|  400|
|Carrots|1500| 1200|
+-------+----+-----+
```

```scala
// stack(n, 列1显示名, 列1, ..., 列n显示名, 列n)
val unPivotDF = pivotDF.select($"Product", expr("stack(2, 'USA', USA, 'China', China) as (Country,Total)"))
    .where("Total is not null")
unPivotDF.show()

+-------+-------+-----+
|Product|Country|Total|
+-------+-------+-----+
| Orange|    USA| 4000|
| Orange|  China| 4000|
|  Beans|    USA| 1600|
|  Beans|  China| 1500|
| Banana|    USA| 1000|
| Banana|  China|  400|
|Carrots|    USA| 1500|
|Carrots|  China| 1200|
+-------+-------+-----+
```

## 参考
- [《Spark 权威指南》](https://snaildove.github.io/2019/08/05/Chapter5_Basic-Structured-Operations(SparkTheDefinitiveGuide)_online/)
- [Spark 2.2.x 中文文档](https://spark-reference-doc-cn.readthedocs.io/zh_CN/latest/programming-guide/sql-guide.html)
- [Spark By Examples](https://sparkbyexamples.com/apache-spark-tutorial-with-scala-examples/)
- [org.apache.spark.sql.Dataset](https://spark.apache.org/docs/latest/api/scala/org/apache/spark/sql/Dataset.html)：Dataset 对象方法
- [org.apache.spark.sql.Dataset.Column](http://spark.apache.org/docs/latest/api/scala/org/apache/spark/sql/Column.html)：Column 对象方法