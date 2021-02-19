---
title: Scala 教程：Basics（四）—— 控制结构
date: 2020-08-08 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---

> Scala中大多数控制结构都是表达式，有返回值

Scala 只有为数不多的几个内建的控制结构：if、match、for、while、try和函数调用，由于它们有返回值，可以很好地支持函数式编程。

## 条件控制结构

### if表达式
语法：

- `if (<Boolean expression>) <expression>`：返回值是 Any 类型；
- `if (<Boolean expression>) <expression> else <expression>`：返回值的类型是两种结果类型的最近公共父类型；
- `if (<Boolean expression>) <expression> else if (<Boolean expression>) ... else <expression>`：本质上是 `if ... else` 表达式的嵌套，返回值的类型是所有可能返回结果类型的最近公共父类型；

执行：如果布尔表达式成立则执行第一个表达式，否则执行另外一个表达式

示例：

```scala
// if ... 返回值类型必为 Any
scala> if (3<4) 4
res0: AnyVal = 4

// if ... else ... ，返回值的类型是所有可能返回结果类型的最近公共父类型
scala> val x = 1
x: Int = 1

scala> val y = 2
y: Int = 2

scala> if (x > y) x
res1: AnyVal = ()

scala> if (x > y) x else y
res2: Int = 2

// if ... else if ... else ...，本质上是嵌套的 if ... else 表达式
scala> if (2 == 3){
     | 0
     | } else
     | if (2 > 3){
     | 1
     | } else {
     | -1
     | }
res23: Int = -1
```

### match表达式
模式匹配是检查某个值（value）是否匹配某一个模式的机制，它是Java中的switch语句的升级版，同样可以用于替代一系列的 if/else 语句。

语法：

```scala
<expression> match {
    case <pattern> => <expression>
    [case ...]
```

执行：获取输入表达式的**值**，逐一匹配备选模式，匹配成功则执行并返回对应模式后的表达式，匹配不成功则触发MatchError，返回值类型是各个备选结果表达式类型的最近公共父类型。

示例：

```scala
// 对 if (x > y) x else y 的改写
scala> val x = 1; val y = 2
x: Int = 1
y: Int = 2

scala> val max = x > y match {
     | case true => x
     | case false => y
     | }
max: Int = 2
```

变形：match 表达式的变形主要发生在 <pattern>

- 复合模式：使用 `<pattern1> | <pattern2> ...` 可以对多个模式重用 case 块

```scala
scala> "MON" match {
     | case "SAT" | "SUN" => "weekend"
     | case "MON" | "TUE" | "WED" | "THU" | "FRI" =>
     | "weekday"
     | }
res9: String = weekday
```

- 通配模式：使用通配符 `_` 可以匹配任意模式，但是不能在 => 右侧访问通配符

```scala
scala> "MON" match {
     | case "SAT" | "SUN" => "weekend"
     | case _ => "weekday"
     | }
res8: String = weekday
```

- 变量模式：使用一个**模式变量**可以将输入表达式的值绑定到该变量，变量可以在 => 右侧访问

```scala
scala> "MON" match {
     | case "SAT" | "SUN" => "weekend"
     | case x => "weekday" + x
     | }
res10: String = weekdayMON
```

- 类型模式：使用 `模式变量: 类型` 可以匹配输入表达式返回值的具体类型，需要注意的是备选模式的类型必须是输入表达式返回值类型的子类，否则会触发异常：`error: scrutinee is incompatible with pattern type`

```scala
scala> val x: Int = 1
x: Int = 1

scala> val y: Any = x
y: Any = 1

scala> y
res25: Any = 1

scala> y match {
     | case t: Float => "Float"
     | case t: Long => "Long"
     | case t: Int => "Int"
     | case _ => "_"
     | }
res26: String = Int
```

- 哨兵模式：在模式变量后面加上 `if <boolean expression>`，可以为匹配表达式添加匹配条件，只有条件满足时才算匹配成功

```scala
def showImportantNotification(notification: Notification, importantPeopleInfo: Seq[String]): String = {
  notification match {
    case Email(sender, _, _) if importantPeopleInfo.contains(sender) =>
      "You got an email from special someone!"
    case SMS(number, _) if importantPeopleInfo.contains(number) =>
      "You got an SMS from special someone!"
    case other =>
      showNotification(other) // nothing special, delegate to our original showNotification function
  }
}

val importantPeopleInfo = Seq("867-5309", "jenny@gmail.com")

val someSms = SMS("867-5309", "Are you there?")
val someVoiceRecording = VoiceRecording("Tom", "voicerecording.org/id/123")
val importantEmail = Email("jenny@gmail.com", "Drinks tonight?", "I'm free after 5!")
val importantSms = SMS("867-5309", "I'm here! Where are you?")

println(showImportantNotification(someSms, importantPeopleInfo))
println(showImportantNotification(someVoiceRecording, importantPeopleInfo))
println(showImportantNotification(importantEmail, importantPeopleInfo))
println(showImportantNotification(importantSms, importantPeopleInfo))
```

