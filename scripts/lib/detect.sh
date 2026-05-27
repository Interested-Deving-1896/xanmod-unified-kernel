#!/usr/bin/env bash
# lib/detect.sh — arch/distro detection and mapping helpers

# karch_for <deb-arch>
# Maps Debian arch names to Linux ARCH= values used by the kernel build system.
karch_for() {
  case "$1" in
    amd64)   echo "x86_64"   ;;
    arm64)   echo "arm64"    ;;
    armhf)   echo "arm"      ;;
    armel)   echo "arm"      ;;
    i686)    echo "i386"     ;;
    ppc64el) echo "powerpc"  ;;
    s390x)   echo "s390"     ;;
    riscv64) echo "riscv"    ;;
    mips64el)echo "mips"     ;;
    loong64) echo "loongarch";;
    *)       echo "$1"       ;;  # pass through unknown arches
  esac
}

# cross_compile_for <deb-arch>
# Returns the CROSS_COMPILE prefix for the given arch.
cross_compile_for() {
  case "$1" in
    amd64)   echo "x86_64-linux-gnu-"      ;;
    arm64)   echo "aarch64-linux-gnu-"     ;;
    armhf)   echo "arm-linux-gnueabihf-"   ;;
    armel)   echo "arm-linux-gnueabi-"     ;;
    i686)    echo "i686-linux-gnu-"        ;;
    ppc64el) echo "powerpc64le-linux-gnu-" ;;
    s390x)   echo "s390x-linux-gnu-"       ;;
    riscv64) echo "riscv64-linux-gnu-"     ;;
    mips64el)echo "mips64el-linux-gnuabi64-";;
    loong64) echo "loongarch64-linux-gnu-" ;;
    *)       echo ""                       ;;
  esac
}

# host_arch — returns the Debian arch name of the current host
host_arch() {
  dpkg --print-architecture 2>/dev/null || uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/'
}

# detect_distro — returns the distro ID from /etc/os-release
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

# cross_compiler_pkg <deb-arch>
# Returns the apt package name for the cross-compiler toolchain.
cross_compiler_pkg() {
  case "$1" in
    arm64)   echo "gcc-aarch64-linux-gnu"          ;;
    armhf)   echo "gcc-arm-linux-gnueabihf"        ;;
    armel)   echo "gcc-arm-linux-gnueabi"          ;;
    i686)    echo "gcc-i686-linux-gnu"             ;;
    ppc64el) echo "gcc-powerpc64le-linux-gnu"      ;;
    s390x)   echo "gcc-s390x-linux-gnu"            ;;
    riscv64) echo "gcc-riscv64-linux-gnu"          ;;
    mips64el)echo "gcc-mips64el-linux-gnuabi64"    ;;
    loong64) echo "gcc-loongarch64-linux-gnu"      ;;
    *)       echo ""                               ;;
  esac
}
