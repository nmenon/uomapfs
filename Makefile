#
# Make file for compiling uomapfs
#
# (C) Copyright 2010
# Texas Instruments, <www.ti.com>
# Nishanth Menon <nm@ti.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation version 2.
#
# This program is distributed .as is. WITHOUT ANY WARRANTY of any kind,
# whether express or implied; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA

# Handle verbose
ifeq ("$(origin V)", "command line")
  VERBOSE = $(V)
endif
ifndef VERBOSE
  VERBOSE = 0
endif
Q := $(if $(VERBOSE:1=),@)

# Our default directories
SCRIPT_DIR := scripts
CONFIG_DIR := configs
BUSYBOX := busybox
ETC_SCRIPTS :=$(CONFIG_DIR)/etc

# Our standard scripts
MAKECONFIG := $(SCRIPT_DIR)/make.config
GETVAR := $(SCRIPT_DIR)/config.var
PWD := $(shell pwd)

-include .config

target_fs_dir ?= $(PWD)/target/rootfs
target_boot_files_dir ?= $(PWD)/target/boot
host_binaries ?= $(PWD)/bin
#host_utils ?= omap-u-boot-utils

ifeq ("$(busybox_defconfig_file)", "")
  busybox_defconfig_file := $(PWD)/$(CONFIG_DIR)/busybox_generic.config
endif

BUILD_TARGETS := 
DCLEAN_TARGETS := 
ifneq ("$(spl_bootloader)", "")
	BUILD_TARGETS += spl_bootloader
	DCLEAN_TARGETS += spl_bootloader_clean
endif
ifneq ("$(bootloader)", "")
	BUILD_TARGETS += bootloader
	DCLEAN_TARGETS += bootloader_clean
endif
ifneq ("$(BUSYBOX)", "")
	BUILD_TARGETS += fs
	DCLEAN_TARGETS += fs_clean
endif
ifneq ("$(kernel)", "")
BUILD_TARGETS += kernel
	DCLEAN_TARGETS += kernel_clean
endif
ifneq ("$(host_utils)", "")
	BUILD_TARGETS += utils
	DCLEAN_TARGETS += utils_clean
endif

# Phony rules
.PHONY: all distclean .config clean bootloader bootloader_defconf fs git ramdisk utils

.EXPORT_ALL_VARIABLES:

all: git .config
	$(Q)[ -f .config ] || (echo "no .config, run 'make with one of: "`ls configs/*defconfig|sed -e 's/configs\///g'` && exit 1)
	$(Q)echo "Build targets=$(BUILD_TARGETS)"
	$(Q)$(MAKE) $(BUILD_TARGETS)

distclean:
	$(Q)$(MAKE) $(DCLEAN_TARGETS)
	$(Q)rm -rf .config $(target_fs_dir) $(target_boot_files_dir) \
		$(host_binaries) target

spl_bootloader_clean:
	$(Q)$(MAKE) -C $(spl_bootloader) distclean

bootloader_clean:
	$(Q)$(MAKE) -C $(bootloader) distclean

kernel_clean:
	$(Q)$(MAKE) -C $(kernel) distclean

fs_clean:
	$(Q)$(MAKE) -C $(BUSYBOX) distclean

utils_clean:
	$(Q)$(MAKE) -C $(host_utils) distclean

git:
	$(Q)git submodule status|grep '^-' && git submodule init && \
		git submodule update || echo 'nothin to update'

spl_bootloader: git .config $(spl_bootloader)/$(spl_bootloader_image_location)
	$(Q)install -d $(target_boot_files_dir)
	$(Q)install $(spl_bootloader)/$(spl_bootloader_image_location) \
		$(target_boot_files_dir)

$(spl_bootloader)/$(spl_bootloader_image_location): $(spl_bootloader)/include/config.h
	$(Q)$(MAKE) -C $(spl_bootloader) $(spl_bootloader_image)

ifneq ("$(bootloader)", "$(spl_bootloader)")
$(spl_bootloader)/include/config.h: .config
	$(Q)$(MAKE) -C $(spl_bootloader) $(spl_bootloader_defconfig)
endif
	
bootloader: git .config $(bootloader)/$(bootloader_image_location)
	$(Q)install -d $(target_boot_files_dir)
	$(Q)install $(bootloader)/$(bootloader_image_location) \
		$(target_boot_files_dir)
ifneq ("$(bootloader_cmd)", "")
	$(Q)mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'bootscr'\
		-d $(bootloader_cmd) $(target_boot_files_dir)/boot.scr
	$(Q)install $(bootloader_cmd) $(target_boot_files_dir)/boot.cmd
