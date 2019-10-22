---
title: Sublime 配置
tags: 
    - 教程
categories:
    - 工具
---

## 快捷键

```
ctrl + ` 调出调出console

command+shift+p 打开命令模式

```


## 安装插件
首先安装[Package Control](https://packagecontrol.io/installation)，通过Package Control安装插件的三个步骤：

- Command+shift+p调出命令面板；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915160550.png)

- 在输入框输入install，然后点击`Package Control:install package`

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915160624.png)

- 在弹出的新的输入框中输入想要下载的插件名，点击对应插件即可开始下载

### 编码转化——ConvertToUTF8
直接在菜单栏中可以转了，专为中文设计，妈妈再也不通担心中文乱码问题了:

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915160938.png)

### 侧边栏右键增强——Side​Bar​Enhancements
右键一下子多处那么多选择：
![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915161545.png)

### 比较文件差异——Compare Side-By-Side
在待比较的Tab上右键选择`Compare with...`，然后选择另一个打开的比较对象即可，Sublime会自动弹出新的窗口显示两个文件:

### 管理主题——ColorSublime
安装完可以使用在控制面板中输入`colorsublime`，点击`install theme`，移动上下箭头就可以预览，回车即可安装：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915162546.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190915162618.png)


## 修改sublime配置
与一般应用软件不同，Sublime Text的用户自定义设置不是在UI界面上直接点击选择，而是通过更改一个json格式的文档来完成自定义设置。点击菜单栏选项Preferences -> Settings，即会新打开一个左右分栏的窗口(tips：所有设置是即时生效的，当保存/发生更改时配置文件会自动刷新，甚至包括字号的大小)：

- 左栏是Preferences.sublime-settings — Default，为软件的默认设置模板(注释包含详细说明)，无法更改，仅供用户查找可设置项；
- 右栏是Preferences.sublime-settings — User，为用户自定义设置文档，保存在本机中(标题栏路径可查)，按照左栏默认设置的格式，对需要设置的项目进行声明，即可完成设置；

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191008155735.png)

### 在当前窗口打开新的文件

Windows/Linux下的sublime总是默认的以标签页的形式打开关联的文件，但是在Mac下使用Sublime打开文件，总是使用新窗口。

```
# 解决办法，见上面截图
Preferences -> Settings – User -> 添加 "open_files_in_new_window": false,
```

## 参考

- [Sublime Text 系列](https://www.jianshu.com/p/d1b9a64e2e37)