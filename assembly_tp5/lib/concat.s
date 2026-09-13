// Biblioteca concat — manipulacao de buffers
//
// copy_n_bytes : copia N bytes entre buffers

.section .text

// x1 = dest, x2 = src, w3 = count  ->  retorna x1 avancado
.global copy_n_bytes
copy_n_bytes:
    cbz     w3, copy_n_bytes_done
copy_n_bytes_loop:
    ldrb    w4, [x2], #1
    strb    w4, [x1], #1
    subs    w3, w3, #1
    b.ne    copy_n_bytes_loop
copy_n_bytes_done:
    ret
