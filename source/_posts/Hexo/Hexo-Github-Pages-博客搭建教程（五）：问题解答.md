---
title: Hexo + Github Pages 博客搭建教程（五）：问题解答
date: 2019-03-10 14:03:45
tags:
    - "搭建博客"
    - "教程"
categories:
    - "搭建博客"
---
![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/f32be74b5abb4a05b57a37a2141e80a4.jpeg)

## 百度和Google收录
使用 `GitHub + Hexo` 搭建的博客，默认只能你自己能看到，别人是无法通过百度、谷歌等搜索引擎搜索到的:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553065501429.jpg)

可以手动将自己的博客站点提交给百度、谷歌的搜索引擎，这样就可以通过百度或谷歌搜索到自己的博客内容了：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553086521591.jpg)

### 百度收录

百度无法搜索到博客信息，是因为 Github Pages 屏蔽了百度爬虫。

#### 验证站点
登录[百度搜索资源平台](https://ziyuan.baidu.com)>用户中心>站点管理>添加网站，输入网站域名，选择站点属性，到第三步“验证网站”：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553082150167.jpg)

有三种不同的验证方式：文件验证、HTML标签验证、CNAME验证。这里我们选择文件验证，下载验证文件到本地，放置在 `themes/next/source`目录下，执行生成和部署命令：

```
$ hexo g -d
```

然后点击完成验证即可：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553065459196.jpg)

#### 添加站点地图
站点地图（sitemap）可以告诉搜索引擎网站上有哪些可供抓取的网页，以便搜索引擎可以更加智能地抓取网站。

- 安装百度和谷歌站点地图生成插件：cd 到你的站点目录，执行以下命令

```
$ npm install hexo-generator-baidu-sitemap --save
$ npm install hexo-generator-sitemap --save
```

- 修改 url：修改站点配置文件 `_config.yml` 中的 `url` 参数:

```
url: http://jonzzs.cn # 修改成你博客的首页地址
root: /
permalink: :year/:month/:day/:title/
permalink_defaults:
```

- 修改配置文件：修改站点配置文件 `_config.yml`，添加以下内容：

```
# 自动生成sitemap
sitemap:
  path: sitemap.xml
baidusitemap:
  path: baidusitemap.xml
```

- 生成和部署：执行生成和部署命令后，进入public目录，你会发现里面有 `sitemap.xml` 和`baidusitemap.xml` 两个文件，这就是生成的站点地图，前者用来提交给谷歌，后者用来提交给百度

```
$ hexo g -d
```

- 自动推送站点地图：在百度资源搜索平台，找到链接提交，这里我们可以看到有两种提交方式，自动提交和手动提交，自动提交又分为主动推送、自动推送和sitemap，自动推送配置最简单，将主题配置文件下的 `baidu_push` 设置为 `true`：

```
# Enable baidu push so that the blog will push the url to baidu automatically which is very helpful for SEO
baidu_push: true
```

百度收录网站到此配置结束，只需要等待百度收录，这个过程会比较久。

### 谷歌收录
#### 验证站点
登陆[Google网站站长](https://www.google.com/webmasters/#?modal_active=none) > 进入Search Console > 添加资源：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553085549734.jpg)

我们选择 HTML 文件上传的方式验证，下载验证文件到本地，放置在 `themes/next/source`目录下，执行生成和部署命令：

```
$ hexo g -d
```
部署完成之后，进行验证即可：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553084916927.jpg)

#### 添加站点地图
安装插件、修改配置文件在上述百度收录过程已经做过了，现在只需要点击前往站点资源页面 > 点击站点地图，添加新的站点地图 `sitemap.xml`：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1553085912959.jpg)

即可完成谷歌收录网站，只需要等待谷歌收录，这个过程会比较久，成功收录后的效果如下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20201125111005.png)


## github 托管博客原始文件

Hexo生成的博客静态网页会被自动托管到 github，我们同样可以通过 github 来实现对博客原始文件的版本管理，这样我们就可以随时随地地将博客迁移至新的电脑，在新的电脑上继续我们的创作了。

Hexo生成的文件里面是有一个`.gitignore`的，所以它的本意应该也是想我们把这些文件放到GitHub上存放的，但如果用额外一个仓库来存放这些文件会显得冗余，我们完全可以在同一个仓库中使用不同分支来分别存放生成的静态网页和原始文件（分支名可以自己决定）：

1. master 分支：用于存放网页发布的静态文件，当执行 `hexo d` 时实际上是将生成的静态网页push到github远程仓库的master分支中去，并使用master分支的文件通过git pages生成博客页面，由于这些过程都是Hexo自动完成的，我们没有必要在本地仓库显式地创建 master 分支；
2. files 分支：用于存放原始文件(博客文件、图片、配置文件等)，由于我们需要手动管理这个分支，可以将 github 中的files分支设置为默认分支，这样每次通过 `git pull` 合并远程分支时默认都是从origin/files分支获取的；

以上是git管理博客文件的答题思路，下面来看看在具体场景下的操作。

### 将博客原始文件同步到github

- 默认情况下，Hexo 博客目录应该已经是一个本地 git 仓库了(包含.git)，且已经将静态网页所存放的远程仓库添加为了远程仓库，否则你需要先将静态网页关联的github仓库添加为博客本地仓库的远程仓库：

```
# 创建本地仓库
$ git init
$ git add -A
$ git commit -m "创建本地仓库"
# 添加远程仓库
$ git remote
$ git remote add origin https://github.com/paulboone/ticgit
```

- 创建新的分支：

```bash
# 创建新的分支
$ git branch files
# 创建远程分支
$ git push origin files:files
```

- 修改 `.gitignore` 文件：默认`.gitignore`文件中过滤了以下文件，这些文件都是被动生成的，不用托管

