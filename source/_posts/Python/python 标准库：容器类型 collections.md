---
title: python 标准库：容器类型 collections
date: 2019-05-03 20:24:14
tags: 
    - Python
    - 教程
categories:
    - Python
---

collections提供了一组高效的容器数据类型，可以作为Python通用容器(tuple、list、dict)的补充。熟练掌握这些容器类型，不仅可以让我们写出的代码更加Pythonic，也可以提高我们程序的运行效率。

构造方法|说明
:---|:---
namedtuple()|创建拥有命名域的元组
deque|创建双端队列
Counter|创建计数器
OrderedDict|创建有序字典
defaultdict|创建具有默认值的字典

## 命名元组——namedtuple()
我们可以为元组中的每个位置起一个名字，名字会被作为对象的属性域，增强了代码的可读性。
此外，命名元组并不会为每个实例创建，所以命名元组是轻量级的，并不会比普通元组差。


```python
from collections import namedtuple
```


```python
# 定义一个命名元组，并创建一个实例
point = namedtuple('Point',['x','y'])
p = point(3,4)
p
```

    Point(x=3, y=4)

```python
# 可以通过实例的属性名访问元组中不同的域，也可以像普通元祖一样使用
print p.x,p.y
print p[0],p[-1]
```

    3 4
    3 4



```python
# 从一个已有的序列创建
point._make([3,4])
```




    Point(x=3, y=4)




```python
# 转化为字典
p._asdict()
```




    OrderedDict([('x', 3), ('y', 4)])



## 双向列表——deque
`class collections.deque([iterable[, maxlen]])`

使用list存储数据时，按索引访问元素很快（O(1)），但是插入和删除元素就很慢了（O(n)），deque是为了高效实现插入和删除操作的双向列表，适合用于队列和栈：

1. dequeue在两端的操作O(1)，方便高效的实现各种栈和队列
2. dequeue在中间的操作O(n)，如需随机存取还应使用普通列表




```python
from collections import deque
```


```python
# 创建双端列表
Q = deque(range(10))
Q
```




    deque([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])




