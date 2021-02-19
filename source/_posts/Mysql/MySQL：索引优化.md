---
title: MySQL：索引优化
date: 2020-07-03 17:01:09
tags:
    - MySQL
categories:
    - MySQL
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200703102511.png)

## What
索引是存储引擎用于快速查找记录的一种数据结构。索引优化是优化查询性能最有效的手段，好的索引能够轻易将查询性能提高几个数量级。但索引并不总是最好的工具，只有当索引帮助存储引擎快速查找记录带来的好处大于其带来的额外工作时，索引才是有效的，一般来讲：

1. 对于小表：全表扫描更高效；
2. 对于中表：索引非常有效；
3. 对于大表：建议采用分区；

Lahdenmaki 和 Leach 在 Relational Database Index Design and the Optimizers 一书中介绍了如何评价一个索引是否适合某个查询的“三星系统”：

1. 聚集：索引将相关的记录放到一起则获得“一星”；
2. 有序：索引中的数据顺序和查找中的排列顺序一致则获得“二星”；
3. 覆盖：索引中的列包含了查询中需要的全部列则获得“三星”；

### 索引类型
索引是在存储引擎层而不是服务器层实现的，所以没有统一的索引标准：不同存储引擎所支持的索引类型不同，即使同一种类型的索引，其底层实现也可能不同。MySQL 中涉及的索引类型有：

1. B-Tree 索引：当人们谈论索引的时候，如果没有特别指明索引类型，一般指的是 B-Tree 索引。大多数 Mysql 引擎都支持这种索引（Archive 例外），NDB 集群存储引擎实际上使用的是 T-Tree，但其名字是 BTREE，InnoDB 使用的是 B+Tree。不同存储引擎以不停方式使用 B-Tree，性能也有所不同，MyISAM 使用前缀压缩技术使得索引更小，InnoDB 则按照原始数据格式进行存储，MyISAM 通过数据的物理位置引用被索引的行，InnoDB 则根据主键引用被索引的行。
2. 哈希索引：存储引擎会对每一行数据的所有索引列计算一个哈希值，哈希索引将所有的哈希值存储在索引中，并保存指向每个数据行的指针；哈希索引的访问速度非常快，但哈希索引只包含哈希值和行指针，无法避免读取行，也无法用于排序，此外哈希索引只支持等值和比较查询，不支持部分索引列匹配。
3. 空间数据索引：MyISAM 表支持空间索引，可以用作地理数据存储。和 B-Tree 索引不同，这类索引无须前缀查询。空间索引会从所有维度来索引数据。查询时，可以有效地使用任意维度来组合查询。必须使用 MySQL 的 GIS 相关函数如 MBRCONTAINS() 等来维护数据。MySQL 的 GIS 支持并不完善，所以大部分人都不会使用这个特性。
4. 全文索引：全文索引是一种特殊类型的索引，它查找的是文本中的关键词，而不是直接比较索引中的值。全文搜索和其他几类索引的匹配方式完全不一样。它有许多需要注意的细节，如停用词、词干和复数、布尔搜索等。全文索引更类似于搜索引擎做的事情，而不是简单的WHERE条件匹配。

本文接下来要讨论的是 InnoDB 所采用的 B+Tree 索引，这也是最常用的索引类型和实现方式。

### B+Tree
M 阶 [B+Tree](https://mp.weixin.qq.com/s/jRZMMONW3QP43dsDKIV9VQ)，满足以下特征：

1. **根节点**至少有两个子树，最多有 M 个**子树**，节点内**关键字**个数与子树个数相同，每个关键字作为子树的索引，等于对应子树中最大/小关键字；
2. **中间节点**至少有 M/2 个子树，最多有 M 个子树，节点内关键字个数与子树个数相同，每个关键字作为子树的索引，等于对应子树中最大/小关键字；
3. **叶子节点**包含了全部关键字，及指向对应记录的指针，叶子节点按关键字**排序**组成双向链表；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200630115000.png)

B+Tree 可以进行两种查找运算：

1. 从最小关键字开始，在叶子节点中顺序查找；
2. 从根节点开始，向下进行二分查找；

相比 B-Tree，B+Tree 的优势：

1. 每次可以读取更多的索引，减少 IO 操作；
2. 查询性能稳定，只有达到子节点才能命中；
3. 范围查询简便，对于范围查询，先从根节点出发找到最小索引，再在叶子节点中顺序查找至最大索引；

### 聚簇索引和二级索引
InnoDB 存储引擎同时维护了两种索引存储方式，两种方式均通过 B+Tree 实现：

