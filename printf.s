;:=========================================================================
;: 0-Linux-nasm-64.s                   (c)Matt,2026
;:=========================================================================

; nasm -f elf64 -l printf.lst printf.s ;  ld -s -o printf printf.o
; nasm -f elf64 -g printf.s -o printf.o ; gcc -no-pie -Wl,--as-needed printf.o -o printf
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

%macro GET_POW2BASE 3 
        mov r13, %1 ;mask
        mov cl, %2  ;offset
        mov dl, %3  ;spec_sym
        jmp .numsyst_conv
%endmacro

%macro GET_ARG 1
        mov rax, [rbp + r12] ;argument value
        add r12, %1 ;elem size step
%endmacro

%macro GET_X_ARG 1 ;!fix
        movdqu xmm0, [rbp + r15] ;argument value
        add r15, %1 ;elem size step
%endmacro

%macro PUSH_ALL_XMM 0
    sub rsp, X_ArgsSize ; 8 * 16 = 128 byte
    movdqu [rsp], xmm0 ;rbp + 8 (allign with rdi) + 128
    movdqu [rsp+16], xmm1
    movdqu [rsp+32], xmm2
    movdqu [rsp+48], xmm3
    movdqu [rsp+64], xmm4
    movdqu [rsp+80], xmm5
    movdqu [rsp+96], xmm6
    movdqu [rsp+112], xmm7
%endmacro

%macro POP_ALL_XMM 0
    movdqu xmm0, [rsp]
    movdqu xmm1, [rsp+16]
    movdqu xmm2, [rsp+32]
    movdqu xmm3, [rsp+48]
    movdqu xmm4, [rsp+64]
    movdqu xmm5, [rsp+80]
    movdqu xmm6, [rsp+96]
    movdqu xmm7, [rsp+112]
    add rsp, X_ArgsSize
%endmacro

;==========================================================================
global my_printf
extern printf
;==========================================================================

