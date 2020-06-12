---
title: Scala 教程（六）：集合框架
date: 2019-12-04 18:01:33
tags:
    - Scala
    - 教程
categories:
    - Scala
---
# scala 教程（六）—— 集合框架
> 两个维度（可变、不可变）-> 三种容器（序列、集合、映射）-> 多种实现
> 常见操作：创建、增删改查、拆分合并、测试、转换、迭代、mapreduce

Scala 2.8 的集合框架有以下特点：

1. 易用：使用20~50个方法的词汇量就足以解决大部分的集合问题；
2. 简洁：可以通过单独的一个词来执行一个或多个循环；
3. 安全：Scala集合的静态类型和函数性质意味着在编译时就可以捕获绝大多数错误；
4. 快速：集合操作已经在类库中优化过；
5. 通用：集合类提供了在一些类型上的相同操作；

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


## 序列（Seq）
序列是有序的可迭代对象。序列的操作有以下几种：

1. **索引和长度的操作** apply、isDefinedAt、length、indices，及lengthCompare。序列的apply操作用于索引访问；因此，Seq[T]类型的序列也是一个以单个Int（索引下标）为参数、返回值类型为T的偏函数。换言之，Seq[T]继承自Partial Function[Int, T]。序列各元素的索引下标从0开始计数，最大索引下标为序列长度减一。序列的length方法是collection的size方法的别名。lengthCompare方法可以比较两个序列的长度，即便其中一个序列长度无限也可以处理。
2. **索引检索操作**（indexOf、lastIndexOf、indexofSlice、lastIndexOfSlice、indexWhere、lastIndexWhere、segmentLength、prefixLength）用于返回等于给定值或满足某个谓词的元素的索引。
3. **加法运算**（+:，:+，padTo）用于在序列的前面或者后面添加一个元素并作为新序列返回。
4. **更新操作**（updated，patch）用于替换原序列的某些元素并作为一个新序列返回
5. **排序操作**（sorted, sortWith, sortBy）根据不同的条件对序列元素进行排序。
6. **反转操作**（reverse, reverseIterator, reverseMap）用于将序列中的元素以相反的顺序排列。
7. **比较**（startsWith, endsWith, contains, containsSlice, corresponds）用于对两个序列进行比较，或者在序列中查找某个元素。
8. **多集操作**（intersect, diff, union, distinct）用于对两个序列中的元素进行类似集合的操作，或者删除重复元素。

Seq 在 Iterator 的基础上添加了其他一些操作 ：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215120.png)


`Seq trait` 具有三个子特征（subtrait）：

- 线性序列（LinearSeq）：不添加新的操作，具有高效的 head 和 tail 操作，常用线性序列有 `scala.collection.immutable.List` 和 `scala.collection.immutable.Stream`；
- 索引序列（IndexedSeq）：不添加新的操作，具有高效的apply, length, 和 (如果可变) update操作，常用索引序列有 `scala.collection.mutable.ArrayBuffer` 和 `scala.collection.immutable.Vector`；
- 缓冲器（Buffer）：缓冲器允许对现有元素进行增、删、改操作，常用的Buffer序列有 `ListBuffer` 和 `ArrayBuffer`，Buffer 在 Seq 的基础上增加了一些添加和删除的操作；

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215318.png)

## 集合（Set）
集合是不包含重复元素的可迭代对象。

- Set 类的操作：测试、加、减、集合操作

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215331.png)

- mutable.Set 类的操作：增、删、改。

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215341.png)

对比 Set 和 mutable.Set：

1. 可变集合同样提供了 `+`、`++` 和 `-`、`--` 来添加或删除元素，但很少使用，因为这些操作都需要通过集合拷贝来实现，可变提盒提供了更有效的更新方法 `+=`、`++=` 和 `-=`、`--=`，这些方法在集合中添加或删除元素，返回变化后的集合；
2. 不可变集合同样提供了 `+=` 和 `-=` 操作，虽然效果相同，但它们在实现上是不同的，可变集合的`+=`是在可变集合上调用`+=`方法，它会改变s的内容，但不可变类型的`+=`却是赋值操作的简写，它是在集合上应用方法`+`，并把结果赋值给集合变量；这体现了一个重要的原则：我们通常能用一个非不可变集合的变量(var)来替换可变集合的常量(val)；
3. 可变集合默认使用哈希表来存储集合元素，不可变集合则根据元素个数不同使用不同的方式来实现元素个数不超过4的集合可以使用单例对象来表达（较小的不可变集合往往会比可变集合更加高效），超过4个元素的不可变集合则使用trie树来实现；