- 聚簇索引(Clustered Index)：也叫主键索引，以主键作为节点页，数据行作为叶子页；聚簇索引不能人为指定，只能自动生成；如果没有定义主键，InnodDB 会选择一个唯一的非空索引代替，如果没有这样的索引，InnoDB 会隐式定义一个主键来作为聚簇索引；一个表只能有一个聚簇索引，在聚簇索引树中，可以通过主键快读查询到对应的数据行。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200701192719.png)

- 二级索引(Secondary index)：也叫非聚簇索引，以索引作为节点页，主键作为叶子页；一个表可以有多个二级索引，使用二级索引查找数据时，如果查询列包含了二级索引没有覆盖的列，则需要先在二级索引树中查询到对应的主键，再在聚簇索引树中查询主键对应的数据行，称为”回表查询“，性能较扫一遍索引树差。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200701192758.png)

对于索引列值为 NULL 的二级索引记录来说，它们会被放在 B+ 树的最左边：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200702140345.png)

## How
### 定义索引
#### 创建索引
MySQL创建索引的语法如下：

```sql
CREATE [UNIQUE|FULLTEXT|SPATIAL] INDEX index_name
[USING index_type]
ON table_name (index_col_name,...)
```

其中：

1. [UNIQUE|FULLTEXT|SPATIAL]：分别代表唯一索引、全文索引、空间索引，如果不指定任何关键字，默认为普通索引；
2. index_name：索引名称，用户自行定义；
3. index_type：索引类型，存储引擎为 MyISAM 和 InnoDB 的表中只能使用 BTREE；存储引擎为 MEMORY 或者 HEAP 的表中可以使用 HASH 和 BTREE 两种类型的索引，默认值为 HASH；
4. index_col_name：要创建索引的字段名称，可以针对多个字段创建联合索引，只需要在多个字段名称之间以英文逗号隔开即可；对于 CHAR 或 VARCHAR 类型的字段，我们还可以只使用字段内容前面的一部分来创建索引，只需要在对应的字段名称后面加上形如(length)的指令即可，表示只需要使用字段内容前面的length个字符来创建索引；

创建索引的语法有以下变体：

```sql
ALTER TABLE table_name
ADD [UNIQUE|FULLTEXT|SPATIAL] INDEX index_name (index_col_name,...) [USING index_type]
```

示例：

```sql
mysql> show create table index_test;
CREATE TABLE `index_test` (
  `f_id` mediumint(9) NOT NULL AUTO_INCREMENT,
  `f_date` varchar(8) DEFAULT NULL COMMENT '日期',
  `f_minute` varchar(12) NOT NULL DEFAULT '0' COMMENT '分钟',
  `f_bizname` varchar(32) NOT NULL DEFAULT '' COMMENT '业务大类',
  `f_pv` int(11) NOT NULL DEFAULT '0' COMMENT 'pv',
  `f_uv` int(11) NOT NULL DEFAULT '0' COMMENT 'uv',
  PRIMARY KEY (`f_id`)
) ENGINE=InnoDB AUTO_INCREMENT=196606 DEFAULT CHARSET=utf8 COMMENT='大类实时数据迁移至tube' 

-- 创建部分索引
mysql> alter table index_test add index idx_biz (f_bizname(6));
-- 创建联合索引
mysql> alter table index_test add index idx_mix (f_date, f_minute, f_bizname);

mysql> show create table index_test;
CREATE TABLE `index_test` (
  `f_id` mediumint(9) NOT NULL AUTO_INCREMENT,
  `f_date` varchar(8) DEFAULT NULL COMMENT '日期',
  `f_minute` varchar(12) NOT NULL DEFAULT '0' COMMENT '分钟',
  `f_bizname` varchar(32) NOT NULL DEFAULT '' COMMENT '业务大类',
  `f_pv` int(11) NOT NULL DEFAULT '0' COMMENT 'pv',
  `f_uv` int(11) NOT NULL DEFAULT '0' COMMENT 'uv',
  PRIMARY KEY (`f_id`),
  KEY `idx_biz` (`f_bizname`(6)),
  KEY `idx_mix` (`f_date`,`f_minute`,`f_bizname`)
) ENGINE=InnoDB AUTO_INCREMENT=196606 DEFAULT CHARSET=utf8 COMMENT='大类实时数据迁移至tube' 
```

#### 删除索引

在MySQL中删除索引的方法非常简单，其完整语法如下：

```sql
--删除指定表中指定名称的索引
ALTER TABLE table_name 
DROP INDEX index_name;
```

#### 修改索引
在MySQL中并没有提供修改索引的直接指令，一般情况下，我们需要先删除掉原索引，再根据需要创建一个同名的索引，从而变相地实现修改索引操作。

```sql
--先删除
ALTER TABLE user
DROP INDEX idx_user_username;
--再以修改后的内容创建同名索引
CREATE INDEX idx_user_username ON user (username(8));
```

