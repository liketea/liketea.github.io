---
title: Git简明教程
tags:
  - 教程
categories:
  - 工具
date: 2019-09-14 14:49:38
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1_9qX9F9MGsWKfcmgTOR9BPw.png)

## Git 配置
Git 诞生于2005年，是一种分布式版本控制系统（Distributed Version Control System，简称 DVCS），客户端并不只提取最新版本的文件快照，而是把代码仓库完整地镜像下来，任何一处协同工作用的服务器发生故障，事后都可以用任何一个镜像出来的本地仓库恢复。

Mac 安装 Xcode Command Line Tools 时会自带 git，也可以通过 homebrew 来安装：

```
$ brew install git
# 查看版本
$ git version
git version 2.20.1 (Apple Git-117)
# 查看帮助
$ git help
```

检查配置信息：

```
$ git config --list
```

配置账号邮箱：

```
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```

## 本地仓库

### 创建本地仓库
有两种方法来获取Git仓库：

```
# 将现有目录初始化为仓库
$ cd <folder>
$ git init

# 从仓库url克隆现有仓库，自定义仓库名称为new_repo_name
$ cd <folder>
$ git clone [url] [new_repo_name]
```

如果要删除本地仓库，只需要删除仓库下的 `.git` 目录即可将git仓库转化为普通目录：

```
$ rm -rf .git
```

### 本地仓库的状态
查看当前分支文件的状态：

```
$ git status
On branch master
nothing to commit, working directory clean
```

Git 的三种区域/文件：

1. 仓库区：用来保存项目元数据和对象数据库的地方；
2. 缓存区：保存了下次将要提交的文件列表信息的文件；
3. 工作区：从git仓库中取出放在磁盘上用于使用或修改的文件；

文件的四类状态：

1. 已跟踪/未跟踪：根据文件是否被纳入了版本控制来分(从第一次add开始跟踪到最后一次rm结束跟踪)；
2. 已修改/未修改：自上次提交之后是否做了修改；
3. 已缓存/未缓存：修改后是否添加到了缓存；
4. 已提交/未提交：添加到了缓存之后是否提交到仓库；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190914150727.png)

### 添加文件至缓存
#### 添加文件
`git add <file>`：将工作区的指定内容添加到下一次的提交列表(缓存区)，在不同条件下add有三种功能

1. 如果是未被跟踪的文件：开始跟踪新文件并将其添加到缓存区；
2. 如果是已跟踪的文件：将已跟踪文件放到缓存区；
3. 如果是合并时有冲突的文件：将有冲突的文件标记为已解决状态；

示例：

```
# 将file添加到下次提交的列表中(缓存区)
$ git add file
# 将多个文件加入缓存区
$ git add readme.txt ant.txt

# 将.c文件加入缓存区
$ git add *.c

# 将当前目录下所有未跟踪或修改的文件放入缓存区
$ git add .
$ git add *
# 将整个工作区下所有未跟踪或修改的文件放入缓存区
$ git add -A
```

#### 忽略文件
可以通过创建一个名为`.gitignore`的文件，列出 add 命令要忽略的文件格式，格式规范如下

1. 所有已空行或以#开头的行会被忽略
2. 可以使用标准的glob模式匹配（shell所使用的简化了的正则表达式）
    1. `*`匹配零或多个任意字符
    2. `[abc]`匹配任何一个列在方括号中的字符
    3. `?`匹配一个任意字符
    4. `**` 表示匹配任意中间目录
3. 匹配模式可以以（/）开头防止递归
4. 匹配模式可以以（/）结尾指定目录
5. 要忽略指定模式以外的文件或目录，可以在模式前加上惊叹号（!）取反


```
# 忽略.a后缀类型的文件
*.a
# 不忽略lib.a，即使上面忽略了.a类型的文件
!lib.a 
# 忽略当前目录下的TODO文件
/TODO
# 忽略build目录下的所有文件
build/
# 忽略doc目录下的所有pdf文件
doc/**/*.pdf
```

