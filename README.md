# 更新备忘录

git master 分支存储部署程序，source 分支存储源码。所有的操作均在 source 分支下。文章/图片等均在 `source` 目录下，next 的主题在 `themes` 目录下。

SSL 相关设置在 [cloudflare](https://www.cloudflare.com/)，域名在[阿里云](https://www.aliyun.com)

## 更新步骤

1. 清空整个文件夹（称之为根目录），重新安装最新的 [Node.js](https://nodejs.org/en/) 和 [hexo](https://hexo.io/)
2. 下载最新版本的 [Next 主题](https://github.com/next-theme/hexo-theme-next)
3. 下载最新版本的 [pandoc](https://github.com/jgm/pandoc/releases/)
4. 在一个空的文件夹执行 `hexo init .`，同时把 Next 主题和之前的 source 文件夹复制进去，再放回根目录
5. 在根目录执行 `npm uninstall hexo-renderer-marked --save` 卸载 hexo 自带的公式渲染器
6. 在根目录执行 `npm install hexo-renderer-pandoc --save` 安装 pandoc 渲染器
7. 在根目录执行 `npm install hexo-deployer-git --save`
8. 在根目录执行 `npm install gitalk --save`，参考[这里](https://github.com/gitalk/gitalk)
9. 修改最外层的 `_config.yml` 文件
10. 修改 `themes/next/_config.yml` 文件
11. 在根目录执行 `hexo clean && hexo server` 测试一下
12. `hexo deploy --generate` 部署，密码在 Lastpass 的私人服务器里面。可能需要修改 `themes/next/layout/_third-party/comments/gitalk.swig` 文件，使得它能正常激活评论
13. 访问 [Github](https://github.com/zjuturtle/zjuturtle.github.io/settings) 修改成自己的域名
14. 切换 AnotherZjuturtle 账号初始化评论

## `_config.yml` 文件需要修改的地方

```yml
# Site
title: zjuturtle's blog
description: 瞎几把搞的幸运E
author: zjuturtle
language: zh-Hans

# URL
url: https://zjuturtle.com

# Writing
new_post_name: :year-:month-:day-:title.md # File name of new posts

# Extensions
## Plugins: https://hexo.io/plugins/
## Themes: https://hexo.io/themes/
theme: next

# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  - type: leancloud_counter_security_sync
  - type: git
    repo: https://github.com/zjuturtle/zjuturtle.github.io.git
    branch: master
```

## `themes/next/_config.yml` 文件

```yml
favicon:
  small: /images/favicon.ico
  medium: /images/favicon.ico
  apple_touch_icon: /images/favicon.ico
  safari_pinned_tab: /images/favicon.ico
  
scheme: Gemini

social:
  GitHub: https://github.com/zjuturtle || github
  E-Mail: mailto:leijinghaog@gmail.com || envelope
  
favicon:
  small: /images/favicon.ico
  medium: /images/favicon.ico
  apple_touch_icon: /images/favicon.ico
  safari_pinned_tab: /images/favicon.ico
  
math:
  # Default (false) will load mathjax / katex script on demand.
  # That is it only render those page which has `mathjax: true` in front-matter.
  # If you set it to true, it will load mathjax / katex script EVERY PAGE.
  every_page: true

  mathjax:
    enable: true
    # Available values: none | ams | all
    tags: none

# Gitalk
# Demo: https://gitalk.github.io
gitalk:
  enable: true
  github_id:  AnotherZjuturtle
  repo:  Gitalk
  client_id: 08e86c9d0536ed791bf9
  client_secret: 0982e8cb7b507eee3022547b44ebc4c4f6f2a944
  admin_user:  AnotherZjuturtle
  
# gitalk & js-md5
# See: https://github.com/gitalk/gitalk, https://github.com/emn178/js-md5
# Example:
gitalk_js: //cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.min.js
gitalk_css: //cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.css
md5: //cdn.jsdelivr.net/npm/js-md5@0/src/md5.min.js
```
