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

%macro print_float 1
	pushad
	mov [float1], %1
	fld dword [float1]
    fstp qword [float2]
	push dword [float2+4]  ;pushes 32 bits (MSB)
    push dword [float2]    ;pushes 32 bits (LSB)
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
    DroneStructLen: equ 37 ; 8xpox, 8ypos, 8angle, 8speed, 4kills, 1isActive
    DRONE_STRUCT_XPOS_OFFSET: equ 0
    DRONE_STRUCT_YPOS_OFFSET: equ 8
    DRONE_STRUCT_HEADING_OFFSET: equ 16
    DRONE_STRUCT_SPEED_OFFSET: equ 24
    DRONE_STRUCT_KILLS_OFFSET: equ 32
    DRONE_STRUCT_ACTIVE_OFFSET: equ 36
    DRONE_STRUCT_KILLS:
    TARGET_STRUCT_SIZE: equ 17
    TARGET_STRUCT_XPOS_OFFSET: equ 0
    TARGET_STRUCT_YPOS_OFFSET: equ 8
    TARGET_STRUCT_IS_DESTROYED_OFFSET: equ 16
    MAX_DEGREE: equ 360
    CO_STK_SIZE: equ 16384 ; 16*1024
    BIT_MASK_16: equ 1
    BIT_MASK_14: equ 4
    BIT_MASK_13: equ 8
    BIT_MASK_11: equ 32
    MAX_SEED: equ 65535
    MAX_SPEED: equ 50
    MAX_ANGLE_DELTA_LIM: equ 60
    MIN_ANGLE_DELTA_LIM: equ -60
    BOARD_SIZE: equ 100
    format_d:   db "%d", 0
    format_f:   db "%f", 0
    MAX_DELTA_DEG_RANGE: equ 120
    MAX_DELTA_POS_RANGE: equ 10
    scaled_rnd_format: db "Scaled rnd with limit of %d, resuly is %d", 10, 0

section .data
    

section .bss				
	float1:			resd 1
	float2:		resq 1
    
section .text
    extern Nval
    extern printf
    extern target_pointer
    extern DronesArrayPointer
    extern cors
    extern resume
    global run_printer


    run_printer:
        _print_target:
            mov edx, [target_pointer]
            print_float edx ;TODO, check if register is needed
            print_comma
            mov edx, 8
            print_float edx

        xor ecx, ecx
        _print_drones_loop:
            cmp ecx, [Nval]            ;while i < N
            je _return_to_printer
            ;mov ebx, [DronesArrayPointer] + ecx * 4]     ; ebx = drone[i] pointer
            mov ebx, [DronesArrayPointer]
            add ebx, ecx
            add ecx, 4                                     ; i++
            cmp byte[ebx+DRONE_STRUCT_ACTIVE_OFFSET], 0 ; drone.isAlive()
            je _print_drones_loop

            print_decimal ecx                           ; drone print index starts at 1
            print_comma
            print_float ebx       ; print ebx+0
            print_comma
            add ebx, 8
            print_float ebx         ;print ebx+8
            print_comma
            add ebx, 8             
            print_float ebx         ;print ebx+16
            print_comma
            add ebx, 8                
            print_float ebx          ;print ebx+24
            print_comma
            add ebx, 8
            print_decimal  [ebx]
            print_new_line

            jmp _print_drones_loop

        _return_to_printer:
            mov ebx, [cors]     ; ebx = scheduler*
            call resume