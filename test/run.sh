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

function docker_build {
  docker build -t osync-$1 -f $DIR/test/Dockerfile.$1 $DIR
}

function docker_remove_image {
  docker rmi -f osync-$1 2>/dev/null
}

function docker_run {
  local name=$1
  shift 1

  local dopts=
  if [ "$1" = "-i" ]; then
    dopts=-i
    shift 1
  fi

  docker run -t $dopts -v $DIR:/osync -w /osync --rm osync-$name $@
}

function docker_shell {
    local name=$1
    shift 1
    docker_run $name -i bash $@
}

function docker_stop {
  docker stop osync-$1 2>/dev/null
}

function tests {
  export DEBUG=yes
  /osync/osync.sh --master=/tmp/dir1 --slave=/tmp/dir2 2>&1
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
