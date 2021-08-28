---
title: 数据结构与算法：Trie 树
date: 2017-10-10 20:13:53
tags: 
    - 数据结构与算法
categories:
    - 数据结构与算法
---

## 理论篇
### 大量字符串的存储-查找-排序问题
Trie树，又称字典树、前缀树(Prefix Tree)、单词查找树或键树，是一种树形结构，主要用于对大量字符串（不仅限于字符串）的高效存储、查询、排序，经常被搜索引擎系统用于文本词频统计。

以词频统计为例，最直接的想法是使用哈希表来统计每个单词的词频，它的时间复杂度为O(n)，空间复杂度为O(dn)，其中n表示单词个数，d表示单词的平均长度。但考虑到下列事实，哈希表并不总是最好的选择：

1. 空间：哈希表需要存储每个不同的单词，当单词量很大时会出现大量相同前缀的单词，对每一个这样的单词，哈希表都会做重复的存储；此外，为了尽可能避免键值冲突，哈希表需要额外的空间避开碰撞，还会有一部分的空间被浪费；
2. 时间：尤其是数据体量增大之后，其查词复杂度常常难以维持在O(1)，同时，对哈希值的计算也需要额外的时间，其具体复杂度由相应的哈希实现来定；

Trie树能够在保证近似O(1)的查询效率的同时，利用字符串本身的特性对数据进行一定程度的压缩。

### 逻辑结构
Trie树定义：

1. 根节点不含字符，每个非根节点只含一个字符；
2. 从根节点到某一节点，路径上经过的字符连起来，即是该节点对应的字符串；
3. 每个节点的所有子节点所包含的字符各不相同；

单词列表为['apps','apply','apple','append','back','backen','basic']对应的Trie树如下：

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/21-02-02.png" width="60%" heigh="60%"></img>
</div>


### 存储结构
Trie树的实现方式多种多样，常见的有以下几种：

Trie树类别|说明|优点|缺点
:---|:---|:---|:---
Array Trie|用定长数组表示Trie树，数组大小为字符集大小，下标代表了字符集中的字符，值代表了子Trie树|巧妙的利用了等长数组中元素位置和值的一一对应关系，完美的实现了了寻址、存值、取值的统一|每一层都要有一个数组，每个数组都必须等长，这在实际应用中会造成大多数的数组指针空置
List Trie|用可变数组表示Trie树|避免空间浪费|无法通过下标得到对应字符，需要遍历，时间O(d)
Hash Trie|用嵌套字典表示Trie树,key表示下一个字符，字典中的value是嵌套的子树|有效的减少空间浪费|对哈希值的计算也需要额外的时间，因此实际查询效率要比Array Trie实现低
Double-array Trie树|将所有节点的状态都记录到一个数组之中（Base Array），避免数组的大量空置，check array 与 base array 等长，它的作用是标识出 base array 中每个状态的前一个状态|Trie 树各种实现中性能和存储空间均达到很好效果|实现复杂

本文着重讨论方便易行且性能堪用的Array Trie 和 Hash Trie。

#### Array Trie
定长数组Trie树：节点包含用数组表示的子节点域和用布尔值表示的词尾标识域，数组大小为字符集大小，数组下标与字符集中的字符构成一一映射，数组中的值存放子Trie树节点。

```python
class Trie(object):
    def __init__(self, N):
        self.children = [None] * N
        self.isword = False
```
#### Hash Trie
Hash Trie树：节点包含用字典表示的子节点域和用布尔值表示的词尾标识域，字典中的key为子节点代表的字符，字典中的value代表子节点对应的子Trie树

```python
class Trie(object):
    def __init__(self):
        self.children = {}
        self.isword = False
```

对于Trie树的简单应用，可以直接用嵌套字典简单实现，整个字典表示一棵Trie树，字典中的key表示下一个字符，字典中的value是嵌套的字典，表示以key为根节点的子Trie树

