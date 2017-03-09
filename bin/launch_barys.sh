#!/bin/bash

#docker run -ti -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup  --privileged --pid=host  --entrypoint=/bin/bash trinitronx/resinos-raspberrypi:latest

source layers/poky/oe-init-build-env
./resin-yocto-scripts/build/barys --remove-build --machine $RESINOS_MACHINE
