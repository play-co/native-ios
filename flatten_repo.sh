#!/usr/bin/env bash

REPO="ios"
MESSAGE="Game Closure iOS engine"
REPO_PUB="https://github.com/gameclosure/native-ios.git"
REPO_PRIV="https://github.com/gameclosure/native-ios-priv.git"
LOCAL_REMOTE="~/cleanroom/ios"
LOCAL_BRANCH="develop"
REMOTE_BRANCH="master"

# create initial repo
mkdir $REPO
cd $REPO

# create the remote branch
echo "creating $REMOTE_BRANCH branch..."
git init
git checkout -b $REMOTE_BRANCH

# create a file so we can commit something
# otherwise git will auto-link the develop branch to the local remote
touch ___tmp___
git add ___tmp___
git commit ___tmp___ -m "$(echo $MESSAGE)"

# lets you reference the original project
echo "fetching from local repo..."
git remote add local-remote $LOCAL_REMOTE

# gets the branch names from the original project
git fetch local-remote

# checkout a temporary local branch pointing at the original project
git checkout -b temp-develop local-remote/$LOCAL_BRANCH

# return to your main branch
git checkout $REMOTE_BRANCH

# merge in your temporary local branch into the staging area
git merge temp-develop --squash

# remove the temporary file
git rm ___tmp___

# rewrite the original commit
git commit --amend --no-edit

# push to github as a new branch develop
git remote add origin $REPO_PRIV
git push -f origin $REMOTE_BRANCH
git remote add gameclosure $REPO_PUB
git push -f gameclosure $REMOTE_BRANCH

# cleanup
git branch -d temp-develop
git remote rm local-remote
