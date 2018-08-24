`dtbocfg` - Device Tree Blob Overlay Configuration File System
==================================================

# Overview

## Device Tree Overlay

Device Tree Overlay is a mechanism that enables dynamic loading/unloading of a new device tree blob
on top of the kernel device tree. Device Tree Overlay was first introduced in Linux Kernel version 3.19.

## `dtbocfg`  - Device Tree Overlay Configuration File System

Linux Kernel Version 4.4.4, the latest at the time of writing (2016-04-04), supports device tree overlay,
but the mechanism can only be accessible from the kernel space. A certain interface is need, when using
device tree overlay from the userspace.

For example, "[Transactional Device Tree & Overlays](http://events.linuxfoundation.org/sites/events/files/slides/dynamic-dt-elce14.pdf)"
describes an interface using ConfigFS, but this has not been merged to the upstream at the time of writing (2016-04-04).

Therefore, `dtbocfg`, which stands for Device Tree Blob Overlay Configuration File System, was developed
to serve as a userspace API of Device Tree Overlay. Though this is a prototypical project, you can experiment
with Device Tree Overlay by using `dtbocfg`.

## Similar project

In some forked kernels such as `linux-xlnx`, the "ConfigFS overlay interface" is available, and provides
an interface to overlay Device Tree Blob from the userspace via ConfigFS. If you use `linux-xlnx` or any
other kernel that includes the "ConfigFS overlay interface", one may want to use this mechanism instead
of `dtbocfg`, by turning it on by `CONFIG_OF_CONFIGFS=y` in the config.

