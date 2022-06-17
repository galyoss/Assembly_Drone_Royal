%macro func_start 0
    push ebp
    mov ebp, esp
%endmacro

%macro func_end 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

%macro modulu 2
    mov eax, [%1]         
    xor edx, edx             
    mov ebx, [%2]            
    div ebx       ; edx = %1 mod %2
%endmacro

;%1 = pointer to float to print    (TODO check if %1 + 4 is valid command)
%macro print_float_2d 1
	pushad
    mov ebx, %1
	push dword [ebx]    ;pushes 32 bits (MSB)
    push dword [ebx+4]   ;pushes 32 bits (LSB)
	push float_format
	call printf
	add esp, 12
	popad
%endmacro

;%1 = int to print
%macro  print_decimal 1
    pushad
    push dword %1
    push decimal_format
    call printf
    add esp, 8
    popad
%endmacro

%macro  print_comma 0
    pushad
    push comma_format
    call printf
    add esp, 4
    popad
%endmacro

%macro print_new_line 0
    pushad
    push new_line_format
    call printf
    add esp, 4
    popad
%endmacro

section	.rodata
    ; formats
	string_format: db "%s", 10, 0			
	decimal_format: db "%d", 0  			
	float_format: db "%.2f", 0 			    ;2digit precision
    new_line_format: db 10, 0
    comma_format: db ",", 0
section .data
    

section .bss
    
section .text
    extern Nval
    extern printf
    global run_printer


    run_printer:
        _print_target:
            print_float_2d [target_pointer + TARGET_STRUCT_XPOS_OFFSET] ;TODO, check if register is needed
            print_comma
            print_float_2d [target_pointer + TARGET_STRUCT_YPOS_OFFSET]

        xor ecx, ecx
        _print_drones_loop:
            cmp ecx, [Nval]            ;while i < N
            je _return_to_printer
            mov ebx, [DronesArrayPointer + ecx * 4]     ; ebx = drone[i] pointer
            inc ecx                                     ; i++
            cmp byte[ebx+DRONE_STRUCT_ACTIVE_OFFSET], 0 ; drone.isAlive()
            je _print_drones_loop

            print_decimal ecx                           ; drone print index starts at 1
            print_comma
            print_float_2d qword[ebx+DRONE_STRUCT_XPOS_OFFSET]       ; TODO check if need qword or register
            print_comma
            print_float_2d qword[ebx+DRONE_STRUCT_YPOS_OFFSET]
            print_comma
            print_float_2d qword[ebx+DRONE_STRUCT_SPEED_OFFSET]
            print_comma
            print_float_2d qword[ebx+DRONE_STRUCT_HEADING_OFFSET]
            print_comma
            print_decimal  qword[ebx+DRONE_STRUCT_KILLS_OFFSET]
            print_new_line

            jmp _print_drones_loop

        _return_to_printer:
            mov ebx, [cors]     ; ebx = scheduler*
            call resume