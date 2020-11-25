---
title: Spark 指南：Spark SQL（六）—— Dataset
date: 2020-11-11 18:51:22
tags: 
   - Spark
categories: 
   - Spark
---

Dataset 是结构化 API 的基本类型，Dataset 是严格的 JVM 语言特性，只能适用 Scala 或 Java。使用 Dataset，你可以定义 Dataset 每一行所包含的对象，这在 Scala 中是一个 case class 对象，在 Java 中，这是一个 Java Bean 对象。有经验的用户通常将 Dataset 称为 Spark 中的 “API 的类型集”（typed set of APIs）。

## Dataset & DataFrame
在 Scala 和 Java 中，DataFrame 只是 Row 类型的 DataSet。使用 Dataset API 时，Spark 编码器会为每一行指定类型，相比使用 DataFrame API 性能较差一些，那为什么还要使用 Dataset 呢，概括起来，可能会有以下三个原因：

1. 当你要执行的操作无法使用 DataFrame 来完成时：虽然这不是很常见，但是你可能想把大段的业务逻辑通过函数来编码，而不是使用 SQL 或者 DataFrame；
2. 当你为了类型安全，宁愿接受较小性能损失时：Dataset API 是类型安全的，类型无效的操作会在编译时而不是运行时失败，如果代码安全是你的最高优先级，Dataset 对你来说会是个不错的选择；
3. 当你想在单节点工作流和 Spark 工作流之间复用转换逻辑时：如果将所有数据和转换定义为接收样例类，那么将它们重用于分布式计算和本地计算就都变得很容易，当你将 Dataset 收集到本地时，它们将具有正确的类型，便于进一步的处理；

可能最流行的用法是串联使用 Dataset 和 DataFrame，在性能和类型安全之间进行手动权衡。

## 创建 Dataset
创建 Dataset 的各种细节详见“结构化对象”一章，在 Scala 中，通常通过样例类来创建 Dataset：

```scala
// 注意样例类的定义不能和使用放在同一个函数内
case class Flight(DEST_COUNTRY_NAME:String,
                  ORIGIN_COUNTRY_NAME:String,
                  count:BigInt)
                  
val ds = spark.read
    .parquet("""data/flight-data/parquet/2010-summary.parquet""")
    .as[Flight]
ds.show(10)
+-----------------+-------------------+-----+
|DEST_COUNTRY_NAME|ORIGIN_COUNTRY_NAME|count|
+-----------------+-------------------+-----+
|    United States|            Romania|    1|
|    United States|            Ireland|  264|
|    United States|              India|   69|
|            Egypt|      United States|   24|
|Equatorial Guinea|      United States|    1|
|    United States|          Singapore|   25|
|    United States|            Grenada|   54|
|       Costa Rica|      United States|  477|
|          Senegal|      United States|   29|
|    United States|   Marshall Islands|   44|
+-----------------+-------------------+-----+

// toDS
import spark.implicits._
case class Person(name: String, age: Long, sex:String)
val ds = Seq(
            Person("Arya", 20, "woman"), 
            Person("Bob", 28, "man"),
            Person("Card", 30, "man")
        ).toDS()
ds.show()
ds.printSchema
+----+---+-----+
|name|age|  sex|
+----+---+-----+
|Arya| 20|woman|
| Bob| 28|  man|
|Card| 30|  man|
+----+---+-----+

root
 |-- name: string (nullable = true)
 |-- age: long (nullable = false)
 |-- sex: string (nullable = true)
```

## Action
适用于 DataFrame 的算子通常也适用于 Dataset：

```scala
ds.first
res6: Person = Person(Arya,20,woman)

ds.first.name
res7: String = Arya

ds.count()
res8: Long = 3

// collect 之后，Dataset 可以通过点操作获取到各字段的值
ds.collect().foreach(p => {
    val name = p.name
    val age = p.age
    val sex = p.sex
    println(s"$name $age $sex")
})
Arya 20 woman
Bob 28 man
Card 30 man
```

## Transformation
Dataset 的转换和我们在 DataFrame 上看到的转换相同，之前了解的任何转换对 Dataset 都有效：

```scala
ds.withColumn("f_concat", concat(col("name"), col("name")))
    .groupBy("f_concat")
    .agg(sum("age").as("sum_age"))
    .filter("sum_age < 30")
    .show()
+--------+-------+
|f_concat|sum_age|
+--------+-------+
|  BobBob|     28|
|AryaArya|     20|
+--------+-------+
```

除了这些转换，Dataset 还允许我们指定更复杂、类型更强的转换，我们可以处理原始的 JVM 类型：

```scala
def manFilter(p:Person):Boolean = {
    return p.sex == "man"
}
ds.filter(r => manFilter(r)).show()
+----+---+---+
|name|age|sex|
+----+---+---+
| Bob| 28|man|
|Card| 30|man|
+----+---+---+

// 函数 manFilter 在 Spark 中与在本地使用方式完全相同
ds.collect().filter(r => manFilter(r))
res24: Array[Person] = Array(Person(Bob,28,man), Person(Card,30,man))

ds.map(p => p.name).show()
+----+
|name|
+----+
|Arya|
| Bob|
|Card|
+----+


```






















