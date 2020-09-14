#!/bin/bash

token=`cat .token`
git clone "https://x-access-token:$token@github.com/redmine-patch-meetup/redmine-dev-mirror.git"

set -x
cd redmine-dev-mirror
git remote add redmine "https://github.com/redmine/redmine.git"
git checkout master
git fetch redmine
git reset --hard redmine/master
git push origin master