集合的两个特质：

1. 有序集（SortedSet）：以特定顺序排列其中元素的集合，有序集默认通过二叉排序树实现，`immutable.TreeSet`使用红黑树实现；
2. 位集合（BitSet）：BitSet是由单Bit或多Bit的位实现的非负整数集合；

## 映射（Map）
映射是一种由键值对构成的可迭代对象。Scala的Predef类提供了隐式转换，允许使用另一种更易于阅读的语法`key -> vale`来代替`(key, value)`。

Map 类的操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215353.png)

mutable.Map 类还支持额外的操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215409.png)


## 元组（Tuple）
元组是一个异构、不可变的有序容器。元组存在的意义只是作为一个容纳多个值的容器，这可以免去创建那些简单的主要用于承载数据的类的麻烦.用户有时可能在元组和 case 类之间难以选择，通常，如果元素具有更多含义，则首选 case 类。

### 创建元组
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

## 选项（Option）
值 `null` 通常被滥用来表征一个可能会缺失的值，Java 开发者一般都知道 `NullPointerException`， 通常这是由于某个方法返回了 `null` ，但这并不是开发者所希望发生的，代码也不好去处理这种异常。

在Scala中，` Option` 是 `null` 值的安全替代：`Option[A]` 是一个类型为 `A` 的可选值的容器，如果值存在，Option[A] 返回一个 Some[A] ，如果不存在， Option[A] 返回对象 `None`。在类型层面上指出一个值是否存在，使用你的代码的开发者（也包括你自己）就会被编译器强制去处理这种可能性， 而不能依赖值存在的偶然性。

### 创建Option
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

### Option 的模式匹配
用模式匹配处理 Option 实例是非常啰嗦的，这也是它非惯用法的原因。 所以，即使你很喜欢模式匹配，也尽量用其他方法吧：

```scala
scala> val x: Option[String] = Option(null)
x: Option[String] = None

scala> x match {
     | case Some(xx) => xx
     | case None => "Nothing"
     | }
res12: String = Nothing
```
### Option 的常用方法

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191204180608.png)

虽然在类型层次上， Option 并不是 Scala 的集合类型， 但，凡是你觉得 Scala 集合好用的方法， Option 也有， 你甚至可以将其转换成一个集合，比如说 List。


### for 语句
用 for 语句来处理 Option 是可读性最好的方式，尤其是当你有多个 map 、flatMap 、filter 调用的时候。 如果只是一个简单的 map 调用，那 for 语句可能有点繁琐。

```scala
scala> val x: Option[Int] = Some(1)
x: Option[Int] = Some(1)

scala> for (t <- x) println(t)
1

scala> val y: Option[Int] = None
y: Option[Int] = None

scala> for (t <- y) println(t)

```

## 选择合适的集合类
Scala 中具体的容器类主要有三大类：

- 序列（Seq）：有序的可迭代对象，可以通过索引序列或线性序列来实现；
- 集合（Set）：不含重复元素的可迭代对象，通过哈希表实现；
- 映射（Map）：由键值对构成的可迭代对象；

不同的容器类型具有不同的性能特点，这通常是选择容器类型的首要依据。
### 选择合适的 Seq
选择一个 Seq 的时候，你需要考虑两件事：

1. 选择线性序列还是索引序列：线性序列方便头尾操作、索引序列方便随机存取；
2. 选择可变序列还是不可变序列：可变序列方便原地修改、不可变序列安全无副作用；

Scala 中对于 Seq，针对数组／链表，可变／不可变的组合，推荐使用以下四种通用容器类：

|       | Immutable | Mutable |
| ---   | ---       | ---     |
| Linear (Linked lists) | List | ListBuffer |
| Indexed | Vector | ArrayBuffer |


主要的不可变序列：


