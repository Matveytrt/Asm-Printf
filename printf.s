;:=========================================================================
;: 0-Linux-nasm-64.s                   (c)Matt,2026
;:=========================================================================

; nasm -f elf64 -l printf.lst printf.s ;  ld -s -o printf printf.o
; nasm -f elf64 -g printf.s -o printf.o
; gdb ./printf

%macro PRINT_STR 2
            mov rax, 0x01
            mov rdi, 1
            mov rsi, %1 ;msg
            mov rdx, %2 ;len
            syscall
%endmacro

%macro CHECK_BUFSIZE 1
            mov rcx, rdi
            sub rcx, Print_Buf
            cmp rcx, Print_BufSize
            jb %1
            push rsi
            PRINT_STR Print_Buf, rcx
            mov rdi, Print_Buf
            pop rsi
%endmacro


%macro SAFE_PRINTF 1
    ; save all regs
    push rax
    push rcx
    push r11
    push rdi
    push rsi
    push rdx
    push r8
    push r9
    push r10
    push rbx
    
    sub rsp, 8
    mov rdi, %1
    xor eax, eax
    call printf
    add rsp, 8
    
    ; Восстанавливаем регистры
    pop rbx
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx
    pop rax
%endmacro

global my_printf
section .text
;=============================My_Printf====================================
my_printf:
                push rbp ;align stk

                push r9
                push r8
                push rcx 
                push rdx
                push rsi
                mov rbp, rsp ;pos of addresation

                push rdi ;save format str
                push rax ;save nfloats
                sub rsp, R_Step ;align stack

                mov r12, R_ArgsPos ; start_pos of arg counter NOT CHANGE
                mov rsi, rdi ; format str ONLY
                mov rdi, Print_Buf ;print_buf pos

.lp:            lodsb ;[rsi] -> al
                cmp al, 0x00
                je .print_buf

                cmp al, '%'
                je .spec
.continue:      
                stosb ; al -> [rdi]
                CHECK_BUFSIZE .lp
.next_parse:    jmp .lp

.print_buf:     
                mov rcx, rdi
                sub rcx, Print_Buf
                PRINT_STR Print_Buf, rcx
                jmp .exit

.spec:
                lodsb ;al - specifier
                cmp al, '%'
                je .continue
                movzx rax, al
                sub al, BaseElem
                shl rax, 3 ;al * 8 byte
                mov rdx, rax

                cmp r12, StartStackPos ;rbp pos
                mov r11, (StartStackPos + X_Step) ;skip rbp and ip
                cmove r12, r11

                mov rax, [rbp + r12] ;argument value
                add r12, R_Step ;next elem

                jmp [.switch_table + rdx]

.switch_table:
                dq .case_b  ;98     0
                dq .case_c  ;99     1
                dq .case_d  ;100    2
                times 10 dq .default
                dq .case_o  ;111    13
                dq .case_p  ;112    14
                times 2 dq .default
                dq .case_s  ;115    16
                times 4 dq .default 
                dq .case_x  ;120    22

.case_c:             
                stosb 
                CHECK_BUFSIZE .next_parse
                jmp .next_parse     

.case_d:
                mov rdx, Temp_BufSize
                call check_buf
                call itoa ;put decimal value string in print_buf
                jmp .next_parse


.case_p:

.case_s:        
                push rsi ;save format_str ptr
                push rdi ;save print_buf addr

                mov rdi, rax ;rdi = string_ptr
                call my_strlen ;rax - len of string arg
                mov rsi, rdi ;string_ptr
                mov rcx, rax ;len to rcx
                pop rdi ;print_buf

                cmp rcx, Print_BufSize
                jb .skip_write_buf

                push rsi
                push rcx
                mov rdx, rdi
                sub rdx, Print_Buf
                PRINT_STR Print_Buf, rdx ;write to cmd_str and clear print_buf
                pop rcx
                pop rsi

                PRINT_STR rsi, rcx ;write str to cmd_str
                mov rdi, Print_Buf
                jmp .end_s

