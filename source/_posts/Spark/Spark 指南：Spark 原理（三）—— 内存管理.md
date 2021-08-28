---
title: Spark 指南：Spark 原理（三）—— 内存管理
date: 2020-11-14 15:29:53
tags: 
   - Spark
categories: 
   - Spark
---
> 原文最初由 IBM developerWorks 中国网站发表，本文在此基础上进行了总结梳理，仅作为个人学习使用。

Spark 作为一个基于内存的分布式计算引擎，其内存管理模块至关重要。理解 Spark 内存管理的基本原理，有助于更好地开发 Spark 应用程序和性能调优。本文基于 Spark 2.1 版本，旨在梳理 Spark 内存管理的基本脉络。

在执行 Spark 应用程序时，Spark 集群会启动 Driver 和 Executor 两种 JVM 进程：

1. Driver 为主控进程，主要负责：
    1. 创建 Spark 上下文；
    2. 提交 Spark 作业（Job）；
    3. 在各 Executor 进程间分配、协调任务（Task）调度；
2. Executor 主要负责：
    1. 在工作节点上执行具体的计算任务（Task）；
    2. 将结果返回给 Driver；
    3. 为需要持久化的 RDD 提供存储功能；

由于 Driver 的内存管理相对简单，本文主要对 Executor 的内存管理进行分析，下文中 Spark 内存均指 Executor 内存。

## 内存规划
作为一个 JVM 进程，Executor 的内存管理建立在 JVM 的内存管理之上，Spark 对 JVM 的堆内（On-heap）空间进行了更为详细的分配，以充分利用内存。同时，Spark 引入了堆外（Off-heap）内存，使之可以直接在工作节点的系统内存中开辟空间，进一步优化了内存的使用。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20210112235829.png" width="100%" heigh="80%"></img>
</div>

## 堆内内存（On-Heap）
Executor 内运行的并发任务共享 JVM 堆内内存，堆内内存的大小由 Spark 应用程序启动时的 `–executor-memory` 或 `spark.executor.memory` 参数配置（默认 1g），Spark 对堆内内存进行了详细的规划：

1. 统一内存（Unified）：Spark 1.6 之后引入了统一内存管理机制，存储内存和执行内存共享该块空间，可以动态占用对方的空闲区域，统一内存的大小（占堆内内存比例）可以通过 Spark 参数 `spark.memory.fraction` 来设置（默认 0.6） 
    1. 存储内存（Storage）：在缓存 RDD 或广播（Broadcast）数据时占用的内存被规划为存储内存，存储内存的大小（占统一内存比例）可以通过 Spark 参数 `spark.memory.storagefraction` 来设置（默认 0.5）；
    2. 执行内存（Execution）：在执行 Shuffle、Join、Sort、Aggregation 等转换时占用的内存被规划为执行内存；
2. 剩余内存（Other）：Spark 内部的对象实例，或者用户定义的 Spark 应用程序中的对象实例，元数据占用剩余内存，Spark 对剩余内存不做特殊规划；
3. 预留内存（Reserved）：默认 300M 的系统预留内存，主要用于程序运行，参见SPARK-12081；

总结堆内内存的规划大小计算公式如下：

| 规划项             | 计算公式                                                                                 | 默认值                       |
|-----------------|--------------------------------------------------------------------------------------|---------------------------|
| 堆内内存（On-Heap）   | `spark.executor.memory`                                                              | 1g                        |
| 统一内存（Unified）   | `spark.executor.memory * spark.memory.fraction`                                      | 1g * 0.6 = 600M           |
| 存储内存（Storage）   | `spark.executor.memory * spark.memory.fraction * spark.memory.storagefraction`       | 1g * 0.6 * 0.5 = 300M     |
| 执行内存（Execution） | `spark.executor.memory * spark.memory.fraction * (1 - spark.memory.storagefraction)` | 1g * 0.6 * (1-0.5) = 300M |
| 剩余内存（Other）     | `spark.executor.memory * (1 - spark.memory.fraction)`                                | 1g * (1-0.6) = 400M       |
| 预留内存（Reserved）  | 300M                                                                                 | 300M                      |

