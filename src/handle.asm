; -----------------------------------------
; 64-bit program that handles HTTP requests
; Author: Ian Goforth
; 
; Child Connection Handler
; -----------------------------------------

section .text
        global  _handle
        extern  _end

_handle: