---
title: 数据结构与算法：图（二）—— BFS
date: 2017-10-10 20:13:53
tags: 
    - 数据结构与算法
categories:
    - 数据结构与算法
---

广度优先搜索(Breadth-First-Search,BFS)：类似于二叉树的层序遍历，首先访问起始顶点v，接着依次访问v的所有未被访问的邻接点w1,w2,...，再依次访问w1,w2,...所有未被访问的邻接点...，直至所有顶点都已被访问。类似的思想还应用于Prime最小生成树算法和Dijkstra单源最短路径算法。

BFS能够发现图中关于源节点的“层次结构”，BFS算法只有在发现所有距离源节点s为k的所有节点之后，才会发现距离源节点s为k+1的其他节点。因此BFS常被用来求解多对多关系中的层次依赖问题，如单源最短距离、凸台积水等问题。

## 理论篇 
### BFS算法模板
为了深入理解BFS的搜索过程，我们通过一些辅助数据结构来追踪算法进展：

1. 顶点颜色：灰色是已发现和未发现的边界
    1. 白色顶点：未被发现的顶点
    2. 灰色顶点：顶点已被发现，但是顶点的邻接点尚未被完全发现
    3. 黑色顶点：顶点以及它所有的邻接点都已被发现
2. 顶点的父节点：记录每个顶点在当前搜索过程中的父亲节点，通过各个节点的父亲节点可以方便地构造出一棵广度优先生成树
3. 顶点的层数：各个顶点距离源顶点的距离，对于同一个源节点来说，每层节点的遍历顺序不同，对应的广度优先生成树可能不同，但是每个顶点到源节点的距离是唯一的

#### BFS标准模板
- 问题：按照广度优先的顺序依次遍历图中每个顶点，记录每个顶点的单源距离和父节点
- 思路：使用队列，循环父出子进，直至队列为空

```
1. 初始化辅助数据结构：
    1. 节点属性：如颜色、父亲、距离等，通常有三种方式存储节点属性
        1. 字典：key为标识节点的状态参数，value为对应属性，在顶点状态参数和属性间建立直接联系，通用、简单；
        2. 列表：列表下标用于标识节点，列表中的值代表对应节点的属性值，顶点通过属性列表的下标和顶点列表中的顶点参数建立映射关系；
        3. 定义顶点类：简单情形，字典可以起到同样效果
    2. 队列：将初始节点放入队列中，如有必要的数据需要在父子之间传递，也可随顶点一起入队，标记灰色
2. 循环出队入队，直至队列为空
    1. 获取出队顶点u
    2. 遍历出队顶点u的所有白色邻接点，入队，标记为灰色
    3. 将对对顶点u标记为黑色
```

- 代码：

```python
import collections
def bfs(G, V, s):
    """
    BFS逐个遍历，这里使用deque双端队列
    @G：以邻接表表示的图，{u:{v1,v2,...}}
    @V：图中所有顶点
    @s：广度优先遍历的出发点
    return：每个节点在广度优先树中的父节点，深度
    """
    # 初始化指标
    color = collections.defaultdict(int)
    father = collections.defaultdict(lambda: None)
    level = collections.defaultdict(int)
    
    # 广度优先遍历
    Q = collections.deque()
    Q.append((s,0))
    color[s] = 1
    while Q:
        u, d = Q.popleft()
        for v in G[u]:
            if not color[v]:
                color[v] = 1
                father[v] = u
                level[v] = d + 1
                Q.append((v, d+1))
        color[u] = 2
        
    return father,level
```

- 时间复杂度分析：邻接表O(V+E)，邻接矩阵 $O(V^2)$
    - 对队列的操作：因为每个节点只出队入队一次，所以队列操作的时间复杂度为O(V)
    - 搜索邻接点：每条边都会被遍历一次，如果使用邻接表，O(E)，如果使用邻接矩阵，$O(V^2)$
- 空间复杂度分析：使用了队列，最坏的情形下O(V)

#### 整层遍历
- 问题：有很多情形，需要对图中的节点进行整层处理：

