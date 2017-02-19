#!/bin/sh
# Set up binfmt_misc for ARM processors using /usr/bin/qemu-arm-static
grep -q binfmt_misc /proc/mounts || mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
test -f /proc/sys/fs/binfmt_misc/arm || echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' | tee /proc/sys/fs/binfmt_misc/register
