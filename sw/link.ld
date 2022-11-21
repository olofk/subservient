/*
 * link.ld : Linker script for subservient SoC
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

OUTPUT_ARCH( "riscv" )
/*ENTRY(_start)*/

SECTIONS
{
  . = 0;
  .text : { *(.text) }
  .data : { *(.data) }
  .bss : { *(.bss) }
}
