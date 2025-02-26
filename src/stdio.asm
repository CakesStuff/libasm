bits 64
%include "syscall.inc"

global stdin
stdin equ 0
global stdout
stdout equ 1
global stderr
stderr equ 2

%include "string.inc"
%include "stdarg.inc"

section .data
newline: db 0x0A

section .text
global puts
puts:
    enter $8, $0
    %define str QWORD [rbp - 8]

    mov str, rdi
    call strlen

    mov rsi, str
    mov edx, eax
    mov rax, SYS_write
    mov rdi, stdout
    syscall

    mov rax, SYS_write
    mov rdi, stdout
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 0
    %undef str
    leave
    ret

global putchar
putchar:
    enter $1, $0
    %define c BYTE [rbp - 1]

    mov c, dil
    mov rax, SYS_write
    mov rdi, stdout
    mov rsi, rbp
    add rsi, -1
    mov rdx, 1
    syscall

    mov rax, 0
    %undef c
    leave
    ret

%define PRINTF_LENGTH_DEFAULT 0
%define PRINTF_LENGTH_SHORT 1
%define PRINTF_LENGTH_SHORT_SHORT 2
%define PRINTF_LENGTH_LONG 3

printf_length:
    enter $32, $0
    %define format QWORD [rbp - 8]
    %define va_list QWORD [rbp - 16]
    %define count QWORD [rbp - 24]
    %define len QWORD [rbp - 32]

    mov format, rdi
    mov va_list, rsi
    mov count, 0

.while:
    mov rdi, format
    cmp BYTE [rdi], 0
    je .end

    cmp BYTE [rdi], '%'
    jne .nothing

    add rdi, 1

    mov len, PRINTF_LENGTH_DEFAULT

    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi

    cmp al, 'h'
    jne .check_l
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi
    mov len, PRINTF_LENGTH_SHORT

    cmp al, 'h'
    jne .switch_start
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi
    mov len, PRINTF_LENGTH_SHORT_SHORT
    jmp .switch_start

.check_l:
    cmp al, 'l'
    jne .switch_start
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi
    mov len, PRINTF_LENGTH_LONG
    
.switch_start:
    cmp al, '%'
    jne .next1
    cmp len, PRINTF_LENGTH_DEFAULT
    mov rax, 0
    jne .ret
    mov rax, count
    add rax, 1
    mov count, rax
    jmp .while

.next1:
    cmp al, 'x'
    je .hex
    cmp al, 'X'
    jne .next2
.hex:
    mov rdi, va_list
    call va_next
    mov rcx, 1
    cmp len, PRINTF_LENGTH_LONG
    je .hex_next
    mov eax, eax
.hex_next:
    mov rdx, 0
    mov rsi, 16
    div rsi
    cmp rax, 0
    je .hex_end
    add rcx, 1
    jmp .hex_next
.hex_end:
    add rcx, count
    mov count, rcx
    jmp .while

.next2:
    cmp al, 'o'
    jne .next3
    mov rdi, va_list
    call va_next
    mov rcx, 1
    cmp len, PRINTF_LENGTH_LONG
    je .oct_next
    mov eax, eax
.oct_next:
    mov rdx, 0
    mov rsi, 8
    div rsi
    cmp rax, 0
    je .oct_end
    add rcx, 1
    jmp .oct_next
.oct_end:
    add rcx, count
    mov count, rcx
    jmp .while

.next3:
    cmp al, 'd'
    jne .next4
    mov rdi, va_list
    call va_next
    mov rcx, 1
    cmp len, PRINTF_LENGTH_LONG
    je .sign_next
    movsx rax, eax
.sign_next:
    cmp rax, 0
    jge .dec_next
    add rcx, 1
    neg rax
    jmp .dec_next

.next4:
    cmp al, 'u'
    jne .next5
    mov rdi, va_list
    call va_next
    mov rcx, 1
    cmp len, PRINTF_LENGTH_LONG
    je .dec_next
    mov eax, eax
.dec_next:
    mov rdx, 0
    mov rsi, 10
    div rsi
    cmp rax, 0
    je .dec_end
    add rcx, 1
    jmp .dec_next
.dec_end:
    add rcx, count
    mov count, rcx
    jmp .while

.next5:
    cmp al, 'c'
    jne .next6
    cmp len, PRINTF_LENGTH_DEFAULT
    mov rax, 0
    jne .ret
    mov rdi, va_list
    call va_next
    mov rcx, count
    add rcx, 1
    mov count, rcx
    jmp .while

.next6:
    cmp al, 'p'
    jne .next7
    cmp len, PRINTF_LENGTH_DEFAULT
    mov rax, 0
    jne .ret
    mov rdi, va_list
    call va_next
    mov rcx, count
    add rcx, 16
    mov count, rcx
    jmp .while

.next7:
    cmp al, 's'
    mov rax, 0
    jne .ret
    mov rdi, va_list
    call va_next
    mov rdi, rax
    call strlen
    add rax, count
    mov count, rax
    jmp .while

