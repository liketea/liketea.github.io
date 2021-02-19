---
title: Scala 教程：Basics（五）—— 函数
date: 2020-08-07 16:00:00
tags:
    - Scala
    - 教程
categories:
    - Scala
---


> 在Scala中，函数是命名的**参数化表达式**，而匿名函数实际上就是参数化表达式，函数可以出现在任何表达式可以出现的地方
> 在Scala中，函数是首类的，不仅可以得到声明和调用，还具有类型和值，函数类型和函数值可以出现在任何类型和值可以出现的地方

对于 Scala 和其他函数式编程语言来说，函数尤其重要。标准函数式编程方法论建议我们尽可能地构建纯（pure）函数，纯函数相对于非纯函数更加稳定，他们没有状态，且与外部数据正交，事实上它们是不可破坏的纯逻辑表达式：

1. 有一个或多个输入参数，只使用输入参数完成计算，返回一个值；
2. 对相同输入总是返回相同的值；
3. 不使用或影响函数之外的任何数据，也不受函数之外的任何数据的影响；


## 作为传统函数
Scala 函数可以像传统函数那样进行声明和调用，还可以进行嵌套和递归。

### 函数声明
函数声明的一般格式：

```scala
def <function_name>[[type_param]](<param1>: <param1_type> [,...]): <function_type> = <expression>
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200811162237.png)

- `def`：函数声明的关键字
- `function_name`：函数名
- `type_param`：类型参数，如果传入了类型参数，类型参数在函数定义的后续代码中就可以像普通类型一样使用
- `param1`：值参数
- `:`：每个参数后面都必须加上以冒号开始的类型标注，因为Scala并不会推断函数参数的类型
- `param1_type`：值参数类型
- `function_type`：函数的返回值类型是可选的，Scalade的**类型推断**会根据函数的实际返回值来推断函数的返回值类型，但在无法推断出函数返回值类型时必须显式提供函数返回值类型，比如递归函数必须显式给出函数的结果类型
- `=`：等号也有特别的含义，表示在函数式的世界观里，函数定义的是一个可以获取到结果值的表达式
- `expression`：函数体，由表达式或表达式块组成，最后一行将成为函数的返回值，如果需要在函数的表达式块结束前退出并返回一个值，可以使用return关键字显式指定函数的返回值，然后退出函数；如果函数只有一条语句，也可以选择不使用花括号

没有参数的函数只是表达式的一个**命名包装器**：适用于通过一个函数来格式化当前数据或者返回一个固定的值

```scala
scala> def hi() = "hi"
hi: ()String

scala> hi
res11: String = hi

scala> hi()
res12: String = hi

scala> def hi = "hi"
hi: String

scala> hi
res13: String = hi

```

没有返回值的函数被称作**过程**：以一个语句结尾的函数，如果函数没有显式的返回类型，且最后是一个语句，则Scala会推导出这个函数的返回类型为Unit

```scala
scala> def log(d: Double) = println(f"Got Value $d%.2f")
log: (d: Double)Unit
```

### 函数调用
函数调用的通用语法：

```scala
<function identifier>(<params>)
```

调用无参函数时，空括号是可选的：如果在定义时加了空括号，在调用时可加可不加，但如果在定义时没有加，在调用时也不能加，这可以避免混淆调用无括号函数与调用函数返回值。

```scala
scala> def hi() = "hi"
hi: ()String

scala> hi
res11: String = hi

scala> hi()
res12: String = hi

scala> def hi = "hi"
hi: String

scala> hi
res13: String = hi

scala> hi()
<console>:13: error: not enough arguments for method apply: (index: Int)Char in class StringOps.
Unspecified value parameter index.
       hi()
         ^
```

当函数只有一个参数时，可以使用表达式块来发送参数：不必先计算一个量，然后把它保存在局部值中再传递给函数，完全可以在表达式块中完成计算，表达式块会在调用函数之前计算，将表达式块的返回值用作函数的参数

```scala
scala> def len(s: String) = {
     |     s.length()
     | }
len: (s: String)Int