Spark 对堆内内存的管理只是一种”规划式“的管理，因为对象实例占用内存的申请和释放都由 JVM 完成，Spark 只能在申请和释放前记录这些内存，其具体流程为：

1. 申请内存：
    1. Spark 在代码中创建一个对象实例；
    2. JVM 从堆内内存分配空间，创建对象并返回对象引用；
    3. Spark 保存该对象的引用，记录该对象占用的内存；
2. 释放内存：
    1. Spark 记录该对象释放的内存，删除该对象的引用；
    2. 等待 JVM 的垃圾回收机制释放该对象占用的堆内内存；

JVM 对象可以以序列化（将对象转化为二进制字节流）的方式存储，本质上可以理解为将非连续的链式存储转化为连续存储，在访问时则需要进行反序列化（将字节流转化为对象），这种方式节省了空间，但是增加了存储和读取的计算开销。对于序列化对象，由于是字节流的形式，其占用的内存大小可以直接计算，而对于非序列化对象，其占用的内存则通过周期采样近似估算，这种方式降低了时间开销但是可能误差较大，导致某一时刻的实际内存有可能远远超出预期。此外，在被 Spark 标记为释放的对象实例，很有可能在实际上并没有被 JVM 回收，导致实际可用的内存小于 Spark 记录的可用内存。所以 Spark 并不能准确记录实际可用的堆内内存，从而也就无法完全避免内存溢出（OOM, Out of Memory）的异常。

### 统一内存管理
Spark 1.6 之后引入了统一内存管理机制，存储内存和执行内存共享同一块空间，可以动态占用对方的空闲区域，如图所示：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/memory_0114.png" width="100%" heigh="80%"></img>
</div>

统一内存的动态占用机制：

1. 当存储内存和执行内存都不足时，则存储到磁盘；当己方空间不足而对方空间空余时，可借用对方空间；
2. 执行内存被存储占用时，可以让对方将占用的部分转存到硬盘，归还借用的空间；
3. 存储内存被执行占用时，无法让对方归还，因为考虑 Shuffle 过程的很多因素，不好实现；

凭借统一内存管理机制，Spark 在一定程度上提高了堆内和堆外内存资源的利用率，降低了开发者维护 Spark 内存的难度，但并不意味着开发者可以高枕无忧。譬如，所以如果存储内存的空间太大或者说缓存的数据过多，反而会导致频繁的全量垃圾回收，降低任务执行时的性能，因为缓存的 RDD 数据通常都是长期驻留内存的。所以要想充分发挥 Spark 的性能，需要开发者进一步了解存储内存和执行内存各自的管理方式和实现原理。

### 存储内存管理
#### RDD 持久化机制
弹性分布式数据集（RDD）作为 Spark 最根本的数据抽象，是只读的分区记录（Partition）的集合，只能基于在稳定物理存储中的数据集上创建，或者在其他已有的 RDD 上执行转换（Transformation）操作产生一个新的 RDD。转换后的 RDD 与原始的 RDD 之间产生的依赖关系，构成了血统（Lineage）。凭借血统，Spark 保证了每一个 RDD 都可以被重新恢复。但 RDD 的所有转换都是惰性的，即只有当一个返回结果给 Driver 的行动（Action）发生时，Spark 才会创建任务读取 RDD，然后真正触发转换的执行。

Task 在启动之初读取一个分区时，会先判断这个分区是否已经被持久化，如果没有则需要检查 Checkpoint 或按照血统重新计算。所以如果一个 RDD 上要执行多次 Action，可以在第一次 Action 中使用 persist 或 cache 方法，在内存或磁盘中持久化或缓存这个 RDD，从而在后面的行动时提升计算速度。事实上，cache 方法是使用默认的 MEMORY_ONLY 的存储级别将 RDD 持久化到内存，故缓存是一种特殊的持久化。 堆内和堆外存储内存的设计，便可以对缓存 RDD 时使用的内存做统一的规划和管理。

