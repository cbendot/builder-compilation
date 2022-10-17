#!/usr/bin/env bash
#
# Copyright (C) 2022 a xyzprjkt property
#

# Needed Secret Variable
# KERNEL_NAME | Your kernel name
# KERNEL_SOURCE | Your kernel link source
# KERNEL_BRANCH  | Your needed kernel branch if needed with -b. eg -b lineage-19.1
# DEVICE_CODENAME | Your device codename
# DEVICE_DEFCONFIG | Your device defconfig eg. ginkgo-perf_defconfig
# ANYKERNEL | Your Anykernel link repository
# TG_TOKEN | Your telegram bot token
# TG_CHAT_ID | Your telegram private ci chat id

START=$(date +"%s")
echo "|| Downloading few Dependecies . . .||"
# Kernel Sources
git clone --depth=1 https://github.com/cbendot/android_kernel_xiaomi_ginkgo.git -b lineage-19.1 ginkgo
# git clone --depth=1 https://github.com/fiqri19102002/android_kernel_xiaomi_ginkgo.git -b android-11 ginkgo
git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r445002.git -b 12.1 aosp-clang
# git clone --depth=1 https://gitlab.com/ben863/aosp-clang.git aosp-clang
# git clone --depth=1 https://gitlab.com/ben863/azure-clang.git aosp-clang
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git -b lineage-19.1 gcc64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git -b lineage-19.1 gcc32
# git clone --depth=1 https://github.com/cbendot/gcc-aarch64.git gcc64
# git clone --depth=1 https://github.com/cbendot/gcc-armv5.git gcc32

# Main Declaration
KERNEL_ROOTDIR=$(pwd)/ginkgo # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_DEFCONFIG="vendor/ginkgo-perf_defconfig" # IMPORTANT ! Declare your kernel source defconfig file here.
DEVICE_CODENAME="ginkgo"
CLANG_ROOTDIR=$(pwd)/aosp-clang # IMPORTANT! Put your clang directory here.
GCC64_ROOTDIR=$(pwd)/gcc64
GCC32_ROOTDIR=$(pwd)/gcc32

# Main Declaration
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
# GCC_VER="$("$GCC64_ROOTDIR"/bin/aarch64-buildroot-linux-gnu-gcc --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
IMAGE=$(pwd)/$DEVICE_CODENAME/out/arch/arm64/boot/Image.gz-dtb
DATE=$(date "+%B %-d, %Y")
ZIP_DATE=$(date +"%Y%m%d")

# Checking environtment
# Warning !! Dont Change anything there without known reason.
function check() {
echo ================================================
echo xKernelCompiler
echo version : rev1.5 - gaspoll modified
echo ================================================
echo BUILDER NAME = ${KBUILD_BUILD_USER}
echo BUILDER HOSTNAME = ${KBUILD_BUILD_HOST}
echo TOOLCHAIN_VERSION = ${KBUILD_COMPILER_STRING}
echo CLANG_ROOTDIR = ${CLANG_ROOTDIR}
echo KERNEL_ROOTDIR = ${KERNEL_ROOTDIR}
echo ================================================
}

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"
}

# Post Main Information
tg_post_msg "<b>$KERNEL_NAME Triggered Build</b>%0A<b>Triggered by: </b><code>ben863</code>%0A<b>Build For: </b><code>Redmi Note 8 ginkgo</code>%0A<b>Build Date: </b><code>$DATE</code>%0A<b>Pipelines Hosts: </b><code>DroneCI</code>%0A<b>Toolchain Information:</b>%0A<code>${KBUILD_COMPILER_STRING}</code>"

# Compile
compile(){
cd ${KERNEL_ROOTDIR}
COMMIT_HEAD=$(git log --oneline -1)
tg_post_msg "<b>commit: </b>$COMMIT_HEAD"
make -j$(nproc) O=out ARCH=arm64 SUBARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 SUBARCH=arm64 O=out \
    CC=${CLANG_ROOTDIR}/bin/clang \
    AR=${CLANG_ROOTDIR}/bin/llvm-ar \
  	NM=${CLANG_ROOTDIR}/bin/llvm-nm \
  	OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
  	OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    CLANG_TRIPLE=${GCC64_ROOTDIR}/aarch64-linux-gnu- \
    CROSS_COMPILE=${GCC64_ROOTDIR}/bin/aarch64-linux-android- \
    CROSS_COMPILE_ARM32=${GCC32_ROOTDIR}/bin/arm-linux-androideabi-
   
   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

  git clone --depth=1 $ANYKERNEL -b ginkgo AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)"
}

# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Build throw an error(s)"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 $KERNEL_NAME-ginkgo-${ZIP_DATE}.zip *
    cd ..

}
check
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