scala> len{
     |    val x = "Hello"
     |    val y = "World"
     |    x + " " + y
     | }
res6: Int = 11
```

### 参数传递
#### 按顺序传参&按关键字传参
Scala 中的参数默认按照参数顺序传递，也可以按照关键字传递：

```scala
scala> def greet(prefix: String, name: String) = s"$prefix $name"
greet: (prefix: String, name: String)String

scala> greet("Mr", "Bob")
res0: String = Mr Bob

scala> greet(name = "Bob", prefix = "Mr")
res1: String = Mr Bob
```

#### 默认参数
Scala 可以为函数的任意参数指定默认值，使得调用者可以忽略这个参数：

```scala
def <identifier>(<identifier>: <type> = <value> [,...]): <type> = <expression>
```

如果默认参数后面还有非默认参数，那只能按照关键字传参，因为无法利用参数的顺序了；如果默认参数后面没有非默认参数，则可以按照顺序来传递前面的参数。

#### 变长参数
Scala 支持vararg参数，可以定义输入参数个数可变的函数，可变参数后面不可以有非可变参数，因为无法加以区分。

语法：在参数类型后面加上 `*` 来标识这是一个可变参数

```scala
scala> def sum(items: Int*): Int = {
     |     var total = 0
     |     for (i <- items) total += i
     |     total
     | }
sum: (items: Int*)Int

scala> sum(1,2,3)
res8: Int = 6
```

#### 类型参数
Scala 函数不仅可以传入“值”参数，还可以传入“类型”参数，这可以提高函数的灵活性和可重用性，这样函数参数或返回值的类型不再是固定的，而是可以由函数调用者控制。

语法：在函数名后的`[]`传入类型参数R之后，R就可以像一个具体的类型一样在后面使用了

```scala
def <identifier>[type-param](<value-param>: <type-param>): <type> = <expression>
```

示例：

```scala
scala> def identity[R](r: R): R = r
identity: [R](r: R)R

scala> identity[String]("sds")
res9: String = sds

scala> identity[Int](23)
res10: Int = 23

scala> identity[Int]("fs")
<console>:13: error: type mismatch;
 found   : String("fs")
 required: Int
       identity[Int]("fs")
                     ^
```

函数调用时，类型参数的类型推断：在调用包含类型参数的函数时，如果未明确指定类型参数的具体类型，scala会根据**第一个**参数列表的类型来推断类型参数的类型，如果第一个参数列表的类型也未知则会抛出异常。因此在设计柯里化函数时，往往将非函数参数放在第一个参数列表，将函数参数放在最后一个参数列表，这样函数的类型参数的具体类型可以通过第一个非函数入参的类型推断出来，而这个类型又能被继续用于对函数参数列表类型进行检查，使用者需要给出的类型信息更少，在编写函数字面量时可以更精简；

```scala
// 类型参数未指定，且第一个参数函数字面值类型未指定，抛出异常
scala> def curry[T](f: T => T)(x:T) = f(x)
curry: [T](f: T => T)(x: T)T

scala> curry(_ * 2)(3)
<console>:13: error: missing parameter type for expanded function ((x$1: <error>) => x$1.$times(2))
       curry(_ * 2)(3)
             ^
// 类型参数的具体类型可以通过第一个参数列表的类型推断出来，继而推断出第二个参数列表的类型
scala> def curry[T](x: T)(f: T => T) = f(x)
curry: [T](x: T)(f: T => T)T

scala> curry(3)(_ * 2)
res97: Int = 6
```

### 递归函数
递归函数在函数式编程中很普遍，因为他们为迭代处理数据结构或计算提供了一种很好的方法，而且不必使用可变的数据，因为每个函数调用自己的栈来存储参数。

示例：

```scala
// 计算正数次幂
scala> greet(name = "Bob", prefix = "Mr")
res1: String = Mr Bob

scala> def power(x:Int,n:Int):Long = {
     |     if (n > 1) x * power(x, n-1)
     |     else 1
     | }
power: (x: Int, n: Int)Long

