#!/bin/bash

export GIT_DIR=/var/www/dariah-de-status/.git; 

git fetch origin master
git checkout master

if [[ $(git rev-parse @) != $(git rev-parse @{u}) ]]; then 
  git -C $GIT_DIR/.. reset --hard origin
  git pull
fi

