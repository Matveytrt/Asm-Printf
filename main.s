; nasm -f elf64 main.s -o asmmain.o
; nasm -f elf64 printf.s -o printf.o
; g++ -no-pie asmmain.o printf.o -o asmprintf
; ./asmprintf

extern my_printf

global main                 ; predefined entry point name for ld
section .text
;================================Code======================================
main:  
                ; mov rax, 1 ;"Is: %% %d %d %c %x %o %s %b "
                ; mov rdi, Format
                ; mov rsi, -256 ;first
                ; mov rdx, 12345 ;second
                ; mov rcx, 'K' ;third
                ; mov r8, 0x0F0 ;fourth
                ; mov r9, 0x0BBB ;fifth 
                ; push 0x28 ;seventh
                ; push Msg ; sixth
                ; sub rsp, 16
                ; movd xmm0, [value] 
                ; call my_printf
                ; add rsp, 16

                ; mov rax, 1
                ; mov rdi, Format2
                ; mov rsi, -5
                ; movq xmm0, [value]
                ; ; mov rdx, -112233
                ; ; mov rcx, 'r'
                ; call my_printf

                mov rax, 9
                mov rdi, Format3
                mov rsi, 1
                mov rdx, 2
                mov rcx, 3
                mov r8, 4
                mov r9, 5 
                push 9
                sub rsp, 16
                mov rax, [value2]      ; float
                mov [rsp], rax
                push 8
                push 7
                push 6
                movq xmm0, [value]
                movq xmm1, [value]
                movq xmm2, [value]
                movq xmm3, [value]
                movq xmm4, [value]
                movq xmm5, [value]
                movq xmm6, [value]
                movq xmm7, [value]
                call my_printf

                mov rax, 0x3C      ; exit64 (rdi)
                xor rdi, rdi
                syscall
;==========================================================================

section .data
Format:         db "Is: %% %d %d %c %x %o %s %b %f ahaha", 0x0a, 0  
Format2:        db "%% Is: %d %f", 0x0a, 0 
Format3:        db 'Test: 1: %f %x | 2: %f %x | 3: %f %x | 4: %f %x | 5: %f %x | 6: %f %x | 7: %f %x | 8: %f %x |9: %f %x', 0
Msg             db "Matuwa the beast!", 0
MsgLen          equ $ - Msg
value           dq 1.253
value2          dq -0.52423233

