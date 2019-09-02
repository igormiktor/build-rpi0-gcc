# build-rpi-gcc
Script to build a GCC cross-compiler for Raspberry Pi

The script defaults to building a cross-compiler that works for Raspberry Pi models B, Zero, ZeroW, and 3.  However,
this can be easily adjusted in the file `build-rpi-gcc-config` to make cross compilers targeting models 3A+ and 3B.

In particular, in the file `build-rpi-gcc-config`:
* Set PREFIX to wherever you want the cross-compiler to be installed.
* Set the version of binutils to match the one on the target RPi.  From the RPi console type `ld -v` to see the binutils version.
* Set the version of gcc to match the one on the target RPi.  From the RPi console type `gcc --version` to see the gcc version.
* Set the version of glibc to match the one on the target RPi.  From the RPi console, type `ldd --version` to see the glibc version.
* Set KERNELNEEDED to "kernel" and ARMARCH to "armv6" to target all RPi models; set these to "kernel7" and "armv7" to target RPi model 3A+ and 3B.
* Set JOBS to the number of parallel make processes you want to run (this should be less than the number of CPUs you have on the build system)

Before executing `buildRPiZeroCrossCompiler.sh`:
* Make sure the directory $PREFIX and $PREFIX/bin exist (create empty versions if needed).
* Make sure $PREFIX/bin is included in the default PATH so that the script can find the executables it creates.  You can temporarily (for the current terminal session) add it to the PATH as follows:

```
PATH=$PREFIX/bin:$PATH
export PATH
```

After completing the build, you should also manually copy the kernel headers from the target RPi to the resulting cross-compiler. Specifically:
* Copy the entire contents of the target RPi directory `/usr/include/linux` to `$PREFIX/arm-linux-gnueabihf/include/`, overwriting the `linux` directory located there.
