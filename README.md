# Dockerize Raspberry Pi OS

This simple script helps out with creating a docker image of Raspberry Pi OS. As
it only creates the base sysroot, it can be built on every docker enabled
architecture (UNIX like system).

If you need to run tasks like updating or installing additional software,
you need to be on an arm64 system, though.

## Prerequisites

You need these commands on your system:

 * curl
 * sha256sum
 * gpg
 * guestmount
 * unxz
 * tar

Make sure to have *guestmount* permissions. In order to be able to verify
the GPG signature of the downloaded base image, make sure to add the Pi OS
signing key:

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 54C3DD610D9D1B4AF82A37758738CD6B956F460C
```

## Running the script

Running `./build.sh` should be enough.
