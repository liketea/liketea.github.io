---
title: Spark 指南：Spark SQL（五）—— SQL
date: 2020-11-11 18:51:22
tags: 
   - Spark
categories: 
   - Spark
---
![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/sparksql_iteblog.png)

SQL（Structured Query Language） 是一种领域特定语言，用于表达对数据的关系型操作。SQL 无处不在，即使技术专家预言了它的消亡，它还是许多企业所依赖的及其灵活的数据工具。Spark 实现了 ANSI SQL:2003 的一个子集，该标准是大多数 SQL 数据库中可用的标准。Spark SQL 旨在用作联机分析处理（OLAP）数据库，而不是联机事务处理（OLTP）数据库，这意味着它不打算执行极低延迟的查询，即使将来肯定会支持原地修改，但是目前还不支持。

## Spark SQL & Hive
Spark SQL 的前身是 Shark。为了给熟悉 RDBMS 但又不理解 MapReduce 的技术人员提供快速上手的工具，hive 应运而生，它是当时唯一运行在 Hadoop 上的 SQL-on-hadoop 工具。但是MapReduce 计算过程中大量的中间磁盘落地过程消耗了大量的 I/O，降低的运行效率，为了提高 SQL-on-Hadoop 的效率，Shark 应运而生，但又因为 Shark 对于 Hive 的太多依赖（如采用 Hive 的语法解析器、查询优化器等等)，2014 年 Spark 团队停止对 Shark 的开发，将所有资源放 Spark SQL 项目上。其中 Spark SQL 作为 Spark 生态的一员继续发展，而不再受限于 Hive，只是兼容 Hive；而 Hive on Spark 是一个 Hive 的发展计划，该计划将 Spark 作为 Hive 的底层引擎之一，也就是说，Hive 将不再受限于一个引擎，可以采用 Map-Reduce、Tez、Spark 等引擎。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/apache_hive_vs._spark__article.jpg)

## 执行 SQL
Spark 提供了几个接口来执行 SQL 查询：

- Spark SQL CLI：你可以使用 Spark SQL CLI 从命令行在本地模式下进行基本的 Spark SQL 查询， Spark SQL CLI 无法与 Thrift JDBC 服务器通信，要启动 Spark SQL CLI，请在 Spark 目录下运行以下命令

```zsh
./bin/spark-sql
```

- Spark 编程接口：你可以通过任意 Spark 语言 API 以临时方式执行 SQL，你可以通过 SparkSession 对象上的 sql 方法执行此操作，这将返回一个 DataFrame

```scala
spark.sql(sql_statement)
```

## Catalog
Catalog 是 Spark SQL 中最高级别的抽象，用于对数据库、表、视图、缓存、列、函数（UDF/UDAF）的元数据进行操作，其 API 可以在 `org.apache.spark.sql.catalog` 中查看。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20201111170644.png)

示例数据：

```scala
val data = Seq(
      Row("M", 3000, Row("James ","","Smith"), Seq(1,2), Map("1"->"a", "11"->"aa")),
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

获取 catalog 对象：

```scala
val c = spark.catalog
```

### 操作数据库
- API：

```scala
// 返回当前使用的数据库，相当于select database()
currentDatabase: String
// 设置当前使用的数据库，相当于use database_name;
setCurrentDatabase(dbName: String): Unit
// 查看所有数据库，相当于show databases;
listDatabases(): Dataset[Database]
// 获取某数据库的元数据，返回值是Database类型的，如果指定的数据库不存在则会@throws[AnalysisException]("database does not exist")
getDatabase(dbName: String): Database
// 判断某个数据库是否已经存在，返回boolean值
databaseExists(dbName: String): Boolean
```

- 示例：

```scala
c.listDatabases().show(false)
+-------+----------------+-----------------------------------------------+
|name   |description     |locationUri                                    |
+-------+----------------+-----------------------------------------------+
|default|default database|file:/Users/likewang/ilab/Spark/spark-warehouse|
+-------+----------------+-----------------------------------------------+

val d = c.getDatabase("default")
println(s"name:${d.name} path:${d.locationUri}")
name:default path:file:/Users/likewang/ilab/Spark/spark-warehouse

