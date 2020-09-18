#!/usr/bin/env bash
function buildAll() {
  local group=$1
  local prefix=$2
  local tag=$3
  docker build -t "$group/$prefix-base:$tag" -f Dockerfile .
  docker build -t "$group/$prefix-master:$tag" -f Dockerfile-master .
  docker build -t "$group/$prefix-slave:$tag" -f Dockerfile-slave .
}
function push(){
  local group=$1
  local prefix=$2
  local tag=$3
  docker login
  docker push "$group/$prefix-base:$tag"
  docker push "$group/$prefix-master:$tag"
  docker push "$group/$prefix-slave:$tag"
}
#sh build.sh jmeter-chrome-selenium
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  buildAll gabrielstar crux latest && push gabrielstar crux latest
fi
