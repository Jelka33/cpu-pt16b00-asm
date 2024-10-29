; boot
sjmp boot - $

; data
fb_ptr_front: #d16 0xA000, 0
fb_ptr_back: #d16 0x5000, 0x5

fb_dev_ptr: #d32 0
fb_dev_fbreg: #d16 0

sysuart_dev_ptr: #d32 0
sysuart_offset: #d16 0

kb_keypress: #d16 0

timer_ptr: #d32 0

; functions
sysuart_isr:
    push %r0
    push %r1
    push %r5
    push %memh

    mov %memh, sysuart_dev_ptr[31:16]
    mov %r0, sysuart_dev_ptr[15:0]
    load %r1, %r0       ; low dev address
    add %r0, 1
    load %r5, %r0       ; high dev address
    mov %memh, sysuart_offset[31:16]
    mov %r0, sysuart_offset[15:0]
    load %r0, %r0

    mov %memh, %r5
    add %r1, %r0

    load %r5, %r1   ; skip command byte (assume it's keyboard)
    load %r5, %r1   ; skip modifiers
    load %r5, %r1   ; keypress!
    load %r0, %r1   ; skip the rest
    load %r0, %r1   ; |
    load %r0, %r1   ; |
    load %r0, %r1   ; |
    load %r0, %r1   ; |

    mov %memh, kb_keypress[31:16]
    mov %r0, kb_keypress[15:0]
    write2b %r0

    pop %memh
    pop %r5
    pop %r1
    pop %r0

    iret

fps_timer_isr:  ; switch front and back fb
    push %r0
    push %r1
    push %r4
    push %r5
    push %memh

    xor %memh, %memh
    load %r5, fb_ptr_front[15:0]
    load %r4, fb_ptr_front[15:0]+1
    load %r1, fb_ptr_back[15:0]
    load %r0, fb_ptr_back[15:0]+1

    write4b fb_ptr_back[15:0]

    mov %r5, %r1
    mov %r4, %r0
    write4b fb_ptr_front[15:0]

    load %r0, fb_dev_fbreg[15:0]
    load %memh, fb_dev_ptr[15:0]+1
    write4b %r0

    pop %memh
    pop %r5
    pop %r4
    pop %r1
    pop %r0

    iret

; ivt
ivt: #res 10    ; not full IVT!

; stack
#res 20
stack:

; code
boot:
; find the VGA and SYSUART module
mov %memh, 0x200
load %r0, 0 ; number of dev ROM entries
xor %r1, %r1
loop_discover:
    mov %memh, 0x200
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
    jnz .check_sysuart
    ; else
    mov %r3, %r1
    sub %r3, 1      ; load the dev address
    load %r4, %r3   ; |
    sub %r3, 1      ; |
    load %r5, %r3   ; |
    mov %memh, fb_dev_ptr[31:16]    ; store the dev address
    write4b fb_dev_ptr[15:0]        ; |
    sjmp loop_discover - $

    .check_sysuart:
    ; if %r2 != 0xfa ; put the calss of sysuart device
    cmp %r2, 0xfa
    jnz .check_timer
    ; else
    mov %r3, %r1
    sub %r3, 1      ; load the dev address
    load %r4, %r3   ; |
    sub %r3, 1      ; |
    load %r5, %r3   ; |
    mov %memh, sysuart_dev_ptr[31:16]    ; store the dev address
    write4b sysuart_dev_ptr[15:0]        ; |
    sjmp loop_discover - $

    .check_timer:
    ; if %r2 != 0xde ; put the class of timer devices
    cmp %r2, 0xde
    jnz loop_discover
    ; else
    mov %r3, %r1
    sub %r3, 1      ; load the dev address
    load %r4, %r3   ; |
    sub %r3, 1      ; |
    load %r5, %r3   ; |

    mov %memh, %r4

    load %r2, %r5       ; get the name length
    ; byte length to word length
    ; %r2 = %r2 / 2 + %r2 % 2
    mov %r3, %r2
    and %r3, 1
    shr %r2
    add %r2, %r3
    add %r2, 1      ; +1 because of 'mode' field
    ; dev_ptr = dev_ptr + name_length
    add %r5, %r2

    mov %memh, timer_ptr[31:16]    ; store the dev address
    write4b timer_ptr[15:0]        ; |

; define the IVT
setivt ivt

; add sysuart interrupt
xor %memh, %memh
mov %r5, fps_timer_isr[15:0]
mov %r4, fps_timer_isr[31:16]
write4b ivt
mov %r5, sysuart_isr[15:0]
mov %r4, sysuart_isr[31:16]
write4b ivt+4

; define the stack
mov %spt, stack

; init VGA module
mov %memh, fb_dev_ptr[31:16]
mov %r0, fb_dev_ptr[15:0]   ; %r0 = ptr address
load %r1, %r0       ; low dev addr
add %r0, 1
load %memh, %r0     ; high dev addr
mov %r0, %memh

load %r2, %r1       ; get the name length
; byte length to word length
; %r2 = %r2 / 2 + %r2 % 2
mov %r3, %r2
and %r3, 1
shr %r2
add %r2, %r3
add %r2, 2      ; +1 because of 'mode' field
; dev_ptr = dev_ptr + name_length + 1
add %r1, %r2

xor %memh, %memh
; save the fb reg address
mov %r5, %r1
write2b fb_dev_fbreg[15:0]
; tell the dev the fb address
load %r4, fb_ptr_front[15:0]+1
load %r5, fb_ptr_front[15:0]
mov %memh, %r0
write4b %r1

; store the SYSUART device data offset
mov %memh, sysuart_dev_ptr[31:16]
mov %r0, sysuart_dev_ptr[15:0]
load %r1, %r0       ; low dev address
add %r0, 1
load %memh, %r0     ; high dev address

load %r5, %r1       ; get the name length
; byte length to word length
; %r5 = %r5 / 2 + %r5 % 2
mov %r3, %r5
and %r3, 1
shr %r5
add %r5, %r3
add %r5, 1

mov %memh, sysuart_offset[31:16]
mov %r0, sysuart_offset[15:0]
write2b %r0

; init the timer module
mov %memh, timer_ptr[31:16]
mov %r0, timer_ptr[15:0]
load %r1, %r0   ; low dev addr
add %r0, 1
load %memh, %r0 ; high dev addr
mov %r3, %memh  ; high dev addr COPY

add %r1, 2

mov %r5, 0x2400
write2b %r1
add %r1, 1
mov %r5, 0xf4
write2b %r1

add %r1, 1
mov %r5, 1 + (1 << 10)
write2b %r1     ; start the timer

hlt
square_size = 10
main_loop:
    ; fill screen black
    xor %memh, %memh
    load %r0, fb_ptr_back[15:0]
    load %memh, fb_ptr_back[15:0]+1
    xor %r4, %r4
    xor %r5, %r5

    load %r1, fb_ptr_back[15:0]
    load %r2, fb_ptr_back[15:0]+1
    add %r1, (640*480)[15:0]
    adc %r2, (640*480)[31:16]

    .fill_loop:
        write4b %r0
        add %r0, 2
        adc %memh, 0

        cmp %memh, %r2
        jnz .fill_loop
        cmp %r0, %r1
        jb .fill_loop

    ; check input
    .check_input:
    mov %memh, kb_keypress[31:16]
    mov %r0, kb_keypress[15:0]
    load %r0, %r0
    ; if 'w'
    cmp %r0, 0x1a
    sjz .input_w - $
    ; if 'a'
    cmp %r0, 0x04
    sjz .input_a - $
    ; if 's'
    cmp %r0, 0x16
    sjz .input_s - $
    ; if 'd'
    cmp %r0, 0x07
    sjz .input_d - $
    ; if 'h'
    cmp %r0, 0x0b
    sjz .input_h - $

    mov %r0, (640-square_size)/2    ; x coord
    mov %r1, (480-square_size)/2    ; y coord
    sjmp .draw_square - $

    .input_w:
        mov %r0, (640-square_size)/2    ; x coord
        xor %r1, %r1
        sjmp .draw_square - $
    .input_a:
        xor %r0, %r0
        mov %r1, (480-square_size)/2    ; y coord
        sjmp .draw_square - $
    .input_s:
        mov %r0, (640-square_size)/2    ; x coord
        mov %r1, 480-square_size
        sjmp .draw_square - $
    .input_d:
        mov %r0, 640-square_size
        mov %r1, (480-square_size)/2    ; y coord
        sjmp .draw_square - $
    .input_h:
        hlt

    .draw_square:
        mov %r4, 0xFFFF
        mov %r5, 0xFFFF
        xor %memh, %memh
        load %r2, fb_ptr_back[15:0]
        load %memh, fb_ptr_back[15:0]+1

        ; + (y * 640)
        ; <=> + (y*136 + y*136 + y*136 + y*136 + y*96)
        ; because there is no 16*16->32bit instruction
        mov %r3, %r1
        mul %r3, 136
        add %r2, %r3
        adc %memh, 0

        mov %r3, %r1
        mul %r3, 136
        add %r2, %r3
        adc %memh, 0

        mov %r3, %r1
        mul %r3, 136
        add %r2, %r3
        adc %memh, 0

        mov %r3, %r1
        mul %r3, 136
        add %r2, %r3
        adc %memh, 0

        mov %r3, %r1
        mul %r3, 96
        add %r2, %r3
        adc %memh, 0

        add %r2, %r0        ; + x
        adc %memh, 0

        xor %r1, %r1        ; loop's y
        .loopy:
            xor %r0, %r0    ; loop's x
            .loopx:
                write4b %r2
                add %r2, 1
                adc %memh, 0
                add %r0, 1
                cmp %r0, square_size
                sjb .loopx - $

            add %r2, 640-square_size
            adc %memh, 0
            add %r1, 1
            cmp %r1, square_size
            sjb .loopy - $

    hlt
    sjmp main_loop - $

hlt
sjmp -1