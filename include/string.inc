%ifndef _STRING_INC
%define _STRING_INC

;QWORD len strlen(QWORD string_pointer)
extern strlen
;QWORD diff strcmp(QWORD string_pointer_a, QWORD string_pointer_b)
extern strcmp
;QWORD token_pointer strtok(QWORD string_pointer, QWORD delimiters_pointer)
extern strtok
;QWORD char_pointer strchr(QWORD string_pointer, BYTE search_char)
extern strchr

%endif