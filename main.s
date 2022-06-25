;; init drone locations
;; init target
;;TODO SATURDAY:
    ; finish random functions (move drone, calc angle, calc angle delta...)
    ; decide on CORS structs
    ; parse input
    ;  gal maybe geh -> maybe debug prints

;;TODO NEXT TIME ON DRAGON BALL Z:
    ; resume + do resume
    ; drone functionality: may destroy, move
    ;print pasha is geh with cors
; מי שמאמין לא מתעד
%macro func_start 0
    push ebp
    mov ebp, esp
%endmacro

%macro mov_mem_to_mem_qwords 2
    push edx
    finit
    fld [%2]
    fstp %1
    pop edx
%endmacro

%macro my_malloc 1
        push edx
        push ebx
        push ecx
        push dword %1
        call malloc
        add esp,4
        pop ecx
        pop ebx
        pop edx
    %endmacro


%macro  parseArgInto 2
    pushad
    push    %1
    push    %2
    push    dword[ebx]
    call    sscanf
    add     esp, 12
    popad
    add     ebx, 4
%endmacro

; מי שמאמין לא מתעד
%macro func_end 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

section .bss
    CURR: resd 1    ;curr co routine
    SPT: resd 1     ;curr stack pointer
    SPMAIN: resd 1  ;main stack pointer

section .rodata
    STKSIZE: equ 16*1024
    CODEP: equ 0; offset of pointer to co-routine function in co-routine struct 
    SPP: equ 4; offset of pointer to co-routine stack in co-routine struct
    DroneStructLen: equ 37 ; 8xpox, 8ypos, 8angle, 8speed, 4kills, 1isActive
    DRONE_STRUCT_XPOS_OFFSET: equ 0
    DRONE_STRUCT_YPOS_OFFSET: equ 8
    DRONE_STRUCT_HEADING_OFFSET: equ 16
    DRONE_STRUCT_SPEED_OFFSET: equ 24
    DRONE_STRUCT_KILLS_OFFSET: equ 32
    DRONE_STRUCT_ACTIVE_OFFSET: equ 36
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
    ;; init all "board" related vars: dronesArray, game params, target
    ;; game initializtion: init schedueler, printer, terget
    ;; defining utility functions: random, rad->deg, ged->rad,
    extern calloc
    extern printf
    extern malloc
    extern run_printer
    extern run_target
    extern run_drone
    extern run_schedueler
    global resume
    global do_resume
    global move_drone
    global move_target
    global update_drone_deg
    global create_target
    global mayDestroy
    global Nval
    global Rval
    global Tval
    global Dval
    global Kval
    global DronesArrayPointer
    global currDrone
    global target_pointer
    global printer_co_index
    global sched_co_index
    global target_co_index
    global cors
    global varA
    global varB
    global Debug
    global main
    extern printf
    extern sscanf

    Nval : dd 0
    Rval : dd 0
    Tval : dd 0
    Kval: dd 0
    Dval : dd 0
    DronesArrayPointer: dd 0
    currDrone: dd 0
    target_pointer: dd 0
    currAngleDeg: dq 0
    currAngleRad: dq 0
    Gamma: dq 0
    varA: dq 0
    varB: dq 0
    num_of_cors: dd 0
    sched_co_index: dd 0
    target_co_index: dd 0
    printer_co_index: dd 0
    cors: dd 0
    seed: dw 0
    Debug: db 1

section .text

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
    mov word[seed], ax      ;seed is now the new random number
    func_end


get_random_scaled_number: ;(int limit) -> varA = scaled float
    func_start
    call generate_random_number     ;now ax and seed hold random short
    ffree
	mov ax, [seed]
	ffree
	mov dword [varA], 0
	mov [varA], ax
	fld dword [varA]			; load x
	
	mov dword [varB], 65535		; MAXSHORT
	fdiv dword [varB]			; getting x / MAXSHORT
	
	mov eax, [ebp+8]
	mov dword [varA], eax		; range
	fimul dword [varA]			; (x / MAXINT) * 100
	
	mov dword [varA], 0
	fstp dword [varA]			; var1 hold the ans
    func_end

generate_random_deg: ; initial degree, 0-360
    ; func ()-> random float between 0-360, in varA
    func_start
    pushad
    push dword MAX_DEGREE
    call get_random_scaled_number
    ;now varA holds a random between 0-MAX_DEGREE
    add esp, 4
    popad
    func_end


generate_random_delta_deg: ;delta degree, (-60)-(60)
    func_start
    pushad
    push dword [MAX_DELTA_DEG_RANGE] ; ==120
    call get_random_scaled_number
    add esp, 4    
    popad
    ffree
    fld qword [varA]
    mov dword [varB], 60
    fisub dword [varB]
    fstp qword [varA]
    func_end


