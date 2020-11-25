---
title: Mac OSX 配置JAVA环境
date: 2019-10-22 22:27:53
tags:
categories:
---


![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022222214.png)

## 安装 JAVA 环境
### 下载安装JDK
检查一下是不是已经安装了Java：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221610.png)

点击更多信息后直接跳转到JDK[下载页](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)，下载完 jdk 后直接双击点开，按照提示走完步骤。

```
# 检查java是否安装成功
➜  ~ java -version
java version "1.8.0_211"
Java(TM) SE Runtime Environment (build 1.8.0_211-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.211-b12, mixed mode)
```

### 配置环境变量

查看JAVA_HOME安装路径：

```
➜  ~ /usr/libexec/java_home -V
Matching Java Virtual Machines (1):
    1.8.0_211, x86_64:	"Java SE 8"	/Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home

/Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home
```

如果使用了oh_my_zsh，打开.zshrc配置文件：

```
$ cd
$ vi .zshrc
# 编辑
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home"
export PATH=".$PATH:$JAVA_HOME/bin"
export CLASS_PATH="$JAVA_HOME/lib"
```

## 下载安装 IntelliJ IDEA

公司IT服务[下载地址](http://8000.oa.com/#/searchDetail?keyword=intelliJ%20IDEA)

## 配置maven

### 安装maven：

```
# 安装
brew install maven
# 验证
mvn -v
➜  conf mvn -v
Apache Maven 3.6.2 (40f52333136460af0dc0d7232c0dc0bcf0d9e117; 2019-08-27T23:06:16+08:00)
Maven home: /usr/local/Cellar/maven/3.6.2/libexec
Java version: 1.8.0_211, vendor: Oracle Corporation, runtime: /Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home/jre
Default locale: zh_CN, platform encoding: UTF-8
OS name: "mac os x", version: "10.14", arch: "x86_64", family: "mac"
```

### mac配置maven

- 配置环境变量：如果是用homebrew安装的，则会自动配置，否则将Maven home的路径添加到M2_HOME

```
# 配置maven环境变量
export M2_HOME="/usr/local/Cellar/maven/3.6.2/libexec"
export PATH=$PATH:$M2_HOME/bin
```

- mac配置settings.xml：如果两者都存在，它们的内容将被合并，并且用户范围的settings.xml会覆盖全局的settings.xml
    - 全局配置，对操作系统的所有使用者生效：/usr/local/Cellar/maven/3.6.2/libexec/conf/settings.xml
    - 用户配置，只对当前操作系统的使用者生效：${user.home}/.m2/settings.xml

### intelliJ配置maven
- intelliJ配置maven：Preferences->Build,Execution,Deployment->Build Tools->Mavent

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221727.png)

## 导入maven项目
如果已经打开了一个项目，可以选择File->Close Project关闭当前项目，回到主界面，点击Import Project，或者点击 `File->New->Project From Existing Sources...`：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221752.png)

![](/media/15718138187400.jpg)


 选择主pom文件，然后确定：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221812.png)

勾选“auto”自动导入maven项目，先不要next，还要选择环境配置：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221823.png)

在跳出来的对话框页面，第一个选择到本地maven的插件，后面两个是setting.xml文件和映射到的仓库地址，可以默认。如果有自己的settings文件，可以选择 override 然后指定自己的settings.xml或者将自己的settings.xml文件拷贝到默认路径下：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221840.png)

点击OK->一路NEXT：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221902.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221918.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221926.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221938.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022221946.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022222009.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022222018.png)

然后等一段时间，项目会自己从maven上下载依赖，并构建工程。等待工程构建完毕后打开`View->Tool Windows-> Maven Projects`，右侧就会打开一个maven工程的构建窗口，打开目录树big_dataàLifecycle双击package，就会执行jar包的打包动作：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022222117.png)

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20191022222138.png)

IDEA下方的信息窗口显示BUILD SUCCESS，则表示代码打包成功，可以上传到TDW平台运行，其中出现问题导致项目构建失败或者打包失，多半都是环境配置问题。

