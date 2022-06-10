;; init drone locations
;; init target
;;



; מי שמאמין לא מתעד
%macro func_start 0
    push ebp
    mov ebp, esp
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

section .data:
    ;; init all "board" related vars: dronesArray, game params, target
    ;; game initializtion: init schedueler, printer, terget
    ;; defining utility functions: random, rad->deg, ged->rad,
    
    N : dd 0
    R : dd 0
    T : dd 0
    DronesArrayPointer: dd 0
    currAngleDeg: dq 0
    currAngleRad: dq 0
    Gamma: dq 0
    varA: dq 0
    cors: dd 0

section .text:
    generate_random_number:
    ;; should get lower, upper bound, return a random between them


convert_deg_to_rad:
    startFun
    finit 
    fld qword [currAngleDeg]
    mov [varA], dword 0 ; TODO maybe delete?
    mov [varA], dword 180
    fild dword [varA]
    fdiv
    fldpi
    fmul
    fstp qword [currAngleRad]
    endFun
    
; specific to gamma
convert_rad_to_deg:
    startFun
    finit 
    fld qword [Gamma]
    fldpi
    fdiv
    mov [varA], dword 0
    mov [varA], dword 180
    fild dword [varA]
    fmul
    fstp qword [Gamma]
    endFun

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
    