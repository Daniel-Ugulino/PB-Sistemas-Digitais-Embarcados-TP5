.include "macros.inc"

.section .data
clear_seq:        .ascii "\x1b[2J\x1b[H"
clear_len:        .quad . - clear_seq
hide_cursor:      .ascii "\x1b[?25l"
hide_cursor_len:  .quad . - hide_cursor
show_cursor:      .ascii "\x1b[?25h"
show_cursor_len:  .quad . - show_cursor

label_input:      .ascii "\x1b[2;2HUltima tecla: "
label_input_len:  .quad . - label_input

pos_key_echo:      .ascii "\x1b[2;19H"
pos_key_echo_len:  .quad . - pos_key_echo

quit_hint:      .ascii "\x1b[4;2HWASD para ajustar, 'q' para sair"
quit_hint_len:  .quad . - quit_hint

pos_help:      .ascii "\x1b[6;2H"
pos_help_len:  .quad . - pos_help

help_text:      .ascii "W: +vel max | S: -vel max | A: +zona risco | D: -zona risco"
help_text_len:  .quad . - help_text

pos_config:     .ascii "\x1b[3;2H\x1b[K"
pos_config_len: .quad . - pos_config

pos_spi:        .ascii "\x1b[7;2H\x1b[K"
pos_spi_len:    .quad . - pos_spi
msg_spi_ok:     .ascii "SPI conectado com sucesso (Tang respondeu)"
msg_spi_ok_len: .quad . - msg_spi_ok
msg_spi_wait:   .ascii "SPI: /dev/spidev0.0 ok, aguardando Tang (GPIO9->pin81 MISO + GND)"
msg_spi_wait_len: .quad . - msg_spi_wait
pos_spi_rx:     .ascii "\x1b[8;2H\x1b[K"
pos_spi_rx_len: .quad . - pos_spi_rx

lbl_stx:        .ascii "STX="
lbl_stx_len:    .quad . - lbl_stx
lbl_type:       .ascii " TYPE="
lbl_type_len:   .quad . - lbl_type
lbl_speed:      .ascii " speed="
lbl_speed_len:  .quad . - lbl_speed
lbl_dist_e:     .ascii " dist_e="
lbl_dist_e_len: .quad . - lbl_dist_e
lbl_dist_c:     .ascii " dist_c="
lbl_dist_c_len: .quad . - lbl_dist_c
lbl_dist_d:     .ascii " dist_d="
lbl_dist_d_len: .quad . - lbl_dist_d
lbl_vel_e:      .ascii " vel_e="
lbl_vel_e_len:  .quad . - lbl_vel_e
lbl_vel_c:      .ascii " vel_c="
lbl_vel_c_len:  .quad . - lbl_vel_c
lbl_vel_d:      .ascii " vel_d="
lbl_vel_d_len:  .quad . - lbl_vel_d
lbl_dir:        .ascii " dir="
lbl_dir_len:    .quad . - lbl_dir
lbl_etx:        .ascii " ETX="
lbl_etx_len:    .quad . - lbl_etx

rx_desc_buf:    .space 192
pos_spi_rtt:    .ascii "\x1b[9;2H\x1b[KRTT: "
pos_spi_rtt_len: .quad . - pos_spi_rtt
suffix_rtt_ms:  .ascii " us"
suffix_rtt_ms_len: .quad . - suffix_rtt_ms
rtt_buf:        .space 16
msg_spi_fail:   .ascii "SPI: /dev/spidev0.0 nao abriu"
msg_spi_fail_len: .quad . - msg_spi_fail

prefix_free:    .ascii "Zona livre: "
prefix_free_len: .quad . - prefix_free
mid_att:        .ascii " m | Atencao: "
mid_att_len:    .quad . - mid_att
mid_vel:        .ascii " m | Vel. max: "
mid_vel_len:    .quad . - mid_vel
suffix_vel:     .ascii " km/h"
suffix_vel_len: .quad . - suffix_vel

config_buf:     .space 64

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max
.extern tel_pkt
.extern spi_rtt_ms

.section .text

