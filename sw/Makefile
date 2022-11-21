#
# Makefile: Makefile for building subservient firmware
#
# SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
RESET_VECTOR ?= 0
FLASH_ADDR ?= 0x0

%.elf: start.S %.c
	$(TOOLCHAIN_PREFIX)gcc -Os -march=rv32i -mabi=ilp32 -nostdlib -o $@ \
		-Wl,-Bstatic,-Tlink.ld $^

%.elf: %.S
	$(TOOLCHAIN_PREFIX)gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -o$@ $<
%.hex: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@
%.bin: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

%.ub: %.bin
	mkimage \
	-A riscv \
	-C none \
	-T standalone \
	-a 0x0 \
	-e $(RESET_VECTOR) \
	-n '$@' \
	-d $< \
	$@

%.ubvh: %.ub
	objcopy --change-addresses $(FLASH_ADDR) -I binary -O verilog $< $@

clean:
	rm -f *.elf *.bin *.hex
