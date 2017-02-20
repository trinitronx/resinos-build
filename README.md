resinos-build
=============

My attempt at getting an ARM-based build of ResinOS working inside a Docker container. YMMV...


This started out as a test to see if I could build [resin-os/resin-raspberrypi@switch_board_to_morty][1] for the Raspberry Pi 3 inside a Docker container.  It ended up being a messy `sed` patch job on top of this branch, because it did not build out of the box, and is probably not yet ready for prime time.

Anyway, the `Dockerfile` is included and is set to check out the `switch_board_to_morty` branch of resin-os/resin-raspberrypi .  It then generates a fresh `build/` directory for `bitbake`, and patches on top of these files for various fixes required to build according to the checked out state of all the submodule bitbake layer repos.

The build host was tested on a CoreOS EC2 instance with the following config:

| AWS Setting  | Value                                                                                              |
|--------------|----------------------------------------------------------------------------------------------------|
|  **Image:**  | `CoreOS-stable-1235.4.0-hvm-0d1e0bd0-eaea-4397-9a3a-c56f861d2a14-ami-39302b2e.3` (`ami-014aaf17`)  |
|  **Type:**   | `c4.2xlarge`                                                                                       |
|  **Disk:**   | `512 GiB` EBS                                                                                      |
|**Vol Type:** | `io1`                                                                                              |
|  **IOPS:**   | `5000`                                                                                             |


`bitbake` Tuning
----------------

If building on a large instance type with many CPU cores (as returned by `nproc`), you will probably want to tune down the `BB_NUMBER_THREADS` setting.  You will probably run into a Network-bound limit on the number of concurrent source downloads that you are able to simultaneously download.  I had decent luck with `BB_NUMBER_THREADS=24`, but depending on your instance type and network traffic for when you kick off a build, this may be too many.  Tune it down until downloads stop failing.  Once your `build/downloads` has all the sources downloaded, you can probably turn `BB_NUMBER_THREADS` back up to `nproc * 4`.

You may wish to first run `bitbake -c fetchall resin-image` with `BB_NUMBER_THREADS = "$(nproc)"`, then run the next build with the original setting.

The `PARALLEL_MAKE` setting defaults to `nproc`. On my system it was `"-j 8"`.

[1]: https://github.com/resin-os/resin-raspberrypi/pull/76/files
