---
title: Scala 教程：Collections（〇）—— 集合框架
date: 2020-08-06 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---

Scala 2.8 的集合框架有以下特点：

1. 易用：使用 20~50 个方法的词汇量就足以解决大部分的集合问题；
2. 简洁：可以通过单独的一个词来执行一个或多个循环；
3. 安全：Scala 集合的静态类型和函数性质意味着在编译时就可以捕获绝大多数错误；
4. 快速：集合操作已经在类库中优化过；
5. 通用：集合类提供了在一些类型上的相同操作；

Seq、Map、Set 是 Scala 最重要的三种集合类（容器），此外还有 Tuple、Option 等，这些会在后面小节逐一讲解，本节将按照自顶向下的层级结构来学习不同集合类的通用特性。

## 可变/不可变类型（Mutable/Immutable）
Scala 集合框架系统地区分了可变的(mutable)和不可变的(immutable)集合，并且可以很方便地在两者之间进行转换。你可以对可变集合中的元素进行增、删、改操作，你也可以对不可变类型模拟这些操作，但每个操作都会返回一个新的集合，原来的集合不会发生改变。

### 集合类的继承树
Scala 所有集合类都可以在以下包中找到：

-  `scala.collection`：包中的集合既可以是可变的也可以是不可变的，下图展示了这个包中所有的集合类，这些都是高级抽象类或特质，它们通常有可变和不可变两种实现方式

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203214821.png)


- `scala.collection.immutable` ：包中的集合类是不可变的，Scala会默认导入这个包，这意味着Scala默认使用不可变集合类，当你写下 Set 而没有加任何前缀，你会得到一个不可变的 Set，下图展示了这个包中所有的集合类

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191204221225.png)

- `scala.collection.mutable`：包中的集合类是可变的，如果你想要使用可变的集合类，通用的做法是导入`scala.collection.mutable`包即可，当你使用没有前缀的 Set 时仍然指的是一个不可变集合，当你使用 `mutable.Set`时指的是可变的集合类，下图展示了这个包中所有的集合类

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215029.png)

- `scala.collection.generic`：包含了集合的构建块，集合类延迟了`collection.generic` 类中的部分操作实现

### 集合类的通用方法
Scala 中的集合类有以下通用方法：

- 集合创建：每一种集合都可以通过在集合类名后紧跟元素的方式进行创建

```scala
Traversable(1, 2, 3)
Iterable("x", "y", "z")
Map("x" -> 24, "y" -> 25, "z" -> 26)
Set(Color.red, Color.green, Color.blue)
SortedSet("hello", "world")
Buffer(x, y, z)
IndexedSeq(1.0, 2.0)
LinearSeq(a, b, c)
List(1, 2, 3)
HashMap("x" -> 24, "y" -> 25, "z" -> 26)
```

- toString：所有集合类都可以用toString的方式进行打印；
- 返回类型一致原则：所有集合类的map方法都会返回相同类型的集合类，例如，在一个List上调用map会又生成一个List，在Set上调用会再生成一个Set，以此类推；
- 大多数类在集合树种都存在三种变体：root、mutable、immutable；

## 可遍历特质（Trait Traversable）
可遍历（Traversable）是容器（collection）类的最高级别特质，它唯一的抽象操作是`foreach`。`foreach` 是 `Traversable` 所有操作的基础，用于遍历容器中所有元素，并对每个元素进行指定的操作：

```scala
// Elem 是容器中元素的类型，U是一个任意的返回值类型，对f的调用仅仅是容器遍历的副作用，实际上所有计算结果都被foreach抛弃（没有返回值）
def foreach[U](f: Elem => U)
```

要实现 Traversable 的容器类仅需要定义与之相关的方法，其他所有方法都可以从 Traversable 中继承，Traversable 定义了许多方法：