#### 查看索引
在MySQL中，要查看某个数据库表中的索引也非常简单：

```sql
-- 语法
SHOW INDEX FROM table_name

-- 示例
mysql> show index from index_test;
+------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table      | Non_unique | Key_name | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| index_test |          0 | PRIMARY  |            1 | f_id        | A         |      146475 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_biz  |            1 | f_bizname   | A         |         130 |        6 | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_mix  |            1 | f_date      | A         |           4 |     NULL | NULL   | YES  | BTREE      |         |               |
| index_test |          1 | idx_mix  |            2 | f_minute    | A         |        7709 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_mix  |            3 | f_bizname   | A         |      146475 |     NULL | NULL   |      | BTREE      |         |               |
+------------+------------+----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
```

其中：

1. Collation：列以什么方式存储在索引中。在MySQL中，有值‘A’（升序）或 NULL（无分类）；
2. **Cardinality**：索引基数，表示索引中不同值个数的**预估值**，值越大，索引的“区分度“（或者说”选择性“）越好；
3. Sub_part：列如果被部分编入索引，则为编入索引的字符数，否则为 NULL；
4. Packed：指示关键字如何被压缩，如果没有被压缩，则为NULL；
5. Null：如果列含有NULL，则含有YES，如果没有，则该列含有NO；
6. Index_type：索引类型；

### 使用索引
下面的内容可能会因为 MySQL 版本的不同而有所差异，另外，查询优化器对索引的选择依赖于对索引统计信息的估计，这种估计可能是不准确的、随数据量变化的，前后两次执行同一个查询可能会出现使用不同索引的情况。

#### 能否命中索引
只有在表达式中正确使用了索引列，才能命中索引（possible_keys）：

1. 索引列单独出现：索引列既不能是表达式的一部分，也不能是函数的参数；特别地，如果索引列发生了隐式类型转换，可能会使得索引不可用；
2. 精确匹配最左前缀 + 范围匹配后一列：对于联合索引，索引前几列采用精确匹配，后一列采用范围匹配，而范围匹配索引列后面（按索引定义中的顺序）的索引都将失效，有以下几种特殊形态
    1. 精确匹配最左前缀：使用的索引列构成了联合索引的某种前缀，索引列的使用顺序无关紧要，因为查询优化器会将其优化为何索引定义的顺序；
    2. 全值匹配：精确匹配所有索引列，精确匹配指的是 `=`；
    3. 范围匹配：使用 >、<、>=、<=，!= 、<>，between，或 LIKE 不以通配符(%)开头的索引列与常量值比较作为范围条件，如果在联合索引中使用了范围索引，那么在范围索引后面的索引会失效（在10.1.9-MariaDB实测，范围条件后面的索引也会生效，可能是版本带来的差异）；

**最左前缀原则**：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20200702141105.png)

示例：