需要注意的是`.gitignore`的文件只对那些尚未被跟踪的文件有用，而对已经被跟踪的文件无效，所以要养成一开始就设置好`.gitignore`文件的习惯，以免将来误提交这类无用的文件。即使这样，有事在项目开发过程中，突然心血来潮想把某些目录加入到忽略规则，只修改`.gitignore`文件是不行的，还要把本地缓存删除，然后再重新添加：

```
$ git rm -r --cached .
$ git add .
$ git commit -m "update .gitignore"
```

#### 对比文件
查看已修改但未暂存的变化：`git diff` 用于比较当前工作区与缓存区的差异，打印那些在工作区做出了修改但尚未添加到缓存区的内容

```
$ git diff
diff --git a/CONTRIBUTING.md b/CONTRIBUTING.md
index 8ebb991..643e24f 100644
--- a/CONTRIBUTING.md
+++ b/CONTRIBUTING.md
```

查看已缓存但未提交的变化：`git diff --staged` 用于比较当前缓存区和仓库的差异，打印那些已添加到缓存区但尚未提交到仓库的内容

```
$ git diff --staged
```

#### 取消暂存

`git restore --staged <file>`：取消对文件file的暂存

```
$ git restore --staged text.txt
位于分支 demo
您的分支领先 'origin/files' 共 1 个提交。
  （使用 "git push" 来发布您的本地提交）

尚未暂存以备提交的变更：
  （使用 "git add <文件>..." 更新要提交的内容）
  （使用 "git restore <文件>..." 丢弃工作区的改动）
	修改：     text.txt
```

#### 取消修改
`git checkout -- <file>`：自上次提交后对文件进行了修改但还没有添加到缓存，则可以通过该命令取消对文件file的修改，也就是用上次提交时的文件覆盖工作区中的文件；

```
$ git checkout -- CONTRIBUTING.md
$ git status
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

    renamed:    README.md -> README
```

#### 移除文件
需要从已跟踪文件清单中移除该文件，然后提交，`git rm` 可以完成此项工作并连带从工作目录中删除指定的文件

```
# 使用git rm移除文件
$ git rm PROJECTS.md
# 如果该文件新的修改已缓存但尚未提交，则必须进行强制删除
$ git rm -f PROJECTS.md
# 也可以手动删除后提交
$ rm PROJECTS.md
$ git commit -a -m "delete file"
```

### 提交文件至仓库
#### 提交文件

`git commit -m ""`：将已缓存的文件提交至仓库

示例：

```
# 会启动shell 的环境变量 $EDITOR 所指定的文本编辑器以便输入本次提交的说明
$ git commit 

# 将提交信息与命令放在同一行
$ git commit -m "***"

# 跳过使用暂存区域，提交之前不再需要 git add 文件
$ git commit -a -m 'added new benchmarks'
```

#### 查看提交历史
`git log`：按提交时间列出所有的更新，最近的更新排在最上面；

```
$ git log
# SHA-1 校验和
commit ca82a6dff817ec66f44342007202690a93763949
# 作者
Author: Scott Chacon <schacon@gee-mail.com>
# 提交时间
Date:   Mon Mar 17 21:52:11 2008 -0700
# 提交说明
    changed the version number

commit 085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Sat Mar 15 16:40:33 2008 -0700

    removed unnecessary test

commit a11bef06a3f659402fe7563abf99ad00de2209e6
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Sat Mar 15 10:31:28 2008 -0700

    first commit
```

如果要显示每次提交的内容差异，可以加上选项-p：

