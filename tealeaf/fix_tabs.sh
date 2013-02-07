for f in $(find . -path './deps' -prune -name '*.h' -or -name '*.m' -or -name '*.mm' -or -name '*.c' -or -name '*.cpp'); do echo $f; unexpand -t 4 $f > temp; mv temp $f; done
