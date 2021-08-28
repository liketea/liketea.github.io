---
title: Spark 指南：Spark SQL（一）—— 结构化对象
date: 2020-11-04 14:16:46
tags: 
   - Spark
categories: 
   - Spark
---

SparkSession 是 Dataset 与 DataFrame API 的编程入口，从 Spark2.0 开始支持，用于统一原来的 HiveContext 和 SQLContext，统一入口提高了 Spark 的易用性，但为了兼容向后兼容，新版本仍然保留了这两个入口。下面的代码展示了如何创建一个 SparkSession：

```scala
import org.apache.spark.sql.SparkSession

val spark = SparkSession
  .builder()
  .appName("Spark SQL basic example")
  .config("spark.some.config.option", "some-value")
  .getOrCreate()
```

DataFrame 仅仅只是 **Dataset[Row]** 的一个类型别名，创建 Dataset 的方式和创建 DataFrame 基本相同。

## 从内置方法创建
`spark.range` 方法可以创建一个单列 DataFrame，其中列名为 id，列的类型为 LongType 类型，列中的值取 range 生成的值。


```scala
// 语法
range(end: Long)
range(start: Long, end: Long)
range(start: Long, end: Long, step: Long)
// 示例
val ddf = spark.range(3)
    .withColumn("today", current_date())
    .withColumn("now", current_timestamp())
ddf.show(false)
+---+----------+-----------------------+
|id |today     |now                    |
+---+----------+-----------------------+
|0  |2020-11-03|2020-11-03 21:05:26.657|
|1  |2020-11-03|2020-11-03 21:05:26.657|
|2  |2020-11-03|2020-11-03 21:05:26.657|
+---+----------+-----------------------+
```

## 从对象序列创建 
spark 提供了一系列隐式转换方法，可以将指定类型的对象序列 `Seq[T]` 或 `RDD[T]` 转化为 `Dataset[T]` 或 `DataFrame`，使用前需要先导入隐式转换：

```scala
// spark 为入口 SparkSession 对象
import spark.implicits._
```

### toDF & toDS
如果 `T` 是 `Int`、`Long`、`String` 或 `T <: scala.Product`(Tuple 或 case class) 类型中的一种，则可以通过 `toDs()` 或 `toDf()` 方法转化为 `Dataset[T]` 或 `DataFrame`。

- `toDF(): DataFrame` 和 `toDF(colNames: String*): DataFrame` 方法提供了一种非常简洁的方式，将对象序列转化为一个 DataFrame；
    - 列名：如果不提供 colNames，当结果只有一列时默认列名为 `value`，如果结果有多列 `_1, _2,...` 会作为默认列名；
    - 类型：默认列类型将会通过输入数据的类型进行推断，如果要显式指定列的类型，可以通过 createDataFrame() 方法指定对应的 schema；

```scala
// 序列元素为简单类型
val seq = Seq(1,2,3)
seq.toDF().show()
+-----+
|value|
+-----+
|    1|
|    2|
|    3|
+-----+

// 序列元素为元组
val df = Seq(
    ("Arya", "Woman", 30),
    ("Bob", "Man", 28)
).toDF("name", "sex", "age")
df.show()

+----+-----+---+
|name|  sex|age|
+----+-----+---+
|Arya|Woman| 30|
| Bob|  Man| 28|
+----+-----+---+

// 序列元素为样例类，通过反射读取样例类的参数名称，并映射成column的名称
case class Person(name: String, age: Long)
val df = Seq(Person("Andy", 32)).toDF
df.show()
+----+---+
|name|age|
+----+---+
|Andy| 32|
+----+---+

// 从 RDD 创建 DataFrame，parallelize 用于将序列转化为 RDD
val rdd = spark.sparkContext.parallelize(List(1,2))
val df = rdd.map(x=>(x,x^2)).toDF("org","xor")
df.show()
+---+---+
|org|xor|
+---+---+
|  1|  3|
|  2|  0|
+---+---+
```

- `toDS(): Dataset[T]` 提供了一种将指定类型的对象序列转化为 DataSet 的简易方法

