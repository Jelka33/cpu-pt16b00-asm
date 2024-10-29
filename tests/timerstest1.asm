; boot
sjmp boot - $

; data
timer_ptr: #d32 0
freq: #d32 0    ; in Hz
time: #d32 0    ; in us

; functions
timer1_isr: ; "stopwatch"
    push %r4
    push %r5
    push %memh

    xor %memh, %memh
    load %r5, time[15:0]
    load %r4, time[15:0]+1
    add %r5, 1
    adc %r4, 0
    write4b time[15:0]

    pop %memh
    pop %r5
    pop %r4

    iret

timer2_isr: ; exit wait
    mov %r3, 1
    iret

; ivt
ivt: #res 10    ; not full IVT!

; stack
#res 20
stack:

; code
boot:
; find the timer module
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
    sjmp -1

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

;hlt
; init the timer module
mov %memh, timer_ptr[31:16]
mov %r0, timer_ptr[15:0]
load %r1, %r0   ; low dev addr
add %r0, 1
load %memh, %r0 ; high dev addr
mov %r3, %memh  ; high dev addr COPY

; get timer freq
load %r5, %r1
add %r1, 1
load %r4, %r1
xor %memh, %memh
write4b freq[15:0]
mov %memh, %r3

; set the timer time
add %r1, 1

mov %r5, 1000
write2b %r1
add %r1, 1
xor %r5, %r5
write2b %r1

add %r1, 1

mov %r5, 1 << 6
write2b %r1

sub %r1, 1
mov %r5, 0x7735
write2b %r1
sub %r1, 1
mov %r5, 0x9400
write2b %r1

add %r1, 2

; define the IVT
setivt ivt

; add timer interrupts
mov %r5, timer1_isr[15:0]
mov %r4, timer1_isr[31:16]
xor %memh, %memh
write4b ivt

mov %r5, timer2_isr[15:0]
write4b ivt+2

mov %memh, %r3

; define the stack
mov %spt, stack
;hlt
; start the timers
mov %r5, 0b10
write2b %r1

xor %r3, %r3
wait:
    cmp %r3, 1
    sjnz wait - $

break:
hlt
sjmp -1