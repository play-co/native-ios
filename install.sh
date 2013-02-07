#!/usr/bin/env bash

remoteurl=`git config --get remote.origin.url`

git submodule init

if [[ "$remoteurl" == *native-ios-priv* ]]
then
	cd tealeaf/native-core
	git remote set-url origin "https://github.com/gameclosure/native-core-priv.git"
	cd ../..
fi

git submodule update --init --recursive
