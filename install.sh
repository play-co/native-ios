#!/usr/bin/env bash

remoteurl=`git config --get remote.origin.url`

PRIV_SUBMODS=false && [[ "$remoteurl" == *native-ios-priv* ]] && PRIV_SUBMODS=true

if $PRIV_SUBMODS; then
	echo "Using private submodules..."
	cp .gitmodules.priv .gitmodules
fi

if ! git submodule sync; then
	error "Unable to sync git submodules"
	exit 1
fi

git submodule update --init --recursive

if $PRIV_SUBMODS; then
	git checkout .gitmodules
fi

npm install
git submodule update --init --recursive

