bits 64

struc va_list
    .index: resq 1
    .regs: resq 5
    .ptr: resq 1
    .reserved: resq 1
endstruc

%include "malloc.inc"

global va_next
va_next:
    mov rsi, [rdi+va_list.index]
    cmp rsi, 40
    jl .less
    sub rsi, 40
    mov rax, [rdi+va_list.ptr]
    mov rax, [rax+rsi]
    add rsi, 48
    mov [rdi+va_list.index], rsi
    ret
.less:
    mov rax, [rdi+va_list.regs+rsi]
    add rsi, 8
    mov [rdi+va_list.index], rsi
    ret

global va_copy
va_copy:
    mov rax, QWORD [rsi+va_list.index]
    mov QWORD [rdi+va_list.index], rax
    mov rax, QWORD [rsi+va_list.regs]
    mov QWORD [rdi+va_list.regs], rax
    mov rax, QWORD [rsi+va_list.regs+8]
    mov QWORD [rdi+va_list.regs+8], rax
    mov rax, QWORD [rsi+va_list.regs+16]
    mov QWORD [rdi+va_list.regs+16], rax
    mov rax, QWORD [rsi+va_list.regs+24]
    mov QWORD [rdi+va_list.regs+24], rax
    mov rax, QWORD [rsi+va_list.regs+32]
    mov QWORD [rdi+va_list.regs+32], rax
    mov rax, QWORD [rsi+va_list.ptr]
    mov QWORD [rdi+va_list.ptr], rax
    ret

global va_end
va_end:
    ret