```
    1. 求每层节点的统计量；
    2. 定制每层节点的访问顺序；
    3. 消除同层节点相互间的干扰；
```

- 思路：与标准写法类似，只是整层出整层入
- 代码：

```python
def bfs(G, V, s):
    """
    BFS逐个遍历
    @G：以邻接表表示的图，{u:{v1,v2,...}}
    @V：图中所有顶点
    @s：广度优先遍历的出发点
    return：每个节点在广度优先树中的父节点，深度
    """
    # 初始化指标
    color = collections.defaultdict(int)
    father = collections.defaultdict(lambda: None)
    level = collections.defaultdict(int)
    
    # 广度优先遍历
    Q = [(s,0)]
    color[s] = 1
    while Q:
        tmp = []
        for u,d in Q:
            for v in G[u]:
                if not color[v]:
                    color[v] = 1
                    father[v] = u
                    level[v] = d + 1
                    tmp.append((v,d+1))
        color[u] = 2
        Q = tmp
    return father,level
```

### BFS基本应用
#### 求广度优先生成树
- 问题：根据BFS搜索过程得到的各节点的父亲节点，计算对应的生成树
- 思路：父节点为None的顶点作为根节点，以邻接表形式表示树
- 代码：

```python
def get_tree(fathers):
    """
    @fathers：BFS算法所得到的所有节点的父节点
    @return：用字典表示的树{父节点:[孩子节点]}，根节点
    """
    T = {}
    root = None
    for child,father in fathers.items():
        T.setdefault(father,[]).append(child)
        if not father:
            root = father
    return T,root
```

#### 求单源最小距离
- 问题：求图中每个顶点到源节点的最小距离
- 思路：单源最小距离既是边的权值为1的单源最短路径，可以用类似于证明Dijkstra的方法来证明BFS得到的各节点的层数既是节点到源节点的最短距离。
- 代码：

```python
levels = bfs(G,s)[1]
```

#### 打印广度优先搜索树中的单源最小路径
- 问题：给定图中某个节点，打印源节点到该节点的最短路径
- 思路：根据BFS得到的节点的父节点关系，打印源节点s到任意节点v在广度优先搜索树中的最短路径
- 代码：

```python
def print_path(father, s, v):
    """
    打印s到v在广度优先生成树中的路径
    """
    res = []
    while v:
        res.append(v)
        v = father[v]
    return res[::-1]
```

#### 打印到指定节点所有的单源最短路径
- 问题：找到源节点s到给定节点v所有最短路径
- 思路：BFS+DFS。
    - BFS得到父节点字典：因为同层节点的不同搜索顺序会导致生成的广度优先搜索树也不同，源节点到给定节点的最短路径可能不止一条。我们需要在广度优先遍历时找到每个节点在上一层所有可能的父节点，困难在于，当我们u的未被访问的邻接点v时，只是找到了v的一个可能的父节点，在与u同层的后续节点中还可能存在v的父节点。如果上一层节点没有完全出队，那么下一层节点对上一层节点就应该是未访问的，同时在寻找上一层节点u的邻接点时，那些和u在同层或更早层的节点对于u来说应该是已访问的。解决办法是，通过逐层遍历，将新一层入队的元素标记为灰色，将旧的已入队的元素标记为黑色，灰色节点对于当前出队层节点是透明的，黑色节点对当前层出队层节点是不透明的。
    - DFS从父节点中找到s到v所有的最短路径
- 代码：

