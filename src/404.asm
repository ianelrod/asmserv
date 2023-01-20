; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Send 404, then exit child
; -----------------------------------------

section .text
        global  _fof

_fof:   ; respond to socket with 404
; rdi: socket fd
        ; prologue
        xor     rax,rax
        push    rdx
        push    rdi
        push    rax

.clr:   mov     QWORD [rsp],0
        lea     rdx,[rsp]
        mov     rsi,0x541B
        mov     rax,16              ; operator ioctl
        syscall
        mov     rax,QWORD [rsp]
        cmp     rax,0
        jle     .done
        mov     rdx,8
        lea     rsi,[rsp]
        mov     rax,0               ; operator read
        syscall
        jmp     .clr                ; read from socket until error to clear buffer

.done:  pop     rax
        mov     rax,1               ; operator write
        pop     rdi                 ; connection fd
        lea     rsi,[fof_str]       ; send 404
        mov     rdx,24
        syscall

        mov     r12,0               ; normal exit
        pop     rdx
        ret

section .rodata
fof_str:db      "HTTP/1.1 404 Not Found",0xa,0