---
title: Hexo博客改造记
date: 2017-04-13 15:43:35
categories:
 - TechChatter
tags:
 - Hexo
 - Ubuntu
 - Linux
---

在年初搭博客的时候其实就有一堆的遗留问题，这两天一并解决了，顺带记录一下。

<!--more-->

## 公式兼容

其实在上一篇的博文里我遇到一个比较蛋疼的问题是公式的显示。我所使用的Hexo主题[Next](http://theme-next.iissnan.com/)是本身支持[MathJax](https://www.mathjax.org/)显示，只要在它原来的主题配置文件里面打开一个开关就可以了，蛋疼之处在于Hexo自己的渲染引擎和MathJax的语法冲突。因此直接替换了Hexo自带的渲染引擎，使用了[Pandoc](http://pandoc.org/)

操作也非常的无脑，首先根据[Pandoc安装指南](http://pandoc.org/installing.html)在机子上安装Pandoc

然后cd到Hexo网站根目录，卸载Hexo自带的渲染引擎

~~~bash
npm uninstall hexo-renderer-marked --save
~~~

再安装pandoc的渲染引擎

~~~bash
npm install hexo-renderer-pandoc --save
~~~

搞定

## 多说替换为云跟帖

我刚用多说才没几个月，它就要下线了（估计是这个项目实在赚不到什么钱吧）。能让广大群众免费这么久也是不容易，在此对多说说一声谢谢。只能说自己没有赶上好时候啊。

我想网易养猪场的[云跟贴](https://gentie.163.com/)应该不那么容易倒闭吧，所以就把多说删了迁移到网易上来了（其实好像也没人评论囧），只希望对小站用户能一直免费下去吧。也是该一行代码就完事。具体参照[Next第三方服务接入说明](http://theme-next.iissnan.com/third-party-services.html)


## 流量统计

在流量统计上，加上了大疼讯的[腾讯分析](http://ta.qq.com/)。也是在Next主题里修改一行代码就好，参照[Next第三方服务接入说明](http://theme-next.iissnan.com/third-party-services.html)。

同时加上了基于LeanCloud的阅读量统计。讲真LeanCloud这家公司还是挺不错的，它的[开放资源](https://open.leancloud.cn/)很赞，看得出来这是一家有心做事的公司。最早先的时候公司后端我曾经考虑直接架在LeanCloud上，后面因为可扩展性的考虑还是用了阿里云。现在自己的博客上搭上了它，也算是念念不忘必有回响吧。接入方法参考[Next接入LeanCloud统计](https://notes.wanghao.work/2015-10-21-%E4%B8%BANexT%E4%B8%BB%E9%A2%98%E6%B7%BB%E5%8A%A0%E6%96%87%E7%AB%A0%E9%98%85%E8%AF%BB%E9%87%8F%E7%BB%9F%E8%AE%A1%E5%8A%9F%E8%83%BD.html#%E9%85%8D%E7%BD%AELeanCloud)。

[Next](http://theme-next.iissnan.com/)真是便利啊！

## 全站https

我打算使用[Let's Encrypt](letsencrypt.org)结合[Nginx](https://www.nginx.com)来实现全站https。根据指引直接使用了[acme-nginx](https://github.com/kshcherban/acme-nginx)

安装[acme-nginx](https://github.com/kshcherban/acme-nginx)

~~~bash
pip install acme-nginx
~~~

使用

~~~bash
sudo acme-nginx -d zjuturtle.com
~~~

然后修改Nginx的配置，注意这里使用重定向强制http的访问变成了https

~~~
server {
    # listen to 80 HTTP port
    listen 80;
    server_name zjuturtle.com;
    return 301 https://$server_name$request_uri;
}
server {
        # listen 80 default_server;
        # listen [::]:80 default_server;

        # SSL configuration
        #
        listen 443 ssl default_server;
        ssl on;
        listen [::]:443 ssl default_server;
        ssl_certificate /etc/ssl/private/letsencrypt-domain.pem;
        ssl_certificate_key /etc/ssl/private/letsencrypt-domain.key;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ...
~~~

最后，因为[Let's Encrypt](letsencrypt.org)的证书3个月就过期，因此再加一个排期的任务，每月自动续签。即在/etc/下新建一个文件，填入如下内容

~~~
12 11 10 * * root /usr/local/bin/acme-nginx -d zjuturtle.com >> /var/log/letsencrypt.log
~~~

真的好方便。。。