```python
def print_paths(G, V, s, v):
    """
    返回源节点s到目标节点v所有的最短路径
    """
    fathers = bfs(G, V, s)
    res = dfs(fathers, s, v, [], [])
    return res
    

def bfs(G, V, s):
    """
    返回所有可能的生成树中节点的父亲节点
    """
    color = {}
    fathers = {}
    for v in V:
        color[v] = 0
        fathers[v] = []
    
    Q = [s]
    color[s] = 2
    while Q:
        tmp = []
        for u in Q:
            for v in G[u]:
                if color[v] < 2:
                    fathers[v].append(u)
                if color[v] == 0:
                    tmp.append(v)
                    color[v] = 1
        for x in tmp:
            color[x] = 2
        Q = tmp
    return fathers


def dfs(fathers, s, v, cur, res):
    """
    @fathers:父节点字典
    @s：源节点
    @v：目标节点
    @cur：存储目标节点到当前v节点之前的路径
    @res：存储所有s到v的路径
    """
    if v == s:
        cur.append(v)
        res.append(cur[::-1])
    else:
        for father in fathers[v]:
            dfs(fathers, s, father, cur + [v], res)
    return res
```

具体实例详见[Leetcode126 单词接龙 II](https://leetcode-cn.com/problems/word-ladder-ii/description/)。

#### 寻找最近公共祖先

```python
class Solution(object):
    """
    LCA思路1： 递归，对任意子树，存在以下几种情形：
        1. 子树中含有p,q的LCA，返回LCA
        2. 子树中不含p,q的LCA，但是含p或q，返回p或q
        3. 子树中不含p或q，返回None
        子树和其左右子树存在递推关系，如果左子树含p或q，右子树也含p或q，则说明当前根节点就是LCA，否则如果左子树不含p或q，那么右子树返回的肯定就是LCA，反之亦然；
    思路2：BFS返回广度优先生成树，在树中找到从p和q到根节点的路径，路径上第一个重复节点就是p和q的LCA
    """
    def lowestCommonAncestor(self, root, p, q):
        """
        :type root: TreeNode
        :type p: TreeNode
        :type q: TreeNode
        :rtype: TreeNode
        """
        def bfs(root):
            Q = collections.deque()
            Q.append(root)
            father = {root:None}
            while Q:
                node = Q.pop()
                if node.left:
                    Q.append(node.left)
                    father[node.left] = node
                if node.right:
                    Q.append(node.right)
                    father[node.right] = node
        
            return father
        
        fathers = bfs(root)
        p_path = [p]
        q_path = [q]
        while p:
            p_path.append(fathers[p])
            p = fathers[p]
        while q:
            q_path.append(fathers[q])
            q = fathers[q]
        
        for x in p_path:
            for y in q_path:
                if x == y:
                    return x
```

## 实战篇
### 应用场景
BFS实际多用于求解“单源最短距离”和“层次依赖问题”：

1. 单源最短距离(无权)问题：
    1. 迷宫问题：走出迷宫最少步数，关键是定义好状态参数
    2. 单词接龙：一个单词到另一个单词的最短距离，关键是定义好相连关系
    3. 求树中到指定节点距离为k的所有节点：先将树转化为图
2. 层次依赖问题：
    1. 凸台积水问题：从边界向内更新水位

### 定制化 BFS
BFS用于解决实际问题的一般步骤：

```
1. 定义图的数据结构：从实际问题中抽象出相互联系的可区分的状态
    1. 定义顶点：顶点就是我们需要搜索的不同状态，不同顶点可以用一组参数唯一标识，注意唯一性往往是定义状态的重要依据；
    2. 定义边：找到遍历顶点的邻接点的方式，即构建邻接表adj(u);
2. 设计BFS算法：
    1. 队列：队列提供了父子节点数据交流的通道，可将父子需要交流的数据一同入队Q=deque();
    2. 访问记录：BFS每种状态最多被访问一次，用标识顶点的参数来记录哪些状态已被访问visited=set();
    3. 迭代过程：
        1. 初始时将标识源节点的参数以及父子关联数据一同入队，将标识源节点的状态参数添加到已访问集合
        2. 循环出队，将出队顶点的未访问的邻接点入队，并标记为已访问，直至队列为空；
3. 根据BFS得到的有用信息求解原问题的解
```

解决好BFS问题的核心在于定义好合适的状态，唯一性是定义状态的重要依据！！！最典型的代表参见“迷宫找钥匙”。

### LeetCode典型题目
#### [LeetCode 863. 二叉树中所有距离为 K 的结点]
- 问题:给定一个二叉树（具有根结点 root）， 一个目标结点 target ，和一个整数值 K 。返回到目标结点 target 距离为 K 的所有结点的值的列表。 答案可以以任何顺序返回。输入：`root = [3,5,1,6,2,0,8,null,null,7,4],target = 5, K = 2`，输出：`[7,4,1]`

<div align=center>
    <img src="https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/13-17-41.jpg" width="40%" heigh="40%"></img>
</div>

- 思路：先将树转化为无向图，再通过BFS求出第K层的所有顶点

```
1. 构建图的数据结构：首先遍历整棵树，构建图的数据结构
    1. 顶点：用原始顶点中的值作为顶点
    2. 边：具有父子关系的顶点是邻接点
2. BFS：从target出发寻找距离为K的所有顶点
```

- 代码:

```python
def distanceK(self, root, target, K):
    """
    :type root: TreeNode
    :type target: TreeNode
    :type K: int
    :rtype: List[int]
    """
    adj = collections.defaultdict(list)
    
    def dfs(root):
        """将树转化为图的数据结构"""
        if root.left:
            adj[root.val].append(root.left.val)
            adj[root.left.val].append(root.val)
            dfs(root.left)
        if root.right:
            adj[root.val].append(root.right.val)
            adj[root.right.val].append(root.val)
            dfs(root.right)
    
    dfs(root)
    level = 0
    visited = set([target.val])
    Q = [target.val]
    while Q:
        if level == K:
            return Q
        tmp = []
        for u in Q:
            for v in adj[u]:
                if v not in visited:
                    tmp.append(v)
                    visited.add(v)
        level += 1
        Q = tmp
    return []
```


#### [LeetCode 126. 单词接龙 II]
- 问题：给定两个单词（beginWord 和 endWord）和一个字典 wordList，找出所有从 beginWord 到 endWord 的最短转换序列。转换需遵循如下规则：每次转换只能改变一个字母。转换过程中的中间单词必须是字典中的单词。

```
输入:
beginWord = "hit",
endWord = "cog",
wordList = ["hot","dot","dog","lot","log","cog"]

输出:
[
  ["hit","hot","dot","dog","cog"],
  ["hit","hot","lot","log","cog"]
]
```
- 思路：BFS+DFS
    - 数据结构：每个单词作为一个节点，单词间相差一个字母代表单词间有边；众多单词中判断单词间是否有边，普通方法需要遍历两次，时间复杂度为O(n2)，如果将每个单词的每个字母用_掩码代替，如果代替后掩码相同说明两个单词有边，只需用一个字典维护掩码:[单词]的映射，寻找一个单词的邻接点时，该单词的所有掩码对应的单词都是它的邻接点；考虑单词长度不大，构建数据结构只需要O(n)的时间复杂度；
    - BFS算法：通过BFS可以找到每个节点在上一层中的所有父节点，技巧在于将之前层的节点标位黑色，将当前层已发现的节点标记为灰色，将未访问节点标记为白色，在统计父节点的孩子时，遍历其邻接点中非黑节点，将邻接点中白色节点入队标灰，最后得到父节点字典
    - DFS算法：
- 代码：从结束单词除法，向上遍历其所有可能的父节点，如果遇到初始节点则说明找到一组解，进行收集，返回最后收集到的所有最短路径

```python
from collections import deque
from collections import defaultdict
class Solution(object):
    def findLadders(self, beginWord, endWord, wordList):
        """
        :type beginWord: str
        :type endWord: str
        :type wordList: List[str]
        :rtype: List[List[str]]
        """
        # 图的数据结构：单词-掩码-邻接单词
        adj = defaultdict(list)
        for word in wordList:
            for i,c in enumerate(word):
                mask = word[:i] + '_' + word[i+1:]
                adj[mask].append(word)
        
        # 求解
        self.res = []
        self.fathers = self.bfs(beginWord, endWord, adj)
        self.dfs(beginWord, endWord, [])
        return self.res
        
    def bfs(self, beginWord, endWord, adj):
        # 存放节点的父节点
        fathers = defaultdict(set)
        # 广度遍历，color=0表示未访问，color=1表示当前层已访问，color=2表示在之前层已访问
        color = defaultdict(int)
        Q = [beginWord]
        color[beginWord] = 2
        ok = True
        while ok and Q:
            next_Q = []
            for pre_w in Q:
                for j,c in enumerate(pre_w):
                    mask = pre_w[:j] + '_' + pre_w[j+1:]
                    for w in adj[mask]:
                        if color[w] < 2:
                            fathers[w].add(pre_w)
                        if not color[w]:
                            if w == endWord:
                                ok = False
                            else:
                                next_Q.append(w)
                                color[w] = 1
            Q = []
            for q in next_Q:
                Q.append(q)
                color[q] = 2
        return fathers
        
        
        # 存放最终结果
    def dfs(self, beginWord, endWord, cur):
        if endWord == beginWord:
            cur.append(endWord)
            self.res.append(cur[::-1])
            return 
        for father in self.fathers[endWord]:
            self.dfs(beginWord, father, cur + [endWord])
```

#### [LeetCode 407. 平台接雨水 II]
- 问题:给定一个m x n的矩阵，其中的值均为正整数，代表二维高度图每个单元的高度，请计算图中形状最多能接多少体积的雨水
- 思路：BFS确定平台水面最大深度
    - 数据结构：平台位置作为一个顶点，位置相邻说明有边
    - BFS：
        -  边界最大水深即为边界平台高度，加入队列
        - 出队一个平台i，更新邻接点j水面深度，如果更新成功则将邻接点入队，更新规则：limit=max(heightMap[j],h[i]),h[j] > limit
        - 统计最终平台水面高度-平台高度之和
- 代码：每个节点最多被更新四次，故时间复杂度为O(m*n)

```python
def trapRainWater(self, heightMap):
    """
    :type heightMap: List[List[int]]
    :rtype: int
    """
    if not any(heightMap):
        return 0
    else:
        m,n = len(heightMap),len(heightMap[0])
    inf = float('inf')
    h = [[inf] * n for _ in xrange(m)]
    Q = collections.deque()
    for i in xrange(m):
        for j in xrange(n):
            if i == 0 or i == m-1 or j == 0 or j == n-1:
                h[i][j] = heightMap[i][j]
                Q.append((i,j))
    
    while Q:
        x,y = Q.popleft()
        for dx,dy in [(0,-1),(0,1),(-1,0),(1,0)]:
            if 0 < x+dx < m and 0 < y+dy < n:
                limit = max(heightMap[x+dx][y+dy], h[x][y])
                if h[x+dx][y+dy] > limit:
                    h[x+dx][y+dy] = limit
                    Q.append((x+dx,y+dy))
    
    return sum(h[i][j] - heightMap[i][j] for i in xrange(m) for j in xrange(n))
```

以上方法对于一维平台接雨水同样适用，参见[42. 接雨水](https://leetcode-cn.com/problems/trapping-rain-water/description/)。

#### [LeetCode 864. 获取所有钥匙的最短路径]
- 问题：给定一个二维网格 grid。 "." 代表一个空房间， "#" 代表一堵墙， "@" 是起点，（"a", "b", ...）代表钥匙，（"A", "B", ...）代表锁。我们从起点开始出发，一次移动是指向四个基本方向之一行走一个单位空间。我们不能在网格外面行走，也无法穿过一堵墙。如果途经一个钥匙，我们就把它捡起来。除非我们手里有对应的钥匙，否则无法通过锁。假设 K 为钥匙/锁的个数，且满足 1 <= K <= 6，字母表中的前 K 个字母在网格中都有自己对应的一个小写和一个大写字母。换言之，每个锁有唯一对应的钥匙，每个钥匙也有唯一对应的锁。另外，代表钥匙和锁的字母互为大小写并按字母顺序排列。返回获取所有钥匙所需要的移动的最少次数。如果无法获取所有钥匙，返回 -1 。
- 示例:

```
输入：[ "@ . a . #",
       "# # # . #",
       "b . A . B"]
输出：8
```
- 思路：BFS

```
思路：单源最短距离问题，找到所有钥匙返回到源节点的距离
        1. 构建图的数据结构：
            1. 定义顶点：将(位置,持有的钥匙集)作为顶点
            2. 定义边：位置相邻且不为墙，说明两个节点为邻接点
        2. BFS算法：从源节点开始进行广度优先遍历，标记已访问节点，遇到非墙邻接点
            1. 如果是.或@入队(新位置，钥匙集)
            2. 如果是小写字母，检查加入该钥匙是否完成收集，是则返回当前距离，否则继续入队(新位置，新钥匙集)
            3. 如果是大写字母，检查钥匙集中是否有对应钥匙，有则开门入队，无则不是邻接点不用处理
```
- 代码:

```python
def shortestPathAllKeys(self, grid):
    """
    :type grid: List[str]
    :rtype: int
    """
    m,n = len(grid),len(grid[0])
    # 邻接点函数
    def adj(i,j):
        for x,y in [(i,j-1),(i,j+1),(i-1,j),(i+1,j)]:
            if 0 <= x < m and 0 <= y < n:
                yield x,y
    # 寻找起点和钥匙总数
    n_keys = 0
    start = None
    for i in xrange(m):
        for j in xrange(n):
            if grid[i][j] == '@':
                start = [i,j]
            elif 'a' <= grid[i][j] <= 'z':
                n_keys += 1
    # BFS
    Q = collections.deque()
    Q.append([start[0],start[1],0,set()])
    visited = set([(start[0],start[1],frozenset())])
    while Q:
        i,j,d,keys = Q.popleft()
        for x,y in adj(i,j):
            if grid[x][y] != '#' and (x,y,frozenset(keys)) not in visited:
                visited.add((x,y,frozenset(keys)))
                if 'a' <= grid[x][y] <= 'z':
                    new_keys = keys | {grid[x][y]}
                    if len(new_keys) == n_keys:
                        return d + 1
                    Q.append([x,y,d+1,new_keys])
                elif 'A' <= grid[x][y] <= 'Z':
                    if grid[x][y].lower() in keys:
                        Q.append([x,y,d+1,keys])
                else:
                    Q.append([x,y,d+1,keys])
                    
    return -1
```

- 反思：复杂问题没什么可怕的，只要抽象出合适的数据结构，就会发现还是常规问题！本题的核心在于使用位置和钥匙集来标识一个状态

#### [LeetCode 815. 公交路线]
- 问题：

```
我们有一系列公交路线。每一条路线 routes[i] 上都有一辆公交车在上面循环行驶。例如，有一条路线 routes[0] = [1, 5, 7]，表示第一辆 (下标为0) 公交车会一直按照 1->5->7->1->5->7->1->... 的车站路线行驶。

假设我们从 S 车站开始（初始时不在公交车上），要去往 T 站。 期间仅可乘坐公交车，求出最少乘坐的公交车数量。返回 -1 表示不可能到达终点车站。

示例:
输入: 
routes = [[1, 2, 7], [3, 6, 7]]
S = 1
T = 6
输出: 2
解释: 
最优策略是先乘坐第一辆公交车到达车站 7, 然后换乘第二辆公交车到车站 6。
```
- 思路：

```
    思路：仍然是单源最短距离问题，BFS求解
    1. 数据结构：
        1. 顶点：每辆公交作为一个顶点，可用下标唯一标识
        2. 边：如果一个公交路线与该公交路线交集不为空，则说明两辆公交之间有边
    2. BFS：
        1. 队列，压入公交下标和距离
        2. 已访问：下标标识
        3. 迭代：
            1. 初始时不在车上，找到含初始栈的公交，距离为1，入队，标记已访问，
            2. 出队时判断目的地在不在该公交上，如果在直接返回当前距离
            3. 如果不在，继续遍历邻接点，存入队列标记已访问
```

- 代码：

```python
def numBusesToDestination(self, routes, S, T):
    """
    :type routes: List[List[int]]
    :type S: int
    :type T: int
    :rtype: int
    """
    # 先将站转化为字典，加速查询
    routes = [set(rout) for rout in routes]
    n = len(routes)
    
    # 按照站将公交分组，公交A有a站->有a站的所有公交都是A的邻接点，类似于成单词接龙
    adj = collections.defaultdict(list)
    for i in xrange(n):
        for c in routes[i]:
            adj[c].append(i)
    
    # 如果S或T不在adj中，返回-1
    if S == T:
        return 0
    elif S not in adj or T not in adj:
        return -1
    
        
    # BFS搜索
    Q = collections.deque()
    visited = set()
    for x in adj[S]:
        Q.append([x,1])
        visited.add(x)
    
    while Q:
        j, d = Q.popleft()
        if T in routes[j]:
            return d
        for x in routes[j]:
            for v in adj[x]:
                if v not in visited:
                    visited.add(v)
                    Q.append((v,d+1))
    return -1
```

#### [LeetCode 847. 访问所有节点的最短路径]
- 问题：

```
给出 graph 为有 N 个节点（编号为 0, 1, 2, ..., N-1）的无向连通图。 
graph.length = N，且只有节点 i 和 j 连通时，j != i 在列表 graph[i] 中恰好出现一次。
返回能够访问所有节点的最短路径的长度。你可以在任一节点开始和停止，也可以多次重访节点，并且可以重用边

输入：[[1,2,3],[0],[0],[0]]
输出：4
解释：一个可能的路径为 [1,0,2,0,3]
```

- 思路：

```
最短距离问题：BFS
1. 数据结构：
    1. 顶点：不可以重复访问的状态是(顶点,已访问顶点集)
    2. 边：图中的邻接点
2. BFS:
```

- 代码：

```python
def shortestPathLength(self, graph):
    """
    :type graph: List[List[int]]
    :rtype: int
    """
    n = len(graph)
    
    res = float('inf')
    Q = collections.deque()
    visited = set()
    for i in xrange(n):
        Q.append([i, 0, {i}])
        visited.add((i,frozenset({i})))
    while Q:
        j,d,path = Q.popleft()
        if len(path) == n:
            res = min(res,d)
        elif d < res:
            for x in graph[j]:
                tmp = path | {x}
                if (x,frozenset(tmp)) not in visited:
                    Q.append([x, d + 1, tmp])
                    visited.add((x,frozenset(tmp)))
    return res
```

#### [LeetCode 854. 相似度为 K 的字符串]
- 问题:如果可以通过将 A 中的两个小写字母精确地交换位置 K 次得到与 B 相等的字符串，我们称字符串 A 和 B 的相似度为 K（K 为非负整数）。给定两个字母异位词 A 和 B ，返回 A 和 B 的相似度 K 的最小值。

```
输入：A = "abc", B = "bca"
输出：2

输入：A = "abac", B = "baca"
输出：2

1 <= A.length == B.length <= 20
A 和 B 只包含集合 {'a', 'b', 'c', 'd', 'e', 'f'} 中的小写字母。
```

- 思路：

```
思路1：最短距离问题，考虑BFS，超时
    1. 构建数据结构：
        1. 定义顶点：单词
        2. 定义边：任意两个不同位置的不同元素交换
    2. BFS算法：找最短路径
思路2：记忆化搜索DFS找到所有可能的解，然后求最优解936ms
    1. AB中相同的部分可以排除，只对不同的位置进行交换
    2. 如果AB首部位置不同，在该位置至少要进行一次交换，遍历后续合法交换位置，问题就转化为了A[1:]和B[1:]的交换了
思路3：借鉴2的思路，重回BFS
    1. 构建数据结构：
        1. 定义顶点：(A,B)作为状态
        2. 定义边：寻找AB第一个不同元素A[i],B[i]，在A[i]的后续元素中找到一个等于B[i]的元素与A[i]交换，得到(A[i+1:],B[i+1:])作为A的邻接点
    2. BFS算法：
        1. 初始(A,B,0)入队，标记已访问
        2. 循环出队，依次将未访问过的邻接点入队，标记已访问，直至找不到不相同的元素(A==B)，返回d
```

- 代码：

```python
def kSimilarity(self, A, B):
    """
    :type A: str
    :type B: str
    :rtype: int
    """
    if A == B:
        return 0
    Q = collections.deque()
    visited = set()
    
    Q.append((A,B,0))
    visited.add((A,B))
    while Q:
        a,b,d = Q.popleft()
        w = -1
        for i,c in enumerate(a):
            if w == -1 and a[i] != b[i]:
                w = i
            elif w != -1 and a[i] == b[w]:
                cur_a = a[w+1:i] + a[w] + a[i+1:]
                cur_b = b[w+1:]
                pair = (cur_a,cur_b,d+1)
                if (cur_a,cur_b) not in visited:
                    Q.append(pair)
                    visited.add((cur_a,cur_b))
        if w == -1:
            return d
```

#### [LeetCode 199. 二叉树的右视图]
- 问题：给定一棵二叉树，想象自己站在它的右侧，按照从顶部到底部的顺序，返回从右侧所能看到的节点值。

```
输入: [1,2,3,null,5,null,4]
输出: [1, 3, 4]
解释:

   1            <---
 /   \
2     3         <---
 \     \
  5     4       <---
```

- 思路：整行BFS，每行返回最后一个节点值

- 代码：

```python
def rightSideView(self, root):
    """
    :type root: TreeNode
    :rtype: List[int]
    """
    res = []
    if root:
        Q = [root]
        while Q:
            res.append(Q[-1].val)
            Q = [child for node in Q for child in [node.left,node.right] if child]
    return res
```

#### [LeetCode 279. 完全平方数]
- 问题：给定正整数 n，找到若干个完全平方数（比如 1, 4, 9, 16, ...）使得它们的和等于 n。你需要让组成和的完全平方数的个数最少。如：12= 4 + 4 + 4。
- 思路：实质也是单源最短路径问题，最坏时间复杂度O(dn)

```
1. 数据结构：
    1. 顶点：当前累加的平方数和作为顶点
    2. 边：累加平方数和与下一次<=n的累加平方数和为邻接点
2. BFS：
    1. 队列：存放当前累加和和当前距离
    2. 已访问：存放累加和，已访问的累加和就不用再访问
```
- 代码:

```python
def numSquares(self, n):
    """
    :type n: int
    :rtype: int
    """
    srt = int(n**0.5)
    if srt * srt == n:
        return 1
    
    Q = collections.deque()
    visited = set()
    for i in xrange(1,srt+1):
        Q.append((i*i,1))
        visited.add(i*i)
    while Q:
        q,d = Q.popleft()
        for j in xrange(1,srt+1):
            tmp = q + j * j
            if tmp not in visited:
                visited.add(tmp)
                if tmp == n:
                    return d + 1
                elif tmp < n:
                    Q.append((tmp,d+1))
```

- 另一种思路：本体最快的解法是利用数论中的四数平方和定理与三数平方和定理

```
思路2：
    四数平方和定理：任何自然数都可以用最多四个平方和数之和表示，
    三数平方和定理：只有当n=4^a*(8b+7)时才需要用四个平方和树之和表示
        1. 如果n==int(n**0.5) ** 2，返回1
        2. 如果n可以被分解为任意两个数的平方和之和，返回2
        3. 如果n==4^a*(8b+7)，返回4
        4. 否则返回3
```

- 代码：

```python
def numSquares(self, n):
    """
    :type n: int
    :rtype: int
    """
    while n & 3 == 0:
        n >>= 2
    if n & 7 == 7:
        return 4
    for a in xrange(int(n**0.5)+1):
        b = int((n - a * a)**0.5)
        if a * a + b * b == n:
            return (a != 0) + (b!=0)
    return 3
```