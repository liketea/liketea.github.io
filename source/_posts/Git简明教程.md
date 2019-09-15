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
# 查看帮助
git version 2.20.1 (Apple Git-117)
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
查看文件的状态：

```
$ git status
On branch master
nothing to commit, working directory clean
```

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1_9qX9F9MGsWKfcmgTOR9BPw.png)

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

#### 取消攒出

`git reset HEAD <file>`：取消对文件file的暂存

```
$ git reset HEAD CONTRIBUTING.md
Unstaged changes after reset:
M	CONTRIBUTING.md
```

#### 取消修改
`git checkout -- <file>`：取消对文件file的修改，也就是用上次提交时的文件覆盖工作区中的文件；

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






### 远程仓库
远程仓库是指托管在因特网或其他网络中的你的项目的版本库，与他人协作涉及管理远程仓库以及根据需要推送或拉取数据。

本地仓库和远程仓库各自可能包含了多个分支，理清几个概念：

1. 本地分支(local branch)：本地仓库中的普通分支；
2. 远程分支(remote branch)：远程仓库中的普通分支；
3. 远程跟踪分支(remote-tracking branch)：本地仓库中自动记录远程分支状态的分支，其指向只会在用户使用git fetch等指令时移动到对应远程仓库最新位置，用户无法直接改变其指向；
4. 跟踪分支(tracking branch)：与远程分支建立了映射关系的普通本地分支，对应的远程分支称为该分支的上游(upstream)分支，用户可以改变跟踪分支的指向，当使用git pull时会按照对应远程分支的指向移动跟踪分支

查看所有分支：

```
# 查看本地分支
$ git branch
# 查看远程分支
$ git branch -r
# 查看所有分支
$ git branch -a
# 查看本地分支以及其跟踪的分支
$ git branch -vv
```

#### 查看远程仓库
克隆仓库服务器的默认名字是origin

```
# 查看远程仓库名
$ git remote
origin

# 显示服务器名和URL
$ git remote -v
origin	https://github.com/schacon/ticgit (fetch)
origin	https://github.com/schacon/ticgit (push)

# 查看某个远程仓库更多信息
$ git remote show origin
* remote origin
  Fetch URL: https://github.com/schacon/ticgit
  Push  URL: https://github.com/schacon/ticgit
  HEAD branch: master
  Remote branches:
    master                               tracked
    dev-branch                           tracked
```
 
#### 添加远程仓库 
添加一个新的远程 Git 仓库，同时指定一个你可以轻松引用的简写

```
# 添加远程仓库的完整语法
$ git remote add <shortname> <url> 
# 示例
$ git remote add pb https://github.com/paulboone/ticgit
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

#### 从远程仓库拉取更新到本地仓库
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
 

 
 
### Git —— 状态


#### Git —— add（添加至缓存区）












## Git 分支




## Git 



## 参考

- [Git 中文文档](https://git-scm.com/book/zh/v2)