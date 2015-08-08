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

function run {
  local cmd=$1
  shift 1
  local args=$@
  if [ -z "$args" ]; then
    warn "No arguments specified"
  else
    $cmd $args
  fi
}

function docker_clear {
  docker ps -a | grep osync | awk '{print $1}' | xargs docker rm
  docker images | grep osync | awk '{print $3}' | xargs docker rmi
}

function docker_build {
  docker build -t osync-$1 -f $DIR/tests/Dockerfile.$1 $DIR
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
  docker run -t $dopts --name osync-$name osync-$name $@
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

case "$OPT" in
  build)
    run docker_build $ARGS
  ;;

  rebuild)
    run docker_stop $ARGS
    run docker_remove_image $ARGS
    run docker_build $ARGS
  ;;

  shell)
    run docker_shell
  ;;

  clear)
    docker_clear
  ;;

  test)
    name=$1
    shift 1
    ARGS=$@
    run docker_run $name /osync/tests/run.sh $ARGS
  ;;

  *)
    ARGS="$OPT $ARGS"
    run docker_run $ARGS
  ;;

esac

cd $CWD
