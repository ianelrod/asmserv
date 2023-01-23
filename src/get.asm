; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; GET request related actions
; -----------------------------------------

section .text
        global  _get
        extern  _read
        extern  _end

chkrd:  ; this subroutine checks the TCP unread buffer and returns count
; rax: ioctl operator / result
; rdi: connection fd
; rsi: TIOCINQ (data in receive queue not read and not ack'd)
; rdx: data count
        mov     QWORD [rbp-267],0           ; clear previous result
        lea     rdx,[rbp-267]
        mov     rsi,0x541B
        movzx   rdi,BYTE [rbp-259]
        mov     rax,16
        syscall
        mov     rax,QWORD [rbp-267]
        ret

; chksd: ; this subroutine checks the TCP unsent buffer and returns count
; ; rax: ioctl operator / result
; ; rdi: connection fd
; ; rsi: TIOCOUTQ (data in send queue not sent and not ack'd)
; ; rdx: data count
;         mov     QWORD [rbp-267],0          ; clear previous result
;         lea     rdx,[rbp-267]
;         mov     rsi,0x5411
;         movzx   rdi,BYTE [rbp-259]
;         mov     rax,16
;         syscall
;         mov     rax,QWORD [rbp-267]
;         ret

flush: ; this subroutine reads from the socket to /dev/null
; rax: read operator / result
; rdi: connection fd
; rsi: /dev/null
; rdx: read count
        mov     rdx,8
        lea     rsi,[rbp-267]
        movzx   rdi,BYTE [rbp-259]
        mov     rax,0
        syscall
        ret

_get:   ; this function is called from handle.asm to perform actions related to GET requests
; REGISTERS
; rax: result handler
; rdi: connection fd / general register
; rsi: general register
; rcx: counter
; OPTIONS
; dh:  offset
; dl:  handle + read i/o control
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 verify fail   (8)
; STACK
; rbp-256:  local path buffer
; rbp-257:  local path offset
; rbp-258:  file fd
; rbp-259:  connection fd
; rbp-267:  unsent/unread data
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,267

        ; get HTTP request path
        xor     rax,rax
        mov     rsi," "             ; delimit strings by space
        bts     dx,0                ; security
.top1:  btr     dx,2
        call    _read

        ; security check (verify failed?)
        bt      dx,3
        jc      .end

        ; interpret HTTP request path
        ; 1. check read result
        mov     BYTE [rbp-259],dil  ; put connection fd
        xor     rdi,rdi
        xor     rsi,rsi
        xchg    dl,dh               ; buffer offset from dh to sil
        mov     sil,dl
        xchg    dh,dl
        mov     dil,BYTE [rax+rsi]  ; offset value
        cmp     dil," "             ; offset value = delimiter?
        je      .i                  ; store FULL path
        xor     rcx,rcx
        mov     cl,255
        sub     cl,32
        cmp     dil,cl              ; offset > BUF_SIZE - MAX_READ?
        jg      .j                  ; store WHAT WE HAVE OF path (case: path is longer than BUF_SIZE - MAX_READ but less than linux max of 255B)
        jmp     .top1

        ; 2. store request path in local variable
.i:     btr     dx,2                ; delimiter found, done reading request path
        jmp     .l
.j:     bt      dx,2                ; is this not our first read?
        jnc     .k
        add     BYTE [rbp-257],dh   ; add offset to local path offset
.k:     bts     dx,2                ; offset > BUF_SIZE - MAX_READ
.l:     xor     rcx,rcx
        movzx   rcx,BYTE [rbp-257]  ; local path offset set to 0 in the beginning, optionally picking up where we left off in subsequent loops
        inc     r12                 ; path error: 7
        cmp     rcx,255             ; if our path is longer than 255 bytes, something has gone seriously wrong
        jge     .end

        lea     rsi,[rbp+rcx-256]
        mov     cl,dh               ; loop counter
        push    rax                 ; retain buffer pointer
.top2:  mov     dil,BYTE [rax]      ; take byte
        mov     BYTE [rsi],dil      ; put byte
        inc     rax
        inc     rsi
        dec     cl
        jz      .done1
        jmp     .top2
.done1: pop     rax
        bt      dx,2
        jc      .top1               ; full path not gotten yet, so read again

        ; interpret file path
        push    rdx                 ; retain options
        mov     rax,2               ; operator open
        lea     rdi,[rbp-255]       ; ignore beginning forward slash
        xor     rsi,rsi
        xor     rdx,rdx
        syscall
        inc     r12                 ; file error: 8
        cmp     rax,0
        jl      .end
        mov     BYTE [rbp-258],al   ; put file descriptor

        ; flush socket using read
.clr:   call    chkrd
        cmp     rax,0
        jle     .done2
        call    flush
        jmp     .clr

        ; send contents of file back to client, we can use sendfile for this
        ; 1. get file size using lseek
.done2: mov     rax,8               ; operator lseek
        movzx   rdi,BYTE [rbp-258]  ; in fd (file)
        mov     rsi,0               ; offset
        mov     rdx,2               ; SEEK_END
        syscall
        cmp     rax,2147483647      ; file over 2GiB-1 limit?
        jo      .end                ; file error: 8
        inc     rax
        push    rax

        ; 2. reset file offset using lseek
        mov     rax,8               ; operator lseek
        mov     rdx,0               ; SEEK_SET
        syscall

        ; 3. transfer file using sendfile
        mov     rax,40              ; operator sendfile
        movzx   rdi,BYTE [rbp-259]  ; out fd (connection)
        movzx   rsi,BYTE [rbp-258]  ; in fd (file)
        mov     rdx,0               ; offset 0
        pop     r10                 ; file size, also count to send
        syscall

        ; 4. wait until all data is sent before closing
        ; this is necessary because our socket is nonblocking. We could and likely would close the connection before all data is sent.
; .sit:   mov     rax,16              ; operator ioctl
;         movzx   rdi,BYTE [rbp-259]
;         mov     rsi,0x5411          ; TIOCOUTQ (data in send queue not sent and not ack'd)
;         lea     rdx,[rbp-267]
;         syscall
;         mov     rdx,QWORD [rbp-267] ; unsigned int
;         cmp     rdx,0
;         jg      .sit

        ; close connection
        ; mov     rax,3               ; operator close
        ; movzx   rdi,BYTE [rbp-259]
        ; syscall

        ; epilogue
        pop     rdx                 ; empty stack
        mov     r12,0               ; normal exit
.end:   mov     rsp,rbp
        pop     rbp
        ret