```python
trie = {}
... ...
trie = {'a': {'p': {'p': {'e': {'n': {'d': {'': {}}}},'l': {'e': {'': {}}, 'y': {'': {}}},'s': {'': {}}}}},
 'b': {'a': {'c': {'k': {'': {}, 'e': {'n': {'': {}}}}},'s': {'i': {'c': {'': {}}}}}}}
```


### 基本操作
#### 操作定义
单词插入和查找是Trie树最基本的操作：

- insert(word):将word插入到Trie树中
- find(word):在Trie树中查找word，找到则返回True，找不到则返回False

此外经常需要判断前缀存在性、统计词频、打印Trie树中所有的单词等操作：

- startwith(prefix)：判断Trie树中是否有以prefix作为前缀的单词
- count(word)：统计单词表中某个单词word的词频
- print_trie()：打印Trie树中所有不同的单词

#### 操作实现
##### Array Trie
```python
class Trie_node(object):
    def __init__(self,N):
        """
        N:字符表长度
        """
        # 子树数组
        self.children = [None] * N
        # 是否为结尾节点
        self.isword = False
        # 以该节点结尾的单词出现次数
        self.count = 0

class Trie(object):
    def __init__(self,chars):
        """
        chars:组成所有单词的字符表(数组)
        """
        # 下标->字符
        self.chars = chars
        # 字符表长度
        self.n = len(self.chars)
        # 字符->下标
        self.c2i = {self.chars[i]:i for i in xrange(self.n)}
        # 根节点
        self.root = Trie_node(self.n)
        

    def insert(self, word):
        """
        插入一个新的字符串
        """
        node = self.root
        for c in word:
            if not node.children[self.c2i[c]]:
                node.children[self.c2i[c]] = Trie_node(self.n)
            node = node.children[self.c2i[c]]
        node.isword = True
        node.count += 1
        

    def find(self, word):
        """
        判断word是否在Trie树中
        """
        node = self.root
        for c in word:
            if node.children[self.c2i[c]]:
                node = node.children[self.c2i[c]]
            else:
                return False
        return node.isword
        

    def startsWith(self, prefix):
        """
        判断Trie树中是否有以prefix作为前缀的单词        
        """
        node = self.root
        for c in prefix:
            if node.children[self.c2i[c]]:
                node = node.children[self.c2i[c]]
            else:
                return False
        return True
    
    def get_count(self, word):
        """
        统计单词word出现的次数
        """
        node = self.root
        for c in word:
            if node.children[self.c2i[c]]:
                node = node.children[self.c2i[c]]
            else:
                return 0
        return node.count
            
    def printt(self):
        """
        打印Trie中所有单词及其出现次数
        """
        def dfs(node,cur,res):
            if node.count:
                res.append([cur, node.count])
            for i,child in enumerate(node.children):
                if child:
                    dfs(child, cur+self.chars[i], res)
        res = []
        dfs(self.root,'',res)
        return res
        
# Your Trie object will be instantiated and called as such:
chars = map(char(i) for i in xrange(97,123))
obj = Trie(chars)
obj.insert(word)
param_2 = obj.find(word)
```

分析：假设字符串数量很大为n，字符集大小为m，单词平均长度为d

1. 空间：在Trie树充分生长的情况下，节点数2^d，每个节点中数组长度为m，总体为O(m2^d)，实际情况取决于单词间前缀的重叠情况，近似O(mn)
2. 时间：无论查找还是插入，单次O(d)

##### Hash Trie
标准实现：

```python
class Trie_node(object):
    def __init__(self):
        self.children = {}
        self.isword = False
        self.count = 0

class Trie(object):
    def __init__(self):
        self.root = Trie_node()

    def insert(self, word):
        node = self.root
        for c in word:
            node = node.children.setdefault(c,Trie_node())
        node.isword = True
        
    def find(self, word):
        node = self.root
        for c in word:
            if c in node.children:
                node = node.children[c]
            else:
                return False
        return node.isword
        
    def startsWith(self, prefix):
        node = self.root
        for c in prefix:
            if c in node.children:
                node = node.children[c]
            else:
                return False
        return True
    
    def get_count(self, word):
        node = self.root
        for c in word:
            if c in node.children:
                node = node[c]
            else:
                return 0
        return node.count
            
    def printt(self):
        def dfs(node,cur,res):
            if node.count:
                res.append([cur, node.count])
            for child in node.children:
                dfs(node.children[child],cur+child,res)
        res = []
        dfs(self.root,'',res)
        return res
        
# Your Trie object will be instantiated and called as such:
trie = Trie()
trie.insert(word)
trie.find(word)
```