```scala
// 序列元素为简单类型
val ds = Seq(1,2,3).toDS()
ds.show(false)
+-----+
|value|
+-----+
|1    |
|2    |
|3    |
+-----+

// 序列元素是元组
val ds = Seq(("Arya",20,"woman"), ("Bob",28,"man")).toDS()
ds.show(false)
+----+---+-----+
|_1  |_2 |_3   |
+----+---+-----+
|Arya|20 |woman|
|Bob |28 |man  |
+----+---+-----+

// 序列元素为样例类实例，样例类的字段会成为 DataSet 的字段
// 注意，case class 的定义要在引用 case class函数的外面，否则即使 import spark.implicits._ 也还是会报错 value toDF is not a member of ***
case class Person(name: String, age: Long, sex:String)
val ds = Seq(Person("Arya", 20, "woman"), Person("Bob", 28, "man"))
            .toDS().show()
+----+---+-----+
|name|age|  sex|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
+----+---+-----+    

// 将 RDD 转化为 DataSet
val rdd = spark.sparkContext.parallelize(Seq(("Arya",20,"woman"), ("Bob",28,"man")))
rdd.toDS().show()
+----+---+-----+
|  _1| _2|   _3|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
+----+---+-----+      
```

toDF 方法对 null 类型处理的不好，不建议在生产环境中使用。

### createDataFrame & createDataSet
相比 toDF 和 toDS，createDataFrame 和 createDataSet 方法支持更多的数据类型，特别是 `Seq[Row]` 和 `RDD[Row]` 只能通过 create 方法来转化为 DataFrame。

- createDataFrame 有多个重载方法：如果只传入数据，则数据只能是一个包含 Product 元素的序列或 RDD；如果传入 Schema，数据可以是 RDD[Row] 或 java.util.List[Row]；如果传入 beanClass，数据可以是 RDD[Java Bean] 或java.util.List[Java Bean]
    - `createDataFrame[A <: Product : TypeTag](data: Seq[A]): DataFrame`: 通过 Product 序列创建 DataFrame，如 tuple、case class
    - `createDataFrame[A <: Product : TypeTag](rdd: RDD[A]): DataFrame`: 通过 Product RDD 创建 DataFrame，如 tuple、case class
    - `createDataFrame(rows: List[Row], schema: StructType): DataFrame`: 通过 java.util.List[Row] 并指定 Schema 创建 DataFrame
    - `createDataFrame(rowRDD: RDD[Row], schema: StructType): DataFrame`: 通过 RDD[Row] 并指定 Schema 创建 DataFrame
    - `createDataFrame(rdd: RDD[_], beanClass: Class[_]): DataFrame`: Applies a schema to an RDD of Java Beans
    - `createDataFrame(data: List[_], beanClass: Class[_]): DataFrame`: Applies a schema to a List of Java Beans

```scala
// 只传入 Seq[Tuple]，列名为 "_1" "_2"
val dfData = Seq((1,"a"), (2, "b"))
val ds = spark.createDataFrame(dfData)
ds.show()
+---+---+
| _1| _2|
+---+---+
|  1|  a|
|  2|  b|
+---+---+

// 只传入 Seq[case class]，列名为样例类字段名
case class Person(name:String, sex:String, age:Int)
val dfData = Seq(Person("a", "b", 1))
val ds = spark.createDataFrame(dfData)
ds.show()
+----+---+---+
|name|sex|age|
+----+---+---+
|   a|  b|  1|
+----+---+---+

// 只传入 RDD[Tuple]
val dfData = spark.sparkContext.parallelize(Seq((1,"a"), (2, "b")))
val ds = spark.createDataFrame(dfData)
ds.show()
+---+---+
| _1| _2|
+---+---+
|  1|  a|
|  2|  b|
+---+---+

// 传入 schema，数据可以是 RDD[Row]
import org.apache.spark.sql.Row
import org.apache.spark.sql.types.{StructType, StructField, StringType, IntegerType};

val dfData = spark.sparkContext.parallelize(
    Seq(
        Row("Arya", "Woman", 30),
        Row("Bob", "Man", 28)
    )
)
val dfSchema = StructType(
    Seq(
    StructField("name", StringType, true),
    StructField("sex", StringType, true),
    StructField("age", IntegerType, true)
    )
)

val df = spark.createDataFrame(dfData, dfSchema)
df.show()
+----+-----+---+
|name|  sex|age|
+----+-----+---+
|Arya|Woman| 30|
| Bob|  Man| 28|
+----+-----+---+

// 传入 schema，数据可以是 java.util.List[Row]
val dfData = new java.util.ArrayList[Row]()
dfData.add(Row("Arya", "Woman", 30))
dfData.add(Row("Bob", "Man", 28))

val df = spark.createDataFrame(dfData, dfSchema)
df.show()
+----+-----+---+
|name|  sex|age|
+----+-----+---+
|Arya|Woman| 30|
| Bob|  Man| 28|
+----+-----+---+

// 构造复杂 Schema 时，使用实例化 StructType 对象的 add 方法更方便
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

- `createDataSet(x)` 是 `x.toDS()` 的等价形式：

```scala
// 序列元素为简单类型
val ds = spark.createDataset(Seq(1,2,3))
ds.show()
+-----+
|value|
+-----+
|    1|
|    2|
|    3|
+-----+
// 序列元素是元组
val ds = spark.createDataset(Seq(("Arya",20,"woman"), ("Bob",28,"man")))
ds.show()
+----+---+-----+
|  _1| _2|   _3|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
+----+---+-----+

