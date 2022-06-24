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
    mov edx, dword [%2]
    mov dword [%1], edx
    mov edx, dword [%2+4]
    mov dword [%1+4], edx
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
    ;; init all "board" related vars: dronesArray, game params, target
    ;; game initializtion: init schedueler, printer, terget
    ;; defining utility functions: random, rad->deg, ged->rad,
    extern calloc
    extern printf
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
    mov dword[varA], 0               ; clean varA
    mov word[varA], ax              ; varA = random short
    fld dword [varA]                         ; push float
    mov dword [varB], 0xffff              ; max int for 16bit
    fidiv dword [varB]                      ; number/ffff  mov eax, dword[ebp+8]              ;eax holds limit
    mov eax, dword [ebp+8]
    mov dword [varB], eax
    fimul dword[varB]                ;now top of stack is the random dist
    fst qword[varA]                 ;varA now holds the position
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
    push dword [MAX_DELTA_POS_RANGE] ; ==20
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
        mov dword [DronesArrayPointer+ebx*4], eax
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
    ; now eax holds the pointer
    mov dword [target_pointer], eax
    call create_target

    
create_target:
    ; void func (), updated target_pointer->xpos=rnd, target_pointer->ypos=rnd, target_pointer->isdestroyed=0
    func_start
    call generate_random_position
    mov_mem_to_mem_qwords target_pointer+TARGET_STRUCT_XPOS_OFFSET, varA
    call generate_random_position
    mov_mem_to_mem_qwords target_pointer+TARGET_STRUCT_YPOS_OFFSET, varA
    mov byte [target_pointer+TARGET_STRUCT_IS_DESTROYED_OFFSET], 0
    func_end

move_target:
    func_start
    call generate_random_delta_xy       ;now var A hold delta x 
    ffree

    ;moving x location
    fld qword [varA]
    fadd qword [target_pointer+TARGET_STRUCT_XPOS_OFFSET]
    fstp qword [varA]
    push dword [BOARD_SIZE]                      ; pushing board limits
    call wrap              ; now var A hold wrap x
    mov_mem_to_mem_qwords target_pointer+TARGET_STRUCT_XPOS_OFFSET, varA    ;TODO see if this works

    ;moving y location
    fld qword [varA]
    fadd qword [target_pointer+TARGET_STRUCT_YPOS_OFFSET]
    fstp qword [varA]
    push dword [BOARD_SIZE]                      ; pushing board limits
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
    push dword [MAX_DEGREE]                      ; pushing board limits
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


init_co_routines:
    func_start
    mov eax, 0
    mov eax, 3
    add eax, [Nval]
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
    mov esi, dword [Nval]
    add esi, 3
    cmp ebx, esi         ; if not working, move [N]+3 into register
    je end_drones_cors_init_loop
    mov dword [cors+ebx*8], run_drone
    push 1
    push CO_STK_SIZE
    call calloc
    add esp, 8
    mov dword [cors+ebx*8+4], eax
    jmp drones_cors_init_loop
    end_drones_cors_init_loop:
    func_end

; EBX is pointer to co-init structure of co-routine to be resumed
; CURR holds a pointer to co-init structure of the curent co-routine
resume:
	pushfd					; Save state of caller
	pushad
	mov	edx, [cors]
	mov	[edx+8], esp		; Save current SP

do_resume:
	mov	esp, [ebx+8]  	; Load SP for resumed co-routine
	mov	[cors], ebx
	popad					; Restore resumed co-routine state
	popfd
	ret                     ; "return" to resumed co-routine!

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
    parseArgInto Rval, format_d
    parseArgInto Tval, format_d
    parseArgInto Kval, format_d
    parseArgInto Dval, format_f
    parseArgInto seed, format_d
    call initDronesArray
    call init_target
    call init_co_routines
    mov [SPMAIN], esp
    mov dword [currDrone], 0			; Curr drone will hold the first drone ID
    mov ebx, cors						; Ebx is pointer to scheduler function
    jmp do_resume

    finish_main:
        mov 	esp, [SPMAIN]
        call    free_mem
        pop     ebp             			; Restore caller state
        ret

free_mem:
    func_start
    func_end