For details of the "ConfigFS overlay interface", please refer
[configfs-overlays.txt](https://raw.githubusercontent.com/Xilinx/linux-xlnx/master/Documentation/devicetree/configfs-overlays.txt).

# Preparation

## Building the Linux Kernel

This project is confirmed to work with Linux Kernel version 4.4.4.

When building a kernel, Device-Tree-Overlay option should be enabled.
You can enable the option via `make menu_config` ---> `Device Drivers` ---> `Device Tree and Open Firmware support`
---> `Device Tree overlays`, or by manually addting `CONFIG_OF_OVERLAY=y` in `.config`.

## Builiding dtbocfg

Clone the git repository, and run `make` after modifying it according to your environment.

````shell
shell% git clone https://github.com/ikwzm/dtbocfg.git
shell% cd dtbocfg
shell% make
````

After booting Linux on the target system, load the above-compiled device driver by doing like:

````shell
shell# insmod dtbocfg.ko
[ 1458.894102] dtbocfg_module_init
[ 1458.897231] dtbocfg_module_init: OK
````

If ConfigFS is not mounted yet, do so by doing like:

````shell
shell# mount -t configfs none /config
````

If `/config/device-tree/overlays` is created, it is ready to use `dtbocfg`.

````shell
shell# ls -la /config/device-tree/overlays/
drwxr-xr-x 2 root root 0  4  4 18:54 .
drwxr-xr-x 3 root root 0  4  4 18:54 ..
shell#
````

# Example usage

## Overlyaing uio (User I/O)

### Prepare Device Tree Source

The following snippet shows an example Device Tree Source that adds uio entity.

Note: the register address, the interrupt number are just randomly picked in the snippet,
and therefore you cannot actually access the created device.

````uio0.dts
/dts-v1/;
/ {
	fragment@0 {
		target-path = "/amba";
		__overlay__ {
			#address-cells = <0x1>;
			#size-cells = <0x1>;
			uio0@43c10000 {
				compatible = "generic-uio";
				reg = <0x43c10000 0x1000>;
				interrupts = <0x0 0x1d 0x4>;
			};
		};
	};
};
````

### Create a directory in ConfigFS

To place a device tree blob overlay, make a directory under `/config/device-tree/overlays`.
The name of the directory actually does not matter, but in this example, a directory named
`uio0`, which corresponds to the entry in the Device Tree Source, is created.

````
shell# mkdir /config/device-tree/overlays/uio0
````

Subsequently, entries named `status` and `dtbo` will be automatically created under
`/config/device-tree/overlays/uio0`. Although these look like standalone files, the are
actually kernel attirubutes exposed by `dtbocfg`.

````
shell# ls -la /config/device-tree/overlays/uio0/
drwxr-xr-x 2 root root    0  4  4 20:08 .
drwxr-xr-x 3 root root    0  4  4 20:08 ..
-rw-r--r-- 1 root root 4096  4  4 20:09 dtbo
-rw-r--r-- 1 root root 4096  4  4 20:09 status
````

### Writing Device Tree Blob

Write a Device Tree Blob to `/config/device-tree/overlays/uio0/dtbo`.

````
shell# dtc -I dts -O dtb -o uio0.dtbo uio0.dts
shell# cp uio0.dtbo /config/device-tree/overlays/uio0/dtbo
````

### Adding Device Tree Blob to Device Tree

The Device Tree Blob written to `dtbo` can be enabled and added to the main (kernel) Device Tree by
writing `1` to `/config/device-tree/overlays/uio0/status`.
If the blob is successfully added to the kernel Device Tree, `/dev/uio0` will be created, as decalred
in the blob.

````
shell# echo 1 > /config/device-tree/overlays/uio0/status
shell# ls -la /dev/uio*
crw------- 1 root root 247, 0  4  4 20:17 /dev/uio0
````

### Removing Device Tree Blob from Device Tree

The added Device Tree Blob can be removed from the kernel Device Tree by writing `0` to
`/config/device-tree/overlays/uio0/status`.

````
shell# echo 0 > /config/device-tree/overlays/uio0/status
````

The same can be achieved by removing `/config/device-tree/overlays/uio0` too.

````
shell# rmdir /config/device-tree/overlays/uio0
````

## Overlaying `udmabuf`

This is another overlaying exmple involving `udmabuf`.

For details about `udmabuf`, see [https://github.com/ikwzm/udmabuf](https://github.com/ikwzm/udmabuf).

### Prepare Device Tree Source

A Device Tree Source like below should be prepared:

````udmabuf4.dts
/dts-v1/;

/ {
	fragment@0 {
		target-path = "/amba";
		__overlay__ {
			udmabuf4 {
				compatible = "ikwzm,udmabuf-0.10.a";
				minor-number = <4>;
				size = <0x00400000>;
			};
		};
	};
};
````

### Create a directory in ConfigFS

To place a device tree blob overlay, make a directory under `/config/device-tree/overlays`.
Again, the name of the directory actually does not matter, and in this example, a directory named
`udmabuf4` is created.

````
shell# mkdir /config/device-tree/overlays/udmabuf4
````

### Load `udmabuf` device driver

Load the `udmabuf` device driver if not automatically loaded up on boot.

````
shell# insmod udmabuf.ko
````

### Writing Device Tree Blob

A compiled Device Tree Blob should be written to  `/config/device-tree/overlays/udmabuf4/dtbo`.
In this example, an output from Device Tree Compiler (`dtc`) is directly written to `dtbo`.

````
shell# dtc -I dts -O dtb -o /config/device-tree/overlays/udmabuf4/dtbo udmabuf4.dts
````

### Adding Device Tree Blob to Device Tree

Similarly to the above example, the Device Tree Blob can be added to the kernel Device Tree by
writing `1` to `/config/device-tree/overlays/udmabuf4/status`.
If the `udmabuf` device driver is already loaded, `/dev/udmabuf4` will be created as declared in
the Device Tree Blob.

````
shell# echo 1 > /config/device-tree/overlays/udmabuf4/status
[ 7256.806725] udmabuf amba:udmabuf4: driver probe start.
[ 7256.827450] udmabuf udmabuf4: driver installed
[ 7256.831818] udmabuf udmabuf4: major number   = 246
[ 7256.836631] udmabuf udmabuf4: minor number   = 4
[ 7256.841192] udmabuf udmabuf4: phys address   = 0x1f500000
[ 7256.846604] udmabuf udmabuf4: buffer size    = 4194304
[ 7256.851694] udmabuf amba:udmabuf4: driver installed.
shell# ls -la /dev/udmabuf*
crw------- 1 root root 247, 0  4  4 20:30 /dev/udmabuf4
````

### Removing Device Tree Blob from Device Tree

The added Device Tree Blob can be removed by writing `0` to 
`/config/device-tree/overlays/udmabuf4/status`.

````
shell# echo 0 > /config/device-tree/overlays/udmabuf4/status
[ 7440.383899] udmabuf udmabuf4: driver uninstalled
[ 7440.389533] udmabuf amba:udmabuf4: driver unloaded
````

Removing the `/config/device-tree/overlays/udmabuf4` directory would also do the same.

````
shell# rmdir /config/device-tree/overlays/udmabuf4/
[ 7473.117564] udmabuf udmabuf4: driver uninstalled
[ 7473.123364] udmabuf amba:udmabuf4: driver unloaded
````
