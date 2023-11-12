#!/bin/bash

TIME_START=$(date +%s)

WORKING_DIR=$(pwd)

source build-rpi-gcc-config


# Stop on errors
set -e


makeDir()
{
	sudo rm -rf "$1"
	mkdir -p "$1"
}



echo "Downloading sources.(if needed)..."
if [ ! - d $NAME_BINUTILS ] && [ ! -f $NAME_BINUTILS.tar.bz2 ]; then
    wget https://ftpmirror.gnu.org/binutils/$NAME_BINUTILS.tar.bz2
fi

if [ ! - d $NAME_GCC ] && [ ! -f $NAME_GCC.tar.gz ]; then
    wget https://ftpmirror.gnu.org/gcc/$NAME_GCC/$NAME_GCC.tar.gz
fi

if [ ! - d $NAME_GLIBC ] && [ ! -f $NAME_GLIBC.tar.bz2 ]; then
    wget https://ftpmirror.gnu.org/glibc/$NAME_GLIBC.tar.bz2
fi


cd $WORKING_DIR
echo "Downloading and expanding $NAME_BINUTILS (if needed)..."
if [ ! - d $NAME_BINUTILS ]; then
    if [ ! -f $NAME_BINUTILS.tar.bz2 ]; then
        echo "Downloading $NAME_BINUTILS..."
        wget https://ftpmirror.gnu.org/binutils/$NAME_BINUTILS.tar.bz2
    fi
    echo "Extracting $NAME_BINUTILS..."
    tar xf $NAME_BINUTILS.tar.bz2
else
    echo "$NAME_BINUTILS already present"
fi


cd $WORKING_DIR
echo "Downloading and expanding $NAME_GCC (if needed)..."
if [ ! - d $NAME_GCC ]; then
    if [ ! -f $NAME_GCC.tar.gz ]; then
        echo "Downloading $NAME_GCC..."
        wget https://ftpmirror.gnu.org/gcc/$NAME_GCC/$NAME_GCC.tar.gz
    fi
    echo "Extracting $NAME_GCC..."
    tar xf $NAME_GCC.tar.gz

    #echo "Patching ${NAME_GCC}//libsanitizer/asan/asan_linux.cpp..."
    VER10PATCH="-10"
    VER11PATCH="-11"
    VER12PATCH="-12"
    if [[ $NAME_GCC =~ $VER10PATCH ]] || [[ $NAME_GCC =~ $VER11PATCH ]] || [[ $NAME_GCC =~ $VER12PATCH ]]
    then
        echo "Patching ${NAME_GCC}/libsanitizer/asan/asan_linux.cpp..."
        cd $WORKING_DIR
        cd ${NAME_GCC}/libsanitizer/asan/
        cp asan_linux.cpp asan_linux.cpp.orig
        patch < ${WORKING_DIR}/asan_linux.patch
    fi

    echo "Downloading prerequisites for GCC..."
    cd $WORKING_DIR
    cd $NAME_GCC
    contrib/download_prerequisites
else
    echo "$NAME_GCC already present"
fi


cd $WORKING_DIR
echo "Downloading and expanding $NAME_GLIBC (if needed)..."
if [ ! - d $NAME_GLIBC ]; then
    if [ ! -f $NAME_GLIBC.tar.bz2 ]; then
        echo "Downloading $NAME_GLIBC..."
        wget https://ftpmirror.gnu.org/glibc/$NAME_GLIBC.tar.bz2
    fi
    echo "Extracting $NAME_GLIBC..."
    wget https://ftpmirror.gnu.org/glibc/$NAME_GLIBC.tar.bz2
else
    echo "$NAME_GLIBC already present"
fi


cd $WORKING_DIR
if [ -d linux ]; then
    echo "Updating RPi Linux headers..."
    cd linux
    git pull
else
    echo "Downloading RPi Linux headers..."
    git clone --depth=1 https://github.com/raspberrypi/linux
fi


# Temporarily change ownership of destination
echo "Temporarily changing ownership of destination directory to $USER..."
sudo chown -R $USER $PREFIX


echo "Copying kernel headers to cross-compiler destination folder..."
cd $WORKING_DIR
cd linux
export KERNEL=$KERNELNEEDED
make ARCH=arm INSTALL_HDR_PATH=$PREFIX/arm-linux-gnueabihf headers_install


cd $WORKING_DIR
echo "Building binutils..."
NAME_BINUTILS_BLD=${NAME_BINUTILS}_build
makeDir $NAME_BINUTILS_BLD
cd $NAME_BINUTILS_BLD
../$NAME_BINUTILS/configure --prefix=$PREFIX --target=arm-linux-gnueabihf --with-arch=$ARMARCH \
    --with-fpu=vfp --with-float=hard --disable-multilib
make -j $JOBS
make install



echo "Building GCC and GLIBC in stages..."


echo "Stage 1: Partial build of GCC..."
cd $WORKING_DIR
NAME_GCC_BLD=${NAME_GCC}_build
makeDir $NAME_GCC_BLD
cd $NAME_GCC_BLD
../$NAME_GCC/configure --prefix=$PREFIX --target=arm-linux-gnueabihf --enable-languages=c,c++ \
    --with-arch=$ARMARCH --with-fpu=vfp --with-float=hard --disable-multilib
make -j $JOBS all-gcc
make install-gcc


echo "Stage 2: Partial build of GLIBC..."
cd $WORKING_DIR
NAME_GLIBC_BLD=${NAME_GLIBC}_build
makeDir $NAME_GLIBC_BLD
cd $NAME_GLIBC_BLD
../glibc-2.24/configure --prefix=$PREFIX/arm-linux-gnueabihf --build=$MACHTYPE --host=arm-linux-gnueabihf \
    --target=arm-linux-gnueabihf --with-arch=$ARMARCH --with-fpu=vfp --with-float=hard \
    --with-headers=$PREFIX/arm-linux-gnueabihf/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j $JOBS csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/arm-linux-gnueabihf/lib
arm-linux-gnueabihf-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/arm-linux-gnueabihf/lib/libc.so
touch $PREFIX/arm-linux-gnueabihf/include/gnu/stubs.h


echo "Stage 3: Continue partial build of GCC..."
cd $WORKING_DIR
cd $NAME_GCC_BLD
make -j $JOBS  all-target-libgcc
make install-target-libgcc


echo "Stage 4: Finish build of GLIBC..."
cd $WORKING_DIR
cd $NAME_GLIBC_BLD
make -j $JOBS
make install


echo "Stage 5: Finish build of GCC..."
cd $WORKING_DIR
cd $NAME_GCC_BLD
make -j $JOBS
make install


echo "Build finished, restoring ownership of destination files to root..."
sudo chown -R root:root $PREFIX 

TIME_END=$(date +%s)
TIME_RUN=$(($TIME_END - $TIME_START))

echo ""
echo "Elapsed time $TIME_RUN seconds"

exit 0
