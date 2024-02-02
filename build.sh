#!/bin/bash

while [[ $# -gt 0 ]]; do
    case "$1" in
        --regenerate) # To regenerate defconfig
            REGENERATE_DEFCONFIG=true
            shift
            ;;
        --clean) # To regenerate defconfig
            CLEAN_KBUILD=true
            shift
            ;;
        --install) # To regenerate defconfig
            KINSTALL=true
            shift
            ;;
        *) # ¯_(ツ)_/¯
            echo "$1: ¯_(ツ)_/¯"
            exit 1
            ;;
    esac
done

# Setup environment
KERNEL_PATH=$PWD
ARCH=arm64
DEFCONFIG=custom_defconfig
CLANG_PATH=$HOME/llvm
export PATH=$CLANG_PATH/bin:$PATH
BUILD_CC="LLVM=1 LLVM_IAS=1 LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf STRIP=llvm-strip"
ROOTFS=$KERNEL_PATH/../rpi/root
BOOTFS=$KERNEL_PATH/../rpi/boot
KERNEL=kernel_2712

if [ "$REGENERATE_DEFCONFIG" = true ];then
    make O=out ARCH=arm64 CC='ccache clang' $BUILD_CC $DEFCONFIG
    cp out/.config arch/arm64/configs/custom_defconfig
    exit
fi

if [ "$CLEAN_KBUILD" = true ];then
    rm -rf out/
fi

make O=out ARCH=arm64 CC='ccache clang' $BUILD_CC $DEFCONFIG
make O=out  CC='ccache clang' CXX='ccache clang++' ARCH=arm64 -j`nproc` ${BUILD_CC} Image modules dtbs 2>&1 | tee error.log

if [ "$KINSTALL" = true ];then
    sudo make O=out  CC='ccache clang' CXX='ccache clang++' ARCH=arm64 ${BUILD_CC} INSTALL_MOD_PATH=$ROOTFS modules_install
    cd out
    sudo cp $BOOTFS/$KERNEL.img $BOOTFS/$KERNEL-backup.img
    sudo cp arch/arm64/boot/Image $BOOTFS/$KERNEL.img
    sudo cp arch/arm64/boot/dts/broadcom/*.dtb $BOOTFS/
    sudo cp arch/arm64/boot/dts/overlays/*.dtb* $BOOTFS/overlays/
fi