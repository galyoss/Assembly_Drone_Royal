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

%macro my_print 1
    push %1
    call printf
    add esp, 4
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
    string_returning_to_sched: db "returning to sched", 10, 0
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
    string_run_printer: db "running printer", 10, 0
    string_printing_target: db "printing target", 10, 0
    string_printing_drones: db "printint drones", 10, 0
    MAX_DELTA_DEG_RANGE: equ 120
    MAX_DELTA_POS_RANGE: equ 10
    scaled_rnd_format: db "Scaled rnd with limit of %d, resuly is %d", 10, 0
    drone_info_line_format: db " %d, %.2f , %.2f , %.2f , %.2f , %d ",10,0 ;index, x, y, heading, speed, num of kills
    target_string_format: db "%.2f, %.2f", 10, 0                            ;x,y (for target)


section .data
    

section .bss				
	float1:			resd 1
	float2:		resq 1
    
section .text
    extern Nval
    extern printf
    extern target_pointer
    extern sched_co_index
    extern DronesArrayPointer
    extern cors
    extern resume
    global run_printer


    run_printer:
        finit
        my_print string_run_printer
        .loop:
            mov ecx,[Nval]
            mov eax,dword [DronesArrayPointer]
            xor ebx,ebx
        .print_target:
            pushad
            mov eax, [target_pointer]
            sub esp,8           ;make 8 bytes for target x in stack
            fld qword [eax+TARGET_STRUCT_XPOS_OFFSET]
            fstp qword [esp]

            sub esp,8             ;make 8 bytes for target y in stack
            fld qword [eax+TARGET_STRUCT_YPOS_OFFSET]
            fstp qword [esp]

            push target_string_format
            call printf
            add esp,16

        .printer_loop:
            cmp ebx,ecx
            je .end_printer_loop

            pushad
            lea eax,[eax+4*ebx]     
            mov eax,dword [eax]     ;calculate address of the i drone
            
            cmp byte [eax+DRONE_STRUCT_ACTIVE_OFFSET], 0
            je .skip_drone

            push dword [eax+DRONE_STRUCT_KILLS_OFFSET]

            sub esp,8
            fld qword [eax+DRONE_STRUCT_SPEED_OFFSET]
            fstp qword [esp]
            
            sub esp,8
            fld qword [eax+DRONE_STRUCT_HEADING_OFFSET]
            fstp qword [esp]

            sub esp,8
            fld qword [eax+DRONE_STRUCT_YPOS_OFFSET]
            fstp qword [esp]

            sub esp,8
            fld qword [eax+DRONE_STRUCT_XPOS_OFFSET]
            fstp qword [esp]
            
            push ebx

            push drone_info_line_format
            
            call printf
            add esp,45

            .skip_drone:
            popad
            
            inc ebx
            jmp .printer_loop
        .end_printer_loop:
        
            push ecx
            mov ecx, sched_co_index
            mov ebx, dword [cors]
            shl ecx,3
            add ebx,ecx
            pop ecx
            call resume


        jmp .loop