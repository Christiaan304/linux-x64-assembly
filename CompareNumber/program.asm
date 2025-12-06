; ======================================================================
; Author: Christiaan FR
; Created at: 2025Y12M5DT19?HZ                                         ;
; A simple program that compares a double against a defined constant   ;
; Assembler: NASM                                                      ;
; OS: x86_64 Linux Mint                                                ;
; Compiling using                                                      ;
; nasm -f elf64 program.asm -o program.o                               ;
; gcc program.o -o program -no-pie                                     ;
; ======================================================================

%include "mymacros.inc"
 
section .data
    const_12 dq 12.0
	
    prompt db "Type a number: ", 0
    prompt_len equ $ - prompt
    invalid_prompt_msg db "Invalid input, type a valid number: ", 10, 0
    invalid_prompt_msg_len equ $ - invalid_prompt_msg
	
    fmt_flush db "%*s", 0
    fmt_in_float db "%lf", 0
    fmt_out_float_le db "You typed %f, less than 12", 10, 0
    fmt_out_float_ge db "You typed %f, greater than 12", 10, 0
 
section .bss
    number resq 1
 
section .text
    global main
    extern printf
    extern scanf
 
main:
    prologue

.read_input
    write prompt, prompt_len
 
    mov rdi, fmt_in_float
    mov rsi, number
    xor rax, rax
    call scanf
	
    ; scanf returns the number of items successfully read
    ; if return != 1 -> invalid input
    cmp rax, 1
    jne .invalid_prompt
    jmp .compare_number
	
.invalid_prompt
    write invalid_prompt_msg, invalid_prompt_msg_len
	
    ; flush invalid input from stdin
    ; this reads a string instead, clearing garbage
    mov rdi, fmt_flush
    xor rax, rax
    call scanf

    jmp .read_input
 
 .compare_number
    movsd xmm0, [number]
    ucomisd xmm0, [const_12]
    jbe .less_or_equal
 
.greater_or_equal:
    mov rdi, fmt_out_float_ge
    mov rax, 1
    call printf
    jmp .exit
 
.less_or_equal:
    mov rdi, fmt_out_float_le
    mov rax, 1
    call printf
 
.exit:
    epilogue
 
    section .note.GNU-stack noalloc noexec nowrite progbits