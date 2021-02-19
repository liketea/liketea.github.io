---
title: Scala 教程：Collections（三）—— Map
date: 2020-08-03 16:00:08
tags:
    - Scala
    - 教程
categories:
    - Scala
---

Map 是一种由键值对构成的可迭代对象，Scala 默认使用的是不可变 map，对 map 的任何修改都会生成一个新的 map，如果你想使用可变 map，需要引用 scala.collection.mutable.Map。 

## Map 创建

Map 的一般创建方式：

```scala
// 创建空 Map
scala> var A:Map[Char,Int] = Map()
// 通过（k, v）二元组创建 Map
scala> val colors1 = Map(("red", "#FF0000"),
                         ("azure", "#F0FFFF"),
                         ("peru", "#CD853F"))
// Scala 的 Predef 类提供了隐式转换，允许使用`key -> vale`来代替`(key, value)`
scala> val colors2 = Map("blue" -> "#0033FF",
                         "yellow" -> "#FFFF00",
                         "red" -> "#FF0000")
// 如果需要使用可变 Map，需要引用 scala.collection.mutable.Map
import scala.collection.mutable
val colors = mutable.Map("red" -> "#FF0000", "azure" -> "#F0FFFF")
```

## Map 操作
### 基本操作
Scala Map 有三个基本操作：

1. `keys`：返回 Map 所有的键(key)
2. `values`：返回 Map 所有的值(value)
3. `isEmpty`：在 Map 为空时返回 true

```scala
scala> val colors = Map("red" -> "#FF0000",
                        "azure" -> "#F0FFFF",
                        "peru" -> "#CD853F")

scala> println( "colors 中的键为 : " + colors.keys )
scala> println( "colors 中的值为 : " + colors.values )
scala> println( "检测 colors 是否为空 : " + colors.isEmpty )
```

### 不可变 Map
不可变 Map 的增、删、查、集操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215353.png)

- 查询：

```scala
// 查询键对应的值：返回一个 Option，如果 key 存在，返回 Some(value)，否则返回 None
scala> println(colors1.get("red"))
scala> println(colors1.get("black"))
Some(#FF0000)
None

// 查询键对应的值：如果 key 存在，返回对应的 value，否则报错
scala> println(colors1("red"))
scala> println(colors1("black"))
#FF0000
error

// 查询键对应的值：如果 key 存在，返回对应的 value，否则返回默认值 d
scala> println(colors1.getOrElse("red", "hello"))
#FF0000
scala> println(colors1.getOrElse("black",  "hello"))
hello

// 查询键是否在 Map 中
scala> println(colors1.contains("black"))
false
```

- 添加：

```scala
scala> colors1 + ("blue" -> "#0033FF", "yellow" -> "#FFFF00")
Map(blue -> #0033FF, 
    azure -> #F0FFFF, 
    peru -> #CD853F, 
    yellow -> #FFFF00, 
    red -> #FF0000)
    
scala> colors1 ++ colors2
Map(blue -> #0033FF, 
    azure -> #F0FFFF, 
    peru -> #CD853F, 
    yellow -> #FFFF00, 
    red -> #FF0000)
```

- 移除：

```scala
scala> colors1 - ("red", "azure")
Map(peru -> #CD853F)

scala> colors1 -- colors2.keys
Map(azure -> #F0FFFF, peru -> #CD853F)

scala> colors1.filterKeys(x=>Set("red", "peru").contains(x))
Map(red -> #FF0000, peru -> #CD853F)
```

### 可变 Map
可变 Map 支持不可变 Map 的所有操作，同时还支持原地修改操作：

![-c](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191203215409.png)

```scala
scala> val colors1 = mutable.Map("red" -> "#FF0000",
                                 "azure" -> "#F0FFFF",
                                 "peru" -> "#CD853F")
colors1: scala.collection.mutable.Map[String,String] = Map(azure -> #F0FFFF, red -> #FF0000, peru -> #CD853F)

scala> val colors2 = mutable.Map("blue" -> "#0033FF",
     |                           "yellow" -> "#FFFF00",
     |                           "red" -> "#FF0000")
colors2: scala.collection.mutable.Map[String,String] = Map(yellow -> #FFFF00, red -> #FF0000, blue -> #0033FF)

scala> colors1("red") = "changed"
res29: scala.collection.mutable.Map[String,String] = Map(azure -> #F0FFFF, red -> changed, peru -> #CD853F)

scala> colors1 += ("blue" -> "#0033FF", "yellow" -> "#FFFF00")
res30: colors1.type = Map(yellow -> #FFFF00, azure -> #F0FFFF, red -> changed, peru -> #CD853F, blue -> #0033FF)

scala> colors1 -= ("blue", "yellow")
res32: colors1.type = Map(azure -> #F0FFFF, red -> changed, peru -> #CD853F)

scala> colors1 ++= colors2
res34: colors1.type = Map(yellow -> #FFFF00, azure -> #F0FFFF, red -> #FF0000, peru -> #CD853F, blue -> #0033FF)

scala> colors1 --= colors2.keys
res36: colors1.type = Map(azure -> #F0FFFF, peru -> #CD853F)
scala> colors1.getOrElseUpdate("black", "new color")

```

### 可变 Map 和不可变 Map 相互转化
可变 Map 和不可变 Map 可以通过 Seq 作为中间桥梁进行相互转化：

```scala
scala> val map_im = Map("a"->"1", "b"->"2")
map_im: scala.collection.immutable.Map[String,String] = Map(a -> 1, b -> 2)

scala> val map_mm = mutable.Map("a"->"1", "b"->"2")
map_mm: scala.collection.mutable.Map[String,String] = Map(b -> 2, a -> 1)

scala> mutable.Map(map_im.toSeq:_*)
res24: scala.collection.mutable.Map[String,String] = Map(b -> 2, a -> 1)

scala> Map(map_mm.toSeq:_*)
res25: scala.collection.immutable.Map[String,String] = Map(b -> 2, a -> 1)
```

### Map 遍历
有三种常见的 Map 遍历方法：

```scala
// 遍历关键字
scala> for (k <- colors1.keys) {
    println(s"${k}:${colors1(k)}")
}
// 遍历(key,value)二元组
scala> for (kv <- colors1) {
    println(s"${kv._1}:${kv._2}")
}
// 遍历(key,value)二元组，并复制给二元组
scala> for ((k, v) <- colors1) {
    println(s"$k:$v")
}
red:#FF0000
azure:#F0FFFF
peru:#CD853F
```


## Map 选择
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
- [Scala Map(集合)](https://www.runoob.com/scala/scala-maps.html)
- [Scala 集合](https://docs.scala-lang.org/zh-cn/overviews/collections/sets.html)









