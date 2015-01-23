#!/usr/bin/env bash

remoteurl=`git config --get remote.origin.url`

node scripts/submodules.js

if ! git submodule sync; then
	error "Unable to sync git submodules"
	exit 1
fi

git submodule update --init --recursive
