struc va_list
    .index: resq 1
    .regs: resq 5
    .ptr: resq 1
    .reserved: resq 1
endstruc

%macro va_start_rdi 1
    mov QWORD [%1+va_list.index], 0
    mov QWORD [%1+va_list.regs], rsi
    mov QWORD [%1+va_list.regs+8], rdx
    mov QWORD [%1+va_list.regs+16], rcx
    mov QWORD [%1+va_list.regs+24], r8
    mov QWORD [%1+va_list.regs+32], r9
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

%macro va_start_rsi 1
    mov QWORD [%1+va_list.index], 8
    mov QWORD [%1+va_list.regs+8], rdx
    mov QWORD [%1+va_list.regs+16], rcx
    mov QWORD [%1+va_list.regs+24], r8
    mov QWORD [%1+va_list.regs+32], r9
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

%macro va_start_rdx 1
    mov QWORD [%1+va_list.index], 16
    mov QWORD [%1+va_list.regs+16], rcx
    mov QWORD [%1+va_list.regs+24], r8
    mov QWORD [%1+va_list.regs+32], r9
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

%macro va_start_rcx 1
    mov QWORD [%1+va_list.index], 24
    mov QWORD [%1+va_list.regs+24], r8
    mov QWORD [%1+va_list.regs+32], r9
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

%macro va_start_r8 1
    mov QWORD [%1+va_list.index], 32
    mov QWORD [%1+va_list.regs+32], r9
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

%macro va_start_r9 1
    mov QWORD [%1+va_list.index], 5
    mov QWORD [%1+va_list.ptr], rbp
    add QWORD [%1+va_list.ptr], 8
%endmacro

;QWORD value va_next(QWORD va_list)
extern va_next
;VOID va_copy(QWORD va_list_dst, QWORD va_list_src)
extern va_copy
;VOID va_end(QWORD va_list)
extern va_end