.skip_write_buf:
                rep movsb ;cpy len [rsi] -> [rdi]

.end_s:         pop rsi ;ret format str ptr
                jmp .next_parse

.default:
                jmp .next_parse

.case_b:
                mov r13, 0x01 ;bin mask
                mov cl, 0x01 ;bin offset
                mov bl, 'b'
                jmp .numsyst_conv

.case_o:        
                mov r13, 0x07 ;octo mask
                mov cl, 0x03 ;octo offset
                mov bl, 'o'
                jmp .numsyst_conv

.case_x:        
                mov r13, 0x0F ;hex mask
                mov cl, 0x04 ;hex offset
                mov bl, 'x'
                jmp .numsyst_conv

.numsyst_conv:
                push rcx
                mov rdx, Temp_BufSize
                call check_buf
                pop rcx

                mov r14, rax ;save arg
                mov al, '0'
                stosb
                mov al, bl
                stosb
                mov rax, r14
                call num_to_str
                jmp .next_parse


.exit:          
                add rsp, R_Step
                pop rax 
                pop rdi

                pop rsi 
                pop rdx
                pop rcx
                pop r8
                pop r9

                pop rbp
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
;Destroyed:     r10 - r14
;Expected:
;Comment:       r12 - current parsing argument
;ToDo: float, """"
;==========================================================================

;===================================num_to_str=============================
num_to_str:
                push rax 
                push rsi

                mov rdx, rax ;save rax
                mov r14, rdi ;save print_buf pos in r14
                mov rdi, Temp_Buf

.next_digit: 
                mov rax, rdx ;save in new rax
                and rax, r13 ;mask with numsyst base

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
                mov rdi, r14 ;return print_buf pos

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
;       r13 - numsyst base (that's degree of 2 and also a mask)
;       cl - numsyst offset (in degree of 2 positions)
;       rdi - printf_buf pos
;Exit:  rdi - buf pos
;Expected:
;Destroyed: rdx, r14, rcx
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
                lodsb ;[rsi] -> al
                cld
                stosb ;al -> [rdi]
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

;================================StrLen====================================
my_strlen:
                push rdi

                cld
                xor rcx, rcx
                dec rcx ;rcx = -1
                xor al, al ; al = null terminate
                repne scasb ;while al != [rdi]
                ;rcx = -len - 1
                ;rdi to null + 1

                xor rax, rax
                dec rax ;rax = -1
                sub rax, rcx

                pop rdi
                ret
;================================StrLen====================================
;Entry: rdi - str ptr
;Exit:  rax - len
;Expected:
;Destroyed: rax, rcx
;Comment: return len of string
;ToDo: \n 
;==========================================================================

;================================Check_Buf=================================
check_buf:  
                mov rcx, rdi
                sub rcx, Print_Buf ;num of writen symblols

                add rdx, rcx ;num of symbols that's should be writen in buf
                cmp rdx, Print_BufSize
                jb .exit

                push rsi ;save format_str ptr
                push rax ;save cur writing_arg

                PRINT_STR Print_Buf, rcx
                mov rdi, Print_Buf

                pop rax
                pop rsi

.exit:          
                ret
;================================Check_Buf=================================
;Entry: rdi - print_buf pos
;       rdx - num of characters, that we are preparing for write
;Exit:  rdi - new or prev print_buf pos 
;Expected:
;Destroyed: rcx rdx r8 - r11
;Comment: write print_buf to cmd str and clear print_buf 
;                         when overflow could be reached
;ToDo: 
;==========================================================================

;==============================Data========================================
section     .data  
Print_BufSize   equ 1024
Print_Buf       times Print_BufSize db 0
Temp_BufSize    equ 64 ;64 bin max size
Temp_Buf        times Temp_BufSize db 0
BaseElem        equ 98d
Temp_Char       db 0

R_Step          equ 8
X_Step          equ 16
R_ArgsPos       equ 0x00
StartStackPos    equ R_ArgsPos + 5 * 0x08 ;R argspos + 5 specificator R args