// 序列元素为样例类实例，样例类的字段会成为 DataSet 的字段
case class Person(name: String, age: Long, sex:String)
val ds = spark.createDataset(Seq(Person("Arya", 20, "woman"), Person("Bob", 28, "man")))
ds.show()
+----+---+-----+
|name|age|  sex|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
+----+---+-----+
// 将 RDD 转化为 DataSet
val ds = spark.createDataset(spark.sparkContext.parallelize(Seq(("Arya",20,"woman"), ("Bob",28,"man"))))
ds.show()
+----+---+-----+
|  _1| _2|   _3|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
+----+---+-----+
```

## 从数据源加载
Spark 有六个核心数据源和社区编写的数百个外部数据源（Cassandra、HBase、MongoDB、XML）：

1. CSV
2. JSON
3. Parquet
4. ORC
5. JDBC/ODBC connections
6. Plain-text files 纯文本文件

### API 格式
#### Read API
读取数据源的通用 API 结构如下：

```scala
DataFrameReader.format(...).option("key", "value").schema(...).load(path)

// 示例
spark.read.format("csv")
    .option("mode", "FAILFAST")
    .option("inferSchema", "true")
    .option("path", "path/to/file")
    .schema(someSchema)
    .load()
```

读取数据的基本要素：

1. `DataFrameReader` 是 DataFrame 读取器，可以通过 `SparkSession` 的 `read` 属性来使用；
2. `format` 是可选的，默认使用 Parquet 格式；
3. `option` 允许设置键值配置，以参数化如何读取数据，也可以传入一个 Map；
4. `schema` 如果数据源提供了 schema，或者你打算使用 schema 推断，则 schema 是可选的；每种格式都有一些必选项，我们将在讨论每种格式时进行详细讨论；

Read modes 用于指定当 Spark 遇到格式错误的记录时如何处理：

1. `permissive`	：默认值，遇到损坏的记录时，将所有损坏记录放在名为`called_corrupt_record`的字符串列中，将所有字段设置为 null；
2. `dropMalformed`	：删除包含格式错误的行；
3. `failFast` ：遇到格式错误的记录立即失败；

#### Write API
写入数据的通用 API 结构如下：

```scala
DataFrameWriter.format(...).option(...).partitionBy(...).bucketBy(...).sortBy(...).save()

// 示例
df.write.format("csv")
    .option("mode", "OVERWRITE")
    .option("dataFormat", "yyyy-MM-dd")
    .option("path", "path/to/file")
    .save(path)