简单实现：

```python
def insert(trie,word):
    for c in word:
        trie = trie.setdefault(c,{})
    trie['#'] = trie.get('#',0) + 1

def find(trie,word):
    for c in word:
        if c in trie:
            trie = trie[c]
        else:
            return False
    return '#' in trie

def startsWith(trie, prefix):
    for c in prefix:
        if c in trie:
            trie = trie[c]
        else:
            return False
    return True

def get_count(trie, word):
    for c in word:
        if c in trie:
            trie = trie[c]
        else:
            return 0
    return trie.get('#',0)
        
def printt(trie):
    def dfs(node,cur,res):
        if node.get('#',0):
            res.append([cur, node['#']])
        for child in node:
            dfs(node[child],cur+child,res)
    res = []
    dfs(trie,'',res)
    return res
    
# Your Trie object will be instantiated and called as such:
trie = {}
x = ['apps','apply','apple','append','back','backen','basic']
insert(trie,word)
find(trie,word)
```

分析：假设字符串数量很大为n，字符集大小为m，单词平均长度为d

1. 空间：trie树充分生长的情况下，节点数2^d，每个节点中字典长度为m，总体为O(m2^d)，在实际情况中，节点数取决于单词间前缀重叠情况，边数小于O(dn)，故空间复杂度<O(min(m,d)n)
2. 时间：无论查找还是插入，只需要O(d)

## 实战篇
### 实战技巧
1. 通常Trie树与哈希表的作用类似，都是以空间换取时间来提高查询效率(出于某种原因我们需要将某些中间结果存储起来，然后以O(1)的时间去读取，如DP问题)
    1. 如果只是要提高查询效率，应首先尝试哈希表，操作简单，适用广泛，且在大多数情况下效率不输Trie树；
    2. 只有在某些特定情况下才能够或才应该尝试Trie树，① 可以转化/类比为字符串查询的问题(如二进制Trie树) ② 使用哈希表将浪费大量空间，可以通过Trie树实现空间压缩的问题
2. 对于简单问题，可以直接采用最简单的嵌套字典方式来实现，同时我们可以在单词结尾存储有价值的信息来作为结尾标识；对于复杂的衍生问题，自定义节点提供了更多的扩展性；
3. 如果需要对字符串排序，可以通过遍历Array Trie来实现
4. n个单词插入和查询的空间近似O(mn)，时间O(dn)，m为字符表长度，d为单词平均长度，可**近似看做O(n)**；

### LeetCode 经典题目

#### 单词替换为前缀
- 问题：[648] 单词替换，在英语中，我们有一个叫做 词根(root)的概念，它可以跟着其他一些词组成另一个较长的单词——我们称这个词为 继承词(successor)

```
输入: dict(词典) = ["cat", "bat", "rat"]
sentence(句子) = "the cattle was rattled by the battery"
输出: "the cat was rat by the bat"
```
- 思路：构建前缀树，然后遍历查询每个单词，如果前进时都遇到单词结尾，则返回前缀
- 代码：

```python
def replaceWords(self, dict, sentence):
    """
    :type dict: List[str]
    :type sentence: str
    :rtype: str
    """
    root = {}
    for word in dict:
        node = root
        for c in word:
            node = node.setdefault(c,{})
        node.setdefault('',{})
    
    def search(word):
        node = root
        for i,c in enumerate(word):
            if '' in node:
                return word[:i]
            else:
                if c in node:
                    node = node[c]
                else:
                    return word
        return word
                
    return ' '.join(map(search,sentence.split()))  
```

- 分析：时间O(nd)

#### 数组中两个数的最大异或值

