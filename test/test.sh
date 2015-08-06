#!/usr/bin/env bash
CWD=`pwd`
DIR=`cd $(dirname $0)/..; pwd`

cd $DIR

function quick_test {
  mkdir -p ./test/$1
  ./test/$1/output.log
  ./test/run.sh docker $1 ./test/run.sh tests 2>&1 | tee ./test/$1/output.log
  ./test/run.sh docker_copy $1 /tmp/files-master.log ./test/$1
  ./test/run.sh docker_copy $1 /tmp/files-slave.log ./test/$1
  sort ./test/$1/files-master.log > ./test/$1/files-master-sorted.log
  sort ./test/$1/files-slave.log > ./test/$1/files-slave-sorted.log
}

./test/run.sh build

case "$1" in
  alpine)
    quick_test alpine
  ;;

  ubuntu)
    quick_test ubuntu
  ;;

  *)
    quick_test alpine
    quick_test ubuntu
  ;;
esac

cd $CWD
