#!/bin/bash

source layers/poky/oe-init-build-env
#export PATH=/src/resin-raspberrypi/layers/poky/bitbake/bin/:/home/bitbake/bin:/home/bitbake/.local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

MACHINE=raspberrypi3 bitbake resin-image

