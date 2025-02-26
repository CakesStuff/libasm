%ifndef _SYSCALLS_INC
%define _SYSCALLS_INC

;NORETURN exit(DWORD exit_code)
extern exit
;NORETURN _exit(QWORD exit_code)
extern _exit
;QWORD result syscall(QWORD syscall_nr, QWORD args...)
extern syscall
;QWORD read_result read(QWORD fd, QWORD buffer_pointer, QWORD read_amount)
extern read
;QWORD write_result write(QWORD fd, QWORD buffer_pointer, QWORD write_amount)
extern write

%endif