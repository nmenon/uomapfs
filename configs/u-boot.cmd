# generate boot.scr the following way:
# mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'bootscr'
#    -d $(bootloader_cmd) $(target_boot_files_dir)/boot.scr
# matches with omap3-mkcard.sh utility here:
# http://git.openembedded.org/cgit.cgi/openembedded/tree/contrib/angstrom/omap3-mkcard.sh

# terminal on ttyO2
set console ttyO2,115200n8
# MMC partition is mmc0 partition2
setenv mmcroot /dev/mmcblk0p2 rw
# we'd like to move to btrfs at some point ahead
setenv mmcrootfstype ext3 rootwait rootflags=barrier=1

# setup the bootargs
setenv bootargs console=${console} root=${mmcroot} rootfstype=${mmcrootfstype} earlyprintk

# lets now execute
if run loaduimage; then bootm; fi;
