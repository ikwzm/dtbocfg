HOST_ARCH       ?= $(shell uname -m | sed -e s/arm.*/arm/ -e s/aarch64.*/arm64/)
ARCH            ?= $(shell uname -m | sed -e s/arm.*/arm/ -e s/aarch64.*/arm64/)
BUILD_DIR       ?= $(PWD)
_BUILD_DIR      ?= $(shell readlink -f $(BUILD_DIR))

CONFIG_OF_DTBOCFG ?= m

ifdef KERNEL_SRC
  KERNEL_SRC_DIR  := $(KERNEL_SRC)
else
  KERNEL_SRC_DIR  ?= /lib/modules/$(shell uname -r)/build
endif

ifeq ($(ARCH), arm)
 ifneq ($(HOST_ARCH), arm)
   CROSS_COMPILE  ?= arm-linux-gnueabihf-
 endif
endif
ifeq ($(ARCH), arm64)
 ifneq ($(HOST_ARCH), arm64)
   CROSS_COMPILE  ?= aarch64-linux-gnu-
 endif
endif

obj-$(CONFIG_OF_DTBOCFG) := dtbocfg.o

all:
	@# If this is an out-of-tree build, we have to create an empty makefile in the build directory
	@# (this is a hack to get around Makefile.modpost trying to include the makefile
	@#  and failing since we're doing a split build by setting src= inside the main Makefile)
	@( [ "$(BUILD_DIR)" != "$(PWD)" ] && (mkdir -p "$(BUILD_DIR)" && touch "$(BUILD_DIR)/Makefile") || true )

	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(_BUILD_DIR) src=$(PWD) modules

modules_install:
	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(_BUILD_DIR) src=$(PWD) modules_install

clean:
	$(MAKE) -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(_BUILD_DIR) src=$(PWD) clean

