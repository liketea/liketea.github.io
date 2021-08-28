---
title: Scala 教程：Basics（三）—— 操作符&表达式
date: 2020-08-09 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---

> 操作符即方法：操作符和方法只不过是操作的两种语法形式
> >一切操作符都只不过是方法调用的漂亮语法
> >一切方法都可以写作操作符表示法

## 操作符
### Scala中的操作符

- 算术操作符: A 为 10，B 为 20

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101215.png)


- 关系操作符: A 为 10，B 为 20，`==`的实现很用心，大部分场合都能返回给你需要的相等性比较的结果，其背后的规则是：首先检查左侧是否为null，如果不为Null，调用equals方法

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101255.png)


- 逻辑操作符：A 为 true，B 为 false；&& 和 || 遵循短路原则，对应的非短路版本为 & 和 |；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101319.png)


- 位操作符：A = 60; 及 B = 13;

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101351.png)

- 赋值运算符：注意，在Java中赋值语句的返回值是被赋上的值，而在Scala中赋值语句的返回值永远是 Unit类型的单元值`()`

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101416.png)

### 操作符的优先级和结合性
由于Scala并不是真的有操作符，操作符仅仅是用操作符表示法使用方法的一种方式，Scala通过操作符的首字符来决定操作符的优先级，通过操作符的尾字符决定操作符的结合性。

尽管你能够记住这些操作符的优先级，为了使得代码更加易于理解，你只应该在算术操作符合赋值操作符上利用操作符的优先级，其他情形还是老老实实加上括号吧。

#### 操作符的优先级
Scala中操作符的优先级由操作符的**首字符**决定：举例来说，以*开始的操作符优先级比以+开始的操作符优先级更高，下图列出了Scala中不同首字母的操作度的优先级（自上而下，依次递减；同一行具有相同优先级）：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203101638.png)


上面红框分类不是很严谨，只是为了方便记忆，比较两个操作符的优先级的时候这样做：

1. 得到两个操作符的首字符A和B;
2. 看看首字母是属于**算术->关系->逻辑**->字母->赋值中的哪一类；
3. 在以上顺序中，位于前面的优先级高；
4. 记住两个特例：`:`在算术和关系之间，`^`在 `&` 和 `|` 之间；

```scala
// + 的优先级在 < 之上，因而 + 先执行
scala> 2 << 2 + 2
res107: Int = 32
// + 的优先级在赋值操作之上，因而 + 先执行
x *= y + 1 等价于 x *= (y+1)
```

#### 操作符的结合性
当多个同等优先级的操作符并排在一起的时候，操作符的结合性由操作符的尾字符决定：任何以 `:` 结尾的操作符都是在它右侧的操作元调用，传入左侧操作元，以任何其他字符结尾的方法则相反。

```scala
a ::: b ::: c 等价于 a ::: (b:::c)
```

### 任何操作符都是方法调用
Scala中的操作符只是方法调用的漂亮语法，换句话说Scala中所有操作符都可以写作方法调用的形式。

- 中缀操作符：`<operator1> <operate> <operator2>` ，如果是左结合性可以写作 `<operator1>.<operate>(<operator2)`，如果是右结合性可以写作`<operator2>.<operate>(<operator1)`；

```scala
// 1 + 2
scala> 1.+(2)
res108: Int = 3
// 2 << 1
scala> 2.<<(1)
res113: Int = 4
```

- 前缀操作符：只有一元操作符(unary)`+`、`-`、`!`、`~`可以被用作前缀操作符，`<operate> <operator1>` 可以写作 `<operator1>.unary_<operate>`

```scala
// -2.0
scala> (2.0).unary_-
res111: Double = -2.0
//  ! true
scala> true.unary_!
res115: Boolean = false
```

### 任何方法都可以是操作符
Scala中操作符并不是特殊的语法，任何方法都可以是操作符。

- 中缀操作符表示法：`<operator1>.<operate>(<operator2>)` 可以写作 `<operator1> <operate> <operator2>` 

```scala
scala> "hello world".indexOf("w")
res122: Int = 6

scala> "hello world" indexOf "w"
res123: Int = 6

scala> "hello world" indexOf ("o",5)
res125: Int = 7

scala> "hello world".indexOf("o",5)
res126: Int = 7
```

- 后缀操作符表示法：后缀操作符是那些不接受任何参数的方法，在Scala中可以在方法调用时省略空的圆括号，除非方法有副作用，比如println()

```scala
scala> import scala.language.postfixOps
import scala.language.postfixOps

scala> "Hello WOrld" toLowerCase
res130: String = hello world

scala> "Hello WOrld".toLowerCase
res131: String = hello world
```

## 表达式
- 表达式：表达式是执行后会返回一个值的代码单元

```scala
// 一个最简单的表达式
scala> 1
res132: Int = 1
```
- 表达式块：可以用大括号结合多个表达式创建一个表达式块，块中最后一个表达式将作为整个表达式块的返回值，表达式块可以进行嵌套，每个表达式块拥有自己的变量和作用域

```scala
// 表达式块
scala> val amount = {
     | val x = 5 * 20
     | x + 10
     | }
amount: Int = 110
```

- 语句：语句就是不返回值的表达式，语句的返回类型为Unit；由于不返回值，语句通常用来修改现有的数据或者完成应用之外的修改；Scala中常见的语句包括 println()调用、变量声明语句、while控制语句

```scala
scala> println("hello world")
hello world

scala> val a = 1
a: Int = 1
```

表达式为函数式编程提供了基础：表达式可以返回数据而不修改现有数据，这就允许使用不可变数据，函数也可以用来返回新的数据，在某种意义上这种函数是另一种类型的表达式。
