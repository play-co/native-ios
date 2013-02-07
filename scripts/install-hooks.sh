#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for file in $DIR/githooks/*; do
	ln -s $file .git/hooks/
	chmod +x .git/hooks/$(basename "$file")
done
