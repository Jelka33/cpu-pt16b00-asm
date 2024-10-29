fb_ptr = 0xA000
fb_dev_ptr: #d32 0

; find the VGA module
mov %memh, 0x200
load %r0, 0 ; number of dev ROM entries
xor %r1, %r1
loop_discover:
    add %r1, 3

    ; if %r1 <= %r0
    cmp %r1, %r0
    jb .check_dev    ; continue
    jz .check_dev    ; |
    ; else -> halt
    hlt
    sjmp $-1

    .check_dev:
    load %r2, %r1
    ; %r2 >> 8
    shr %r2
    shr %r2
    shr %r2
    shr %r2
    shr %r2
    shr %r2
    shr %r2
    shr %r2

    ; if %r2 != 0xaf ; put the class of graphics devices
    cmp %r2, 0xaf
    jnz loop_discover
    ; else
    sub %r1, 1      ; load the dev address
    load %r4, %r1   ; |
    sub %r1, 1      ; |
    load %r5, %r1   ; |
    mov %memh, fb_dev_ptr[31:16]    ; store the dev address
    write4b fb_dev_ptr[15:0]        ; |

; init VGA module
mov %memh, fb_dev_ptr[31:16]
mov %r0, fb_dev_ptr[15:0]   ; %r0 = ptr address
load %r1, %r0       ; low dev addr
add %r0, 1
load %memh, %r0     ; high dev addr

load %r2, %r1       ; get the name length
; byte length to word length
; %r2 = %r2 / 2 + %r2 % 2
mov %r3, %r2
and %r3, 1
shr %r2
add %r2, %r3
add %r2, 2      ; +1 because of 'mode' field
; dev_ptr = dev_ptr + name_length
add %r1, %r2
; tell the dev the fb address
xor %r4, %r4
mov %r5, fb_ptr
write4b %r1


; draw something
mov %memh, 0
mov %r0, fb_ptr
mov %r5, 0b0000011111100000     ; green colour
; fill first 10 rows
loop_green:
    write2b %r0
    add %r0, 1
    cmp %r0, 0xB900
    sjb loop_green - $

mov %r5, 0b1111100000000000     ; red colour
; fill next 10 rows
loop_red:
    write2b %r0
    add %r0, 1
    cmp %r0, 0xD200
    sjb loop_red - $

mov %r5, 0     ; black colour
; fill until end
loop_black:
    write2b %r0
    add %r0, 1
    cmp %r0, 0xFFFF
    sjnz skip_inc - $
    add %memh, 1
    sjmp loop_black - $

    skip_inc:
    cmp %r0, 0x5000
    sjz check_memh - $
    sjb loop_black - $
    check_memh:
    cmp %memh, 0x0005
    sjb loop_black - $

hlt
sjmp -1
