#!/bin/sh

BUILD_HOST_OS='ubuntu:16.04'
BUILD_TARGET='raspberrypi'
DOCKER_GID=$(id -g docker)

docker build --build-arg DOCKER_GID=${DOCKER_GID} -t trinitronx/build-resinos:${BUILD_TARGET}-${BUILD_HOST_OS//:/-} -f dockerfiles/${BUILD_HOST_OS//://}/Dockerfile .

[ -d /export ] || sudo mkdir -p /export
[ -d /data_disk ] || sudo mkdir -p /data_disk
sudo chown 1000:1000 /export
sudo chown 1000:1000 /data_disk

docker run -ti -v $(pwd)/build:/src/resin-raspberrypi/build/ --device=/dev/loop-control:/dev/loop-control -v /dev/loop0:/dev/loop0 -v /export:/export -v /data_disk:/data_disk  -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup  --privileged=true --pid=host  --cap-add=CAP_MKNOD  --entrypoint=/bin/bash trinitronx/build-resinos:${BUILD_TARGET}-${BUILD_HOST_OS//:/-}
