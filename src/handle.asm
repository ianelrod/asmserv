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
;        extern  _post

_handle:; this function receives a child forked from main and performs all steps necessary to handle a connection
; It closely interoperates with read.asm to parse data
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; dh:  offset
; dl:  handle + read i/o control
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 verify fail   (8)
; rcx: counter
        ; prologue
        push    rdi                 ; put connection fd

        ; set socket option SO_LINGER
        mov     r8,8                ; struct length 8 bytes
        ; struct linger {
        ;     int l_onoff;    /* linger active */
        ;     int l_linger;   /* how many seconds to linger for */
        ; };
        mov     rax,0x100000001     ; SO_LINGER struct
        push    rax
        lea     r10,[rsp]           ; set boolean to true
        mov     rdx,13              ; SO_LINGER (wait around until all data is sent for 200 ms even after calling exit())
        mov     rsi,1               ; SOL_SOCKET (edit socket api layer)
        xor     rax,rax
        mov     rax,54              ; operator setsockopt
        syscall
        pop     rax

        ; get HTTP request method
        xor     rax,rax
        xor     rdx,rdx             ; clear options for new child
        mov     rsi," "             ; delimit strings by space
        btr     dx,0                ; no security
        call    _read

        ; interpret HTTP request method
        ; 1. check read result
        xor     rdi,rdi
        inc     r12                 ; method error: 6
        cmp     dh,8                ; verify length
        jg      .end
        push    dx                  ; next 5 lines devoted to coping with using dh
        xchg    dl,dh
        movzx   rdx,dl
        mov     dil,BYTE [rax+rdx]
        pop     dx
        cmp     dil," "             ; verify delimiter
        jne     .end

        ; 2. store request method in local variable
        xor     rcx,rcx
        xor     rsi,rsi
        mov     cl,dh
        dec     cl
.top:   mov     dil,BYTE [rax+rcx]  ; take byte
        mov     sil,dil             ; put byte
        test    cl,cl
        jz      .done
        dec     cl
        shl     rsi,8
        jmp     .top

        ; 3. compare request method to "GET" or "POST"
.done:  pop     rdi                 ; get connection fd
        cmp     rsi,"GET"
        jne     .i
        call    _get
        jmp     .end
.i:     cmp     rsi,"POST"
        jne     .end
;        call    _post

        ; epilogue
.end:    ret
