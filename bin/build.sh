#!/bin/sh

BUILD_HOST_OS='ubuntu:16.04'
BUILD_TARGET='raspberrypi'

docker build -t trinitronx/resinos-raspberrypi:${BUILD_HOST_OS//:/-} -f dockerfiles/${BUILD_HOST_OS//://}/Dockerfile .

docker run -ti -v $(pwd)/build:/src/resin-raspberrypi/build/ -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup  --privileged --pid=host  --entrypoint=/bin/bash trinitronx/build-resinos:${BUILD_TARGET}-${BUILD_HOST_OS//:/-}
