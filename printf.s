;:=========================================================================
;: 0-Linux-nasm-64.s                   (c)Matt,2026
;:=========================================================================

; nasm -f elf64 -l printf.lst printf.s ;  ld -s -o printf printf.o
; nasm -f elf64 -g printf.s -o printf.o
; gcc -no-pie printf.o -o printf
; gdb ./printf

%macro PRINT_STR 2
    mov rax, 0x01
    mov rdi, 1
    mov rsi, %1 ;msg
    mov rdx, %2 ;len
    syscall
%endmacro

section .text
global _start                  ; predefined entry point name for ld
;================================Code======================================
_start:         mov rax, 0x01      ; write64 (rdi, rsi, rdx) ... r10, r8, r9
                mov rdi, 1         ; stdout
                mov rsi, Msg
                mov rdx, MsgLen    ; strlen (Msg)
                syscall

                xor rax, rax
                mov rdi, Format
                mov rsi, -256
                mov rdx, 12345
                mov rcx, 'K'
                mov r8, 0x00
                mov r9, 0x0B
                push 0x0A
                call my_printf
                add rsp, 0x08

                ; mov rdi, Format2
                ; mov rsi, -253
                ; mov rdx, -112233
                ; mov rcx, 'r'
                ; call my_printf

                
                
                mov rax, 0x3C      ; exit64 (rdi)
                xor rdi, rdi
                syscall
;==========================================================================

;=============================My_Printf====================================
my_printf:
                push r9
                push r8
                push rcx 
                push rdx
                push rsi
                push rax
                push rbp
                mov rbp, rsp

                mov r10, PrintArgsPos ; start_pos of arg counter
                mov rsi, rdi ; format str
                mov rdi, Print_Buf ;printbuf pos

.lp:            lodsb ;[rsi] -> al
                cmp al, 0x00
                je .print_buf
                cmp al, '%'

                je .spec
.back:          stosb ; al -> [rdi]
.next_parse:    jmp .lp

.print_buf:     
                mov rcx, rdi
                sub rcx, Print_Buf
                PRINT_STR Print_Buf, rcx
                jmp .exit

.spec:
                lodsb ;al - specifier
                cmp al, '%'
                je .back
                movzx rax, al
                sub al, BaseElem
                shl rax, 3 ;al * 8 byte
                mov rdx, rax

                mov rax, [rbp + r10] ;argument value
                add r10, 0x08 ;next elem
                cmp r10, IpStackPos
                mov r11, (IpStackPos + 0x08) ;skip ip
                cmove r10, r11

                jmp [.switch_table + rdx]

.switch_table:
                dq .case_b  ;98     0
                dq .case_c  ;99     1
                dq .case_d  ;100    2
                times 10 dq .default
                dq .case_o  ;111    13
                dq .case_p  ;112    14
                dq .default
                dq .case_s  ;114    16
                times 5 dq .default 
                dq .case_x  ;120    22

.case_b:
                mov r8, 0x01 ;bin mask
                mov cl, 0x01 ;bin offset
                mov dl, 'b'
                jmp .numsyst_conv

.case_c:             
                stosb 
                jmp .next_parse     

.case_d:
                call itoa
                jmp .next_parse


.case_o:        
                mov r8, 0x07 ;octo mask
                mov cl, 0x03 ;octo offset
                mov dl, 'o'
                jmp .numsyst_conv

.case_p:

.case_s:

.case_x:        
                mov r8, 0x0F ;hex mask
                mov cl, 0x04 ;hex offset
                mov dl, 'x'
                jmp .numsyst_conv

.default:
                jmp .next_parse

.numsyst_conv:
                mov r9, rax ;save arg
                mov al, '0'
                stosb
                mov al, dl
                stosb
                mov rax, r9
                call num_to_str
                jmp .next_parse


.exit:          pop rbp
                pop rax 
                pop rsi 
                pop rdx
                pop rcx
                pop r8
                pop r9

                ret
;==========================================================================
;Entry:         rdi - format str addr
;               rsi - first spec arg
;               rdx - second
;               rcx - third
;               r8  - fourth
;               r9  - fifth
;               others in a stack
;               rax - count float args xmm0 - xmm7
;Destroyed:     r10
;Expected:
;Comment:       r10 - current parsing argument
;ToDo:
;==========================================================================

;=============================Print_Str====================================
;==========================================================================
;Entry:  
;Destroyed:
;Expected:
;Comment:
;ToDo:
;==========================================================================

;===================================num_to_str=============================
num_to_str:
                push rax 
                push rsi

                mov rdx, rax ;save rax
                mov r9, rdi ;save print_buf pos in r9
                mov rdi, Temp_Buf

.next_digit: 
                mov rax, rdx ;save in new rax
                and rax, r8 ;mask with numsyst base

                cmp rax, 0x0A ;is letter digit
                jae .get_letter
                add rax, '0' ;get digit
.back:          stosb ;temp_buf

                shr rdx, cl ;next digit

                test rdx, rdx 
                jz .exit ;don't check insign zeros

                jmp .next_digit

.get_letter:    add rax, ('A' - 0x0A) ;10-15 to A-F
                jmp .back

.exit:          
                mov rsi, rdi ;cur Temp_Buf pos
                mov rdi, r9 ;return print_buf pos

                mov rcx, rsi
                sub rcx, Temp_Buf ; get_len
                dec rsi

.lp:            std
                lodsb
                cld
                stosb
                loop .lp 

                pop rsi
                pop rax

                ret
;===================================num_to_str=============================
;Entry: rax - arg, 
;       r8 - numsyst base (that's degree of 2 and also a mask)
;       cl - numsyst offset (in degree of 2 positions)
;       rdi - printf_buf pos
;Exit:  
;Expected:
;Destroyed: rdx, r9, rcx
;Comment: convert digit to numsystem str
;ToDo:
;==========================================================================

;===================================Itoa===================================
itoa:           
                push rax 
                push rsi

                mov rbx, 10 ;decimal
                mov rsi, Temp_Buf

                cmp rax, 0x00 ;set SF
                jns .next_digit

                mov dl, '-'
                mov [rdi], dl ; - to print_buf
                inc rdi
                not rax
                inc rax

.next_digit:    xor rdx, rdx
                div rbx ;rax /= 10 rdx - left
                add dl, '0'
                mov [rsi], dl
                inc rsi

                test rax, rax
                jnz .next_digit

                mov rcx, rsi
                sub rcx, Temp_Buf ; get_len
                dec rsi
                
.lp:            std
                lodsb
                cld
                stosb
                loop .lp          

.exit:          pop rsi 
                pop rax
                ret
;===================================Itoa===================================
;Entry: rax - value
;       rsi - format str pos, 
;       rdi - print_buf pos
;Exit:  rdi - cur print_buf pos
;Expected:
;Destroyed: rbx, rdx, rcx
;Comment: convert int to string
;ToDo:
;==========================================================================

;==============================Data========================================
section     .data  
Format:         db "Is: %% %d %d %c %x %o %b ", 0  
Format2:        db "%% Is: %d %d %c", 0  
Print_Buf       times 1000 db 0
Print_Buf_Len   equ $ - Print_Buf    
Temp_Buf        times 64 db 0
Temp_BufSize    equ $ - Temp_Buf
BaseElem        equ 98d
PrintArgsPos    equ 0x08 * 2
IpStackPos      equ PrintArgsPos + 5 * 0x08 ;argspos + 5 args

Msg:            db "Matt", 0x0a
MsgLen          equ $ - Msg
