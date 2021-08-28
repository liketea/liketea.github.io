---
date: 2018-01-05 15:08
status: public
tags: python
title: python-赋值-浅拷贝-深拷贝图例
---

```python
import objgraph
```

## Python的对象模型

Python中一切都是对象，而变量则是对对象的引用：

1. 对象：分配的一块内存，有足够空间去表示他们所代表的值；
2. 变量：是命名空间（字典）中的key，指向它所引用的对象；
3. 引用：变量到对象的连接，以指针的形式实现；


![](~/屏幕快照 2016-10-10 22.14.15.png)

关于变量-对象-引用之间的关系：

1. 变量只能引用对象，绝不会引用其其他变量；
2. 一个变量同一时刻只能引用一个对象，但一个对象同时间可以被多个变量引用；
3. 容器对象可以连接到子对象；

本文用到的辅助工具：

1. id(object): 返回对象的内存地址；
2. a is b: 判断两个对象是否为同一对象；
3. a == b: 判断两个对象是否等值；
4. objgraph.show_refs(objects): 生成从对象objects开始的对象引用图例，参见[文档](https://mg.pov.lt/objgraph/)；

## 赋值

Python中变量定义、函数定义、函数传参、类定义、模块导入等操作本质上都是赋值操作，遵循同样的赋值逻辑：Python中的赋值只是创建引用，不会拷贝对象。

> a = b

C语言的赋值："拷贝-写入"模式（拷贝b对象的值，写入a内存）

python语言的赋值：“解引用-创建引用”模式（将变量b解引用为对象，创建变量a到对象b的引用）


```python
b = "hello"
a=b
print(id(a),id(b))
print(a is b)
objgraph.show_refs([a,b])
```

    4457019016 4457019016
    True





![svg](~/output_6_1.svg)




```python
b ="no"
print(id(a),id(b))
print(a is b)
objgraph.show_refs([a,b])
```

    4457019016 4417389320
    False





![svg](~/output_7_1.svg)



### 变量赋值、对象原地修改

- 变量赋值：对变量赋值，只是使该变量指向了新的对象；


```python
a = [1,2,3]
aa = a
print(id(a),id(aa))
objgraph.show_refs([a,aa])
```

    4457160136 4457160136





![svg](~/output_10_1.svg)




```python
a = {'a':22,'b':33}
print(id(a),id(aa))
objgraph.show_refs([a,aa])
```

    4457132464 4457160136





![svg](~/output_11_1.svg)



- 原地修改：对容器对象进行原地修改，只是改变了子对象的引用，不改变容器对象的地址


```python
a = [1,2,3]
b = 1
print(id(a),id(b))
objgraph.show_refs([a,b])
```

    4457143432 4414302400





![svg](~/output_13_1.svg)




```python
a[0] = 11
print(id(a),id(b))
objgraph.show_refs([a,b])
```

    4457143432 4414302400





![svg](~/output_14_1.svg)



按照是否支持原地修改，Python中的内置数据类型可分为两大类：

1. 可变类型：支持原地修改，如列表、字典；
2. 不可变类型：不支持原地修改，如元组、字符串等列表、字典以外的内置类型；

### 共享引用

共享引用：多个变量同时引用了同一个对象；

- 对其中一个变量赋值，不会影响到其他变量；


```python
a = b = c = [1,2]
print(id(a),id(b),id(c))
objgraph.show_refs([a,b,c])
```

    4454376648 4454376648 4454376648





![svg](~/output_19_1.svg)




```python
c = None
print(id(a),id(b),id(c))
objgraph.show_refs([a,b,c])
```

    4454376648 4454376648 4414019688





![svg](~/output_20_1.svg)



- 对其中一个进行原地修改则会同时改变其他变量；


```python
b[0]='change'
print(id(a),id(b),id(c))
objgraph.show_refs([a,b,c])
```

    4454376648 4454376648 4414019688





![svg](~/output_22_1.svg)



- Python会缓存复用小的整数(-5到256)和字符串以提高效率，不同版本缓存范围不同，缓存字符串的行为令人费解，尽量不要在应用程序中使用这个特性；


```python
# 缓存整数范围：[-5~256]
begin = False

m = n= float('-inf')
for i in range(-10000,10000):
    x = 0+i
    y = 0+i
    if (not begin) and id(x) == id(y):
        begin = True
        m = i
    if begin and id(x) != id(y):
        n = i - 1
        break

print('整数缓存范围：[{},{}]'.format(m,n))
```

    整数缓存范围：[-5,256]



```python
# 缓存字符串长度范围：20以内
x = 'a' * 20
y = 'a' * 20
print(x is y)
objgraph.show_refs([x,y])
```

    True





![svg](~/output_25_1.svg)




```python
const = 20
xx = 'a' * const
yy = 'a' * const
print(xx is yy)
objgraph.show_refs([xx,yy])
```

    False





![svg](~/output_26_1.svg)



##  显式拷贝

赋值不会发生拷贝，如果想要生成新的副本则需要显式地进行拷贝。

###  浅拷贝

copy.copy(obj)通过拷贝生成一个新对象，新对象只拷贝了原对象的壳，但仍共享引用原对象的内容，也就是说新对象与原对象的id不同，但是新对象中的子对象与原始对象中的子对象id相同。


```python
import copy
a = [[1,2],[6,5]]
b = copy.copy(a)
print(a,b)
print(id(a),id(b))
print(id(a[0]),id(b[0]))
objgraph.show_refs([a,b])
```

    [[1, 2], [6, 5]] [[1, 2], [6, 5]]
    4456953352 4457062536
    4456953160 4456953160





![svg](~/output_31_1.svg)



- 对新旧对象的原地修改不会影响到另外一个对象


```python
a[1]='ni'
print(a,b)
objgraph.show_refs([a,b])
```

    [[1, 2], 'ni'] [[1, 2], [6, 5]]





![svg](~/output_33_1.svg)



- 对新旧对象的属性和内容进行原地修改则会影响到另一对象


```python
a[0][0]='aaa'
print(a,b)
objgraph.show_refs([a,b])
```

    [['aaa', 2], [6, 5]] [['aaa', 2], 'ni']





![svg](~/output_35_1.svg)



###  深拷贝

copy.deepcopy(obj)，通过“递归拷贝”原对象生成新对象，新对象与原始对象除了内容相同外没有任何联系。


```python
a = [[1,2],[6,5]]
b = copy.deepcopy(a)
print(a,b)
print(id(a),id(b))
print(id(a[0]),id(b[0]))
objgraph.show_refs([a,b])
```

    [[1, 2], [6, 5]] [[1, 2], [6, 5]]
    4457080328 4456172872
    4457082376 4457081672





![svg](~/output_38_1.svg)



新旧对象互不影响


```python
b[1]='ni'
print(a,b)
objgraph.show_refs([a,b])
```

    [[1, 2], [6, 5]] [[1, 2], 'ni']





![svg](~/output_40_1.svg)




```python
a[0][0]='aaa'
print(a,b)
objgraph.show_refs([a,b])
```

    [['aaa', 2], [6, 5]] [[1, 2], 'ni']





![svg](~/output_41_1.svg)



##  隐式浅拷贝

除了使用显式拷贝来生成原对象的副本外，需要特别注意的是，Python内置的一些方法会“隐式”地对原始对象进行浅拷贝，比如类型转换函数、列表切片、运算符重载的`+` `*`，这往往会导致Python中某些看起来很奇怪的现象。

###  类型转换函数


```python
L = [[1],[2],[3]]
T = tuple(L)
print(L,T)
print(id(L),id(T))
print(id(L[0]),id(T[0]))
objgraph.show_refs([L,T])
```

    [[1], [2], [3]] ([1], [2], [3])
    4456981064 4457278776
    4456898440 4456898440





![svg](~/output_45_1.svg)




```python
L[0]=99
print(L,T)
objgraph.show_refs([L,T])
```

    [99, [2], [3]] ([9], [2], [3])





![svg](~/output_46_1.svg)




```python
L[0][0]=9
print(L,T)
objgraph.show_refs([L,T])
```

    [[9], [2], [3]] ([9], [2], [3])





![svg](~/output_47_1.svg)



###  合并重复操作

`+` `*`用于列表，相当于浅拷贝了原始对象，产生多个副本，新副本中的每个子对象都还是原始对象中的子对象，任何对这些子对象的原地修改都会自动应用到所有新的副本中。


```python
L=[0,1]
R = L+L
print(L,R)
objgraph.show_refs([L,R])
```

    [0, 1] [0, 1, 0, 1]





![svg](~/output_49_1.svg)




```python
L=[0,1]
R = L*3
print(L,R)
objgraph.show_refs([L,R])
```

    [0, 1] [0, 1, 0, 1, 0, 1]





![svg](~/output_50_1.svg)




```python
L=[0,1]
J=['a','b']
S=[L,J]
R=S*3
print(L,J,S,R)
objgraph.show_refs([L,J,S,R])
```

    [0, 1] ['a', 'b'] [[0, 1], ['a', 'b']] [[0, 1], ['a', 'b'], [0, 1], ['a', 'b'], [0, 1], ['a', 'b']]





![svg](~/output_51_1.svg)




```python
L[0]=99
print(L,J,S,R)
objgraph.show_refs([L,J,S,R])
```

    [99, 1] ['a', 'b'] [[99, 1], ['a', 'b']] [[99, 1], ['a', 'b'], [99, 1], ['a', 'b'], [99, 1], ['a', 'b']]





![svg](~/output_52_1.svg)



###  切片
切片虽然返回了新的对象，但是新对象中的子对象还是原始对象中的子对象


```python
L=[[0],[1],[2],[3],[4],[5]]
Q=L[1::2]
print(L,Q)
objgraph.show_refs([L,Q])
```

    [[0], [1], [2], [3], [4], [5]] [[1], [3], [5]]





![svg](~/output_54_1.svg)



对新生成的对象原地修改并不会改变原对象


```python
Q[0]='first'
print(L,Q)
objgraph.show_refs([L,Q])
```

    [[0], [1], [2], [3], [4], [5]] ['first', [3], [5]]





![svg](~/output_56_1.svg)



对新对象的元素进行原地修改会影响到原对象


```python
Q[1][0]=333
print(L,Q)
objgraph.show_refs([L,Q])
```

    [[0], [1], [2], [333], [4], [5]] ['first', [333], [5]]





![svg](~/output_58_1.svg)



##  拷贝不可变对象

没有必要拷贝不可变对象，因为完全不用担心会不经意改动它们。
如果对不可变对象进行拷贝操作，仍然会得到原对象


```python
T=(1,2,3)
F=copy.copy(T)
print(T,F)
objgraph.show_refs([T,F])
```

    (1, 2, 3) (1, 2, 3)





![svg](~/output_61_1.svg)




```python
T=([1],[2],[3])
F=copy.copy(T)
print(T,F)
objgraph.show_refs([T,F])
```

    ([1], [2], [3]) ([1], [2], [3])





![svg](~/output_62_1.svg)




```python
T[1][0]='ni'
print(T,F)
objgraph.show_refs([T,F])
```

    ([1], ['ni'], [3]) ([1], ['ni'], [3])





![svg](~/output_63_1.svg)



## 烤全羊
下面的例子融合了Python中各种常见的引用关系：


```python
li = [1,'string',('tuple',1),['list',3,('gh',4),{'i':'j',5:'k'}]
      ,{'di':2,3:'l',(8,'m'):'n','list':['l','i','s','t']}]
```


```python
objgraph.show_refs([li], filename='sample-graph.png')
```




![svg](~/output_66_0.svg)



下面例子反应了在Python自动缓存较小整数时的引用关系


```python
import copy
a = [1,[2,3,4]]
b = a
c = copy.copy(a)
d = copy.deepcopy(a)
e = a+a
f = list(a)
objgraph.show_refs([a,b,c,d,e,f])
```




![svg](~/output_68_0.svg)