```

数据写入的基本要素：

1. `DataFrameWriter` 是 DataFrame 写入器，可以通过 `DataFrame` 的 `write` 属性来使用；
2. `format` 是可选的，默认使用 Parquet 格式；
3. `option` 允许设置键值配置，以参数化如何读取数据，也可以传入一个 Map；必须至少提供一个保存路径；

Save modes 用于指定当 Spark 在指定位置找到数据将发生什么：

1. `apppend`：将输出文件追加到该位置已存在的文件列表中；
2. `overwrite`：将完全覆盖那里已经存在的任何数据；
3. `errorIfExists`：默认值，如果指定位置已经存在数据或文件，则会引发错误并导致写入失败；
4. `ignore`：如果该位置存在数据或文件，则不执行任何操作；

### CSV
CSV 文件虽然看起来结构良好，但实际上是你将遇到的最棘手的文件格式之一，因为在生产方案中无法对其所包含的内容或结果进行很多假设，因此，CSV 读取器具有大量选项。

- option 说明：

| 参数                        | 解释                                                                                                                                                                                                                          |
|---------------------------|---------------------------------------------------------|
| sep                       | 默认是, 指定单个字符分割字段和值                                                                                                                                                                                                           |
| encoding                  | 默认是uft\-8通过给定的编码类型进行解码                                                                                                                                                                                                      |
| quote                     | 默认是“，其中分隔符可以是值的一部分，设置用于转义带引号的值的单个字符。<br>如果您想关闭引号，则需要设置一个空字符串，而不是null。                                                                                                                                                           |
| escape                    | 默认\(\\\)设置单个字符用于在引号里面转义引号                                                                                                                                                                                                   |
| charToEscapeQuoteEscaping | 默认是转义字符（上面的escape）或者\\0，当转义字符和引号\(quote\)字符<br>不同的时候，默认是转义字符\(escape\)，否则为\\0                                                                                                                                                   |
| comment                   | 默认是空值，设置用于跳过行的单个字符，以该字符开头。默认情况下，它是禁用的                                                                                                                                                                                       |
| header                    | 默认是false，将第一行作为列名                                                                                                                                                                                                           |
| enforceSchema             | 默认是true， 如果将其设置为true，则指定或推断的模式将强制应用于数据源文件，<br>而CSV文件中的标头将被忽略。 如果选项设置为false，则在header选项设置为true的情况下，<br>将针对CSV文件中的所有标题验证模式。模式中的字段名称和CSV标头<br>中的列名称是根据它们的位置检查的，并考虑了\*spark\.sql\.caseSensitive。<br>虽然默认值为true，但是建议禁用 enforceSchema选项，以避免产生错误的结果 |
| inferSchema               | inferSchema（默认为false\`）：从数据自动推断输入模式。 <br>\*需要对数据进行一次额外的传递                                                                                                                                                                       |
| samplingRatio             | 默认为1\.0,定义用于模式推断的行的分数                                                                                                                                                                                                       |
| ignoreLeadingWhiteSpace   | 默认为false,一个标志，指示是否应跳过正在读取的值中的前导空格                                                                                                                                                                                           |
| ignoreTrailingWhiteSpace  | 默认为false一个标志，指示是否应跳过正在读取的值的结尾空格                                                                                                                                                                                             |
| nullValue                 | 默认是空的字符串,设置null值的字符串表示形式。从2\.0\.1开始，<br>这适用于所有支持的类型，包括字符串类型                                                                                                                                                                     |
| emptyValue                | 默认是空字符串,设置一个空值的字符串表示形式                                                                                                                                                                                                      |
| nanValue                  | 默认是Nan,设置非数字的字符串表示形式                                                                                                                                                                                                        |
| positiveInf               | 默认是Inf                                                                                                                                                                                                                      |
| negativeInf               | 默认是\-Inf 设置负无穷值的字符串表示形式                                                                                                                                                                                                     |
| dateFormat                | 默认是yyyy\-MM\-dd,设置指示日期格式的字符串。自定义日期格式遵循<br>java\.text\.SimpleDateFormat中的格式。这适用于日期类型                                                                                                                                             |
| timestampFormat           | 默认是yyyy\-MM\-dd'T'HH:mm:ss\.SSSXXX，设置表示时间戳格式的字符串。<br>自定义日期格式遵循java\.text\.SimpleDateFormat中的格式。这适用于时间戳记类型                                                                                                                       |
| maxColumns                | 默认是20480定义多少列数目的硬性设置                                                                                                                                                                                                        |
| maxCharsPerColumn         | 默认是\-1定义读取的任何给定值允许的最大字符数。默认情况下为\-1，表示长度不受限制                                                                                                                                                                                 |
| mode                      | 默认（允许）允许一种在解析过程中处理损坏记录的模式。它支持以下不区分大小写的模式。<br>请注意，Spark尝试在列修剪下仅解析CSV中必需的列。<br>因此，损坏的记录可以根据所需的字段集而有所不同。<br>可以通过spark\.sql\.csv\.parser\.columnPruning\.enabled（默认启用）来控制此行为。                                                               |
| columnNameOfCorruptRecord | 默认值指定在spark\.sql\.columnNameOfCorruptRecord,<br>允许重命名由PERMISSIVE模式创建的格式错误的新字段。<br>这会覆盖spark\.sql\.columnNameOfCorruptRecord                                                                                                         |
| multiLine                 | 默认是false,解析一条记录，该记录可能跨越多行   

- 读取 CSV 示例：

```scala
val mySchema = new StructType(
    Array(
        new StructField("a", StringType, true),
        new StructField("b", IntegerType, true),
        new StructField("c", StringType, false)
    )
)

val df = spark.read.format("csv")
    .option("header", "true")
    .option("mode", "permissive")
    .schema(mySchema)
    .load("job.csv")
df.show()
df.printSchema
+------+---+---+
|     a|  b|  c|
+------+---+---+
|caster|  0| 26|
|  like|  1| 30|
|   leo|  2| 30|
|rayray|  3| 27|
+------+---+---+

root
 |-- a: string (nullable = true)
 |-- b: integer (nullable = true)
 |-- c: string (nullable = true)
