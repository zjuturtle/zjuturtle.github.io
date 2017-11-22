---
title: 博客平台更换
date: 2017-11-20 23:26:59
categories:
 - TechChatter
tags:
 - Hexo
---

今年穷，租不起服务器了，所以只能把博客整体搬到 Github 上。另外之前用的网易云跟贴也跪了（我真是用一家倒一家）。本来是打算用 [Gitment](https://imsun.github.io/gitment/) 不过作者似乎弃坑了。所以现在用 [Gitalk](https://gitalk.github.io/) 替代评论系统。Next 主题下目前（截止 2017.11.20）已经有 Gitalk 的 [Pull request](https://github.com/iissnan/hexo-theme-next/pull/1814)，不过似乎还是有各种 bug (我试过了)。估计过段时间就会接入正式版本吧。在这之前还是得自己动手。讲道理应该说的详细一点，不过 Hexo 部署到 github pages 上的教程网上多如牛毛，就不在废话了（其实是当初搞的时候忘记了记下来了现在懒得回去弄了）

<!--more-->

## Gitalk 配置

我是根据这个[博客](http://www.whtis.com/2017/10/19/%E7%BB%99hexo%E5%8D%9A%E5%AE%A2nexT%E4%B8%BB%E9%A2%98%E6%B7%BB%E5%8A%A0Gitalk%E8%AF%84%E8%AE%BA%E7%B3%BB%E7%BB%9F/)来手动配置的。

### 申请 Github 的 Application

如果没有申请的话，可以直接[点这里](https://github.com/settings/applications/new)申请。注意填写信息时的 `Authorization callback URL` 这一项需要填正确的博客地址（比如我填的是 `https://zjuturtle.com`）。

在申请后，要记下 `Client ID` 和 `Client Secret` 两个信息，后面会用到。

### Next 主题修改

我们需要修改 Next 主题下的 4 个文件 

* `layout/_third-party/comments/gitalk.swig`
* `layout/_third-party/comments/index.swig`
* `layout/_partials/comments.swig`
* `_config.yml`

注意原博客的变量名有点问题，这里做了一点基本的修改。

-------

### `layout/_third-party/comments/gitalk.swig` 文件

直接新建一个名为 `gitalk.swig` 的文件，并填入以下内容

~~~html
{% if not (theme.duoshuo and theme.duoshuo.shortname) and not theme.duoshuo_shortname %}
{% if theme.gitalk.enable and theme.gitalk.client_id %}
<!-- LOCAL: You can save these files to your site and update links -->
  {% set CommentsClass = "Gitalk" %}
  <link rel="stylesheet" href="https://unpkg.com/gitalk/dist/gitalk.css">
  <script src="https://unpkg.com/gitalk/dist/gitalk.min.js"></script>
<!-- END LOCAL -->
    {% if page.comments %}
      <script type="text/javascript">
      function renderGitalk(){
        var gitalk = new {{CommentsClass}}({
            owner: '{{ theme.gitalk.owner }}',
            repo: '{{ theme.gitalk.repo }}',
            clientID: '{{ theme.gitalk.client_id }}',
            clientSecret: '{{ theme.gitalk.client_secret }}',
            admin: '{{ theme.gitalk.admin }}',
            {% if theme.gitalk.distraction_free_mode %}
              distractionFreeMode: '{{ theme.gitalk.distraction_free_mode }}'
            {% endif %}
            });
        gitalk.render('gitalk-container');
      }
      renderGitalk();
      </script>
    {% endif %}
{% endif %}
{% endif %}
~~~

-------


### `layout/_third-party/comments/index.swig` 文件

在该文件加入一行代码

~~~html
{% include 'gitalk.swig' %}
~~~


-------


### `layout/_partials/comments.swig` 文件

在差不多文件末尾的地方加上

~~~html
{% elseif theme.gitalk.enable %}
    <div class="comments" id="comments">
      <div id="gitalk-container"></div>
    </div>
~~~

-------

### `_config.yml` 文件

在这个文件加入以下设置项，并填入相关信息。

~~~yml
# Gitalk
# more info please open https://github.com/gitalk/gitalk
gitalk:
  enable: true
  client_id: # your github application id
  client_secret: # your github application secret
  repo:  # your repo. Such as zjuturtle.github.io
  owner: # your github username. Such as zjuturtle
  admin: # People(github username) who have write permission to blog repo. Use commas to separate. 
  distraction_free_mode: false
~~~

__Tips:如果出现 '未找到相关的 Issues 进行评论' 的字样，则登陆 GitHub 授权即可__

## SSL 实现

因为博客托管在 Github 上，所以在实现 SSL 上有点麻烦（毕竟不能直接）。我借助的是 [cloudflare](https://www.cloudflare.com/) 曲线救国的方式来实现的，虽然严格来说不能算是全链路 https，但起码不会被无良运营商夹带私货。

### 一些基本的修改

最好是能先修改 Hexo 博客的部署方式。在站点目录下的 `_config.yml` 文件里修改如下内容

~~~yml
deploy:
  type: git
  repo: https://github.com/[username]/[username].github.io.git
  branch: master
~~~

然后把博客的源代码切换至其他分支（我用的是source）。这样每一次的部署只要运行以下命令就可以了

~~~bash
hexo clean
hexo generate
hexo d
~~~

### Cloudfare 设置步骤

设置步骤基本参照了[这个博客](https://g2ex.github.io/2015/10/14/Hexo-with-SSL-Hosted-on-Github-Page/)。

我们要做以下几步工作

1. 注册 [`Cloudflare`](https://www.cloudflare.com)，添加个人网站
2. 获取 `Cloudflare` 的 `Domain Name Server`
3. 在域名提供商处修改自己域名的 `Domain Name Server` 为 2 所获取的 DNS
4. 在 CloudFlare 的 Crypto 中开启 SSL 加密，选择 `flexible` (似乎 `full` 也可以？)
5. 在 CloudFlare 的 Crypto 中设置 Always use HTTPS
6. 在 GitHub 仓库设置中设置自定义域名

在 Cloudflare 的 Crypto 上我用的是 `Full` 模式。而在 DNS 界面上，我的信息是这样的

{% asset_img cloudflare_dns.jpg %}


大体思路就这样，当初没有具体详细的记录每一步，现在懒得回去再弄了。。。实际上 Cloudflare 上还有很多设置可以玩，大家可以自行研究下。