```
# -2 表示仅显示最近两次提交
$ git log -p -2
commit ca82a6dff817ec66f44342007202690a93763949
Author: Scott Chacon <schacon@gee-mail.com>
Date:   Mon Mar 17 21:52:11 2008 -0700

    changed the version number

diff --git a/Rakefile b/Rakefile
index a874b73..8f94139 100644
--- a/Rakefile
+++ b/Rakefile
@@ -5,7 +5,7 @@ require 'rake/gempackagetask'
 spec = Gem::Specification.new do |s|
     s.platform  =   Gem::Platform::RUBY
     s.name      =   "simplegit"
-    s.version   =   "0.1.0"
+    s.version   =   "0.1.1"
     s.author    =   "Scott Chacon"
     s.email     =   "schacon@gee-mail.com"
     s.summary   =   "A simple gem for using Git in Ruby code."

```

每行显示一次提交：`--pretty=oneline`

```
$ git log --pretty=oneline
ca82a6dff817ec66f44342007202690a93763949 changed the version number
085bb3bcb608e1e8451d4b2432f8ecbe6306e7e7 removed unnecessary test
a11bef06a3f659402fe7563abf99ad00de2209e6 first commit
```

展示分支合并历史：`--graph`

```
$ git log --pretty=format:"%h %s" --graph
* 2d3acf9 ignore errors from SIGCHLD on trap
*  5e3ee11 Merge branch 'master' of git://github.com/dustin/grit
|\
| * 420eac9 Added a method for getting the current branch.
* | 30e367c timeout code and tests
* | 5a09431 add timeout protection to grit
* | e1193f8 support for heads with slashes in them
|/
* d6016bc require time for xmlschema
*  11d191e Merge branch 'defunkt' into local
```

### 分支管理
Git 中的分支可以看做是由仓库快照组成的反向链表，每个分支名就是指向对应分支的头指针(HEAD是指向当前分支头指针的指针)，在该分支中的每次提交都会在对应链表头部插入一个快照节点，并将分支的头指针向前移动。

