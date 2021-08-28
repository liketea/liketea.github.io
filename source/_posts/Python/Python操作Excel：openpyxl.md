---
title: Python 操作 Excel：openpyxl
date: 2019-05-03 20:24:14
tags: 
    - Python
    - 教程
categories:
    - Python
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/0_eSQte3e-rJeH7bu8.jpg)

## 快速指引

用python读写excel的强大工具：openpyxl。本文只整理了openpyxl中那些使用最频繁的操作，其余的可自行搜索或查看[官方文档](https://openpyxl.readthedocs.io/en/stable/tutorial.html)，或者[中文文档](http://www.osgeo.cn/openpyxl/index.html#)。

### openpyxl安装

```
$ pip install openpyxl
```

### openpyxl使用


```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
import openpyxl as opx
from openpyxl.utils import get_column_letter
```

## workbook级操作


```python
# 创建一个workbook对象，默认只含有一个sheet
wb = opx.Workbook()
print wb

# 加载已有的Workbook文件，返回一个Workbook对象
wb_exist = opx.load_workbook('./learn.xlsx')
print wb_exist

# 关闭workbook，如果Workbook已打开则关闭，只会影响到read_only和write_only模式
wb_exist.close()
```

    <openpyxl.workbook.workbook.Workbook object at 0x10966fa50>
    <openpyxl.workbook.workbook.Workbook object at 0x10968ee90>



```python
# 保存Workbook
wb.save('./5-3.xlsx')
```

## Worksheet级操作

### 获取Worksheet对象


```python
# 激活第一个worksheet
ws = wb.active

# 创建新的worksheet，如果表名已被占用则在表名后加123
ws1 = wb.create_sheet('Sheet1')
ws2 = wb.create_sheet('sheet2')
print ws, ws1, ws2

# 获取Worksheet对象
ws1 = wb['Sheet1']
print ws1

# 遍历所有worksheets
for wse in wb.worksheets:
    print wse.title

```

    <Worksheet "Sheet"> <Worksheet "Sheet1"> <Worksheet "sheet2">
    <Worksheet "Sheet1">
    Sheet
    Sheet1
    sheet2


### 获取Worksheet对象的属性


```python
# 返回所有worksheets的名字
print wb.sheetnames

# 获取Worksheet的名字
print ws.title

# 获取Worksheet最大行和最大列，初始时只有一行一列
print ws.max_column,ws.max_row
```

    [u'Sheet0', u'Sheet1', u'sheet2', u'Sheet0 Copy']
    Sheet0
    1 1


### 操作Worksheet


```python
# 更改Worksheet的表名
ws.title = 'Sheet0'
print ws.title

# 更改表名背景颜色
ws.sheet_properties.tabColor = "1072BA"

# 复制worksheet
ws_copy = wb.copy_worksheet(ws)
print ws_copy
```

    Sheet0
    <Worksheet "Sheet0 Copy1">


### Worksheet行列操作


```python
# 在Worksheet的max_row后面追加一行数据，序列默认从第一列添加，不足则补None
ws.append([1,2])
tuple(ws.values)
```




    ((1, 2),)




```python
# 也可传入字典，key对应了列
ws.append({1:3, 'C': 5})
tuple(ws.values)
```




    ((1, 2, None), (3, None, 5))



### Worksheet插入/删除行或列


```python
# 在第3行前面插入行，如果参数超出了当前范围则什么也不做
ws.insert_rows(1)
tuple(ws.values)
```




    ((None, None, None), (1, 2, None), (3, None, 5))




```python
ws.delete_rows(idx=3,amount=1)
tuple(ws.values)
```




    ((None, None, None), (1, 2, None))



## Cell级操作

### 获取Cell对象


```python
# 获取单个Cell
cell_a1 = ws['A1']
cell_a1 = ws.cell(row=1, column=1)
print cell_a1

# 当一个worksheet在内存中被创建时，它不包含任何Cell，只有当Cell被首次访问时才被创建
for r in range(3):
    for c in range(2):
        ws.cell(row=r+1, column=c+1)

# 获取单行Cell、获取单列Cell，返回一个单元格对象组成的元组
print ws[1], len(ws[1])
print ws['A'], len(ws['A'])

# 获取多行多列
print '前三列', ws['A':'C']
print '前两行：', ws[1:2]

# 获取一个区域
print 'A1:C2：',ws['A1':'C2']

```

    <Cell u'Sheet0'.A1>
    (<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.B1>, <Cell u'Sheet0'.C1>) 3
    (<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.A2>, <Cell u'Sheet0'.A3>) 3
    前三列 ((<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.A2>, <Cell u'Sheet0'.A3>), (<Cell u'Sheet0'.B1>, <Cell u'Sheet0'.B2>, <Cell u'Sheet0'.B3>), (<Cell u'Sheet0'.C1>, <Cell u'Sheet0'.C2>, <Cell u'Sheet0'.C3>))
    前两行： ((<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.B1>, <Cell u'Sheet0'.C1>), (<Cell u'Sheet0'.A2>, <Cell u'Sheet0'.B2>, <Cell u'Sheet0'.C2>))
    A1:C2： ((<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.B1>, <Cell u'Sheet0'.C1>), (<Cell u'Sheet0'.A2>, <Cell u'Sheet0'.B2>, <Cell u'Sheet0'.C2>))


### 遍历行/列/单元格对象

遍历用 `ws.iter_rows` 和 `ws.iter_cols` 就够了！！


```python
# 按行列号遍历每一行，带min max参数时不受已激活范围的影响
for row in ws.iter_rows(min_row=1,max_row=2,min_col=1,max_col=3):
    print row
```

    (<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.B1>, <Cell u'Sheet0'.C1>)
    (<Cell u'Sheet0'.A2>, <Cell u'Sheet0'.B2>, <Cell u'Sheet0'.C2>)



```python
# 遍历每一列，不带min max参数时，只返回激活范围内的单元格
for col in ws.iter_cols():
    print col
```

    (<Cell u'Sheet0'.A1>, <Cell u'Sheet0'.A2>, <Cell u'Sheet0'.A3>)
    (<Cell u'Sheet0'.B1>, <Cell u'Sheet0'.B2>, <Cell u'Sheet0'.B3>)
    (<Cell u'Sheet0'.C1>, <Cell u'Sheet0'.C2>, <Cell u'Sheet0'.C3>)



```python
# 行优先遍历每个单元格，ws.iter_rows()和ws.rows效果相同，但前者可自定义参数
for row in ws.iter_rows():
    for cell in row:
        print cell
```

    <Cell u'Sheet0'.A1>
    <Cell u'Sheet0'.B1>
    <Cell u'Sheet0'.C1>
    <Cell u'Sheet0'.A2>
    <Cell u'Sheet0'.B2>
    <Cell u'Sheet0'.C2>
    <Cell u'Sheet0'.A3>
    <Cell u'Sheet0'.B3>
    <Cell u'Sheet0'.C3>



```python
# 遍历区域
for row in ws['a1:c2']:
    for cell in row:
        print cell
```

    <Cell u'Sheet0'.A1>
    <Cell u'Sheet0'.B1>
    <Cell u'Sheet0'.C1>
    <Cell u'Sheet0'.A2>
    <Cell u'Sheet0'.B2>
    <Cell u'Sheet0'.C2>



```python
# 遍历值
for row in ws.iter_rows(min_row=1,max_col=2,values_only=True):
    print row
```

    (None, None)
    (1, 2)
    (None, None)


### 获取单元格的属性


```python
cell = ws['A1']
print cell.value
```

    None


### 修改Cell的属性

#### 修改单元格的值


```python
# 修改单元格的值
ws['A1'] = 0
print ws['A1'].value

# 修改一个区域的值，需要逐个赋值
for r in ws['a1':'c3']:
    for c in r:
        c.value = 3
print tuple(ws.values)
```

    0
    ((3, 3, 3), (3, 3, 3), (3, 3, 3))


#### 修改单元格的格式

```
单元格的默认属性:

>>> font = Font(name='Calibri',
...                 size=11,
...                 bold=False,
...                 italic=False,
...                 vertAlign=None,
...                 underline='none',
...                 strike=False,
...                 color='FF000000')
>>> fill = PatternFill(fill_type=None,
...                 start_color='FFFFFFFF',
...                 end_color='FF000000')
>>> border = Border(left=Side(border_style=None,
...                           color='FF000000'),
...                 right=Side(border_style=None,
...                            color='FF000000'),
...                 top=Side(border_style=None,
...                          color='FF000000'),
...                 bottom=Side(border_style=None,
...                             color='FF000000'),
...                 diagonal=Side(border_style=None,
...                               color='FF000000'),
...                 diagonal_direction=0,
...                 outline=Side(border_style=None,
...                              color='FF000000'),
...                 vertical=Side(border_style=None,
...                               color='FF000000'),
...                 horizontal=Side(border_style=None,
...                                color='FF000000')
...                )
>>> alignment=Alignment(horizontal='general',
...                     vertical='bottom',
...                     text_rotation=0,
...                     wrap_text=False,
...                     shrink_to_fit=False,
...                     indent=0)
>>> number_format = 'General'
>>> protection = Protection(locked=True,
...                         hidden=False)
```


```python
from openpyxl.styles import PatternFill, Border, Side, Alignment, Protection, Font
```


```python
# 以修改单元格的字体为例
font = Font(name='Calibri',
                 size=16,
                 bold=False,
                 italic=False,
                 vertAlign=None,
                 underline='none',
                 strike=False,
                 color='FF000000')
alignment=Alignment(horizontal='left',
                     vertical='center',
                     text_rotation=0,
                     wrap_text=False,
                     shrink_to_fit=False,
                     indent=0)
ws['a1'] = 9999
ws['a1'].font = font
ws['a1'].alignment = alignment
```


```python
wb.save('./learn_openpyxl.xlsx')
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/dadd.png)

## 改进模式

有时，您需要打开或写入非常大的XLSX文件，而OpenPYXL中的常见例程将无法处理该负载。幸运的是，有两种模式使您能够以（接近）恒定的内存消耗来读写无限量的数据。

### 只读模式


```python
wb_read = opx.load_workbook(filename='./learn_openpyxl.xlsx', read_only=True)
wb_read
```




    <openpyxl.workbook.workbook.Workbook at 0x1096f4110>




```python
ws_read = wb_read.active
print ws_read.max_row,ws_read.max_column
```

    3 3



```python
for row in ws_read.iter_rows(values_only=True):
    print row
```

    (9999L, 3L, 3L)
    (3L, 3L, 3L)
    (3L, 3L, 3L)



```python
wb_read.close()
wb_read
```




    <openpyxl.workbook.workbook.Workbook at 0x1096f4110>



### 只写模式

- 与普通工作簿不同，新创建的只写工作簿不包含任何工作表；必须使用 create_sheet() 方法。
- 在只写工作簿中，只能使用 append() . 不能在任意位置用 cell() 或 iter_rows() .
- 它能够导出无限量的数据（甚至超过了Excel的实际处理能力），同时将内存使用量保持在10MB以下。
- 只写工作簿只能保存一次。之后，每次试图将工作簿或append（）保存到现有工作表时，都会引发 openpyxl.utils.exceptions.WorkbookAlreadySaved 例外。
- 在添加单元格之前，必须创建实际单元格数据之前出现在文件中的所有内容，因为在此之前必须将其写入文件。例如， freeze_panes 应在添加单元格之前设置。


```python
# load_workbook本地读取的Excel没有只写权限
wb_write = opx.Workbook(write_only=True)
wb_write
```




    <openpyxl.workbook.workbook.Workbook at 0x1096cba10>




```python
# 只写模式的Workbook创建后，没有sheet，需要手动创建
print wb_write.worksheets
ws_write = wb_write.create_sheet()
print ws_write
```

    []
    <WriteOnlyWorksheet "Sheet">



```python
# 只写模式的worksheet没有cell属性，也不能通过索引来获取单元格
ws_write.cell
```


    ---------------------------------------------------------------------------

    AttributeError                            Traceback (most recent call last)

    <ipython-input-39-5164431d4a6c> in <module>()
          1 # 只写模式的worksheet没有cell属性，也不能通过索引来获取单元格
    ----> 2 ws_write.cell
    

    AttributeError: 'WriteOnlyWorksheet' object has no attribute 'cell'



```python
ws_write.append([1,2,3])
```


```python
# 如果希望为单元格添加格式或注释，可以使用WriteOnlyCell
from openpyxl.cell import WriteOnlyCell
from openpyxl.comments import Comment
from openpyxl.styles import Font

cell = WriteOnlyCell(ws, value="hello world")
cell.font = Font(name='Courier', size=36)
cell.comment = Comment(text="A comment", author="Author's Name")
ws.append([cell, 3.14, None])
```


```python
wb_write.save('./write_only.xlsx')
```
