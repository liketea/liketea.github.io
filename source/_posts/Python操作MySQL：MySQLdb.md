---
title: Python 操作 MySQL：MySQLdb
date: 2019-05-03 20:24:53
tags: 
    - Python
    - 教程
    - 数据库
categories:
    - Python
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/hqdefault.jpg)

## 快速指引
MySQLdb 是用于Python链接Mysql数据库的接口，它实现了 Python 数据库 API 规范 V2.0，基于 MySQL C API 上建立的。

### MySQLdb安装
在命令行中执行：

```
$ pip install mysql-python

```

### MySQLdb使用

[MySQLdb Tutorials](https://dev.mysql.com/doc/connector-python/en/connector-python-tutorial-cursorbuffered.html)

#### `MySQLdb` 导入方式


```python
#!/usr/bin/python
# -*- coding: UTF-8 -*-
import MySQLdb
import time
```

### `MySQLdb` 一般流程

Python通过MySQLdb操作MySQL数据库的一般过程：


> 配置数据库参数->连接数据库->获取游标对象->构造SQL语句->执行SQL语句->提交事务(write)->关闭连接



```python
# 1. 配置数据库参数：参数字典
conf = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'db': 'didi',
    'charset': 'utf8'
}

# 2. 连接数据库：返回连接对象conn
conn = MySQLdb.connect(**conf)
print conn

# 3. 获取游标对象：cursor
cursor = conn.cursor(MySQLdb.cursors.DictCursor)
print cursor

# 4. 构造SQL语句和参数序列:
sql_table_str = 'g_team_combine_activity_city_map'
sql_fields = ['id', 'activity_id', 'city_id', 'create_time']
sql_fields_str = '({})'.format(','.join(sql_fields))
sql_values_str = '({})'.format(','.join(['%s'] * len(sql_fields)))
sql_stmt = """INSERT INTO {} {} VALUES {}""".format(sql_table_str, sql_fields_str, sql_values_str)
sql_data = [2000,0,0,0]
print sql_stmt, sql_data

# 5. 执行SQL语句：返回受影响的条数，如果插入失败则回滚事务
try:
    print cursor.execute(sql_stmt, sql_data)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e

# 6. 关闭连接
conn.close()
```

    <_mysql.connection open to '127.0.0.1' at 7f87bf2df620>
    <MySQLdb.cursors.DictCursor object at 0x10c13af90>
    INSERT INTO g_team_combine_activity_city_map (id,activity_id,city_id,create_time) VALUES (%s,%s,%s,%s) [2000, 0, 0, 0]
    (1062, "Duplicate entry '2000' for key 'PRIMARY'")


## 连接DB


```python
# 端口是int，其他都是字符串
# MySQLdb.connect(host=主机, port=端口, user=用户名, passwd=密码, db=数据库, charset='utf8')
conf = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'db': 'didi',
    'charset': 'utf8'
}

conn = MySQLdb.connect(**conf)
```

##  获取游标


```python
# 传入游标类型：决定了返回记录的类型，字典最常用
cursor = conn.cursor(MySQLdb.cursors.DictCursor)
```

##  执行SQL

原型：`cursor.execute(query, args=None)` 

`query`查询语句和`args`数据参数需配合使用，总体上有三种使用方式：

1. 完整查询语句+数据参数None：`query`是一句完整可执行的SQL语句字符串 + `args`为None；
2. 占位符查询语句+数据参数序列：`query`中含有占位符`%s`，`args` 为一个序列，执行时会先使用`args`中的值依次替换`query`中的占位符；
3. 关键字占位符查询语句+数据参数字典：`query`中含有关键字占位符`%(key)s` ，`args` 为一个字典，执行时会先使用`args`按关键字替换`query`中的占位符；

后两种方式是将参数作为最终要插入的值，然后代入到查询语句的，而不是先代入再用SQL语句计算其值。

### 查询

#### 执行查询语句


```python
# 方式一
sql1 = 'select * from {0} where {1} < {2}'.format(
    'g_team_combine_activity_city_map', 'id', 80)

# 返回受影响的记录行数
cursor.execute(sql1)
```




    6L



####  获取查询结果

每次获取查询结果，游标会自动后移。


```python
# 逐条获取记录：返回一个字典，每次获取，游标下移，无数据返回None
data1 = cursor.fetchone()
print data1
```

    {'city_id': 1L, 'activity_id': 1L, 'create_time': 1556865052L, 'id': 1L}



```python
# 获取指定数目的记录：返回一个字典元组，每次读取，游标都会移动
data2 = cursor.fetchmany(2)
print data2
```

    ({'city_id': 3L, 'activity_id': 2L, 'create_time': 1556868188L, 'id': 2L}, {'city_id': 1L, 'activity_id': 45L, 'create_time': 1505969474L, 'id': 5L})



```python
# 返回全部结果，字典元组
data3 = cursor.fetchall()
data3
```




    ({'activity_id': 71L, 'city_id': 35L, 'create_time': 1506402761L, 'id': 79L},)



### 插入

#### 单条插入
'INSERT INTO table_name (字段1，字段2,...,字段n)' VALUES (值1，值2，...，值n)


```python
# 方式一：构造出完整SQL语句，注意这里的unix_timestamp(now())会被SQL执行
sql4 = """INSERT INTO g_team_combine_activity_city_map(
                            id, activity_id, city_id, create_time)
                            VALUES(11, 1, 1, unix_timestamp(now()))"""

# 方式二：占位符查询语句+数据参数序列，注意这里传递给%s的是最终的结果，因为如果传入SQL函数则不会在SQL中执行
sql_stmt1 = """INSERT INTO g_team_combine_activity_city_map(
                            id,activity_id,city_id,create_time)
                            VALUES(%s, %s, %s, %s)"""

sql_data1 = [2, 2, 3, time.time()]

# 方式三：关键字占位符查询语句+数据参数字典
sql_stmt2 = """INSERT INTO g_team_combine_activity_city_map(
                            id,activity_id,city_id,create_time)
                            VALUES(%(id)s, %(activity_id)s, %(city_id)s, %(create_time)s)"""

sql_data2 = {
    'id': 3,
    'activity_id': 5,
    'city_id': 7,
    'create_time': time.time()
}
```


```python
# 执行SQL语句，提交事务，如果提交失败则回滚
try:
    cursor.execute(sql_stmt2, sql_data2)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```

#### 批量插入


```python
# 普通方式
sql_stmt4 = """INSERT INTO g_team_combine_activity_city_map
                                (id,activity_id,city_id,create_time)
                                VALUES
                                {}""".format(','.join(['(%s)' % ','.join(['%s'] * 4)] * 3))

sql_data4 = [(1210,0,0,0),
             (1211,0,0,0),
             (1212,0,0,0)]

sql_data4 = [tt for t in sql_data4 for tt in t]

try:
    cursor.execute(sql_stmt4, sql_data4)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```


```python
# executemany，用于多行插入，效率比逐行插入更高
sql_stmt3 = """INSERT INTO g_team_combine_activity_city_map
                                (id,activity_id,city_id,create_time)
                                VALUES
                                (%s, %s, %s, %s)"""

sql_data3 = [(1205,0,0,0),
             (1206,0,0,0),
             (1207,0,0,0)]

try:
    cursor.executemany(sql_stmt3, sql_data3)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```

### 更新操作


```python
sql_table_str = 'g_team_combine_activity_city_map'
sql_key_dict = {'city_id':999, 'create_time': time.time()}
sql_eval_str = ','.join('{} = {}'.format(item[0],item[1]) for item in key_dict.items())
sql_cond_str = '{}>{}'.format('id', 1100)

sql_stmt4 = """UPDATE {0} SET {1} WHERE {2}""".format(table_str, eval_str, cond_str)

try:
    cursor.execute(sql_stmt4)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```

###  删除操作


```python
sql_table_str = 'g_team_combine_activity_city_map'
sql_cond_str = 'id > 1200' 
sql_stmt5 = """DELETE FROM {} WHERE {}""".format(sql_table_str, sql_cond_str)

try:
    cursor.execute(sql_stmt5)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```

###  创建数据库表


```python
sql_stmt6 = """
CREATE TABLE `t_data_status` (
  `f_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `f_app_id` varchar(32) NOT NULL COMMENT '合作方id',
  `f_busi_id` varchar(32) NOT NULL DEFAULT 0 COMMENT '内部业务id',
  `f_src_data_set` varchar(60) NOT NULL DEFAULT '' COMMENT '数据源,即分表名称, 包括基础表和业务基础数据表',
  `f_des_data_set` varchar(60) NOT NULL DEFAULT '' COMMENT '数据目标,即各个副本表名称, 包括基础表和业务基础数据表',
  `f_dataset_type_id` int(2) NOT NULL COMMENT '数据源类型dic_dataset_type f_id，字典:医院基础数据，科室基础数据, 医院挂号业务数据等, 通过dic_dataset_type的type知道这条数据是不是基础数据',
  `f_type` int(1) NOT NULL COMMENT '数据类型，0基础数据, 1业务数据, 冗余字段，便于检索',
  `f_data_num` int(11) NOT NULL DEFAULT '0' COMMENT '数据总量',
  `f_relation_id` varchar(32) NOT NULL DEFAULT '' COMMENT '业务生成的unique id，标识基础表和星形表的关联, 例如医院基础数据和医院挂号业务数据两个数据源就需要共用同一个唯一id',
  `f_status` tinyint NOT NULL COMMENT '状态 1 成功 0 失败',
  `f_create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '数据方创建时间',
  `f_version` int(10) NOT NULL DEFAULT 1 COMMENT '数据在当天的版本',
  `f_deal_status` tinyint NOT NULL DEFAULT '-1' COMMENT '状态 -1 未处理 1 成功 0 失败 状态位2表示处理中..',
  `f_deal_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '处理数据时的时间',
  PRIMARY KEY (`f_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;
"""

try:
    cursor.execute(sql_stmt6)
    conn.commit()
except Exception as e:
    conn.rollback()
    print e
```

    (1050, "Table 't_data_status' already exists")

