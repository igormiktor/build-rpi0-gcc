# build-rpi-gcc
Script to build a GCC cross-compiler for Raspberry Pi Zero and Zero W.

This is current as of Nov 2023 and builds: GCC-12.2.0, Glibc-2.36, and Binutils-2.40 (as found on fresh installs of Raspberry PI OS on an RPi Zero).

The script defaults to building a cross-compiler that is tuned for Raspberry Pi model Zero and Zero W.  However,
this can be easily adjusted in the file `build-rpi-gcc-config` to make cross compilers targeting any other models.

In particular, in the file `build-rpi-gcc-config`:
* Set PREFIX to wherever you want the cross-compiler to be installed.
* Set the version of binutils to match the one on the target RPi.  From the RPi console type `ld -v` to see the binutils version.
* Set the version of gcc to match the one on the target RPi.  From the RPi console type `gcc --version` to see the gcc version.
* Set the version of glibc to match the one on the target RPi.  From the RPi console, type `ldd --version` to see the glibc version.
* Set KERNELNEEDED to "kernel" and ARMARCH to "armv6" to target all RPi models (and specifically RPI Zero & Zero W); set these to "kernel7" and "armv7" to target RPi model 3A+ and 3B (for more info see [here](https://raspberrypi.stackexchange.com/questions/104722/kernel-types-in-raspbian-10-buster/104726#104726)).
* Set JOBS to the number of parallel make processes you want to run (this should be not more than the number of CPUs you have on your build system)

Before executing `buildRPiZeroCrossCompiler.sh`:
* Make sure the directory $PREFIX and $PREFIX/bin exist (create empty versions if needed).
* Make sure $PREFIX/bin is included in the default PATH so that the script can find the executables it creates.  You can temporarily (for the current terminal session) add it to the PATH as follows:

```
PATH=$PREFIX/bin:$PATH
export PATH
```

After completing the build, you should also manually copy the kernel headers from the target RPi to the resulting cross-compiler. Specifically:
* Copy the entire contents of the target RPi directory `/usr/include/linux` to `$PREFIX/arm-linux-gnueabihf/include/`, overwriting the `linux` directory located there.
