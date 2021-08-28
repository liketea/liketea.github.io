---
title: Hexo + Github Pages 博客搭建教程（二）：主题定制
date: 2019-03-13 14:03:45
tags:
    - "搭建博客"
    - "教程"
categories:
    - "搭建博客"
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/NextSchemes3.png)

Hexo 安装主题的方式非常简单，只需要将主题文件拷贝至站点目录的 themes 目录下，然后修改下配置文件即可。

这里推荐 Next 主题，该主题简洁大方美观，集成度高，定制性强，[官方文档](https://theme-next.iissnan.com/getting-started.html)完备，十分适合新手使用。下面以 NexT 主题为例，介绍主题切换、配置方法。

## NexT 主题安装
### 下载主题
NexT 主题下载有两种方式：

1. 官网下载：前往 NexT 版本[发布页面](https://github.com/iissnan/hexo-theme-next/releases)，找到 `Source code` 点击下载，下载后解压到站点目录的 `themes` 目录下；
2. `git clone`：直接将源码克隆到站点目录的 `themes` 目录下；

```
$ cd your-hexo-site
$ git clone https://github.com/iissnan/hexo-theme-next themes/next
```

### 启用主题
打开`站点配置文件`，找到 `theme` 字段，并将其值更改为 `next` 即可；

```
theme: next
```

### 验证主题
启动本地站点服务器，使用浏览器访问 `http://localhost:4000` 当你看到站点的外观与下图所示类似时即说明你已成功安装 NexT 主题，这是 NexT 默认的 `Scheme` —— `Muse`。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314194948.png)

## NexT 主题定制
主题风格千变万化且各有所好，建议在充分参考 NexT 官方文档和他人博客风格的前提下，选择最适合自己的风格，总的原则是：简洁、实用。下面列举了 NexT 主题常见的定制方法，如果有更多定制需求，可自行百度。

说明：

1. 配置文件：“站点配置文件”是指站点目录下的 `_config.yml` 文件，“主题配置文件”是指NexT 主题文件下的 `_config.yml` 文件。
2. 配置生效：如果修改了站点配置文件，可能需要先清理静态文件，再重新生成静态文件，最后重新启动服务器，才会生效，如果还不行，可能需要多次生成部署；

```
$ hexo clean
$ hexo g
$ hexo s
```

### 整体定制
#### 选择 Scheme
NexT 提供了多种不同的外观风格 `Scheme`，几乎所有的配置都可以在 `Scheme` 之间共用，可通过更改 `主题配置文件`，搜索 `Scheme` 关键字，将你需用启用的 `scheme` 前面注释 `#` 去除即可。

- 将默认的 `Muse` 主题注释掉，取消 `Mist` 的注释

```
# ---------------------------------------------------------------
# Scheme Settings
# ---------------------------------------------------------------
# Schemes
# scheme: Muse
scheme: Mist
# scheme: Pisces
# scheme: Gemini
```

- 查看新 Scheme 的效果:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314195333.png)

#### 设置语言
观察以上截图，发现首页标签为英文，编辑`站点配置文件`，将 `language` 设置成你所需要的语言（简体中文对应`zh-Hans`）:

```
language: zh-Hans
```

#### 设置字体
Hexo 默认字体大小为 14px，如果感觉字体太小，可打开 `\themes\next\source\css\ _variables\base.styl`文件，将 `font-size-base` 改成16px即可，如下所示：

```
// Font size
$font-size-base           = 16px
```

#### 更改网页图标 Favicon
NexT 提供了默认的网页图标，可通过以下步骤进行自定义设置：

- 制作 Favicon 图标：可以先在 [EasyIcon](https://www.easyicon.net/) 中找到一张你所喜欢的 ico 图标，然后通过[比特虫](http://www.bitbug.net/)在线生成两张ico图标（大小分别为16x16和32x32），将图标放在 `/themes/next/source/images` ；
- 修改主题配置文件：

```
favicon:
  small: /images/feather-16x16.ico
  medium: /images/feather-32x32.ico
  apple_touch_icon: /images/apple-touch-icon-feather.png
  safari_pinned_tab: /images/apple-touch-icon-feather.png
```

- 修改后的实际效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315174101.png)

#### 隐藏网页底部 powered By Hexo
在主题配置文件中，修改如下配置：

```
 # Hexo link (Powered by Hexo).
  powered: false

  theme:
    # Theme & scheme info link (Theme - NexT.scheme).
    enable: false
    # Version info of NexT after scheme info (vX.X.X).
    version: true
```

#### 修改网页头部图片
- 修改格式文件：打开 `hexo\themes\next\source\css\_schemes\Mist\_header.styl`，将第一行 `background:` 后的内容改为如下形式：

