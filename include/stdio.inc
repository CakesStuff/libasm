%ifndef _STDIO_INC
%define _STDIO_INC

;DWORD result puts(QWORD string_pointer)
extern puts
;DWORD result putchar(BYTE char)
extern putchar
;DWORD out_len printf(QWORD format_pointer, QWORD ...)
extern printf
;DWORD out_len sprintf(QWORD buffer, QWORD format_pointer, QWORD ...)

extern stdin
extern stdout
extern stderr

%endif