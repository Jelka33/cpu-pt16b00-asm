#once

;; ============================================================== ;;
;; This is the architecture definition for the CPU PT16B00        ;;
;; Always use this file when assembling your programs for the CPU ;;
;; $ customasm ./path/to/pt16b00.asm <your files> -o <out file>   ;;
;; ============================================================== ;;

; Registers
#subruledef reg {
    %r{i : u3}  => i`3
    %rwh        => 4`3
    %rwl        => 5`3
    %spt        => 6`3
    %memh       => 7`3
}

; Immediate (-0x8000 to +0xffff)
#subruledef num {
    {imm : i16} => imm`16
}

; 32-bit memory address
#subruledef address {
    {addr : u32} => (addr[15:0] @ addr[31:16])`32
}

; Lower 16-bits of memory address
#subruledef low_addr {
    {addr : u16} => addr`16
}

; Relative address (10-bits)
#subruledef rel_addr {
    {addr : s10} => addr`10
}

; Instructions
#ruledef instructions {
    nop                                     => 0x0`16

    add {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x1`6
    add {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x2`6  @ imm
    adc {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x3`6
    adc {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x4`6  @ imm
    sub {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x5`6
    sub {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x6`6  @ imm
    sbc {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x7`6
    sbc {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x8`6  @ imm
    mul {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x9`6
    mul {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0xa`6  @ imm

    and {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0xb`6
    and {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0xc`6  @ imm
    or {reg_a : reg}, {reg_b : reg}         => 0`4  @ reg_b @ reg_a @ 0xd`6
    or {reg_a : reg}, {imm : num}           => 0`7          @ reg_a @ 0xe`6  @ imm
    xor {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0xf`6
    xor {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x10`6 @ imm
    SHR {reg_a : reg}                       => 0`7          @ reg_a @ 0x11`6
    SAR {reg_a : reg}                       => 0`7          @ reg_a @ 0x12`6

    cmp {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x13`6
    cmp {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x14`6 @ imm

    load {reg_a : reg}, {addr : low_addr}   => 0`7          @ reg_a @ 0x15`6 @ addr
    write1b {addr : low_addr}               => 0`10                 @ 0x16`6 @ addr
    write2b {addr : low_addr}               => 0`10                 @ 0x17`6 @ addr
    write3b {addr : low_addr}               => 0`10                 @ 0x18`6 @ addr
    write4b {addr : low_addr}               => 0`10                 @ 0x19`6 @ addr
    mov {reg_a : reg}, {reg_b : reg}        => 0`4  @ reg_b @ reg_a @ 0x1a`6
    mov {reg_a : reg}, {imm : num}          => 0`7          @ reg_a @ 0x1b`6 @ imm
    push {reg_a : reg}                      => 0`7          @ reg_a @ 0x1c`6
    push {imm : num}                        => 0`10                 @ 0x1d`6 @ imm
    pop {reg_a : reg}                       => 0`7          @ reg_a @ 0x1e`6
    pushf                                   => 0`10                 @ 0x1f`6
    popf                                    => 0`10                 @ 0x20`6

    jmp {addr : address}                    => 0`10                 @ 0x21`6 @ addr
    jz {addr : address}                     => 0`10                 @ 0x22`6 @ addr
    jnz {addr : address}                    => 0`10                 @ 0x23`6 @ addr
    jg {addr : address}                     => 0`10                 @ 0x24`6 @ addr
    jl {addr : address}                     => 0`10                 @ 0x25`6 @ addr
    ja {addr : address}                     => 0`10                 @ 0x26`6 @ addr
    jb {addr : address}                     => 0`10                 @ 0x27`6 @ addr
    sjmp {addr : rel_addr}                  => addr                 @ 0x28`6
    sjz {addr : rel_addr}                   => addr                 @ 0x29`6
    sjnz {addr : rel_addr}                  => addr                 @ 0x2a`6
    sjg {addr : rel_addr}                   => addr                 @ 0x2b`6
    sjl {addr : rel_addr}                   => addr                 @ 0x2c`6
    sja {addr : rel_addr}                   => addr                 @ 0x2d`6
    sjb {addr : rel_addr}                   => addr                 @ 0x2e`6

    call {addr : address}                   => 0`10                 @ 0x2f`6 @ addr
    ret                                     => 0`10                 @ 0x30`6
    int {iv : u8}                           => 0`2                  @ iv     @ 0x31`6
    iret                                    => 0`10                 @ 0x32`6

    hlt                                     => 0`10                 @ 0x33`6

    setspth {reg_a : reg}                   => 0`7          @ reg_a @ 0x34`6
    getspth {reg_a : reg}                   => 0`7          @ reg_a @ 0x35`6
    setivt {addr : address}                 => 0`10                 @ 0x36`6 @ addr
    load {reg_a : reg}, {reg_b : reg}       => 0`4  @ reg_b @ reg_a @ 0x37`6
    write1b {reg_a : reg}                   => 0`7          @ reg_a @ 0x38`6
    write2b {reg_a : reg}                   => 0`7          @ reg_a @ 0x39`6
    write3b {reg_a : reg}                   => 0`7          @ reg_a @ 0x3a`6
    write4b {reg_a : reg}                   => 0`7          @ reg_a @ 0x3b`6
}

#bankdef ram {
    #addr 0x0
    #addr_end 0x01ff_ffff
    #outp 0
    #bits 16
}

#bank ram