```
.header { background: url('https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/top_pic.jpg'); }
```
- 显示效果：并不简洁美观，建议采用默认背景

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552755988940.jpg)

#### 添加 README.md 文件
如果希望在项目中添加 README.md 文件，又不想对该文件进行渲染，可在 Hexo 目录下的 source 根目录下添加一个 README.md 文件，修改站点配置文件 `_config.yml`，将 `skip_render` 参数的值设置为

```
skip_render: README.md
```

保存退出即可，再次使用 `hexo d` 命令部署博客的时候就不会再渲染 README.md 这个文件了。

### 侧边栏定制
#### 侧边栏出现位置和时机
默认情况下，侧栏仅在文章页面（拥有目录列表）时才显示，并放置于右侧位置。可以通过修改`主题配置文件`中的 `sidebar` 字段来控制侧栏的行为。侧栏的设置包括两个部分，其一是侧栏的位置， 其二是侧栏显示的时机。

- 设置侧边栏位置：

```
# left 靠左，right靠右
sidebar:
  position: left
```
- 设置侧边栏显示时机：

```
# post是默认行为，在文章页显示；另外几个选项是always、hide、remove
sidebar:
  display: post
```

#### 设置站点信息
- 设置头像：编辑 `主题配置文件`，修改字段 `avatar`，值设置成头像的链接地址，可以是完整URI，也可以是本地文件路径（站点目录下的 `source/images` 或者主题目录下的 `source/uploads`）。

```
# Sidebar Avatar
# in theme directory(source/images): /images/avatar.gif
# in site  directory(source/uploads): /uploads/avatar.gif
avatar: /images/avatar.png
```
- 设置作者昵称：编辑 `站点配置文件`， 设置 `author` 为你的昵称；
- 设置站点描述：编辑 `站点配置文件`， 设置 `description` 字段为你的站点描述。站点描述可以是你喜欢的一句签名；
- 建站时间：编辑 `主题配置文件`，新增字段 `since:年份`；

#### 修改作者头像并旋转
如果希望将作者头像修改为圆形，并且实现鼠标悬浮于图片上时图片旋转的效果，可按照以下步骤进行修改：

- 修改代码：打开`\themes\next\source\css\_common\components\sidebar\sidebar-author.styl`，在里面添加如下代码：

```
.site-author-image {
  display: block;
  margin: 0 auto;
  padding: $site-author-image-padding;
  max-width: $site-author-image-width;
  height: $site-author-image-height;
  border: $site-author-image-border-width solid $site-author-image-border-color;
  /* 头像圆形 */
  border-radius: 80px;
  -webkit-border-radius: 80px;
  -moz-border-radius: 80px;
  box-shadow: inset 0 -1px 0 #333sf;
  /* 设置循环动画 [animation: (play)动画名称 (2s)动画播放时长单位秒或微秒 (ase-out)动画播放的速度曲线为以低速结束 
    (1s)等待1秒然后开始动画 (1)动画播放次数(infinite为循环播放) ]*/
 
  /* 鼠标经过头像旋转360度 */
  -webkit-transition: -webkit-transform 1.0s ease-out;
  -moz-transition: -moz-transform 1.0s ease-out;
  transition: transform 1.0s ease-out;
}
img:hover {
  /* 鼠标经过停止头像旋转 
  -webkit-animation-play-state:paused;
  animation-play-state:paused;*/
  /* 鼠标经过头像旋转360度 */
  -webkit-transform: rotateZ(360deg);
  -moz-transform: rotateZ(360deg);
  transform: rotateZ(360deg);
}
/* Z 轴旋转动画 */
@-webkit-keyframes play {
  0% {
    -webkit-transform: rotateZ(0deg);
  }
  100% {
    -webkit-transform: rotateZ(-360deg);
  }
}
@-moz-keyframes play {
  0% {
    -moz-transform: rotateZ(0deg);
  }
  100% {
    -moz-transform: rotateZ(-360deg);
  }
}
@keyframes play {
  0% {
    transform: rotateZ(0deg);
  }
  100% {
    transform: rotateZ(-360deg);
  }
}
```

- 效果如图：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314205943.png)

#### 设置RSS
NexT 中 RSS 有三个设置选项，满足特定的使用场景，更改 `主题配置文件`：设定 `rss` 字段的值：

- false：禁用 RSS，不在页面上显示 RSS 连接。
- 留空：使用 Hexo 生成的 Feed 链接，你可以需要先安装 hexo-generator-feed 插件。

```
$ npm install hexo-generator-feed
```
- 具体的链接地址：适用于已经烧制过 Feed 的情形。

重启服务器，侧边栏效果如图：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314202519.png)

