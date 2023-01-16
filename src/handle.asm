; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Child Connection Handler
; -----------------------------------------

section .text
        global  _handle
        extern  _read
        extern  _error
        extern  _get
        extern  _post
        extern  _end

open:   ; this subroutine attempts to open a file fd
; r8:  path string pointer
; r9:  file fd
; r10: general register

_handle:; this function receives a child forked from main and performs all steps necessary to handle a connection
; It closely interoperates with read.asm to parse data
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
        push    rdi                 ; put connection fd
        xor     dx,dx               ; clear options for new child

        ; get HTTP request method
        xor     rax,rax
        mov     rsi," "             ; delimit strings by space
        btr     dx,0                ; no security
        call    _read
        push    rax                 ; put buffer pointer

        ; interpret HTTP request method
        ; 1. check read result
        xor     rdi,rdi
        inc     r12                 ; method error: 6
        cmp     dh,8                ; verify length
        jg      end
        push    dx                  ; next 5 lines devoted to coping with using dh
        xchg    dl,dh
        movzx   rdx,dl
        mov     dil,BYTE [rax+rdx]
        pop     dx
        cmp     dil," "             ; verify delimiter
        jne     end

        ; 2. store request method in local variable
        xor     rcx,rcx
        xor     rsi,rsi
        mov     cl,dh
.top:   mov     dil,BYTE [rax]      ; take byte
        mov     sil,dil             ; put byte
        shl     rsi,8
        inc     rax
        dec     cl
        jz      .done
        jmp     .top

        ; 3. compare request method to "GET" or "POST"
.done:  pop     rax                 ; get buffer pointer
        pop     rdi                 ; get connection fd
        cmp     rsi,"GET"
        jne     .i
        call    _get
        jmp     end
.i:     cmp     rsi,"POST"
        jne     end
        call    _post

        ; epilogue
end:    ret