```

- 写入 CSV 示例：`job2.csv` 实际上是一个目录，其中包含很多文件，文件数对应分区数；

```scala
df.write.format("csv")
    .mode("overwrite")
    .option("seq", "\t")
    .save("job2.csv")
```

### JSON
在 Spark 中，当我们谈到 JSON 文件时，指的的是 `line-delimited` JSON 文件，这与每个文件具有较大 JSON 对象或数组的文件形成对比。`line-delimited` 和 `multiline` 由选项 `multiLine` 控制，当将此选项设置为 true 时，可以将整个文件作为一个 json 对象读取。`line-delimited` 的 JSON 实际上是一种更加稳定的格式，它允许你将具有新记录的文件追加到文件中，这也是建议你使用的格式。

- option 说明：

| 属性名称                               | 默认值        | 含义                                                                                                                                                         |
|------------------------------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| primitivesAsString                 | FALSE      | 将所有原始类型推断为字符串类型                                                                                                                                         |
| prefersDecimal                     | FALSE      | 将所有浮点类型推断为 decimal 类型，如果不适合，<br>则推断为 double 类型                                                                                                              |
| allowComments                      | FALSE      | 忽略 JSON 记录中的 Java / C \+\+样式注释                                                                                                                                |
| allowUnquotedFieldNames            | FALSE      | 允许不带引号的 JSON 字段名称                                                                                                                                            |
| allowSingleQuotes                  | TRUE       | 除双引号外，还允许使用单引号                                                                                                                                             |
| allowNumericLeadingZeros           | FALSE      | 允许数字前有零                                                                                                                                                    |
| allowBackslashEscapingAnyCharacter | FALSE      | 允许反斜杠转义任何字符                                                                                                                                                |
| allowUnquotedControlChars          | FALSE      | 允许JSON字符串包含不带引号的控制字符（值小于32的ASCII字符，<br>包括制表符和换行符）或不包含。                                                                                                         |
| mode                               | PERMISSIVE | PERMISSIVE：允许在解析过程中处理损坏记录； DROPMALFORMED：<br>忽略整个损坏的记录；FAILFAST：遇到损坏的记录时抛出异常。                                                                                  |
| columnNameOfCorruptRecord          |            | columnNameOfCorruptRecord（默认值是spark\.sql\.columnNameOfCorruptRecord中指定的值）：<br>允许重命名由PERMISSIVE 模式创建的新字段（存储格式错误的字符串）。<br>这会覆盖spark\.sql\.columnNameOfCorruptRecord。 |
| dateFormat                         |            | dateFormat（默认yyyy\-MM\-dd）：设置表示日期格式的字符串。<br>自定义日期格式遵循java\.text\.SimpleDateFormat中的格式。                                                                         |
| timestampFormat                    |            | timestampFormat（默认yyyy\-MM\-dd’T’HH：mm：ss\.SSSXXX）：<br>设置表示时间戳格式的字符串。 自定义日期格式遵循java\.text\.SimpleDateFormat中的格式。                                               |
| multiLine                          | FALSE      | 解析可能跨越多行的一条记录                                                                                                           |
                                                                                                                                                                                                

- 读取 JSON 示例：

```scala
spark.read.format("json")
    .option("mode", "FAILFAST")
    .schema(mySchema)
    .load(path)
```

- 写入 JSON 示例：同样每个分区将写入一个文件，而整个 DataFrame 将作为一个文件夹写入，每行将有一个 JSON 对象

```scala
df.write.format("json").mode("overwrite").save(path)
```

### Parquet
Parquet 是 Spark 的默认文件格式（默认数据源可以通过 `spark.sql.sources.default` 进行设置），Parquet 是面向列的开源数据存储，可提供各种存储优化。它提供了列压缩，从而节省了存储空间，并允许读取单个列而不是整个文件。Parquet 支持复杂类型，如果你的列是 `struct`、`array`、`map` 类型，仍然可以正常读写该文件。

- 读取 Parquet 文件：Parquet 选项很少，因为它在存储数据时会强制执行自己的 Schema，你只需要设置格式就行了

```scala
spark.read.format("parquet").load(path)
```

- 写入 Parquet 文件：只需要指定文件位置即可

```scala
df.write.format("parquet")
    .mode("overwrite")
    .save(path)
