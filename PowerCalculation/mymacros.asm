; =======================================================================
; MACRO DEFINITIONS
; =======================================================================

; -----------------------------------------------------------------------
; Macro: prologue
; Purpose: Sets up the "Stack Frame" for a function.
; Why? It saves the caller's stack location (rbp) so we can restore it later.
;      This is required for the code to play nice with C functions like printf.
; -----------------------------------------------------------------------
%macro prologue 0
    push rbp        ; Save the old Base Pointer to the stack
    mov rbp, rsp    ; Set the new Base Pointer to the current Stack Pointer
%endmacro

; -----------------------------------------------------------------------
; Macro: epilogue
; Purpose: Cleans up the stack and returns to the caller.
; -----------------------------------------------------------------------
%macro epilogue 0
    mov rax, 0      ; Return 0 (standard for "success" in main functions)
    pop rbp         ; Restore the caller's Base Pointer
    ret             ; Return to where this function was called
%endmacro

; -----------------------------------------------------------------------
; Macro: write
; Arguments: %1 = Address of message, %2 = Length of message
; Purpose: Prints a string to stdout using the system call (syscall).
; -----------------------------------------------------------------------
%macro write 2
    mov rax, 1      ; Syscall ID for 'sys_write' is 1
    mov rdi, 1      ; File Descriptor 1 = stdout (standard output)
    mov rsi, %1     ; Argument 2: Address of the text to print
    mov rdx, %2     ; Argument 3: How many bytes (length) to print
    syscall         ; Ask the kernel to perform the action
%endmacro

; -----------------------------------------------------------------------
; Macro: invalid_input_flush
; Arguments: %1 = Error message address, %2 = Error message length
; Purpose: Prints an error and clears the input buffer (stdin).
; Why? If scanf fails, the bad character stays in the buffer. 
;      We must read until a newline (\n) to "flush" the garbage out, 
;      otherwise scanf will fail infinitely in a loop.
; -----------------------------------------------------------------------
%macro invalid_input_flush 2
    ; 1. Print the error message
    write %1, %2

    ; 2. Start a loop to read character by character
    ; Note: We use %% before labels (%%loop) to make them "local".
    ; NASM generates a unique name (like ..@182.flush_loop) every time
    ; this macro is used, preventing "Redefined Label" errors.    
%%flush_loop:
    call getchar        ; Call C function to get one char. Result in AL/RAX.
    
    cmp rax, -1         ; Check for EOF (End Of File)
    je %%flush_done     ; If end of input, stop loop to avoid hanging
    
    cmp rax, 10         ; Compare input with 10 (ASCII for Newline '\n')
    jne %%flush_loop    ; If it's NOT a newline, keep eating characters
    
%%flush_done:
    ; Loop finishes when we hit a newline or EOF.
    ; We fall through to the end of the macro.
%endmacro