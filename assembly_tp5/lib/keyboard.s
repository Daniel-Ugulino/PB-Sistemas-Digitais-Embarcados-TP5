.include "macros.inc"

.section .bss
.align 8
orig_termios: .skip 64
raw_termios:  .skip 64
key_buf:      .skip 8

.section .text

.global keyboard_init
keyboard_init:
    stp     x29, x30, [sp, #-16]!

    mov     x0, #STDIN
    mov     x1, #TCGETS
    ldr     x2, =orig_termios
    svc_call SYS_IOCTL

    ldr     x1, =raw_termios
    ldr     x2, =orig_termios
    mov     w3, #64
    bl      copy_n_bytes

    ldr     x0, =raw_termios
    ldr     w1, [x0, #12]
    mov     w2, #ICANON
    orr     w2, w2, #ECHO
    bic     w1, w1, w2
    str     w1, [x0, #12]

    mov     w1, #0
    strb    w1, [x0, #17 + 6]
    strb    w1, [x0, #17 + 5]

    mov     x0, #STDIN
    mov     x1, #TCSETS
    ldr     x2, =raw_termios
    svc_call SYS_IOCTL

    ldp     x29, x30, [sp], #16
    ret

.global keyboard_restore
keyboard_restore:
    mov     x0, #STDIN
    mov     x1, #TCSETS
    ldr     x2, =orig_termios
    svc_call SYS_IOCTL
    ret

.global keyboard_read
keyboard_read:
    stp     x29, x30, [sp, #-16]!

    mov     x0, #STDIN
    ldr     x1, =key_buf
    mov     x2, #1
    svc_call SYS_READ

    cmp     x0, #1
    bne     kb_nothing

    ldr     x1, =key_buf
    ldrb    w0, [x1]

    cmp     w0, #0x0A
    beq     kb_nothing
    cmp     w0, #0x0D
    beq     kb_nothing
    b       kb_read_done

kb_nothing:
    mov     w0, #-1

kb_read_done:
    ldp     x29, x30, [sp], #16
    ret
