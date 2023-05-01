.section .text
_start:
	li sp, 0x300
	call main
	lui a0, %hi(0x90000000)
	sw zero, 0(a0)
