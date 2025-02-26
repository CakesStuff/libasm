%ifndef _MALLOC_INC
%define _MALLOC_INC

;QWORD pointer malloc(QWORD size)
extern malloc
;QWORD pointer realloc(QWORD pointer, QWORD size)
extern realloc
;VOID free(QWORD pointer)
extern free

%endif