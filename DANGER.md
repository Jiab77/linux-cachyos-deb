# Dangerous troubleshooting commands that still may be useful

Before running all the commands below, you must be sure about what you are doing. A single error will render your whole system unable to boot anymore.

__We won't be responsible if you break your system by running them.__

We've used them to debug issues related to boot partitions being too small to be used to store the compiled custom kernel.

## Dangerous small boot partition size workarounds

If your `/boot` partition size is smaller than 2GB but still bigger than 1GB, you can try the following (and dangerous) workarounds in the next sections.

### 1. Using `/tmp` folder trick

* Create temporary boot folder

```console
mkdir -v /tmp/boot
```

* Copy `/boot` partition content

```console
cp -rav /boot/* /tmp/boot/
```

* Create `initramfs` file

```console
sudo update-initramfs -v -c -k <version> -b /tmp/boot/
```

* Check created `initrd` files

```console
ls -halF /tmp/boot
```

* Copy created `initrd` files to original `/boot` partition

```console
cp -rauv /tmp/boot/* /boot/
```

### 2. Using the `bind` mount trick

* Get the device behind the `/boot` partition

```console
BOOT_DEVICE=$(mount | grep -v /efi | grep /boot | cut -d" " -f1) ; echo "$BOOT_DEVICE"
```

* Get the mount options of the `/boot` partition

```console
BOOT_MNT_OPTS=$(mount | grep -v /efi | grep /boot | cut -d" " -f6) ; BOOT_MNT_OPTS="${BOOT_MNT_OPTS/\(/}" ; BOOT_MNT_OPTS="${BOOT_MNT_OPTS/\)/}" ; echo "$BOOT_MNT_OPTS"
```

* Create temporary boot folder

```console
mkdir -v /tmp/boot
```

* Copy `/boot` partition content

```console
cp -rav /boot/* /tmp/boot/
```

* Unmount `/boot` partition

```console
sudo umount -v /boot
```

* Create `bind` mount

```console
sudo mount -v --bind /tmp/boot /boot
```

* Create `initramfs` file

```console
sudo update-initramfs -v -c -k <version>
```

* Remove `bind` mount

```console
sudo umount -v /boot
```

* Mount original `/boot` partition

```console
sudo mount -v $BOOT_DEVICE /boot -o $BOOT_MNT_OPTIONS
```

* Check created `initrd` files

```console
ls -halF /tmp/boot
```

* Copy created `initrd` files to original `/boot` partition

```console
cp -rauv /tmp/boot/* /boot/
```

If everything went well until there, you can reboot and you should normally see and boot onto your custom kernel.
