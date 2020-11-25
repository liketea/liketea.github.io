---
title: Hexo + Github Pages 博客搭建教程（一）：博客搭建
date: 2019-03-14 14:03:45
tags:
    - "搭建博客"
    - "教程"
categories:
    - "搭建博客"
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314172637.png)

## 前言
随着移动互联网的到来，使用电脑订阅资讯的时代一去不复返，博客时代芳华已逝，但内容创作永不过时。这里我想先谈一下自己对于个人博客的看法。

为什么要写博客：

1. 践行“费曼技巧”：与假想听众一起学习是最佳的学习方式；
2. 建立“云知识库”：大脑的记忆总是模糊、有限而易逝的，博客便是整理过的记忆，清晰、持久而又便于回忆；

为什么要搭建个人博客：

1. 公共博客平台不可控或收费；
2. 收获自主权和归属感；

为什么选择 `Hexo + GitPages` 搭建个人博客：

1. 轻量：没有麻烦的配置，使用标记语 `Markdown` ，无需自己搭建服务器；
2. 免费：免费托管 `Github` 仓库，有 1G 免费空间；
3. 通用：是目前比较流行的方案，社区活跃，不断创新；

## 准备工作
博客搭建过程主要涉及 `Hexo` 和 `Github Pages` 两个工具，在开始搭建博客前，首先要完成以下准备工作：

