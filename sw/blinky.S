/*
 * blinky.S : LED blink example firmware for the subservient SoC
 *
 * SPDX-FileCopyrightText: 2021 Olof Kindgren <olof.kindgren@gmail.com>
 * SPDX-License-Identifier: Apache-2.0
 */

/*
* Assuming that GPIO_BASE is mapped to a GPIO core, which in turn is
* connected to a LEDs, this will blink the LED.
* Useful as smoke test to see that serv is running correctly
*/
#ifndef GPIO_BASE
#define GPIO_BASE 0x40000000
#endif

#ifndef DELAY
#define DELAY 0x10 /* Loop this many times before inverting the LED */
#endif

	/*
	a0 = GPIO Base address
	t0 = Value
	t1 = Timer max value
	t2 = Current timer value
	*/

.globl _start
_start:
	/* Load GPIO base address to a0 */
	li	a0, GPIO_BASE

	/* Set timer value to control blink speed */
	li	t1, DELAY

	/* Clear t0 */
	addi	t0, zero, 0

	/* Write to LED */
bl1:	sb	t0, 0(a0)

	/* invert LED */
	xori	t0, t0, 1

	/* Reset timer */
	and	t2, zero, zero

	/* Delay loop */
time1:	addi	t2, t2, 1
	bne	t1, t2, time1
	j	bl1