generate_random_delta_xy: ; delta dict, (-10)-(10)
    func_start
    pushad
    push dword MAX_DELTA_POS_RANGE ; ==20
    call get_random_scaled_number
    add esp, 4
    popad
    ffree
    fld qword [varA]
    mov dword [varB], 10
    fisub dword [varB]
    fstp qword [varA]
    func_end
    
generate_random_position:
    ; func ()-> random float between 0-360, in varA
    func_start
    pushad
    push dword BOARD_SIZE ;==100
    call get_random_scaled_number
    ;now varA holds a random between 0-MAX_POS
    add esp, 4
    popad
    func_end

generate_random_speed:
    ; func ()-> random float between 0-360, in varA
    func_start
    pushad
    push dword MAX_SPEED ;==50
    call get_random_scaled_number
    ;now varA holds a random between 0-MAX_POS
    add esp, 4
    popad
    func_end


convert_deg_to_rad:
    ; func(angle in deg(in currAngleDeg)) -> AngleinRad(in currAngleRad)
    func_start
    finit 
    fld qword [currAngleDeg]
    mov [varA], dword 0 ; TODO remove?
    mov [varA], dword 180
    fild dword [varA]
    fdiv
    fldpi
    fmul
    fstp qword [currAngleRad]
    func_end
    
; ; TODO: maybe not necassary?
; convert_rad_to_deg:
;     func_start
;     finit 
;     fld qword [Gamma]
;     fldpi
;     fdiv
;     mov [varA], dword 0
;     mov [varA], dword 180
;     fild dword [varA]
;     fmul
;     fstp qword [Gamma]
;     func_end

calc_delta_x:
    ; README: before calling this func, drone must put it's speed in varA, heading angle in currAngleDeg
    ; func (speed[varA], angle in degrees[currAngleDeg]) -> deltaX[varA]
    func_start
    finit
    call convert_deg_to_rad
    fld qword [currAngleRad]
    fcos
    fld qword [varA]
    fmul
    fstp qword [varA]
    func_end


calc_delta_y:
    ; README: before calling this func, drone must put it's speed in varA, heading angle in currAngleDeg
    ; func (speed[varA], angle in degrees[currAngleDeg]) -> deltaX[varA]
    func_start
    finit
    call convert_deg_to_rad
    fld qword [currAngleRad]
    fsin
    fld qword [varA]
    fmul
    fstp qword [varA]
    func_end


initDronesArray:
    ;; calloc array, with N cells each 4bytes
    ;; set DronesArrayPointer to the return val of calloc
    ;; for each call in array, create a new drone, 
    ;; Struct drone: 8 bytes Xpos, 8 bytes Ypos, 8 bytes Angle, 8 byte speed, byte isActive

    func_start
    push dword [Nval]
    push 4
    call calloc
    add esp, 8
    ;now eax holds array start pointer
    mov dword [DronesArrayPointer], eax
    ;looping:
    mov ebx, 0
    initiating_drone:
        cmp ebx, dword [Nval]
        je end_init_drones_loop
        push 1
        push DroneStructLen
        call calloc
        add esp, 8
        mov edx, [DronesArrayPointer]
        shl ebx, 2
        add edx, ebx
        shr ebx, 2
        mov dword [edx], eax
        pushad
        push eax
        call init_drone_sturct ; init inside all values of this drone
        add esp, 4
        popad
        inc ebx
        jmp initiating_drone

    end_init_drones_loop:
        func_end

init_drone_sturct:
; void func (drone* in ebp+8)
    func_start
    mov ebx, [ebp+8]
    ;now ebx holds pointer to the desired drone
    call generate_random_position
    mov_mem_to_mem_qwords ebx+DRONE_STRUCT_XPOS_OFFSET, varA ; TODO: figure how to load 8 bytes to another address in memory
    call generate_random_position
    mov_mem_to_mem_qwords ebx+DRONE_STRUCT_YPOS_OFFSET, varA
    call generate_random_deg
    mov_mem_to_mem_qwords ebx+DRONE_STRUCT_HEADING_OFFSET, varA
    call generate_random_speed
    mov_mem_to_mem_qwords ebx+DRONE_STRUCT_SPEED_OFFSET, varA
    mov dword [ebx+DRONE_STRUCT_KILLS_OFFSET], 0
    mov byte [ebx+DRONE_STRUCT_ACTIVE_OFFSET], 1
    func_end

init_target:
; void func (target* in ebp+8)
    func_start
    push TARGET_STRUCT_SIZE
    push 1
    call calloc
    add esp, 8
    ; now eax holds the pointer
    mov dword [target_pointer], eax
    call create_target
    func_end

    
