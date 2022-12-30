; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; GET Request Handler
; -----------------------------------------

section .text
        global  _get
        extern  _end

_get:
        push    rbp
        mov     rbp,rsp

        mov     rax,57              ; operator fork
        syscall
        cmp     rax,0               ; child process
        jne     .end

.end:   mov     rsp,rbp
        pop     rbp
        ret