|  | IndexedSeq | LinearSeq | Description |
| --- | :-: | :-: | --- |
| List |  | ✓ |  A singly linked list. Suited for recursive algorithms that work by splitting the head from the remainder of the list.|
| Queue |  | ✓ |  A first-in, first-out data structure.|
| Range | ✓ |  |  A range of integer values. |
| Stack |  | ✓ |  A last-in, first-out data structure. |
| Stream |  | ✓ |  Similar to List, but it’s lazy and persistent. Good for a large or infinite sequence, similar to a Haskell List. |
| String | ✓ |  |  Can be treated as an immutable, indexed sequence of characters.|
| Vector | ✓ |  |  The “go to” immutable, indexed sequence. The Scaladoc describes it as, “Implemented as a set of nested arrays that’s efficient at splitting and joining.”|

主要的可变序列：

|  | IndexedSeq | LinearSeq | Description |
| --- | :-: | :-: | --- |
| Array | ✓ |  | Backed by a Java array, its elements are mutable, but it can’t change in size. |
| ArrayBuffer | ✓ |  |  The “go to” class for a mutable, sequential collection. The amortized cost for appending elements is constant.|
| ArrayStack | ✓ |  | A last-in, first-out data structure. Prefer over Stack when performance is important. |
| DoubleLinkedList |  | ✓ | Like a singly linked list, but with a prev method as well. The documentation states, “the additional links make element removal very fast.” |
| LinkedList |  | ✓ | A mutable, singly linked list. |
| ListBuffer |  | ✓ | Like an ArrayBuffer, but backed by a list. The documentation states, “If you plan to convert the buffer to a list, use ListBuffer instead of ArrayBuffer.” Offers constant-time prepend and append; most other operations are linear. |
| MutableList |  | ✓ | A mutable, singly linked list with constant-time append. |
| Queue |  | ✓ | A first-in, first-out data structure. |
| Stack |  | ✓ | A last-in, first-out data structure. (The documentation suggests that an ArrayStack is slightly more efficient.) |
| StringBuilder | ✓ |  | Used to build strings, as in a loop. Like the Java StringBuilder. |


序列类型常用操作的性能特点：

| 类型        | 具体类型          | head | tail | apply | update | prepend | append | insert |
|-----------|---------------|------|------|-------|--------|---------|--------|--------|
| immutable | List          | C    | C    | L     | L      | C       | L      | \-     |
| immutable | Stream        | C    | C    | L     | L      | C       | L      | \-     |
| immutable | Vector        | eC   | eC   | eC    | eC     | eC      | eC     | \-     |
| immutable | Stack         | C    | C    | L     | L      | C       | L      | L      |
| immutable | Queue         | aC   | aC   | L     | L      | C       | C      | \-     |
| immutable | Range         | C    | C    | C     | \-     | \-      | \-     | \-     |
| immutable | String        | C    | L    | C     | L      | L       | L      | \-     |
| mutable   | ArrayBuffer   | C    | L    | C     | C      | L       | aC     | L      |
| mutable   | ListBuffer    | C    | L    | L     | L      | C       | C      | L      |
| mutable   | StringBuilder | C    | L    | C     | C      | L       | aC     | L      |
| mutable   | MutableList   | C    | L    | L     | L      | C       | C      | L      |
| mutable   | Queue         | C    | L    | L     | L      | C       | C      | L      |
| mutable   | ArraySeq      | C    | L    | C     | C      | \-      | \-     | \-     |
| mutable   | Stack         | C    | L    | L     | L      | C       | L      | L      |
| mutable   | ArrayStack    | C    | L    | C     | C      | aC      | L      | L      |
| mutable   | Array         | C    | L    | C     | C      | \-      | \-     | \-     |


其中，时间复杂度符号解释如下：

| 符号  | 说明                                               |
|-----|--------------------------------------------------|
| C   | 指操作的时间复杂度为常数                                     |
| eC  | 指操作的时间复杂度实际上为常数，但可能依赖于诸如一个向量最大长度或是哈希键的分布情况等一些假设。 |
| aC  | 该操作的均摊运行时间为常数。某些调用的可能耗时较长，但多次调用之下，每次调用的平均耗时是常数。  |
| Log | 操作的耗时与容器大小的对数成正比。                                |
| L   | 操作是线性的，耗时与容器的大小成正比。                              |
| \-  | 操作不被支持。                                          |

序列操作说明：

