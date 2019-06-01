#!/bin/bash

TIME_START=$(date +%s)

source build-rpi-gcc-config


# Stop on errors
set -e


makeDir()
{
	sudo rm -rf "$1"
	mkdir -p "$1"
}



echo "Downloading sources..."

if [ ! -f $NAME_BINUTILS.tar.bz2 ]; then
    wget https://ftpmirror.gnu.org/binutils/$NAME_BINUTILS.tar.bz2
fi

if [ ! -f $NAME_GCC.tar.gz ]; then
    wget https://ftpmirror.gnu.org/gcc/$NAME_GCC/$NAME_GCC.tar.gz
fi

if [ ! -f $NAME_GLIBC.tar.bz2 ]; then
    wget https://ftpmirror.gnu.org/glibc/$NAME_GLIBC.tar.bz2
fi

if [ ! -d linux ]; then
    git clone --depth=1 https://github.com/raspberrypi/linux
fi


echo "Expanding sources..."

tar xf $NAME_BINUTILS.tar.bz2
tar xf $NAME_GLIBC.tar.bz2
tar xf $NAME_GCC.tar.gz




# Temporarily change ownership of destination
# sudo chown -R $USER $PREFIX


echo "Building binutils..."

NAME_BINUTILS_BLD=${NAME_BINUTILS}_build
makeDir $NAME_BINUTILS_BLD
cd $NAME_BINUTILS_BLD
../$NAME_BINUTILS/configure --prefix=$PREFIX --target=arm-linux-gnueabihf --with-arch=$ARMARCH --with-fpu=vfp --with-float=hard --disable-multilib
make -j $JOBS
sudo env "PATH=$PATH" make install
cd ..


echo "Install kernel headers"

cd linux
KERNEL=$KERNELNEEDED
sudo env "PATH=$PATH" make ARCH=arm INSTALL_HDR_PATH=$PREFIX/arm-linux-gnueabihf headers_install
cd ..



echo "Building GCC..."

cd $NAME_GCC
echo "Setting up GCC prerequisites..."
contrib/download_prerequisites
echo "- Patching ubsan.c"
cd gcc
cp ubsan.c ubsan.c.orig
sed -f ../../ubsanFix.sed ubsan.c.orig > ubsan.c.fixed
cp ubsan.c.fixed ubsan.c
cd ..
cd ..

echo "- Partial build of GCC..."
NAME_GCC_BLD=${NAME_GCC}_build
makeDir $NAME_GCC_BLD
cd $NAME_GCC_BLD
../$NAME_GCC/configure --prefix=$PREFIX --target=arm-linux-gnueabihf --enable-languages=c,c++ \
    --with-arch=$ARMARCH --with-fpu=vfp --with-float=hard --disable-multilib
make -j $JOBS all-gcc
sudo env "PATH=$PATH" make install-gcc
cd ..

echo "- Partial build of GLIBC..."
NAME_GLIBC_BLD=${NAME_GLIBC}_build
makeDir $NAME_GLIBC_BLD
cd $NAME_GLIBC_BLD
echo "-- Do config"
../glibc-2.24/configure --prefix=$PREFIX/arm-linux-gnueabihf --build=$MACHTYPE --host=arm-linux-gnueabihf \
    --target=arm-linux-gnueabihf --with-arch=$ARMARCH --with-fpu=vfp --with-float=hard \
    --with-headers=$PREFIX/arm-linux-gnueabihf/include --disable-multilib libc_cv_forced_unwind=yes
sudo env "PATH=$PATH" make install-bootstrap-headers=yes install-headers
make -j $JOBS csu/subdir_lib
sudo env "PATH=$PATH" install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/arm-linux-gnueabihf/lib
sudo env "PATH=$PATH" arm-linux-gnueabihf-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/arm-linux-gnueabihf/lib/libc.so
sudo env "PATH=$PATH" touch $PREFIX/arm-linux-gnueabihf/include/gnu/stubs.h
sudo chown -R $USER:$USER *
cd ..

echo "- Continue partial build of GCC..."
cd $NAME_GCC_BLD
make -j $JOBS  all-target-libgcc
sudo env "PATH=$PATH" make install-target-libgcc
sudo chown -R $USER:$USER *
cd ..

echo "- Finish build of GLIBC..."
cd $NAME_GLIBC_BLD
sudo chown -R $USER:$USER *
make -j $JOBS
sudo env "PATH=$PATH" make install
cd ..

echo "- Finish build of GCC..."
cd $NAME_GCC_BLD
sudo chown -R $USER:$USER *
make -j $JOBS
sudo env "PATH=$PATH" make install
cd ..


TIME_END=$(date +%s)
TIME_RUN=$(($TIME_END - $TIME_START))

echo ""
echo "Elapsed time $TIME_RUN seconds"

exit 0