```

### ORC
ORC 是一种专为 Hadoop workloads 设计的自我描述、有类型的列式文件格式。它针对大型数据流进行了优化，但是集成了对快速查找所需行的支持。ORC 实际上没有读取数据的选项，因为 Spark 非常了解这种文件格式，一个经常会被问到的问题是：ORC 和 Parquet 有什么区别？在大多数情况下，他们非常相似，根本的区别在于 Parquet 专门为 Spark 做了优化，而 ORC 专门为 Hive 做了优化。

- 读取 ORC 示例：

```scala
spark.read.format("orc").load(path)
```

- 写入 ORC 示例：

```scala
df.write.format("orc").mode("overwrite").save(path)
```

### Hive 数据源
Spark SQL 还支持读取和写入存储在Apache Hive中的数据。但是，由于Hive具有大量依赖项，因此这些依赖项不包含在默认的Spark发布包中。如果可以在类路径上找到Hive依赖项，Spark将自动加载它们。请注意，这些Hive依赖项也必须存在于所有工作节点(worker nodes)上，因为它们需要访问Hive序列化和反序列化库（SerDes）才能访问存储在Hive中的数据。

在使用Hive时，必须实例化一个支持Hive的SparkSession，包括连接到持久性Hive Metastore，支持Hive 的序列化、反序列化（serdes）和Hive用户定义函数。没有部署Hive的用户仍可以启用Hive支持。如果未配置hive-site.xml，则上下文(context)会在当前目录中自动创建metastore_db，并且会创建一个由spark.sql.warehouse.dir配置的目录，其默认目录为spark-warehouse，位于启动Spark应用程序的当前目录中。请注意，自Spark 2.0.0以来，该在hive-site.xml中的hive.metastore.warehouse.dir属性已被标记过时(deprecated)。使用spark.sql.warehouse.dir用于指定warehouse中的默认位置。可能需要向启动Spark应用程序的用户授予写入的权限。

下面的案例为在本地运行(为了方便查看打印的结果)，运行结束之后会发现在项目的目录下 `E:\IdeaProjects\myspark` 创建了 `spark-warehouse` 和 `metastore_db` 的文件夹。可以看出没有部署Hive的用户仍可以启用Hive支持，同时也可以将代码打包，放在集群上运行。

```scala
object SparkHiveExample {
  case class Record(key: Int, value: String)

  def main(args: Array[String]) {
    val spark = SparkSession
      .builder()
      .appName("Spark Hive Example")
      .config("spark.sql.warehouse.dir", "e://warehouseLocation")
      .master("local")//设置为本地运行
      .enableHiveSupport()
      .getOrCreate()

    Logger.getLogger("org.apache.spark").setLevel(Level.OFF)
    Logger.getLogger("org.apache.hadoop").setLevel(Level.OFF)
    import spark.implicits._
    import spark.sql
    
    //使用Spark SQL 的语法创建Hive中的表
    sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING) USING hive")
    sql("LOAD DATA LOCAL INPATH 'file:///e:/kv1.txt' INTO TABLE src")

    // 使用HiveQL查询
    sql("SELECT * FROM src").show()
    // +---+-------+
    // |key|  value|
    // +---+-------+
    // |238|val_238|
    // | 86| val_86|
    // |311|val_311|
    // ...

    // 支持使用聚合函数
    sql("SELECT COUNT(*) FROM src").show()
    // +--------+
    // |count(1)|
    // +--------+
    // |    500 |
    // +--------+

    // SQL查询的结果是一个DataFrame，支持使用所有的常规的函数
    val sqlDF = sql("SELECT key, value FROM src WHERE key < 10 AND key > 0 ORDER BY key")

    // DataFrames是Row类型的, 允许你按顺序访问列.
    val stringsDS = sqlDF.map {
      case Row(key: Int, value: String) => s"Key: $key, Value: $value"
    }
    stringsDS.show()
    // +--------------------+
    // |               value|
    // +--------------------+
    // |Key: 0, Value: val_0|
    // |Key: 0, Value: val_0|
    // |Key: 0, Value: val_0|
    // ...

    //可以通过SparkSession使用DataFrame创建一个临时视图
    val recordsDF = spark.createDataFrame((1 to 100).map(i => Record(i, s"val_$i")))
    recordsDF.createOrReplaceTempView("records")

    //可以用DataFrame与Hive中的表进行join查询
    sql("SELECT * FROM records r JOIN src s ON r.key = s.key").show()
    // +---+------+---+------+
    // |key| value|key| value|
    // +---+------+---+------+
    // |  2| val_2|  2| val_2|
    // |  4| val_4|  4| val_4|
    // |  5| val_5|  5| val_5|
    // ...

    //创建一个Parquet格式的hive托管表，使用的是HQL语法，没有使用Spark SQL的语法("USING hive")
    sql("CREATE TABLE IF NOT EXISTS hive_records(key int, value string) STORED AS PARQUET")

