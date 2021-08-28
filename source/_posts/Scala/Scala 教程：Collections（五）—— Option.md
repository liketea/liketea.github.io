---
title: Scala 教程：Collections（五）—— Option
date: 2020-08-01 16:00:10
tags:
    - Scala
    - 教程
categories:
    - Scala
---

值 `null` 通常被滥用于表征一个可能会缺失的值，Java 开发者一般都知道 `NullPointerException`，通常这是由于某个方法返回了 `null` ，但这并不是开发者所希望发生的，代码也不好去处理这种异常。

在Scala中，`Option` 是 `null` 值的安全替代：`Option[A]` 是一个类型为 `A` 的可选值的容器，如果值存在，Option[A] 返回一个 Some[A] ，如果不存在， Option[A] 返回对象 `None`。在类型层面上指出一个值是否存在，使用你的代码的开发者（也包括你自己）就会被编译器强制去处理这种可能性，而不能依赖值存在的偶然性。

## Option 创建
- 可以通过直接实例化 `Some` 样例类来创建一个 `Option`，或者在知道值缺失时，直接使用 `None` 对象：

```scala
scala> val a: Option[Int] = None
a: Option[Int] = None

scala> val b: Option[Int] = Some(1)
b: Option[Int] = Some(1)
```

- 在实际工作中，不可避免地要去操作一些 Java 库，或者是其他将 null 作为缺失值的JVM 语言的代码，为此， Option 伴生对象提供了一个工厂方法，可以根据给定的参数创建相应的 Option：

```scala
scala> val c: Option[String] = Option(null)
c: Option[String] = None

scala> val d: Option[String] = Option("hello")
d: Option[String] = Some(hello)
```
## Option 操作
### 从 Option 抽取值
有多种方法从 Option 中抽取值：

- get 属性：如果值存在，则返回值，如果不存在，则报错

```scala
scala> println("a.get: " + a.get)
java.util.NoSuchElementException: None.get
  at scala.None$.get(Option.scala:366)
  at scala.None$.get(Option.scala:364)
  ... 28 elided

scala> println("b.get: " + b.get)
b.get: 1
```

- getOrElse() 方法：如果值存在，则返回值，如果不存在，则返回默认值

```scala
scala> println("a.getOrElse(0): " + a.getOrElse(0) )
a.getOrElse(0): 0

scala> println("b.getOrElse(10): " + b.getOrElse(10) )
b.getOrElse(10): 1
```

- 模式匹配：用模式匹配处理 Option 实例是非常啰嗦的，这也是它非惯用法的原因。所以，即使你很喜欢模式匹配，也尽量用其他方法吧

```scala
scala> a match {
     |  case Some(xx) => xx
     |  case None => "Nothing"
     |  }
res8: Any = Nothing

scala> b match {
     |  case Some(xx) => xx
     |  case None => "Nothing"
     |  }
res9: Any = 1
```


### 作为集合的 Option

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191204180608.png)

你可以把 Option 看作是某种集合，这个特殊的集合要么只包含一个元素，要么就什么元素都没有。虽然在类型层次上，Option 并不是 Scala 的集合类型，但凡是你觉得 Scala 集合好用的方法， Option 也有，你甚至可以将其转换成一个集合，比如说 List。


```scala
// 使用 .foreach 
scala> a.foreach(x => println(x))

scala> b.foreach(x => println(x))
1

// 使用 map
scala> a.map(x => x+100)
res13: Option[Int] = None
scala> b.map(x => x+100)
res11: Option[Int] = Some(101)

// 使用 flatMap，如果用 map 将 x 映射为 Option 类型的值，映射结果类型就编程了嵌套 Option 类型，可以使用 flatMap 将结果打平，最终结果仍是 Option 类型
scala> a.map(x=>Option(1))
res2: Option[Option[Int]] = None

scala> b.map(x=>Option(1))
res3: Option[Option[Int]] = Some(Some(1))

scala> a.flatMap(x=>Option(1))
res6: Option[Int] = None      

scala> b.flatMap(x=>Option(1))
res5: Option[Int] = Some(1)

// 使用 filter
scala> a.filter(_ > 30)
res16: Option[Int] = None
scala> b.filter(_ > 30)
res17: Option[Int] = None
scala> b.filter(_ < 30)
res18: Option[Int] = Some(1)

// 使用 isEmpty() 方法来检测元组中的元素是否为 None
scala> println("a.isEmpty: " + a.isEmpty )
scala> println("b.isEmpty: " + b.isEmpty )
a.isEmpty: false
b.isEmpty: true

// 使用 for
scala> for (t <- a) println(t)

scala> for (t <- b) println(t)
1
```

## 参看
[Scala 初学者指南](https://windor.gitbooks.io/beginners-guide-to-scala/content/chp5-the-option-type.html)