.nothing:
    add rdi, 1
    mov format, rdi
    mov rdi, count
    add rdi, 1
    mov count, rdi
    jmp .while

.end:
    mov rax, count
.ret:
    %undef len
    %undef count
    %undef va_list
    %undef format
    leave
    ret

section .data
hexNumsL: db "0123456789abcdef"
hexNumsU: db "0123456789ABCDEF"

section .text
sprintf_pointer:
    mov rax, 0

.loop:
    rol rsi, 4
    mov rcx, rsi
    and rcx, 0xf
    mov al, [hexNumsL + rcx]
    mov [rdi], al
    add rdi, 1
    add rax, 1
    cmp rax, 16
    jne .loop

    ret

sprintf_unsigned:
    enter $32, $0
    %define buffer QWORD [rbp - 32]
    %define number QWORD [rbp - 24]
    %define radix QWORD [rbp - 16]
    %define nums QWORD [rbp - 8]

    mov buffer, rdi
    mov number, rsi
    mov radix, rdx
    cmp cl, 0
    je .lower
    mov nums, hexNumsU
    jmp .start
.lower:
    mov nums, hexNumsL
.start:

    mov rcx, 1
    mov rdi, 1
    mov rax, number
.while:
    mov rdx, 0
    div radix
    cmp rax, 0
    je .next

    add rcx, 1
    mov rsi, rax
    mov rdx, 0
    mov rax, rdi
    mul radix
    mov rdi, rax
    mov rax, rsi
    jmp .while
.next:
    push rcx
.for:
    sub rcx, 1
    cmp rcx, 0
    jl .end

    mov rax, number
    mov rdx, 0
    div rdi
    mov rsi, rax
    mov rdx, 0
    mul rdi
    sub number, rax
    mov rax, nums
    mov al, [rax + rsi]
    mov rsi, buffer
    mov [rsi], al
    add rsi, 1
    mov buffer, rsi
    mov rax, rdi
    mov rdx, 0
    div radix
    mov rdi, rax
    jmp .for
.end:
    pop rax

    %undef upper
    %undef radix
    %undef number
    %undef buffer
    leave
    ret

sprintf_signed:
    cmp rsi, 0
    jge sprintf_unsigned
    mov BYTE [rdi], '-'
    add rdi, 1
    neg rsi
    call sprintf_unsigned
    add rax, 1
    ret

global printf
printf:
    enter (va_list_size + 16), $0
    %define va_list_ptr QWORD [rbp - va_list_size - 8]
    %define format QWORD [rbp - va_list_size - 16]

    mov format, rdi
    mov rax, rbp
    sub rax, va_list_size
    mov va_list_ptr, rax

    va_start_rdi rax
    mov rsi, va_list_ptr
    mov rdi, format
    call vprintf
    push rax
    mov rdi, va_list_ptr
    call va_end
    pop rax

    %undef format
    %undef va_list_ptr
    leave
    ret

global vprintf
vprintf:
    enter (va_list_size + 40), $0
    %define va_list_src QWORD [rbp - va_list_size - 8]
    %define va_list_copy QWORD [rbp - va_list_size - 16]
    %define format QWORD [rbp - va_list_size - 24]
    %define plen QWORD [rbp - va_list_size - 32]
    %define strbuf QWORD [rbp - va_list_size - 40]
    mov format, rdi
    mov va_list_src, rsi
    mov va_list_copy, rbp
    sub va_list_copy, va_list_size

    mov rdi, va_list_copy
    mov rsi, va_list_src
    call va_copy

    mov rdi, format
    mov rsi, va_list_copy
    call printf_length
    mov plen, rax

    mov rdi, va_list_copy
    call va_end

    cmp plen, 0
    jne .valid
    mov rax, 0
    leave
    ret

.valid:
    sub rsp, plen
    sub rsp, 1
    mov strbuf, rsp

    mov rdi, strbuf
    mov rsi, format
    mov rdx, va_list_src
    call vsprintf
    push rax

    mov rdi, strlen
    mov rdx, rax
    mov rdi, stdout
    mov rsi, strbuf
    mov rax, SYS_write
    syscall

    pop rax
    leave
    ret

global sprintf
sprintf:
    enter (va_list_size + 24), $0
    %define va_list_ptr QWORD [rbp - va_list_size - 8]
    %define format QWORD [rbp - va_list_size - 16]
    %define buffer QWORD [rbp - va_list_size - 24]

    mov buffer, rdi
    mov format, rsi
    mov rax, rbp
    sub rax, va_list_size
    mov va_list_ptr, rax

    va_start_rsi rax
    mov rdx, va_list_ptr
    mov rsi, format
    mov rdi, buffer
    call vsprintf
    push rax
    mov rdi, va_list_ptr
    call va_end
    pop rax

    %undef buffer
    %undef format
    %undef va_list_ptr
    leave
    ret

