; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; POST Request Handler
; -----------------------------------------

section .text
        global  _post
        extern  _end

_post:
        push    rbp
        mov     rbp,rsp

        mov     rax,57              ; operator fork
        syscall
        cmp     rax,0               ; child process
        jne     .end

.end:   mov     rsp,rbp
        pop     rbp
        ret