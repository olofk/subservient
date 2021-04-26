#
# Makefile: Makefile for building subservient firmware
#
# SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
# SPDX-License-Identifier: Apache-2.0
#
TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-

%.elf: %.S
	$(TOOLCHAIN_PREFIX)gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -o$@ $<
%.hex: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@
%.bin: %.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
clean:
	rm -f *.elf *.bin *.hex