#### 侧边栏社交链接
侧边栏社交链接的修改包括链接和图标两部分，打开主题配置文件：

```
# 社交链接，键值格式是“显示文本: 链接地址 || 图标名”
social:
  GitHub: https://github.com/your-user-name
  Twitter: https://twitter.com/your-user-name
  微博: http://weibo.com/your-user-name
  豆瓣: http://douban.com/people/your-user-name
  知乎: http://www.zhihu.com/people/your-user-name
  
# 社交图标，键值格式是“显示文本: Font Awesome 图标名称”，enable 选项用于控制是否显示图标
social_icons:
  enable: true
  # Icon Mappings
  GitHub: github
  Twitter: twitter
  微博: weibo
```

#### 侧边友情链接
友情链接可用于提供一些关联网站地址，或者推荐文章。

- 编辑 `主题配置文件`：友情链接包含两个部分，① 友情链接名称、图标；② 每个友情链接的名称、地址；

```
# Blog rolls
# 友情链接本身的名字和图标
links_icon: plane
links_title: 友情链接
# 友情链接显示格式：竖、横
links_layout: block
#links_layout: inline
# 友情链接名称、地址
links:
  likew: https://likew.bitcron.com
```
- 侧边栏最终效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314203250.png)

### 首页定制
#### 设置菜单
菜单配置包括三个部分：

1. 菜单项：名称和链接，名称指在内部文件中使用的变量名；
2. 菜单项文本：菜单在页面上显示的文字；
3. 菜单项图标：NexT 主题默认集成了识别[Font Awesome图标](http://www.bootcss.com/p/font-awesome/#icons-web-app)的方法，只需要在里面找到想要图标的名称，去掉前缀`icon-` 就可以拿过来直接使用，可以满足绝大的多数的场景，同时无须担心在 Retina 屏幕下 图标模糊的问题；

编辑主题配置文件，修改以下内容：

- 设定菜单项和菜单项图标：menu下的设置项格式为`菜单项名称: 链接路径 || 菜单项图标`；

```
menu:
  home: / || home
  about: /about/ || user
  tags: /tags || tags
  categories: /categories/ || th
  archives: /archives/ || archive
  schedule: /schedule/ || calendar
  sitemap: /sitemap.xml || sitemap
```
- 设置菜单项文本：如果要修改菜单项文本，可打开 NexT 主题目录下的 `languages/{language}.yml`（{language} 为你所使用的语言），进行编辑修改；

```
menu:
  home: 首页
  archives: 归档
  categories: 分类
  tags: 标签
  about: 关于
  search: 搜索
  commonweal: 公益404
  something: 有料
```
保留你需要的菜单项后，实际效果如图：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314200100.png)

#### 添加标签页面
新建“标签”页面，并在菜单中显示“标签”链接，在标签页展示站点所有标签，如果所有文章都没有标签则标签页将是空的。

配置方法：

- 新建页面：在终端窗口下，定位到 Hexo 站点目录下，使用 `hexo new page` 新建一个页面，命名为 `tags` ；

```
# 切换到站点目录
$ cd your-hexo-site
# 新建tags页面，会在source目录下自动生成tags文件夹
$ hexo new page tags
# tags目录下包含index文件夹和index.md文件
$ tree ./source/tags
    ./source/tags
    ├── index
    └── index.md
```
- 设置页面类型：编辑刚才新建的`index.md`文件，将页面类型设置为tags， 主题将自动为这个页面显示标签云，一般标签页不显示评论；

```
---
title: 标签
date: 2019-03-12 16:15:10
type: "tags"
comments: false
---
```
- 修改菜单：在菜单中添加链接，编辑`主题配置文件`，添加 `tags` 到 menu 中，如下:

```
menu:
  home: /
  archives: /archives
  tags: /tags
```
- 设置文章标签：在文章 `front-matter` 添加 `tags` 字段，可设置文章的标签：

```
---
title: 测试标签页
date: 2019-03-12 16:34:39
tags:
    - 标签1
    - 标签2
    - 标签3
---
```

- 实际效果：启动本地站点服务器，使用浏览器访问 `http://localhost:4000` ，标签页如图所示。

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314201002.png)

#### 添加分类页面
“分类”和“标签”都可以用来对文章进行管理，区别在于分类多级、有序而标签同级、无序。分类是一种更加精细的文件管理方式，可以按照主题结构树来管理文章，标签则是一种平面化的管理方式，适合于快速定位到一些关键词。

- 新建页面：在站点目录下创建分类页面

```
$ cd your-hexo-site
$ hexo new page categories
```
- 设置页面类型：打开 `categories/index.md` 文件，修改页面类型，一般分类页面不显示评论：

