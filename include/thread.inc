%ifndef _THREAD_INC
%define _THREAD_INC

;QWORD long_pointer __errno_location()
extern __errno_location
;QWORD prog_ptr __tls_ptr_location()
extern __tls_ptr_location
;QWORD thread_pointer __this_thread_location()
extern __this_thread_location

;QWORD thread_pointer thread_create(QWORD stack_size, QWORD thread_func, QWORD thread_arg)
extern thread_create
;NORETURN thread_exit(QWORD exit_code)
extern thread_exit
;QWORD exit_result thread_join(QWORD thread_pointer)
extern thread_join
;VOID thread_join_multiple(QWORD thread_pointer_arr, QWORD thread_pointer_count)
extern thread_join_multiple
;QWORD result thread_destroy(QWORD thread_pointer)
extern thread_destroy

%endif