RDD 的持久化由 Spark 的 Storage 模块负责，实现了 RDD 与物理存储的解耦合。Storage 模块负责管理 Spark 在计算过程中产生的数据，将那些在内存或磁盘、在本地或远程存取数据的功能封装了起来。在具体实现时 Driver 端和 Executor 端的 Storage 模块构成了主从式的架构，即 Driver 端的 BlockManager 为 Master，Executor 端的 BlockManager 为 Slave。Storage 模块在逻辑上以 Block 为基本存储单位，RDD 的每个 Partition 经过处理后唯一对应一个 Block（BlockId 的格式为 rdd_RDD-ID_PARTITION-ID ）。Master 负责整个 Spark 应用程序的 Block 的元数据信息的管理和维护，而 Slave 需要将 Block 的更新等状态上报到 Master，同时接收 Master 的命令，例如新增或删除一个 RDD。

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/202101151555.png" width="60%" heigh="80%"></img>
</div>

在对 RDD 持久化时，Spark 规定了 MEMORY_ONLY、MEMORY_AND_DISK 等 7 种不同的 [存储级别](http://spark.apache.org/docs/latest/rdd-programming-guide.html) ，而存储级别是以下 5 个变量的组合：

```java
class StorageLevel private(
    private var _useDisk: Boolean,      // 磁盘
    private var _useMemory: Boolean,    // 堆内内存
    private var _useOffHeap: Boolean,   // 堆外内存
    private var _deserialized: Boolean, // 是否为非序列化
    private var _replication: Int = 1   // 副本个数
)
```

通过对数据结构的分析，可以看出存储级别从三个维度定义了 RDD 的 Partition（同时也就是 Block）的存储方式：

1. 存储位置：磁盘／堆内内存／堆外内存。如 MEMORY_AND_DISK 是同时在磁盘和堆内内存上存储，实现了冗余备份。OFF_HEAP 则是只在堆外内存存储，目前选择堆外内存时不能同时存储到其他位置；
2. 存储形式：Block 缓存到存储内存后，是否为非序列化的形式。如 MEMORY_ONLY 是非序列化方式存储，OFF_HEAP 是序列化方式存储；
3. 副本数量：大于 1 时需要远程冗余备份到其他节点。如 DISK_ONLY_2 需要远程备份 1 个副本；

#### RDD 缓存过程
RDD 缓存的过程是将对象从 other 内存区迁移至 Storage 区或 Disk 的过程：

1. RDD 在缓存到存储内存之前：Partition 中的数据一般以迭代器（Iterator）的数据结构来访问，这是 Scala 语言中一种遍历数据集合的方法。通过 Iterator 可以获取分区中每一条序列化或者非序列化的数据项(Record)，这些 Record 的对象实例在逻辑上占用了 JVM 堆内内存的 other 部分的空间，同一 Partition 的不同 Record 的空间并不连续；
2. RDD 在缓存到存储内存之后：Partition 被转换成 Block，Record 在堆内或堆外存储内存中占用一块连续的空间，当存储空间不足时会根据动态占用机制进行处理。将 Partition 由不连续的存储空间转换为连续存储空间的过程，Spark 称之为”展开”（Unroll）。Block 有序列化和非序列化两种存储格式，具体以哪种方式取决于该 RDD 的存储级别
    1. 非序列化的 Block 以一种 DeserializedMemoryEntry 的数据结构定义，用一个数组存储所有的对象实例；
    2. 序列化的 Block 则以 SerializedMemoryEntry的数据结构定义，用字节缓冲区（ByteBuffer）来存储二进制数据。每个 Executor 的 Storage 模块用一个链式 Map 结构（LinkedHashMap）来管理堆内和堆外存储内存中所有的 Block 对象的实例[6]，对这个 LinkedHashMap 新增和删除间接记录了内存的申请和释放；

因为不能保证存储空间可以一次容纳 Iterator 中的所有数据，当前的计算任务在 Unroll 时要向 MemoryManager 申请足够的 Unroll 空间来临时占位，空间不足则 Unroll 失败，空间足够时可以继续进行。对于序列化的 Partition，其所需的 Unroll 空间可以直接累加计算，一次申请。而非序列化的 Partition 则要在遍历 Record 的过程中依次申请，即每读取一条 Record，采样估算其所需的 Unroll 空间并进行申请，空间不足时可以中断，释放已占用的 Unroll 空间。如果最终 Unroll 成功，当前 Partition 所占用的 Unroll 空间被转换为正常的缓存 RDD 的存储空间，如下图所示：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/spark_unroll.png" width="70%" heigh="80%"></img>
</div>

#### 淘汰和落盘
由于同一个 Executor 的所有的计算任务共享有限的存储内存空间，当有新的 Block 需要缓存但是剩余内存空间不足且无法动态占用时，就要对 LinkedHashMap 中的旧 Block 进行淘汰（Eviction），而被淘汰的 Block 如果其存储级别中同时包含存储到磁盘的要求，则要对其进行落盘（Drop），否则直接删除该 Block。

存储内存的淘汰规则为：

1. 被淘汰的旧 Block 要与新 Block 的 MemoryMode 相同，即同属于堆外或堆内内存；
2. 新旧 Block 不能属于同一个 RDD，避免循环淘汰；
3. 旧 Block 所属 RDD 不能处于被读状态，避免引发一致性问题；
4. 遍历 LinkedHashMap 中 Block，按照最近最少使用（LRU）的顺序淘汰，直到满足新 Block 所需的空间。其中 LRU 是 LinkedHashMap 的特性；

存储内存的落盘规则为：如果其存储级别符合 `_useDisk` 为 true 的条件，再根据其`_deserialized` 判断是否是非序列化的形式，若是则对其进行序列化，最后将数据存储到磁盘，在 Storage 模块中更新其信息。

### 执行内存管理
#### 多任务间内存分配
Executor 内运行的任务同样共享执行内存，Spark 用一个 HashMap 结构保存了任务到内存耗费的映射。每个任务可占用的执行内存大小的范围为 1/2N ~ 1/N，其中 N 为当前 Executor 内正在运行的任务的个数。每个任务在启动之时，要向 MemoryManager 请求申请最少为 1/2N 的执行内存，如果不能被满足要求则该任务被**阻塞**，直到有其他任务释放了足够的执行内存，该任务才可以被唤醒。

#### Shuffle 内存占用
执行内存主要用来存储任务在执行 Shuffle 时占用的内存，Shuffle 是按照一定规则对 RDD 数据重新分区的过程，我们来看 Shuffle 的 Write 和 Read 两阶段对执行内存的使用：

1. Shuffle Write
    1. 若在 map 端选择普通的排序方式，会采用 ExternalSorter 进行外排，在内存中存储数据时主要占用堆内执行空间；
    2. 若在 map 端选择 Tungsten 的排序方式，则采用 ShuffleExternalSorter 直接对以序列化形式存储的数据排序，在内存中存储数据时可以占用堆外或堆内执行空间，取决于用户是否开启了堆外内存以及堆外执行内存是否足够；
2. Shuffle Read
    1. 在对 reduce 端的数据进行聚合时，要将数据交给 Aggregator 处理，在内存中存储数据时占用堆内执行空间；
    2. 如果需要进行最终结果排序，则要再次将数据交给 ExternalSorter 处理，占用堆内执行空间；

在 ExternalSorter 和 Aggregator 中，Spark 会使用一种叫 AppendOnlyMap 的哈希表在堆内执行内存中存储数据，但在 Shuffle 过程中所有数据并不能都保存到该哈希表中，当这个哈希表占用的内存会进行周期性地采样估算，当其大到一定程度，无法再从 MemoryManager 申请到新的执行内存时，Spark 就会将其全部内容存储到磁盘文件中，这个过程被称为溢存(Spill)，溢存到磁盘的文件最后会被归并(Merge)。

Shuffle Write 阶段中用到的 Tungsten 是 Databricks 公司提出的对 Spark 优化内存和 CPU 使用的计划，解决了一些 JVM 在性能上的限制和弊端。Spark 会根据 Shuffle 的情况来自动选择是否采用 Tungsten 排序。Tungsten 采用的页式内存管理机制建立在 MemoryManager 之上，即 Tungsten 对执行内存的使用进行了一步的抽象，这样在 Shuffle 过程中无需关心数据具体存储在堆内还是堆外。每个内存页用一个 MemoryBlock 来定义，并用 Object obj 和 long offset 这两个变量统一标识一个内存页在系统内存中的地址。堆内的 MemoryBlock 是以 long 型数组的形式分配的内存，其 obj 的值为是这个数组的对象引用，offset 是 long 型数组的在 JVM 中的初始偏移地址，两者配合使用可以定位这个数组在堆内的绝对地址；堆外的 MemoryBlock 是直接申请到的内存块，其 obj 为 null，offset 是这个内存块在系统内存中的 64 位绝对地址。Spark 用 MemoryBlock 巧妙地将堆内和堆外内存页统一抽象封装，并用页表(pageTable)管理每个 Task 申请到的内存页。Tungsten 页式管理下的所有内存用 64 位的逻辑地址表示，由页号和页内偏移量组成：

1. 页号：占 13 位，唯一标识一个内存页，Spark 在申请内存页之前要先申请空闲页号。
2. 页内偏移量：占 51 位，是在使用内存页存储数据时，数据在页内的偏移地址。

有了统一的寻址方式，Spark 可以用 64 位逻辑地址的指针定位到堆内或堆外的内存，整个 Shuffle Write 排序的过程只需要对指针进行排序，并且无需反序列化，整个过程非常高效，对于内存访问效率和 CPU 使用效率带来了明显的提升。

Spark 的存储内存和执行内存有着截然不同的管理方式：对于存储内存来说，Spark 用一个 LinkedHashMap 来集中管理所有的 Block，Block 由需要缓存的 RDD 的 Partition 转化而成；而对于执行内存，Spark 用 AppendOnlyMap 来存储 Shuffle 过程中的数据，在 Tungsten 排序中甚至抽象成为页式内存管理，开辟了全新的 JVM 内存管理机制。

## 堆外内存（Off-Heap）
为了进一步优化内存的使用以及提高 Shuffle 时排序的效率，Spark 引入了堆外（Off-heap）内存，使之可以直接在工作节点的系统内存中开辟空间，存储经过序列化的二进制数据。利用 JDK Unsafe API（从 Spark 2.0 开始，在管理堆外的存储内存时不再基于 Tachyon，而是与堆外的执行内存一样，基于 JDK Unsafe API 实现），Spark 可以直接操作系统堆外内存，减少了不必要的内存开销，以及频繁的 GC 扫描和回收，提升了处理性能。堆外内存可以被精确地申请和释放，而且序列化的数据占用的空间可以被精确计算，所以相比堆内内存来说降低了管理的难度，也降低了误差。

在默认情况下堆外内存并不启用，可通过配置 `spark.memory.offHeap.enabled` 参数启用，并由 `spark.memory.offHeap.size` 参数设定堆外空间的大小。除了没有 other 空间，堆外内存与堆内内存的划分方式相同，所有运行中的并发任务共享存储内存和执行内存。

## 运行实例
假设 Spark 应用程序运行参数设置如下：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/202101152046.png" width="100%" heigh="80%"></img>
</div>

Spark 应用程序运行过程中，我们可以在 Web UI -> Executors 中查看 Excutor 内存实际使用大小/内存规划大小：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20212051.png" width="100%" heigh="80%"></img>
</div>

从该实例可以看出 Executor 的统一内存为 5.9G，与理论计算出来的值相近（10G * 0.6 = 6G），存储内存为 5.8 G，动态占用机制使得存储内存占用了绝大部分统一内存，导致只有很少的内存用于 Shuffle，这也是影响本任务执行效率的关键问题。此外，Driver 的内存基本没有被存储占用，有充足的内存可以用于执行 Spark 程序，可以适当减少 Driver 端内存分配。

进一步考察存储内存占用过高的原因，可以看到该程序缓存了非常大的中间结果，可以选择把缓存数据全部存储到磁盘，在这个场景下不会对缓存过程有太大影响，却可以保证充足的执行内存：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/affdssgg.png" width="100%" heigh="80%"></img>
</div>

## 参考
[Apache Spark 内存管理详解](https://developer.ibm.com/zh/articles/ba-cn-apache-spark-memory-management/)
[Spark 配置](https://spark.apache.org/docs/latest/configuration.html)
[yarn 资源管理参数设置](https://blog.csdn.net/suifeng3051/article/details/45477773)
[Spark 性能优化指南(官网文档)](https://my.oschina.net/cutexim/blog/4416369)