bits 64

%include "syscall.inc"

section .text

%define FUTEX_WAIT 0
%define FUTEX_WAKE 1
%define FUTEX_REQUEUE 3

%define FUTEX_PRIVATE_FLAG 128

%define FUTEX_WAIT_PRIVATE (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
%define FUTEX_WAKE_PRIVATE (FUTEX_WAKE | FUTEX_PRIVATE_FLAG)
%define FUTEX_REQUEUE_PRIVATE (FUTEX_REQUEUE | FUTEX_PRIVATE_FLAG)

global mutex_lock
mutex_lock:
    mov al, 0
    mov bl, 1
    lock cmpxchg [rdi], bl
    je .ret

    push rdi
    mov rax, SYS_futex
    mov rsi, FUTEX_WAIT_PRIVATE
    mov rdx, 1
    mov r10, 0
    syscall
    pop rdi
    jmp mutex_lock

.ret:
    ret

global mutex_trylock
mutex_trylock:
    mov al, 0
    mov bl, 1
    lock cmpxchg [rdi], bl
    mov rax, 0
    mov rbx, 1
    cmove rax, rbx
    ret

global mutex_unlock
mutex_unlock:
    mov DWORD [rdi], 0

    mov rax, SYS_futex
    mov rsi, FUTEX_WAKE_PRIVATE
    mov rdx, 1
    syscall
    ret

global cond_wait
cond_wait:
    mov eax, [rdi]
    push rsi
    push rax
    push rdi
    mov rdi, rsi
    call mutex_unlock
    mov rax, SYS_futex
    pop rdi
    mov rsi, FUTEX_WAIT_PRIVATE
    pop rdx
    mov r10, 0
    syscall
    pop rdi
    call mutex_lock
    ret

global cond_signal
cond_signal:
    lock add DWORD [rdi], 1
    mov rax, SYS_futex
    mov rsi, FUTEX_WAKE_PRIVATE
    mov rdx, 1
    mov r10, 0
    syscall
    ret

global cond_broadcast
cond_broadcast:
    lock add DWORD [rdi], 1
    mov r8, rsi
    mov rsi, FUTEX_REQUEUE_PRIVATE
    mov rdx, 1
    mov r10, 2147483647;INT_MAX
    syscall
    ret