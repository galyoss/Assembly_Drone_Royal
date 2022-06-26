%macro func_start 0
    push ebp
    mov ebp, esp
%endmacro

%macro func_end 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

%macro printFloat 1
    pushad
    
    finit
    fld dword %1
    sub esp, 8
    fstp qword [esp]
    ffree
    
    push dword floatFormat
    call printf
    add esp, 12
    ; push dword [stdout]
    ; call fflush
    ; add esp, 4
    popad
%endmacro

%macro modulu 2
    mov eax, [%1]         
    xor edx, edx             
    mov ebx, [%2]            
    div ebx       ; edx = %1 mod %2
%endmacro

%macro my_print 1
    push %1
    call printf
    add esp, 4
%endmacro

%macro call_next_cors 1
            push ecx
            mov ecx,%1
            mov ebx, dword [cors]
            shl ecx,3
            add ebx,ecx
            pop ecx
            call resume
%endmacro


%macro mov_mem_to_mem_qwords 2
    push edx
    mov edx, dword [%2]
    mov dword [%1], edx
    mov edx, dword [%2+4]
    mov dword [%1+4], edx
    pop edx
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
    floatFormat: db "%.2f", 0
    MAX_DELTA_DEG_RANGE: equ 120
    MAX_DELTA_POS_RANGE: equ 10
    scaled_rnd_format: db "Scaled rnd with limit of %d, resuly is %d", 10, 0
    drone_info_line_format: db " %d, %.2f , %.2f , %.2f , %.2f",10,0 ;index, x, y, heading, speed, num of kills
    target_string_format: db "%.2f, %.2f", 10, 0                            ;x,y (for target)
    dummy_line: db "printing... %d", 10, 0
    test_print: db "test", 10, 0
    newLine: db 10, 0 ; '\n'
    separator: db "," , 0
    int_format: db "%d", 0


section .data
    

section .bss				
	float1:			resd 1
	float2:		resq 1
    
section .text
    extern Nval
    extern printf
    extern target_pointer
    extern num_of_drones_left
    extern sched_co_index
    extern DronesArrayPointer
    extern cors
    extern resume
    global run_printer


    run_printer:
        my_print string_run_printer
        finit
        inf_loop:
        mov ecx, [Nval]
        mov eax,dword [DronesArrayPointer]
        xor ebx,ebx
        
        printer_loop:
            cmp ebx,ecx
            je end_printer_loop

            pushad
            mov eax, [DronesArrayPointer]
            shl ebx, 2
            add eax, ebx
            shr ebx, 2
            mov eax, [eax]

            cmp byte [eax+DRONE_STRUCT_ACTIVE_OFFSET], 0
            je dont_print_drone

            ;format line: index (of drone), float(x), float(y), float(angle), float(speed), int(points)
            
            ;print the index
            push ebx
            push int_format
            call printf
            add esp, 8

            ; my_print separator
            ; printFloat [eax + DRONE_STRUCT_XPOS_OFFSET]
            ; my_print separator
            ; printFloat [eax + DRONE_STRUCT_YPOS_OFFSET]
            ; my_print separator
            ; printFloat [eax + DRONE_STRUCT_HEADING_OFFSET]
            ; my_print separator
            ; printFloat [eax + DRONE_STRUCT_SPEED_OFFSET]
            ; my_print separator
            
            push dword [eax+DRONE_STRUCT_KILLS_OFFSET]
            push int_format
            call printf
            add esp, 8

            my_print newLine

            dont_print_drone:
            popad
            
            inc ebx
            jmp printer_loop
        end_printer_loop:
        
        push test_print
        call printf
        add esp, 4
        break_here:
        call_next_cors dword [sched_co_index]      ;transfering control to scheduler after print
        
        push test_print
        call printf
        add esp, 4
        jmp inf_loop