```sql
-- 索引结构
mysql> show create table index_test;
CREATE TABLE `index_test` (
  `f_id` mediumint(9) NOT NULL AUTO_INCREMENT,
  `f_date` int(11) NOT NULL DEFAULT '0' COMMENT '日期',
  `f_minute` varchar(12) NOT NULL DEFAULT '0' COMMENT '分钟',
  `f_bizname` varchar(32) NOT NULL DEFAULT '' COMMENT '业务大类',
  `f_pv` int(11) NOT NULL DEFAULT '0' COMMENT 'pv',
  `f_uv` int(11) NOT NULL DEFAULT '0' COMMENT 'uv',
  `f_const` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`f_id`),
  KEY `idx_mix` (`f_date`,`f_minute`,`f_bizname`),
  KEY `idx_const` (`f_const`)
) ENGINE=InnoDB AUTO_INCREMENT=2032124 DEFAULT CHARSET=utf8 COMMENT='大类实时数据迁移至tube'
-- 索引明细
mysql> show index from index_test;
+------------+------------+-----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table      | Non_unique | Key_name  | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+------------+------------+-----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| index_test |          0 | PRIMARY   |            1 | f_id        | A         |     1191444 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_mix   |            1 | f_date      | A         |          44 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_mix   |            2 | f_minute    | A         |       70084 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_mix   |            3 | f_bizname   | A         |     1191444 |     NULL | NULL   |      | BTREE      |         |               |
| index_test |          1 | idx_const |            1 | f_const     | A         |           2 |     NULL | NULL   |      | BTREE      |         |               |
+------------+------------+-----------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+

-- 不带 WHERE 条件，且查询了非索引字段，全表扫描
MariaDB [db_data_anlysis]> explain
    -> select *
    -> from index_test;
+------+-------------+------------+------+---------------+------+---------+------+---------+-------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------+
|    1 | SIMPLE      | index_test | ALL  | NULL          | NULL | NULL    | NULL | 1191444 |       |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------+

-- 不带 WHERE 条件，count(*) 直接在二级索引树种就可以计算出来
MariaDB [db_data_anlysis]> explain
    -> select count(*)
    -> from index_test;
+------+-------------+------------+-------+---------------+-----------+---------+------+---------+-------------+
| id   | select_type | table      | type  | possible_keys | key       | key_len | ref  | rows    | Extra       |
+------+-------------+------------+-------+---------------+-----------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | index | NULL          | idx_const | 4       | NULL | 1191444 | Using index |
+------+-------------+------------+-------+---------------+-----------+---------+------+---------+-------------+

-- 按主键/索引排序，索引扫描
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> order by f_id;
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows    | Extra |
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------+
|    1 | SIMPLE      | index_test | index | NULL          | PRIMARY | 3       | NULL | 1191444 |       |
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------+

-- 索引列不能作为表达式的一部分
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where f_date - 1= 20200622;
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | ALL  | NULL          | NULL | NULL    | NULL | 1191444 | Using where |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+

-- 索引列不能作为函数的参数
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where cast(f_date as unsigned) = 20200622;
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | ALL  | NULL          | NULL | NULL    | NULL | 1191444 | Using where |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+

-- 索引查找，只使用了联合索引idx_mix中第一个字段
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where f_date = '';
+------+-------------+------------+------+---------------+---------+---------+-------+------+-------+
| id   | select_type | table      | type | possible_keys | key     | key_len | ref   | rows | Extra |
+------+-------------+------------+------+---------------+---------+---------+-------+------+-------+
|    1 | SIMPLE      | index_test | ref  | idx_mix       | idx_mix | 4       | const |    1 |       |
+------+-------------+------------+------+---------------+---------+---------+-------+------+-------+

-- 索引查找，只使用了联合索引idx_mix中前两个字段，索引使用顺序不影响
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where f_minute='202006220001' and f_date = '20200622';
+------+-------------+------------+------+---------------+---------+---------+-------------+------+-----------------------+
| id   | select_type | table      | type | possible_keys | key     | key_len | ref         | rows | Extra                 |
+------+-------------+------------+------+---------------+---------+---------+-------------+------+-----------------------+
|    1 | SIMPLE      | index_test | ref  | idx_mix       | idx_mix | 42      | const,const |   39 | Using index condition |
+------+-------------+------------+------+---------------+---------+---------+-------------+------+-----------------------+

-- 全值匹配
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where f_minute='202006220001' and f_date = '20200622' and f_bizname='首页';
+------+-------------+------------+------+---------------+---------+---------+-------------------+------+-----------------------+
| id   | select_type | table      | type | possible_keys | key     | key_len | ref               | rows | Extra                 |
+------+-------------+------------+------+---------------+---------+---------+-------------------+------+-----------------------+
|    1 | SIMPLE      | index_test | ref  | idx_mix       | idx_mix | 140     | const,const,const |    1 | Using index condition |
+------+-------------+------------+------+---------------+---------+---------+-------------------+------+-----------------------+

-- 最左前缀 + 范围查询，范围后的索引列仍会有效（在我测试的10.1.9-MariaDB版本是这样）
MariaDB [db_data_anlysis]> explain 
    -> select *  
    -> from index_test 
    -> where f_minute='202006220001' and f_bizname='首页' and f_date between 20200622 and 20200623;
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows   | Extra                 |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
|    1 | SIMPLE      | index_test | range | idx_mix       | idx_mix | 140     | NULL | 101998 | Using index condition |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
    
```

#### 是否使用索引
##### 查询优化器
即使正确定义并命中了索引，最终的执行计划是否会使用索引仍要取决于查询优化器的判断，优化器会对比所有可能的方案，找出成本最低的方案作为最终的执行计划，大致过程如下：

1. 根据查找条件找出所有可能使用的索引，计算使用不同索引执行查询的代价；
2. 计算全表扫描的代价；
3. 选择代价最低的方案作为执行计划；

