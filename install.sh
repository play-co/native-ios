#!/usr/bin/env bash

remoteurl=`git config --get remote.origin.url`

if [[ "$remoteurl" == *native-ios-priv* ]]
then
	cp .gitmodules.priv .gitmodules
fi

git submodule update --init --recursive
