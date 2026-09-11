// Biblioteca arith — operacoes aritmeticas com saturacao
//
// add_to_byte_saturated : soma delta a um byte e satura em 0..255

.section .text

// x9 = ponteiro para byte, w1 = delta  ->  *x9 saturado em 0..255
.global add_to_byte_saturated
add_to_byte_saturated:
    ldrb    w2, [x9]
    add     w2, w2, w1
    cmp     w2, #255
    mov     w3, #255
    csel    w2, w2, w3, le
    cmp     w2, #0
    csel    w2, w2, wzr, ge
    strb    w2, [x9]
    ret