```
title: 分类
date: 2014-12-22 12:39:04
type: "categories"
comments: false
---
```
- 修改菜单：打开主题配置文件，修改 `menu` 下的`categories` 为 `/categories`


```
menu:
  home: /
  archives: /archives
  categories: /categories
```

- 实际效果：分类页面显示分类树结构，但不会显示具体分类下的文章。点击具体的分类类别，可显示该类别下的所有文章：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314201055.png)

#### 首页文章以摘要形式显示
- 修改主题配置文件：打开`主题配置文件`，找到如下位置，修改

```
# 其中length代表显示摘要的截取字符长度
auto_excerpt:
  enable: true
  length: 150
```

- 修改后的效果如图：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314210243.png)

#### 设置首页文章显示篇数
- 安装插件：

```
npm install --save hexo-generator-index
npm install --save hexo-generator-archive
npm install --save hexo-generator-tag
```

- 修改站点配置文件：在 `站点配置文件` 中，添加如下内容，其中 `per_page` 字段是你希望设定的显示篇数。`index`，`archive` 及 `tag` 开头分表代表主页，归档页面和标签页面

```
index_generator:
  path: ''
  per_page: 10
  order_by: -date   # 反之，date时间早的在前面

archive_generator:
  per_page: 20
  yearly: true
  monthly: true

tag_generator:
  per_page: 10
```

### 文章页定制
#### 设置代码高亮
NexT 使用 Tomorrow Theme 作为代码高亮，共有5款主题供你选择。 NexT 默认使用的是 白色的 normal 主题，可选的值有 normal，night， night blue， night bright， night eighties：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314201404.png)

更改 highlight_theme 字段，将其值设定成你所喜爱的高亮主题（默认的就挺好），例如：

```
# Code Highlight theme
# Available value:
#    normal | night | night eighties | night blue | night bright
# https://github.com/chriskempson/tomorrow-theme
highlight_theme: normal
```

#### 修改文章底部带 # 号的标签
修改模板 `/themes/next/layout/_macro/post.swig`，搜索 `rel="tag">#`，将 `#` 换成`<i class="fa fa-tag"></i>`，效果如图：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314204634.png)

#### 文章顶部显示更新时间

```
# Post meta display settings 文章显示信息
post_meta:
  item_text: true
  created_at: true
  updated_at: true
  categories: true
```
#### 开启打赏功能
NexT 支持微信打赏和支付宝打赏，只需要在 `主题配置文件` 中填入微信或支付宝收款二维码图片地址（绝对地址从source目录起）即可开启该功能。

```
reward_comment: 坚持原创技术分享，您的支持将鼓励我继续创作！
wechatpay: /path/to/wechat-reward-image
alipay: /path/to/alipay-reward-image
```

实际效果:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314203519.png)

### 设置动画效果
#### 设置加载动画
NexT 默认开启动画效果，效果使用 JavaScript 编写，因此需要等待 JavaScript 脚本完全加载完毕后才会显示内容。 如果您比较在乎速度，可以将 `use_motion` 设置为 false 来关闭加载动画；

#### 添加顶部加载条
修改主题配置文件 `_config.yml` 将 `pace`设为 `true` 就行了，你还可以换不同样式的加载条，如下图：

```
# Progress bar in the top during page loading.
pace: true
# Themes list:
#pace-theme-big-counter
# 跳跳球
#pace-theme-bounce
#pace-theme-barber-shop
# 原子转
#pace-theme-center-atom
#pace-theme-center-circle
#pace-theme-center-radar
# 进度条
#pace-theme-center-simple
#pace-theme-corner-indicator
#pace-theme-fill-left
#pace-theme-flash
#pace-theme-loading-bar
# pace-theme-mac-osx
# 简约式
#pace-theme-minimal
# For example
# pace_theme: pace-theme-center-simple
pace_theme: pace-theme-minimal
```

实际效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/5308475-2f5051d9f0352b90.gif)

