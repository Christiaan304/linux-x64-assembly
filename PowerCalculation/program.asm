; ======================================================================
; Author: Christiaan FR                                                ;
; Created at: 2025Y12M6DT18H46MZ                                       ;
; A simple program that calculates exponentiation                      ;
; Assembler: NASM                                                      ;
; OS: x86_64 Linux Mint                                                ;
; Compiling using                                                      ;
; nasm -f elf64 program.asm -o program.o                               ;
; gcc program.o -o program -no-pie -lm                                 ;
; ======================================================================

%include "mymacros.inc"

section .data
    base_prompt_msg db "Type the base: ", 0
    base_prompt_msg_len equ $ - base_prompt_msg
    
    exponent_prompt_msg db "Type the exponent: ", 0
    exponent_prompt_msg_len equ $ - exponent_prompt_msg

    invalid_prompt_msg db "Invalid prompt, type a valid number ", 10, 0
    invalid_prompt_msg_len equ $ - invalid_prompt_msg
    
    ; Format strings for C functions
    fmt_in_double db "%lf", 0          ; %lf = long float (double precision) for scanf
    fmt_out_double db "Result: %f ^ %f = %f", 10, 0 ; Output format

section .bss    
    ; "resq" = Reserve Quadword (8 bytes). Needed for 64-bit doubles.
    base_number resq 1
    exponent_number resq 1

section .text
    global main
    
    ; Import C library functions
    extern getchar
    extern pow
    extern printf
    extern scanf

main:
    prologue

.read_base_input:
    write base_prompt_msg, base_prompt_msg_len

    ; Prepare arguments for scanf("%lf", &base_number)
    mov rdi, fmt_in_double  ; Arg 1: Format string
    mov rsi, base_number    ; Arg 2: Memory address to store result
    xor rax, rax            ; Clear RAX (Standard for calling variadic functions like scanf)
    call scanf
    
    ; Check if scanf succeeded
    cmp rax, 1              ; scanf returns the number of items successfully read
    je .read_exponent_input ; If 1 item read, jump to next section
    
    ; ERROR HANDLING
    ; If we are here, scanf failed (rax == 0).
    ; Expand the macro to print error and clear buffer.
    invalid_input_flush invalid_prompt_msg, invalid_prompt_msg_len
    
    ; Jump back to try again
    jmp .read_base_input

.read_exponent_input:
    write exponent_prompt_msg, exponent_prompt_msg_len

    mov rdi, fmt_in_double
    mov rsi, exponent_number
    xor rax, rax
    call scanf

    cmp rax, 1
    je .calculate_power    
    invalid_input_flush invalid_prompt_msg, invalid_prompt_msg_len
    jmp .read_exponent_input

.calculate_power:
    ; Function signature: double pow(double base, double exponent)
    ; In x64 ABI, floating point arguments go into XMM registers.
    ; Arg 1 (base) -> xmm0
    ; Arg 2 (exp)  -> xmm1    
    movsd xmm0, [base_number]     ; Load base from memory to XMM0
    movsd xmm1, [exponent_number] ; Load exponent from memory to XMM1
    call pow
    
    ; The result of 'pow' is now inside xmm0.    
    ; We need to save the result and the original inputs to print them later.
    ; Because printf reuses xmm0 and xmm1, we shuffle registers.
    ; Desired printf("%f ^ %f = %f") arguments:
    ; xmm0 = base
    ; xmm1 = exponent
    ; xmm2 = result (which is currently in xmm0)
    movsd xmm2, xmm0              ; Move Result to xmm2
    movsd xmm1, [exponent_number] ; Reload Exponent to xmm1
    movsd xmm0, [base_number]     ; Reload Base to xmm0

.result:
    mov rdi, fmt_out_double ; Arg 1: Format string
    mov rax, 3              ; Important: Tell printf we are using 3 vector registers (xmm0-2)
    call printf

.exit:
    epilogue
    
    ; Note regarding Stack Security:
    section .note.GNU-stack noalloc noexec nowrite progbits