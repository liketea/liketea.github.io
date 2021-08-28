---
title: Python IO：OJ 输入输出
date: 2019-05-03 20:24:14
tags: 
    - Python
    - 教程
categories:
    - Python
---

一些公司的在线笔试会承包给第三方，第三方平台通常会采用 OJ(Online Judge) 判题系统，OJ 并不会像 LeetCode 那样给定函数声明，而是需要我们自己去处理输入和输出。

OJ 平台的输入数据有各种各样的格式，再加上 python2.x 和 python3.x 在输入输出方法上又有很大差异，这使得在 OJ 平台上使用Python处理输入输出显得有点复杂，因此有必要做一下整理。

## python2.7
### 输入
python2.7会默认将所有输入读取为字符串。

#### sys.stdin标准输入
sys.stdin会读入输入的所有字符，包括每行结尾的换行符。

方式一：读入所有字符，返回字符串，如果没有任何输入则返回''。

```python
In [5]: content = sys.stdin.read()
abcd
10 11 12 13
ab bc cd de
^D
In [7]: content
Out[7]: 'abcd\n10 11 12 13\nab bc cd de\n'
```

方式二：按行读入所有字符，返回由行字符串组成的迭代器，如果没有任何输入则返回[]。

```python
In [8]: lines = sys.stdin.readlines()
abcd
10 11 12 13
ab bc cd de^D
In [9]: lines
Out[9]: ['abcd\n', '10 11 12 13\n', 'ab bc cd de']
```
以上两种读入方式在OJ中基本用不到，更常用到的是第三种方式。

方式三：读入一行，返回该行字符串，如果没有任何输入则返回''

```python
In [16]: line = sys.stdin.readline()
abcd

In [17]: line
Out[17]: 'abcd\n'
```

通过标准输入读取数据的通用实例：

```python
# 1. 读入一个字符串
In [21]: line = sys.stdin.readline().strip()
abc

In [22]: line
Out[22]: 'abc'

# 2. 读入一个浮点数
In [23]: line = float(sys.stdin.readline().strip())
3.14

In [24]: line
Out[24]: 3.14

# 3. 读入一个字符串列表
In [26]: line = sys.stdin.readline().strip().split()
ab bc cde

In [27]: line
Out[27]: ['ab', 'bc', 'cde']

# 4. 读入一个整数列表
In [28]: line = map(int,sys.stdin.readline().strip().split())
10 11 12

In [29]: line
Out[29]: [10, 11, 12]

# 5. 读入k行整数列表
In [31]: lines = []

In [32]: for i in xrange(3):
    ...:     line = map(int,sys.stdin.readline().strip().split())
    ...:     lines.append(line)
    ...:
1 2 3
4 5 6
7 8 9

In [33]: lines
Out[33]: [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

# 6. 读入若干行整数列表
In [36]: lines = []

In [37]: count = 0

In [38]: while True:
    ...:     line = sys.stdin.readline().strip()
    ...:     if not line:
    ...:         break
    ...:     line = map(int, line.split())
    ...:     lines.append(line)
    ...:     count += 1
    ...:
1 2 3
4 5 6
7 8 9
10 11 12


In [39]: lines
Out[39]: [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]
```

#### raw_input()和input()
可以看到，通过标准输入读取每行数据需要手动去除行尾的换行符，而且代码量较大。python2.7提供了两个专门用于接收整行输入的函数raw_input()和input()，代码简介且会自动去除行尾的换行符，

1. raw_input()：将用户整行输入作为字符串返回，如果用户输入为空则返回''；
2. input()：将用户整行输入作为可执行的表达式，返回表达式结果，等价于eval(raw_input())，如果用户输入为空，则出错；

建议：强烈建议统一使用raw_input()读取输入；但如果输入为单个数值时使用input()会比较方便。

```python
# 1. 读入一个字符串
In [45]: line = raw_input()
abc

In [46]: line
Out[46]: 'abc'

# 2. 读入一个数值
In [1]: line = int(raw_input())
3

In [2]: line
Out[2]: 3

In [47]: line = input()
3.14

In [48]: line
Out[48]: 3.14

In [49]: type(line)
Out[49]: float

# 3. 读入一个字符串列表
In [50]: line = raw_input().split()
ab bc cde

In [51]: line
Out[51]: ['ab', 'bc', 'cde']

# 4. 读入一个整数列表
In [52]: line = map(int, raw_input().split())
10 11 12

In [53]: line
Out[53]: [10, 11, 12]

# 5. 读入k行整数列表
In [55]: for i in xrange(3):
    ...:     line = map(int,raw_input().split())
    ...:     lines.append(line)
    ...:
1 2 3
4 5 6
7 8 9

In [56]: lines
Out[56]: [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

# 6. 读入若干行整数列表
In [57]: lines = []

In [58]: count = 0

In [59]: while True:
    ...:     line = raw_input()
    ...:     if not line:
    ...:         break
    ...:     line = map(int,line.split())
    ...:     lines.append(line)
    ...:     count += 1
    ...:
1 2 3
4 5 6 7
8 9 10
11 12 13


In [60]: lines
Out[60]: [[1, 2, 3], [4, 5, 6, 7], [8, 9, 10], [11, 12, 13]]
```

