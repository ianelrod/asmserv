; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Secure file descriptor reader
; This shit is voodoo
; Java's BufferedReader with extra steps
; -----------------------------------------

section .text
        global  _read
        extern  _verify

        ; print a read warning to stdout
rw:     mov     rax,1
        mov     rdi,1
        lea     rsi,[rws]
        mov     rdx,30
        syscall
        jmp     end

        ; print an alignment error to stdout
ae:     mov     rax,1
        mov     rdi,1
        lea     rsi,[aes]
        mov     rdx,31
        syscall
        jmp     end

shift:  ; this subroutine brings all bytes from offset to null to front of buffer
; we are considering the potential that we read more into the buffer than it takes to find the delimiter (specified by the offset), so we save the extra content past offset for the next read
; r8:  offset pointer
; r9:  buf pointer
; r10: general register
        ; prologue
        push    rax
        push    rdi
        push    rcx
        xor     r8,r8
        xor     r9,r9
        xor     r10,r10

        ; body
        xchg    dl,dh
        movzx   r10,dl
        xchg    dh,dl
        lea     r9,[_buf]
        cmp     r10,223
        jge     .zero               ; if buffer > BUF_SIZE - MAX_READ, just zero it
        mov     r8b,BYTE [_buf+r10]
        test    r8b,r8b             ; if buffer offset value is not zero, we need to add one (presuming here the value is the delimiter) to start properly at next section
        jz      .i
        inc     r10
.i:     lea     r8,[_buf+r10]
.top:   mov     r10b,BYTE [r8]
        test    r10b,r10b
        jz      .zero
        mov     BYTE [r9],r10b      ; if byte is not null, bring it to front
        inc     r8
        inc     r9
        jmp     .top
.zero:  lea     r8,[_buf]
        sub     r9,r8
        xchg    dl,dh
        mov     dl,0                ; new offset
        xchg    dh,dl
        mov     r8,0xff
        sub     r8,r9

        ; rep stosb stores rax in memory up to count rcx
        mov     cl,r8b              ; null count
        xor     rax,rax
        lea     rdi,[_buf+r9]
        rep stosb                   ; zero rest of buffer

        ; epilogue
.dna:   pop     rcx
        pop     rdi
        pop     rax
        ret

check:  ; this subroutine checks conditions below for alignment
; The offset is greater than BUF_SIZE - MAX_READ
; OR
; The offset value is delimiter
; rax: 0 none, 1 full buffer, 2 delimiter, 3 both
; dh:  offset
; r8:  general register
; r9:  general register
        ; prologue
        push    r8
        push    r9
        xor     rax,rax

        ; constants
        mov     r9,254
        sub     r9,32               ; BUF_SIZE - MAX_READ

        ; check for full buffer
        xchg    dl,dh
        movzx   r8,dl               ; offset
        xchg    dh,dl
        cmp     r8,r9
        jge     .buf
.next:  ; check for delimiter
        mov     r8b,BYTE [_buf+r8]  ; offset buffer value
        test    r8b,r8b
        jnz     .del
        jmp     .done

        ; actions
.buf:   inc     rax
        jmp     .next
.del:   cmp     rax,1
        je      .done
        add     rax,2

        ; epilogue
.done:  pop     r9
        pop     r8
        ret

take:   ; this subroutine reads from fd into buffer from offset to MAX_READ
        ; prologue
        push    r8
        push    r9
        push    rdi
        push    rsi
        push    rdx
        xor     r8,r8
        xor     r9,r9
        
        ; read 32 bytes into buffer
        mov     rax,0
        movzx   rdi,BYTE [rbp-0x1]
        xchg    dl,dh
        movzx   r8,dl
        xchg    dh,dl
        lea     rsi,[_buf+r8]
        mov     r8b,BYTE [rsi]
        test    r8,r8
        jnz     .dnt                    ; We want to preserve content that hasn't been read yet. This case happens if shift is called due to a found delimiter, and not a full buffer.
        mov     rdx,32
        syscall
        
        ; epilogue
.dnt:   pop     rdx
        pop     rsi
        pop     rdi
        pop     r9
        pop     r8
        ret

seek:   ; this subroutine reads from buffer from offset to delimiter or null
; rsi: delimiter
; r8:  offset
; r9:  general register
        ; prologue
        push    r8
        push    r9
        xor     r8,r8
        xor     r9,r9

        ; delimiter comparison loop
        xchg    dl,dh
        movzx   r8,dl
        xchg    dh,dl
.top:   mov     r9b,BYTE [_buf+r8]
        test    r9b,r9b
        jz      .done
        cmp     r9b,sil
        je      .done
        inc     r8b
        jmp     .top
.done:  xchg    dl,dh
        mov     dl,r8b
        xchg    dh,dl               ; set offset

        ; epilogue
        pop     r9
        pop     r8
        ret

_read:  ; this function reads from a fd and optionally sanitizes, up to 254 bytes
; rax:  [buf]
; rdi:  file descriptor
; rsi:  delimiter
; dh:  offset
; dl:  handle + read i/o control
; 0000 0001 read security (1)
; 0000 0010 keep verify   (2)
; 0000 0100 read not done (4)
; 0000 1000 none          (8)
; Security is only necessary if reading from a socket, not a file.
; In this case, we can trust that the fd is a socket fd
; r8:   general register
; r9:   general register
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,0x5
        push    r10

        ; local variables
        mov     BYTE [rbp-0x1],dil  ; file descriptor
        mov     BYTE [rbp-0x2],sil  ; delimiter
        mov     WORD [rbp-0x4],dx   ; options
        
        ; prepare function
        mov     BYTE [_buf+255],0   ; zero null
        call    check               ; check alignment
        cmp     rax,0
        je      .top
        call    shift

; the loop below reads from fd until security is triggered, buffer is full, or delimiter is found

.top:   call    take                ; read from fd
        cmp     rax,0
        jl      rw                  ; if read error, warn
        bt      dx,0
        jnc     .dnv                ; do not verify

        ; verify
        lea     rax,[_buf]
        movzx   rdi,BYTE [rbp-0x1]  ; connection fd
        movzx   rsi,BYTE [rbp-0x2]  ; delimiter
        call    _verify
        bts     dx,1                ; keep verify state
        mov     WORD [rbp-0x4],dx

.dnv:   call    seek                ; find delimiter
        call    check               ; check buffer for delimiter or fullness
        and     rax,3
        jz      .top

        ; epilogue
end:    lea     rax,[_buf]
        movzx   rdi,BYTE [rbp-0x1]  ; connection fd
        pop     r10
        mov     rsp,rbp
        pop     rbp
        ret

section .rodata
rws:    db      "Warning: Read returned error",0xa,0
aes:    db      "Error: Unexpected char in buf",0xa,0

section .bss
_buf:   resb    255                 ; buffer
        resb    1                   ; null