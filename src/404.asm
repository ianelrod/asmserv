; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Send 404, then exit child
; -----------------------------------------

section .text
        global  _fof
        extern  _end

_fof:
        ; rdi: socket
        push    rdi
        mov     rax,0
        mov     rsi,0               ; dump socket
        mov     rdx,8
        syscall
        pop     rdi
        cmp     rax,0
        jge     _fof
        push    rdi
        mov     rax,1
        mov     rsi,[fof_str]       ; send 404
        mov     rdx,24
        syscall
        pop     rdi
        mov     rax,3
        syscall
        mov     rax,0
        jmp     _end

section .rodata
fof_str:db      "HTTP/1.1 404 Not Found",0xa,0