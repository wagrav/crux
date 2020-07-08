#!/usr/bin/env bash
function build() {
  local image=$1
  docker build -t $image -f Dockerfile .
}

function buildAll() {
  local group=$1
  docker build --tag="$group/jmeter-base:latest" -f Dockerfile .
  docker build --tag="$group/jmeter-master:latest" -f Dockerfile-master .
  docker build --tag="$group/jmeter-slave:latest" -f Dockerfile-slave .
}
function push(){
  local group=$1
  docker login
  docker push $group/jmeter-base
  docker push $group/jmeter-master
  docker push $group/jmeter-slave
}
#sh build.sh jmeter-chrome-selenium
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  buildAll gabrielstar && push gabrielstar
fi