Mysql 的代价模型比较复杂，感兴趣的话可以参考 [MySQL 5.7 代价模型浅析](http://mysql.taobao.org/monthly/2016/07/02/)，这里不对细节进行深究。

##### 范围索引
范围访问方法使用单个索引来检索包含在一个或多个索引值区间内的表行的子集，这里的单个索引可以是单列索引或联合索引。

1. 对于单列索引，可以通过 WHERE 子句中的条件表达式来表示范围条件，当使用 >、<、>=、<=，between，!= 、<> 或 LIKE 不以通配符(%)开头的索引列与常量值比较时，是个范围条件，多个范围条件使用 OR 或 AND 组合而成。
2. 对于联合索引，区间可能适用于 AND 的条件组合，其中每个条件使用 =、<=>、IS NULL、>、>=、<、<=、!= 、<>、BETWEEN 或 LIEK 模糊匹配(不能通配符开头) 来比较索引和常量值。

对于范围索引，查询优化器会通过“索引统计信息”来估计每个范围的行数，如果行数占表总行比例较大，且不会触发覆盖索引，查询优化器会放弃使用范围索引，直接使用全表扫描：

```sql
-- 只是修改了数据范围，就改变了索引选择；实验表明，如果减少表中整体的数据量，以下两个都不会走索引
MariaDB [db_data_anlysis]> explain
    -> select *
    -> from index_test 
    -> where f_date between 20200620 and 20200621
    -> ;
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows   | Extra                 |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
|    1 | SIMPLE      | index_test | range | idx_mix       | idx_mix | 4       | NULL | 115016 | Using index condition |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+-----------------------+
1 row in set (0.03 sec)

MariaDB [db_data_anlysis]> explain
    -> select *
    -> from index_test 
    -> where f_date between 20200618 and 20200619;
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | ALL  | idx_mix       | NULL | NULL    | NULL | 1191444 | Using where |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
```

##### 覆盖索引
如果一个索引包含（覆盖）所有需要查询的字段（主键以外的字段），我们就称之为“覆盖索引”。覆盖索引可以直接在二级索引树种查询到所有字段，无需进行回表查询，可以**极大**提高查询性能。

```sql
-- (f_minute, f_bizname) 是主键，(f_date, f_minute, f_bizname) 是一个联合索引
explain 
select f_date, f_minute, f_bizname
from index_test 
where f_date='20200622' and f_minute like '2020062200%'


-- Extra 列中的 Using index 表示使用的是覆盖索引
+------+-------------+------------+-------+---------------+---------+---------+------+------+--------------------------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows | Extra                    |
+------+-------------+------------+-------+---------------+---------+---------+------+------+--------------------------+
|    1 | SIMPLE      | index_test | range | idx_mix       | idx_mix | 42      | NULL | 2160 | Using where; Using index |
+------+-------------+------------+-------+---------------+---------+---------+------+------+--------------------------+
```

但如果索引不能覆盖查询所需的全部列，那就不得不每扫描一条索引记录就回表查询一次对应的行。
这基本上都是随机I/O，因此按索引顺序读取数据的速度通常要比顺序地全表扫描慢，尤其是在I/O密集型的工作负载时。

```sql
MariaDB [db_data_anlysis]> pager cat > /dev/null;
MariaDB [db_data_anlysis]> select f_date, f_minute, f_bizname
    -> from index_test
    -> order by 1,2,3;
1195949 rows in set (1.63 sec)

MariaDB [db_data_anlysis]> select f_date, f_minute, f_bizname, f_uv
    -> from index_test
    -> order by 1,2,3;
1195949 rows in set (4.00 sec)

-- 排序没有走索引，而是进行了全表扫描
MariaDB [db_data_anlysis]> explain
    -> select f_date, f_minute, f_bizname, f_uv
    -> from index_test
    -> order by 1,2,3;
+------+-------------+------------+------+---------------+------+---------+------+---------+----------------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra          |
+------+-------------+------------+------+---------------+------+---------+------+---------+----------------+
|    1 | SIMPLE      | index_test | ALL  | NULL          | NULL | NULL    | NULL | 1191444 | Using filesort |
+------+-------------+------------+------+---------------+------+---------+------+---------+----------------+
1 row in set (0.02 sec)

MariaDB [db_data_anlysis]> explain
    -> select f_date, f_minute, f_bizname
    -> from index_test
    -> order by 1,2,3;
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows    | Extra       |
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | index | NULL          | idx_mix | 140     | NULL | 1191444 | Using index |
+------+-------------+------------+-------+---------------+---------+---------+------+---------+-------------+
```

##### 延迟关联
如果查询字段中包含了该索引（以及主键）以外的字段，便无法使用覆盖索引，此时可以通过一种“延迟关联”的技术先在子查询中通过覆盖索引查询对应主键集合，再通过主键关联其余字段。这样就不用每次都进行回表查询，减少了磁盘 I/O 读取次数。

```sql
-- f_uv 不在索引内，无法使用覆盖索引
MariaDB [db_data_anlysis]> explain 
    -> select f_date, f_minute, f_bizname, f_uv
    -> from index_test 
    -> where f_date between '20200620' and '20200622'
    -> ;
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
| id   | select_type | table      | type | possible_keys | key  | key_len | ref  | rows    | Extra       |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
|    1 | SIMPLE      | index_test | ALL  | idx_mix       | NULL | NULL    | NULL | 1191444 | Using where |
+------+-------------+------------+------+---------------+------+---------+------+---------+-------------+
1 row in set (0.03 sec)

-- f_date, f_minute, f_bizname 在索引内，可以使用覆盖索引
MariaDB [db_data_anlysis]> explain
    -> select f_date, f_minute, f_bizname
    -> from index_test 
    -> where f_date between '20200620' and '20200622'
    -> ;
+------+-------------+------------+-------+---------------+---------+---------+------+--------+--------------------------+
| id   | select_type | table      | type  | possible_keys | key     | key_len | ref  | rows   | Extra                    |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+--------------------------+
|    1 | SIMPLE      | index_test | range | idx_mix       | idx_mix | 4       | NULL | 217974 | Using where; Using index |
+------+-------------+------------+-------+---------------+---------+---------+------+--------+--------------------------+
1 row in set (0.03 sec)

-- 延迟关联，子查询使用覆盖索引，a 使用索引查找
MariaDB [db_data_anlysis]> explain
    -> select
    -> a.*
    -> from 
    -> index_test a
    -> join
    -> (select f_date, f_minute, f_bizname
    -> from index_test 
    -> where f_date between '20200620' and '20200622'
    -> ) b 
    -> on a.f_bizname = b.f_bizname and a.f_minute = b.f_minute
    -> ;
+------+-------------+------------+-------+-----------------+---------+---------+--------------------------------------+--------+--------------------------+
| id   | select_type | table      | type  | possible_keys   | key     | key_len | ref                                  | rows   | Extra                    |
+------+-------------+------------+-------+-----------------+---------+---------+--------------------------------------+--------+--------------------------+
|    1 | SIMPLE      | index_test | range | idx_biz,idx_mix | idx_mix | 4       | NULL                                 | 217974 | Using where; Using index |
|    1 | SIMPLE      | a          | ref   | idx_biz         | idx_biz | 20      | db_data_anlysis.index_test.f_bizname |  10451 | Using where              |
+------+-------------+------------+-------+-----------------+---------+---------+--------------------------------------+--------+--------------------------+
2 rows in set (0.03 sec)

```


##### 索引提示
MySQL 支持通过“索引提示”显式地告诉优化器使用哪个索引，这在以下两种情况下可能会用到：

1. 查询优化器错误地选择了某个索引：这种情况在最新的 MySQL 版本中已经非常少见了；
2. 查询可选索引非常多，导致选择执行计划的事件开销很大：这是可以通过索引提示强行指定索引来完成查询；

常用的 Index Hint 语法如下：如果是对主键的 Hint，可以用 `PRI` 指代主键

```sql
-- USE INDEX 只是告诉优化器可以选择该索引，但实际上优化器还是会再根据自己的判断进行选择
SELECT *
FROM t
USE INDEX(index_a)
WHERE a=1 and b=2

-- FORCE INDEX 可以强制优化器使用该索引
SELECT *
FROM t
FORCE INDEX(index_a)
WHERE a=1 and b=2

-- IGNORE INDEX 可以强制优化器不使用某个索引
SELECT *
FROM t
IGNORE INDEX(index_a)
WHERE a=1 and b=2
```

### 辅助信息
#### 查看查询耗时
在执行完查询语句之后可以通过 `show profiles` 查看查询时间：

```sql
-- 查看profiling 是否是on状态
mysql> show variables like '%profiling%';

-- 如果是off，则 
mysql> set profiling = 1;

-- 执行自己的sql语句
mysql> select f_date, f_minute, f_biznamefrom index_test where f_minute = 202006200001 and f_bizname = '首页'+----------+--------------+-----------+
| f_date   | f_minute     | f_bizname |
+----------+--------------+-----------+
| 20200620 | 202006200001 | 首页      |
+----------+--------------+-----------+
1 row in set (0.20 sec)

-- show profiles 查看语句执行时间
mysql> show profiles;
+----------+------------+------------------------------------------------------------------------------------------------------------+
| Query_ID | Duration   | Query                                                                                                      |
+----------+------------+------------------------------------------------------------------------------------------------------------+
|        1 | 0.16595042 | select f_date, f_minute, f_bizname
from index_test 
where f_minute = 202006200001 and f_bizname = '首页'   |
+----------+------------+------------------------------------------------------------------------------------------------------------+
```

#### 查看索引统计信息
MySQL 执行 SQL 会经过 SQL 解析和查询优化的过程，解析器将 SQL 分解成数据结构并传递到后续步骤，查询优化器发现执行 SQL 查询的最佳方案、生成执行计划。查询优化器决定 SQL 如何执行，依赖于数据库的统计信息，下面我们介绍MySQL 5.7中innodb统计信息的相关内容。

MySQL统计信息的存储分为两种，非持久化和持久化统计信息。
##### 非持久化统计信息
非持久化统计信息存储在内存里，如果数据库重启，统计信息将丢失，有两种方式可以设置为非持久化统计信息：

1. 全局变量，INNODB_ STATS_PERSISTENT=OFF
2. CREATE/ALTER 表的参数，STATS_PERSISTENT=0

非持久化统计信息在以下情况会被自动更新：

1. 执行 `ANALYZE TABLE` 语句
2. innodb_stats_on_metadata=ON 情况下，执 SHOW TABLE STATUS, SHOW INDEX, 查询  INFORMATION_SCHEMA下的TABLES, STATISTICS
3. 启用 --auto-rehash 功能情况下，使用 mysql client 登录
4. 表第一次被打开
5. 距上一次更新统计信息，表 1/16 的数据被修改

非持久化统计信息的缺点显而易见，数据库重启后如果大量表开始更新统计信息，会对实例造成很大影响，所以目前都会使用持久化统计信息。
##### 持久化统计信息
5.6.6开始，MySQL默认使用了持久化统计信息，即 INNODB_STATS_PERSISTENT=ON ，持久化统计信息保存在表 mysql.innodb_table_stats 和 mysql.innodb_index_stats 。

持久化统计信息在以下情况会被自动更新：

1. INNODB_ STATS _AUTO_RECALC=ON 情况下，表中 10% 的数据被修改
2. 增加新的索引  

innodb_table_stats 是表的统计信息：

| 字段                           | 含义           |
|------------------------------|--------------|
| database\_name               | 数据库名         |
| table\_name                  | 表名           |
| last\_update                 | 统计信息最后一次更新时间 |
| n\_rows                      | 表的行数         |
| clustered\_index\_size       | 聚集索引的页的数量    |
| sum\_of\_other\_index\_sizes | 其他索引的页的数量    |

innodb_index_stats 是索引的统计信息：

| 字段                | 含义           |
|-------------------|--------------|
| database\_name    | 数据库名         |
| table\_name       | 表名           |
| index\_name       | 索引名          |
| last\_update      | 统计信息最后一次更新时间 |
| stat\_name        | 统计信息名        |
| stat\_value       | 统计信息的值       |
| sample\_size      | 采样大小         |
| stat\_description | 类型说明         |

示例：

```sql
CREATE TABLE t1 ( 
	a INT, b INT, c INT, d INT, e INT, f INT,
	PRIMARY KEY (a, b), 
	KEY i1 (c, d), 
	UNIQUE KEY i2uniq (e, f)
) ENGINE=INNODB;

mysql> select * from t1;
+---+---+------+------+------+------+
| a | b | c    | d    | e    | f    |
+---+---+------+------+------+------+
| 1 | 1 |   10 |   11 |  100 |  101 |
| 1 | 2 |   10 |   11 |  200 |  102 |
| 1 | 3 |   10 |   12 |  100 |  103 |
| 1 | 4 |   10 |   12 |  200 |  104 |
+---+---+------+------+------+------+

mysql> select last_update, n_rows, clustered_index_size, sum_of_other_index_sizes
from mysql.innodb_table_stats 
where table_name='t1'
+---------------------+--------+----------------------+--------------------------+
| last_update         | n_rows | clustered_index_size | sum_of_other_index_sizes |
+---------------------+--------+----------------------+--------------------------+
| 2020-07-02 15:42:11 |      4 |                    1 |                        2 |
+---------------------+--------+----------------------+--------------------------+

mysql> select index_name, stat_name, stat_value, stat_description
from mysql.innodb_index_stats 
where table_name='t1'

+------------+--------------+------------+-----------------------------------+
| index_name | stat_name    | stat_value | stat_description                  |
+------------+--------------+------------+-----------------------------------+
| PRIMARY    | n_diff_pfx01 |          1 | a                                 |
| PRIMARY    | n_diff_pfx02 |          4 | a,b                               |
| PRIMARY    | n_leaf_pages |          1 | Number of leaf pages in the index |
| PRIMARY    | size         |          1 | Number of pages in the index      |
| i1         | n_diff_pfx01 |          1 | c                                 |
| i1         | n_diff_pfx02 |          2 | c,d                               |
| i1         | n_diff_pfx03 |          2 | c,d,a                             |
| i1         | n_diff_pfx04 |          4 | c,d,a,b                           |
| i1         | n_leaf_pages |          1 | Number of leaf pages in the index |
| i1         | size         |          1 | Number of pages in the index      |
| i2uniq     | n_diff_pfx01 |          2 | e                                 |
| i2uniq     | n_diff_pfx02 |          4 | e,f                               |
| i2uniq     | n_leaf_pages |          1 | Number of leaf pages in the index |
| i2uniq     | size         |          1 | Number of pages in the index      |
+------------+--------------+------------+-----------------------------------+
```

- stat_name=size 时：stat_value 表示索引页的数量
- stat_name=n_leaf_pages 时： stat_value 表示叶子节点的数量
- stat_name=n_diff_pfxNN 时： stat_value 表示索引字段上唯一值的数量，此处做一下具体说明：
    - n_diff_pfx01 表示索引第一列 distinct 之后的数量，如 PRIMARY 的a列，只有一个值1，所以 index_name='PRIMARY' and stat_name='n_diff_pfx01' 时， stat_value=1；
    - n_diff_pfx02 表示索引前两列 distinct 之后的数量，如 i2uniq 的 e,f 列，有4个值，所以 index_name='i2uniq' and stat_name='n_diff_pfx02' 时， stat_value=4；
    - 对于非唯一索引，会在原有列之后加上主键索引，如 index_name=’i1’ and stat_name=’n_diff_pfx03’ ，在原索引列c,d后加了主键列 a，(c,d,a) 的 distinct 结果为2；

了解了 stat_name 和 stat_value 的具体含义，就可以协助我们排查SQL执行时为什么没有使用合适的索引，例如某个索引 n_diff_pfxNN 的 stat_value 远小于实际值，查询优化器认为该索引选择度较差，就有可能导致使用错误的索引。

##### 统计信息不准确的处理
我们查看执行计划，发现未使用正确的索引，如果是 innodb_index_stats 中统计信息差别较大引起，可通过以下方式处理：

1. 手动更新统计信息 `ANALYZE TABLE TABLE_NAME`，注意执行过程中会加读锁；
2. 如果更新后统计信息仍不准确，可考虑增加表采样的数据页，两种方式可以修改：
    1. 全局变量 `INNODB_STATS_PERSISTENT_SAMPLE_PAGES`，默认为20；
    2. 单个表可以指定该表的采样：`ALTER TABLE TABLE_NAME STATS_SAMPLE_PAGES=40`； 经测试，此处 STATS_SAMPLE_PAGES 的最大值是65535，超出会报错。

目前MySQL并没有提供直方图的功能，某些情况下（如数据分布不均）仅仅更新统计信息不一定能得到准确的执行计划，只能通过 index hint 的方式指定索引，新版本8.0会增加直方图功能。

### 索引设计原则
实践中的一些经验法则：

1. 在使用频繁的条件字段上建立索引：根据表上最频繁的查询语句，在 WHERE 条件字段或 JOIN 关联字段上建立索引，关联字段尽量保持和关联表字段相同的数据类型；
2. 在选择性好的字段上建索引：选择性可以用索引基数来衡量，尽量选择不同值较多的字段建立索引，如果索引基数很小，就没有建索引的必要了，建了优化器可能也不会选择，除非是为了满足最左前缀的需求；
3. 过长的字段可以在列前缀上建立索引：在类似 url 这样长度特别大的字段上建立索引，会增加系统开销，如果前几个字段就有不错的选择性，只需要在其前缀上建立索引就好了；
4. 定义联合索引以实现覆盖索引：覆盖索引能够带来性能的极大提升，可以考虑把需要经常查询的字段也加到索引中去；
5. 联合索引选择合适的索引列顺序：需要综合考虑满足频繁查询的最左前缀，以及高选择性字段在前的原则；
6. 减少冗余索引：优化器在选择索引的时候会计算各种索引方案的代价，索引太多也会影响查询性能
    1. 如果创建了索引(A, B) 再创建 (A) 就是冗余索引，因为这只是一个索引前缀
    2. 如果创建了索引(A, B) 再创建 (A, PRIMARY) 也是冗余索引，因为主键已将包含在二级索引树中了
    3. 删除重复索引，重复索引是指在相同列上按相同顺序创建的相同类型的索引，如已经将ID作为主键了，再添加先的索引 INDEX(ID)
    4. 删除未使用的索引

理解索引是如何工作的非常重要，应该根据这些理解来创建最合适的索引，而不是根据一些诸如“在多列索引中将选择性最高的列放在第一列”或“应该为WHERE子句中出现的所有列创建索引”之类的经验法则及其推论。
## 参考

- [漫画：什么是 B+树](https://mp.weixin.qq.com/s/jRZMMONW3QP43dsDKIV9VQ)
- [B树和B+树](https://segmentfault.com/a/1190000020416577)
- [MySQL统计信息系列](http://blog.itpub.net/26736162/viewspace-2644274/)
- [我以为我对Mysql索引很了解，直到我遇到了阿里的面试官](https://zhuanlan.zhihu.com/p/73204847)
- [MySQL · 特性分析 · 5.7 代价模型浅析](http://mysql.taobao.org/monthly/2016/07/02/)
- [MySQL系列(二十)：优化 之 范围查询优化](http://www.gxitsky.com/2019/03/21/mysql-20-Optimizing-Rang-Scan/)