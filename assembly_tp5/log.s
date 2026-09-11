.include "macros.inc"

.section .data
log_path: .asciz "spi_log.txt"
newline:  .ascii "\n"

msg_vel_inc:    .ascii "Vel. max aumentada para "
msg_vel_inc_len: .quad . - msg_vel_inc
msg_vel_dec:    .ascii "Vel. max reduzida para "
msg_vel_dec_len: .quad . - msg_vel_dec
msg_vel_unit:   .ascii " km/h"
msg_vel_unit_len: .quad . - msg_vel_unit

msg_risk_inc:   .ascii "Zona de risco aumentada: livre="
msg_risk_inc_len: .quad . - msg_risk_inc
msg_risk_dec:   .ascii "Zona de risco reduzida: livre="
msg_risk_dec_len: .quad . - msg_risk_dec
msg_mid_att:    .ascii " m atencao="
msg_mid_att_len: .quad . - msg_mid_att
msg_mid_unit:   .ascii " m"
msg_mid_unit_len: .quad . - msg_mid_unit

msg_log_pre:    .ascii "Log - "
msg_log_pre_len: .quad . - msg_log_pre
msg_avg_pre:    .ascii "AVG - "
msg_avg_pre_len: .quad . - msg_avg_pre
msg_tel_vel:    .ascii "vel="
msg_tel_vel_len: .quad . - msg_tel_vel
msg_tel_e:      .ascii " dist_e="
msg_tel_e_len:  .quad . - msg_tel_e
msg_tel_c:      .ascii " dist_c="
msg_tel_c_len:  .quad . - msg_tel_c
msg_tel_d:      .ascii " dist_d="
msg_tel_d_len:  .quad . - msg_tel_d
msg_tel_dir:    .ascii " dir="
msg_tel_dir_len: .quad . - msg_tel_dir

dir_str_frente:   .ascii "frente"
dir_len_frente:   .quad . - dir_str_frente
dir_str_esquerda: .ascii "esquerda"
dir_len_esquerda: .quad . - dir_str_esquerda
dir_str_direita:  .ascii "direita"
dir_len_direita:  .quad . - dir_str_direita
dir_str_tras:     .ascii "tras"
dir_len_tras:     .quad . - dir_str_tras

.align 3
dir_lut_ptr:
    .quad dir_str_frente
    .quad dir_str_esquerda
    .quad dir_str_direita
    .quad dir_str_tras
dir_lut_len:
    .quad dir_len_frente
    .quad dir_len_esquerda
    .quad dir_len_direita
    .quad dir_len_tras

msg_tel_ve:     .ascii " vel_e="
msg_tel_ve_len: .quad . - msg_tel_ve
msg_tel_vc:     .ascii " vel_c="
msg_tel_vc_len: .quad . - msg_tel_vc
msg_tel_vd:     .ascii " vel_d="
msg_tel_vd_len: .quad . - msg_tel_vd
msg_session:    .ascii "---------------NEW INIT -------------------"
msg_session_len: .quad . - msg_session
msg_sep:        .ascii "----------------------------------------------------------------------------------"
msg_sep_len:    .quad . - msg_sep

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max
.extern filt_pkt

.section .bss
.align 8
log_fd:       .skip 8
log_line_buf: .skip 128

.section .text

