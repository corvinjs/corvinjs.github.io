#!/usr/bin/bash

mkdir _site/
cp home/index.html _site/

mkdir _site/assets/ _site/fonts/ _site/impressum/
cp -r home/assets/. _site/assets/
cp -r home/fonts/.  _site/fonts/
cp home/impressum/*.png _site/impressum/
cp home/impressum/index.html _site/impressum/index.html
cp home/favicon.* _site/
cp home/robots.txt home/sitemap.xml _site/