scala> power(2,8)
res2: Long = 128
```

使用递归函数可能会遇到”栈溢出“错误，为了避免这种情况，Scala编译器可以使用尾递归（tail-recursion）优化一些递归函数，使得递归调用不使用额外的栈空间，而只使用当前函数的栈空间。但是只有最后一个语句是递归调用的函数时（调用函数本身的结果作为直接返回值），Scala编译器才能完成尾递归优化。

示例：

```scala
// 用尾递归的方式重写power
scala> def power(x: Int, n: Int, t: Int = 1): Int = {
     |     if (n < 1) t
     |     else power(x, n - 1, x * t)
     | }
power: (x: Int, n: Int, t: Int)Int

scala> power(2, 8)
res4: Int = 256
```

### 嵌套函数
函数是命名的参数化表达式，而表达式是可以嵌套的，所以函数本身也是可以嵌套的。当需要在一个方法中重复某个逻辑，但是把它作为外部方法有没有太大意义时，可以在函数中定义一个内部函数，这个内部函数只能在该函数内部使用。

示例：

```scala
scala> def max(a: Int, b: Int, c: Int) = {
     |     def max(x: Int, y: Int) = if (x > y) x else y
     |     max(a,max(b,c))
     | }
max: (a: Int, b: Int, c: Int)Int

scala> max(1,2,3)
res7: Int = 3
```

## 作为首类函数
> 函数式编程的一个关键是函数应当是首类的（first-class）：函数不仅能得到声明和调用，还具有类型和值，函数类型和函数值可以出现在任何类型和值可以出现的地方

### 函数类型
与函数返回值类型不同，函数类型是函数本身的类型，函数类型可以用 `参数类型 => 返回值类型` 来表示：

```scala
([<type>, ...]) => <type>
```

函数类型可以出现在任何类型可以出现的地方：

```scala
scala> def func(a: Int, b: Int): Int = if (a > b) a else b
func: (a: Int, b: Int)Int

// 1. 出现在变量/值声明语句中
scala> val x: (Int, Int) => Int = func
x: (Int, Int) => Int = $$Lambda$1096/23426726@70b037ac

scala> x(1,2)
res9: Int = 2
// 2. 出现在函数参数类型中
scala> def max(a: Int, b: (Int, Int) => Int): Int = b(a, 3)
max: (a: Int, b: (Int, Int) => Int)Int

scala> max(1, func)
res10: Int = 3
// 3. 出现在函数返回值类型中
scala> def dummy(): (Int, Int) => Int = func
dummy: ()(Int, Int) => Int

scala> dummy()(1,2)
res11: Int = 2
```

### 函数值
与函数返回值不同，函数值是函数本身的值，每个函数值都是某个扩展自scala包的FunctionN系列当中的一个特质的类的**实例**，比如Function0表示不带参数的函数，Function1表示带一个参数的函数，等等。每一个FunctionN特质都有一个apply方法用来调用该函数。

函数值可以出现在任何值可以出现的地方：

1. 可以用字面值形式创建，而不必指定标识符；
2. 可以存储在某个容器，比如值、变量或数据结构；
3. 作为另一个函数的参数或返回值；

Scala 中有一些特殊的方法来创建或返回函数值，包括：

1. 创建函数字面值/匿名函数；
2. 当通过函数名为一个显式声明为函数类型的变量赋值时，函数名会被推断为一个函数值，而不是函数调用；
3. 使用通配符替换部分参数来**部分调用函数**，将返回一个能够接收剩余参数的函数值；
4. 函数柯里化提供了一种更加简洁的方式来实现部分调用函数；

#### 匿名函数（Anonymous function）
匿名函数是一个没有名字的函数值，匿名函数可以用 `输入参数 => 返回值` 来表示：

```scala
([<param1>: <type>...]) => <expression>
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200811162254.png)

示例：

```scala
// 一个没有输入的函数字面值
scala> val func = () => "hi"
func: () => String = $$Lambda$1182/355159860@42e71f6c

scala> val doubler = (x: Int) => x * 2
doubler: Int => Int = $$Lambda$1181/1140744858@40fd8aa1
```

