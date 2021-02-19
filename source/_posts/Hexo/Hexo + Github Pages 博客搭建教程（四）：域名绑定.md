---
title: Hexo + Github Pages 博客搭建教程（四）：域名绑定
date: 2019-03-11 14:03:45
tags:
    - "搭建博客"
    - "教程"
categories:
    - "搭建博客"
---

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314214524.png)

## 购买域名
`Github Pages` 的默认域名是 `<your_name>.github.io`， 如果想将默认域名修改为个人域名，首先你要拥有一个自己的域名，如果还没有，可在以下几个网站购买：

- [阿里云域名注册](https://wanwang.aliyun.com/)
- [腾讯云域名注册](https://buy.cloud.tencent.com/domain)
- [GoDaddy](https://sg.godaddy.com/zh/)

## 绑定域名
如果你已经购买了域名，绑定已有域名需要分别在“域名解析服务商”和 “Github” 两边进行设置。

### 域名解析配置
将域名和其他域名进行绑定，让你可以通过不同域名访问同一个网站。因为我是在腾讯云上买的域名，就用腾讯云的域名解析服务了。

[腾讯云控制台](https://console.cloud.tencent.com/) > [云解析](https://console.cloud.tencent.com/cns) > 解析 > 修改 > 添加记录：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314214203.png)

- 主机记录：`@` 表直接解析主域名；
- 记录类型：`CNAME` 将域名指向另一个域名，再由另一个域名提供 ip ；
- 线路类型：选默认；
- 记录值：填写一个域名，即你原有的Github Pages 访问地址；
- TTL：缓存默认时间，默认600s；

### Github 设置
进入你的仓库 `<your_name>.github.io` ，点击 `Settings` ，在 Github Pages设置项中将 `Custom domain` 设置为你的个人域名：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/20190314214240.png)

这时会在你的仓库目录下自动生成一个 `CNME` 文件，里面存放着你的个人域名。

上面的方式有一个问题，那就是你每次部署站点时 `CNME`都会自动消失，还需要你手动再设置一遍，所以为了方便，可以直接将 `CNME` 存放在 `source` 目录下，每次部署就会一同上传了。

完成以上设置之后，可以在浏览器中输入你自己的域名即可访问你的博客了：

![](https://likeitea-1257692904.cos.ap-guangzhou.myqcloud.com/liketea_blog/1552754255288.jpg)

## 参考
1. [Github pages 绑定个人域名](https://segmentfault.com/a/1190000011203711)
2. [腾讯云COS](https://cloud.tencent.com/)