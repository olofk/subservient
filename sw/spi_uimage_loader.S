	/* Assembly program to go into the boot ROM
	   For use with the simple_spi core and standard SPI flash
	   interface-compatible parts (ST M25P16 for example.)

	   Loads an image in the U-boot uimage format from SPI Flash
	   in the the RAM at the address specified in the uimage header.
	   After loading is completed, it will jump to the entry point
	   address specified in the uimage header.

	   To keep it simple, only basic sanity checks are made on the image
	*/

/* Base address of the SPI controller used to communicate with the Flash */
#ifndef SPI_BASE
#define SPI_BASE 0xC0000000
#endif

/* 24-bit address in SPI Flash where application image is stored */
#ifndef BOOTROM_ADDR
#define BOOTROM_ADDR 0x000000
#endif

/* Flash needs 300 us to warm up from power-on. In practice, this is only an
   issue in simulations as FPGA boot is far longer than 300 us
*/
#ifndef INIT_DELAY
#define INIT_DELAY 700
#endif

#define RETRIES     3

#define SPI_SPCR 0x00
#define SPI_SPSR 0x04
#define SPI_SPDR 0x08
#define SPI_SPER 0x0C
#define SPI_SPSS 0x10

#define SPI_SPSS_INIT 0x1
#define SPI_SPSR_RX_CHECK 0x01 /* Check bit 0 is cleared, fifo !empty*/

	/* Registers used
	ra link register
	t1 temp register
	t2 temp register
	s0 Image size
	s1 Load address
	s2 Reset vector
	s3 Retry counter
	gp SPI master base address
	a3 get_rx_data return value
	t3 temp register
	*/
	.globl _start
_start:
.globl spi_boot
spi_boot:
	mv a1, zero
	/* Load SPI base address to gp */
	li gp, SPI_BASE

//	li s3, RETRIES
spi_init:
	/* Clear slave selects */
	sb	zero, SPI_SPSS(gp)
//	fence

	/* Set clock divider to 4 (arbitrarily chosen value)
	and enable controller */
	addi	t1, zero, 0x40 | 0x01
	sb	t1, SPI_SPCR(gp)

	/* Set appropriate slave select */
	addi	t1, zero, 1
	sb	t1, SPI_SPSS(gp)

	/* Set command to READ at BOOTROM_ADDR */
	li	a0, ((BOOTROM_ADDR & 0xFF) <<24) | ((BOOTROM_ADDR & 0xFF00) << 8) | ((BOOTROM_ADDR & 0xFF0000) >> 8) | 0x3
	jal	spi_xfer

	/* Get magic word */
	jal	spi_xfer

	/* Verify that magic word is (endian-swapped) 0x27051956
	Retry a couple of times before we give up */
//	addi	s3, s3, -1
//boot_fail:	beqz	s3, boot_fail
	li	t1, 0x56190527
	bne	t1, a1, spi_init


read_header:
	/* Dummy read two words */
	jal	spi_xfer
	jal	spi_xfer

	/* Load image size to s0 */
	jal	spi_xfer
	jal	endian_swap
	mv	s0, a2

	/* Load RAM base address to s1 */
	jal	spi_xfer
	jal	endian_swap
	mv	s1, a2

	/* Load reset vector to s2 */
	jal	spi_xfer
	jal	endian_swap
	mv	s2, a2

	/* Dummy last ten words of header */
	li	s4, 10
flush_header:
	addi	s4, s4, -1
	jal	spi_xfer
	bne	s4, zero, flush_header

	/* We know s4 = 0, so use that as counter for number of copied bytes */
copy_to_ram:
	jal	spi_xfer

	/* Set memory store address */
	add	t1, s1, s4

	/* Write word to RAM */
	sw	a1, 0(t1)

	/* Increase counter */
	addi	s4, s4, 4

	/* Check if file is completely copied */
	blt	s4, s0, copy_to_ram

	/* Jump to entry point */
goto_reset:
	jr	s2

	/* Reads ddccbbaa from a1, stores aabbccdd to a2 */
endian_swap:
	slli	a2, a1, 24   // a2 = aa000000
	srli	t1, a1, 8    // t1 = 00ddccbb
	andi	t1, t1, 0xff // t1 = 000000bb
	slli	t1, t1, 16   // t1 = 00bb0000
	or	a2, a2, t1   // a2 = aabb0000

	srli	t1, a1, 16   // t1 = 0000ddcc
	andi	t1, t1, 0xff // t1 = 000000cc
	slli	t1, t1, 8    // t1 = 0000cc00
	or	a2, a2, t1   // a2 = aabbcc00

	srli	t1, a1, 24   // t1 = 000000dd
	or	a2, a2, t1   // a2 = aabbccdd

	ret

spi_xfer:
	/* Loop four times */
	addi	t0, zero, 4

spi_xfer_loop:
	/* Send data in a0[7:0] */
	sb	a0, SPI_SPDR(gp)

spi_xfer_poll:
	/* Wait for data in RX FIFO */
	lbu	t1, SPI_SPSR(gp)
	andi	t1, t1, SPI_SPSR_RX_CHECK
	bnez	t1, spi_xfer_poll

	/* Shift down current word to make place at bits 31:24 */
	srli	a1, a1, 8
	/* Read RX FIFO and shift to bits 31:24 */
	lbu	t1, SPI_SPDR(gp)
	slli	t1, t1, 24
	/* Combine old and new data */
	or	a1, a1, t1

	/* Shift in next TX byte */
	srli	a0, a0, 8

	addi	t0, t0, -1
	bnez	t0, spi_xfer_loop

	ret