.global log_init
log_init:
    stp     x29, x30, [sp, #-16]!

    mov     x0, #AT_FDCWD
    ldr     x1, =log_path
    mov     x2, #O_WRONLY
    orr     x2, x2, #O_CREAT
    orr     x2, x2, #O_APPEND
    mov     x3, #MODE_0644
    svc_call SYS_OPENAT

    ldr     x1, =log_fd
    str     x0, [x1]

    ldr     x0, =msg_session
    ldr     x1, =msg_session_len
    ldr     x1, [x1]
    bl      log_write

    ldp     x29, x30, [sp], #16
    ret

.global log_write
log_write:
    stp     x29, x30, [sp, #-32]!
    stp     x0, x1, [sp, #16]

    fd_skip_if_lt log_fd, log_write_skip
    ldp     x1, x2, [sp, #16]
    svc_call SYS_WRITE

    fd_load log_fd
    ldr     x1, =newline
    mov     x2, #1
    svc_call SYS_WRITE
log_write_skip:
    ldp     x29, x30, [sp], #32
    ret

log_format_dir:
    and     w0, w0, #3
    ldr     x2, =dir_lut_ptr
    ldr     x2, [x2, w0, uxtw #3]
    ldr     x3, =dir_lut_len
    ldr     x3, [x3, w0, uxtw #3]
    ldr     w3, [x3]
    b       copy_n_bytes

log_format_fields:
    stp     x29, x30, [sp, #-16]!

    buf_append msg_tel_vel, msg_tel_vel_len
    append_decimal_byte_at x19, 2
    buf_append msg_vel_unit, msg_vel_unit_len

    buf_append msg_tel_e, msg_tel_e_len
    append_decimal_byte_at x19, 3

    buf_append msg_tel_c, msg_tel_c_len
    append_decimal_byte_at x19, 4

    buf_append msg_tel_d, msg_tel_d_len
    append_decimal_byte_at x19, 5

    buf_append msg_tel_ve, msg_tel_ve_len
    append_decimal_sbyte_at x19, 6

    buf_append msg_tel_vc, msg_tel_vc_len
    append_decimal_sbyte_at x19, 7

    buf_append msg_tel_vd, msg_tel_vd_len
    append_decimal_sbyte_at x19, 8

    buf_append msg_tel_dir, msg_tel_dir_len
    ldrb    w0, [x19, #9]
    bl      log_format_dir

    ldp     x29, x30, [sp], #16
    ret

.section .rodata
.align 3
log_action_table:
    .quad log_action_vel_inc
    .quad log_action_vel_dec
    .quad log_action_risk_inc
    .quad log_action_risk_dec
.equ LOG_ACTION_MAX, 3

.section .text

.global log_control_action
log_control_action:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]

    mov     w19, w0
    adr     x20, log_line_buf
    mov     x1, x20

    sub     w2, w19, #1
    cmp     w2, #LOG_ACTION_MAX
    b.hi    log_action_done

    ldr     x3, =log_action_table
    ldr     x3, [x3, w2, uxtw #3]
    br      x3

log_action_vel_inc:
    buf_append msg_vel_inc, msg_vel_inc_len
    b       log_action_vel_value

log_action_vel_dec:
    buf_append msg_vel_dec, msg_vel_dec_len

log_action_vel_value:
    adr     x9, cfg_vel_max
    append_decimal_byte_at x9, 0
    buf_append msg_vel_unit, msg_vel_unit_len
    b       log_action_emit

log_action_risk_inc:
    buf_append msg_risk_inc, msg_risk_inc_len
    b       log_action_risk_values

log_action_risk_dec:
    buf_append msg_risk_dec, msg_risk_dec_len

log_action_risk_values:
    adr     x9, cfg_dist_free
    append_decimal_byte_at x9, 0
    buf_append msg_mid_att, msg_mid_att_len
    adr     x9, cfg_dist_att
    append_decimal_byte_at x9, 0
    buf_append msg_mid_unit, msg_mid_unit_len

log_action_emit:
    sub     x1, x1, x20
    mov     x0, x20
    bl      log_write

log_action_done:
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

.global log_telemetry
log_telemetry:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]

    mov     x19, x0
    adr     x20, log_line_buf
    mov     x1, x20
    buf_append msg_log_pre, msg_log_pre_len
    bl      log_format_fields
    sub     x1, x1, x20
    mov     x0, x20
    bl      log_write

    ldr     x19, =filt_pkt
    adr     x20, log_line_buf
    mov     x1, x20
    buf_append msg_avg_pre, msg_avg_pre_len
    bl      log_format_fields
    sub     x1, x1, x20
    mov     x0, x20
    bl      log_write

    ldr     x0, =msg_sep
    ldr     x1, =msg_sep_len
    ldr     x1, [x1]
    bl      log_write

    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

.global log_close
log_close:
    fd_skip_if_lt log_fd, log_close_skip
    svc_call SYS_CLOSE
log_close_skip:
    ret
