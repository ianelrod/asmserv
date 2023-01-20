; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Byte validity checker
; -----------------------------------------

section .text
        global  _verify
        extern  _fof

flush:  ; verify is acting on a new string, so we must reset r1
; r8:  byte pointer
; r9:  zero
; r10: general register
        ; prologue
        xor     r8,r8
        xor     r9,r9
        xor     r10,r10

        ; body
        lea     r8,[r1]
.top:   mov     r10b,BYTE [r8]
        cmp     r10b,r9b
        je      .done
        mov     BYTE [r8+1],r9b
        add     r8,2
        jmp     .top

        ; epilogue
.done:  ret

checkr1:; check byte against rule 1
; r8:  byte
; r9:  byte pointer
; r10: general register
        ; prologue
        xor     r9,r9
        xor     r10,r10

        ; body
        lea     r9,[r1]
.top:   mov     r10b,BYTE [r9]
        cmp     r10b,0
        je      .done
        cmp     r8b,r10b
        je      .fail
.next:  add     r9,2
        jmp     .top

.fail:  mov     r10b,BYTE [r9+1]
        test    r10b,r10b
        jnz     .fof
        inc     r10b
        mov     BYTE [r9+1],r10b
        jmp     .next

.fof:   call    _fof
        bts     dx,3

        ; epilogue
.done:  ret

checkr2:; check byte against rule 2
; r8:  byte
; r9:  byte pointer
; r10: general register
        ; prologue
        xor     r9,r9
        xor     r10,r10

        ; body
        lea     r9,[r2]
.top:   mov     r10b,BYTE [r9]
        cmp     r10b,0
        je      .done
        cmp     r8b,r10b
        je      .fail
.next:  inc     r9
        jmp     .top

.fail:  call    _fof
        bts     dx,3

        ; epilogue
.done:  ret

_verify:; verify will compare bytes from offset up to delimiter against an array of bad bytes. It will respond 404 if a match is found.
; rax: buffer pointer
; rdi: connection fd
; rsi: delimiter
; dh:  offset
; dl:  handle + read i/o control
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 verify fail   (8)
; rcx: loop counter
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,0xd
        push    rcx

        ; local variables
        mov     QWORD [rbp-0x8],rax ; buffer
        mov     WORD [rbp-0xa],di   ; connection fd
        mov     BYTE [rbp-0xb],sil  ; delimiter
        mov     WORD [rbp-0xd],dx   ; options

        ; flush r1
        bt      dx,1
        jc      .dnf
        call    flush

        ; body
.dnf:   mov     cl,BYTE [rbp-0xb]   ; delimiter
        xchg    dl,dh
        movzx   rdx,dl
.top:   movzx   r8,BYTE [rax+rdx]   ; offset buffer value
        cmp     r8b,sil
        je      .done               ; if delimiter, done
        test    r8b,r8b
        jz      .done               ; if end of buffer content, done
        push    rdx
        xor     rdx,rdx
        call    checkr1
        bt      dx,3
        jc      .fail
        call    checkr2
        bt      dx,3
        jc      .fail
        pop     rdx
        inc     rdx
        jmp     .top

.fail:  mov     WORD [rbp-0xd],dx

        ; epilogue
.done:  mov     dx,WORD [rbp-0xd]  ; options
        pop     rcx
        mov     rsp,rbp
        pop     rbp
        ret

section .data
r1:     db      0x2E,0,0x2F,0,0     ; no more than one ./

section .rodata
r2:     db      0x5C,0x3A,0x2A,0x3F,0x25,0x22,0x3C,0x3E,0x7C,0       ; never \:*?%"<>|