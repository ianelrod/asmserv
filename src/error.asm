; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; All error handlers
; -----------------------------------------

section .text
        global  _error
        extern  _end

exit:                               ; normal exit
        mov     rax,1               ; operator write
        mov     rdi,1
        lea     rsi,[exit]          ; error message
        mov     rdx,12
        syscall
        ret

args:                               ; invalid args handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error1]
        mov     rdx,30
        syscall
        ret

param:                              ; invalid param handler
        mov     rax,1
        mov     rdi,1
        mov     rsi,[error2]
        mov     rdx,27
        syscall
        ret

sock:                               ; socket error handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error3]
        mov     rdx,21
        syscall
        ret

bind:                               ; bind error handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error4]
        mov     rdx,19
        syscall
        ret

listen:                             ; listen error handler
        mov     rax,1
        mov     rdi,1
        lea     rsi,[error5]
        mov     rdx,21
        syscall
        ret

_error:
        push    rdi                 ; save exit code
        call    [dict+rdi*8]
        pop     rdi
        ret

section .rodata
dict:   dq      [exit],[args],[param],[sock],[bind],[listen]
exit:   db      "Exiting...",0xa,0
error1: db      "Syntax: ./server [ip] [port]",0xa,0
error2: db      "Error: Invalid IP or port",0xa,0
error3: db      "Error: Socket error",0xa,0
error4: db      "Error: Bind error",0xa,0
error5: db      "Error: Listen error",0xa,0