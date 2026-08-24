#!/usr/bin/bash

mkdir _site/
cp index.html _site/

mkdir _site/assets/ _site/fonts/
cp -r assets/. _site/assets/
cp -r fonts/.  _site/fonts/