匿名函数有很多名字：

> 函数字面量(function literal)：由于匿名函数的创建不必指定标识符，且可以出现在一切函数值可以出现的地方，和一般类型中的字面值作用类似；
> Lambda表达式：C#和Java8都采用这种说法，这是从原先数学中的lambda演算语法得来的；
> functionN：Scala编译器对函数字面量的叫法，根据输入参数的个数而定；


当函数字面值满足以下两个条件时，甚至可以使用通配符语法把参数和箭头也给匿了：

1. 函数的显式类型在字面量之外指定，Scala可以通过类型推断推断出参数类型；
2. 参数最多被使用一次；

```scala
// 一个参数的情形
scala> def x(s: String, f: String => String) = {
     |     if (s != null) f(s) else s
     | }
x: (s: String, f: String => String)String

scala> x("Ready", _.reverse)
res14: String = ydaeR

// 多个参数的情形：通配符会按照顺序替换输入参数，通配符必须与输入参数个数一致
scala> def com(x: Int, y:Int, f:(Int, Int)=> Int) = f(x, y)
com: (x: Int, y: Int, f: (Int, Int) => Int)Int

scala> com(23, 12, _ * _)
res15: Int = 276
// 使用类型参数的情形
scala> def x[A, B](a: A, b: A, c: A, f:(A, A, A)=>B) = f(a,b,c)
x: [A, B](a: A, b: A, c: A, f: (A, A, A) => B)B

scala> x[Int, Int](1,2,3,_*_+_)
res18: Int = 5
```

通配符语法在处理数据结构和集合事尤其有帮助，很多核心的排序、过滤和其他数据结构方法都会使用首类函数和占位符语法来减少调用这些方法所需的额外代码。

#### 偏函数（partial function）
偏函数是只对满足某些特定模式的输入进行输出的函数字面值，如果输入匹配不到任何给定模式则会导致一个Scala错误（如果要避免这样的错误可以在末尾使用一个通配符）：

```scala
scala> val statusHandler: Int => String = {
     |     case 200 => "Okay"
     |     case 400 => "Your Error"
     |     case 500 => "Our Error"
     | }
statusHandler: Int => String = $$Lambda$1196/551773385@24efdd16

scala> statusHandler(200)
res22: String = Okay

scala> statusHandler(20)
scala.MatchError: 20 (of class java.lang.Integer)
  at .$anonfun$statusHandler$1(<console>:11)
  at .$anonfun$statusHandler$1$adapted(<console>:11)
  ... 28 elided
```

偏函数无法单独存在，必须要赋值给变量/参数。偏函数有点像 Sql 中的 `case when` 语句，在处理集合和模式匹配时更为有用。

#### 函数名用作函数值
函数名出现的时候会被默认视作一次函数调用，但是当将函数名赋值/传递给一个显式声明的变量/参数时，Scala会将其推断为一个函数值：

```scala
scala> def double(x: Int): Int = x * 2
double: (x: Int)Int

scala> val myDouble: (Int) => Int = double
myDouble: Int => Int = $$Lambda$1135/1858051117@753c7411

scala> myDouble(5)
res6: Int = 10
// 没有参数的函数不建议这样使用
scala> def func() = "hi"
func: ()String

scala> val x = func
x: String = hi

scala> val x: () => String = func
<console>:12: warning: Eta-expansion of zero-argument methods is deprecated. To avoid this warning, write (() => func()).
       val x: () => String = func
                             ^
x: () => String = $$Lambda$1177/572488693@2986db02
```

#### 部分调用函数（partially apply）
对于多参数函数，如果固定其中某些参数，剩余参数用通配符替换，将返回一个只接收剩余参数的函数值：

