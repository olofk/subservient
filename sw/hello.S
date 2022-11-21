/*
 * hello.S : Hello world for subservient
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

/*
*
* Continuously read a string from memory and transmit each character (bitbang)
* like a UART over GPIO
*
*/
#define GPIO_ADDR 0x40000000

	/*
	a0 = GPIO address
	a1 = String address
	t0 = Character to write
	*/

.globl _start
_start:
	/* Load gpio address to a0 */
	li	a0, GPIO_ADDR

	/* Set GPIO high initially */
	addi	t0, zero, 1
	sb	t0, 0(a0)

loop:
	/* Load string address to a1 */
	la	a1, str

next_char:
	/* Read char from string */
	lbu	t0, 0(a1)

	/* If zero, we reached end of string and will reload first character */
	beqz	t0, loop

	/* Bitbanged UART loop */
	ori	t0, t0, 0x300
	slli	t0, t0, 1
1:	sb	t0, 0(a0)
	srli	t0, t0, 1

	/*
	 * Adding delay nops to achieve an approximate
	 * baud rate of 115200 at 100MHz
	*/
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bnez	t0, 1b

	/* Increase address to next char in string */
	addi	a1, a1, 1

	j	next_char

str:
	.section .data
	.string "Hi I'm subservient\n"
