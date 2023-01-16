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
        dec     rax
        lea     rdx,[ep1]
        mov     rsi,[rdx+rax*8]
        call    length
        mov     rdi,1
        mov     rax,1
        syscall                     ; print error msg

.end:   pop     rax

        mov     rsp,rbp
        pop     rbp
        ret

section .data align=8               ; store error pointers
ep1:    dq      es1
ep2:    dq      es2
ep3:    dq      es3
ep4:    dq      es4
ep5:    dq      es5
ep6:    dq      es6
ep7:    dq      es7
ep8:    dq      es8

section .rodata                     ; store error strings
es1:    db      "Syntax: ./server [ip] [port]",0xa,0
es2:    db      "Error: Invalid IP or port",0xa,0
es3:    db      "Error: Socket error",0xa,0
es4:    db      "Error: Bind error",0xa,0
es5:    db      "Error: Listen error",0xa,0
es6:    db      "Error: Invalid request method",0xa,0
es7:    db      "Error: Invalid path",0xa,0
es8:    db      "Error: File error",0xa,0