c.databaseExists("default")
res4: Boolean = true
```

### 操作表/视图
- API：

```scala
// 表/视图的属性
name：表的名字
database：表所属的数据库的名字
description：表的描述信息
tableType：用于区分是表还是视图，两个取值：table或view
isTemporary：是否是临时表或临时视图，解释一下啥是临时表，临时表就是使用 Dataset 或DataFrame 的 createOrReplaceTempView 等类似的 API 注册的视图或表，当此次 Spark 任务结束后这些表就没了，再次使用的话还要再进行注册，而非临时表就是在 Hive 中真实存在的，开启Hive支持就能够直接使用的，本次 Spark 任务结束后表仍然能存在，下次启动不需要重新做任何处理就能够使用，表是持久的，这种不是临时表

// 查看所有表或视图，相当于show tables
listTables(): Dataset[Table]
// 返回指定数据库下的表或视图，如果指定的数据库不存在则会抛出@throws[AnalysisException]("database does not exist")表示数据库不存在。
listTables(dbName: String): Dataset[Table]
// 获取表的元信息，不存在则会抛出异常
getTable(tableName: String): Table
getTable(dbName: String, tableName: String): Table
// 判断表或视图是否存在，返回boolean值
tableExists(tableName: String): Boolean
tableExists(dbName: String, tableName: String): Boolean
// 使用createOrReplaceTempView类似API注册的临时视图可以使用此方法删除，如果这个视图已经被缓存过的话会自动清除缓存
dropTempView(viewName: String): Boolean
dropGlobalTempView(viewName: String): Boolean
// 用于判断一个表否已经缓存过了
isCached(tableName: String): Boolean
// 用于缓存表
cacheTable(tableName: String): Unit
cacheTable(tableName: String, storageLevel: StorageLevel): Unit
// 对表取消缓存
uncacheTable(tableName: String): Unit
// 清空所有缓存
clearCache(): Unit
// Spark为了性能考虑，对表的元数据做了缓存，所以当被缓存的表已经改变时也必须刷新元数据重新缓存
refreshTable(tableName: String): Unit
refreshByPath(path: String): Unit
// 根据给定路径创建表，并返回相关的 DataFrame
createTable(tableName: String, path: String): DataFrame
createTable(tableName: String, path: String, source: String): DataFrame
createTable(tableName: String, source: String, options: java.util.Map[String, String]): DataFrame
createTable(tableName: String, source: String, options: Map[String, String]): DataFrame
createTable(tableName: String, source: String, schema: StructType, options: java.util.Map[String, String]): DataFrame
createTable(tableName: String, source: String, schema: StructType, options: Map[String, String]): DataFrame 
```

- 示例：

```scala
c.listTables("default").show()
+----+--------+-----------+---------+-----------+
|name|database|description|tableType|isTemporary|
+----+--------+-----------+---------+-----------+
+----+--------+-----------+---------+-----------+

df.createOrReplaceTempView("df")
c.listTables("default").show()
+----+--------+-----------+---------+-----------+
|name|database|description|tableType|isTemporary|
+----+--------+-----------+---------+-----------+
|  df|    null|       null|TEMPORARY|       true|
+----+--------+-----------+---------+-----------+

val t = c.getTable("df")
println(s"name:${t.name} tableType:${t.tableType} isTemporary:${t.isTemporary}")
name:df tableType:TEMPORARY isTemporary:true

c.tableExists("df")
res10: Boolean = true

c.isCached("df")
res11: Boolean = false

df.cache()
c.isCached("df")
res13: Boolean = true

c.uncacheTable("df")
c.isCached("df")
res14: Boolean = false

c.refreshTable("df")
```
### 函数相关
- API：

```scala
// 函数的属性
database：函数注册在哪个数据库下，函数是跟数据库绑定的
description：对函数的描述信息，可以理解成注释
className：函数其实就是一个class，调用函数就是调用类的方法，className表示函数对应的class的全路径类名
isTemporary：是否是临时函数

