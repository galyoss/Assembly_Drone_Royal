;; init drone locations
;; init target
;;

;;TODO SATURDAY:
    ; finish random functions (move drone, calc angle, calc angle delta...)
    ; decide on CORS structs
    ; parse input
    ;  gal maybe geh -> maybe debug prints
    ; if god helps us work fast DO SCHEDUeler

; מי שמאמין לא מתעד
%macro func_start 0
    push ebp
    mov ebp, esp
%endmacro

%macro print_debug_rnd_num 0
    cmp Debug, 1
    jne end_debug_print
    push rnd_num_format
    push [seed]
    call printf
    add esp, 4
    %%end_debug_print:
%endmacro

%macro print_debug_scaled_rnd 0
    cmp Debug, 1
    jne end_debug_print
    push scaled_rnd_format
    push [VarA]
    push [ebp+8]
    call printf
    add esp, 8
%endmacro

; מי שמאמין לא מתעד
%macro func_end 0
    mov esp, ebp
    pop ebp
    ret
%endmacro


section .rodata:
    DroneStructLen: equ 33 ; 8xpox, 8ypos, 8angle, 8speed, 1isActive
    CO_STK_SIZE: equ 16384 ; 16*1024
    BIT_MASK_16: equ 1
    BIT_MASK_14: equ 4
    BIT_MASK_13: equ 8
    BIT_MASK_11: equ 32
    MAX_SEED: equ 65535
    MAX_ANGLE_DELTA_LIM: equ 60
    MIN_ANGLE_DELTA_LIM: equ -60
    BOARD_SIZE: equ 100

section .data:
    ;; init all "board" related vars: dronesArray, game params, target
    ;; game initializtion: init schedueler, printer, terget
    ;; defining utility functions: random, rad->deg, ged->rad,
    
    N : dd 0
    R : dd 0
    T : dd 0
    DronesArrayPointer: dd 0
    target_pointer: dd 0
    currAngleDeg: dq 0
    currAngleRad: dq 0
    Gamma: dq 0
    varA: dq 0
    varB: dq 0
    cors: dd 0
    seed: dw 0

section .text:

;; should get lower, upper bound, return a random between them
generate_random_number:
    func_start                                               ; of random number
    pushad
    xor eax, eax
    xor ebx, ebx
    xor ecx,ecx
    mov ax, word[seed]
    calc_random:
        cmp ecx, 16
        je end_calc_random
        mov bx, BIT_MASK_16
        and bx, ax
        shl bx, 2
        mov dx, BIT_MASK_14
        and dx, ax
        xor bx, dx          ; now bx holds the result of 14bit xor 16bit in the 14th bit
        
        shl bx, 1
        mov dx, BIT_MASK_13
        and dx, ax
        xor bx, dx         ; now bx holds the result of 16bit xor 14bit xor 13bit in the 13th bit  

        shl bx, 2
        mov dx, BIT_MASK_11
        and dx, ax
        xor bx, dx         ; now bx holds the result of 16bit xor 14bit xor 13bit xor 11bit in the 11th bit

        shl bx, 10
        shr ax, 1           ;ax first bit is now 0
        or ax, bx           ;ax first bit is the xors result

        inc ecx
        jmp calc_random
    end_calc_random:
    print_debug_rnd_num
     
    mov word[seed], ax      ;seed is now the new random number
    func_end


get_random_scaled_number: ;(int limit) -> VarA = scaled float
    func_start
    
    call generate_random_number     ;now ax and seed hold random short

    ffree
    mov dword[varA], 0                   ; clean varA
    mov word[varA], ax              ; varA = random short
    fld dword[varA]                 ; push varA

    mov dword[varB], MAX_SEED
    fdiv dword[varB]                 ;now float stack top is a number (0,1];

    mov eax, dword[ebp+8]              ;eax holds limit
    mov dword [VarB], eax
    fimul dword[VarB]                ;now top of stack is the random dist

    mov dword[varA], 0
    fstp dword[varA]                 ;VarA now holds the position
    print_debug_scaled_rnd
    func_end


place_target:
    func_start
    push BOARD_SIZE
    call get_random_scaled_number
    ; target.xPOS = VarA
    call get_random_scaled_number
    ; target.yPOS = VarA
    add esp, 4
    print_debug_target_place [target_pointer+xposOffset] [target_pointer+yposOffset]
    func_end


convert_deg_to_rad:
    func_start
    finit 
    fld qword [currAngleDeg]
    mov [varA], dword 0 ; TODO maybe delete?
    mov [varA], dword 180
    fild dword [varA]
    fdiv
    fldpi
    fmul
    fstp qword [currAngleRad]
    func_end
    
; specific to gamma
convert_rad_to_deg:
    func_start
    finit 
    fld qword [Gamma]
    fldpi
    fdiv
    mov [varA], dword 0
    mov [varA], dword 180
    fild dword [varA]
    fmul
    fstp qword [Gamma]
    func_end

calc_delta_x:
    

calc_delta_y:


initDronesArray:
    ;; calloc array, with N cells each 4bytes
    ;; set DronesArrayPointer to the return val of calloc
    ;; for each call in array, create a new drone, 
    ;; Struct drone: 8 bytes Xpos, 8 bytes Ypos, 8 bytes Angle, 8 byte speed, byte isActive

    func_start
    push [N]
    push 4
    call calloc
    add esp, 8
    ;now eax holds array start pointer
    mov dword [DronesArrayPointer], eax
    ;looping:
    mov ebx, 0
    initiating_drone:
        cmp ebx, dword [N]
        je end_init_drones_loop
        push 1
        push DroneStructLen
        call calloc
        add esp, 8
        mov dword [DronesArrayPointer+ebx*4], eax
        push eax
        call init_drone_sturct ; init inside all values of this drone
        add esp, 4
        inc ebx
        jmp initiating_drone

    je end_init_drones_loop:
        func_end


init_co_routines:
    func_start
    mov eax, 0
    mov eax, 3
    add eax, [N]
    ; eax hold num of required cors - printer, scheder, target, N drones
    push eax
    push 8 ; TODO - does the order matter?
    call calloc
    add esp, 8
    mov dword [cors], eax
    init_sched_cor:
    mov dword [cors], run_schedueler
    push 1
    push CO_STK_SIZE
    call calloc
    add esp, 8
    mov dword [cors+4], eax

    init_target_cor:
    mov dword [cors+8], run_target
    push 1
    push CO_STK_SIZE
    call calloc
    add esp, 8
    mov dword [cors+12], eax

    init_printer_cor:
    mov dword [cors+16], run_printer
    push 1
    push CO_STK_SIZE
    call calloc
    add esp, 8
    mov dword [cors+20], eax

    init_drones_cors:
    mov ebx, 3 ; our loop counter (cmp ebx with [N]+3)
    drones_cors_init_loop:
    cmp ebx, [N]+3 ; if not working, move [N]+3 into register 
    je end_drones_cors_init_loop
    mov dword [cors+ebx*8], run_drone
    push 1
    push CO_STK_SIZE
    call calloc
    add esp, 8
    mov dword [cors+ebx*8+4], eax
    jmp drones_cors_init_loop


init_drone_sturct:

    