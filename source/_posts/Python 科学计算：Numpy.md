---
title: Python 科学计算：Numpy 
date: 2020-06-12 17:01:09
tags: 
    - Python
categories:
    - Python
---

<img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200612153604.png" width="50%" height="50%"  style="margin: 0 auto;"/>


NumPy(Numerical Python) 是 Python 的一个扩展库，主要用于多维数组 (ndarray) 的快速计算，通常与 SciPy 和 Matplotlib 一起使用来代替 MatLab 做科学计算，也有助于我们通过 Python 学习数据科学或者机器学习。

任何笔记都难以穷尽所有细节，笔记的真正意义在于提纲挈领，在需要时能够快速唤醒大部分核心知识，更多的细节请参考官方文档或Google：

- NumPy 官网 http://www.numpy.org/
- Numpy 中文官网 https://www.numpy.org.cn/





```python
import numpy as np 
```

## 数据类型

### 内置数据类型
numpy 支持的数据类型比 Python 内置的类型要多很多，基本上可以和 C 语言的数据类型对应上，其中部分类型对应为 Python 内置的类型。下表列举了常用 NumPy 基本类型：

| 名称         | 描述                                                 |
|:------------|:----------------------------------------------------|
| bool\_     | 布尔型数据类型（True 或者 False）                             |
| int\_      | 默认的整数类型（类似于 C 语言中的 long，int32 或 int64）             |
| intc       | 与 C 的 int 类型一样，一般是 int32 或 int 64                  |
| intp       | 用于索引的整数类型（类似于 C 的 ssize\_t，一般情况下仍然是 int32 或 int64） |
| int8       | 字节（\-128 to 127）                                   |
| int16      | 整数（\-32768 to 32767）                               |
| int32      | 整数（\-2147483648 to 2147483647）                     |
| int64      | 整数（\-9223372036854775808 to 9223372036854775807）   |
| uint8      | 无符号整数（0 to 255）                                    |
| uint16     | 无符号整数（0 to 65535）                                  |
| uint32     | 无符号整数（0 to 4294967295）                             |
| uint64     | 无符号整数（0 to 18446744073709551615）                   |
| float\_    | float64 类型的简写                                      |
| float16    | 半精度浮点数，包括：1 个符号位，5 个指数位，10 个尾数位                    |
| float32    | 单精度浮点数，包括：1 个符号位，8 个指数位，23 个尾数位                    |
| float64    | 双精度浮点数，包括：1 个符号位，11 个指数位，52 个尾数位                   |
| complex\_  | complex128 类型的简写，即 128 位复数                         |
| complex64  | 复数，表示双 32 位浮点数（实数部分和虚数部分）                          |
| complex128 | 复数，表示双 64 位浮点数（实数部分和虚数部分）                          |

### 数据类型对象（dtype）
数据类型对象描述了数组对应的内存区域如何使用，包括

- 数据的类型：整数，浮点数或者 Python 对象
- 数据的大小：例如， 整数使用多少个字节存储
- 数据的字节顺序："<"意味着小端法(最小值存储在最小的地址，即低位组放在最前面)。">"意味着大端法(最重要的字节存储在最小的地址，即高位组放在最前面)
- 结构化类型的字段名和字段类型：结构化类型指的是每个元素的类型，如果结构化类型为 `[(filed_name1, filed_type1), (filed_name2, filed_type2)]`，那么数组对应的元素 `(a, b)`，a 的字段名为filed_name1，字段类型为 filed_type1，b 的字段名为filed_name2，字段类型为 filed_type2；

`numpy.dtype(object, align, copy)`

- object - 要转换为的数据类型对象
- align - 如果为 true，填充字段使其类似 C 的结构体。
- copy - 复制 dtype 对象 ，如果为 false，则是对内置数据类型对象的引用

每个内建类型都有一个唯一定义它的字符代码，如下：

| 字符   | 对应类型            |
|------|-----------------|
| b    | 布尔型             |
| i    | \(有符号\) 整型      |
| u    | 无符号整型 integer   |
| f    | 浮点型             |
| c    | 复数浮点型           |
| m    | timedelta（时间间隔） |
| M    | datetime（日期时间）  |
| O    | \(Python\) 对象   |
| S, a | \(byte\-\)字符串   |
| U    | Unicode         |
| V    | 原始数据 \(void\)   |



```python
print np.dtype(np.int32)
# int8, int16, int32, int64 四种数据类型可以使用字符串 'i1', 'i2','i4','i8' 代替
print np.dtype('i4')
print np.dtype('<i4')
```

    int32
    int32
    int32



```python
# 结构化类型：元素的类型为结构化类型，元素的每个域可以用(字段名, 字段类型)组成
student = np.dtype([('name','S20'), ('age', 'i1'), ('marks', 'f4')]) 
# a 是一个一维数组，每个元素是一个三元组，元素类型是结构化类型
a = np.array([('abc', 21, 50),('xyz', 18, 75)], dtype = student) 
# 可以通过结构类型的字段名来引用该列
print a['name']
a
```

    ['abc' 'xyz']





    array([('abc', 21, 50.), ('xyz', 18, 75.)],
          dtype=[('name', 'S20'), ('age', 'i1'), ('marks', '<f4')])



## 数组创建