- 问题：[421] 数组中两个数的最大异或值，给定一个非空数组，数组中元素为 a0, a1, a2, … , an-1，其中 0 ≤ ai < 2^31 ，在O(n)时间内找到 ai 和aj 最大的异或 (XOR) 运算结果，其中0 ≤ i,  j < n 
- 思路：二进制Trie树+贪心：难点在于O(n)的时间要求，将每个数转化为31位二进制串，首先构建二进制Trie树，然后在Trie树中查找每个二进制串，贪心策略，高位异或为1的肯定较大，如果子节点中有与当前字符相异的，则走相异的子节点，否则走相同的！经典！
- 代码：

```python
    def findMaximumXOR(self, nums):
        """
        :type nums: List[int]
        :rtype: int
        """
        root = {}
        res = -1
        for num in nums:
            node = root
            bi_str = format(num,'b').zfill(31)
            for bit in bi_str:
                node = node.setdefault(bit,{})
            node.setdefault('value',num)
            
            node = root
            for bit in bi_str:
                if bit == '0' and '1' in node:
                    node = node['1']
                elif bit == '1' and '0' in node:
                    node = node['0']
                else:
                    node = node[bit]
            
            res = max(node['value'] ^ num,res)
        
        return res
```

#### 前 K 个高频单词
- 问题：[692】 前K个高频单词，给一非空的单词列表，返回前 k 个出现次数最多的单词。返回的答案应该按单词出现频率由高到低排序。如果不同的单词有相同出现频率，按字母顺序排序。尝试以 O(n log k) 时间复杂度和 O(n) 空间复杂度解决
- 思路：O(n)空间可以用Trie树或者一般哈希表，O(nlgk)需要长为k的小根堆；
    - 构建Trie树：将单词表中所有单词插入到Trie树，同时统计每个单词的词频；
    - 构建定长小根堆：如果堆的长度小于k则直接将单词和词频压入，否则先入堆再出堆，需要注意的是，词频越小优先级越高，单词字典序越大优先级越高，这需要自定义入栈元素的有限集，可以通过重载<运算符来实现
- 代码：

```python
import heapq

class Trie_node(object):
    def __init__(self):
        self.children = {}
        self.count = 0

class Trie(object):
    def __init__(self):
        self.root = Trie_node()
        
    def insert(self, word):
        node = self.root
        for c in word:
            node = node.children.setdefault(c,Trie_node())
        node.count += 1
    
    def find(self, word):
        node = self.root
        for c in word:
            if c in node.children:
                node = node.children[c]
            else:
                return 0
        return node.count
    
    def get_freqs(self):
        def dfs(node,cur,res):
            if node.count:
                res.append([cur, node.count])
            for child in node.children:
                dfs(node.children[child],cur+child,res)
        res = []
        dfs(self.root,'',res)
        return res
            

class Element(object):
    def __init__(self, word, freq):
        self.freq = freq
        self.word = word
    
    def __lt__(self, other):
        """
        重载<操作符
        """
        if self.freq == other.freq:
            return self.word > other.word
        return  self.freq < other.freq
    
class Solution(object):
    def topKFrequent(self, words, k):
        """
        :type words: List[str]
        :type k: int
        :rtype: List[str]
        """
        counter = Counter(words)
        heap = []
        count = 0
        for word in counter:
            heapq.heappush(heap,Element(word,counter[word]))
            count += 1
            if count > k:
                heapq.heappop(heap)
        return [ele.word for ele in heapq.nlargest(k,heap)]
```

- 分析：
    - 空间：构建Trie树O(n)，构建小根堆O(n)
    - 时间：构建Trie树O(n)，小根堆维护O(nlgk)

#### 连接词
- 问题：[472] 连接词，给定一个不含重复单词的列表，编写一个程序，返回给定单词列表中所有的连接词，连接词的定义为：一个字符串完全是由至少两个给定数组中的单词(非空)组成的
```
输入: ["cat","cats","catsdogcats","dog","dogcatsdog","hippopotamuses","rat","ratcatdogcat"]
输出: ["catsdogcats","dogcatsdog","ratcatdogcat"]
```
- 思路： 判断单词是否为连接词等价于判断单词是否可以由至少两个前缀词构成
    - 思路1：哈希表+DFS，将所有单词存放在哈希表中，遍历单词的各个可能的前缀，如果对应后缀在哈希表中或者是连接词，则返回True，否则返回False
    - 思路2：双哈希+DFS+DP，思路1存在重叠子问题，可以用另一个哈希表存储已找到的所有可连接的词；
    - 思路3：Trie树+哈希+DFS+DP，存储这么多的单词，耗费空间巨大，可考虑用Trie树来降低空间复杂度，与思路2基本一致，只是用Trie树代替第一个哈希表

- 代码：

```python
# 思路2：双哈希+DFS+DP
def findAllConcatenatedWordsInADict(self, words):
    """
    :type words: List[str]
    :rtype: List[str]
    """
    def dfs(word):
        if word in dp:
            return True
        for i,c in enumerate(word,1):
            left,right = word[:i],word[i:]
            if left in s and (right in s or dfs(right)):
                dp.add(word)
                return True
        return False
        
    s = set(word for word in words if word)
    dp = set()
    return filter(dfs,words)
```

```python
# 思路3：
def findAllConcatenatedWordsInADict(self, words):
    """
    :type words: List[str]
    :rtype: List[str]
    """
    def insert(trie,word):
        for c in word:
            trie = trie.setdefault(c,{})
        trie['#'] = True
            
    def find(trie,word):
        for c in word:
            if c in trie:
                trie = trie[c]
            else:
                return False
        return '#' in trie
    
    def dfs(word):
        if word in dp:
            return True
        for i,c in enumerate(word,1):
            left,right = word[:i], word[i:]
            if find(trie,left) and (find(trie,right) or dfs(right)):
                dp.add(word)
                return True
        return False
        
    trie = {}
    dp = set()
    for word in words:
        if word:
            insert(trie,word)
    
    return filter(dfs, words)
```

- 分析：思路2与思路3一个用哈希表，一个用Trie树，除此之外几乎完全一致，理论上二者时间复杂度相近，但实际测试发现前者444ms，后者2000ms；而且前者代码要简洁的多。

#### 回文对
- 问题：[336]回文对，给定一组独特的单词， 找出在给定列表中不同 的索引对(i, j),使得关联的两个单词，例如：words[i] + words[j]形成回文。
```
给定 words = ["abcd", "dcba", "lls", "s", "sssll"]
返回 [[0, 1], [1, 0], [3, 2], [2, 4]]
回文是 ["dcbaabcd", "abcddcba", "slls", "llssssll"]
```
- 思路：Trie树/哈希，如果a的前缀是回文，且对应后缀的逆序b在数组中，则b+a构成回文对，类似的，如果a的后缀是回文，且对应的前缀b在数组中，则a+b是回文对，但是后缀为空的情况与对方前缀为空的情况重复，对后缀只讨论非空的情形

- 代码：

```python
def palindromePairs(self, words):
    """
    :type words: List[str]
    :rtype: List[List[int]]
    """
    def insert(trie,word,i):
        node = trie
        for c in word:
            node = node.setdefault(c,{})
        node['#'] = i
        
    def find(trie,word):
        node = trie
        for c in word:
            if c in node:
                node = node[c]
            else:
                return None
        return node.get('#',None)
    
    trie = {}
    for i,word in enumerate(words):
        insert(trie,word,i)
    
    res = []
    for i,word in enumerate(words):
        n = len(word)
        for j in xrange(n+1):
            left, right = word[:j], word[j:]
            releft, reright = left[::-1], right[::-1]
            if left == releft:
                k = find(trie,reright)
                if (k is not None) and k != i:
                    res.append([k,i])
            if j != n and right == reright:
                k = find(trie, releft)
                if (k is not None) and k != i:
                    res.append([i,k])
    return res
```

- 分析：空间O(n)，时间O(dn)


## 引用

[小白详解 Trie 树](https://segmentfault.com/a/1190000008877595)