1. **相加操作++（addition）**表示把两个traversable对象附加在一起或者把一个迭代器的所有元素添加到traversable对象的尾部
2. **Map操作**有map，flatMap和collect，它们可以通过对容器中的元素进行某些运算来生成一个新的容器
3. **转换器（Conversion）操作**包括toArray，toList，toIterable，toSeq，toIndexedSeq，toStream，toSet，和toMap，它们可以按照某种特定的方法对一个Traversable 容器进行转换
4. **拷贝（Copying）操作**有copyToBuffer和copyToArray。从字面意思就可以知道，它们分别用于把容器中的元素元素拷贝到一个缓冲区或者数组里
5. **Size info**操作包括有isEmpty，nonEmpty，size和hasDefiniteSize
6. **元素检索（Element Retrieval）操作**有head，last，headOption，lastOption和find。这些操作可以查找容器的第一个元素或者最后一个元素，或者第一个符合某种条件的元素。注意，尽管如此，但也不是所有的容器都明确定义了什么是“第一个”或”最后一个“。例如，通过哈希值储存元素的哈希集合（hashSet），每次运行哈希值都会发生改变。在这种情况下，程序每次运行都可能会导致哈希集合的”第一个“元素发生变化。如果一个容器总是以相同的规则排列元素，那这个容器是有序的。大多数容器都是有序的，但有些不是（例如哈希集合）– 排序会造成一些额外消耗。排序对于重复性测试和辅助调试是不可或缺的。这就是为什么Scala容器中的所有容器类型都把有序作为可选项。例如，带有序性的HashSet就是LinkedHashSet
7. **子容器检索（sub-collection Retrieval）操作**有tail，init，slice，take，drop，takeWhilte，dropWhile，filter，filteNot和withFilter。它们都可以通过范围索引或一些论断的判断返回某些子容器
8. **拆分（Subdivision）操作**有splitAt，span，partition和groupBy，它们用于把一个容器（collection）里的元素分割成多个子容器
9. **元素测试（Element test）**包括有exists，forall和count，它们可以用一个给定论断来对容器中的元素进行判断
10. **折叠（Folds）操作**有foldLeft，foldRight，/:，:\，reduceLeft和reduceRight，用于对连续性元素的二进制操作
11. **特殊折叠（Specific folds）**包括sum, product, min, max。它们主要用于特定类型的容器（数值或比较）
12. **字符串（String）操作**有mkString，addString和stringPrefix，可以将一个容器通过可选的方式转换为字符串
13. **视图（View）操作**包含两个view方法的重载体。一个view对象可以当作是一个容器客观地展示

Traversable对象的操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215045.png)

可以选择使用操作符记法，也可以选择点记法，这取决于个人喜好，但是没有参数的方法除外，这时必须使用点记法，为了一致性推荐使用点记法。

## 可迭代特质（Trait Iterable）
可迭代是容器类的另一个特质，这个特质里所有方法的定义都基于一个抽象方法`iterator`，从`Traversable Trait`中继承来的foreach方法在这里也是利用 `iterator` 来实现的：

```scala
def foreach[U](f: Elem => U): Unit = {
  val it = iterator
  while (it.hasNext) f(it.next())
}
```

Iterator 有两个方法返回迭代器：grouped和sliding，这些迭代器返回的不是单个元素，而是原容器元素的全部子序列，grouped方法返回元素的增量分块，sliding方法生成一个滑动元素的窗口：

```scala
scala> val xs = List(1, 2, 3, 4, 5)
xs: List[Int] = List(1, 2, 3, 4, 5)
scala> val git = xs grouped 3
git: Iterator[List[Int]] = non-empty iterator
scala> git.next()
res3: List[Int] = List(1, 2, 3)
scala> git.next()
res4: List[Int] = List(4, 5)
scala> val sit = xs sliding 3
sit: Iterator[List[Int]] = non-empty iterator
scala> sit.next()
res5: List[Int] = List(1, 2, 3)
scala> sit.next()
res6: List[Int] = List(2, 3, 4)
scala> sit.next()
res7: List[Int] = List(3, 4, 5)
```

Iterator 在 Traversable 的基础上添加了一些其他方法：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215057.png)


## 参考

[Mutable和Immutable集合](https://docs.scala-lang.org/zh-cn/overviews/collections/introduction.html)

[类型 Option](https://windor.gitbooks.io/beginners-guide-to-scala/content/chp5-the-option-type.html)