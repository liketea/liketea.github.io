---
title: python 标准库：二分查找 bisect
date: 2019-05-03 20:24:14
tags: 
    - Python
    - 教程
categories:
    - Python
---


```python
import bisect
```

使用Bisect二分查找模块前必须保证列表已经是有序的，bisect模块提供以下功能：

1. bisect：返回待插入元素的插入位置，保证数组仍然有序；
    1. bisect(a,x,lo=0,hi=len(a)):如果相同，则插入右侧，满足all(val > x for val in a[i:hi])，all(val <= x for val in a[lo:i])
    2. bisect_left:如果相同则插入左侧，all(val < x for val in a[lo:i])， all(val >= x for val in a[i:hi])
    3. bisect_right:同bisect
2. insort：将给定元素插入到有序表中，保证数组仍然有序；
    1. insort(a,x,lo=0,hi=len(a)):等价于a.insert(bisect.bisect(a, x, lo, hi), x)
    2. insort_left:等价于a.insert(bisect.bisect_left(a, x, lo, hi), x)
    3. insort_right:等价于insort


```python
a = [2,3,4,5,6,6,10]
```

### bisect


```python
bisect.bisect(a,6)
```




    6




```python
bisect.bisect(a,6.1)
```




    6




```python
bisect.bisect_left(a,6)
```




    4




```python
bisect.bisect_left(a,6.1)
```




    6




```python
bisect.bisect_right(a,6)
```




    6




```python
bisect.bisect_right(a,6.1)
```




    6



### insort


```python
a = [2,3,4,5,6,6,10]
```


```python
bisect.insort(a,6)
a
```




    [2, 3, 4, 5, 6, 6, 6, 10]




```python
bisect.insort(a,6.1)
a
```




    [2, 3, 4, 5, 6, 6, 6, 6.1, 10]




```python
bisect.insort_left(a,4)
a
```




    [2, 3, 4, 4, 5, 6, 6, 6, 6.1, 10]




```python
bisect.insort_right(a,10)
a
```




    [2, 3, 4, 4, 5, 6, 6, 6, 6.1, 10, 10]



### 常用查询操作


```python
def index(a, x):
    '返回第一个等于x的元素下标'
    i = bisect_left(a, x)
    if i != len(a) and a[i] == x:
        return i
    raise ValueError

def find_lt(a, x):
    '返回最后一个小于x的元素下标'
    i = bisect_left(a, x)
    if i:
        return a[i-1]
    raise ValueError

def find_le(a, x):
    '返回最右侧小于等于x的元素下标'
    i = bisect_right(a, x)
    if i:
        return a[i-1]
    raise ValueError

def find_gt(a, x):
    'Find leftmost value greater than x'
    i = bisect_right(a, x)
    if i != len(a):
        return a[i]
    raise ValueError

def find_ge(a, x):
    'Find leftmost item greater than or equal to x'
    i = bisect_left(a, x)
    if i != len(a):
        return a[i]
    raise ValueError
```