// 列出当前数据库下的所有函数，包括注册的临时函数
listFunctions(): Dataset[Function]
// 列出指定数据库下注册的所有函数，包括临时函数，如果指定的数据库不存在的话则会抛出@throws[AnalysisException]("database does not exist")表示数据库不存在
listFunctions(dbName: String): Dataset[Function]
// 获取函数的元信息，函数不存在则会抛出异常
getFunction(functionName: String): Function
getFunction(dbName: String, functionName: String): Function
// 判断函数是否存在，返回boolean值
functionExists(functionName: String): Boolean
functionExists(dbName: String, functionName: String): Boolean
```

- 示例：

```scala
c.listFunctions.show(10, false)
+----+--------+-----------+---------------------------------------------------------+-----------+
|name|database|description|className                                                |isTemporary|
+----+--------+-----------+---------------------------------------------------------+-----------+
|!   |null    |null       |org.apache.spark.sql.catalyst.expressions.Not            |true       |
|%   |null    |null       |org.apache.spark.sql.catalyst.expressions.Remainder      |true       |
|&   |null    |null       |org.apache.spark.sql.catalyst.expressions.BitwiseAnd     |true       |
|*   |null    |null       |org.apache.spark.sql.catalyst.expressions.Multiply       |true       |
|+   |null    |null       |org.apache.spark.sql.catalyst.expressions.Add            |true       |
|-   |null    |null       |org.apache.spark.sql.catalyst.expressions.Subtract       |true       |
|/   |null    |null       |org.apache.spark.sql.catalyst.expressions.Divide         |true       |
|<   |null    |null       |org.apache.spark.sql.catalyst.expressions.LessThan       |true       |
|<=  |null    |null       |org.apache.spark.sql.catalyst.expressions.LessThanOrEqual|true       |
|<=> |null    |null       |org.apache.spark.sql.catalyst.expressions.EqualNullSafe  |true       |
+----+--------+-----------+---------------------------------------------------------+-----------+

c.functionExists("!")
res21: Boolean = true

c.getFunction("!")
res22: org.apache.spark.sql.catalog.Function = Function[name='!', className='org.apache.spark.sql.catalyst.expressions.Not', isTemporary='true']
```

### 操作表/视图的列

- API：

```scala
// 列的属性
name：列的名字
description：列的描述信息，与注释差不多
dataType：列的数据类型
nullable：列是否允许为null
isPartition：是否是分区列
isBucket：是否是桶列
// 列出指定的表或视图有哪些列，表不存在则抛异常
listColumns(tableName: String): Dataset[Column]
listColumns(dbName: String, tableName: String): Dataset[Column]
```

- 示例：

```scala
c.listColumns("df").show()
+--------+-----------+--------------------+--------+-----------+--------+
|    name|description|            dataType|nullable|isPartition|isBucket|
+--------+-----------+--------------------+--------+-----------+--------+
|  gender|       null|              string|    true|      false|   false|
|  salary|       null|                 int|    true|      false|   false|
|f_struct|       null|struct<firstname:...|    true|      false|   false|
| f_array|       null|          array<int>|    true|      false|   false|
|   f_map|       null|  map<string,string>|    true|      false|   false|
+--------+-----------+--------------------+--------+-----------+--------+
```

## Tables
要用 Spark SQL 做任何有用的事情，首先要定义表，表在逻辑上等效于 DataFrame，因为他们是运行命令所依据的数据结构，我们可以对表进行关联、过滤、汇总等操作，表和 DataFame 之间的核心区别在于：在编程语言范围内定义 DataFrame，在数据库中定义表。

### 创建表
Spark 相当独特的功能是可以在 SQL 中重用整个数据源 API：

```scala
// 从数据源读取数据，创建表，定义了一个非托管表
val sql = """
CREATE TABLE if not exists flights(
	a string comment "name", 
	b int comment "level", 
	c int comment "age"
) using csv options (path 'job.csv')
"""
spark.sql(sql)

// 从查询创建表，定义了一个托管表，Spark 会为其跟踪所有相关信息
val sql = """
CREATE  TABLE if not exists df_copy
USING parquet AS SELECT * from df
"""
spark.sql(sql)

c.listTables().show()
+-------+--------+-----------+---------+-----------+
|   name|database|description|tableType|isTemporary|
+-------+--------+-----------+---------+-----------+
|df_copy| default|       null|  MANAGED|      false|
|flights| default|       null| EXTERNAL|      false|
|     df|    null|       null|TEMPORARY|       true|
+-------+--------+-----------+---------+-----------+