- [注册 Github 账号](https://github.com/join)：按指示完成注册即可；
- 创建两个 Github 仓库：一个仓库名为`<username>.github.io`，用于托管博客的静态文件（`public`文件夹）、生成 `Github Pages` 展示页面；另一个仓库名为`<username>.github.source` 用于文章备份，可兼作图床（`source` 文件夹）；
- [本地安装git](https://git-scm.com/book/zh/v1/%E8%B5%B7%E6%AD%A5-%E5%AE%89%E8%A3%85-Git)：先在本地安装 [homebrew 软件包管理工具](https://brew.sh/index_zh-cn)，再通过 `brew install git` 安装 `git` 工具，通过`git version` 查看 git 是否成功安装；

```
# 安装homebrew
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
# 安装git
$ brew install git
$ git version
git version 2.15.0
```
- [配置git公钥](https://git-scm.com/book/zh/v1/%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%B8%8A%E7%9A%84-Git-%E7%94%9F%E6%88%90-SSH-%E5%85%AC%E9%92%A5)：Git 服务器都会选择使用 SSH 公钥来进行授权，配置方法也很简单，在本地通过 `ssh-keygen` 生成密钥对之后，将`./.ssh/id_rsa.pub` 中的公钥添加到github账号`SSH key`；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314183306.png)

- 安装`node.js`：`brew install node`安装，`node -v`检查是否安装成功；

```
$ brew install node
$ node -v
v8.4.0
```
- [安装Hexo](https://hexo.io/zh-cn/docs/setup)：在安装好 `git` 和 `node.js` 之后就可以使用`npm install -g hexo-cli` 安装 `hexo` 了，可通过 `hexo version` 查看`hexo` 版本信息；

```
$ npm install -g hexo-cli
$ hexo version
hexo-cli: 1.1.0
os: Darwin 18.0.0 darwin x64
```

本系列教程基于操作系统 `macOS Mojave`，`windows` 或`Linux` 也可作参考。

## 搭建博客
利用 `Hexo` 和 `Github Pages` 搭建博客的基本原理：首先通过 `Hexo` 将 `Markdown` 文件渲染生成静态网页，再将静态站点托管到 `Github` 仓库，利用 `Github Pages` 服务以网页形式显示仓库内容。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190206003147.png)

### 创建站点
成功安装 `Hexo` 后，请执行下列命令，`Hexo` 将会在指定文件夹中新建所需要的文件：

```
# 在目标文件夹中创建新站点，Hexo会从hexo-starter代码库clone代码到目标文件夹
$ hexo init <folder>
$ cd <folder>
$ npm install
```

创建站点后的文件目录：

```
    .
    ├── node_modules        
    ├── scaffolds           
    ├── source              
    ├── themes              
    ├── _config.yml         
    ├── package-lock.json   
    └── package.json        
```
- `node_modules`：node依赖包；
- `scaffolds`：模版文件夹，用户可自定义markdown模板，默认包含了以下三种模板
    - `page`：页面模板；
    - `post`：文章模板；
    - `draft`：草稿模板；
- `source`：资源文件夹，存放用户所有资源；
- `themes`：主题文件夹；
- `_config.yml`：在 Hexo 中有两份主要的配置文件，其名称都是 `_config.yml`。 其中，一份位于站点根目录下，主要包含 Hexo 本身的配置，称作`站点配置文件`；另一份位于主题目录下，这份配置由主题作者提供，主要用于配置主题相关的选项，称作`主题配置文件`；

### 生成静态文件
使用 Hexo 生成静态文件快速而且简单：

```
$ hexo generate
```

Hexo 能够监视文件变动并立即重新生成静态文件，在生成时会比对文件的 SHA1 checksum，只有变动的文件才会写入：
```
$ hexo generate --watch
```

完成后部署，让 Hexo 在生成完毕后自动部署网站，以下四个命令的作用是相同的：

```
$ hexo generate --deploy
$ hexo deploy --generate
$ hexo g -d
$ hexo d -g
```
### 调试站点
Hexo 3.0 把服务器独立成了个别模块，您必须先安装 hexo-server 才能使用：

```
$ npm install hexo-server --save
```

安装完成后，输入以下命令以启动服务器：

```
$ hexo server
```

在服务器启动期间，Hexo 会监视文件变动并自动更新，您无须重启服务器，您的网站会在 `http://localhost:4000` 下启动，效果如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314185517.png)

如果希望服务器只处理 `public` 文件夹内的文件，而不会处理文件变动，可以在**静态模式**下启动服务器，此模式通常用于生产环境（production mode）下：

```
$ hexo server -s
```

- 如果希望以调试模式启动服务器：

```
$ hexo server --debug
```

- 如果您想要更改端口，或是在执行时遇到了 EADDRINUSE 错误，可以在执行时使用 -p 选项指定其他端口，如下：

```
$ hexo server -p 5000
```

### 部署站点
将我们的站点部署到github上，需要三个步骤：

- 安装 `hexo-deployer-git`：该命令需在站点文件目录下执行；

```
$ npm install hexo-deployer-git --save
```

- 修改配置：修改配置文件`_config.yml`中的 deploy 配置；

```
# type表示服务器类型，repo表示仓库地址，branch和message可省略
deploy:
  type: git
  repo: <repository url>    # https://bitbucket.org/JohnSmith/johnsmith.bitbucket.io
  branch: [branch]          # published
  message: [message]

# 您可同时使用多个 deployer，Hexo 会依照顺序执行每个 deployer
deploy:
  type: git
  repo:
  type: heroku
  repo:
```

- Hexo 一键部署：如果出现错误请先检查以上各步骤是否正确设置；

```
$ hexo deploy
```

站点成功部署后，站点目录下的 `public` 文件夹会被同步到相应的 github 仓库中，可以在仓库的 Settings 下找到 GitHub Pages 网页的地址（默认为 `<github用户名>.github.io`），网页默认效果如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/15525610289408.jpg)

至此，一个简易的个人博客就搭建完成了。但是距离一个简洁大方、美观实用的博客系统还有很多地方需要优化。

### Hexo 常用命令
现将 Hexo 常用命令整理如下，更详细的说明参见[Hexo官方文档-指令](https://hexo.io/zh-cn/docs/commands)：

| 命令 | 简写 | 说明 |
| :-: | :-: | :-- |
|`hexo init [folder]`|  | 新建一个网站。如果没有设置 folder ，Hexo 默认在目前的文件夹建立网站 |
|`hexo new [layout] <title>`| `hexo n [layout] <title>`| 新建一篇文章。如果没有设置 `layout` 的话，默认使用 `_config.yml` 中的 `default_layout` 参数代替。如果标题包含空格的话，请使用引号括起来|
|`hexo generate`| `hexo g` | 生成静态文件 `-d, --deploy`文件生成后立即部署网站`-w, --watch`监视文件变动|
|  `hexo publish [layout] <filename>`|  | 发表草稿，将草稿移动至`_post`文件夹 |
|`hexo server`| `hexo s`| 启动服务器 `-p, --port`重设端口；`-s, --static`只使用静态文件；`-l, --log`启动日记记录，使用覆盖记录格式；|
|`hexo deploy`| `hexo d` | 部署网站，`-g, --generate`部署之前预先生成静态文件 |
|`hexo clean`|  |清除缓存文件 (db.json) 和已生成的静态文件 (public)。在某些情况（尤其是更换主题后），如果发现您对站点的更改无论如何也不生效，您可能需要运行该命令|
|`hexo list`|  | 列出网站资料，Available types: page, post, route, tag, category |
|`hexo version`|  | 显示Hexo版本 |
|`hexo --draft`|  | 显示 source/_drafts 文件夹中的草稿文章 |
|`hexo migrate <type>`|  | 从其他博客系统 迁移内容 |

## 参考

1. [Hexo官方文档](https://hexo.io/zh-cn/docs/)
2. [GitHub+Hexo 搭建个人网站详细教程](https://zhuanlan.zhihu.com/p/26625249)
3. [Hexo+Github Pages+Next博客搭建](https://www.jianshu.com/p/d654d52f2739)
4. [mac环境下搭建hexo+github pages+next个人博客](https://blog.csdn.net/qq_34290780/article/details/78230706)

