#!/bin/bash

set -e
set -u

ROOTFSDIR="$BASE_DIR/target"
OUTPUTDIR="$BASE_DIR/images"
BOARDDIR="$PWD/board/develer/develboard"

echo "Prepend AT91 nand flash header to bootstrap"
"$BOARDDIR"/at91_nand_header.sh \
	"$OUTPUTDIR"/sama5d4_xplained-nandflashboot-uboot-3.7.1.bin \
	"$OUTPUTDIR"/at91bootstrap.bin

#
# systemd specific
#

if grep -q 'BR2_INIT_SYSTEMD=y' "${BR2_CONFIG}"; then
    echo "Remove sysvinit compatibility scripts"
    rm -rf "$ROOTFSDIR/etc/init.d"
    rm -rf "$ROOTFSDIR/etc/network"

    echo "Disable dropbear.service"
    rm -f "$ROOTFSDIR/etc/systemd/system/multi-user.target.wants/dropbear.service"

    echo "Enable dropbear.socket (socket activation)"
    ln -sf "$ROOTFSDIR/etc/systemd/system/dropbear.socket" "$ROOTFSDIR/etc/systemd/system/multi-user.target.wants/dropbear.socket"

    echo "Enforce dynamic hostname regeneration through genhostname.service"
    rm -f "$ROOTFSDIR/etc/hostname"
    ln -sf "$ROOTFSDIR/etc/systemd/system/genhostname.service" "$ROOTFSDIR/etc/systemd/system/multi-user.target.wants/genhostname.service"

    echo "Disable unnecessary services"
    find "$ROOTFSDIR" -type f -iname 'systemd-logind.service' -delete
    find "$ROOTFSDIR" -type f -iname 'systemd-remount-fs.service' -delete
    find "$ROOTFSDIR" -type f -iname 'systemd-udev-hwdb-update.service' -delete
    find "$ROOTFSDIR" -type f -iname 'systemd-user-sessions.service' -delete
fi

echo "Done"
