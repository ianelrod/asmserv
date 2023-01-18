; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Send 404, then exit child
; -----------------------------------------

section .text
        global  _fof
        extern  _end

_fof:   ; respond to socket with 404
; rdi: socket fd
        push    rdi
        mov     rsi,0               ; dump socket
        mov     rdx,8
.sys:   mov     rax,0               ; operator read
        syscall
        cmp     rax,0
        jge     .sys                ; read from socket until error to clear buffer
        mov     rax,1
        pop     rdi
        mov     rsi,[fof_str]       ; send 404
        mov     rdx,24
        syscall
        mov     rax,3
        syscall
        mov     rax,0
        jmp     _end

section .rodata
fof_str:db      "HTTP/1.1 404 Not Found",0xa,0