KERNEL_SRC_DIR=$(HOME)/work/linux-4.4.4

obj-m := dtbocfg.o

all:
	make -C $(KERNEL_SRC_DIR) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- M=$(PWD) modules

clean:
	make -C $(KERNEL_SRC_DIR) ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- M=$(PWD) clean

