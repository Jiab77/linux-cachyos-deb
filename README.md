# CachyOS Kernel Builder

This repository contains a script for building the CachyOS kernel with various optimizations tailored to your system's CPU architecture. The script automates the process of configuring and optimizing the kernel build according to your hardware and preferences.

## Prerequisites

Before running the script, ensure you have the following prerequisites installed:

- `gcc`: The GNU Compiler Collection is required for detecting the CPU architecture.
- `whiptail`: For displaying dialog boxes in the script.

You can install these dependencies using your distribution's package manager.

## Features

The script offers a variety of configuration options:

- Auto-detection of CPU architecture for optimization.
- Selection of CachyOS specific optimizations.
- Configuration of CPU scheduler, LLVM LTO, tick rate, and more.
- Support for various kernel configurations such as NUMA, NR_CPUS, Hugepages, and LRU.
- Application of O3 optimization and performance governor settings.

## Usage

To use the script, follow these steps:

1. Clone the repository to your local machine.
2. Make the script executable with `chmod +x cachyos-deb.sh`.
3. Run the script with `./cachyos-deb.sh`.
4. Follow the on-screen prompts to select your desired kernel version and configurations, for:
   - Choose the kernel version.
   - Enable or disable CachyOS optimizations.
   - Configure the CPU scheduler, LLVM LTO, tick rate, NR_CPUS, Hugepages, LRU, and other system optimizations.
   - Select the preempt type and tick type for further system tuning.

## Advanced Configurations

The script includes advanced configuration options for users who want to fine-tune their kernel:

- **CachyOS Configuration**: Enable optimizations specific to CachyOS.
- **CPU Scheduler**: Choose between different schedulers like Cachy, PDS, or none.
- **LLVM LTO**: Select between Thin and Full LTO for better optimization.
- **KCFI**: Enable or disable KCFI optimization.
- **Tick Rate**: Configure the kernel tick rate according to your system's needs.
- **NR_CPUS**: Set the maximum number of CPUs/cores the kernel will support.
- **Hugepages**: Enable or disable Hugepages support.
- **LRU**: Configure the Least Recently Used memory management mechanism.
- **O3 Optimization**: Apply O3 optimization for performance improvement.
- **Performance Governor**: Set the CPU frequency scaling governor to performance.

## Install custom kernel

Once you have compiled your custom kernel, you can install it manually or use the dedicated script.

### Automatic installation

Once the custom kernel compiled and `.deb` files created, you can install it with the [cachyos-deb-install.sh](cachyos-deb-install.sh) script:

```console
sudo ./cachyos-deb-install.sh
```

Or check usage instructions that way:

```console
./cachyos-deb-install.sh --help
```

> You can also use the shorthand flag `-h` instead if you prefer.

### Manual installation

Once the custom kernel compiled and `.deb` files created, you can install it that way:

1. Install created `.deb` files:

```console
sudo dpkg -i /path/to/linux-<version>/*.deb
```

2. Check `/boot` partition size (__This step is very important!__)

```console
# Total size
$ lsblk -npr -x MOUNTPOINT -o FSSIZE,MOUNTPOINT | grep -m1 /boot

# Free size
$ lsblk -npr -x MOUNTPOINT -o FSAVAIL,MOUNTPOINT | grep -m1 /boot
```

> __/!\\ Warning /!\\__
>
> If your `/boot` partition size is smaller than 1GB, __it will not work!!__.
>
> Don't even try to force it as the next step which is creating the `initramfs` file will simply fail!
>
> You may end with a broken bootloader..

<!--
> __/!\\ Warning /!\\__
>
> If your `/boot` partition size is smaller than 1GB, __you will have to edit your `initramfs` config__.
>
> Don't even try to force it or skip the configuration change as the next step which is creating the `initramfs` file will simply fail!

3. Enable [DEP](https://forum.doozan.com/read.php?2,135322) module

```console
sudo cp -v /etc/initramfs-tools/initramfs.conf /etc/initramfs-tools/initramfs.conf.original
sudo sed -e 's|MODULES=most|MODULES=dep|' -i /etc/initramfs-tools/initramfs.conf
```
-->

3. Create the `initramfs` file

```console
sudo update-initramfs -c -k <version>
```

> You can add `-v` to the command above if you want a __verbose__ ouput.

4. Update `grub` bootloader config

```console
sudo update-grub
```

6. Reboot

## Remove custom kernel

To remove the installed custom kernel, just run the following command:

```console
sudo apt remove --purge custom-kernel-*<version>*
```

## Contributing

Contributions are welcome! If you have suggestions for improving the script or adding new features, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
