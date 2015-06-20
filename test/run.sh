#!/usr/bin/env bash

CWD=`pwd`
DIR=`cd $(dirname $0)/..; pwd`

cd $DIR

OPT=$1
shift 1
ARGS=$@

function warn {
  >&2 echo $@
}

function run2 {
  local cmd=$1
  if ! [ -z "$cmd" ]; then
    if [ -z "$ARGS" ]; then
      $cmd node
      $cmd alpine
      $cmd ubuntu
    else
      $cmd $ARGS
    fi
  fi
}

function run {
  local cmd=$1
  if [ -z "$ARGS" ]; then
    warn "No arguments specified"
  else
    $cmd $ARGS
  fi
}

function docker_clear {
  docker ps -a | grep osync | awk '{print $1}' | xargs docker rm
  docker images | grep osync | awk '{print $1}' | xargs docker rmi
}

function docker_build {
  docker build -t osync-$1 -f $DIR/test/Dockerfile.$1 $DIR
}

function docker_remove_image {
  docker rmi -f osync-$1 2>/dev/null
}

function docker_remove_container {
  docker rm -f osync-$1 2>/dev/null
}

function docker_run {
  local name=$1
  shift 1

  local dopts=
  if [ "$1" = "-i" ]; then
    dopts=-i
    shift 1
  fi

  docker_stop $name
  docker_remove_container $name
  docker run -t $dopts -v $DIR:/osync -w /osync --name osync-$name osync-$name $@
}

function docker_shell {
    local name=$1
    shift 1
    docker_run $name -i bash $@
}

function docker_stop {
  docker stop osync-$1 2>/dev/null
}

function docker_copy {
  docker cp osync-$1:$2 $3
}

function tests {
  export DEBUG=yes
  cd /tmp/master/
  find . > /tmp/files-master.log

  /osync/osync.sh --master=/tmp/master --slave=/tmp/slave

  cd /tmp/slave/
  find . > /tmp/files-slave.log
}

case "$OPT" in
  build)
    run2 docker_build
  ;;

  rebuild)
    run2 docker_stop
    run2 docker_remove_image
    run2 docker_build
  ;;

  shell)
    run docker_shell
  ;;

  docker)
    run docker_run $ARGS
  ;;

  *)
    $OPT $ARGS
  ;;

esac

cd $CWD