create_target:
    ; void func (), updated target_pointer->xpos=rnd, target_pointer->ypos=rnd, target_pointer->isdestroyed=0
    func_start
    call generate_random_position
    mov esi, [target_pointer]
    mov_mem_to_mem_qwords esi+TARGET_STRUCT_XPOS_OFFSET, varA
    call generate_random_position
    mov_mem_to_mem_qwords esi+TARGET_STRUCT_YPOS_OFFSET, varA
    mov byte [esi+TARGET_STRUCT_IS_DESTROYED_OFFSET], 0
    func_end

move_target:
    func_start
    call generate_random_delta_xy       ;now var A hold delta x 
    ffree

    ;moving x location
    fld qword [varA]
    fadd qword [target_pointer+TARGET_STRUCT_XPOS_OFFSET]
    fstp qword [varA]
    push dword BOARD_SIZE                      ; pushing board limits
    call wrap              ; now var A hold wrap x
    mov_mem_to_mem_qwords target_pointer+TARGET_STRUCT_XPOS_OFFSET, varA    ;TODO see if this works

    ;moving y location
    fld qword [varA]
    fadd qword [target_pointer+TARGET_STRUCT_YPOS_OFFSET]
    fstp qword [varA]
    push dword BOARD_SIZE                      ; pushing board limits
    call wrap              ; now var A hold wrap y
    mov_mem_to_mem_qwords target_pointer+TARGET_STRUCT_YPOS_OFFSET, varA    ;TODO see if this works

    func_end

update_drone_deg: ;(drone * ) -> null, update drone deg
    func_start
    call generate_random_delta_deg  ;now varA hold delta deg
    mov ebx, [ebp+8]                ;ebx = drone *
    ffree
    ;changing deg
    fld qword [varA]
    fadd qword [ebx + DRONE_STRUCT_HEADING_OFFSET]
    fstp qword [varA]
    push dword MAX_DEGREE                      ; pushing board limits
    call wrap                             ; now var A hold wrap x
    mov_mem_to_mem_qwords ebx+DRONE_STRUCT_HEADING_OFFSET, varA  ;TODO see if this works

    func_end

move_drone:
    ;void func (current drone)
    ;This func moves the drone's XY:

    func_start
    mov_mem_to_mem_qwords currAngleDeg, currDrone+DRONE_STRUCT_HEADING_OFFSET
    mov_mem_to_mem_qwords varA, currDrone+DRONE_STRUCT_SPEED_OFFSET
    call calc_delta_x
    ffree
    fld qword [varA] ; loading the delta
    fld qword [currDrone+DRONE_STRUCT_XPOS_OFFSET]
    fadd
    fstp qword [varA]
    push BOARD_SIZE ;TODO word?
    call wrap
    add esp, 4
    mov_mem_to_mem_qwords currDrone+DRONE_STRUCT_XPOS_OFFSET, varA
    call calc_delta_y
    ffree
    fld qword [varA] ; loading the delta
    fld qword [currDrone+DRONE_STRUCT_YPOS_OFFSET]
    fadd
    fstp qword [varA]
    push BOARD_SIZE ;TODO word?
    call wrap
    add esp, 4
    mov_mem_to_mem_qwords currDrone+DRONE_STRUCT_YPOS_OFFSET, varA
    func_end


wrap:
    ; func (limit): if varA-limit >= 0, set varA = varA-limit. if varA < 0, set varA = varA + limit.
    func_start
    ffree
    fld qword [varA]
    fld dword [ebp+8]
    fcomip
    jb skip_subtruct_limit
    subtruct_limit:
    fisub dword [ebp+8]
    skip_subtruct_limit:
    ; now [floating stack head (our varA)] is < limit, now we need to check if it's negative and fix
    fldz
    fcomip
    jae skip_add_limit
    fld dword [ebp+8]
    fadd
    skip_add_limit:
    ; now the number is normalized, return it to varA
    fstp qword [varA]
    func_end

mayDestroy:
    ; func(drone[currDrone], target[target_pointer])->bool[eax]
    func_start
	mov eax,0                           ;eax will hold the result

	; we need to calculate:
	; distance = sqrt((target_x-drone_x)^2 + (target_y-drone_y)^2)
	ffree
	fld qword [currDrone+DRONE_STRUCT_XPOS_OFFSET]
	fsub qword [target_pointer+TARGET_STRUCT_XPOS_OFFSET]
	fst st1     ;it duplicates the number
	fmulp
	fstp qword [varA]					; var1 = (target_x - drone_x)^2
    ;floats stack is empty now
	fld qword [target_pointer+TARGET_STRUCT_YPOS_OFFSET]
	fsub qword [currDrone+DRONE_STRUCT_YPOS_OFFSET]
	fst st1     ;it duplicates the number
	fmulp								; stack = (target_y - drone_y)^2
	fadd qword [varA]					; stack = (target_y - drone_y)^2 + (target_x - drone_x)^2
	fsqrt

	; compare distance with dval and return true or false accordingly
	fsub dword [Dval]					; stack = distance - D
	fldz                                ; load 0 to the stack
	fcomip								; if (stack <= 0)
	jae return_true
	; else - return_false
	popad
	mov eax, 0							; false == 0
	mov esp, ebp
	pop ebp
	ret
	return_true:
		popad
		mov eax, 1							; true == 1
		mov esp, ebp
		pop ebp
		ret