#### 点击出现红心效果
- 添加 js 文件：在 `hexo\themes\next\source\js\src\` 目录下新增文件 `love.js`，文件内容如下：

```js
!function(e, t, a) {
    function n() {
        c(".heart{width: 10px;height: 10px;position: fixed;background: #f00;transform: rotate(45deg);-webkit-transform: rotate(45deg);-moz-transform: rotate(45deg);}.heart:after,.heart:before{content: '';width: inherit;height: inherit;background: inherit;border-radius: 50%;-webkit-border-radius: 50%;-moz-border-radius: 50%;position: fixed;}.heart:after{top: -5px;}.heart:before{left: -5px;}"), o(), r()
    }
    function r() {
        for (var e = 0; e < d.length; e++)
            d[e].alpha <= 0 ? (t.body.removeChild(d[e].el), d.splice(e, 1)) : (d[e].y--, d[e].scale += .004, d[e].alpha -= .013, d[e].el.style.cssText = "left:" + d[e].x + "px;top:" + d[e].y + "px;opacity:" + d[e].alpha + ";transform:scale(" + d[e].scale + "," + d[e].scale + ") rotate(45deg);background:" + d[e].color + ";z-index:99999");
        requestAnimationFrame(r)
    }
    function o() {
        var t = "function" == typeof e.onclick && e.onclick;
        e.onclick = function(e) {
            t && t(), i(e)
        }
    }
    function i(e) {
        var a = t.createElement("div");
        a.className = "heart", d.push({
            el: a,
            x: e.clientX - 5,
            y: e.clientY - 5,
            scale: 1,
            alpha: 1,
            color: s()
        }), t.body.appendChild(a)
    }
    function c(e) {
        var a = t.createElement("style");
        a.type = "text/css";
        try {
            a.appendChild(t.createTextNode(e))
        } catch (t) {
            a.styleSheet.cssText = e
        }
        t.getElementsByTagName("head")[0].appendChild(a)
    }
    function s() {
        return "rgb(" + ~~(255 * Math.random()) + "," + ~~(255 * Math.random()) + "," + ~~(255 * Math.random()) + ")"
    }
    var d = [];
    e.requestAnimationFrame = function() {
        return e.requestAnimationFrame || e.webkitRequestAnimationFrame || e.mozRequestAnimationFrame || e.oRequestAnimationFrame || e.msRequestAnimationFrame || function(e) {
                setTimeout(e, 1e3 / 60)
            }
    }(), n()
}(window, document);
```
- 修改配置：在文件 `hexo\themes\next\layout\_layout.swig` 底部的 `</body>` 标签上一行增加：

```
<!-- 页面点击小红心 -->
<script type="text/javascript" src="/js/src/love.js"></script>
```
- 实际效果:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/out1.gif)

#### 设置背景动画
编辑 `主题配置文件`， 搜索 `canvas_nest` 或 `three_waves`，根据您的需求设置值为 true 或者 false 即可（会干扰读者注意力，建议关闭）：

```
# Canvas-nest
canvas_nest: true
# three_waves
# three_waves: true
# canvas_lines
# canvas_lines: true
# canvas_sphere
# canvas_sphere: True
```

`Canvas-nest` 的实际效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/aa.gif)

### Next 的其他样式设置

- [去除 Next 主题图片的灰色边框](https://realneo.me/remove-next-gray-border/)
- [Hexo下表格的美化和优化](https://hexo.imydl.tech/archives/6742.html)
- [Hexo之NexT主题代码块MacPanel特效配置](http://wiki.johnhao.tech/Hexo%E4%B9%8BNexT%E4%B8%BB%E9%A2%98%E4%BB%A3%E7%A0%81%E5%9D%97MacPanel%E7%89%B9%E6%95%88%E9%85%8D%E7%BD%AE/)
- 表格宽度根据内容自适应：可以尝试将 source/css/_common/scaffolding/tables.styl 中的 table-layout: fixed; 改为 table-layout: auto;

## 第三方插件使用
静态站点拥有一定的局限性，因此我们需要借助于第三方服务来扩展站点的功能。 以下是 NexT 目前支持的第三方服务，你可以根据你的需求集成一些功能进来。

### 添加站内搜索
配置方法如下：

- 安装 `hexo-generator-searchdb`，在站点的根目录下执行以下命令：
 
```
npm install hexo-generator-searchdb --save
```

- 编辑站点配置文件，新增以下内容到任意位置：

```
search:
 	  path: search.xml
 	  field: post
 	  format: html
 	  limit: 10000
```

- 编辑主题配置文件，启用本地搜索功能：

```
# Local search
local_search:
   enable: true
```
- 站点搜索效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315111338.png)

### 添加评论区
NexT 支持多款评论系统：

1. 多说：已挂；
2. 畅言：需要备案；
3. Disqus：已墙；
4. valine：LeanCloud提供的后端云服务，可用于统计网址访问数据，分为开发版和商用版，只需要注册生成应用App ID和App Key即可使用；
5. 来必力：来自韩国，使用邮箱注册；
6. Gitment：一款基于 `GitHub Issues` 的评论系统，支持在前端直接引入，不需要任何后端代码。可以在页面进行登录、查看、评论、点赞等操作，同时有完整的 `Markdown / GFM` 和代码高亮支持，尤为适合各种基于GitHub Pages的静态博客或项目页面；

#### DISQUS
编辑 `主题配置文件`， 将 `disqus` 下的 `enable` 设定为 `true`，同时提供您的 `shortname`，`count` 用于指定是否显示评论数量：

```
disqus:
  enable: false
  shortname:
  count: true