| 操作      | 说明                                               |
|---------|--------------------------------------------------|
| head    | 选择序列的第一个元素。                                      |
| tail    | 生成一个包含除第一个元素以外所有其他元素的新的列表。              |
| apply   | 索引。                                              |
| update  | 功能性更新不可变序列，同步更新可变序列。                             |
| prepend | 添加一个元素到序列头。对于不可变序列，操作会生成个新的序列。对于可变序列，操作会修改原有的序列。 |
| append  | 在序列尾部插入一个元素。对于不可变序列，这将产生一个新的序列。对于可变序列，这将修改原有的序列。 |
| insert  | 在序列的任意位置上插入一个元素。只有可变序列支持该操作。                |


### 选择合适的 Set
选择一个 Set 比选择一个Seq要简单多，可以直接使用可变与不可变的Set。SoredSet是按内容排序存储；LinkedHashSet是按插入顺序存储；ListSet可以想使用List一样使用，按插入顺序反序存储。


|  | Immutable | Mutable | Description |
| --- | :-: | :-: | --- |
| BitSet | ✓ | ✓ | A set of “non-negative integers represented as variable-size arrays of bits packed into 64-bit words.” Used to save memory when you have a set of integers. |
| HashSet | ✓ | ✓ | The immutable version “implements sets using a hash trie”; the mutable version “implements sets using a hashtable.” |
| LinkedHashSet |  | ✓ | A mutable set implemented using a hashtable. Returns elements in the order in which they were inserted. |
| ListSet | ✓ |  | A set implemented using a list structure. |
| TreeSet | ✓ | ✓ | The immutable version “implements immutable sets using a tree.” The mutable version is a mutable SortedSet with “an immutable AVL Tree as underlying data structure.” |
| Set | ✓ | ✓ | Generic base traits, with both mutable and immutable implementations. |
| SortedSet | ✓ | ✓ | A base trait. (Creating a variable as a SortedSet returns a TreeSet.) |

集合和映射类型常用操作的性能特点：

| 是否可变类型    | 具体类型            | lookup | add | remove | min |
|-----------|-----------------|--------|-----|--------|-----|
| immutable | HashSet/HashMap | eC     | eC  | eC     | L   |
| immutable | TreeSet/TreeMap | Log    | Log | Log    | Log |
| immutable | BitSet          | C      | L   | L      | eC1 |
| immutable | ListMap         | L      | L   | L      | L   |
| mutable   | HashSet/HashMap | eC     | eC  | eC     | L   |
| mutable   | WeakHashMap     | eC     | eC  | eC     | L   |
| mutable   | BitSet          | C      | aC  | C      | eC1 |
| mutable   | TreeSet         | Log    | Log | Log    | Log |

操作说明：

| 操作     | 说明                             |
|--------|--------------------------------|
| lookup | 测试一个元素是否被包含在集合中，或者找出一个键对应的值    |
| add    | 添加一个新的元素到一个集合中或者添加一个键值对到一个映射中。 |
| remove | 移除一个集合中的一个元素或者移除一个映射中一个键。      |
| min    | 集合中的最小元素，或者映射中的最小键。            |


### 选择合适的 Map
Map 像 Set 一样，可以直接使用可变的和不可变的Map。SortedMap不可变但是其内容是按key值排序的；LinkedHashMap是可变的，其内容按插入的顺序存储；ListMap则是按插入顺序反序存储；TreeMap是使用红黑树存储。


|  | Immutable | Mutable | Description |
| --- | :-: | :-: | --- |
| HashMap | ✓ | ✓ | The immutable version “implements maps using a hash trie”; the mutable version “implements maps using a hashtable.” |
| LinkedHashMap |  | ✓ | “Implements mutable maps using a hashtable.” Returns elements by the order in which they were inserted. |
| ListMap | ✓ | ✓ | A map implemented using a list data structure. Returns elements in the opposite order by which they were inserted, as though each element is inserted at the head of the map. |
| Map | ✓ | ✓ | The base map, with both mutable and immutable implementations. |
| SortedMap | ✓ |  | A base trait that stores its keys in sorted order. (Creating a variable as a SortedMap currently returns a TreeMap.) |
| TreeMap | ✓ |  | An immutable, sorted map, implemented as a red-black tree. |
| WeakHashMap |  | ✓ | A hash map with weak references, it’s a wrapper around java.util.WeakHashMap. |


## 参考

[Mutable和Immutable集合](https://docs.scala-lang.org/zh-cn/overviews/collections/introduction.html)

[类型 Option](https://windor.gitbooks.io/beginners-guide-to-scala/content/chp5-the-option-type.html)