```scala
def sum(a: Int, b: Int, c: Int) = a + b + c
// 返回保留一个参数的函数值
scala> val left1 = sum(1, _, 3)
left1: Int => Int = $$Lambda$1090/466959452@38affd02
scala> left1(2)
res8: Int = 6

// 返回保留两个参数的函数值
scala> val left2 = sum(1, _, _)
left2: (Int, Int) => Int = $$Lambda$1088/1147105139@27f31d91
scala> left2(2,3)
res7: Int = 6

// 返回保留三个参数，等价于 sum _
scala> val left3 = sum(_, _, _)
left3: (Int, Int, Int) => Int = $$Lambda$1087/417004859@2954c429
scala> left3(1, 2, 3)
res6: Int = 6
// 返回保留所有参数的函数值
scala> val leftAll = sum _
leftAll: (Int, Int, Int) => Int = $$Lambda$1103/118175968@79414283

scala> leftAll(1,2,3)
res12: Int = 6
```

#### 函数柯里化（function Currying）
> 柯里化（Currying）是以逻辑学家 Haskell Curry 命名的一种将多参数函数转化为**单参数函数链**的技术。某些分析技术只能应用于具有单个参数的函数，在处理多参数函数时，柯里化通过逐一固定参数来得到关于剩余参数的新的函数，这样每次只需要处理单参数函数。

函数柯里化可以看做是部分调用函数的一种简洁语法：使用有多个参数表的函数，而不是将一个参数表分解为调用参数和非调用参数，每次调用一个函数表将返回一个函数而非函数值：

```scala
// 定义一个多参数表的函数
scala> def sum(x: Int)(y: Int)(z: Int): Int = x + y + z
sum: (x: Int)(y: Int)(z: Int)Int
// 调用一个参数表将返回一个函数，这个函数默认被视为函数调用，因此报错
scala> sum(1)
<console>:13: error: missing argument list for method sum
Unapplied methods are only converted to functions when a function type is expected.
You can make this conversion explicit by writing `sum _` or `sum(_)(_)(_)` instead of `sum`.
       sum(1)
          ^
// 使用部分调用函数语法返回一个函数值
scala> sum(1) _
res17: Int => (Int => Int) = $$Lambda$1143/106305065@26156929

scala> sum(1)(2) _
res18: Int => Int = $$Lambda$1144/141828288@1cdb0d7b
// 函数完全调用后得到函数最终的返回值
scala> sum(1)(2)(3)
res19: Int = 6
```

### 高阶函数（high-order function）
如果一个函数不接收任何函数作为入参，就被称为初阶（first-order）函数，
高阶（high-order）函数则是包含了函数类型的参数或返回值的函数。

```scala
scala> def safeStringOp(s: String, f: String => String) = {
     |     if (s != null) f(s) else s
     | }
safeStringOp: (s: String, f: String => String)String

scala> def reverser(s: String) = s.reverse
reverser: (s: String)String

scala> safeStringOp("Hello", reverser)
res20: String = olleH
```

### 传名参数（by-name）
对于普通的传值参数（by-value）来说，如果向其传递一个函数调用，那么只会在参数传递的时候调用这个函数并将其**返回值**传递给传值参数，后面在使用这个参数的时候使用的都是它的值。而传名参数（by-name）不同，可以获取一个值，也可以获取最终返回一个值的函数，如果向这个函数传入一个值，和传值参数效果相同，但如果向它传入一个函数调用，那么每次使用这个参数时都会调用这个函数，整体上起到了“延迟调用”的效果。

传名参数的声明语法：仅仅是在参数和参数类型中间加了一个 `=>`：

```scala
<identifier>: => <type>
```

示例：

```scala
scala> def f(i: Int) = {
     |     println(s"Hello from f($i)")
     |     i
     | }
f: (i: Int)Int
// 传值参数
scala> def doubles(x: Int) = {
     |     println("Now doubling" + x)
     |     x * 2
     | }

scala> doubles(f(3))
Hello from f(3)
Now doubling3
res5: Int = 6
// 传名参数
scala> def doubles(x: => Int) = {
     |     println("Now doubling" + x)
     |     x * 2
     | }
     
scala> doubles(f(3))
Hello from f(3)
Now doubling3
Hello from f(3)
res4: Int = 6
scala> doubles(3)
Now doubling3
res0: Int = 6
```

