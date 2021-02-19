---
title: Hexo + Github Pages 博客搭建教程（三）：文章写作
date: 2019-03-12 14:03:45
tags:
    - "搭建博客"
    - "教程"
categories:
    - "搭建博客"
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/yu1.jpg)

## 写作流程
使用 HEXO 写作博客的一般流程：

1. 创建文章：通过 `hexo new [layout] <title>` 创建一篇新的文章；
2. 编辑文章：通过本地 `Markdown` 编辑器完成博客内容的写作；
3. 发布文章：将博客发布到你的服务器；

### 创建文章
你可以通过下列命令来创建一篇新文章：

```
$ hexo new [layout] <title>
```

#### 布局
`Hexo` 有三种默认布局：`post`、`page` 和 `draft`，它们分别对应不同的路径，而您自定义的其他布局和 `post` 相同，都将储存到 `source/_posts` 文件夹：

| 布局 | 翻译|路径 |
| --- | --- |--- |
| post |发表| `source/_post` |
| page | 页面|`source` |
| draft | 草稿|`source/_drafts` |

#### 草稿
草稿（`draft`）默认不会显示在页面中，但你可以通过以下三种方式中的任意一种来预览草稿：

1. 发布草稿：执行 `hexo publish [layout] <title>` 可以将草稿从`source/_drafts` 文件夹移动到 `source/_posts` 文件夹；
2. 在执行时加上 ` --draft` 参数；
3. 把 `render_drafts` 参数设为 `true` ：这将在页面中显示全部草稿，一般不这么用；

#### 模板
在新建文章时，`Hexo` 会根据 `scaffolds` 文件夹内相对应的文件来建立文件，例如：

```
$ hexo new photo "My Gallery"
```

在执行这行指令时，`Hexo` 会尝试在 `scaffolds` 文件夹中寻找 `photo.md`，并根据其内容建立文章，以下是您可以在模版中使用的变量：

变量	|描述
---|---
layout|	布局
title	|标题
date	|文件建立日期

#### 文件名
`Hexo` 默认以标题做为文件名称，但您可编辑站点配置文件中的 `new_post_name` 参数来改变默认的文件名称，举例来说，设为 `:year-:month-:day-:title.md` 可让您更方便的通过日期来管理文章：


| 变量 | 描述 |
| --- | --- |
| :title | 标题（小写，空格将会被替换为短杠） |
| :year | 建立的年份，比如， 2015 |
| :month | 建立的月份（有前导零），比如， 04 |
| :i_month | 建立的月份（无前导零），比如， 4 |
| :day | 建立的日期（有前导零），比如， 07 |
| :i_day | 建立的日期（无前导零），比如， 7 |

