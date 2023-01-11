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
.top:   mov     r10,BYTE [r8]
        cmp     r10b,r9b
        je      .done
        mov     BYTE [r8+1],r9
        add     r8,2
        jmp     .top

        ; epilogue
.done:  ret

r1:     ; check byte against rule 1
; r8:  byte
; r9:  byte pointer
; r10: general register
        ; prologue
        xor     r9,r9
        xor     r10,r10

        ; body
        lea     r9,[r1]
.top:   mov     r10,BYTE [r9]
        cmp     r10b,0
        je      .done
        cmp     r8b,r10b
        je      .error
.next:  add     r9,2
        jmp     .top

.error: mov     r10,BYTE [r9+1]
        cmp     r10b,0
        jne     _fof
        inc     r10b
        mov     BYTE [r9+1],r10
        jmp     .next

        ; epilogue
.done:  ret

r2:     ; check byte against rule 2
; r8:  byte
; r9:  byte pointer
; r10: general register
        ; prologue
        xor     r9,r9
        xor     r10,r10

        ; body
        lea     r9,[r2]
.top:   mov     r10,BYTE [r9]
        cmp     r10b,0
        je      .done
        cmp     r8b,r10b
        je      _fof
.next:  inc     r9
        jmp     .top

        ; epilogue
.done:  ret

_verify:; verify will compare bytes from offset up to MAX_READ against an array of bad bytes. It will respond 404 if a match is found.
; rax: r1 state
; 0000 keep
; 0001 flush
; rdi: buffer pointer
; rsi: socket fd
; dh:  offset
; dl:  handle + read state
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 none          (8)
; rcx: loop counter
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,0xb
        push    rcx

        ; local variables
        mov     QWORD [rbp-0x8],rdi
        mov     WORD [rbp-0xa],rsi
        mov     BYTE [rbp-0xb],rdx  ; options

        ; flush r1
        bt      dx,1
        jnc     .dnf
        call    flush

        ; body
.dnf:   mov     cl,32
.itop:  mov     sil,[rdi+dh]        ; offset buffer value
        mov     r8b,sil
        call    r1
        call    r2
.ibot:  inc     dh
        dec     cl
        cmp     cl,0                ; MAX_READ reached?
        jne     .itop

        ; epilogue
.done:  mov     rdx,BYTE [rbp-0xb]  ; options
        pop     rcx
        mov     rsp,rbp
        pop     rbp
        ret

section .data
r1:     db      0x2E,0,0x2F,0,0     ; no more than one ./

section .rodata
r2:     db      0x5C,0x3A,0x2A,0x3F,0x25,0x22,0x3C,0x3E,0x7C,0       ; never \:*?%"<>|