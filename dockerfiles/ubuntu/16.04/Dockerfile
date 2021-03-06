#FROM resin/armv7hf-debian
FROM ubuntu:16.04

RUN mkdir -p /src

WORKDIR /src/

ARG DEBIAN_FRONTEND=noninteractive
ARG PKG_DEPENDENCIES="build-essential gcc-multilib python-software-properties locales curl xz-utils git jq diffstat texinfo gawk chrpath wget cpio unzip file pkg-config libsdl1.2-dev xterm"
ARG DOCKER_GID=233

RUN apt-get update && apt-get -y install $PKG_DEPENDENCIES && \
    curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
    apt-get -y install nodejs

ARG DOCKER_VERSION=1.12.6

RUN curl -Ls -o - https://get.docker.com/ | bash -s
#RUN \
#    curl -L -o - https://get.docker.com/builds/$(uname -s)/$(uname -m)/docker-${DOCKER_VERSION}.tgz | \
#    gzip -d -c | \
#    tar -C /tmp/ -xf - && mv /tmp/docker/* /usr/bin/ && mv /usr/bin/docker /usr/bin/docker-${DOCKER_VERSION} && \
#    ln -s /usr/bin/docker-${DOCKER_VERSION} /usr/bin/docker && chmod +x /usr/bin/docker /usr/bin/docker-${DOCKER_VERSION}

#RUN apt-get -y install zlib1g zlib1g-dev libglib2.0-0 libglib2.0-dev dh-autoreconf
#RUN git clone git://git.qemu.org/qemu.git /src/qemu && \
#    cd /src/qemu && git submodule update --init pixman 

#RUN cd /src/qemu && ./configure --target-list=arm-linux-user --static && make -j$(nproc) && \
#    make install && \
#    cp qemu/arm-linux-user/qemu-arm /usr/local/bin/ && chmod +x /usr/local/bin/qemu-arm

RUN apt-get -y install sudo && \
    sed -i -e 's/^Defaults.*requiretty/Defaults    !requiretty/' -e 's/^%sudo.*ALL$/%sudo    ALL=(ALL)    NOPASSWD: ALL/' /etc/sudoers
RUN useradd -ms /bin/bash bitbake && getent group docker || groupadd --gid $DOCKER_GID docker && usermod -aG docker,sudo bitbake && groupmod --gid $DOCKER_GID docker

RUN sed -i  -e 's/^# \(en_US.UTF-8.*\)/\1/' /etc/locale.gen ; \
    dpkg-reconfigure locales && locale-gen "en_US.UTF-8"

ARG RESINOS_BOARD=raspberrypi
ARG RESINOS_BRANCH=master
ARG RESINOS_MACHINE=raspberrypi3

RUN git clone https://github.com/resin-os/resin-${RESINOS_BOARD}.git /src/resin-${RESINOS_BOARD} && \
    cd /src/resin-${RESINOS_BOARD} && git checkout $RESINOS_BRANCH && git submodule update --init --recursive

RUN chown -R bitbake:bitbake /src/resin-${RESINOS_BOARD}


RUN printf "export LC_ALL=en_US.UTF-8\nexport LANG=en_US.UTF-8\nexport LANGUAGE=en_US.UTF-8\n" >> /etc/profile.d/locale-en-us-utf8.sh

RUN apt-get -y install vim less

USER bitbake

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

WORKDIR /src/resin-${RESINOS_BOARD}
RUN ./resin-yocto-scripts/build/barys --dry-run --remove-build --machine $RESINOS_MACHINE && \
    sed -i -e 's/GPU_MEM.*=.*/GPU_MEM = "128"/' build/conf/local.conf

### Ok... so the rest of this stuff is pretty busted apparently...
# Hacks for docker container showing arch as armv7l
# This should at least make bitbake happier

## NOTE: UNINATIVE is only available for i686 and x86_64
##       To get bitbake to build on arm, we fudge it to use x86_64 (not sure what consequences of this are)
## URL for uninative recipe downloads:
##    http://downloads.yoctoproject.org/releases/uninative/1.4/

