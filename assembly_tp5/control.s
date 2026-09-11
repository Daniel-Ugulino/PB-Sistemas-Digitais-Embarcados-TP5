.include "macros.inc"

.equ STEP_DIST, 5
.equ STEP_VEL,  5

.extern cfg_dist_free
.extern cfg_dist_att
.extern cfg_vel_max

.section .rodata
.align 3
key_table:
    .quad increase_risk_zone
    .quad control_ignore
    .quad control_ignore
    .quad reduce_risk_zone
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad reduce_max_speed
    .quad control_ignore
    .quad control_ignore
    .quad control_ignore
    .quad increase_max_speed
.equ KEY_TABLE_MAX, 22

.section .text

.global control
control:
    stp     x29, x30, [sp, #-32]!
    mov     x29, sp
    str     x19, [sp, #16]

    orr     w0, w0, #0x20
    sub     w1, w0, #'a'
    cmp     w1, #KEY_TABLE_MAX
    b.hi    control_ignore

    ldr     x2, =key_table
    ldr     x3, [x2, w1, uxtw #3]
    br      x3

control_ignore:
    mov     w0, #0
    b       control_ret

increase_max_speed:
    mov     w1, #STEP_VEL
    mov     w19, #0x01
    b       apply_speed

reduce_max_speed:
    mov     w1, #-STEP_VEL
    mov     w19, #0x02

apply_speed:
    adr     x9, cfg_vel_max
    bl      add_to_byte_saturated
    b       control_log

increase_risk_zone:
    mov     w1, #STEP_DIST
    mov     w19, #0x03
    b       apply_risk_zone

reduce_risk_zone:
    mov     w1, #-STEP_DIST
    mov     w19, #0x04

apply_risk_zone:
    adr     x9, cfg_dist_free
    bl      add_to_byte_saturated
    adr     x9, cfg_dist_att
    bl      add_to_byte_saturated

control_log:
    mov     w0, w19
    bl      log_control_action
    bl      config_init
    mov     w0, w19

control_ret:
    ldr     x19, [sp, #16]
    ldp     x29, x30, [sp], #32
    ret
