hexo clean
hexo generate
rm -rf /var/www/hexo
cp -r public /var/www
mv /var/www/public /var/www/hexo
