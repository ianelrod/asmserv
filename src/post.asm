; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; POST request related actions
; -----------------------------------------

section .text
        global  _post
        extern  _read

_post:  ; this function is called from handle.asm to perform actions related to POST requests
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; dh:  offset
; dl:  handle + read state
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 none          (8)
; rcx: counter
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x8

        ; local variables
        mov     WORD [rbp-0x2],di   ; connection fd

        ; get file path
        xor     rax,rax
        xor     rdi,rdi
        xor     rsi,rsi
        movzx   rdi,WORD [rbp-0x2]  ; connection fd
        mov     rsi," "             ; delimit strings by space
        bts     dx,0                ; security
        call    _read
        mov     [rbp-0xa],rax       ; store buffer pointer

        ; interpret file path

        ; epilogue
        mov     rsp,rbp
        pop     rbp
        ret