endif
ifneq ("$(bootloader_env)", "")
	$(Q)install $(bootloader_env) $(target_boot_files_dir)/uEnv.txt
endif

$(bootloader)/$(bootloader_image_location): $(bootloader)/include/config.h
	$(Q)$(MAKE) -C $(bootloader) $(bootloader_image)

$(bootloader)/include/config.h: .config
	$(Q)$(MAKE) -C $(bootloader) $(bootloader_defconfig)

fs: git .config $(BUSYBOX)/busybox busymkdir
	$(Q)fakeroot $(MAKE) -C$(BUSYBOX) CONFIG_PREFIX=$(target_fs_dir) install
	$(Q)./scripts/cp_libs.sh $(target_fs_dir)/bin/busybox $(target_fs_dir)/lib
	$(Q)cp -rf $(PWD)/$(ETC_SCRIPTS)/* $(target_fs_dir)/etc/

busymkdir: .config
	for d in lib etc dev dbg proc sys var/log var/run var/lib/misc; do \
		install -d $(target_fs_dir)/$$d;\
	done

# Ensure that everything is built before we build ramdisk - e.g. tests/utils etc.
ramdisk: all
	$(Q)rm -rf $(target_boot_files_dir)/ramdisk* 2>/dev/null
	$(Q)mkdir -p $(target_boot_files_dir)/ramdisk-dir
	$(Q)dd if=/dev/zero of=$(target_boot_files_dir)/ramdisk count=1 bs=10M
	$(Q)(sleep 1|echo y)| fakeroot mkfs -t ext3 $(target_boot_files_dir)/ramdisk
	$(Q) echo "NEEDS SUPER USER PERMISSIONS - could not get fusermount to work"
	$(Q)sudo mount -o loop -t ext3 $(target_boot_files_dir)/ramdisk $(target_boot_files_dir)/ramdisk-dir
	$(Q)sudo cp -a $(target_fs_dir)/* $(target_boot_files_dir)/ramdisk-dir
	$(Q)sudo chown -R root.root $(target_boot_files_dir)/ramdisk-dir/bin $(target_boot_files_dir)/ramdisk-dir/sbin
	$(Q)sudo umount $(target_boot_files_dir)/ramdisk-dir
	$(Q)rmdir $(target_boot_files_dir)/ramdisk-dir
	$(Q)gzip $(target_boot_files_dir)/ramdisk

$(BUSYBOX)/busybox: .config $(BUSYBOX)/.config
	$(Q)$(MAKE) -C $(BUSYBOX)

$(BUSYBOX)/.config: .config git
	$(Q)cp $(busybox_defconfig_file) $(BUSYBOX)/.config
	$(Q)$(MAKE) -C $(BUSYBOX) oldconfig

kernel: git fs .config $(kernel)/$(kernel_image_location)
	$(Q)$(MAKE) -C$(kernel) INSTALL_MOD_STRIP=1 \
	INSTALL_MOD_PATH=$(target_fs_dir) modules_install
	$(Q)install -d $(target_boot_files_dir)
	$(Q)install $(kernel)/$(kernel_image_location) $(target_boot_files_dir)
ifneq ("$(kernel_dtb)", "")
	$(Q)install $(kernel)/$(kernel_dtb) $(target_boot_files_dir)
endif

$(kernel)/$(kernel_image_location): .config $(kernel)/.config
	$(Q)$(MAKE) -C $(kernel) $(kernel_image)
	$(Q)$(MAKE) -C $(kernel) modules
ifneq ("$(kernel_dtb)", "")
	$(Q)$(MAKE) -C $(kernel) dtbs
endif

$(kernel)/.config: .config git
	$(Q)if [ -f $(kernel_defconfig) ]; then \
		cp $(kernel_defconfig) $(kernel)/.config && \
		$(MAKE) -C $(kernel) oldconfig;\
	else\
		$(MAKE) -C $(kernel) $(kernel_defconfig);\
	fi;

%config: git
	$(Q)$(MAKECONFIG) $(if $(VERBOSE:0=),-v) -d $(CONFIG_DIR) -c $@

utils: git
	$(Q) install -d $(host_binaries)
	$(Q) $(MAKE) -C $(host_utils) all usb
	$(Q) install $(host_utils)/pusb  $(host_utils)/pserial \
		$(host_utils)/gpsign  $(host_utils)/ukermit  $(host_utils)/ucmd\
		$(host_binaries) 
