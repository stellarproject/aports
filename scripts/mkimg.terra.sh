profile_terra() {
        profile_standard
        kernel_cmdline="unionfs_size=512M console=tty0 console=ttyS0,115200"
        syslinux_serial="0 115200"
        kernel_flavors="terra"
        kernel_addons="zfs spl"
	apkovl="genapkovl-terra.sh"
	hostname="terra"
        apks="$apks iscsi-scst efibootmgr bash dialog vim zfs-scripts zfs zfs-utils-py
                cciss_vol_status lvm2 mdadm mkinitfs mtools
                parted rsync sfdisk syslinux unrar util-linux xfsprogs
                dosfstools ntfs-3g terraos-installer
                "
        local _k _a
        for _k in $kernel_flavors; do
                apks="$apks linux-$_k"
                for _a in $kernel_addons; do
                        apks="$apks $_a-$_k"
                done
        done
        apks="$apks linux-firmware"
}