## 循环表达式/语句

### for表达式
Scala 的for表达式是用于迭代的瑞士军刀，每次迭代会执行一个表达式，并返回所有表达式返回值的一个集合（可选）。

语法：enumerators 是一个枚举器，可以包含多个生成器（items <- items）和过滤器（if <expression>）；

```slaca
for (enumerators) [yield] <expression>
```

执行：每次从枚举器中取出一个元素，执行表达式，返回所有返回值构成的一个集合（如果加了 yield 的话）。

示例：

```scala
// 不带 yield，没有返回值
scala> for (i <- 1 to 10) {2 * i}
// 带了yeild，返回所有返回值构成的一个集合
scala> for (i <- 1 to 10) yield {2 * i}
res30: scala.collection.immutable.IndexedSeq[Int] = Vector(2, 4, 6, 8, 10, 12, 14, 16, 18, 20)
```

变形：

- 迭代器哨兵：枚举器中可以包含多个过滤器

```scala
scala> for (i <- 1 to 10 if i % 2 == 0) yield {2 * i}
res32: scala.collection.immutable.IndexedSeq[Int] = Vector(4, 8, 12, 16, 20)

scala> for (i <- 1 to 10 if i % 2 == 0 if i > 5) yield {2 * i}
res33: scala.collection.immutable.IndexedSeq[Int] = Vector(12, 16, 20)
```

- 迭代器嵌套：枚举器中可以包含多个迭代器

```scala
scala>  for {i <- 1 to 10
     |       j <- 1 until 3
     |      if i > j
     |      if i % 2 == 0
     |  } yield {
     |      i + j
     |  }
res37: scala.collection.immutable.IndexedSeq[Int] = Vector(3, 5, 6, 7, 8, 9, 10, 11, 12)
```

- 值绑定：在for循环中使用值绑定，可以把循环的大部分逻辑都集中在定义中，可以得到一个更为简洁的 yield 表达式

```scala
scala> for {
     |     i <- 1 to 8
     |     pow = 1 << i
     | } yield {
     |     pow
     | }
res38: scala.collection.immutable.IndexedSeq[Int] = Vector(2, 4, 8, 16, 32, 64, 128, 256)
```


### while语句
Scala 同样支持 while 和 do/while 循环语句，不过没有 for 表达式那么常用，因为它不是表达式，不能用来返回值。事实上，while 循环和 var通常是一起使用的，要想对程序产生任何效果，while循环通常要么更新一个var要么执行I/O。Scala 没有内建的 break 和 continue 语句，但可以通过 if 表达式来改写。

语法：

```scala
// while
while (Boolean expression) statement
// do ... while
do statement while (Boolean expression)
```

执行：

- while 只要条件为true，循环体就会一遍接着一遍执行；
- do/while：一遍接着一遍执行循环体，直至条件为false

while 和 do/while语句也有自己的用途，比如需要不断读取外部输入知道没有可读的内容为止，不过Scala提供了很多更有表述性且功能更强的方法来处理循环。

## try 表达式
异常传播机制：方法除了正常返回某个值外，也可以通过抛出异常终止执行，方法调用方要么捕获并处理这个异常，要么自我终止，让异常传播到更上层的方法调用方，异常通过这种方式传播，逐个展开调用栈，直至某个方法处理该异常或再没有更多方法为止。

### 抛出异常

语法：

```scala
throw new classException("something")
```

执行：抛出对应类型的异常，返回值类型为Nothing

```scala
scala> throw new IllegalArgumentException("ddfs")
java.lang.IllegalArgumentException: ddfs
  ... 28 elided
```

### 捕获异常
语法：

```scala
try {
    <expression1>
} catch {
    case <pattern1> => <expression2>
    case <pattern2> => <expression3>
} finally {
    <expression4>
}
```

执行：

- try子句：首先执行代码体 <expression1>，如果出现异常则先执行 catch 子句后再执行finally 子句，如果没有异常，则直接执行finally子句
- catch子句：根据try子句抛出的异常，依次尝试匹配每个模式，匹配成功则执行模式后面对应的表达式（使用方式和match表达式一致）
- finally子句：将那些无论是否抛出异常都想执行的代码以表达式的形式包在finally子句里，finally子句一般都是执行清理工作，这是正确关闭非内存资源的惯用做法，比如关闭文件、套接字、数据库连接

返回值：

- 如果没有抛出异常，返回try表达式子句的结果；
- 如果抛出异常且被捕获，则返回对应catch子句的结果；
- 如果抛出异常但没有被捕获，则整个表达式没有结果；
- 如果finally子句包含一个显式地返回语句，则整个表达式会返回finally子句的结果，否则按前三个规则

示例:

```scala
import java.io.FileReader

try {
    val file = new FileReader("input.txt")
    // 使用文件
} catch {
    // 捕获并处理异常
    case e: FileNotFoundException => "未找到对应文件"
    case e: IOException => "处理其他I/O错误" 
} finally {
    // 关闭文件
    file.close()
    // 显式返回一个值
    return 1
}
```

