---
title: Scala 教程：Collections（四）—— Tuple
date: 2020-08-02 16:00:09
tags:
    - Scala
    - 教程
categories:
    - Scala
---

元组（Tuple）是一个异构、不可变的有序容器。元组存在的意义只是作为一个容纳多个值的容器，这可以免去创建那些简单的主要用于承载数据的类的麻烦.用户有时可能在元组和 case 类之间难以选择，通常，如果元素具有更多含义，则首选 case 类。

## 元组创建
可以通过三种方式创建一个元组：

- 通过用逗号分隔的值写入值，并用一对括号括起来

```scala
scala> val t = (1, 1.2, 'h', "hello")
t: (Int, Double, Char, String) = (1,1.2,h,hello)
```

- 通过 `Tuplen` 类创建元组对象：

```scala
scala> val t3 = Tuple3(1, 1.2, "hello")
t3: (Int, Double, String) = (1,1.2,hello)
```

- 通过使用关系运算符 `->`创建二元组：

```scala
scala> val t = 'a' -> 1
t: (Char, Int) = (a,1)
```

Scala 中的元组包含一系列类：`Tuple2、Tuple3 ... Tuple22`，目前 Scala 支持的元组最大长度为 22。当我们创建一个包含 n 个元素（n 位于 2 和 22 之间）的元组时，Scala 基本上就是从上述的一组类中实例化一个相对应的类，使用组成元素的类型进行参数化；对于更大长度你可以使用集合，或者扩展元组。

## 元组操作
### 访问元素
使用下划线语法 `tuple._n` 可以取出第 n 个元素（假设有足够多元素）：

```scala
scala> t3._2
res0: Double = 1.2
```

### 解构元组
Scala 元组也支持解构：

```scala
scala> val (a, b, c) = t3
a: Int = 1
b: Double = 1.2
c: String = hello
```

元组解构也可用于模式匹配：

```scala
val planetDistanceFromSun = List(("Mercury", 57.9), ("Venus", 108.2), ("Earth", 149.6 ), ("Mars", 227.9), ("Jupiter", 778.3))
planetDistanceFromSun.foreach{ tuple => {
  tuple match {
      case ("Mercury", distance) => println(s"Mercury is $distance millions km far from Sun")
      case p if(p._1 == "Venus") => println(s"Venus is ${p._2} millions km far from Sun")
      case p if(p._1 == "Earth") => println(s"Blue planet is ${p._2} millions km far from Sun")
      case _ => println("Too far....")
    }
  }
}

Mercury is 57.9 millions km far from Sun
Venus is 108.2 millions km far from Sun
Blue planet is 149.6 millions km far from Sun
Too far....
Too far....
```

### 迭代元组
元组无法直接进行迭代，但可以通过Tuple.productIterator() 方法来迭代：

```scala
scala> t3.productIterator.foreach{ i => println("Value = " + i )}
Value = 1
Value = 1.2
Value = hello
```