    //读取Hive中的表，转换成了DataFrame
    val df = spark.table("src")
    //将该DataFrame保存为Hive中的表，使用的模式(mode)为复写模式(Overwrite)
    //即如果保存的表已经存在，则会覆盖掉原来表中的内容
    df.write.mode(SaveMode.Overwrite).saveAsTable("hive_records")
    // 查询表中的数据
    sql("SELECT * FROM hive_records").show()
    // +---+-------+
    // |key|  value|
    // +---+-------+
    // |238|val_238|
    // | 86| val_86|
    // |311|val_311|
    // ...

    // 设置Parquet数据文件路径
    val dataDir = "/tmp/parquet_data"
    //spark.range(10)返回的是DataSet[Long]
    //将该DataSet直接写入parquet文件
    spark.range(10).write.parquet(dataDir)
    // 在Hive中创建一个Parquet格式的外部表
    sql(s"CREATE EXTERNAL TABLE IF NOT EXISTS hive_ints(key int) STORED AS PARQUET LOCATION '$dataDir'")
    // 查询上面创建的表
    sql("SELECT * FROM hive_ints").show()
    // +---+
    // |key|
    // +---+
    // |  0|
    // |  1|
    // |  2|
    // ...

    // 开启Hive动态分区
    spark.sqlContext.setConf("hive.exec.dynamic.partition", "true")
    spark.sqlContext.setConf("hive.exec.dynamic.partition.mode", "nonstrict")
    // 使用DataFrame API创建Hive的分区表
    df.write.partitionBy("key").format("hive").saveAsTable("hive_part_tbl")

    //分区键‘key’将会在最终的schema中被移除
    sql("SELECT * FROM hive_part_tbl").show()
    // +-------+---+
    // |  value|key|
    // +-------+---+
    // |val_238|238|
    // | val_86| 86|
    // |val_311|311|
    // ...