spark.sql("select * from df_copy").show()
+------+------+--------------------+-------+------------------+
|gender|salary|            f_struct|f_array|             f_map|
+------+------+--------------------+-------+------------------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|
+------+------+--------------------+-------+------------------+
```

### 插入表

```scala
val sql = """
insert into df_copy
SELECT * from df limit 3
"""
spark.sql(sql)

spark.sql("select * from flights").show()
+------+------+--------------------+-------+------------------+
|gender|salary|            f_struct|f_array|             f_map|
+------+------+--------------------+-------+------------------+
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|
|     F|  4000|[Maria , Anne, Jo...| [3, 3]|[4 -> d, 44 -> dd]|
|     F|    -1|  [Jen, Mary, Brown]| [5, 2]|          [5 -> e]|
|     M|  3000|   [James , , Smith]| [1, 2]|[1 -> a, 11 -> aa]|
+------+------+--------------------+-------+------------------+
```

### 描述表

```scala
spark.sql("describe df_copy").show()
+--------+--------------------+-------+
|col_name|           data_type|comment|
+--------+--------------------+-------+
|  gender|              string|   null|
|  salary|                 int|   null|
|f_struct|struct<firstname:...|   null|
| f_array|          array<int>|   null|
|   f_map|  map<string,string>|   null|
+--------+--------------------+-------+
```

### 刷新表
REFRESH TALE 刷新与该表的所有缓存条目（实质上是文件），如果该表先前已被缓存，则下次扫描时将被延迟缓存：

```scala
spark.sql("refresh table df_copy")
```

### 删除表
删除表会删除托管表中的数据，因此执行此操作时需要非常小心。

```scala
spark.sql("drop table if exists df_copy")
c.listTables().show()
+-------+--------+-----------+---------+-----------+
|   name|database|description|tableType|isTemporary|
+-------+--------+-----------+---------+-----------+
|flights| default|       null| EXTERNAL|      false|
|     df|    null|       null|TEMPORARY|       true|
+-------+--------+-----------+---------+-----------+
```

### 缓存表
和 DataFrame 一样，你可以缓存表或者取消缓存表:

```scala
spark.sql("uncache table flights")
c.isCached("flights")
res60: Boolean = false

spark.sql("cache table flights")
c.isCached("flights")
res59: Boolean = true
```

## Views
视图是保存的查询计划，可以方便地组织或重用查询逻辑。

### 创建视图
Spark 有几种不同的视图概念，视图可以是全局视图、数据库视图或会话视图：

```scala
// 常规/数据库视图：在所属数据库可见，不能基于视图再创建常规视图
val sql = """
create view view_f as 
select * from flights
"""
spark.sql(sql)

// 会话临时视图：仅在当前会话期间可用，且未注册到数据库
val sql = """
create temp view temp_view_f as 
select * from flights
"""
spark.sql(sql)

// 全局临时视图：仅在当前会话期间可用，无论用哪个数据库都可见
val sql = """
create global temp view global_temp_view_f as 
select * from flights
"""
spark.sql(sql)

// 覆盖临时视图：如果临时视图已存在则覆盖
val sql = """
create or replace temp view replace_temp_view_f as 
select * from flights
"""
spark.sql(sql)

// 视图会在表列表中列出
spark.sql("show tables").show()
+--------+-------------------+-----------+
|database|          tableName|isTemporary|
+--------+-------------------+-----------+
| default|            flights|      false|
| default|             view_f|      false|
|        |                 df|       true|
|        |replace_temp_view_f|       true|
|        |        temp_view_f|       true|
+--------+-------------------+-----------+
```
### 访问视图
定义好视图，就可以像访问表一样在 SQL 中访问视图了：

```scala
spark.sql("select * from replace_temp_view_f").show()
+------+---+---+
|     a|  b|  c|
+------+---+---+
|     a|  b|  c|
|caster|  0| 26|
|  like|  1| 30|
|   leo|  2| 30|
|rayray|  3| 27|
+------+---+---+
```

### 删除视图

```scala
spark.sql("drop view if exists replace_temp_view_f")
spark.sql("show tables").show()
+--------+-----------+-----------+
|database|  tableName|isTemporary|
+--------+-----------+-----------+
| default|    flights|      false|
| default|     view_f|      false|
|        |         df|       true|
|        |temp_view_f|       true|
+--------+-----------+-----------+
```

## Databases
数据库是用于组织表的工具，如果你没有定义数据库，Spark 将使用默认的数据库，在 Spark 中运行的所有 SQL 语句（包括 DataFrame 命令）都是在数据库的上下文中执行的，如果你更改数据库，则任何用户定义的表都将保留在先前的数据库中，并且要以其他方式查询。

```scala
// 创建数据库
spark.sql("create database if not exists some_db")
// 查看所有数据库
spark.sql("show databases").show()
+------------+
|databaseName|
+------------+
|     default|
|     some_db|
+------------+
// 切换数据库
spark.sql("use some_db")
spark.sql("show tables").show()
// 删除数据库
spark.sql("drop database if exists some_db")
spark.sql("show databases").show()
+------------+
|databaseName|
+------------+
|     default|
+------------+
```

## 查询语句
Spark 中的查询支持以下 ANSI SQL 要求（此处列出了 SELECT 表达式的布局）：

```sql
SELECT [ALL|DISTINCT] named_expression[, named_expression, ...]
FROM relation[, relation, ...][lateral_view[, lateral_view, ...]]
[WHERE boolean_expression]
[aggregation [HAVING boolean_expression]]
[ORDER BY sort_expressions]
[CLUSTER BY expressions]
[DISTRIBUTE BY expressions]
[SORT BY sort_expressions]
[WINDOW named_window[, WINDOW named_window, ...]]

named_expression: 
				:expression [AS alias]

relation:
		| join_relation
		| (table_name|query|relation)[sample][AS alias]
		: VALUES(expressions)[, (expressions), ...]
				[AS (column_name[, column_name, ...])]

expressions:
		   : expressions[, expressions, ...]

sort_expressions:
			    :expressions [ASC|DESC][, expressions [ASC|DESC], ...]
```

## SQL 配置
查看当前环境 SQL 参数的配置:

```scala
spark.sql("SET -v").show(false)

+-----------------------------------------------------+---------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|key                                                  |value          |meaning                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
+-----------------------------------------------------+---------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|spark.sql.adaptive.enabled                           |false          |When true, enable adaptive query execution.                                                                                                                                                                                                                                                                                                                                                                                                                         |
|spark.sql.adaptive.shuffle.targetPostShuffleInputSize|67108864b      |The target post-shuffle input size in bytes of a task.                                                                                                                                                                                                                                                                                                                                                                                                              |
|spark.sql.autoBroadcastJoinThreshold                 |10485760       |Configures the maximum size in bytes for a table that will be broadcast to all worker nodes when performing a join.  By setting this value to -1 broadcasting can be disabled. Note that currently statistics are only supported for Hive Metastore tables where the command <code>ANALYZE TABLE &lt;tableName&gt; COMPUTE STATISTICS noscan</code> has been run, and file-based data source tables where the statistics are computed directly on the files of data.|
|spark.sql.avro.compression.codec                     |snappy         |Compression codec used in writing of AVRO files. Supported codecs: uncompressed, deflate, snappy, bzip2 and xz. Default codec is snappy.                                                                                                                                                                                                                                                                                                                            |
|spark.sql.avro.deflate.level                         |-1             |Compression level for the deflate codec used in writing of AVRO files. Valid value must be in the range of from 1 to 9 inclusive or -1. The default value is -1 which corresponds to 6 level in the current implementation.                                                                                                                                                                                                                                         |
|spark.sql.broadcastTimeout                           |300000ms       |Timeout in seconds for the broadcast wait time in broadcast joins.                                                                                                                                                                                                                                                                                                                                                                                                  |
|spark.sql.cbo.enabled                                |false          |Enables CBO for estimation of plan statistics when set true.                                                                                                                                                                                                                                                                                                                                                                                                        |
|spark.sql.cbo.joinReorder.dp.star.filter             |false          |Applies star-join filter heuristics to cost based join enumeration.                                                                                                                                                                                                                                                                                                                                                                                                 |
|spark.sql.cbo.joinReorder.dp.threshold               |12             |The maximum number of joined nodes allowed in the dynamic programming algorithm.                                                                                                                                                                                                                                                                                                                                                                                    |
|spark.sql.cbo.joinReorder.enabled                    |false          |Enables join reorder in CBO.                                                                                                                                                                                                                                                                                                                                                                                                                                        |
|spark.sql.cbo.starSchemaDetection                    |false          |When true, it enables join reordering based on star schema detection.                                                                                                                                                                                                                                                                                                                                                                                               |
|spark.sql.columnNameOfCorruptRecord                  |_corrupt_record|The name of internal column for storing raw/un-parsed JSON and CSV records that fail to parse.                                                                                                                                                                                                                                                                                                                                                                      |
|spark.sql.crossJoin.enabled                          |false          |When false, we will throw an error if a query contains a cartesian product without explicit CROSS JOIN syntax.                                                                                                                                                                                                                                                                                                                                                      |
|spark.sql.execution.arrow.enabled                    |false          |When true, make use of Apache Arrow for columnar data transfers. Currently available for use with pyspark.sql.DataFrame.toPandas, and pyspark.sql.SparkSession.createDataFrame when its input is a Pandas DataFrame. The following data types are unsupported: BinaryType, MapType, ArrayType of TimestampType, and nested StructType.                                                                                                                              |
|spark.sql.execution.arrow.fallback.enabled           |true           |When true, optimizations enabled by 'spark.sql.execution.arrow.enabled' will fallback automatically to non-optimized implementations if an error occurs.                                                                                                                                                                                                                                                                                                            |
|spark.sql.execution.arrow.maxRecordsPerBatch         |10000          |When using Apache Arrow, limit the maximum number of records that can be written to a single ArrowRecordBatch in memory. If set to zero or negative there is no limit.                                                                                                                                                                                                                                                                                              |
|spark.sql.extensions                                 |<undefined>    |Name of the class used to configure Spark Session extensions. The class should implement Function1[SparkSessionExtension, Unit], and must have a no-args constructor.                                                                                                                                                                                                                                                                                               |
|spark.sql.files.ignoreCorruptFiles                   |false          |Whether to ignore corrupt files. If true, the Spark jobs will continue to run when encountering corrupted files and the contents that have been read will still be returned.                                                                                                                                                                                                                                                                                        |
|spark.sql.files.ignoreMissingFiles                   |false          |Whether to ignore missing files. If true, the Spark jobs will continue to run when encountering missing files and the contents that have been read will still be returned.                                                                                                                                                                                                                                                                                          |
|spark.sql.files.maxPartitionBytes                    |134217728      |The maximum number of bytes to pack into a single partition when reading files.                                                                                                                                                                                                                                                                                                                                                                                     |
+-----------------------------------------------------+---------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

```

### 配置项
```python
#Job ID /Name
spark.app.name=clsfd_ad_attr_map_w_mvca_ins

#yarn 进行调度，也可以是mesos，yarn，以及standalone

#一个spark application，是一个spark应用。一个应用对应且仅对应一个sparkContext。每一个应用，运行一组独立的executor processes。一个应用，可以以多线程的方式提交多个作业job。spark可以运行在多种集群管理器上如：mesos，yarn，以及standalone，每种集群管理器都会提供跨应用的资源调度策略。
spark.master=yarn

#激活外部shuffle服务。服务维护executor写的文件，因而executor可以被安全移除。
#需要设置spark.dynamicAllocation.enabled 为true，同事指定外部shuffle服务。
#对shuffle来说，executor现将自己的map输出写入到磁盘，然后，自己作为一个server，向其他executor提供这些map输出文件的数据。而动态资源调度将executor返还给集群后，这个shuffle数据服务就没有了。因此，如果要使用动态资源策略，解决这个问题的办法就是，将保持shuffle文件作为一个外部服务，始终运行在spark集群的每个节点上，独立于应用和executor
spark.shuffle.service.enabled=true

#在默认情况下，三种集群管理器均不使用动态资源调度模式。所以要使用动态资源调度需要提前配置。
spark.dynamicAllocation.enabled=true

# 如果所有的executor都移除了，重新请求时启动的初始executor数
spark.dynamicAllocation.initialExecutors=20

# 最少保留的executor数
spark.dynamicAllocation.minExecutors=10

# 最多使用的executor数，默认为你申请的最大executor数
spark.dynamicAllocation.maxExecutors=100

# 可以是cluster也可以是Client
spark.submit.deployMode=cluster

# 指定提交到Yarn的资源池
spark.yarn.queue=hdlq-data-batch-low

# 在yarn-cluster模式下，申请Yarn App Master（包括Driver）所用的内存。
spark.driver.memory=8g
# excutor的核心数
spark.executor.cores=16
# 一个Executor对应一个JVM进程。Executor占用的内存分为两部分：ExecutorMemory和MemoryOverhead
spark.executor.memory=32g
spark.yarn.executor.memoryOverhead=2g

# shuffle分区数100，根据数据量进行调控，这儿配置了Join时shuffle的分区数和聚合数据时的分区数。
spark.sql.shuffle.partitions=100

# 如果用户没有指定并行度，下面这个参数将是RDD中的分区数，它是由join,reducebykey和parallelize 
# 这个参数只适用于未加工的RDD不适用于dataframe
# 没有join和聚合计算操作，这个参数将是无效设置
spark.default.parallelism

# 打包传入一个分区的最大字节，在读取文件的时候。
spark.sql.files.maxPartitionBytes=128MB

# 用相同时间内可以扫描的数据的大小来衡量打开一个文件的开销。当将多个文件写入同一个分区的时候该参数有用。
# 该值设置大一点有好处，有小文件的分区会比大文件分区处理速度更快（优先调度）。
spark.sql.files.openCostInBytes=4MB

# Spark 事件总线是SparkListenerEvent事件的阻塞队列大小
spark.scheduler.listenerbus.eventqueue.size=100000

# 是否启动推测机制
spark.speculation=false

# 开启spark的推测机制，开启推测机制后如果某一台机器的几个task特别慢，推测机制会将任务分配到其他机器执行，最后Spark会选取最快的作为最终结果。
# 2表示比其他task慢两倍时，启动推测机制
spark.speculation.multiplier=2

# 推测机制的检测周期
spark.speculation.interval=5000ms

# 完成task的百分比时启动推测
spark.speculation.quantile=0.6

# 最多允许失败的Executor数量。
spark.task.maxFailures=10

# spark序列化 对于优化<网络性能>极为重要，将RDD以序列化格式来保存减少内存占用.
spark.serializer=org.apache.spark.serializer.KryoSerializer

# 因为spark是基于内存的机制，所以默认是开启RDD的压缩
spark.rdd.compress=true

# Spark的安全管理
#https://github.com/apache/spark/blob/master/core/src/main/scala/org/apache/spark/SecurityManager.scala
spark.ui.view.acls=*
spark.ui.view.acls.groups=*

# 表示配置GC线程数为3
spark.executor.extraJavaOptions="-XX:ParallelGCThreads=3"

# 最大广播表的大小。设置为-1可以禁止该功能。当前统计信息仅支持Hive Metastore表。这里设置的是10MB
spark.sql.autoBroadcastJoinThreshold=104857600

# 广播等待超时，这里单位是秒
spark.sql.broadcastTimeout=300

# 心跳检测间隔
spark.yarn.scheduler.heartbeat.interval-ms=10000

spark.sql.broadcastTimeout

#缓存表问题
#spark2.+采用：
#spark.catalog.cacheTable("tableName")缓存表，spark.catalog.uncacheTable("tableName")解除缓存。
#spark 1.+采用：
#sqlContext.cacheTable("tableName")缓存，sqlContext.uncacheTable("tableName") 解除缓存
#Sparksql仅仅会缓存必要的列，并且自动调整压缩算法来减少内存和GC压力。

#假如设置为true，SparkSql会根据统计信息自动的为每个列选择压缩方式进行压缩。
spark.sql.inMemoryColumnarStorage.compressed=true

#控制列缓存的批量大小。批次大有助于改善内存使用和压缩，但是缓存数据会有OOM的风险
spark.sql.inMemoryColumnarStorage.batchSize=10000
```

### 配置方法
可以在应用程序初始化时或在应用程序执行过程中进行设置：

```scala
spark.conf.set("spark.sql.crossJoin.enabled", "true")
```

## 参考
- 《Spark 权威指南：Chapter 10》
- [什么是Catalog](https://www.cnblogs.com/cc11001100/p/9463578.html)
- [https://spark.apache.org/docs/2.3.0/api/sql/](https://spark.apache.org/docs/2.3.0/api/sql/)


































