.global ui_init
ui_init:
    stp     x29, x30, [sp, #-16]!
    write_str STDOUT, clear_seq, clear_len
    write_str STDOUT, hide_cursor, hide_cursor_len
    write_str STDOUT, label_input, label_input_len
    write_str STDOUT, quit_hint, quit_hint_len
    write_str STDOUT, pos_help, pos_help_len
    write_str STDOUT, help_text, help_text_len
    ldp     x29, x30, [sp], #16
    ret

.global ui_show_key
ui_show_key:
    stp     x29, x30, [sp, #-16]!
    strb    w0, [sp, #-16]!
    write_str STDOUT, pos_key_echo, pos_key_echo_len
    mov     x1, sp
    mov     x2, #1
    write_out STDOUT
    add     sp, sp, #16
    ldp     x29, x30, [sp], #16
    ret

.global ui_show_config
ui_show_config:
    stp     x29, x30, [sp, #-32]!

    adr     x20, config_buf
    mov     x1, x20

    buf_append prefix_free, prefix_free_len
    adr     x9, cfg_dist_free
    append_decimal_byte_at x9, 0

    buf_append mid_att, mid_att_len
    adr     x9, cfg_dist_att
    append_decimal_byte_at x9, 0

    buf_append mid_vel, mid_vel_len
    adr     x9, cfg_vel_max
    append_decimal_byte_at x9, 0

    buf_append suffix_vel, suffix_vel_len

    sub     x21, x1, x20

    write_str STDOUT, pos_config, pos_config_len
    mov     x1, x20
    mov     x2, x21
    write_out STDOUT

    ldp     x29, x30, [sp], #32
    ret

ui_write_spi_line:
    stp     x29, x30, [sp, #-32]!
    stp     x19, x20, [sp, #16]
    mov     x19, x0
    mov     x20, x1
    write_str STDOUT, pos_spi, pos_spi_len
    mov     x1, x19
    mov     x2, x20
    write_out STDOUT
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret

.global ui_show_spi_ok
ui_show_spi_ok:
    ldr     x0, =msg_spi_ok
    ldr     x1, =msg_spi_ok_len
    ldr     x1, [x1]
    b       ui_write_spi_line

.global ui_show_spi_wait
ui_show_spi_wait:
    ldr     x0, =msg_spi_wait
    ldr     x1, =msg_spi_wait_len
    ldr     x1, [x1]
    b       ui_write_spi_line

.global ui_show_spi_fail
ui_show_spi_fail:
    ldr     x0, =msg_spi_fail
    ldr     x1, =msg_spi_fail_len
    ldr     x1, [x1]
    b       ui_write_spi_line

.global ui_show_spi_rx
ui_show_spi_rx:
    stp     x29, x30, [sp, #-48]!
    stp     x19, x20, [sp, #16]
    str     x21, [sp, #32]

    ldr     x19, =tel_pkt
    adr     x20, rx_desc_buf
    mov     x1, x20

    buf_append lbl_stx, lbl_stx_len
    ldrb    w0, [x19, #0]
    bl      format_byte_to_hex

    buf_append lbl_type, lbl_type_len
    ldrb    w0, [x19, #1]
    bl      format_byte_to_hex

    buf_append lbl_speed, lbl_speed_len
    ldrb    w0, [x19, #2]
    bl      format_byte_to_decimal

    buf_append lbl_dist_e, lbl_dist_e_len
    ldrb    w0, [x19, #3]
    bl      format_byte_to_decimal

    buf_append lbl_dist_c, lbl_dist_c_len
    ldrb    w0, [x19, #4]
    bl      format_byte_to_decimal

    buf_append lbl_dist_d, lbl_dist_d_len
    ldrb    w0, [x19, #5]
    bl      format_byte_to_decimal

    buf_append lbl_vel_e, lbl_vel_e_len
    ldrb    w0, [x19, #6]
    bl      format_signed_byte_to_decimal

    buf_append lbl_vel_c, lbl_vel_c_len
    ldrb    w0, [x19, #7]
    bl      format_signed_byte_to_decimal

    buf_append lbl_vel_d, lbl_vel_d_len
    ldrb    w0, [x19, #8]
    bl      format_signed_byte_to_decimal

    buf_append lbl_dir, lbl_dir_len
    ldrb    w0, [x19, #9]
    bl      format_byte_to_decimal

    buf_append lbl_etx, lbl_etx_len
    ldrb    w0, [x19, #10]
    bl      format_byte_to_hex

    sub     x21, x1, x20

    write_str STDOUT, pos_spi_rx, pos_spi_rx_len
    mov     x1, x20
    mov     x2, x21
    write_out STDOUT

    ldp     x19, x20, [sp, #16]
    ldr     x21, [sp, #32]
    ldp     x29, x30, [sp], #48
    ret

.global ui_show_spi_rtt
ui_show_spi_rtt:
    stp     x29, x30, [sp, #-32]!

    adr     x20, rtt_buf
    mov     x1, x20

    ldr     x0, =spi_rtt_ms
    ldr     w0, [x0]
    bl      format_ms_to_decimal
    buf_append suffix_rtt_ms, suffix_rtt_ms_len

    sub     x21, x1, x20

    write_str STDOUT, pos_spi_rtt, pos_spi_rtt_len
    mov     x1, x20
    mov     x2, x21
    write_out STDOUT

    ldp     x29, x30, [sp], #32
    ret

.global ui_restore
ui_restore:
    write_str STDOUT, show_cursor, show_cursor_len
    ret
