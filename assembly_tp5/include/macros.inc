// Macros parametrizadas — padroes reais deste firmware
//
//   .include "macros.inc"
//
.include "syscall.inc"

// --- Syscall ---

.macro svc_call sysnum
    mov     x8, #\sysnum
    svc     #0
.endm

// --- Escrita (terminal, log, SPI) ---

// write(fd, buf, len) com buf/len ja em x1/x2
.macro write_out fd
    mov     x0, #\fd
    svc_call SYS_WRITE
.endm

// write(fd, &texto, &rotulo_tamanho) — par simbolos em .data
.macro write_str fd, text, lenlbl
    mov     x0, #\fd
    ldr     x1, =\text
    ldr     x2, =\lenlbl
    ldr     x2, [x2]
    svc_call SYS_WRITE
.endm

// --- Montagem de buffer (ui.s, log.s) ---

// x1=dest: copia string; x1 avanca (copy_n_bytes)
.macro buf_append text, lenlbl
    ldr     x2, =\text
    ldr     x3, =\lenlbl
    ldr     w3, [x3]
    bl      copy_n_bytes
.endm

// x1=dest, base+offset -> format_byte_to_decimal -> x1 avanca
.macro append_decimal_byte_at base, offset
    ldrb    w0, [\base, #\offset]
    bl      format_byte_to_decimal
.endm

// x1=dest, base+offset -> format_signed_byte_to_decimal -> x1 avanca
.macro append_decimal_sbyte_at base, offset
    ldrb    w0, [\base, #\offset]
    bl      format_signed_byte_to_decimal
.endm

// --- Descritores de arquivo (spi.s, log.s) ---

.macro fd_load ptr, reg=x0
    ldr     \reg, =\ptr
    ldr     \reg, [\reg]
.endm

.macro fd_skip_if_lt ptr, skip, reg=x0
    fd_load \ptr, \reg
    cmp     \reg, #0
    b.lt    \skip
.endm

// read/write/read em fd global: entrada x0=buf x1=len; retorna via syscall
.macro fd_transfer ptr, sysnum
    stp     x29, x30, [sp, #-32]!
    stp     x0, x1, [sp, #16]
    fd_load \ptr
    cmp     x0, #0
    b.lt    .Lfd_fail\@
    ldp     x1, x2, [sp, #16]
    svc_call \sysnum
    ldp     x29, x30, [sp], #32
    ret
.Lfd_fail\@:
    mov     x0, #-1
    ldp     x29, x30, [sp], #32
    ret
.endm

// --- Protocolo SPI (telemetry.s, config.s) ---

.macro pkt_expect_byte base, offset, value, fail
    ldrb    w0, [\base, #\offset]
    cmp     w0, #\value
    b.ne    \fail
.endm
