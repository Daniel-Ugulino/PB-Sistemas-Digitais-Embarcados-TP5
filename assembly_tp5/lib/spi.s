// Enlace Raspberry Pi (master) -> Tang Nano (slave) via spidev.
// Cada write/read e UMA transacao SPI completa (CS baixo durante todos os bytes).

.include "macros.inc"

.equ SPI_IOC_WR_MODE,          0x40016B01
.equ SPI_IOC_WR_BITS_PER_WORD, 0x40016B03
.equ SPI_IOC_WR_MAX_SPEED_HZ,  0x40046B04

.section .data
spi_path:  .asciz "/dev/spidev0.0"
spi_mode:  .byte 0
spi_bits:  .byte 8
.align 2
spi_speed: .word 250000

.section .bss
.align 8
.global spi_fd
spi_fd: .skip 8

.section .text

.global spi_open
spi_open:
    stp     x29, x30, [sp, #-16]!
    mov     x0, #AT_FDCWD
    ldr     x1, =spi_path
    mov     x2, #O_RDWR
    mov     x3, #0
    svc_call SYS_OPENAT
    ldr     x1, =spi_fd
    str     x0, [x1]
    ldp     x29, x30, [sp], #16
    ret

.global spi_is_open
spi_is_open:
    fd_load spi_fd
    cmp     x0, #0
    cset    w0, ge
    ret

.global spi_configure
spi_configure:
    stp     x29, x30, [sp, #-16]!
    ldr     x1, =SPI_IOC_WR_MODE
    ldr     x2, =spi_mode
    bl      spi_ioctl
    ldr     x1, =SPI_IOC_WR_BITS_PER_WORD
    ldr     x2, =spi_bits
    bl      spi_ioctl
    ldr     x1, =SPI_IOC_WR_MAX_SPEED_HZ
    ldr     x2, =spi_speed
    bl      spi_ioctl
    ldp     x29, x30, [sp], #16
    ret

spi_ioctl:
    fd_skip_if_lt spi_fd, spi_ioctl_skip
    svc_call SYS_IOCTL
spi_ioctl_skip:
    ret

.global spi_write_buf
spi_write_buf:
    fd_transfer spi_fd, SYS_WRITE

.global spi_read_buf
spi_read_buf:
    fd_transfer spi_fd, SYS_READ

.global spi_close
spi_close:
    fd_skip_if_lt spi_fd, spi_close_skip
    svc_call SYS_CLOSE
spi_close_skip:
    ret