![](https://git-scm.com/book/en/v2/images/branch-and-history.png)

查看分支：

```
# 查看本地分支，*标识的是当前分支
$ git branch 
  iss53
* master
  testing
# 查看所有分支
$ git branch -a
# 查看远程分支
$ git branch -r

# 查看每一个分支的最后一次提交
$ git branch -v
# 查看已经合并或尚未合并到当前分支的分支
$ git branch --merged
$ git branch --no-merged
```

#### 分支创建

`git branch <branch_name>`：创建一个名为branch_name的新分支，这会在当前所在的提交队形上创建一个指针

```
$ git branch testing
```

![](https://git-scm.com/book/en/v2/images/head-to-master.png)

#### 分支切换
`git checkout <branch_name>`：切换到一个已存在的分支，之后对文件的修改、添加、提交都在在新的分支上进行的；

```
$ git branch testing
```

![](https://git-scm.com/book/en/v2/images/head-to-testing.png)

#### 分支合并
`git merge <branch_name>`：将另一个分支合并到当前分支上来，根据当前主分支（当前分支）和副分支（被合并的分支）头指针间的关系，有四种情形：

- 副分支是主分支的直接上游：不会发生任何变化

![](https://git-scm.com/book/en/v2/images/basic-branching-3.png)

```
$ branch checkout issue53
$ branch merge master
```

![](https://git-scm.com/book/en/v2/images/basic-branching-3.png)

- 主分支是副分支的直接上游：将主分支快进(fast-ward)到副分支的位置

![](https://git-scm.com/book/en/v2/images/basic-branching-4.png)

```
$ branch checkout master
$ branch merge issue53
```

![](https://git-scm.com/book/en/v2/images/basic-branching-5.png)

- 主分支和副分支分叉不冲突：Git 会使用两个分支的末端所指的快照（C4 和 C5）以及这两个分支的工作祖先（C2），做一个简单的三方合并，并自动创建一个新的提交指向它，这称作一次合并提交

![](https://git-scm.com/book/en/v2/images/basic-merging-1.png)

```
$ git checkout master
Switched to branch 'master'
$ git merge iss53
Merge made by the 'recursive' strategy.
index.html |    1 +
1 file changed, 1 insertion(+)
```

![](https://git-scm.com/book/en/v2/images/basic-merging-2.png)

- 主分支和副分支分叉冲突：如果你在两个不同的分支中，对同一个文件的同一个部分进行了不同的修改，此时Git做了合并但不会自动创建一个新的提交，需要等到你手动解决了冲突之后再进行手动提交

```
# 冲突合并
$ git merge iss53
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.

# 包含冲突待解决的文件都会以未合并状态标识出来，Git 会在有冲突的文件中加入标准的冲突解决标记，这样你可以打开这些包含冲突的文件然后手动解决冲突，<<<后面和>>>>后面表示发生冲突的两个分支文件，======上下是发生冲突的内容
<<<<<<< HEAD:index.html
<div id="footer">contact : email.support@github.com</div>
=======
<div id="footer">
 please contact us at support@github.com
</div>
>>>>>>> iss53:index.html

# 冲突解决后的样子
<div id="footer">
please contact us at email.support@github.com
</div>

# 如果你对结果感到满意，并且确定之前有冲突的的文件都已经暂存了，这时你可以输入 git commit 来完成合并提交
$ git add *
$ git commit -m "解决冲突"
```

#### 删除分支


```
$ git branch -d hotfix
Deleted branch hotfix (3a0874c).
```

#### 分支策略

常见的利用分支进行开发的工作流程：

- 渐进稳定分支（长期分支）：只在 master 分支上保留完全稳定的代码，还有一些名为 develop 或者 next 的平行分支，被用来做后续开发或者测试稳定性——这些分支不必保持绝对稳定，但是一旦达到稳定状态，它们就可以被合并入 master 分支了，本博客采用的也是一种长期分支策略，用master分支存放静态网页，用files分支存放网站原始文件；

![](https://git-scm.com/book/en/v2/images/lr-branches-2.png)

- 特性分支（短期分支）：特性分支被用来实现单一特性或其相关工作，考虑这样一个例子，你在 master 分支上工作到 C1，这时为了解决一个问题而新建 iss91 分支，在 iss91 分支上工作到 C4，然而对于那个问题你又有了新的想法，于是你再新建一个 iss91v2 分支试图用另一种方法解决那个问题，接着你回到 master 分支工作了一会儿，你又冒出了一个不太确定的想法，你便在 C10 的时候新建一个 dumbidea 分支，并在上面做些实验。 你的提交历史看起来像下面这个样子：

![](https://git-scm.com/book/en/v2/images/topic-branches-1.png)

## 远程仓库
远程仓库是指托管在因特网或其他网络中的你的项目的版本库，与他人协作涉及管理远程仓库以及根据需要推送或拉取数据。

### 查看远程仓库
查看你已经配置的远程仓库服务器，可以运行 git remote 命令，克隆的仓库默认将origin作为远程仓库的名字：

```
$ git remote
origin

# 可以指定选项 -v，会显示需要读写远程仓库使用的 Git 保存的简写与其对应的 URL
$ git remote -v
origin	https://github.com/schacon/ticgit (fetch)
origin	https://github.com/schacon/ticgit (push)

# 查看某个远程仓库更多信息
➜ .git git:(files) git remote show origin
* 远程 origin
  获取地址：git@github.com:liketea/liketea.github.io.git
  推送地址：git@github.com:liketea/liketea.github.io.git
  HEAD 分支：files
  远程分支：
    demo   已跟踪
    files  已跟踪
    master 已跟踪
    ss     已跟踪
    tt     已跟踪
    ttt    已跟踪
    xx     已跟踪
    xxx    已跟踪
  为 'git pull' 配置的本地分支：
    demo  与远程 files 合并
    files 与远程 files 合并
    tt    与远程 demo 合并
  为 'git push' 配置的本地引用：
    demo  推送至 demo  (本地已过时)
    files 推送至 files (最新)
    ss    推送至 ss    (最新)
    tt    推送至 tt    (可快进)py
```

### 添加远程仓库
`git remote add <shortname> <url>`： 添加一个新的远程 Git 仓库，同时指定一个你可以轻松引用的简写

```
$ git remote
origin
$ git remote add pb https://github.com/paulboone/ticgit
$ git remote -v
origin	https://github.com/schacon/ticgit (fetch)
origin	https://github.com/schacon/ticgit (push)
pb	https://github.com/paulboone/ticgit (fetch)
pb	https://github.com/paulboone/ticgit (push)
```

### 修改远程仓库
有三种方法来修改远程仓库：

- 直接修改本地仓库下的.git/config文件:

```
url = http://xxx.com/Name/project.git
改为
url = git@xxx.com/Name/project.git
```

- 修改命令:

```
git remote set-url origin [url]
例如：git remote set-url origin gitlab@gitlab.chumob.com:php/hasoffer.git
```

- 先删后加

```
git remote rm origin
git remote add origin [url]
```

### 配置SSH 公钥
许多 Git 服务器都使用 SSH 公钥进行认证，需要在本地生成SSH 公钥，然后将公钥发送给 Git 服务器管理员（配置到github中）。

- 生成SSH 公钥

```
# 默认情况下，用户的 SSH 密钥存储在其 ~/.ssh 目录下
$ cd ~/.ssh
# .pub 文件是你的公钥，另一个则是私钥
$ ls
id_dsa    id_dsa.pub
# 如果没有则需要生成：首先 ssh-keygen 会确认密钥的存储位置（默认是 .ssh/id_rsa），然后它会要求你输入两次密钥口令。如果你不想在使用密钥时输入口令，将其留空即可
$ ssh-keygen
# 获取公钥
$ cat id_dsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSU
GPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3
Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XA
t3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/En
mZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbx
NrRFi9wrf+M7Q== schacon@mylaptop.local
```

- 配置公钥：github -> personal settings -> SSH and GPG keys

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915210819.png)

### 远程分支&跟踪分支
本地仓库和远程仓库各自可能包含多个分支，理清几个概念：

1. 本地分支(local branch)：本地仓库中的普通分支；
2. 远程分支(remote branch)：远程仓库中的普通分支；
3. 远程跟踪分支(remote-tracking branch)：本地仓库中自动记录远程分支状态的分支(远程主机名/远程分支名，如origin/master)，其指向只会在用户使用git fetch等指令时移动到对应远程仓库最新位置，用户无法直接改变其指向；
4. 跟踪分支(tracking branch)：如果在某个本地分支 L 与某个远程分支 R 之间建立了映射关系，则称 L 为 R的跟踪分支，称 R 为 L 的上游分支(upstream)，当使用git pull时会按照对应远程分支的指向移动跟踪分支;

在 L 和 R 之间建立映射关系：

```
git branch --set-upstream-to=origin/R L
```

### 本地仓库推送到远程仓库

`git push` 的一般形式为 `git push <远程主机名> <本地分支名>  <远程分支名>`：将指定的本地分支推送到指定远程主机上指定的远程分支，需注意两点：

- 如果远程分支不存在则自动创建，但不会自动创建跟踪，如需建立跟踪关系可添加选项`-u`：

```
# 远程分支不存在，自动创建但不会跟踪
➜ liketea.github.io git:(demo) ✗ git push origin tt:xx
总共 0 （差异 0），复用 0 （差异 0）
remote:
remote: Create a pull request for 'xx' on GitHub by visiting:
remote:      https://github.com/liketea/liketea.github.io/pull/new/xx
remote:
remote:
remote:
remote: GitHub found 1 vulnerability on liketea/liketea.github.io's default branch (1 moderate). To find out more, visit:
remote:      https://github.com/liketea/liketea.github.io/network/alerts
remote:
To github.com:liketea/liketea.github.io.git
 * [new branch]      tt -> xx
 
# 远程分支不存在，自动创建并跟踪
➜ liketea.github.io git:(demo) ✗ git push origin tt:xxx -u
总共 0 （差异 0），复用 0 （差异 0）
remote:
remote: Create a pull request for 'xxx' on GitHub by visiting:
remote:      https://github.com/liketea/liketea.github.io/pull/new/xxx
remote:
remote:
remote:
remote: GitHub found 1 vulnerability on liketea/liketea.github.io's default branch (1 moderate). To find out more, visit:
remote:      https://github.com/liketea/liketea.github.io/network/alerts
remote:
To github.com:liketea/liketea.github.io.git
 * [new branch]      tt -> xxx
分支 'tt' 设置为跟踪来自 'origin' 的远程分支 'xxx'。
```

- 如果远程分支已存在，只有当远程分支是本地分支的直接上游才能push成功，本地分支直接merge到远程分支，否则需要先将远程分支拉取到本地，在本地合并/解决冲突后重新提交、推送，如需强制推送则添加选项`-f`:

```
➜ liketea.github.io git:(tt) git push origin tt:files
To github.com:liketea/liketea.github.io.git
 ! [rejected]        tt -> files (non-fast-forward)
error: 推送一些引用到 'git@github.com:liketea/liketea.github.io.git' 失败
提示：更新被拒绝，因为推送的一个分支的最新提交落后于其对应的远程分支。
提示：检出该分支并整合远程变更（如 'git pull ...'），然后再推送。详见
提示：'git push --help' 中的 'Note about fast-forwards' 小节。

# 强制推送
➜ liketea.github.io git:(files) git push -f
枚举对象: 14, 完成.
对象计数中: 100% (14/14), 完成.
使用 12 个线程进行压缩
压缩对象中: 100% (10/10), 完成.
写入对象中: 100% (10/10), 5.12 KiB | 5.12 MiB/s, 完成.
总共 10 （差异 8），复用 0 （差异 0）
remote: Resolving deltas: 100% (8/8), completed with 4 local objects.
remote:
remote: GitHub found 1 vulnerability on liketea/liketea.github.io's default branch (1 moderate). To find out more, visit:
remote:      https://github.com/liketea/liketea.github.io/network/alerts
remote:
To github.com:liketea/liketea.github.io.git
 + 62bc43b...ca67c31 files -> files (forced update)
```

比起`git push`的一般格式外，更常用的是它的简略模式。

#### 省略远程分支——推送到同名分支

`git push <remote> <local_branch>`：将指定本地分支推送到指定远程主机上的**同名分支**，如果同名分支不存在则创建，新建的远程分支不会自动与本地分支建立映射

```
# 推送至同名远程分支
$ git push <远程主机名> <local_branch>

# 推送时创建本地分支与远程同名分支的映射
$ git push -u <远程主机名> <local_branch>
```

#### 省略本地分支——删除远程分支

`git push <remote> :<remote_branch>`：省略了本地分支名，相当于推送了一个空的本地分支到远程分支，实际效果是删除了指定的远程分支

```
$ git <远程主机名> :<remote_branch>
```

#### 省略本地分支和远程分支——当前分支到上游同名分支

`git push <remote>`：将当前分支推送到指定主机上的当前分支所跟踪的的远程分支(上游分支)，如果主机上没有上游分支则失败，如果有上游分支但与当前分支不同名也会失败

```
# 没有上游分支
➜ liketea.github.io git:(tt) ✗ git push origin
fatal: 当前分支 tt 没有对应的上游分支。
为推送当前分支并建立与远程上游的跟踪，使用

    git push --set-upstream origin tt

# 有上游分支但不同名，产生歧义
➜ liketea.github.io git:(demo) ✗ git push origin
fatal: 您当前分支的上游分支和您当前分支名不匹配，为推送到远程的上游分支，
使用

    git push origin HEAD:files

为推送至远程同名分支，使用

    git push origin HEAD

为了永久地选择任一选项，参见 'git help config' 中的 push.default。
```

#### 省略远程主机名、本地仓库名和远程仓库名——当前分支到上游唯一同名分支

`git push`：将当前分支推送到其跟踪的唯一的远程上游分支，远程主机不唯一会失败，没有上游分支则失败，有上游分支但不同名也会失败

```
➜ liketea.github.io git:(tt) ✗ git push
fatal: 当前分支 tt 没有对应的上游分支。
为推送当前分支并建立与远程上游的跟踪，使用

    git push --set-upstream origin tt
```

### 从远程仓库拉取到本地仓库

`git fetch` 的一般形式为 `git fetch <remote> <remote_branch> <local_branch>`：
将指定远程主机上指定分支的更新拉取到
本地指定分支，如果本地分支不存在则自动创建，但不会自动创建跟踪。

```
➜ liketea.github.io git:(files) ✗ git fetch origin files:xyz
来自 github.com:liketea/liketea.github.io
 * [新分支]          files      -> xyz
```

默认情况下，git合并命令拒绝合并没有共同祖先的历史。当两个项目的历史独立地开始时，这个选项可以被用来覆盖这个安全。由于这是一个非常少见的情况，因此没有默认存在的配置变量，也不会添加。如果要拉取没有共同祖先的分支，直接拉取会出错，可以使用如下命令来合并：

```
$ git pull
fatal: 拒绝合并无关的历史

$ git pull origin master --allow-unrelated-histories 
```




#### 从本地仓库推送更新到远程仓库
`git push` 用于将本地分支的更新推送到远程分支，其完整语法为：

```
# 将本地指定分支的更新推送到指定远程主机的指定分支名
$ git push <远程主机名> <本地分支名>:<远程分支名>
```

如果省略远程分支名，则将本地指定分支的更新推送到指定主机上的同名分支(注意不是所跟踪的远程分支)，如果远程仓库中不存在同名分支则会被新建(注意他们之间的映射关系不会自动创建)：

```
$ git push <远程主机名> <本地分支名>
```

如果省略了本地分支名，相当于推送了一个空的本地分支到远程分支，实际效果是删除了指定的远程分支：

```
$ git push <远程主机名> :<远程分支名>

➜ liketea.github.io git:(demo) ✗ git push origin :demo
remote:
remote: GitHub found 1 vulnerability on liketea/liketea.github.io's default branch (1 moderate). To find out more, visit:
remote:      https://github.com/liketea/liketea.github.io/network/alerts
remote:
To github.com:liketea/liketea.github.io.git
 - [deleted]         demo
```

如果同时省略本地分支名和远程分支名，则将当前分支的更新推送到其跟踪且同名的远程分支：

```
$ git push <远程主机名> 
```

如果省略远程主机名、远程仓库名和本地仓库名，则将当前分支的更新推送到其所跟踪且同名的远程分支

```
$ git push
```

### 从远程仓库拉取更新到本地仓库
`git fetch` 从远程分支拉取更新到本地分支，其完整语法为：

```
# 将指定远程仓库中指定分支的更新拉取到本地仓库指定分支中，如果本地分支不存在则被创建，如果本地仓库存在且是`fast forword`则合并两个分支，否则拒绝拉取
$ git fetch <远程主机名> <远程分支名>:<本地分支名>
```









从远程仓库拉取数据：`git fetch` 

会拉取远程仓库最新数据到本地仓库中对应的远程分支，它并不会自动合并或修改你当前的工作，当准备好时必须手动合并到你的分支中；如果你有一个分支设置为跟踪一个远程分支，则可以使用 `git pull` 来自动抓取并合并远程分支到当前分支

```
# 先抓取远程仓库数据到远程分支，再手动合并远程分支到当前分支
# 抓取远程服务器origin上的默认分支
$ git fetch origin
# 抓取远程服务器origin上的指定分支master
$ git fetch origin master
# 将远程分支与当前分支合并
$ git merge origin/master

# 直接抓取并合并远程仓库中的数据到当前分支
$ git pull
```


## 参考

- [Git 中文文档](https://git-scm.com/book/zh/v2)