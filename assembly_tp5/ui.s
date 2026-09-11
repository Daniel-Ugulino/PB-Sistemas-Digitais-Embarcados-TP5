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
pos_spi_rx:     .ascii "\x1b[8;2H\x1b[KRX: "
pos_spi_rx_len: .quad . - pos_spi_rx
pos_spi_rtt:    .ascii "\x1b[9;2H\x1b[KRTT: "
pos_spi_rtt_len: .quad . - pos_spi_rtt
suffix_rtt_ms:  .ascii " ms"
suffix_rtt_ms_len: .quad . - suffix_rtt_ms
rtt_buf:        .space 16
msg_spi_fail:   .ascii "SPI: /dev/spidev0.0 nao abriu (dtparam=spi=on, reboot, sudo)"
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
    stp     x29, x30, [sp, #-32]!

    write_str STDOUT, pos_spi_rx, pos_spi_rx_len

    ldr     x9, =tel_pkt
    mov     w11, #0
    sub     sp, sp, #16

ui_rx_loop:
    cmp     w11, #11
    b.ge    ui_rx_done

    ldrb    w0, [x9, x11]
    mov     x1, sp
    bl      format_byte_to_hex
    mov     w2, #' '
    strb    w2, [x1], #1

    mov     x1, sp
    mov     x2, #3
    write_out STDOUT

    add     w11, w11, #1
    b       ui_rx_loop

ui_rx_done:
    add     sp, sp, #16
    ldp     x29, x30, [sp], #32
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
