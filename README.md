# build-rpi-gcc
Script to build a GCC cross-compiler for Raspberry Pi Zero and Zero W.

This is current as of Dec 2025 and builds: GCC-12.2.0, Glibc-2.36, and Binutils-2.40 (as found on fresh installs of Raspberry PI OS "Bookworm") (or to support Raspberry PI OS "Trixie": GCC-14.2.0, GLibc-2.41, and Binutils-2.44)

The script defaults to building a cross-compiler that is tuned for Raspberry Pi model Zero and Zero W.  However,
this can be easily adjusted in the file `build-rpi-gcc-config` to make cross compilers targeting any other models.

In particular, in the file `build-rpi-gcc-config`:
* Set PREFIX to wherever you want the cross-compiler to be installed.
* Set the version of binutils to match the one on the target RPi.  From the RPi console type `ld -v` to see the binutils version.
* Set the version of gcc to match the one on the target RPi.  From the RPi console type `gcc --version` to see the gcc version.
* Set the version of glibc to match the one on the target RPi.  From the RPi console, type `ldd --version` to see the glibc version.
* Set KERNELNEEDED to "kernel" to target all RPi models.  If you wish to be more specific:
    * Set to "kernel" to target 32-bit for RPi1, PRi0, and Rpi0 W
    * Set to "kernel7" to target 32-bit for RPi2, RPi3, RPi3+, and RPi0 2 W
    * Set to "kernel7l" to target 32-bit for RPi4
    * Set to "kernel8" to target 64-bit for RPi2, RPi3, RPi3+, RPi4, and RPi0 2 W
    * Aet to "kernel_2712" to target 64-bit RPi5
    * For more info see [here](https://www.raspberrypi.com/documentation/computers/linux_kernel.html#building).
* Set ARMARCH to "armv6" to target all RPi models.  _In theory,_ the following should work:
    * Set to "armv6" to target 32-bit for BCM2835 (RPi1 & PRi0, Rpi0 W)
    * Set to "armv7" to target 32-bit for RPi2, RPi3, RPi3+, RPi4, and RPi0 2 W
    * Set to "armv8" to target 64-bit for RPi2, RPi3, RPi3+, RPi4, RPi5, and RPi0 2 W
    * But **none** of these other settings for ARMARCH work for me.  Stick to "armv6".
* Set JOBS to the number of parallel make processes you want to run (this should be not more than the number of CPUs you have on your build system)

Before executing `buildRPiZeroCrossCompiler.sh`:
* Install the following: `sudo apt install texinfo cmake bison flex autoconf automake autotools-dev`
* Make sure the directory $PREFIX and $PREFIX/bin exist (create empty versions if needed).
* Make sure $PREFIX/bin is included in the default PATH so that the script can find the executables it creates.  You can temporarily (for the current terminal session) add it to the PATH as follows:

```
PATH=$PREFIX/bin:$PATH
export PATH
```

After completing the build, you should also manually copy the kernel headers from the target RPi to the resulting cross-compiler. Specifically:
* Copy the entire contents of the target RPi directory `/usr/include/linux` to `$PREFIX/arm-linux-gnueabihf/include/`, overwriting the `linux` directory located there.
