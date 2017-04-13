hexo clean
hexo generate
rm -rf /var/www/hexo
cp -r public /var/www
mv public hexo
