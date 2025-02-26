%ifndef _MUTEX_INC
%define _MUTEX_INC

%define MUTEX_INITIALIZER DWORD 0

;VOID mutex_lock(QWORD mutex_pointer)
extern mutex_lock
;BOOL success mutex_trylock(QWORD mutex_pointer)
extern mutex_trylock
;VOID mutex_unlock(QWORD mutex_pointer)
extern mutex_unlock

%define COND_INITIALIZER DWORD 0

;VOID cond_wait(QWORD cond_pointer, QWORD mutex_pointer)
extern cond_wait
;VOID cond_signal(QWORD cond_pointer)
extern cond_signal
;VOID cond_broadcast(QWORD cond_pointer, QWORD mutex_pointer)
extern cond_broadcast

%endif