```
# mac版本文件
.DS_Store
Thumbs.db
db.json
*.log
# npm依赖包，不用托管，npm install 会自动下载
node_modules/
# hexo g 生成的静态网页文件
public/
# hexo d 生成的版本管理文件
.deploy*/%
```

- 新增忽略规则：如果在提交了之后，希望在`.gitignore`文件中添加新的过滤规则，除了修改`.gitignore`文件外，还需要清除缓存后重新添加并提交

```
git rm -r --cached .
git add .
git commit -m 'update .gitignore'
```

- 将子仓库转化为正常文件：如果你是通过 git clone 拷贝的 `themes/next`，next目录就会作为一个子仓库嵌套在博客仓库内，在push或pull时会发现next目录虽有但是空的，这是因为外层仓库是不会跟踪内层仓库的变化的，这需要将内层仓库转化为普通目录，除此之外还需要将next目录移出-提交-移入-提交，否则博客仓库也还是无法将其纳入版本控制

```zsh
$ cd themes/next
# 删除 .git 文件
$ rm -rf .git
# 移出next后
$ git add -A
$ git commit -m "移出next"
# 移入next
$ git add -A 
$ git commit -m "移入next"
# 同步到远程仓库
$ git push origin files:files
```

本地分支只有一个`files`，但有两个远程分支 `origin/files` 和 `origin/master`：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190913213734.png)


### 在新电脑上部署博客
先安装好homebrew，再安装 node 和 hexo：

```
# 安装node
$ brew install node
$ node -v
v8.4.0

# 安装 hexo
$ npm install -g hexo-cli
$ hexo version
hexo-cli: 1.1.0
os: Darwin 18.0.0 darwin x64
```


克隆远程仓库到本地：

```
$ git clone ***
```

进入仓库目录，安装依赖：不要 `hexo init` 会覆盖博客配置文件 `_config.yml`，npm install 安装过程可能会报错，忽略就行

```
# 安装npm依赖
$ cd <folder>
$ npm install

# 安装启动服务
$ npm install hexo-server --save
# 安装部署服务
$ npm install hexo-deployer-git --save
```

### 新的工作流

```
# 1. 创建文章
$ hexo new filename

# 2. 编辑文章
# 3. 发布文章
$ hexo g -d
# 4. 上传原始文件
$ git commit -a -m "更新了一篇文章"
$ git push 
```

### hexo next主题解决无法显示数学公式
https://blog.csdn.net/yexiaohhjk/article/details/82526604

#### 问题
Hexo 默认使用 hexo-renderer-marked 引擎渲染网页，该引擎会把一些特殊的 markdown 符号转换为相应的 html 标签，比如在 markdown 语法中，下划线`_`代表斜体，会被渲染引擎处理为`<em>`标签。

因为类 Latex 格式书写的数学公式下划线_表示下标，有特殊的含义，如果被强制转换为`<em>`标签，那么 MathJax 引擎在渲染数学公式的时候就会出错，类似的语义冲突的符号还包括`*, {, }, \\`等。

#### 解决
- 更换 Hexo 的 markdown 渲染引擎：hexo-renderer-kramed 引擎是在默认的渲染引擎 hexo-renderer-marked 的基础上修改了一些 bug ，两者比较接近，也比较轻量级。执行下面的命令即可，先卸载原来的渲染引擎，再安装新的：

```
npm uninstall hexo-renderer-marked --save
npm install hexo-renderer-kramed --save
```

- escape、em 变量修改：引擎后行间公式可以正确渲染了，但是这样还没有完全解决问题，行内公式的渲染还是有问题，因为 hexo-renderer-kramed 引擎也有语义冲突的问题。接下来到博客根目录下，找到node_modules\kramed\lib\rules\inline.js，把第11行的 escape 变量的值以及第20行的em变量做相应的修改

```
//escape: /^\\([\\`*{}\[\]()#$+\-.!_>])/,
escape: /^\\([`*\[\]()#$+\-.!_>])/,
```

- 在 Next 主题中开启 MathJax 开关：如果使用了主题了，别忘了在主题（Theme）中开启 MathJax 开关，下面以 next 主题为例，介绍下如何打开 MathJax 开关。进入到主题目录，找到 _config.yml 配置问题，把 math 默认的 false 修改为true：

```
# MathJax Support
mathjax:
  enable: true
  per_page: false
  engine: mathjax
  cdn: //cdn.bootcss.com/mathjax/2.7.1/latest.js?config=TeX-AMS-MML_HTMLorMML
```

- 如果希望只有在用到公式的页面才加载 Mathjax，这样不需要渲染数学公式的页面的访问速度就不会受到影响，可以将per_page设置为true，然后再需要加载mathjax的md文件头部加上`mathjax: true`：

```
---
title: index.html
date: 2018-07-05 12:01:30
tags:
mathjax: true
--
```

最终效果：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191231143732.png)

### 在手机无法打开博客
博客在某些网络中无法访问，原因可能是 gitpage 被墙，解决办法：

- 在[站长工具-DNS查询](https://tool.chinaz.com/dns/?type=1&host=liketea.xyz&ip=)输入博客网址如`liketea.xyz`，查询响应 IP

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20201230213808.png)

- 修改电脑 hosts 文件，以 MAC为例：

```zsh
(base) ➜  ~ sudo vim /etc/hosts
Password:
# 将查询到的 IP 和域名写到这里
185.199.109.153 liketea.xyz
```

刷新博客网站即可正常访问。

## 参考

1. [Hexo博客提交百度和Google收录](https://www.jianshu.com/p/f8ec422ebd52)
2. [百度资源平台](https://ziyuan.baidu.com)
3. [Google网站站长](https://www.google.com/webmasters/#?modal_active=none)