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

The `PARALLEL_MAKE` setting defaults to `nproc`. On my system it was `"-j 8"`.  If building on a large instance type with many CPU cores (as returned by `nproc`), you will probably want to tune down the `BB_NUMBER_THREADS` setting.  You will probably run into a Network-bound limit on the number of concurrent source downloads that you are able to simultaneously download.  I had decent luck with `BB_NUMBER_THREADS=24`, but depending on your instance type, memory, and network traffic for when you kick off a build, this may be too many.  Tune it down until downloads stop failing.  Once your `build/downloads` has all the sources downloaded, you can probably turn `BB_NUMBER_THREADS` back up to `nproc * 4`.


You may wish to first run `bitbake -c fetchall resin-image` with `BB_NUMBER_THREADS = "$(nproc)"`, then run the next build with the original setting.  This may still be too much depending on how much memory your system has.  If you see [errors like this][2]:

```
ERROR: Worker process (32666) exited unexpectedly (-9), shutting down...
ERROR: Worker process (32666) exited unexpectedly (-9), shutting down...
ERROR: Worker process (32666) exited unexpectedly (-9), shutting down...
ERROR: Worker process (32666) exited unexpectedly (-9), shutting down...
WARNING: /tmp/yocto-autobuilder/yocto-autobuilder/yocto-worker/nightly-x86-64-lsb/build/bitbake/lib/bb/runqueue.py:1159: ResourceWarning: unclosed file <_io.BufferedWriter name=35>
  self.worker = {}

NOTE: Sending SIGTERM to remaining 7 tasks
NOTE: Sending SIGTERM to remaining 7 tasks
NOTE: Sending SIGTERM to remaining 7 tasks
NOTE: Sending SIGTERM to remaining 7 tasks
NOTE: Tasks Summary: Attempted 5938 tasks of which 1385 didn't need to be rerun and all succeeded.
NOTE: Writing buildhistory

Summary: There were 3 WARNING messages shown.
Summary: There were 5 ERROR messages shown, returning a non-zero exit code.
program finished with exit code 1

## And in your syslog or journald logs, you see:
$ journalctl -xn1000
Feb 21 16:01:15 ip-12-34-56-78.ec2.internal kernel: Out of memory: Kill process 27228 (Cooker) score 15 or sacrifice child
Feb 21 16:01:15 ip-12-34-56-78.ec2.internal kernel: Killed process 27247 (Worker) total-vm:219616kB, anon-rss:90192kB, file-rss:8244kB, shmem-rss:0k
```

Then, you are getting OOM (Out of memory) errors somewhere during the build.  You may want to tune down the default `BB_NUMBER_THREADS`, use a [different instance size][3] (Try the memory optimized instances such as `m4.2xlarge` or perhaps a larger RAM to CPU ratio).

[1]: https://github.com/resin-os/resin-raspberrypi/pull/76/files
[2]: http://www.variwiki.com/index.php?title=VAR-SOM-MX6_Yocto_Common_Errors#Unexpected_Error
[3]: http://www.ec2instances.info/?selected=m4.2xlarge,c4.2xlarge,r4.2xlarge,r3.2xlarge,m1.xlarge