```

需要注册 `disqus` 账号后才可参与评论，效果如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315111715.png)

#### gitment
Gitment 使用 `GitHub Issues` 作为评论系统，在接入 Gitment 前，需要获得 GitHub 的授权，获得相应的客户端id和客户端私钥，以备站点使用。gitment 的配置方法:

- 创建 `oAuth App` ：`github首页` > `settings` > `Developer settings` > `OAuth Apps` > `New oAuth App`，`Homepage URL` 和 `Authorization callback URL` 都写上你的 github 博客首页地址（如果绑定了个人域名，则写完整的新域名地址），比如 `https://liketea.xyz`，点击 `Register application`即可完成注册，生成 `Client ID` 和 `Client Secret`；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315193518.png)
- 修改 `主题配置文件` ：最重要的就是 `github_repo`，可以是你托管博客静态文件的仓库，也可以是新仓库，注意是仓库名称而不是仓库地址；

```
gitment:
  enable: true
  mint: true # RECOMMEND, A mint on Gitment, to support count, language and proxy_gateway
  count: true # Show comments count in post meta area
  lazy: false # Comments lazy loading with a button
  cleanly: true # Hide 'Powered by ...' on footer, and more
  language: zh-CN # Force language, or auto switch by theme
  github_user: liketea # MUST HAVE, Your Github ID
  github_repo: liketea.github.io  # MUST HAVE, The repo you use to store Gitment comments
  client_id: a52dc...0f3b156f7c # MUST HAVE, Github client id for the Gitment
  client_secret: 2307d156a...a8495b1b68a3a3ae # EITHER this or proxy_gateway, Github access secret token for the Gitment
  proxy_gateway: # Address of api proxy, See: https://github.com/aimingoo/intersect
  redirect_protocol: # Protocol of redirect_uri with force_redirect_protocol when mint enabled
```
- 重新部署：通过 `hexo g -d` 重新部署站点，进入一篇文章的评论区；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315182559.png)
- 登入授权：点击登入，对评论区进行授权；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315182527.png)

- 解决无法登陆的问题：如果点击授权之后，评论区一直在转圈圈，但是登录不进去

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190316171023.png)
- 打开浏览器的调试功能，发现报了个错误~点击后面的网址，一路点击高级、继续前往

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190316171402.png)

- 然后你会发现依旧访问不了，不过不用理会，此时gitment已经可以登录啦~

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190316172829.png)

- 最后初始化评论：每一篇文章都需要进行初始化才能开始评论，目前还没有较好的一键初始化方法；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190316171555.png)

#### 来必力
以上评论系统，要么已经挂掉了、要么被墙了、要么各种BUG、要么原始界面奇丑，通过各种尝试发现还是来必力最好用：

- 注册登陆 [来必力](http://www.laibili.com.cn) 获取你的 `LiveRe UID`：点击安装免费的city版本，安装成功后点击代码管理，复制其中的 `data-uid` 字段

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552725793366.jpg)

- 编辑主题配置文件，填写 `livere_uid`：将复制的 `data-uid`
 
```
# You can get your uid from https://livere.com/insight/myCode (General web site)
livere_uid: "MTAyMC80M...Tc0NQ=="
```
- 实际效果：来必力支持使用已有社交网站(SNS)账号登录

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552744311918.jpg)

### 添加统计分析
#### 统计文章阅读次数
LeanCloud 可以统计单篇文章阅读次数，配置过程如下:

- 注册 [LeanCloud](https://leancloud.cn/)：完成邮箱激活，进入控制台页面；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315145826.png)

- 创建应用：创建一个新应用，名称无所谓，点击应用进入；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315145939.png)
- 创建名称为Counter的Class：名称必须为Counter；
- 查看应用 key：在所创建的应用的`设置->应用key` 中查看 `app_id` 和` app_key` ；
- 修改主题配置文件：

```
leancloud_visitors:
  enable: true
  app_id: m135LmdEWo9GrD-gzGzoHsz
  app_key: CWheAQhgeEYEa1nDYn
```
- 重新部署 Hexo 博客：重新部署后便可以在博客主页以及每篇文章中显示阅读次数，如图所示

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315161834.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315150436.png)

说明：

1. 为了安全，设置网站的安全域名：设置——安全中心——Web安全域名；
2. 记录文章访问量的唯一标识符是文章的发布日期以及文章的标题，因此请确保这两个数值组合的唯一性，如果你更改了这两个数值，会造成文章阅读数值的清零重计；