### 输出
#### print 语句
python2.7的print为表达式语句，括号可带可不带，将对象的文本形式打印到sys.stdout，并在各项之间添加一个空格，并在行末添加一个换行符。如果不希望在行末添加换行符，则可以在最后一个元素后面加上逗号(注意此时并没有自动添加空格)，如果再次使用print进行输出时，默认会自动在新的输出内容和旧的输出之间添加空格。

```python
print 33,34
print 35
33 34
35
print 33,34,
print 35
33 34 35
```

相比python2，python3的print函数可定制化更强，如果要在python2中使用python3中的print语句，可以通过以下方式实现：

```python
In [68]: from __future__ import print_function

In [69]: print 2
  File "<ipython-input-69-9d8034018fb9>", line 1
    print 2
          ^
SyntaxError: invalid syntax


In [70]: print(1,2,3,sep='',end='')
123
```

#### 格式化字符串
python支持两种形式的格式化字符串：%语句和format函数。

format函数更加强大、灵活，一般格式为：

`'{位置/关键字:填充-对齐-宽度-类型}ohers{...}'.format(x,y,...)`

1. 格式串：每个格式串用花括号括起来
2. format函数：参数个数必须与格式串个数相同
3. 以函数传参的方式将format接受到的参数按照位置或关键字对应到每个格式串，然后每个参数按照格式串的格式替换到字符串中
4. 格式串的格式：位置/关键字:填充-对齐-宽度-类型

```python
# 填充-对齐-宽度-类型，注意会对浮点数进行四舍五入
x = 's1:{key:+^10s} s2:{2: <10s} int:{0:,d} float:{1:0>10.3f}'.format(100000,1.3456,'word2',key='word1')
print x
s1:++word1+++ s2:word2      int:100,000 float:000001.346

# 进制转换
y = '{0:b} {0:o} {0:x} {0:X}'.format(10)
print y
1010 12 a A
```

## python3.5
python3相对python2有很多不同，出于OJ实践考虑，暂时只需要了解以下内容即可。

### 输入

python3.中的标准输入与python2.x并无太大区别。

python3.x中没有raw_input()函数，但是python3.x中的input()函数等价于python2.x中的raw_input()函数。

```python
>>> input()
2 3 4
'2 3 4'
```

### 输出
python3.x中print()是一个打印函数，必须带括号，其原型为：

```python
print(value, ..., sep=' ', end='\n'
```

- 多个对象间默认以空格分隔
- 行末默认使用换行符

```python
print(23,34,sep=',',end=',')
print(35)
23,34,35
```

## OJ平台常见的输入输出模式
OJ平台的输入数据通常会有多组，并且格式多种多样。注意审题，千万不要在输入输出格式上出错，否则很难通过反馈结果找到这种错误。

### 只有一组输入

输入：

```
3 2
```

输出：

```
5
```

代码：只需要处理一组测试用例即可

```python
a,b = map(int, raw_input().split())
print a + b
```

### 预先知道输入数据的组数

输入：已知有k组测试数据以及每组数据的输入格式

```
2 3
22 33
...
```

输出：

```
5
55
...
```

代码：在3.1的基础上循环k次即可

```python
for _ in xrange(k):
    a,b = map(int, raw_input().split())
    print a + b
```

### 预先不知道数据的组数

输入：可能有多组测试数据

```
2 3
22 33
...
```

输出：对于每组数据，将结果单独作为一行输出

```
5
55
...
```

代码：一直读到文件末尾，raw_input会引发EOFError错误，而sys.stdin.readline()却不会引发EOFError错误，而是返回空串''。

```python
# 方式一：逐行读入，读到末尾结束
while True:
    # 注意此处不能strip，否则就变成了遇到空行结束
    line = sys.stdin.readline()
    if not line:
        break
    a,b = map(int,line.strip())
    print a+b       
        
# 方式二：整体读入
for line in sys.stdin.readlines():
    a,b = map(int,line.strip())
    print a+b

# 方式三：通过raw_input()报错识别文件末尾
try:
    while True:
        line = raw_input()
        a,b = map(int,line.strip())
        print a + b
except EOFError:
    pass                
```

总结: 选择python2.x中的raw_input()逐行读入，不知道数据组数时，通过EOFError结束。`

1. python2和python3的选择：为了避免混淆，建议只使用一种版本来刷OJ
2. 逐行读入和整体读入：逐行读入有更好的灵活性，使用逐行读入的方式就可以满足python在OJ上的所有输入要求
3. raw_input和readline：readline需要手动处理行末换行符，raw_input读到文件末尾会报错
4. raw_input和input：在python2中只有输入是单个数值时，才能用input，简单一些


