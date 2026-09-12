.include "macros.inc"

.equ STX,      0x02
.equ ETX,      0x03
.equ TYPE_TEL, 0x20
.equ TEL_LEN,  11
.equ TEL_PAY,  8

.extern filt_push
.extern cfg_dist_free
.extern config_send

.section .bss
.align 8
.global tel_pkt
tel_pkt:      .skip 16
tel_last_pay: .skip 8
tel_seen:     .byte 0
tel_time_start: .skip 16
tel_time_end:   .skip 16

.section .data
.align 8
nsec_per_sec: .quad 1000000000
.global spi_rtt_ms
spi_rtt_ms:   .word 0

.section .text

tel_update_rtt:
    ldr     x0, =tel_time_start
    ldr     x2, [x0]
    ldr     x3, [x0, #8]
    ldr     x0, =tel_time_end
    ldr     x4, [x0]
    ldr     x5, [x0, #8]

    sub     x6, x4, x2
    subs    x7, x5, x3
    b.ge    tel_rtt_nsec_ok
    sub     x6, x6, #1
    ldr     x8, =nsec_per_sec
    ldr     x8, [x8]
    add     x7, x7, x8

tel_rtt_nsec_ok:
    ldr     x8, =nsec_per_sec
    ldr     x8, [x8]
    mul     x9, x6, x8
    add     x9, x9, x7

    // SPI termina em <1 ms; converte ns -> us com arredondamento
    add     x9, x9, #500
    mov     w10, #1000
    udiv    w0, w9, w10
    ldr     x1, =spi_rtt_ms
    str     w0, [x1]
    ret

.global telemetry_poll
telemetry_poll:
    stp     x29, x30, [sp, #-16]!

    mov     x0, #CLOCK_MONOTONIC
    ldr     x1, =tel_time_start
    svc_call SYS_CLOCK_GETTIME

    bl      config_send

    ldr     x0, =tel_pkt
    str     xzr, [x0]
    str     xzr, [x0, #8]
    mov     x1, #TEL_LEN
    bl      spi_read_buf
    mov     w14, w0

    mov     x0, #CLOCK_MONOTONIC
    ldr     x1, =tel_time_end
    svc_call SYS_CLOCK_GETTIME
    bl      tel_update_rtt

    cmp     w14, #TEL_LEN
    b.ne    tel_fail

    ldr     x9, =tel_pkt
    pkt_expect_byte x9, 0, STX, tel_fail
    pkt_expect_byte x9, 1, TYPE_TEL, tel_fail
    pkt_expect_byte x9, 10, ETX, tel_fail

    add     x0, x9, #2
    bl      filt_push

    ldr     x10, =tel_seen
    ldrb    w3, [x10]
    cbz     w3, tel_novo

    ldr     x11, =tel_last_pay
    add     x12, x9, #2
    mov     w13, #0
tel_cmp:
    cmp     w13, #TEL_PAY
    b.ge    tel_ok
    ldrb    w0, [x12, w13, uxtw]
    ldrb    w1, [x11, w13, uxtw]
    cmp     w0, w1
    b.ne    tel_novo
    add     w13, w13, #1
    b       tel_cmp

tel_novo:
    mov     w3, #1
    strb    w3, [x10]

    ldr     x11, =tel_last_pay
    add     x12, x9, #2
    mov     w13, #0
tel_save:
    cmp     w13, #TEL_PAY
    b.ge    tel_saved
    ldrb    w0, [x12, w13, uxtw]
    strb    w0, [x11, w13, uxtw]
    add     w13, w13, #1
    b       tel_save

tel_saved:
    ldr     x0, =cfg_dist_free
    ldrb    w1, [x0]
    ldrb    w0, [x9, #3]
    cmp     w0, w1
    b.lo    tel_log
    ldrb    w0, [x9, #4]
    cmp     w0, w1
    b.lo    tel_log
    ldrb    w0, [x9, #5]
    cmp     w0, w1
    b.hs    tel_ok
tel_log:
    mov     x0, x9
    bl      log_telemetry

tel_ok:
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

tel_fail:
    mov     w0, #-1
    ldp     x29, x30, [sp], #16
    ret