allocate_cors:
        func_start
        mov edx,dword [Nval]            ;set edx with num of drones 
        add edx, 3                      ;add to edx num of 3 additional cors (print, sched, target)
        shl edx,3                       ;mult by 8, size of each cors struct size
        my_malloc edx
        mov dword [cors],eax ;moving pointer to allocated array into the CORS label
        pushad
        mov ebx,dword [cors]
        mov edx, [Nval]
        xor ecx,ecx
        .drone_cors_loop:
            cmp ecx,edx
            je .end_drone_cors_loop
            
            mov dword [ebx+CODEP+8*ecx], run_drone
            
            my_malloc STKSIZE
            add eax,STKSIZE
            
            mov dword [ebx+SPP+8*ecx],eax
            inc ecx
            jmp .drone_cors_loop
        .end_drone_cors_loop:
        
        ;allocating correct pointers and stack for scheduler and target and print cors
        popad
        mov ebx, [cors]
        mov edx,dword [Nval]
        add edx, 3          ;edx = num of cors in total
        dec edx             ;go to the last 'index' in cors array
        mov dword [sched_co_index], edx
        mov dword [ebx+8*edx],run_schedueler
        my_malloc STKSIZE
        add eax,STKSIZE
        mov dword [ebx+4+8*edx],eax
        
        dec edx
        mov dword [printer_co_index], edx
        mov dword [ebx+8*edx],run_printer
        my_malloc STKSIZE
        add eax,STKSIZE
        mov dword [ebx+4+8*edx],eax
        
        dec edx
        mov dword [target_co_index],edx
        mov dword [ebx+8*edx],run_target
        my_malloc STKSIZE
        add eax,STKSIZE
        mov dword [ebx+4+8*edx],eax
        func_end
; EBX is pointer to co-init structure of co-routine to be resumed
; CURR holds a pointer to co-init structure of the curent co-routine


 initCo:
        func_start
        
        mov ebx,[ebp+8]
        mov ecx , dword [cors] ;ecx=ptr to CORS struct
        shl ebx,3
        add ebx,ecx
        ; now ebx holds pointer to the cor struct we want (i)
        mov eax, dword [ebx+CODEP]
        mov dword [SPT], esp
        mov esp, dword [ebx+SPP]
        push eax
        pushfd
        pushad
        mov dword [ebx+SPP], esp
        mov esp, dword [SPT]
        
        func_end

 startCo:
        func_start
        
        pushad; save registers of main ()
        mov dword [SPMAIN], esp; save ESP of main ()
        mov ebx, dword [ebp+8]; gets ID of a scheduler co-routine
        mov ecx , dword [cors] ;ecx=ptr to CORS struct
        shl ebx,3
        add ebx,ecx
        jmp do_resume; resume a scheduler co-routine
        
    end_co:
        mov esp,dword [SPMAIN]
        popad
        end_method

    
    resume:
        pushfd
        pushad
        mov edx,[CURR]
        mov [edx+SPP],esp
    do_resume:
        mov esp,[ebx+SPP]
        mov [CURR],ebx
        popad
        popfd
        ret

main:
    ;parse input
    ;initDroneArray
    ;init_target
    ;init_cors
    ; call scheduler?
    ;end_game? (free?)
    func_start
    ;TODO: do we need space for this? sub     esp, 4
    mov     eax, [ebp+8]                         ; argc
    mov     ebx, [ebp+12]                        ; argv <N> <R> <K> <d> <seed>
    add     ebx, 4                               ; skip first arg
    parseArgInto Nval, format_d
    mov esi, [Nval]
    add esi, 3
    mov [num_of_cors], esi
    parseArgInto Rval, format_d
    parseArgInto Tval, format_d
    parseArgInto Kval, format_d
    parseArgInto Dval, format_f
    parseArgInto seed, format_d
    pushad
    call initDronesArray
    call init_target
    call allocate_cors ;allocating all the necessary memory , for the CORS struct and the stacks of each coroutine
    popad
    xor ecx,ecx
    .init_loop:
        cmp ecx,dword [num_of_cors]
        je .end_init_loop
        pushad
        push ecx
        call initCo
        add esp,4
        popad
        inc ecx
        jmp .init_loop
    .end_init_loop:

        push dword [sched_co_index]
        call startCo
        add esp,4
        func_end


free_mem:
    func_start
    func_end