#### 添加文章阅读量排行榜
- 新建排行页面：在根目录路径下，执行 `hexo new page "rank"`；
- 编辑主题配置文件：加上菜单 rank 和它的 icon:

```
menu:
  rank: /rank/ || signal
```
- 在语言文件中加上菜单 rank，以中文为例，在 `/themes/next/languages/zh_Hans.yml` 中添加：

```
menu:
  home: 首页
  archives: 归档
  categories: 分类
  tags: 标签
  about: 关于
  search: 搜索
  schedule: 日程表
  sitemap: 站点地图
  commonweal: 公益404
  rank: 排行榜
```

 - 编辑~/source/top/index.md：必须将里面的里面的 `app_id` 和 `app_key` 替换为你的 `LeanCloud` 在主题配置文件中的值；必须替换里面博客的链接；1000 是显示文章的数量，其它可以自己看情况更改；

```js
---
title: 排行榜
comments: false
---
<div id="hot"></div>
<script src="https://cdn1.lncld.net/static/js/av-core-mini-0.6.4.js"></script>
<script>AV.initialize("app_id", "app_key");</script>
<script type="text/javascript">
  var time=0
  var title=""
  var url=""
  var query = new AV.Query('Counter');
  query.notEqualTo('id',0);
  query.descending('time');
  query.limit(1000);
  query.find().then(function (todo) {
    for (var i=0;i<1000;i++){
      var result=todo[i].attributes;
      time=result.time;
      title=result.title;
      url=result.url;
      var content="<p>"+"<font color='#1C1C1C'>"+"【文章热度:"+time+"℃】"+"</font>"+"<a href='"+"https://liketea.github.io/"+url+"'>"+title+"</a>"+"</p>";
      document.getElementById("hot").innerHTML+=content
    }
  }, function (error) {
    console.log("error");
  });
</script>
```
- 实际效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552762267890.jpg)

#### 统计站点访问次数
NexT 集成了“不蒜子服务”，可以统计站点 `uv`（全站访客人次）、`pv`（全站点击次数）和单页面 `pv`，配置更加方便。

- 编辑 `主题配置文件` 中的 `busuanzi_count` 配置项：当 `enable: true` 时，代表开启全局开关，若` site_uv` 、`site_pv` 、`page_pv` 的值均为 false 时，不蒜子仅作记录而不会在页面上显示

```
busuanzi_count:
  # count values only if the other configs are false
  enable: true
  # custom uv span for the whole site
  site_uv: true
  site_uv_header: <i class="fa fa-user"></i>
  site_uv_footer: 人次
  # custom pv span for the whole site
  site_pv: true
  site_pv_header: <i class="fa fa-eye"></i>
  site_pv_footer: 次
  # custom pv span for one page only
  page_pv: false
  page_pv_header: <i class="fa fa-eye"></i>
  page_pv_footer: 次
```

- 禁用单页面pv：不蒜子的 `单页面pv` 默认显示在文章标题下边，但是却不会在站点主页显示，因此我们还是选择用 `LeanCloud` 来显示 `单页面pv` 而使用不蒜子来显示 `站点uv, pv` ，实际效果如图所示：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315161052.png)

如果发现页面中的统计数据都不显示：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315162709.png)

那是因为不蒜子统计的js文件找不到了，官方给出了相应的方法，即只需要更改 next 主题下的不蒜子 插件的 js 引用链接即可。进入 hexo 博客项目的 themes 目录下，在 next 主题目录中的 `layout/_third-party/analytics/` 下找到 `busuanzi-counter.swig` 文件，将:

```js
<script async src="https://dn-lbstatics.qbox.me/busuanzi/2.3/busuanzi.pure.mini.js"></script>
```

替换为如下代码既可：

```js
<script async src="//busuanzi.ibruce.info/busuanzi/2.3/busuanzi.pure.mini.js">
</script>
```
#### 统计文章字数
- 安装插件:在根目录下安装 `hexo-wordcount`，运行：

```
$ npm install hexo-wordcount --save
```

- 修改主题配置文件：然后在主题的配置文件中，配置如下

```
# Post wordcount display settings
# Dependencies: https://github.com/willin/hexo-wordcount
post_wordcount:
  item_text: true  # 是否显示项目文字
  wordcount: true  # 是否显示统计字数
  min2read: true  # 是否显示阅读时长（分钟）
  totalcount: true  # 是否显示总字数
  separated_meta: true
```
- 实际效果:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552754006485.jpg)

### 添加分享服务
`jiathis` 已关闭服务，我采用了  `needmoreshare2`，其配置过程如下：

- 编辑主题配置文件中的 `needmoreshare2` ：将`enable` 设置为 `true`：

