%include "syscall.inc"
%include "errno.inc"
%include "malloc.inc"

%define FUTEX_WAIT 0x0
%define FUTEX_WAKE 0x1
%define PROT_READ  0x1
%define PROT_WRITE 0x2
%define MAP_PRIVATE 0x02
%define MAP_ANONYMOUS 0x20
%define CLONE_VM 0x00000100
%define CLONE_FS 0x00000200
%define CLONE_FILES 0x00000400
%define CLONE_SIGHAND 0x00000800
%define CLONE_THREAD 0x00010000
%define CLONE_SYSVSEM 0x00040000
%define CLONE_SETTLS 0x00080000
%define CLONE_PARENT_SETTID 0x00100000
%define CLONE_CHILD_CLEARTID 0x00200000

global TLS_SIZE

struc tls
    .errno_offset: resq 1
    .this_thread_offset: resq 1
    .prog_ptr_offset: resq 1
endstruc
TLS_SIZE equ tls_size

struc thread
    .tid: resq 1
    .lock: resq 1
    .stack: resq 1
    .stack_size: resq 1
    .retval: resq 1
endstruc

global __errno_location
__errno_location:
    rdfsbase rax
    add rax, tls.errno_offset
    ret

global __tls_ptr_location
__tls_ptr_location:
    rdfsbase rax
    add rax, tls.prog_ptr_offset
    ret

global __this_thread_location
__this_thread_location:
    rdfsbase rax
    add rax, tls.this_thread_offset
    ret

%define stack_size_default 0x10000000
%define stack_size_min 0x10000
%define THREAD_JOIN_VALUE 42

global thread_exit
thread_exit:
    call __this_thread_location
    cmp QWORD [rax], 0
    je .main

    mov rax, rdi
    jmp thread_create.child_exit

.main:
    mov rax, SYS_exit_group
    syscall

global thread_join
thread_join:
    call __this_thread_location
    cmp QWORD [rax], rdi
    je .err

    push rdi
    add rdi, thread.lock
    mov rsi, FUTEX_WAIT
    mov rdx, THREAD_JOIN_VALUE
    mov r10, 0
    mov rax, SYS_futex
    syscall

    pop rdi
    push rdi
    add rdi, thread.lock
    mov rsi, FUTEX_WAKE
    mov rdx, 1
    mov r10, 0
    mov rax, SYS_futex
    syscall

    pop rax
    mov rax, QWORD [rax+thread.retval]
    ret

.err:
    call __errno_location
    mov QWORD [rax], EDEADLK
    mov rax, -1
    ret

global thread_join_multiple
thread_join_multiple:
    cmp rsi, 0
    je .end

    push rdi
    push rsi
    mov rdi, QWORD [rdi]
    call thread_join
    pop rsi
    sub rsi, 1
    pop rdi
    add rdi, 8
    jmp thread_join_multiple
.end:
    ret

global thread_create
thread_create:
    cmp rdi, 0
    jne .check_stack_size

    mov rdi, stack_size_default;
.check_stack_size:
    cmp rdi, stack_size_min;
    jae .got_stack_size

    call __errno_location
    mov QWORD [rax], EINVAL
    mov rax, 0
    ret
.got_stack_size:
    push rsi;
    push rdx;
    push rdi;

    mov rdi, thread_size
    call malloc

    pop rdi;
    mov QWORD [rax+thread.stack_size], rdi
    push rax;

    mov rsi, rdi
    mov rdi, 0
    mov rdx, (PROT_READ|PROT_WRITE)
    mov r10, (MAP_PRIVATE|MAP_ANONYMOUS)
    mov r8, -1
    mov r9, 0
    mov rax, SYS_mmap
    syscall

    mov rdi, rax;
    pop rax;
    mov QWORD [rax+thread.stack], rdi
    add rdi, QWORD [rax+thread.stack_size]
    sub rdi, 8
    pop rsi;
    mov QWORD [rdi], rsi
    pop rsi;
    sub rdi, 8
    mov QWORD [rdi], rsi
    sub rdi, 8
    mov QWORD [rdi], rax
    push rax;

    push rax;
    push rdi;

    mov rdi, TLS_SIZE
    call malloc

    mov r8, rax
    pop rsi
    pop rdx
    mov r10, rdx
    add rdx, thread.tid
    add r10, thread.lock
    mov QWORD [r10], THREAD_JOIN_VALUE
    mov rdi, (CLONE_VM|CLONE_FS|CLONE_FILES|CLONE_SIGHAND|CLONE_THREAD|CLONE_SYSVSEM|CLONE_SETTLS|CLONE_PARENT_SETTID|CLONE_CHILD_CLEARTID)
    mov rax, SYS_clone
    syscall

    cmp rax, 0
    jne .parent

    call __errno_location
    mov QWORD [rax], -1
    call __tls_ptr_location
    mov QWORD [rax], 0

    pop rdi;
    call __this_thread_location
    mov QWORD [rax], rdi
    pop rax;
    pop rdi;
    call rax
.child_exit:
    mov rdi, rax
    call __this_thread_location
    mov rax, QWORD [rax]
    mov QWORD [rax+thread.retval], rdi
    mov r12, rdi
    push rax

    call __tls_ptr_location
    cmp QWORD [rax], 0
    je .tls_free

    mov rdi, QWORD [rax]
    call free

.tls_free:
    rdfsbase rdi
    call free

    pop rax
    mov rdi, QWORD [rax+thread.stack]
    mov rsi, QWORD [rax+thread.stack_size]
    mov rax, SYS_munmap
    syscall

    mov rdi, r12
    mov rax, SYS_exit
    syscall
.parent:
    pop rax
    ret

global thread_destroy
thread_destroy:
    mov rax, QWORD [rdi+thread.lock]
    cmp rax, 0
    jne .not_finished

    call free
    mov rax, 0
    ret

.not_finished:
    call __errno_location
    mov QWORD [rax], EBUSY
    mov rax, -1
    ret