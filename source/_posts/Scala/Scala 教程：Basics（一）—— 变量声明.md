---
title: Scala 教程：Basics（一）—— 变量声明
date: 2017-08-11 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---

变量声明语法：

```scala
var/val <identifier> [: <type>] = <data>
```

变量声明三要素：

1. 变量：标识指定存储空间和指定类型的标签；
2. 类型：对存储空间中数据的解释方式；
3. 对象：包含数据的存储空间/地址；

变量声明时，如果缺省变量类型，Scala 将通过值的类型来推断变量的类型：

```scala
// 显式声明变量的类型
scala> val x: Int = 1
x: Int = 1
// 隐式类型推断
scala> val x = 1
x: Int = 1
// 同时为多个变量赋以相同的值
scala> val x, y = 1
x: Int = 1
y: Int = 1
// 同时为多个变量赋以不同的值，多个变量必须用小括号包围，右侧元组对象中的元素个数必须与变量个数相同，Scala 会将元组解开，并将其中每个元素分别赋值给不同的变量
scala> val (x, y) = (1, 2)
x: Int = 1
y: Int = 2
```

## 变量
按照是否可以被重新赋值，Scala 中的变量分为两种：

1. value：初始化之后不能再被赋值的变量，虽然 value 一旦被初始化之后就无法再为其赋值，但是如果 value 指向的是一个可变对象，则可以改变对象内部的状态；
2. variable：初始化之后可重新赋值的变量，变量可以被重新赋值，但是不能改变其指定的类型，除非前后类型可以进行隐式转化；

```scala
// 创建一个 val 
scala> val array: Array[String] = new Array(5)
array: Array[String] = Array(null, null, null, null, null)
// 无法对 val 重新赋值
scala> array = new Array(5)
<console>:12: error: reassignment to val
       array = new Array(5)
             ^
// 但如果 val 指向的是一个可变对象，那么可以改变对象内部域状态
scala> array(0) = "a"
scala> array
res7: Array[String] = Array(a, null, null, null, null)

// 创建一个 var
scala> var array: Array[String] = new Array(5)
array: Array[String] = Array(null, null, null, null, null)
// 可以为 var 重新赋值
scala> array = new Array(3)
array: Array[String] = [Ljava.lang.String;@44f338ec
// 但是不能改变 var 的类型
scala> array = new Array[Int](3)
<console>:12: error: type mismatch;
 found   : Array[Int]
 required: Array[String]
       array = new Array[Int](3)
               ^
```

Scala 建议只要有机会，尽量使用val，这有以下几个好处：

1. 有助于减少变量修改所带来的副作用；
2. 让你的代码更加简洁、易读和重构；
3. val 支持等式推理（equational reasoning）：引入的变量等于计算出它的值的表达式，在任何你打算写变量名的地方，都可以直接用表达式来替换；

## 类型
Scala 中所有值都有一个类型，包括数值和函数。与Java不同， Scala中没有基本类型的概念，Scala 中的所有类型，从数字到字符串以至集合，都属于一个类型层次体系：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203102104.png)

- `Any`：是Scala中所有类型的超类型，也称为顶级类型，它定义了一些通用的方法如 `equals`、`hashCode`、`toString`，`Any`有两个直接子类`AnyVal`和`AnyRef`；
- `AnyVal`：所有数值类型的父类，有9个预定义的值类型：`Double`、`Float`、`Long`、`Int`、`Short`、`Byte`、`Char`、`Unit`和 `Boolean`；
- `AnyRef`：所有引用类型的父类；
- 数值类型：包括 Byte Short Int Long Float Double 以及Char Boolean 和Unit，可以在运行时作为对象在堆中分配内存，也可以作为JVM基本类型值在栈中分配内存；
- 引用类型：只能作为对象在堆中分配内存；
- `Unit`：代表空值，用来标识没有返回值的函数，类似于Java中的void；Unit只有一个实例`()`，这个实例也没有实质的意义；
- `Null`：所有引用类型的子类，相当于一个空指针，类似于Java中的null引用; 它有一个单例值由关键字 `null` 所定义。Null 主要是使得 Scala 满足和其他 JVM 语言的互操作性，但是几乎不应该在Scala代码中使用；
- `Nothing`：所有类型的子类，也称为底部类型，它的用途之一是给出非正常终止的信号，如抛出异常、程序退出或者一个无限循环（可以理解为它是一个不对值进行定义的表达式的类型，或者是一个不能正常返回的方法）；

## 对象
Scala 采用了一种纯粹的面向对象的模型，**一切值都是对象，一切操作符都是对象的方法调用，一切代码块都是表达式（有返回值）**：

- 字面值对象：每个字面值都可以被当做一个对象来处理，操作符可以看做是该对象上的方法调用

```scala
scala> 5210000 + 1 * 1024 / 1
res11: Int = 5211024

scala> 5210000.+(1.*(1024./(1)))
res10: Int = 5211024
```

- 类型对象：

- 函数对象：
