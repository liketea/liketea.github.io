---
title: Scala 教程：Collections（二）—— Set
date: 2020-08-04 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---

Set 是不包含重复元素的可迭代对象，Scala 默认使用的是不可变集合，对集合的任何修改都会生成一个新的集合，如果你想使用可变集合，需要引用 scala.collection.mutable.Set 。

## Set 创建
集合的一般创建方式：

```scala
// 创建空 Set
scala> val setImmut = Set()

// 默认创建不可变集合
scala> val setImmut = Set(1,2,3)
scala> println(setImmut.getClass.getName)

// 创建可变集合
scala> import scala.collection.mutable
scala> val setMut = mutable.Set(1,2,3)
scala> println(setMut.getClass.getName)

// 将可变集合转化为不可变集合
scala> val set = setMut.toSet
scala> println(set.getClass.getName)
```

## Set 操作
### 基本操作
集合的任何操作都可以使用以下三个基本操作来表达：

1. `head`：返回集合第一个元素
2. `tail`：返回一个集合，包含除了第一元素之外的其他元素
3. `isEmpty`：在集合为空时返回 true

```scala
scala> val site = Set("Runoob", "Google", "Baidu")
scala> val nums: Set[Int] = Set()

scala> println( "第一网站是 : " + site.head)
scala> println( "最后一个网站是 : " + site.tail)
scala> println( "查看列表 site 是否为空 : " + site.isEmpty)
scala> println( "查看 nums 是否为空 : " + nums.isEmpty)

第一网站是 : Runoob
最后一个网站是 : Set(Google, Baidu)
查看列表 site 是否为空 : false
查看 nums 是否为空 : true
```

### 不可变 Set
不可变 Set 的测、增、删、集合操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215331.png)

```scala
scala> val setA = Set(1,2,3)
scala> val setB = Set(3,4,5)
scala> val setC = Set(1,2,3,4,5)

// 测：判断是否包含某个元素
scala> println(setA.contains(3))
scala> println(setA(3))
// 测：判断是否是另一个集合的子集
scala> println(setA.subsetOf(setC))
true
true
true

// 增：追加单个元素、多个元素、集合
scala> println(setA + 4)
scala> println(setA + (3,4,5))
scala> println(setA ++ Set(3,4) )
Set(1, 2, 3, 4)
Set(5, 1, 2, 3, 4)
Set(1, 2, 3, 4)

// 删：删除单个元素、多个元素、集合
scala> println(setA - 3)
scala> println(setA - (1,2))
scala> println(setA -- setB)
Set(1, 2)
Set(3)
Set(1, 2)

// 删：清空集合
scala> println(setA.empty)
Set()

// 查：返回集合中最小元素
scala> println(setA.min)
1

// 二元操作
scala> println(setA & setB)
scala> println(setA | setB)
scala> println(setA &~ setB)
Set(3)
Set(5, 1, 2, 3, 4)
Set(1, 2)
```

### 可变 Set
可变 Set 支持不可变集合的所有操作，同时还支持对集合的原地修改操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215341.png)

```scala
scala> import scala.collection.mutable
scala> val setA = mutable.Set(1,2,3)
scala> val setB = mutable.Set(3,4,5)
scala> val setC = mutable.Set(1,2,3,4,5)

scala> setA += 4
scala> println(setA)
Set(1, 2, 3, 4)
scala> setA -= 5
scala> println(setA)
Set(1, 2, 3, 4)

scala> setA ++= setB
scala> println(setA)
Set(1, 5, 2, 3, 4)
scala> setA --= setB
scala> println(setA)
Set(1, 2)

scala> setC.retain(x=>x % 2==0)
scala> println(setC)
Set(2, 4)

scala> setB(999) = true
scala> println(setB)
Set(999, 5, 3, 4)
```

对比 Set 和 mutable.Set：

1. 可变集合同样提供了 `+`、`++` 和 `-`、`--` 来添加或删除元素，但很少使用，因为这些操作都需要通过集合拷贝来实现，可变集合提供了更有效的更新方法 `+=`、`++=` 和 `-=`、`--=`，这些方法在集合中添加或删除元素，返回变化后的集合；
2. 不可变集合同样提供了 `+=` 和 `-=` 操作，虽然效果相同，但它们在实现上是不同的，可变集合的`+=`是在可变集合上调用`+=`方法，它会改变s的内容，但不可变类型的`+=`却是赋值操作的简写，它是在集合上应用方法`+`，并把结果赋值给集合变量；这体现了一个重要的原则：**我们通常能用一个非不可变集合的变量(var)来替换可变集合的常量(val)**；
3. 可变集合默认使用哈希表来存储集合元素，不可变集合则根据元素个数不同使用不同的方式来实现元素个数不超过4的集合可以使用单例对象来表达（较小的不可变集合往往会比可变集合更加高效），超过4个元素的不可变集合则使用trie树来实现；

### 可变 Set 和不可变 Set 相互转化
可变 Set 和不可变 Set 可以通过 Seq 作为中间桥梁进行相互转化：

```scala
scala> val set_im = Set(1,2,3)
set_im: scala.collection.immutable.Set[Int] = Set(1, 2, 3)

scala> val set_mm = mutable.Set(1,2,3)
set_mm: scala.collection.mutable.Set[Int] = Set(1, 2, 3)

scala> mutable.Set(set_im.toSeq:_*)
res26: scala.collection.mutable.Set[Int] = Set(1, 2, 3)

scala> Set(set_mm.toSeq:_*)
res27: scala.collection.immutable.Set[Int] = Set(1, 2, 3)
```

## Set 选择
选择一个 Set 比选择一个 Seq 要简单得多，可以直接使用可变与不可变的 Set。SoredSet 是按内容排序存储；LinkedHashSet 是按插入顺序存储；ListSet 可以像使用 List 一样使用，按插入顺序反序存储。


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


## 参考
- [Scala Set(集合)](https://www.runoob.com/scala/scala-sets.html)
- [Scala 集合](https://docs.scala-lang.org/zh-cn/overviews/collections/sets.html)