NumPy的主要对象是同构多维数组，可以使用[数组创建API](https://www.numpy.org.cn/reference/routines/array-creation.html#ones-%E5%92%8C-zeros-%E5%A1%AB%E5%85%85%E6%96%B9%E5%BC%8F)中详述的各种方法来创建数组。

### 通过构造函数创建
`numpy.array(object, dtype = None, copy = True, order = None, subok = False, ndmin = 0)`

| 名称     | 描述                             |
|--------|:--------------------------------|
| object | 数组或嵌套的数列                       |
| dtype  | 数组元素的数据类型，可选                   |
| copy   | 对象是否需要复制，可选                    |
| order  | 创建数组的样式，C为行方向，F为列方向，A为任意方向（默认） |
| subok  | 默认返回一个与基类类型一致的数组               |
| ndmin  | 指定生成数组的最小维度                    |


```python
li = [[3 * i + j for j in range(3)] for i in range(2)]
a = np.array(li)
ac = np.array(li, order='C')
af = np.array(li, order='F')
print '默认方向：\n{}'.format(a)
print 'C行方向：\n{}'.format(ac)
print 'F列方向：\n{}'.format(af)
```

    默认方向：
    [[0 1 2]
     [3 4 5]]
    C行方向：
    [[0 1 2]
     [3 4 5]]
    F列方向：
    [[0 1 2]
     [3 4 5]]


### 通过 numpy 方法创建
- `numpy.empty(shape, dtype = float, order = 'C')` ：创建指定形状和类型的数组，数组元素以随机值来填充；
- `numpy.zeros(shape, dtype = float, order = 'C')`：创建指定形状和类型的数组，数组元素以 0 来填充；
- `numpy.ones(shape, dtype = None, order = 'C')`：创建指定形状和类型的数组，数组元素以 1 来填充；
- `numpy.eye(N, M=None, k=0, dtype=<class 'float'>, order='C')`：返回一个二维数组，对角线为1，其他位置为0；


```python
np.empty([3,2], dtype = int) 
```




    array([[140719574482952, 140719574514864],
           [     4531377328,      4517086152],
           [              6,               0]])




```python
np.zeros([3,2], dtype = float, order = 'C')
```




    array([[0., 0.],
           [0., 0.],
           [0., 0.]])




```python
np.ones([3,2], dtype = None, order = 'C')
```




    array([[1., 1.],
           [1., 1.],
           [1., 1.]])




```python
np.eye(3,4,1)
```




    array([[0., 1., 0., 0.],
           [0., 0., 1., 0.],
           [0., 0., 0., 1.]])



### 通过数值范围创建
- `numpy.arange(start, stop, step, dtype)`: 根据 start 与 stop 指定的范围以及 step 设定的步长，生成一个 ndarray
- `np.linspace(start, stop, num=50, endpoint=True, retstep=False, dtype=None)`: 根据 start 与 stop 指定的数量生成一个等差数列，endpoint 表示是否包含stop的值，retstep代表是否显示步长
- `np.logspace(start, stop, num=50, endpoint=True, base=10.0, dtype=None)`: 根据 start 与 stop 指定的数量生成一个等比数列，base是对数的时候log的下标


```python
np.arange(5, dtype =  float)  
```




    array([0., 1., 2., 3., 4.])




```python
np.linspace(1, 10, 10, endpoint=False, retstep=True)
```




    (array([1. , 1.9, 2.8, 3.7, 4.6, 5.5, 6.4, 7.3, 8.2, 9.1]), 0.9)




```python
np.logspace(1, 6, 6, base=2)
```




    array([ 2.,  4.,  8., 16., 32., 64.])



### 通过坐标函数创建
`numpy.fromfunction(function, shape, **kwargs)` 通过作用于坐标上的函数构建数组

- function：function 是一个python函数，参数个数等于shape的维度，例如shape=(2,2)，传给 function 的参数将是 `array([[0, 0], [1, 1]])` 和 `array([[0, 1], [0, 1]])`，分别是 shape=(2,2) 的行标数组和列标数组
- shape：输出数组的shape


```python
np.fromfunction(lambda i, j: i == j, (3, 3), dtype=int)
```




    array([[ True, False, False],
           [False,  True, False],
           [False, False,  True]])



## 数组属性

| 属性                | 说明                                          |
|-------------------|---------------------------------------------|
| ndarray\.ndim     | 秩，即轴的数量或维度的数量                               |
| ndarray\.shape    | 数组的维度，对于矩阵，n 行 m 列                          |
| ndarray\.size     | 数组元素的总个数，相当于 \.shape 中 n\*m 的值              |
| ndarray\.dtype    | ndarray 对象的元素类型                             |
| ndarray\.itemsize | ndarray 对象中每个元素的大小，以字节为单位                   |
| ndarray\.flags    | ndarray 对象的内存信息                             |
| ndarray\.real     | ndarray元素的实部                                |
| ndarray\.imag     | ndarray 元素的虚部                               |
| ndarray\.data     | 包含实际数组元素的缓冲区，由于一般通过数组的索引获取元素，所以通常不需要使用这个属性。 |



```python
a = np.array([[1,2,3],[4,5,6]]) 
print 'a 的秩：{}'.format(a.ndim)
print 'a 的形状：{}'.format(a.shape)
print 'a 的元素个数：{}'.format(a.size)
print 'a 的元素类型：{}'.format(a.dtype)
print 'a 的元素大小：{}'.format(a.itemsize)
print 'a 的内存信息：\n{}'.format(a.flags)
a
```

    a 的秩：2
    a 的形状：(2, 3)
    a 的元素个数：6
    a 的元素类型：int64
    a 的元素大小：8
    a 的内存信息：
      C_CONTIGUOUS : True
      F_CONTIGUOUS : False
      OWNDATA : True
      WRITEABLE : True
      ALIGNED : True
      WRITEBACKIFCOPY : False
      UPDATEIFCOPY : False





    array([[1, 2, 3],
           [4, 5, 6]])




```python
# 关于一维数组的形状
print '一维数组形状：\n{}'.format(np.arange(3).shape)
print '二维数组形状：\n{}'.format(np.arange(3).reshape(1,3))
print '二维数组形状：\n{}'.format(np.arange(3).reshape(3,1))
```

    一维数组形状：
    (3,)
    二维数组形状：
    [[0 1 2]]
    二维数组形状：
    [[0]
     [1]
     [2]]


## 数组方法
这里只是对众多数组方法的简单索引，每种方法的详细使用细则参见[数组方法](https://www.numpy.org.cn/reference/arrays/ndarray.html#%E8%AE%A1%E7%AE%97)。

### 数组转换

| 方法                                              | 描述                                                        |
|-------------------------------------------------|-----------------------------------------------------------|
| ndarray\.item\(\*args\)                         | 将数组元素复制到标准Python标量并返回它。                                   |
| ndarray\.tolist\(\)                             | 将数组作为a\.ndim\-levels深层嵌套的Python标量列表返回。                    |
| ndarray\.itemset\(\*args\)                      | 将标量插入数组（如果可能，将标量转换为数组的dtype）                              |
| ndarray\.tostring\(\[order\]\)                  | 构造包含数组中原始数据字节的Python字节。                                   |
| ndarray\.tobytes\(\[order\]\)                   | 构造包含数组中原始数据字节的Python字节。                                   |
| ndarray\.tofile\(fid\[, sep, format\]\)         | 将数组作为文本或二进制写入文件（默认）。                                      |
| ndarray\.dump\(file\)                           | 将数组的pickle转储到指定的文件。                                       |
| ndarray\.dumps\(\)                              | 以字符串形式返回数组的pickle。                                        |
| ndarray\.astype\(dtype\[, order, casting, …\]\) | 数组的副本，强制转换为指定的类型。                                         |
| ndarray\.byteswap\(\[inplace\]\)                | 交换数组元素的字节                                                 |
| ndarray\.copy\(\[order\]\)                      | 返回数组的副本。                                                  |
| ndarray\.view\(\[dtype, type\]\)                | 具有相同数据的数组的新视图。                                            |
| ndarray\.getfield\(dtype\[, offset\]\)          | 返回给定数组的字段作为特定类型。                                          |
| ndarray\.setflags\(\[write, align, uic\]\)      | 分别设置数组标志WRITEABLE，ALIGNED，（WRITEBACKIFCOPY和UPDATEIFCOPY）。 |
| ndarray\.fill\(value\)                          | 使用标量值填充数组。                                                |                                       |


### 形状操作

| 方法                                          | 描述                       |
|---------------------------------------------|--------------------------|
| ndarray\.reshape\(shape\[, order\]\)        | 返回包含具有新形状的相同数据的数组。       |
| ndarray\.resize\(new\_shape\[, refcheck\]\) | 就地更改数组的形状和大小。            |
| ndarray\.transpose\(\*axes\)                | 返回轴转置的数组视图。              |
| ndarray\.swapaxes\(axis1, axis2\)           | 返回数组的视图，其中axis1和axis2互换。 |
| ndarray\.flatten\(\[order\]\)               | 将折叠的数组的副本返回到一个维度。        |
| ndarray\.ravel\(\[order\]\)                 | 返回一个扁平的数组。               |
| ndarray\.squeeze\(\[axis\]\)                | 从形状除去单维输入一个。             |


对 axis 的理解：轴是为超过一维的数组定义的属性，二维数据拥有两个轴，第 0 轴沿着行的垂直往下，第 1 轴沿着列的方向水平延伸。


### 项目选择和操作

| 方法                                                  | 描述                                    |
|-----------------------------------------------------|:---------------------------------------|
| ndarray\.take\(indices\[, axis, out, mode\]\)       | 返回由给定索引处的a元素组成的数组。                    |
| ndarray\.put\(indices, values\[, mode\]\)           | 为索引中的所有n设置。a\.flat\[n\] = values\[n\] |
| ndarray\.repeat\(repeats\[, axis\]\)                | 重复数组的元素。                              |
| ndarray\.choose\(choices\[, out, mode\]\)           | 使用索引数组从一组选项中构造新数组。                    |
| ndarray\.sort\(\[axis, kind, order\]\)              | 对数组进行就地排序。                            |
| ndarray\.argsort\(\[axis, kind, order\]\)           | 返回将对此数组进行排序的索引。                       |
| ndarray\.partition\(kth\[, axis, kind, order\]\)    | 重新排列数组中的元素，使得第k个位置的元素值位于排序数组中它应该在的位置。 比它小的都在前面，大的都在后面    |
| ndarray\.argpartition\(kth\[, axis, kind, order\]\) | 返回将对此数组进行分区的索引。                       |
| ndarray\.searchsorted\(v\[, side, sorter\]\)        | 查找应在其中插入v的元素以维护顺序的索引。                 |
| ndarray\.nonzero\(\)                                | 返回非零元素的索引。                            |
| ndarray\.compress\(condition\[, axis, out\]\)       | 沿给定轴返回此数组的选定切片。                       |
| ndarray\.diagonal\(\[offset, axis1, axis2\]\)       | 返回指定的对角线。                             |



### 计算


| 方法                                                     | 描述                        |
|--------------------------------------------------------|---------------------------|
| ndarray\.max\(\[axis，out，keepdims，initial，\.\.\.\]）    | 沿给定轴返回最大值                |
| ndarray\.argmax\(\[axis, out\]\)                       | 返回给定轴上的最大值的索引            |
| ndarray\.min\(\[axis，out，keepdims，initial，\.\.\.\]\)   | 沿给定轴返回最小值                |
| ndarray\.argmin\(\[axis, out\]\)                       | 返回最小值的索引沿给定轴线一个          |
| ndarray\.ptp\(\[axis, out, keepdims\]\)                | 沿给定轴的峰峰值（最大值 \- 最小值）     |
| ndarray\.clip\(\[min，max，out\]\)                       | 返回值限制为的数组。\[min, max\]    |
| ndarray\.conj\(\)                                      | 复合共轭所有元素                 |
| ndarray\.round\(\[decimals, out\]\)                    | 返回a，每个元素四舍五入到给定的小数位数    |
| ndarray\.trace\(\[offset, axis1, axis2, dtype, out\]\) | 返回数组对角线的总和              |
| ndarray\.sum\(\[axis, dtype, out, keepdims, …\]\)      | 返回给定轴上的数组元素的总和           |
| ndarray\.cumsum\(\[axis, dtype, out\]\)                | 返回给定轴上元素的累积和         |
| ndarray\.mean\(\[axis, dtype, out, keepdims\]\)        | 返回给定轴上数组元素的平均值           |
| ndarray\.var\(\[axis, dtype, out, ddof, keepdims\]\)   | 返回给定轴的数组元素的方差         |
| ndarray\.std\(\[axis, dtype, out, ddof, keepdims\]\)   | 返回沿给定轴的数组元素的标准偏差         |
| ndarray\.prod\(\[axis, dtype, out, keepdims, …\]\)     | 返回给定轴上的数组元素的乘积            |
| ndarray\.cumprod\(\[axis, dtype, out\]\)               | 返回沿给定轴的元素的累积乘积        |
| ndarray\.all\(\[axis, out, keepdims\]\)                | 如果所有元素都计算为True，则返回True  |
| ndarray\.any\(\[axis, out, keepdims\]\)                | 如果任何元素为True，则返回true |


其中许多方法都采用名为 axis 的参数：

- 如果 axis 为 None （默认值），则将数组视为1-D数组，并对整个数组执行操作。 如果self是0维数组或数组标量，则此行为也是默认行为。 （数组标量是类型/类float32，float64等的实例，而0维数组是包含恰好一个数组标量的ndarray实例。）
- 如果 axis 是整数，则操作在给定轴上完成（对于可沿给定轴创建的每个1-D子数组）




```python
x = np.array([[[ 0,  1,  2],
            [ 3,  4,  5],
            [ 6,  7,  8]],
           [[ 9, 10, 11],
            [12, 13, 14],
            [15, 16, 17]],
           [[18, 19, 20],
            [21, 22, 23],
            [24, 25, 26]]])
print x.sum()
print x.sum(axis=0)
```

    351
    [[27 30 33]
     [36 39 42]
     [45 48 51]]


### 算术运算和比较运算
几个关键点：

1. 算术和比较操作 ndarrays 被定义为逐元素操作，并且通常返回 ndarray 对象；
2. 参与运算的数组必须具有相同规模，或者满足广播条件；
3. 每个算术运算（的`+`，`-`，`*`，`/`，`//`，`%`，`divmod()`，`**`或`pow()`，`<<`，`>>`，`&`， `^`，`|`，`~`）和比较（`==`，`<`，`>`，`<=`，`>=`，`!=`）等效于numpy中对应的通用函数。


```python
x = np.arange(12).reshape(3,4)
y = np.arange(3).reshape(3,1)
print 'x:\n%s' %x
print 'y:\n%s' %y
print 'x+y:\n%s' %(x + y)
```

    x:
    [[ 0  1  2  3]
     [ 4  5  6  7]
     [ 8  9 10 11]]
    y:
    [[0]
     [1]
     [2]]
    x+y:
    [[ 0  1  2  3]
     [ 5  6  7  8]
     [10 11 12 13]]

### where 
`where(condition, [x, y])`，有两种用法：

- `where(condition)`：等价于 `np.asarray(condition).nonzero()`，返回 True 对应的各轴索引元组；
- `where(condition, x, y)`：如果 `condition` 为 True，则从 `x` 中选取对应元素，否则从 `y` 中选取元素，`x`, `y` 和 `condition` 必须是可广播的。

```python
x = np.arange(12).reshape(3,4)
x
```

    array([[ 0,  1,  2,  3],
       [ 4,  5,  6,  7],
       [ 8,  9, 10, 11]])
       
```python
np.where(x > 5)
```

    (array([1, 1, 2, 2, 2, 2]), array([2, 3, 0, 1, 2, 3]))

```python
np.asarray(x > 5).nonzero()
```

    (array([1, 1, 2, 2, 2, 2]), array([2, 3, 0, 1, 2, 3]))
    
```python
x, y = np.ogrid[:3, :4]
np.where(x < y, x, 10 + y)  # both x and 10+y are broadcast

```

    array([[10,  0,  0,  0],
       [10, 11,  1,  1],
       [10, 11, 12,  2]])

## 数组广播
Numpy 操作通常在数组对之间逐个元素进行，在最简单的情况下，两个数组具有相同形状，对于不同形状的数组，广播（BroadCasting）提供了一种将较小数组扩展至和较大数组具有相同形状的机制。这只是概念上的，Numpy实际上并不会制作副本，以节省内存、提高计算效率。

1. 广播的条件：数组对按照 shape 尾对齐后，比较对应维度的长度，要么相等要么其中一个是1
2. 广播的过程：从内到外/从后向前比较对应维度的长度
    1. 如果两个数组在该维度下长度相同，就跳过
    2. 如果长度不同但其中一个数组在该维度下长度为1，则将该数组沿着该维度”复制“为和另一数组具有相同长度
    3. 如果一个数组维度结束了，就在该数组外面加一个`[]`，相当于该数组在该维度下长度变为1
    4. 如果两个数组在该维度下长度不同且长度都不为1，则产生 `ValueError`
3. 广播的结果：广播后的数组每一维度的长度都是两个数组中对应维度长度的最大值

```
A      (4d array):  8 x 1 x 6 x 1
B      (3d array):      7 x 1 x 5
Result (4d array):  8 x 7 x 6 x 5
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200529114236.png)


```python
from numpy import array, newaxis
a = array([0.0, 10.0, 20.0, 30.0])
b = array([1.0, 2.0, 3.0])
a[:,newaxis] + b
```




    array([[ 1.,  2.,  3.],
           [11., 12., 13.],
           [21., 22., 23.],
           [31., 32., 33.]])



## 索引切片
Numpy 将 Python 的切片概念扩展到了n维，`x[(exp1，exp2，.，EXPN)]` 等同于 `x[exp1，exp2，.，EXPN]`，后者只是前者的语法糖。`exp` 可以有多种形式：

1. 基本索引
    1. 整数索引：c，
    2. 切片：`start:stop:step`
2. 高级索引
    1. 整数数组索引：由索引组成的数组
    2. 布尔数组索引：由Boolean值组成的数组

基本索引生成的所有数组始终是原数组的是**视图**，而不是复制，视图是对原始数组中一小部分的引用，对视图中元素的修改同样会反映到原始数组中，如果需要明确使用复制，可以调用数组的copy方法。与基本索引不同，高级索引始终返回数据的副本。

### 整数索引
- 形式：`x[c1, c2,.,cN]`，第一个元素的索引从0开始，假设某个维度元素个数为n，那么索引的有效取值范围为 `-n ~ n-1`，其中负数`-k`等价于 `n-k`
- 含义：返回由索引 `(c1, c2, . , cN)` 定位到的元素标量


```python
x = np.arange(10).reshape(2,5)
print x
print x[1,1]
print x[-1,1]
```

    [[0 1 2 3 4]
     [5 6 7 8 9]]
    6
    6


### 切片

- 形式：`x[i1:j1:k1, ..., i2:j2:k2, :, i3:j3:k3]`
- 含义：序列切片的标准规则适用于基于每维（假设某维长度为n）的基本切片：
    - 基本切片语法是 $i:j:k$，其中 i 是起始索引，j 是停止索引，k 是步长（$k\neq0$），这将选择具有索引值（在相应的维度中）$i, i+k, ..., i+(m-1) k$ 的 m 个元素，其中 $m = q + (r\neq0)$，q 和 r 是 j-i 除以 k 得到的商和余数：$j - i = q k + r$，使得 $i + ( m - 1 ) k < j$。
    - -i 和 -j 被解释为 n - i 和 n - j ，其中 n 是相应维度中的元素数量；
    - 如果没有给出 i，对于 k > 0，它默认为 0，对于 k < 0，它默认为 n - 1，默认取到头；
    - 如果没有给出 j，对于 k > 0，它默认为 n，对于 k < 0，则默认为 - n - 1；
    - 如果没有给出 k，则默认为 1；
    - `:` 代表此轴所有索引；
    - 对于 N 维数组，如果索引表达式个数 K 小于 N，后面 N-K 维默认以 `:` 填充；
    - numpy.Ellipsis `...` 等价于多个连续的 `:,:,:`，表示中间维度包含所有索引，`...` 最多只能出现一次；
    - numpy.newaxis：numpy.newaxis 是 None 的别名，作用是为前面一个轴内的每个元素添加 `[]`，从而在其所处位置添加一个轴；


```python
x[:, 1:-1:2]
```




    array([[1, 3],
           [6, 8]])




```python
x[..., ::-2]
```




    array([[4, 2, 0],
           [9, 7, 5]])




```python
np.newaxis == None
```




    True




```python
x[np.newaxis,:, 1:-1:2]
```




    array([[[1, 3],
            [6, 8]]])




```python
x[:, np.newaxis, 1:-1:2]
```




    array([[[1, 3]],
    
           [[6, 8]]])




```python
x[:, 1:-1:2, np.newaxis]
```




    array([[[1],
            [3]],
    
           [[6],
            [8]]])



### 整数数组索引
整数数组索引也叫**花式索引**：

- 形式：`x[index_array1, index_array2, ., index_arrayN]`
- 含义：不同维度的索引数组之间必须满足广播条件，否则就会报错
    - 广播：广播索引数组 `index_arrayk, k=1,...,N`，得到形状相同的索引数组 `index_arraykb, k=1,...,N`
    - 组合：对广播索引数组，进行逐元素配对（类似于 zip 的过程）
    - 查找：按照广播组合后的索引定位对应位置的元素
    - 返回：将查找到的元素替换到广播后的索引数组对应位置，作为结果返回
    


```python
x = np.arange(30).reshape(2,3,5)
x
```




    array([[[ 0,  1,  2,  3,  4],
            [ 5,  6,  7,  8,  9],
            [10, 11, 12, 13, 14]],
    
           [[15, 16, 17, 18, 19],
            [20, 21, 22, 23, 24],
            [25, 26, 27, 28, 29]]])




```python
"""
三个维度的整数数组索引 [[0],[0]],[1,2],[[1,1], [2,2]]，满足广播条件
2 * 1
1 * 2
2 * 2

广播后三个维度的整数数组索引为：
[[0, 0],    [[1,2],   [[1,1],
 [0, 0]]     [1,2]]    [2,2]]
 
进行逐元素组合：
[[(0,1,1), (0, 2, 1)],
 [(0,1,2), (0, 2, 2)]]

定位对应元素：
x[(0,1,1)]  x[(0, 2, 1)]  x[(0,1,2)]  x[(0, 2, 2)]

替换索引数组对应位置的值
[[x[(0,1,1)], x[(0,2,1)]],
 [x[(0,1,2)], x[(0,2,2)]]]
"""
x[[[0],[0]], [1,2], [[1,1], [2,2]]]
```




    array([[ 6, 11],
           [ 7, 12]])




```python
array([[x[(0,1,1)], x[(0, 2, 1)]], 
       [x[(0,1,2)], x[(0, 2, 2)]]])
```




    array([[ 6, 11],
           [ 7, 12]])




```python
# np.ix_(arr_1,...,arr_N) 返回N个数组，每个数组arr_k的形状为 1 * ... * k * ... * 1，即除了其所在维长度等于对应数组本身长度，其余维度元素个数均为1
rows = np.array([0, 3], dtype=np.intp)
columns = np.array([0, 2], dtype=np.intp)
construct = np.ix_(rows, columns)
print construct
x[np.ix_(rows, columns)]
```

    (array([[0],
           [3]]), array([[0, 2]]))





    array([[ 0,  2],
           [ 9, 11]])



### 布尔数组索引

- 形式：`x[obj]`，我中 obj 可以是
    - 与所在维度长度相等的数组；
    - 与x整体形状相同的布尔数组；
- 含义：`x[ind_1，boolean_array，ind_2] 等价于 x[(ind_1，)+boolean_array.nonzero()+(ind_2，)]`，如果索引包含布尔数组，则结果与将 `obj.nonzero()` 插入到相同位置并使用上述整数组索引机制相同。


```python
x = np.arange(30).reshape(2,3,5)
x
```




    array([[[ 0,  1,  2,  3,  4],
            [ 5,  6,  7,  8,  9],
            [10, 11, 12, 13, 14]],
    
           [[15, 16, 17, 18, 19],
            [20, 21, 22, 23, 24],
            [25, 26, 27, 28, 29]]])




```python
# 布尔数组长度与所在维度长度相等的数组
print x[[True, False], [True, True, False], [True, True, False, False, False]]
b_index = np.nonzero([True, False]), np.nonzero([True, True, False]), np.nonzero([True, True, False, False, False])
x[b_index]
```

    [0 6]





    array([[0, 6]])




```python
# 布尔索引数组和被索引的数组形状相同
x[x % 2 == 0]
```




    array([ 0,  2,  4,  6,  8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28])



### 混合索引

对于索引切片 `x[(exp1，exp2，.，EXPN)]`，`expk` 可以是以下四种形式：

| 索引名称   | 形式                  | 含义                                      | 广播维度                           | 视图/复制 |
|--------|---------------------|-----------------------------------------|--------------------------------|-------|
| 整数索引   | c                   | 在k轴中取出索引为 c 元素                          | 索引维长度为 0                       | 视图    |
| 切片索引   | i:j:k               | 在k轴中取出 i:j:k 的切片                        | 索引维长度为 divmod\(j\-I, k\) 的商加余数 | 视图    |
| 整数数组索引 | array\(m\*n\)       | 对所有整数数组索引广播、组合、查找、替换                    | 索引维形状为整数数组索引形状                   | 复制    |
| 布尔数组索引 | bool\_array\(s\*t\) | 等价于np\.nonzero\( bool\_array\)对应的整数数组索引 | 首先转化为整数数组索引，按照整数数组索引的规则确定索引维形状 | 复制    |


以上四种索引形式可以在不同维混合使用，但需满足以下两个条件：

1. 各维度索引满足对应索引形式的使用规范；
2. 不同维度之间满足广播条件：包括基本索引之间、高级索引之间、基本索引和高级索引之间；

确定混合索引结果数组的步骤：

1. 对基本索引和高级索引分别进行广播：
    1. 基本索引广播：假设广播后得到的基本索引为 basic_index，形状为 (m * n)
        1. 整数索引：`1 * ... * 0 * ... * 1`，整数索引对应维度元素长度为0，其他基本索引维度取默认值1；
        2. 切片索引：`1 * ... * ijk * ... * 1`，切片索引对应维度元素长度为切片长度，其他基本索引维度取默认值1；特殊地，`:` 元素长度即为原数组对应维的长度；
    2. 高级索引广播：假设广播后得到的高级索引为 advanced_index，形状为(s * t)
        1. 整数数组索引：`array_index.shape`，整数数组索引对应的形状就是整数数组索引本身的形状；
        2. 布尔数组索引：`nonzero_array_index.shape`，布尔数组索引本质上是整数数组索引，规则与整数数组索引相同；
2. 对广播后的基本索引和高级索引进行拼接广播：最终的结果数组形状为 s * t * m * n，即将广播后的高级索引中的每个元素替换为 m * n 的形状，其中替换后的索引数组中，每个元素都是一个索引元组，元组前半部分取自广播后的高级索引，后半部分取自广播后的基本索引；
3. 使用原数组中对应的元素替换组合后的索引数组中的元素（索引元组），得到最终的结果数组；
    



```python
print x.shape
x
```

    (2, 3, 5)





    array([[[ 0,  1,  2,  3,  4],
            [ 5,  6,  7,  8,  9],
            [10, 11, 12, 13, 14]],
    
           [[15, 16, 17, 18, 19],
            [20, 21, 22, 23, 24],
            [25, 26, 27, 28, 29]]])




```python
"""
示例1：普通索引和切片
    1. 确定各维度索引形状
        : 对应的索引数组形状 2 * 1 * 1，对应的完整索引数组为 [[[0]], [[1]]]
        :2 对应的索引数组形状 1 * 2 * 1，对应的完整索引数组为 [[[0], [1]]]
        4 对应的索引数组形状 1 * 1 * 0，对应的完整索引数组为 [[4]]
    2. 广播
        2 * 1 * 1
        1 * 2 * 1    => 2 * 2
        1 * 0 * 1
        广播后各维度索引形状分别为
        [[[0], [0]],    [[[0], [1]],    [[4]]
         [[1], [1]]]     [[0], [1]]]
        =>
        [[0, 0],        [[0, 1],        [[4, 4]
         [1, 1]]         [0, 1]]         [4, 4]]
    3. 组合
        [[(0,0,4), (0,1,4)],
         [(1,0,4), (1,1,4)]]
    4. 替换
        [[x[(0,0,4)], x[(0,1,4)]],
         [x[(1,0,4)], x[(1,1,4)]]]
"""
print [[x[(0,0,4)], x[(0,1,4)]],
       [x[(1,0,4)], x[(1,1,4)]]]
x[:, :2, 4]
```

    [[4, 9], [19, 24]]





    array([[ 4,  9],
           [19, 24]])




```python
"""
示例2：高级索引（高级索引和基本索引要分开来算）
    1. 确定广播后的高级索引
        1. 确定各维度索引形状，三个维度均为高级索引，统一确定整数数组索引的维度
            [0,1] 对应的索引数组形状 1 * 2
            [True, True, False] np.nonzero([True, True, False]) == [0,1] 对应的索引数组形状 1 * 2
            [4] 对应的索引数组形状 1 * 1
        2. 广播后各维度索引形状分别为 1 * 2，对应的整数数组索引为 [0,1] [0,1] [4,4]
        3. 组合 [(0,0,4), (1,1,4)]
    2. 确定基本索引，没有基本索引
    3. 拼接高级索引和基本索引 [(0,0,4), (1,1,4)]
    4. 替换 [x[(0,0,4)], x[(1,1,4)]]
"""

print [x[(0,0,4)], x[(1,1,4)]]
x[[0,1], [True, True, False], [4]]
```

    [4, 24]





    array([ 4, 24])




```python
"""
示例3：高级索引 + 基本索引（高级索引和基本索引要分开来算）
    1. 高级索引内部广播
        1. 确定各维度索引形状
            [0,1] 对应的索引数组形状 (2,)
            [True, False, True] np.nonzero([True, True, False]) == [0,2] 对应的索引数组形状 (2,)
        2. 广播后高级索引形状分别为 (2,)，对应的整数数组索引为 [0,1] [0,2]
        3. 组合 [(0,0), (1,2)]
    2. 确定基本索引
        1. 4:5 基本索引形状为 (1,)，索引为 [4]
    3. 整体广播，高级索引和基本索引拼接，对应整数数组索引形状为 (2,1)，索引分别为 [[(0,0)], [(1,2)]] [[4], [4]]
    3. 拼接高级索引和基本索引 [[0,0,4], [1,2,4]]
    4. 替换 [[x[(0,0,4)]], [x[(1,2,4)]]]
"""


print [[x[(0,0,4)]], [x[(1,2,4)]]]
x[[0,1], [True, False, True], 4:5]
```

    [[4], [29]]





    array([[ 4],
           [29]])



## 迭代数组


### 迭代数组中每个元素


```python
# 默认按照 order ='K' 以行优先迭代数组中的元素
a = np.arange(6).reshape(2,3)
print a
print a.T.copy(order='C')

for x in np.nditer(a):
    print x,

```

    [[0 1 2]
     [3 4 5]]
    [[0 3]
     [1 4]
     [2 5]]
    0 1 2 3 4 5



```python
# 迭代时访问每个元素的索引

it = np.nditer(a, flags=['multi_index'])
while not it.finished:
    print("%d %s" % (it[0], it.multi_index))
    it.iternext()
```

    0 (0, 0)
    1 (0, 1)
    2 (0, 2)
    3 (1, 0)
    4 (1, 1)
    5 (1, 2)


### 迭代广播数组
向 nditer 传递一个数组列表，多个数组先进行广播组合，然后再迭代。


```python
a = np.arange(3)
b = np.arange(6).reshape(2,3)
for x, y in np.nditer([a,b]):
    print("%d:%d" % (x,y))
```

    0:0
    1:1
    2:2
    0:3
    1:4
    2:5


## 通用函数
通用函数（universal function, ufunc）是以逐元素方式作用于 ndarray 上的函数，支持数组广播、类型转换以及其他几种特性。ufunc 是函数的矢量化包装器，接收固定数量的输入，并产生固定数量的输出。

在NumPy中，通用函数是numpy.ufunc类的实例，许多内置函数都是在编译的C代码中实现的，用户可以通过 frompyfunc 工厂函数生成自定义的通用函数示例。

### ufunc 属性
ufunc 有一些信息属性，这些属性不可以设置：

| 方法               | 描述                        |
|------------------|---------------------------|
| ufunc\.nin       | 输入数量。                     |
| ufunc\.nout      | 输出数量。                     |
| ufunc\.nargs     | 参数的数量。                    |
| ufunc\.ntypes    | 类型数量。                     |
| ufunc\.types     | 返回包含input\-> output类型的列表。 |
| ufunc\.identity  | 身份价值。                     |
| ufunc\.signature | 广义ufunc操作的核心元素的定义。        |



```python
sin_func = np.sin
print sin_func.nin
print sin_func.nout
print sin_func.nargs
print sin_func.ntypes
print sin_func.types
print sin_func.identity
print sin_func.signature
```

    1
    1
    2
    11
    ['e->e', 'f->f', 'd->d', 'e->e', 'f->f', 'd->d', 'g->g', 'F->F', 'D->D', 'G->G', 'O->O']
    None
    None


### ufunc 方法
所有ufunc都有四种方法。但是，这些方法只对采用两个输入参数并返回一个输出参数的标量ufunc有意义。尝试在其他ufunc上调用这些方法将导致ValueError。reduce-like方法都采用axis关键字、dtype关键字和out关键字，并且数组的维数都必须大于等于1。

1. axis 关键字指定将在其上进行缩减的数组的轴（负值向后计数）。一般来说，它是一个整数，但是对于 ufunc.reduce，它也可以是int的元组，一次减少多个轴、或者不减少、或者减少所有轴
2. dtype 关键字允许您更改进行 reduce 的数据类型（因此更改输出的类型）
3. out 关键字允许你提供一个输出数组，目前只支持单一输出的 ufunc，如果提供了out参数，dtype 参数将被忽略
4. ufunc还有第五种方法，允许使用特殊的索引执行就地操作。在使用花式索引的维度上不使用缓冲，因此花式索引可以多次列出一个项，并且将对该项的上一个操作的结果执行该操作。

| 方法                                                  | 描述                                |
|-----------------------------------------------------|-----------------------------------|
| ufunc\.reduce\(a\[, axis, dtype, out, …\]\)         | 减少一个接一个的尺寸，由沿一个轴施加ufunc。          |
| ufunc\.accumulate\(array\[, axis, dtype, out\]\)    | 累积将运算符应用于所有元素的结果。                 |
| ufunc\.reduceat\(a, indices\[, axis, dtype, out\]\) | 在单个轴上使用指定切片执行（局部）缩减。              |
| ufunc\.outer\(A, B, \*\*kwargs\)                    | 将ufunc op应用于所有对（a，b），其中a中的a和b中的b。 |
| ufunc\.at\(a, indices\[, b\]\)                      | 对'index'指定的元素在操作数'a'上执行无缓冲的就地操作。  |



```python
x = np.arange(10).reshape(2,5)
x
```




    array([[0, 1, 2, 3, 4],
           [5, 6, 7, 8, 9]])




```python
np.add.reduce(x, axis=0, dtype='i8')
```




    array([ 5,  7,  9, 11, 13])




```python
np.add.accumulate(x, axis=1)
```




    array([[ 0,  1,  3,  6, 10],
           [ 5, 11, 18, 26, 35]])



### 内置 ufunc 方法
目前在numpy中定义的一个或多个类型的通用函数超过60个，涵盖了各种各样的操作。当使用相关的中缀符号时，这些ufunc中的一些在数组上被自动调用（例如，当a+b被写入并且a或b是ndarray时，add（a，b）在内部被调用）。不过，您可能仍然希望使用ufunc调用，以便使用可选的输出参数将输出放置在您选择的一个或多个对象中。

回想一下，每个ufunc都逐个操作元素。因此，每个标量 ufunc 将被描述为作用于一组标量输入以返回一组标量输出。

- 数学运算：

| 方法                                                      | 描述                             |
|---------------------------------------------------------|--------------------------------|
| add\(x1, x2, \[, out, where, cast, order, \.\.\.\]\)   | 按元素添加参数。                       |
| subtract\(x1, x2, \[, out, where, cast, \.\.\.\]\)     | 从元素方面减去参数。                     |
| multiply\(x1, x2, \[, out, where, cast, \.\.\.\]\)     | 在元素方面乘以论证。                     |
| divide\(x1, x2, \[, out, where, cast, \.\.\.\]\)       | 以元素方式返回输入的真正除法。                |
| logaddexp\(x1, x2, \[, out, where, cast, \.\.\.\]\)    | 输入的取幂之和的对数。                    |
| logaddexp2\(x1, x2, \[, out, where, cast, \.\.\.\]\)   | base\-2中输入的取幂之和的对数。            |
| true\_divide\(x1, x2, \[, out, where, \.\.\.\]\)       | 以元素方式返回输入的真正除法。                |
| floor\_divide\(x1, x2, \[, out, where, \.\.\.\]\)      | 返回小于或等于输入除法的最大整数。              |
| negative\(x, \[, out, where, cast, order, \.\.\.\]\)   | 数字否定, 元素方面。                    |
| positive\(x, \[, out, where, cast, order, \.\.\.\]\)   | 数字正面, 元素方面。                    |
| power\(x1, x2, \[, out, where, cast, \.\.\.\]\)        | 第一个数组元素从第二个数组提升到幂, 逐个元素。       |
| remainder\(x1, x2, \[, out, where, cast, \.\.\.\]\)    | 返回除法元素的余数。                     |
| mod\(x1, x2, \[, out, where, cast, order, \.\.\.\]\)   | 返回除法元素的余数。                     |
| fmod\(x1, x2, \[, out, where, cast, \.\.\.\]\)         | 返回除法的元素余数。                     |
| divmod\(x1, x2 \[, out1, out2\], \[\[, out, \.\.\.\]\) | 同时返回逐元素的商和余数。                  |
| absolute\(x, \[, out, where, cast, order, \.\.\.\]\)   | 逐个元素地计算绝对值。                    |
| fabs\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式计算绝对值。                    |
| rint\(x, \[, out, where, cast, order, \.\.\.\]\)       | 将数组的元素舍入为最接近的整数。               |
| sign\(x, \[, out, where, cast, order, \.\.\.\]\)       | 返回数字符号的元素指示。                   |
| heaviside\(x1, x2, \[, out, where, cast, \.\.\.\]\)    | 计算Heaviside阶跃函数。               |
| conj\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式返回复共轭。                    |
| conjugate\(x, \[, out, where, cast, \.\.\.\]\)         | 以元素方式返回复共轭。                    |
| exp\(x, \[, out, where, cast, order, \.\.\.\]\)        | 计算输入数组中所有元素的指数。                |
| exp2\(x, \[, out, where, cast, order, \.\.\.\]\)       | 计算输入数组中所有 p 的 2\*\*p。          |
| log\(x, \[, out, where, cast, order, \.\.\.\]\)        | 自然对数, 元素方面。                    |
| log2\(x, \[, out, where, cast, order, \.\.\.\]\)       | x的基数为2的对数。                     |
| log10\(x, \[, out, where, cast, order, \.\.\.\]\)      | 以元素方式返回输入数组的基数10对数。            |
| expm1\(x, \[, out, where, cast, order, \.\.\.\]\)      | 计算数组中的所有元素。exp\(x\) \- 1       |
| log1p\(x, \[, out, where, cast, order, \.\.\.\]\)      | 返回一个加上输入数组的自然对数, 逐个元素。         |
| sqrt\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式返回数组的非负平方根。               |
| square\(x, \[, out, where, cast, order, \.\.\.\]\)     | 返回输入的元素方块。                     |
| cbrt\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式返回数组的立方根。                 |
| reciprocal\(x, \[, out, where, cast, \.\.\.\]\)        | 以元素方式返回参数的倒数。                  |
| gcd\(x1, x2, \[, out, where, cast, order, \.\.\.\]\)   | 返回 \| x1 \| 和的最大公约数 \| x2 \| 。 |
| lcm\(x1, x2, \[, out, where, cast, order, \.\.\.\]\)   | 返回 \| x1 \| 和的最小公倍数 \| x2 \| 。 |

- 三角函数：

| 方法                                                   | 描述                  |
|------------------------------------------------------|---------------------|
| sin\(x, \[, out, where, cast, order, \.\.\.\]\)     | 三角正弦, 元素方式。         |
| cos\(x, \[, out, where, cast, order, \.\.\.\]\)     | 余弦元素。               |
| tan\(x, \[, out, where, cast, order, \.\.\.\]\)     | 计算切线元素。             |
| arcsin\(x, \[, out, where, cast, order, \.\.\.\]\)  | 反向正弦, 元素方式。         |
| arccos\(x, \[, out, where, cast, order, \.\.\.\]\)  | 三角反余弦, 元素方式。        |
| arctan\(x, \[, out, where, cast, order, \.\.\.\]\)  | 三角反正切, 逐元素。         |
| arctan2\(x1, x2, \[, out, where, cast, \.\.\.\]\)   | x1/x2正确选择象限的逐元素反正切。 |
| hypot\(x1, x2, \[, out, where, cast, \.\.\.\]\)     | 给定直角三角形的“腿”, 返回其斜边。 |
| sinh\(x, \[, out, where, cast, order, \.\.\.\]\)    | 双曲正弦, 元素。           |
| cosh\(x, \[, out, where, cast, order, \.\.\.\]\)    | 双曲余弦, 元素。           |
| tanh\(x, \[, out, where, cast, order, \.\.\.\]\)    | 计算双曲正切元素。           |
| arcsinh\(x, \[, out, where, cast, order, \.\.\.\]\) | 逆双曲正弦元素。            |
| arccosh\(x, \[, out, where, cast, order, \.\.\.\]\) | 反双曲余弦, 元素。          |
| arctanh\(x, \[, out, where, cast, order, \.\.\.\]\) | 逆双曲正切元素。            |
| deg2rad\(x, \[, out, where, cast, order, \.\.\.\]\) | 将角度从度数转换为弧度。        |
| rad2deg\(x, \[, out, where, cast, order, \.\.\.\]\) | 将角度从弧度转换为度数。        |

- 位运算函数：

| 方法                                                     | 描述                     |
|--------------------------------------------------------|------------------------|
| bitwise\_and\(x1, x2, \[, out, where, \.\.\.\]\)      | 逐个元素地计算两个数组的逐位AND。     |
| bitwise\_or\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 逐个元素地计算两个数组的逐位OR。      |
| bitwise\_xor\(x1, x2, \[, out, where, \.\.\.\]\)      | 逐个元素地计算两个数组的逐位XOR。     |
| invert\(x, \[, out, where, cast, order, \.\.\.\]\)    | 计算逐位反转, 或逐位NOT, 逐元素计算。 |
| left\_shift\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 将整数位移到左侧。              |
| right\_shift\(x1, x2, \[, out, where, \.\.\.\]\)      | 将整数位移到右侧。              |

- 比较函数：

| 方法                                                     | 描述                      |
|--------------------------------------------------------|-------------------------|
| greater\(x1, x2, \[, out, where, cast, \.\.\.\]\)     | 以元素方式返回\(x1 > x2\)的真值。  |
| greater\_equal\(x1, x2, \[, out, where, \.\.\.\]\)    | 以元素方式返回\(x1 >= x2\)的真值。 |
| less\(x1, x2, \[, out, where, cast, \.\.\.\]\)        | 返回\(x1 < x2\)元素的真值。     |
| less\_equal\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 以元素方式返回\(x1 =< x2\)的真值。 |
| not\_equal\(x1, x2, \[, out, where, cast, \.\.\.\]\)  | 以元素方式返回\(x1 \!= x2\)。   |
| equal\(x1, x2, \[, out, where, cast, \.\.\.\]\)       | 以元素方式返回\(x1 == x2\)。    |

- 逻辑函数：不要使用Python关键字and并or组合逻辑数组表达式。这些关键字将测试整个数组的真值(不是你想象的逐个元素)。使用按位运算符＆和| 代替

| 方法                                                     | 描述                   |
|--------------------------------------------------------|----------------------|
| logical\_and\(x1, x2, \[, out, where, \.\.\.\]\)      | 计算x1和x2元素的真值。        |
| logical\_or\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 计算x1 OR x2元素的真值。     |
| logical\_xor\(x1, x2, \[, out, where, \.\.\.\]\)      | 以元素方式计算x1 XOR x2的真值。 |
| logical\_not\(x, \[, out, where, cast, \.\.\.\]\)     | 计算NOT x元素的真值。        |

- 浮点函数：

| 方法                                                       | 描述                              |
|----------------------------------------------------------|---------------------------------|
| isfinite\(x, \[, out, where, cast, order, \.\.\.\]\)    | 测试元素的有限性\(不是无穷大或不是数字\)。         |
| isinf\(x, \[, out, where, cast, order, \.\.\.\]\)       | 正面或负面无穷大的元素测试。                  |
| isnan\(x, \[, out, where, cast, order, \.\.\.\]\)       | 测试NaN的元素, 并将结果作为布尔数组返回。         |
| isnat\(x, \[, out, where, cast, order, \.\.\.\]\)       | 为NaT\(不是时间\)测试元素, 并将结果作为布尔数组返回。 |
| fabs\(x, \[, out, where, cast, order, \.\.\.\]\)        | 以元素方式计算绝对值。                     |
| signbit\(x, \[, out, where, cast, order, \.\.\.\]\)     | 返回元素为True设置signbit\(小于零\)。      |
| copysign\(x1, x2, \[, out, where, cast, \.\.\.\]\)      | 将元素x1的符号更改为x2的符号。               |
| nextafter\(x1, x2, \[, out, where, cast, \.\.\.\]\)     | 将x1之后的下一个浮点值返回x2\(元素方向\)。       |
| spacing\(x, \[, out, where, cast, order, \.\.\.\]\)     | 返回x与最近的相邻数字之间的距离。               |
| modf\(x \[, out1, out2\], \[\[, out, where, \.\.\.\]\)  | 以元素方式返回数组的小数和整数部分。              |
| ldexp\(x1, x2, \[, out, where, cast, \.\.\.\]\)         | 以元素方式返回x1 \* 2 \*\* x2。         |
| frexp\(x \[, out1, out2\], \[\[, out, where, \.\.\.\]\) | 将x的元素分解为尾数和二进制指数。               |
| fmod\(x1, x2, \[, out, where, cast, \.\.\.\]\)          | 返回除法的元素余数。                      |
| floor\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式返回输入的底限。                   |
| ceil\(x, \[, out, where, cast, order, \.\.\.\]\)        | 以元素方式返回输入的上限。                   |
| trunc\(x, \[, out, where, cast, order, \.\.\.\]\)       | 以元素方式返回输入的截断值。                  |

- 其他函数：

| 方法                                                 | 描述         |
|----------------------------------------------------|------------|
| maximum\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 元素最大的数组元素。 |
| minimum\(x1, x2, \[, out, where, cast, \.\.\.\]\) | 元素最小的数组元素。 |


```python
x = np.arange(10).reshape(2,5)
y = 3
np.maximum(x,y)
```




    array([[3, 3, 3, 3, 4],
           [5, 6, 7, 8, 9]])



### 自定义 ufunc

`numpy.frompyfunc(func, nin, nout)` 接收一个python函数，返回一个Numpy函数

- func：python函数
- nin：python函数输入参数的个数
- nout：python函数输出参数的个数

自定义 ufunc 的步骤：

1. 定义一个python函数
2. 将python函数转化为numpy函数
3. 使用numpy函数: numpy函数总是返回 PyObject 类型的数组，可以通过astype()做类型转换


```python
def func(x,y):
    return x + y
ufunc = np.frompyfunc(func, 2, 1)
result = ufunc(np.array([1,2,3]), np.array([4,5,6]))

result, result.astype(int)
```




    (array([5, 7, 9], dtype=object), array([5, 7, 9]))



## 沿轴应用函数

`numpy.apply_along_axis(func, axis, arr, *args, **kwargs)`

沿轴对数组里的每一个元素进行变换，得到目标的结果：

- func：接收数组 arr 元素的函数
- axis：轴向
- arr：数组
- *args, **kwargs都是func()函数额外的参数。




```python
def my_func(a):
    return (a[0] + a[-1]) * 0.5

b=np.array([[1,2,3,4],[5,6,7,8],[9,10,11,12]])

print np.apply_along_axis(my_func, 0, b)
print np.apply_along_axis(my_func, 1, b)

```

    [5. 6. 7. 8.]
    [ 2.5  6.5 10.5]


## 常量


```python
print '正无穷:{}'.format(np.inf)
print '负无穷:{}'.format(-np.inf)

print '自然对数:{}'.format(np.e)
print '圆周率:{}'.format(np.pi)

```

    正无穷:inf
    负无穷:-inf
    自然对数:2.71828182846
    圆周率:3.14159265359


## 日期
numpy 中的日期数据类型称为 “datetime64”。


```python
print np.datetime64('2005-02-25')
print np.datetime64('2005-02')
print np.datetime64('2005-02', 'D')
# 不是时间
print np.datetime64('nat')
```

    2005-02-25
    2005-02
    2005-02-01
    NaT



```python
# 生成一个日期范围数组
np.arange('2005-02', '2005-03', dtype='datetime64[D]')
```




    array(['2005-02-01', '2005-02-02', '2005-02-03', '2005-02-04',
           '2005-02-05', '2005-02-06', '2005-02-07', '2005-02-08',
           '2005-02-09', '2005-02-10', '2005-02-11', '2005-02-12',
           '2005-02-13', '2005-02-14', '2005-02-15', '2005-02-16',
           '2005-02-17', '2005-02-18', '2005-02-19', '2005-02-20',
           '2005-02-21', '2005-02-22', '2005-02-23', '2005-02-24',
           '2005-02-25', '2005-02-26', '2005-02-27', '2005-02-28'],
          dtype='datetime64[D]')




```python
# 日期间隔
d = np.timedelta64(1, 'D')
x = np.datetime64('2009-01-01') - d
x, d
```




    (numpy.datetime64('2008-12-31'), numpy.timedelta64(1,'D'))



## 杂项
numpy 提供了丰富的科学计算 API，用到时可以查看 API 文档，不再赘述，以上以上涵盖了 numpy 的核心框架。



