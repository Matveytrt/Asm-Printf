; nasm -f elf64 main.s -o asmmain.o
; nasm -f elf64 printf.s -o printf.o
; g++ -no-pie asmmain.o printf.o -o asmprintf
; ./asmprintf

extern my_printf

global main                 ; predefined entry point name for ld
section .text
;================================Code======================================
main:  
                xor rax, rax ;"Is: %% %d %d %c %x %o %s %b "
                mov rdi, Format
                mov rsi, -256 ;first
                mov rdx, 12345 ;second
                mov rcx, 'K' ;third
                mov r8, 0x0F0 ;fourth
                mov r9, 0x0BBB ;fifth   
                push 0x28 ;seventh
                push Msg ; sixth
                call my_printf
                add rsp, 16

                ; xor rax, rax
                ; mov rdi, Format2
                ; mov rsi, Msg
                ; ; mov rdx, -112233
                ; ; mov rcx, 'r'
                ; call my_printf

                
                
                mov rax, 0x3C      ; exit64 (rdi)
                xor rdi, rdi
                syscall
;==========================================================================

section .data
Format:         db "Is: %% %d %d %c %x %o %s %b ahaha", 0x0a, 0  
Format2:        db "%% Is: %s", 0x0a, 0  
Msg             db "Matuwa the beast!", 0
MsgLen          equ $ - Msg