```
needmoreshare2:
  enable: true
  # 底部提交分享按钮
  postbottom:
    enable: false
    options:
      iconStyle: box
      boxForm: horizontal
      position: bottomCenter
      networks: Weibo,Wechat,Douban,QQZone,Twitter,Facebook
  # 左侧悬浮分享按钮 
  float:
    enable: true
    options:
      iconStyle: box
      boxForm: horizontal
      position: topRight
      networks: Weibo,Wechat,Douban,QQZone,Twitter,Facebook
```

- 实际效果如图，包含了微博、微信、QQ、豆瓣等众多渠道：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315170100.png)

以上只有微信点击无法分享，只需修改`themes\next\source\lib\needsharebutton\needsharebutton.js`：

```
# 把
var imgSrc = "https://api.qinco.me/api/qr?size=400&content=" + encodeURIComponent(myoptions.url);
# 改为
var imgSrc = "http://api.qrserver.com/v1/create-qr-code/?size=150x150&data=" + encodeURIComponent(myoptions.url);
```

该分享方式为生成博客的二维码，手机扫码之后即可分享:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190315170849.png)

## 为博客添加其他功能
### 文章加密访问
- 修改代码：打开主题文件夹/layout/_partials/head.swig
在首句<meta charset="UTF-8"/>后面插入以下代码：

```
<script>
    (function(){
        if('{{ page.password }}'){
            if (prompt('请输入文章密码') !== '{{ page.password }}'){
                alert('密码错误');
                history.back();
            }
        }
    })();
</script>
```
- 为文章设置密码：在需要加密的文章里加进password: 你要设的密码，像这样：

```
---
title: 13
date: 2019-03-14 21:06:14
tags:
categories:
password: 123456
---
```

- 实际效果：点击文章，需要输入正确密码
 
![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/out.gif)

### 文章置顶
- 修改 `hero-generator-index` 插件：把文件：`node_modules/hexo-generator-index/lib/generator.js` 内的代码替换为：

```
'use strict';
var pagination = require('hexo-pagination');
module.exports = function(locals){
  var config = this.config;
  var posts = locals.posts;
    posts.data = posts.data.sort(function(a, b) {
        if(a.top && b.top) { // 两篇文章top都有定义
            if(a.top == b.top) return b.date - a.date; // 若top值一样则按照文章日期降序排
            else return b.top - a.top; // 否则按照top值降序排
        }
        else if(a.top && !b.top) { // 以下是只有一篇文章top有定义，那么将有top的排在前面（这里用异或操作居然不行233）
            return -1;
        }
        else if(!a.top && b.top) {
            return 1;
        }
        else return b.date - a.date; // 都没定义按照文章日期降序排
    });
  var paginationDir = config.pagination_dir || 'page';
  return pagination('', posts, {
    perPage: config.index_generator.per_page,
    layout: ['index', 'archive'],
    format: paginationDir + '/%d/',
    data: {
      __index: true
    }
  });
};

```

- 在文章中添加 top 值：数值越大文章越靠前

```
---
title: 13
date: 2017-05-22 22:45:48
tags: 
categories: 
top: 100
---
```

### 添加网易云音乐
我将网易云音乐播放器放在了侧边栏，想要听的朋友可以手动点击播放，配置方法如下：

- 生成外链播放器：在[网页版网易云音乐](https://music.163.com)中搜索我们想要插入的音乐或歌单，然后点击“生成外链播放器”

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552759046750.jpg)

- 设置ifame插件参数：选择 `310x90`，取消勾选自动播放

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552758972772.jpg)

- 插入代码：将网易云音乐插件生成的 HDML 代码插入到文件 `themes\next\layout\_macro\sidebar.swig`
 中 `</aside>`上一行，类似于以下代码

```js
# auto=0 禁止网页打开自动播放
<div id="music163player">
    <iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=280 height=86 src="//music.163.com/outchain/player?type=2&id=38358214&auto=0&height=66">
    </iframe>
</div>
```

- 实际效果：可操作播放、暂停，上/下一曲，如果尺寸是 `310x413` 则可以展开播放列表

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552759256726.jpg)


## 参考

1. [hexo的next主题个性化教程:打造炫酷网站](http://shenzekun.cn/hexo%E7%9A%84next%E4%B8%BB%E9%A2%98%E4%B8%AA%E6%80%A7%E5%8C%96%E9%85%8D%E7%BD%AE%E6%95%99%E7%A8%8B.html)
2. [NexT官方文档](https://theme-next.iissnan.com/getting-started.html)
3. [NexT主题个性化设置](http://www.jeyzhang.com/next-theme-personal-settings.html)

