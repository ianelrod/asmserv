; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Secure file descriptor reader
; This shit is voodoo
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
        jmp     fin

        ; print an alignment error to stdout
ae:     mov     rax,1
        mov     rdi,1
        lea     rsi,[aes]
        mov     rdx,31
        syscall
        jmp     fin

align:  ; this subroutine brings all bytes from offset to null to front of buffer
; we are considering the potential that we read more into the buffer than it takes to find the delimiter (specified by the offset), so we save the extra content past offset for the next read
; r8:  offset pointer
; r9:  buf pointer
; r10: general register
        ; prologue
        push    rax,rax
        push    rdi,rdi
        push    rcx,rcx
        xor     r8,r8
        xor     r9,r9
        xor     r10,r10

        ; body
        mov     r10b,BYTE [_buf-1]
        lea     r9,[_buf]
        cmp     r10b,0xff
        je      .zero               ; if buffer is full, just zero it
        lea     r8,[_buf+r10b]
.top:   mov     r10b,[r8]
        jz      .zero
        mov     BYTE [r9],r10b      ; if byte is not null, bring it to front
        inc     r8
        inc     r9
        jmp     .top
.zero:  lea     r8,[_buf]
        sub     r9,r8
        mov     BYTE [_buf-1],r9b   ; new offset
        mov     r8b,254
        sub     r8b,r9b

        ; rep stosb stores rax in memory up to count rcx
        mov     cl,r8b              ; null count
        xor     rax,rax
        lea     rdi,[_buf+r9b]
        rep stosb                   ; zero rest of buffer

        ; epilogue
.dna:   pop     rcx,rcx
        pop     rdi,rdi
        pop     rax,rax
        ret

check:  ; this subroutine checks conditions below for alignment
; The offset is greater than BUF_SIZE - MAX_READ
; OR
; The offset value is delimiter
; rax: 0 none, 1 full buffer, 2 delimiter, 3 both
; r8:  general register
; r9:  general register
        ; prologue
        push    r8
        push    r9
        xor     rax,rax

        ; constants
        mov     r9b,254
        sub     r9b,32              ; BUF_SIZE - MAX_READ

        ; check for full buffer
        mov     r8b,BYTE [_buf-1]    ; offset
        cmp     r8b,r9b
        jge     .buf
.next:  ; check for delimiter
        mov     r8b,BYTE [_buf+r8b]  ; offset buffer value
        jnz     .del

        ; actions
.buf:   inc     rax
        jmp     .next
.del:   inc     rax
        cmp     rax,2
        jl      .done
        inc     rax

        ; epilogue
.done:  pop     r9
        pop     r8
        ret

take:   ; this subroutine reads from fd into buffer from offset to MAX_READ
        ; prologue
        push    r8
        push    r9
        xor     r8,r8
        xor     r9,r9
        
        ; read 32 bytes into buffer
        mov     rax,0
        mov     rdi,WORD [rbp-0x2]
        xor     r8,r8
        mov     r8,BYTE [_buf-1]
        lea     rsi,[_buf+r8]
        mov     rdx,32
        syscall
        
        ; epilogue
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
        mov     r8b,[_buf-1]
.top:   mov     r9b,[_buf+r8b]
        jz      .done
        cmp     r9b,sil
        je      .done
        inc     r8b
        jmp     .top
.done:  mov     [_buf-1],r8b        ; set offset

        ; epilogue
        pop     r9
        pop     r8
        ret

_read:  ; this function reads from a fd and optionally sanitizes, up to 254 bytes
; rax:  [buf]
; rdi:  file descriptor
; rsi:  delimiter
; rdx:  options
; 0001  security
; Security is only necessary if reading from a socket, not a file.
; In this case, we can trust that the fd is a socket fd
; r8:   general register
; r9:   general register
        ; prologue
        push    rbp
        mov     rbp,rsp
        sub     rsp,4
        push    r10

        ; local variables
        mov     WORD [rbp-0x2],rdi  ; file descriptor
        mov     BYTE [rbp-0x3],rsi  ; delimiter
        mov     BYTE [rbp-0x4],rdx  ; options
        
        ; prepare function
        mov     [_buf+254],0        ; zero null
        call    check               ; check alignment
        cmp     rax,0
        je      .top
        call    align

; the loop below reads from fd until security is triggered, buffer is full, or delimiter is found

.top:   call    take                ; read from fd
        cmp     rax,0
        jle     rw                  ; if read error, warn
        cmp     rdx,1
        jl      .dnv                ; do not verify

        ; verify
        lea     rdi,[_buf]
        mov     rsi,WORD [rbp-0x2]  ; delimiter
        call    _verify
        mov     rdx,3               ; keep verify state
        mov     BYTE [rbp-0x4],rdx

.dnv:   call    seek                ; find delimiter
        call    check               ; check buffer for delimiter or fullness
        and     rax,3
        jz      .top

        ; epilogue
fin:    lea     rax,[_buf]
        pop     r10
        mov     rsp,rbp
        pop     rbp
        ret

section .rodata
rws:    db      "Warning: Read returned error",0xa,0
aes:    db      "Error: Unexpected char in buf",0xa,0

section .bss
        resb    1                   ; offset
_buf:   resb    254                 ; buffer
        resb    1                   ; null