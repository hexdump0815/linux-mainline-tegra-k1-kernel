# directories:
# - /compile/doc/stable-tg - the files in this dir
# - /compile/source/linux-grate-tst - the kernel sources checked out from gitrepo
# - /compile/result/stable-tg - the resulting kernel, modules etc. tar.gz files
# - /compile/doc/kernel-config-options - https://github.com/hexdump0815/kernel-config-options
# name: tst-tst

cd /compile/source/linux-grate-tst

# patches:
# fix xusb
patch -p1 < /compile/doc/stable-tg/misc.tst/patches/xusb-usb-role-switch.patch
# the dfll part is required for cpu freq scaling to work
patch -p1 < /compile/doc/stable-tg/misc.tst/patches/cec-and-dfll-clock.patch
# a workaround for the broken soctherm hw thermal driver for now
patch -p1 < /compile/doc/stable-tg/misc.tst/patches/nyan-thermal-workaround.patch

export ARCH=arm
scripts/kconfig/merge_config.sh -m arch/arm/configs/multi_v7_defconfig /compile/doc/kernel-config-options/docker-options.cfg /compile/doc/kernel-config-options/options-to-remove-generic.cfg /compile/doc/stable-tg/misc.tst/options/options-to-remove-special.cfg /compile/doc/kernel-config-options/additional-options-generic.cfg /compile/doc/kernel-config-options/additional-options-armv7l.cfg /compile/doc/stable-tg/misc.tst/options/additional-options-special.cfg
( cd /compile/doc/kernel-config-options ; git rev-parse --verify HEAD ) > /compile/doc/stable-tg/misc.tst/options/kernel-config-options.version
make olddefconfig
make -j 4 bzImage dtbs modules
cd tools/perf
make
cd ../power/cpupower
make
cd ../../..
export kver=`make kernelrelease`
echo ${kver}
# remove debug info if there and not wanted
#find . -type f -name '*.ko' | sudo xargs -n 1 objcopy --strip-unneeded
make modules_install
mkdir -p /lib/modules/${kver}/tools
cp -v tools/perf/perf /lib/modules/${kver}/tools
cp -v tools/power/cpupower/cpupower /lib/modules/${kver}/tools
cp -v tools/power/cpupower/libcpupower.so.0.0.1 /lib/modules/${kver}/tools/libcpupower.so.0
# make headers_install INSTALL_HDR_PATH=/usr
cp -v .config /boot/config-${kver}
cp -v arch/arm/boot/zImage /boot/zImage-${kver}
mkdir -p /boot/dtb-${kver}
cp -v arch/arm/boot/dts/tegra124*.dtb /boot/dtb-${kver}
cp -v System.map /boot/System.map-${kver}
# start chromebook special - required: apt-get install liblz4-tool vboot-kernel-utils
cp arch/arm/boot/zImage zImage
dd if=/dev/zero of=bootloader.bin bs=512 count=1
cp /compile/doc/stable-tg/misc.tst/misc/cmdline cmdline
mkimage -D "-I dts -O dtb -p 2048" -f auto -A arm -O linux -T kernel -C none -a 0 -d zImage -b arch/arm/boot/dts/tegra124-nyan-big.dtb -b arch/arm/boot/dts/tegra124-nyan-blaze.dtb kernel.itb
vbutil_kernel --pack vmlinux.kpart --keyblock /usr/share/vboot/devkeys/kernel.keyblock --signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk --version 1 --config cmdline --bootloader bootloader.bin --vmlinuz kernel.itb --arch arm
cp -v vmlinux.kpart /boot/vmlinux.kpart-${kver}
rm -f zImage cmdline bootloader.bin kernel.itb vmlinux.kpart
# end chromebook special
cd /boot
update-initramfs -c -k ${kver}
#mkimage -A arm -O linux -T ramdisk -a 0x0 -e 0x0 -n initrd.img-${kver} -d initrd.img-${kver} uInitrd-${kver}
tar cvzf /compile/source/linux-grate-tst/${kver}.tar.gz /boot/*-${kver} /lib/modules/${kver}
cp -v /compile/doc/stable-tg/config.tst /compile/doc/stable-tg/config.tst.old
cp -v /compile/source/linux-grate-tst/.config /compile/doc/stable-tg/config.tst
cp -v /compile/source/linux-grate-tst/.config /compile/doc/stable-tg/config.tst-${kver}
cp -v /compile/source/linux-grate-tst/*.tar.gz /compile/result/stable-tg