```python
# 默认右端操作
Q.append(10)
print Q
Q.pop()
print Q
```

    deque([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    deque([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])



```python
# 支持左端操作
Q.appendleft(-1)
print Q
Q.popleft()
print Q
```

    deque([-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    deque([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])



```python
# 数组旋转
Q = deque([1,2,3,4,5])
Q.rotate(2)
Q
```




    deque([4, 5, 1, 2, 3])




```python
# 实现一个无尽换换的跑马灯
import sys
import time

fancy_loading = deque('>--------------------')

while True:
    print '\r%s' % ''.join(fancy_loading),
    fancy_loading.rotate(1)
    sys.stdout.flush()
    time.sleep(0.1)
```

## 计数器——Counter


```python
from collections import Counter
```

### 创建计数器
`class collections.Counter([iterable-or-mapping])`

可以由任意的可迭代对象来创建计数器，Counter会对可迭代对象中的相同对象计数统计，返回一个计数字典，以不同对象为key，以该对象出现次数为value。


```python
a = Counter()
a
```




    Counter()




```python
b = Counter(range(3))
b
```




    Counter({0: 1, 1: 1, 2: 1})




```python
c = Counter('hello')
c
```




    Counter({'e': 1, 'h': 1, 'l': 2, 'o': 1})




```python
d = Counter(a=1,b=2.1)
d
```




    Counter({'a': 1, 'b': 2.1})




```python
x = Counter({'a':1,'b':0,'c':-2})
x
```




    Counter({'a': 1, 'b': 0, 'c': -2})



### Counter对象是字典的子类
Counter对象与内置dict的显著差异是Counter会自动为新的键值创建默认值0


```python
# 不存在的键，默认返回0，但是如果只是访问不会自动添加新的键，等价于x.get('d',0)
print x['d']
x['d'] += 1
print x
```

    0
    Counter({'a': 1, 'd': 1, 'b': 0, 'c': -2})



```python
# 存在性
'a' in x
```




    True




```python
# 返回视图
print x.keys()
print x.values()
print x.items()
```

    ['a', 'c', 'b', 'd']
    [1, -2, 0, 1]
    [('a', 1), ('c', -2), ('b', 0), ('d', 1)]


### Counter的常用方法


```python
x = Counter({'a':2,'b':0,'c':-2})
x
```




    Counter({'a': 2, 'b': 0, 'c': -2})



#### elements()
elements方法用户迭代地展示Counter内的所有元素，按元素的计数重复该元素，如果该元素的计数小于1，那么Counter就会忽略该元素，不进行展示。


```python
list(x.elements())
```




    ['a', 'a']



#### most_common([k])
most_common函数返回Counter中次数最多的k个元素，如果N没有提供或者是None，那么就会返回所有元素。


```python
x.most_common()
```




    [('a', 2), ('b', 0), ('c', -2)]




```python
x.most_common(2)
```




    [('a', 2), ('b', 0)]



#### clear()
清除所有元素的统计次数


```python
x.clear()
x
```




    Counter()



#### subtract([iterable-or-mapping])
substract方法接收一个可迭代或者可映射的对象，针对每个元素减去参数中的元素对应的次数。


```python
x.subtract('abc')
x
```




    Counter({'a': 1, 'b': -1, 'c': -3})



#### update([iterable-or-mapping])
update方法的功能和substract方法的功能正好相反，它接收一个可迭代或者可映射的对象，针对每个元素加上参数中的元素对应的次数。


```python
x.update('bcd')
x
```




    Counter({'a': 1, 'b': 0, 'c': -2, 'd': 1})



#### Counter对象运算
注意：Counter对象的运算会自动忽略掉小于等于0的元素，也常常通过这种方法去除Counter对象中小于等于0的元素。


```python
x = Counter({'a':1,'b':0,'c':-2,'d':3})
y = Counter({'a':2,'d':1,'e':2})
x,y
```




    (Counter({'a': 1, 'b': 0, 'c': -2, 'd': 3}), Counter({'a': 2, 'd': 1, 'e': 2}))




```python
x + y
```




    Counter({'a': 3, 'd': 4, 'e': 2})




```python
x - y
```




    Counter({'d': 2})




```python
x & y
```




    Counter({'a': 1, 'd': 1})




```python
x | y
```




    Counter({'a': 2, 'd': 3, 'e': 2})




```python
# 仅在python3支持
+x
Counter({'a': 1, 'd': 3})
```


    ---------------------------------------------------------------------------

    TypeError                                 Traceback (most recent call last)

    <ipython-input-35-a5890c994b78> in <module>()
          1 # 仅在python3支持
    ----> 2 +x
    

    TypeError: bad operand type for unary +: 'Counter'



## 有序字典——orderedDict

使用dict时，Key是无序的。在对dict做迭代时，我们无法确定Key的顺序。如果要保持Key的顺序，可以用OrderedDict


```python
from collections import OrderedDict
```

    



```python
od = OrderedDict()
od['a'] = 1
od['c'] = 1
od['b'] =2
for k in od:
    print k,od[k]
```

    a 1
    c 1
    b 2


## 默认类型字典——defaultdict
`class collections.defaultdict([default_factory[, ...]])¶`

使用dict时，如果引用的Key不存在，就会抛出KeyError。如果希望key不存在时，为key设置一个默认值，就可以用defaultdict。

```python
from collections import defaultdict
```

如果我们想从无到有构建一个字典{key:list}，通常有以下三种方式，可以看到使用defaultdict用时最少。

```python
# 使用get追加的方式最慢，因为每次都生成新的副本，O(n)
start = time.time()

dic_1 = {}
for i in range(100000):
    dic_1[i%2] = dic_1.get(i%2,[]) + [i]
    
print '%.3f'%(time.time() - start)
25.481

# 使用setdefault的方式，很快
start = time.time()
dic_3 = {}
for i in range(100000):
    dic_3.setdefault(i%2,[]).append(i)
print '%.3f'%(time.time() - start)
0.080

# 使用defaultdict的方式
start = time.time()
dic_2 = defaultdict(list)
for i in range(100000):
    dic_2[i%2].append(i)
print '%.3f'%(time.time() - start)
0.065
```

值得注意的是，一旦我们引用了defaultdict中的某个key，defaultdict就会自动添加该key并为之赋予对应类型的默认值，因此使用x in dict时要格外注意：

```python
x = collections.defaultdict(int)
print x
print 2 in x
print x[2]
print x
print 2 in x

defaultdict(<type 'int'>, {})
False
0
defaultdict(<type 'int'>, {2: 0})
True
```


## 引用
[8.3. collections — High-performance container datatypes](https://docs.python.org/2/library/collections.html#defaultdict-objects)