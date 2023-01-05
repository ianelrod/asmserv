; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; All error handlers
; -----------------------------------------

section .text
        global  _error

length:                             ; calculate length of error string
; rsi: string pointer
; rdi: general purpose
; rdx: length result
        xor     rdx,rdx
.top:   mov     dil,[rsi]
        cmp     dil,0
        je      .done
        inc     rdx
        inc     rsi
        jmp     .top
.done:  sub     rsi,rdx             ; return rsi to beginning
        inc     rdx                 ; include one null byte at end
        ret

_error:
        push    rbp
        mov     rbp,rsp

        push    rax

        cmp     rax,0               ; if normal exit, skip message
        je      .end
        lea     rsi,[section.rodata.start+(rax-1)*32]
        call    length
        mov     rdi,1
        mov     rax,1
        syscall                     ; print error msg

.end:   pop     rax

        mov     rsp,rbp
        pop     rbp
        ret

section .rodata align=16
error1: db      "Syntax: ./server [ip] [port]",0xa,0
        times 32-$+error1 db 0
error2: db      "Error: Invalid IP or port",0xa,0
        times 32-$+error2 db 0
error3: db      "Error: Socket error",0xa,0
        times 32-$+error3 db 0
error4: db      "Error: Bind error",0xa,0
        times 32-$+error4 db 0
error5: db      "Error: Listen error",0xa,0
        times 32-$+error5 db 0