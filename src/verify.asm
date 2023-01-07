; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Byte validity checker
; -----------------------------------------

section .text
        global  _verify
        extern  _end

_verify:


        
section .rodata
bb:     db      "/","\","%",0       ; bad bytes