### 编辑文章
HEXO 文章编写采用 [Markdown 语法](https://coding.net/help/doc/project/markdown.html)进行写作，一级标题太大，建议从二级标题开始。

#### Front-matter
`Front-matter` 是指文章头部以 `---` 分隔的区域，用于指定个别文件的变量。以下是预先定义的参数，您可在模板中使用这些参数值并加以利用：

参数	|描述	|默认值
---|---|---
layout	|布局	|
title	|标题	|
date	|建立日期	|文件建立日期
updated	|更新日期	|文件更新日期
comments	|开启文章的评论功能|	true
tags	|标签（不适用于分页）|	
categories	|分类（不适用于分页）|
permalink|	覆盖文章网址	|

只有文章支持分类和标签，分类具有顺序性和层次性，以下是文章分类和标签的一个例子：

```
# 文章在Diary/Life下
categories:
    - Diary
    - Life
# 文章有两个标签PS3、Games
tags:
    - PS3
    - Games
```

一个文章可以有多个标签，多个分类，用中括号就可以达到并列效果:

```
# 文章同时在Diary类别和Life类别下
categories:
    - [Diary]
    - [Life]
```

#### 插入图片
俗话说“一图胜千言”，但在博客中插入图片一直是件让人头疼的事，在博客中插入图片大体有两种方式：

1. 作为本地文件引用：首先将图片同代码文件一起上传至站点服务器，然后以相对路径形式引用；HEXO 提供了三种图片引用方式：
    1. 将图片放在 `source/images` 文件夹中。然后通过类似于 `![](/images/image.jpg)` 的方法访问它们；
    2. 将 `_config.yml` 文件中的 `post_asset_folder` 选项设为 `true` ，Hexo将会在你每一次通过 `hexo new [layout] <title>` 命令创建新文章时自动创建一个文件夹，这个资源文件夹将会有与这个 `markdown` 文件一样的名字，将所有与你的文章有关的资源放在这个关联文件夹中之后，你可以通过相对路径来引用它们；
    3. 以上两种方式会导致图片无法在主页或归档页显示的问题，为此， [HEXO]((https://hexo.io/zh-cn/docs/asset-folders)) 推出了使用标签插件来引用图片的方式，但这种方式的可移植性不强，也不推荐；
2. 作为外链引用：首先将图片上传至图床（储存图片的服务器）生成外链，然后以外链形式引用；这种方式可大大简化图片管理，节约宝贵的服务器资源，加快图片加载速度，推荐使用；


### 发布文章
发布文章很简单，只需要经过“生成”和“部署”两步就行了：

```
$ hexo g
$ hexo d
```

你也可以通过以下一行命令来完成“生成”和“部署”两个过程：

```
$ hexo g -d
```

如果你希望在正式发布前，先在本地查看发布后的实际效果并进行调试，也可以在“生成”步骤之后，通过以下命令打开本地服务器，您的网站会在 `http://localhost:4000` 下启动。在服务器启动期间，Hexo 会监视文件变动并自动更新，您无须重启服务器。

```
$ hexo s
# 或者进入调试模式
$ hexo s --debug
```

如果你的文章符合以下两种情况之一，那么以上过程将不会对你的文章进行处理，你的文章也就不会被发布出去：

1. 文章存放在草稿文件夹 `source/_drafts` 中；
2. 文章名称被添加到站点配置文件中的 `skip_render`；

在实际写作中，更常用的写作流程如下：

```
# 1. 创新草稿
$ hexo n draft <title>
# 2. 编辑文章
# 3. 发布文章
$ hexo publish <title>
# 4. 渲染文章
$ hexo g
# 5. 部署文章
$ hexo d
```

## 写作工具
“工欲善其事，必先利其器”，好的写作工具能够让博客写作变得更简单、更有趣。

### Mweb 编辑器
Mweb 是 Mac上一款非常好用的 Markdown 写作、记笔记、静态博客生成软件，[极力推荐](https://sspai.com/post/33855)。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190320125255.png)

Mweb 有以下一些优点:

- 简洁的外观；
- 丰富的快捷键；
- 丰富的扩展语法；
- 轻松编辑表格；
- 图片的快速插入与统一管理；
- 图片自动上传图床功能；
- 可设置图片居左/中/右；
- 一键生成/上传博客；
- 支持各种导出格式；


### 图床
国内外有众多图床可供选择，图床可分为两种：

1. 公共图床：利用公共服务的图片上传接口，来提供图片外链的服务，比如 Imgur 图床、微博图床、SM.MS 图床等等；
2. 私有图床：利用各大云服务商提供的存储空间或者自己在 VPS 上使用开源软件来搭建图床，如七牛云、又拍云、阿里云 OSS、腾讯云 COS、自建图床工具 Lychee，此外 Github 仓库也可作为少量图片的图床使用，但不推荐这么做；

关于各种图床的优劣可以参考文章[盘点一下免费好用的图床](https://zhuanlan.zhihu.com/p/35270383)，公共图床不可控也不安全、私有图床大多需要网站备案，在尝试了多个图床之后，我最后选择了腾讯云 COS 。

#### 腾讯 COS 配置
通过腾讯云>控制台>对象存储>存储同列表>创建存储桶，如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553061767678.jpg)

有两个关键的配置不能忽略：

- 设置访问权限：将访问权限应设置为公有读私有写；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553061867458.jpg)

- 设置防盗链：开启之后即使其他人获取到链接也无法访问相应图片；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553062205605.jpg)



#### PicGo图片上传工具
[PicGo](https://picgo.github.io/PicGo-Doc/zh/) 是一款开源跨平台的免费图片上传工具以及图床相册管理软件，它能帮你快速地将图片上传到微博、又拍云、阿里云 OSS、腾讯云 COS、七牛、GitHub、sm.ms、Imgur 等常见的免费图床网站或云存储服务上，并自动复制图片的链接到剪贴板里，使用上非常高效便捷。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553058253127.jpg)

关于 PicGo 的下载安装和配置使用的详细过程请参照[PicGo指南](https://picgo.github.io/PicGo-Doc/zh/)。PicGo 支持剪切板上传和拖拽上传两种方式：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/sdf.gif)

以PicGo配置腾讯COS为例：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/企业微信截图_30def863-06fd-4cad-8820-77f155dc1e58.png)



## 参考
1. [腾讯对象存储](https://cloud.tencent.com/document/product/436/16871)
2. [PicGo指南](https://picgo.github.io/PicGo-Doc/zh/)