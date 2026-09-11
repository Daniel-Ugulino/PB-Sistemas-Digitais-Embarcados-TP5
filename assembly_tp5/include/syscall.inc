// Numeros de syscall Linux AArch64 usados no projeto (stand-alone)

.equ SYS_IOCTL,     29
.equ SYS_READ,      63
.equ SYS_WRITE,     64
.equ SYS_CLOSE,     57
.equ SYS_OPENAT,    56
.equ SYS_EXIT,      93
.equ SYS_NANOSLEEP,     101
.equ SYS_CLOCK_GETTIME, 113

.equ CLOCK_MONOTONIC, 1

.equ AT_FDCWD,      -100
.equ STDIN,         0
.equ STDOUT,        1

.equ O_RDWR,        0x0002
.equ O_WRONLY,      0x0001
.equ O_CREAT,       0x0040
.equ O_APPEND,      0x0400
.equ MODE_0644,     0x1A4

.equ TCGETS,        0x5401
.equ TCSETS,        0x5402
.equ ICANON,        0x0002
.equ ECHO,          0x0008