    spark.stop()
  }
}
```

### JDBC 数据源
Spark SQL 还包括一个可以使用 JDBC 从其他数据库读取数据的数据源。与使用 JdbcRDD 相比，应优先使用此功能。这是因为结果作为 DataFrame 返回，它们可以在 Spark SQL 中轻松处理或与其他数据源连接。JDBC 数据源也更易于使用 Java 或 Python，因为它不需要用户提供 ClassTag。

可以使用 Data Sources API 将远程数据库中的表加载为 DataFrame 或 Spark SQL 临时视图。用户可以在数据源选项中指定JDBC连接属性。user并且password通常作为用于登录数据源的连接属性提供。除连接属性外，Spark还支持以下不区分大小写的选项：

| 属性名称                               | 含义                                                                                                                                                                                              |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| url                                   | 要连接的JDBC URL，可以再URL中指定特定于源的连接属性                                                                                                                                                                 |
| dbtable                               | 应该读取或写入的JDBC表                                                                                                                                                                                   |
| query                                 | 将数据读入Spark的查询语句                                                                                                                                                                                 |
| driver                                | 用于连接到此URL的JDBC驱动程序的类名                                                                                                                                                                           |
| numPartitions                         | 表读取和写入中可用于并行的最大分区数，同时确定了最大并发的JDBC连接数                                                                                                                                                            |
| partitionColumn,<br>lowerBound,<br>upperBound | 如果指定了任一选项，则必须指定全部选项。此外，还必须指定numPartitions。<br>partitionColumn必须是表中的数字，日期或时间戳列。<br>注意：lowerBound和upperBound（仅用于决定分区步幅，而不是用于过滤表中的行。<br>因此，表中的所有行都将被分区并返回，这些选项仅用于读操作。）                                         |
| queryTimeout                          | 超时时间（单位：秒），零意味着没有限制                                                                                                                                                                             |
| fetchsize                             | 用于确定每次往返要获取的行数（例如Oracle是10行），<br>可以用于提升JDBC驱动程序的性能。此选项仅适用于读                                                                                                                                         |
| batchsize                             | JDBC批处理大小，默认 1000，用于确定每次往返要插入的行数。 <br>这可以用于提升 JDBC 驱动程序的性能。此选项仅适用于写。                                                                                                                                     |
| isolationLevel                        | 事务隔离级别，适用于当前连接。它可以是 NONE，READ\_COMMITTED，<br>READ\_UNCOMMITTED，REPEATABLE\_READ 或 SERIALIZABLE 之一，<br>对应于 JDBC的Connection 对象定义的标准事务隔离级别，<br>默认值为 READ\_UNCOMMITTED。此选项仅适用于写。                                |
| sessionInitStatement                  | 在向远程数据库打开每个数据库会话之后，在开始读取数据之前，<br>此选项将执行自定义SQL语句（或PL / SQL块）。 <br>使用它来实现会话初始化，例如：option\(“sessionInitStatement”, <br>“”“BEGIN execute immediate ‘alter session set “\_serial\_direct\_read”=true’; END;”""\) |
| truncate                              | 当启用SaveMode\.Overwrite时，此选项会导致 Spark 截断现有表，<br>而不是删除并重新创建它。这样更高效，并且防止删除表元数据（例如，索引）。<br>但是，在某些情况下，例如新数据具有不同的 schema 时，它将无法工作。此选项仅适用于写。                                                                   |
| cascadeTruncate                       | 如果JDBC数据库（目前为 PostgreSQL和Oracle）启用并支持，<br>则此选项允许执行TRUNCATE TABLE t CASCADE（在PostgreSQL的情况下，<br>仅执行TRUNCATE TABLE t CASCADE以防止无意中截断表）。<br>这将影响其他表，因此应谨慎使用。此选项仅适用于写。                                          |
| createTableOptions                    | 此选项允许在创建表时设置特定于数据库的表和分区选项<br>（例如，CREATE TABLE t \(name string\) ENGINE=InnoDB）。此选项仅适用于写。                                                                                                            |
| createTableColumnTypes                | 创建表时要使用的数据库列数据类型而不是默认值。<br>（例如：name CHAR（64），comments VARCHAR（1024））。<br>指定的类型应该是有效的 spark sql 数据类型。 此选项仅适用于写。                                                                                          |
| customSchema                          | 用于从JDBC连接器读取数据的自定义 schema。<br>例如，id DECIMAL\(38, 0\), name STRING。<br>您还可以指定部分字段，其他字段使用默认类型映射。 <br>例如，id DECIMAL（38,0）。列名应与JDBC表的相应列名相同。<br>用户可以指定Spark SQL的相应数据类型，而不是使用默认值。 此选项仅适用于读。                          |
| pushDownPredicate                     | 用于 启用或禁用 谓词下推 到 JDBC数据源的选项。<br>默认值为 true，在这种情况下，Spark会尽可能地将过滤器下推到JDBC数据源。<br>否则，如果设置为 false，则不会将过滤器下推到JDBC数据源，<br>此时所有过滤器都将由Spark处理。                                                                        |


- 读写 JDBC 示例：

```scala
object JdbcDatasetExample {
  def main(args: Array[String]): Unit = {
    val spark = SparkSession
      .builder()
      .appName("JdbcDatasetExample")
      .master("local") //设置为本地运行
      .getOrCreate()
    Logger.getLogger("org.apache.spark").setLevel(Level.OFF)
    Logger.getLogger("org.apache.hadoop").setLevel(Level.OFF)
    runJdbcDatasetExample(spark)
  }

  private def runJdbcDatasetExample(spark: SparkSession): Unit = {
    //注意：从JDBC源加载数据
    val jdbcPersonDF = spark.read
      .format("jdbc")
      .option("url", "jdbc:mysql://localhost/mydb")
      .option("dbtable", "person")
      .option("user", "root")
      .option("password", "123qwe")
      .load()
    //打印jdbcDF的schema
    jdbcPersonDF.printSchema()
    //打印数据
    jdbcPersonDF.show()

    val connectionProperties = new Properties()
    connectionProperties.put("user", "root")
    connectionProperties.put("password", "123qwe")
    //通过.jdbc的方式加载数据
    val jdbcStudentDF = spark
      .read
      .jdbc("jdbc:mysql://localhost/mydb", "student", connectionProperties)
    //打印jdbcDF的schema
    jdbcStudentDF.printSchema()
    //打印数据
    jdbcStudentDF.show()
    
    // 保存数据到JDBC源
    jdbcStudentDF.write
      .format("jdbc")
      .option("url", "jdbc:mysql://localhost/mydb")
      .option("dbtable", "student2")
      .option("user", "root")
      .option("password", "123qwe")
      .mode(SaveMode.Append)
      .save()

    jdbcStudentDF
      .write
      .mode(SaveMode.Append)
      .jdbc("jdbc:mysql://localhost/mydb", "student2", connectionProperties)
  }
}
```

## 参考
- [Spark DataSource Option 参数](https://blog.csdn.net/An1090239782/article/details/101466076)
- [《Spark 权威指南》](https://snaildove.github.io/2019/10/20/Chapter9_DataSources(SparkTheDefinitiveGuide)_online/)