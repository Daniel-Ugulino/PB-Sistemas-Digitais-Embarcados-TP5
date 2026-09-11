// Biblioteca parse — conversoes texto<->numero e formatacao
//
// format_byte_to_decimal         : byte unsigned  -> decimal ASCII
// format_signed_byte_to_decimal  : byte signed    -> decimal ASCII (com sinal)
// format_ms_to_decimal           : ms 0..99999     -> decimal ASCII
// format_byte_to_hex             : byte -> 2 chars hex maiusculos

.section .rodata
hex_digits: .ascii "0123456789ABCDEF"

.section .text

// w0 = 0..255, x1 = dest  ->  x1 avancado (sem zeros a esquerda)
.global format_byte_to_decimal
format_byte_to_decimal:
    mov     w2, w0
    mov     w4, #100
    udiv    w5, w2, w4
    msub    w2, w5, w4, w2
    mov     w4, #10
    udiv    w6, w2, w4
    msub    w7, w6, w4, w2

    cbz     w5, fmt_byte_no_hund
    add     w5, w5, #'0'
    strb    w5, [x1], #1
    b       fmt_byte_tens

fmt_byte_no_hund:
    cbz     w6, fmt_byte_ones

fmt_byte_tens:
    add     w6, w6, #'0'
    strb    w6, [x1], #1

fmt_byte_ones:
    add     w7, w7, #'0'
    strb    w7, [x1], #1
    ret

// w0 = int8, x1 = dest  ->  x1 avancado
.global format_signed_byte_to_decimal
format_signed_byte_to_decimal:
    sxtb    w0, w0
    tbz     w0, #31, format_byte_to_decimal
    mov     w2, #'-'
    strb    w2, [x1], #1
    neg     w0, w0
    b       format_byte_to_decimal

// w0 = ms, x1 = dest  ->  x1 avancado
.global format_ms_to_decimal
format_ms_to_decimal:
    cbz     w0, fmt_ms_zero
    sub     sp, sp, #16
    mov     w2, w0
    mov     w3, #0

fmt_ms_next:
    mov     w4, #10
    udiv    w5, w2, w4
    msub    w6, w5, w4, w2
    add     w6, w6, #'0'
    strb    w6, [sp, w3, uxtw]
    add     w3, w3, #1
    mov     w2, w5
    cbnz    w2, fmt_ms_next

    subs    w4, w3, #1
fmt_ms_skip:
    cbz     w4, fmt_ms_put
    ldrb    w5, [sp, w4, uxtw]
    cmp     w5, #'0'
    b.ne    fmt_ms_put
    sub     w4, w4, #1
    b       fmt_ms_skip

fmt_ms_put:
    ldrb    w5, [sp, w4, uxtw]
    strb    w5, [x1], #1
    cbz     w4, fmt_ms_out
    sub     w4, w4, #1
    b       fmt_ms_put

fmt_ms_out:
    add     sp, sp, #16
    ret

fmt_ms_zero:
    mov     w2, #'0'
    strb    w2, [x1], #1
    ret

// w0 = byte, x1 = dest (2 chars)  ->  x1 avancado
.global format_byte_to_hex
format_byte_to_hex:
    stp     x29, x30, [sp, #-16]!
    ldr     x2, =hex_digits
    lsr     w3, w0, #4
    and     w4, w0, #0xF
    ldrb    w3, [x2, x3]
    ldrb    w4, [x2, x4]
    strb    w3, [x1], #1
    strb    w4, [x1], #1
    ldp     x29, x30, [sp], #16
    ret