RUN sed -i -e '/SUPERVISOR_REPOSITORY_armv7a/aSUPERVISOR_REPOSITORY_armv7l = "resin/armv7hf-supervisor"\nSUPERVISOR_REPOSITORY_arm = "resin/armv7hf-supervisor"' ./layers/meta-resin/meta-resin-common/recipes-containers/docker-disk/docker-resin-supervisor-disk.bb
RUN sed -i -e  '/#MACHINE ?= "raspberrypi3"/a TARGET_ARCH = "arm"\nBUILD_ARCH = "arm"\nMACHINE = "raspberrypi3"\nDEVELOPMENT_IMAGE = "1"\nUNINATIVE_TARBALL = "x86_64-nativesdk-libc.tar.bz2"\nUNINATIVE_CHECKSUM[arm] = "101ff8f2580c193488db9e76f9646fb6ed38b65fb76f403acb0e2178ce7127ca"\n' build/conf/local.conf

# Use default Parallelism settings for bitbake based on nproc / python @oe.utils.cpu_count()
# Make jobs = -j `nproc`
# BB Threads = `nproc`
# Important! DEVELOPMENT_IMAGE must be set to 1 to avoid building docker-disk & docker-resin-supervisor-disk recipes
# These recipes don't work when running the bitbake build using Docker-in-Docker (mounting /var/run/docker.sock into the container)
# Reason:  docker-disk* recipes assume that they're not inside a docker container, and are on a host supporting the Docker graphdriver
#          They launch "docker daemon -g /resin-data/docker -s aufs" after mounting this location as a loopback device in order to pull the resin/armv7hf-supervisor image
#          Intent seems to be to pre-seed the base OS with an existing docker image pull result.
#          For our purposes, we don't need the board to contact resin.io, so we put a basic empty ext4 image "resin-data.img" in the bitbake work directory to get the bitbake build working
#          See:
#            layers/meta-resin/meta-resin-common/recipes-containers/docker-disk/files/entry.sh
#          Run the above script manually to create the image, then copy it into the work directory after bitbake fails on docker-custom-disk
#          cp /export/resin-data.img build/tmp/work/raspberrypi3-poky-linux-gnueabi/docker-custom-disk/1.0-r0/
RUN sed -i -e "/#MACHINE ?= \"raspberrypi3\"/a DEVELOPMENT_IMAGE = \"1\"\n" build/conf/local.conf

# Update the bcm2835 recipe to use latest release
# It seems that the previous tag was deleted from the raspberrypi/firmware GitHub repo
# So, the old setting (bcm2835-bootfiles-20161209-r3) will not build!
RUN printf '# add support for the rpi3\n# kernel: Bump to 4.4.38\nRPIFW_SRCREV = "2190ebaaab17d690fb4a6aa767ff7755eaf51b12"\nRPIFW_DATE = "20161215"\nSRC_URI[md5sum] = "ddd7645988360d7ef267b48c32293ad7"\nSRC_URI[sha256sum] = "bda18f2affb50053940fd88c3f3bec5af9a4b4ced753d01107a2b106cfb02d13"\n' > /src/resin-raspberrypi/layers/meta-resin-raspberrypi/recipes-bsp/bootfiles/bcm2835-bootfiles.bbappend

# At build run time: groupid must match docker group on host
# groupmod --gid $(stat -c '%g' /var/run/docker.sock) docker
# Must run with VOLUMES, and dockerd /proc/PID must be accessible from the host for docker-disk bb recipe to work:
# -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup

ADD ./bin /src/resin-raspberrypi/build-helper-bin

# BUILD IT!
# docker run -ti -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup  --privileged --pid=host  trinitronx/resinos-build:morty /bin/bash
## resin/armv7hf-debian
# docker run -ti -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/docker.pid:/var/run/docker.pid -v /sys/fs/cgroup:/sys/fs/cgroup  --privileged --pid=host  --entrypoint=/bin/bash trinitronx/resinos-raspberrypi:morty
# source layers/poky/oe-init-build-env
# MACHINE=raspberrypi3 bitbake resin-image