;==========================================================================
section         .text
;==========================================================================

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

                PUSH_ALL_XMM
                push rax ;save nfloats

                push rbx
                push r12
                push r13
                push r14
                push r15 ;callee saved

                mov r12, R_ArgsPos ; start_pos of arg counter NOT CHANGE
                mov r15, X_ArgsPos
                mov rsi, rdi ; format str ONLY
                mov rdi, Print_Buf ;print_buf pos
                xor rbx, rbx ;parsed float args counter = 0

    .next_parse: 
                lodsb ;[rsi] -> al
                cmp al, NullTrm
                je .print_buf

                cmp al, FormatSpec
                je .spec
        .continue:      
                stosb ; al -> [rdi]
                CHECK_BUFSIZE .next_parse
                jmp .next_parse

        .print_buf:   ;syscall and write print_buf to cmd_str  
                mov rcx, rdi
                sub rcx, Print_Buf
                PRINT_STR Print_Buf, rcx
                jmp .exit

        .spec:
                lodsb ;al - specifier
                cmp al, FormatSpec
                je .continue

                movzx rax, al ;clear rax except al
                sub al, BaseElem ;get jump table offset
                shl rax, 3 ;al * 8 byte addreses
                mov rdx, rax

                mov r11, (StartStackPos + X_Step) ;skip rbp and ip
                cmp r12, StartStackPos ;rbp pos
                cmove r12, r11

                jmp [.switch_table + rdx]

    .switch_table:
                dq .case_b  ;98     0
                dq .case_c  ;99     1
                dq .case_d  ;100    2
                dq .default
                dq .case_f  ;102    4
                times 8 dq .default
                dq .case_o  ;111    13
                dq .case_p  ;112    14
                times 2 dq .default
                dq .case_s  ;115    16
                times 4 dq .default 
                dq .case_x  ;120    22

        .case_c:         
                GET_ARG R_Step   
                stosb 
                CHECK_BUFSIZE .next_parse
                jmp .next_parse     

        .case_d:
                GET_ARG R_Step       
                mov rdx, Temp_BufSize
                call check_buf
                call itoa ;put decimal value string in print_buf
                jmp .next_parse

        .case_f:

                inc rbx
                cmp rbx, N_X_notStk_Args
                cmova r15, r12
                ja .incstkpos
            .get_float_arg:
                GET_X_ARG X_Step
                call ftoa
                jmp .next_parse

            .incstkpos:
                add r12, X_Step
                jmp .get_float_arg

        .case_p: 
                jmp .case_x

        .case_s:        
                GET_ARG R_Step 
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

            .end_s:         
                pop rsi ;ret format str ptr
                jmp .next_parse


        .case_b:
                GET_ARG R_Step 
                GET_POW2BASE 0x01, 0x01, 'b'
                jmp .numsyst_conv

        .case_o:
                GET_ARG R_Step         
                GET_POW2BASE 0x07, 0x03, 'o'
                jmp .numsyst_conv

        .case_x:  
                GET_ARG R_Step 
                GET_POW2BASE 0x0F, 0x04, 'x'      
                jmp .numsyst_conv

            .numsyst_conv: ;converting to cur num system
                push rcx
                push rdx
                mov rdx, Temp_BufSize
                call check_buf
                pop rdx
                pop rcx

                mov r14, rax ;save arg
                mov al, '0'
                stosb
                mov al, dl
                stosb
                mov rax, r14
                call num_to_str

                jmp .next_parse

        .default:
                jmp .next_parse

    .exit:      
                ; mov rdi, DebugFormat
                ; mov rsi, DebugStr
                ; xor rax, rax
                ; call printf

                pop r15
                pop r14
                pop r13 
                pop r12
                pop rbx  ;callee saved

                pop rax 
                POP_ALL_XMM

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
;Comment:       during the execution of printf
;               r12 - current stack R arg position NOT TOUCH!
;               r15 - current stack X arg pos NOT TOUCH!
;               rbx - float arg counter NOT TOUCH!
;               rdi - print_buf addr
;               rsi - format str addr
;ToDo: float, """", \n
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
        .back:          
                stosb ;temp_buf

                shr rdx, cl ;next digit

                test rdx, rdx 
                jz .exit ;don't check insign zeros
                jmp .next_digit

        .get_letter:   
                add rax, ('A' - 0x0A) ;10-15 to A-F
                jmp .back

    .exit:          
                mov rsi, rdi ;cur Temp_Buf pos
                mov rdi, r14 ;return print_buf pos

                mov rcx, rsi
                sub rcx, Temp_Buf ; get_len
                dec rsi

        .next_cpy:            
                std
                lodsb
                cld
                stosb
                loop .next_cpy 

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

                mov r13, 10 ;decimal
                mov rsi, Temp_Buf

                cmp rax, 0x00 ;set SF
                jns .next_digit

                mov dl, '-'
                mov [rdi], dl ; - to print_buf
                inc rdi
                not rax
                inc rax

    .next_digit:    
                xor rdx, rdx
                div r13 ;rax /= 10 rdx - left
                add dl, '0'
                mov [rsi], dl
                inc rsi

                test rax, rax
                jnz .next_digit

                mov rcx, rsi
                sub rcx, Temp_Buf ; get_len
                dec rsi
                
    .next_cpy:            
                std
                lodsb ;[rsi] -> al
                cld
                stosb ;al -> [rdi]
                loop .next_cpy          

    .exit:          
                pop rsi 
                pop rax

                ret
;===================================Itoa===================================
;Entry: rax - value
;       rsi - format str pos, 
;       rdi - print_buf pos
;Exit:  rdi - cur print_buf pos
;Expected:
;Destroyed: r13, rdx, rcx
;Comment: convert int to string
;ToDo:
;==========================================================================

;===================================Ftoa===================================
ftoa:  
                mov eax, DecNum
                cvtsi2ss xmm3, eax ;10.0


                movd eax, xmm0
                test eax, [Sign_Mask] ;float signmask
                jz .positive

                xorps xmm1, xmm1          ; xmm1 = 0.0
                subss xmm1, xmm0          ; xmm1 = -xmm0
                movss xmm0, xmm1
                mov al, '-'
                stosb
    .positive:
                movss xmm4, [epsilon]
                addss xmm0, xmm4
                movss xmm2, xmm0 
                cvttss2si rax, xmm0 ; eax integer part

                call itoa ;write integer part

                cvtsi2ss xmm1, rax
                movss xmm0, xmm2
                subss xmm0, xmm1 ;kill iteger part
                mov al, '.'
                stosb

                mov rcx, Precision

    .next_digit:
                mulss xmm0, xmm3    ;xmm0 *= 10.0
                movss xmm2, xmm0  ;save xmm0
                cvttss2si rax, xmm0  
                
                mov rdx, rax
                add al, '0'
                stosb
                mov rax, rdx
                
                cvtsi2ss xmm1, rax
                movss xmm0, xmm2
                subss xmm0, xmm1
    
                loop .next_digit
                
    .exit:          
                ret
;===================================Ftoa===================================
;Entry: xmm0 - value
;       rsi - format str pos, 
;       rdi - print_buf pos
;Exit:  rdi - cur print_buf pos
;Expected:
;Destroyed:
;Comment: convert float to string
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
section         .data  
Print_BufSize   equ 1024
Print_Buf       times Print_BufSize db 0
Temp_BufSize    equ 66 ;64 bin max size plus prefix 0x 0b 0o
Temp_Buf        times Temp_BufSize db 0
BaseElem        equ 98d

R_Step          equ 8 ;regs stack ofs
X_Step          equ 16 ;xmm stack ofs
R_ArgsPos       equ 0
X_ArgsPos       equ  0 - 8 - X_ArgsSize
Parsed_X_Args   dq 0
N_X_notStk_Args     equ 8
X_ArgsSize      equ 16 * 8 ;8 xmm regs in stack
StartStackPos   equ R_ArgsPos + 5 * 0x08 ;R argspos + 5 specificator R args
NullTrm         equ 0x00
FormatSpec      equ '%'
Precision       equ 3
Sign_Mask       dd 0x80000000
DecNum          equ 10
epsilon         dd 0.00005
DebugFormat:    db 0x0a, "Debug format for printf called from %s %%", 0x0a, 0
DebugStr:       db "my_printf.s", 0