setenv fdtbaddr 0x80F80000
setenv loadaddr 0x80200000
setenv fatloaduimage fatload mmc 0:1 ${loadaddr} uImage
setenv bootargs console=ttyO2,115200n8 root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait earlyprintk
setenv loaddtb fatload mmc 0:1 ${fdtbaddr} omap4-panda-es.dtb; fdt addr ${fdtbaddr}; fdt resize
setenv bootwdtb bootm ${loadaddr} - ${fdtbaddr}
mw.w 0x4A31E05A 0x1f
printenv
echo "NOTE: booting from MMC filesystem"
sleep 1
run fatloaduimage
sleep 1
run loaddtb
echo "starting.."
sleep 1
run bootwdtb