global vsprintf
vsprintf:
    enter $40, $0
    %define buffer QWORD [rbp - 8]
    %define format QWORD [rbp - 16]
    %define va_list_ptr QWORD [rbp - 24]
    %define count QWORD [rbp - 32]
    %define len QWORD [rbp - 40]

    mov buffer, rdi
    mov format, rsi
    mov va_list_ptr, rdx
    mov count, 0

.while:
    mov rdi, format
    cmp BYTE [rdi], 0
    je .finish

    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi

    cmp al, '%'
    jne .normal

    mov len, PRINTF_LENGTH_DEFAULT
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi

    cmp al, 'h'
    jne .check_l

    mov len, PRINTF_LENGTH_SHORT
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi

    cmp al, 'h'
    jne .switch

    mov len, PRINTF_LENGTH_SHORT_SHORT
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi
    jmp .switch

.check_l:
    cmp al, 'l'
    jne .switch

    mov len, PRINTF_LENGTH_LONG
    mov al, BYTE [rdi]
    add rdi, 1
    mov format, rdi

.switch:
    cmp al, '%'
    jne .next1

    cmp len, PRINTF_LENGTH_DEFAULT
    jne .abort

    mov rdi, buffer
    mov rsi, count
    mov BYTE [rdi + rsi], '%'
    add rsi, 1
    mov count, rsi
    jmp .while

.next1:
    cmp al, 'x'
    je .hex
    cmp al, 'X'
    jne .next2
.hex:
    mov rdi, va_list_ptr
    call va_next
    cmp len, PRINTF_LENGTH_LONG
    je .hex_next
    mov eax, eax
.hex_next:
    mov rsi, rax
    mov rdi, buffer
    add rdi, count
    mov rdx, 16
    mov rcx, 0
    mov rbx, format
    cmp BYTE [rbx], 'X'
    mov rbx, 1
    cmove rcx, rbx
    call sprintf_unsigned
    add rax, count
    mov count, rax
    jmp .while

.next2:
    cmp al, 'o'
    jne .next3

    mov rdi, va_list_ptr
    call va_next
    cmp len, PRINTF_LENGTH_LONG
    cmovne eax, eax
    mov rsi, rax
    mov rdi, buffer
    add rdi, count
    mov rdx, 8
    mov rcx, 0
    call sprintf_unsigned
    add rax, count
    mov count, rax
    jmp .while

.next3:
    cmp al, 'u'
    jne .next4

    mov rdi, va_list_ptr
    call va_next
    cmp len, PRINTF_LENGTH_LONG
    cmovne eax, eax
    mov rsi, rax
    mov rdi, buffer
    add rdi, count
    mov rdx, 10
    mov rsi, 0
    call sprintf_unsigned
    add rax, count
    mov count, rax
    jmp .while

.next4:
    cmp al, 'd'
    jne .next5

    mov rdi, va_list_ptr
    call va_next
    cmp len, PRINTF_LENGTH_LONG
    je .sign_next
    movsx rax, eax
.sign_next:
    mov rsi, rax
    mov rdi, buffer
    add rdi, count
    mov rdx, 10
    mov rcx, 0
    call sprintf_signed
    add rax, count
    mov count, rax
    jmp .while

.next5:
    cmp al, 'c'
    jne .next6
    mov rdi, va_list_ptr
    call va_next
    mov rdi, buffer
    mov rsi, count
    mov BYTE [rdi + rsi], al
    add rsi, 1
    mov count, rsi
    jmp .while

.next6:
    cmp al, 'p'
    jne .next7
    cmp len, PRINTF_LENGTH_DEFAULT
    jne .abort
    mov rdi, va_list_ptr
    call va_next
    mov rsi, rax
    mov rdi, buffer
    call sprintf_pointer
    add rax, count
    mov count, rax
    jmp .while

.next7:
    cmp al, 's'
    jne .abort
    cmp len, PRINTF_LENGTH_DEFAULT
    jne .abort
    mov rdi, va_list_ptr
    call va_next
    mov rdi, buffer
    mov rsi, rax
    mov rcx, count
    mov rdx, 0
.string_while:
    cmp BYTE [rsi + rdx], 0
    je .while

    mov al, [rsi + rdx]
    mov [rdi + rcx], al
    add rcx, 1
    add rdx, 1
    mov count, rcx
    jmp .string_while

.normal:
    mov rdi, buffer
    mov rsi, count
    mov BYTE [rdi + rsi], al
    add rsi, 1
    mov count, rsi
    jmp .while

.finish:
    mov rdi, buffer
    mov rsi, count
    mov BYTE [rdi + rsi], 0
    jmp .ret

.abort:
    mov rdi, buffer
    mov BYTE [rdi], 0
    mov count, 0

.ret:
    mov rax, count
    %undef len
    %undef count
    %undef va_list_ptr
    %undef format
    %undef buffer
    leave
    ret
