; ShiZixuan_GAP295_Midterm.1.1_MazeProgram.asm
.586
.model flat, stdcall
option casemap:none

; Link in the CRT.
includelib libcmt.lib
includelib libvcruntime.lib
includelib libucrt.lib
includelib legacy_stdio_definitions.lib

; Extern functions
extern printf:NEAR      ; Write to screen
extern scanf:NEAR       ; Read input
extern system:NEAR      ; Clear screen and system pause
extern _getch:NEAR      ; Read a character
extern time:NEAR        ; Seed random generator
extern srand:NEAR       ; Seed random generator
extern rand:NEAR        ; Generate random number

.DATA
        ;----------------------------------------------------------
        ; Print strings
        ;----------------------------------------------------------
        kClsStr db 'cls', 0              ; clean screen
        kCharPrintfStr db '%c', 0        ; Print game object symbols
        kNewLine db 0Ah, 0               ; New line "\n"
        kGameWinStr db 'You won!', 0Ah, 0         ; Win string
        kGameLoseStr db 'You lost!', 0Ah, 0       ; Lose string
        kInstructionStr db 0Ah, 'Use wasd to move, good luck', 0ah, 0; Instruction str

        ;----------------------------------------------------------
        ; Game Map
        ;----------------------------------------------------------        
        kMapHeight dd 7       ; Height of game map
        kMapWidth  dd 10      ; Width of game map
        gameMap    db 70 DUP('.'), 0     ; Array of char, used for game map

        ;----------------------------------------------------------
        ; Game Objects
        ;----------------------------------------------------------     
        kPlayerSymbol  db 'G', 0        ; Player symbol
        playerPosition dd 0             ; Player spawn and current position
        kTrapSymbol    db 'T', 0        ; Trap symbol
        kTrapCount     dd 3             ; Amount of trap
        kExitSymbol    db 'X', 0        ; Exit symbol
        kEmptySpace    db '.', 0        ; Empty space symbol
        kEnemySymbol   db 'E', 0        ; Enemy symbol
        kEnemyCount    dd 1             ; Enemy count
        enemyPosition  dd 0             ; Enemy's position

        ;----------------------------------------------------------
        ; User movement input
        ;----------------------------------------------------------     
        kTotalMoveCount dd 4    ; The total possible movement count

.CODE
;=========================================================================================================================================================================
; Main
;=========================================================================================================================================================================
main PROC C
        ; set up stack frame
        push ebp
        mov ebp, esp

        call Init         ; Init game
        call RunGameLoop  ; Run game loop

        push eax          ; RunGameLoop() returned value to result function and print it
        call PrintResult  ; Print the last frame of the map and tell the result

        ; restore the old stack frame
        mov esp, ebp
        pop ebp
        xor eax, eax
        ret       
main ENDP


;=========================================================================================================================================================================
; Init()
;       - Seed random number generator
;       - Fill in objects in game map
;       - Print instructions
;=========================================================================================================================================================================
Init PROC
        ; set the up the stack
        push ebp
        mov ebp, esp
        
        call InitRand          ; Seed random
        call SetUpGameObjects  ; Fill in game objects

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp
 
        ret
Init ENDP


;=========================================================================================================================================================================
; RunGameLoop
;       - Clear screen
;       - Display map
;       - Update
;       - Check if should quit
;=========================================================================================================================================================================
RunGameLoop proc
	    push ebp
	    mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;------------------------------------------------------------------------

        ;------------------------------------------------------------------------
        ; Classic game loop
        ;------------------------------------------------------------------------
    GameLoop:
        ; Draw
        call DisplayMap  

        ; Update
        call Update             ; The game stats outcome will be in eax, 0 for continue, 1 for quit

        ; Check quit
        cmp eax, 0
        je GameLoop             ; if eax == 0, loop again

	    mov esp, ebp
	    pop ebp
		
	    ret
RunGameLoop endp


;=========================================================================================================================================================================
; Display game result to user
;   - Parameter: Game outcome. 1 is won, 2 is lost
;=========================================================================================================================================================================
PrintResult PROC
        ; set the up the stack
        push ebp
        mov ebp, esp
        
        call DisplayMap     ; Print last frame of game map

        mov eax, [ebp+8]    ; Mov parameter to eax, which is the game's result
        cmp eax, 2          ; Check if it's the losing ending
        je Lost             ; If it is, Jmp to Lost

        ; If not losing, then it must be a winning ending. Fall down to win label
    Win:
        push offset kGameWinStr
        jmp Done
        
    Lost:
        push offset kGameLoseStr

    Done:
        call printf
        add esp, 4

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp
 
        ret 4
PrintResult ENDP


;=========================================================================================================================================================================
; Seed random generator
;       srand(time(0));
;=========================================================================================================================================================================
InitRand PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        rdtsc           ; Takes the time-stamp counter and puts it in EDX:EAX. This is the number of milliseconds since the computer has started.
        push eax        ; push the lower dword onto the stack as the parameter for srand()
        call srand      ; call srand()
        add esp, 4      ; Clean up

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp
 
        ret
InitRand ENDP


;=========================================================================================================================================================================
; Put game objects in game map
;       - Traps
;       - Enemies
;       - Player
;       - Exit
;=========================================================================================================================================================================
SetUpGameObjects PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        ;-------------------------------------------------------
        ; Allocate local 
        ;-------------------------------------------------------
        push ebx        ; Keep registers neat
        push esi        

        sub esp, 4                   ; Used for looping to init game objects
        mov DWORD PTR [ebp-4], 0     ; loop count in for loop
        mov esi, offset gameMap      ; ESI = &gameMap

        ;-------------------------------------------------------
        ; Put traps
        ;       for (int i = 0; i < kTrap; ++i)
        ;               gameMap[rand() % (kMapHeight * kMapWidth)] = kTrap
        ;-------------------------------------------------------
    TrapLoop:
        call rand               ; Get a random number in eax

        mov ebx, kMapHeight     ; EBX = kMapHeight
        imul ebx, kMapWidth     ; EBX = kMapHeight * kMapWidth, so we can get a number to do modulo
        xor edx, edx            ; EDX = 0
        idiv ebx                ; Mod result is in EDX
        mov al, kTrapSymbol     ; al = kTrap       
        mov [esi+edx], al       ; Put trap into map

        ; Loop
        inc DWORD PTR [ebp-4]   ; ++i
        mov ebx, kTrapCount     ; ebx = kTrapCount to compare with i
        cmp DWORD PTR [ebp-4], ebx      ; if i is less than kTrapCount, continue
        jl TrapLoop             ; Loop back

        ;-------------------------------------------------------
        ; Put Enemies
        ;      gameMap[rand() % (kMapHeight * kMapWidth)] = kEnemy
        ;-------------------------------------------------------
        call rand               ; Get a random number in eax

        mov ebx, kMapHeight     ; EBX = kMapHeight
        imul ebx, kMapWidth     ; EBX = kMapHeight * kMapWidth, so we can get a number to do modulo,
        xor edx, edx            ; EDX = 0
        idiv ebx                ; Mod result is in edx
        mov al, kEnemySymbol    ; al = kEnemy       
        mov [esi+edx], al       ; Put enemy into map

        ; Set enemy position
        mov eax, offset enemyPosition
        mov [eax], edx

        ;-------------------------------------------------------
        ; Put player
        ;       gameMap[playerPosition] = kPlayer
        ;-------------------------------------------------------
        mov al, kPlayerSymbol           ; al = kPlayerSymbol
        mov ebx, playerPosition         ; ebx = playerPosition
        mov [esi+ebx], al    ; put player into map

        ;-------------------------------------------------------
        ; Put Exit
        ;       gameMap[(mapWidth*mapHeight) - 1] = kExit
        ;-------------------------------------------------------
        mov ebx, kMapHeight     ; EBX = kMapHeight
        imul ebx, kMapWidth     ; EBX = kMapHeight * kMapWidth, so we can get a number to do modulo
        dec ebx                 ; --EBX to get the right lower corner
        mov al, kExitSymbol     ; al = exit symbol
        mov [esi+ebx], al       ; put exit into map

        ; fully reset the stack and base pointers to whatever they were
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
 
        ret
SetUpGameObjects ENDP


;=========================================================================================================================================================================
; System("cls"), clear the screen
;=========================================================================================================================================================================
ClearScreen PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        push offset kClsStr
        call system
        add esp, 4

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp
 
        ret
ClearScreen ENDP


;=========================================================================================================================================================================
; Print Game Map
;       int x = 0;   
;       int y = 0;
;	for (y = 0; y < mapHeight; ++y)
;	{
;		for (x = 0; x < mapWidth; ++x)
;		{
;			std::cout << gameMap[x + (y * kWidth)];
;		}
;		std::cout << std::endl;
;	}
;=========================================================================================================================================================================
DisplayMap PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;------------------------------------------------------------------------
        push ebx                     ; Keep registers neat 
        push esi

        sub esp, 8                   ; Allocate two local variables for looping through map
        mov DWORD PTR [ebp-4], 0     ; mapWidth,  aka X in for loop
        mov DWORD PTR [ebp-8], 0     ; mapHeight, aka Y in for loop
        mov esi, offset gameMap      ; Esi = &gameMap

        ;------------------------------------------------------------------------
        ; Print game map
        ;------------------------------------------------------------------------
        ; System("cls")
        call ClearScreen

    HeightLoop: ; for (int y = 0; y < mapHeight; ++y)

        WidthLoop:  ; for (int x = 0; x < mapWidth; ++x)
            ;------------------------------------------------------
            ; std::cout << gameMap[x + (y * kWidth)];
            ;------------------------------------------------------
            mov eax, [ebp-4]            ; eax = x
            mov ebx, [ebp-8]            ; ebx = y       
            imul ebx, kMapWidth         ; ebx = y * kMapWidth, aka ebx *= kMapWidth
            add eax, ebx                ; eax = x + (y * kWidth)
            mov eax, [esi+eax]          ; eax = *gameMap[x + (y * kWidth)]
            push eax                    ; Push eax on stack, make it the parameter to PrintSymbol function
            call PrintSymbol            ; std::cout << eax;

            inc DWORD PTR [ebp-4]       ; ++x
            mov ebx, kMapWidth          ; EBX = kMapWidth for comparing
            cmp DWORD PTR [ebp-4], ebx  ; see if we should loop again
            jl WidthLoop                ; if x < kMapWidth, loop back

        call PrintNewline           ; std::cout << std::endl;
        mov DWORD PTR [ebp-4], 0    ; Assign [ebp-4] (x) to 0

        inc DWORD PTR [ebp-8]       ; ++y
        mov ebx, kMapHeight         ; EBX = kMapHeight for comparing
        cmp DWORD PTR [ebp-8], ebx  ; see if we should loop again
        jl HeightLoop               ; if y < kHeight, loop back

        ; Print out instructions
        push offset kInstructionStr
        call printf
        add esp, 4

        ; fully reset the stack and base pointers to whatever they were
        pop esi
        pop ebx         
        mov esp, ebp
        pop ebp

	    ret
DisplayMap ENDP


;=========================================================================================================================================================================
; Print symbol passed in
;=========================================================================================================================================================================
PrintSymbol proc
	    push ebp
	    mov ebp, esp

        push [ebp+8]                ; Push parameter onto the stack
        push offset kCharPrintfStr  ; This string is '%c'
        call printf
        add esp, 8

	    mov esp, ebp
	    pop ebp
		
	    ret 4   ; Clean parameter
PrintSymbol endp


;=========================================================================================================================================================================
; Take user's input, update the game, return the if we should continue game to EAX
;       - Using edi to store user's input
;       - Using ebx to store player's previous position
;       - Using [ebp-4] to store player's new position after updating it
;=========================================================================================================================================================================
Update proc
	    push ebp
	    mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;       - Allocate four bytes to store player's new position
        ;------------------------------------------------------------------------
        push edi        ; store user's input
        push ebx        ; do modulo

        sub esp, 8      ; Four bytes to store player's new position after MovePlayer()

        mov esi, offset gameMap         ; ESI = &gameMap
        mov edx, playerPosition
        mov [ebp-8], edx ; Player's previous position

        ;------------------------------------------------------------------------
        ; Do work
        ;       - _getch to take user's input
        ;       - Update player's position
        ;       - Randomly move enemy
        ;       - Return if we should quit or continue the game
        ;------------------------------------------------------------------------
        ; Get user's input
        call _getch     ; User's input is in eax now
        mov edi, eax    ; Store _getch() value into edi
        
        ; Update player's position according to user's input
        push [ebp-8]            ; Player's previous position
        push edi                ; Push movement input
        call Move               ; Player's new position is in EAX now
        mov [ebp-4], eax        ; Stores player's new position

        ; Randomly move enemy
        call MoveEnemy          

        ; Check game stats
        push [ebp-4]              ; Push player's new position to check if we should quit the game or not        
        call ReturnGameStats      ; Return value is in EAX, 0 is continue, 1 is won, 2 is lose

        ; Update Game map
        mov dl, kEmptySpace       ; dl = '.'
        mov ebx, [ebp-8]          ; ebx = player's previous position
        mov [esi+ebx], dl         ; gameMap[playerPreviousPosition] = kEmptySpace;

        mov dl, kPlayerSymbol     ; dl = playerSymbol
        mov ecx, [ebp-4]          ; ECX = player's new position
        mov [esi+ecx], dl         ; gameMap[playerPosition] = kPlayerSymbol;

        ; Update player's position
        mov ecx, offset playerPosition  ; ECX = &playerPosition
        mov edx, [ebp-4]                ; EDX = newPlayerPosition
        mov [ecx], edx                  ; ECX = EDX

        ;------------------------------------------------------------------------
        ; Clean up, return if we should quit or continue
        ;------------------------------------------------------------------------
        pop ebx
        pop edi         
	    mov esp, ebp
	    pop ebp
		
	    ret
Update endp


;=========================================================================================================================================================================
; Return player's position new position according to _getch() input
;       - parameter:  User's input in [ebp+8]
;       - Parameter2: The moving object's position [ebp+12]
;=========================================================================================================================================================================
Move PROC
        push ebp
        mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;------------------------------------------------------------------------
        push ebx        ; Keep registers' value

        ;------------------------------------------------------------------------
        ; Do work
        ;       - switch(input)
        ;           case kUp: 
        ;		        if (objectPosition - kWidth >= 0)
	    ;	            {
	    ;		            objectPosition -= kWidth;
	    ;	            }
	    ;	        return;
        ;               ...
        ;------------------------------------------------------------------------
        mov ecx, 'w'            ; Let ecx = 'w', which is the greatest hex number amoung four possible input
        sub ecx, [ebp+8]        ; ecx -= movement input. If the value is 0, means the input is kUp key, if the value is 19, means the input is kRight, etc.

        ; Mov objectPosition to eax and edx for calculations in each move direction Label
        mov eax, [ebp+12] ; Final return result
        mov edx, [ebp+12] ; EDX is used for checking edges statements

        ; Consider this as a switch statement.
        ; if input is 's', 'w' - 's' = 4 in decimal. Go to MoveDown label.
        cmp ecx, 4
        je MoveDown

        cmp ecx, 22
        je MoveLeft

        cmp ecx, 19
        je MoveRight

        ; If we passed all three conditions above, but the input is not 'w'. It means the user entered invalid input. Go to done
        cmp ecx, 0
        jne Done

    MoveUp:
        ; if (objectPosition - kWidth >= 0) {}
        sub edx, kMapWidth
        cmp edx, 0
        jl Done

        ; objectPosition -= kWidth;
        sub eax, kMapWidth
        jmp Done

    MoveDown:
 	    ; if (objectPosition + kWidth < kWidth * kHeight)   {}
        add edx, kMapWidth      ;(objectPosition + kWidth)
        mov ecx, kMapWidth
        imul ecx, kMapHeight    ;(kWidth * kHeight)
        cmp edx, ecx
        jge Done

        ; objectPosition += kWidth if we pass the edge check
        add eax, kMapWidth
        jmp Done       

    MoveRight:
        ; if ((objectPosition + 1) % kWidth != 0)
        xor edx, edx              ; EDX = 0, storing the result of modulo
        mov eax, 1                ; Initialize EAX to 1 here
        add eax, [ebp+12]         ; EAX = objectPosition + 1
        mov ebx, kMapWidth        ; Move map width into EBX
        idiv ebx                  ; EAX = EAX/EBX, modulo outcome will be in EDX, check if it's 0
        mov eax, [ebp+12]         ; Restore eax to objectPosition

        cmp edx, 0      ; If we are on the right edge, do nothing and return
        je Done

        ; objectPosition += 1;
        inc eax
        jmp Done

    MoveLeft:
        ; if (objectPosition % kMapWidth != 0)
        xor edx, edx              ; EDX = 0, storing the result of modulo
        mov eax, [ebp+12]         ; Put objectPosition position into EAX
        mov ebx, kMapWidth        ; Move map width into EBX
        idiv ebx                  ; EAX = EAX/EBX, modulo outcome will be in EDX, check if it's 0
        mov eax, [ebp+12]         ; Reassign object's previous to EAX

        cmp edx, 0      ; If we are on the left edge, do nothing and return
        je Done

        ; objectPosition -= 1;
        dec eax

    Done:
        ;------------------------------------------------------------------------
        ; Clean, return Value in eax
        ;------------------------------------------------------------------------
        pop ebx
        mov esp, ebp
        pop ebp
        ret 8           ; Clean parameter
Move ENDP


;=========================================================================================================================================================================
; Log if The object is stepping into a trap, reaches the exit, an enemy, or nothing
; Return 0 if we should keep playing, return 1 if we won, return 2 if we lose
;=========================================================================================================================================================================
ReturnGameStats proc
	    push ebp
	    mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;------------------------------------------------------------------------
        push esi

        mov esi, offset gameMap ; ESI = &gameMap
        mov ecx, [ebp+8]        ; Move player's new location to ecx!
        mov al, [esi+ecx]       ; put the object in player's new position into al

        ;------------------------------------------------------------------------
        ; Do work
        ;       - Check if hits a trap
        ;       - Check if hits the exit
        ;------------------------------------------------------------------------
        ; Check trap
        mov dl, kTrapSymbol     ; dl = TrapSymbol
        cmp al, dl              ; Check if it's a trap
        je Dead

        ; Check enemy
        mov dl, kEnemySymbol    ; dl = kEnemySymbol
        cmp al, dl              ; Check if it's a Enemy
        je Dead

        ; Check exit
        mov dl, kExitSymbol
        cmp al, dl              ; If it's 0, means we hit a trap
        je Win

        ; If we didn't hit either, continue game
        xor eax, eax    ; return 0
        jmp Done

    Win:
        mov eax, 1      ; Return 1
        jmp Done
        
    Dead:
        mov eax, 2      ; Return 2

    Done: 
        ;------------------------------------------------------------------------
        ; Clean
        ;------------------------------------------------------------------------
        pop esi
	    mov esp, ebp
	    pop ebp
	    ret 4
ReturnGameStats endp


;=========================================================================================================================================================================
; Prints a single newline character.
;=========================================================================================================================================================================
PrintNewline PROC
        push ebp
        mov ebp, esp

	    push offset kNewLine
	    call printf
	    add esp, 4
        
        mov esp, ebp
        pop ebp
        ret
PrintNewline ENDP


;=========================================================================================================================================================================
; Randomly move the enemy
;=========================================================================================================================================================================
MoveEnemy PROC
        push ebp
        mov ebp, esp

        ;------------------------------------------------------------------------
        ; Set up
        ;------------------------------------------------------------------------
        push ebx
        push esi
        
        mov esi, offset gameMap

        ;------------------------------------------------------------------------
        ; Do work
        ;------------------------------------------------------------------------
        ; Get a random movement input (wasd)
        call rand

        ; randomOutcome = rand() % kTotalMoveCount
        xor edx, edx
        mov ebx, kTotalMoveCount        
        idiv ebx        ; Random movement outcome is in EDX now

        cmp edx, 0
        jpe MoveUp

        cmp edx, 1
        jpe MoveDown

        cmp edx, 2
        jpe MoveLeft

        cmp edx, 3
        jpe MoveRight

    MoveUp:
        mov ecx, 'w'
        jmp Done

    MoveDown:
        mov ecx, 's'
        jmp Done

    MoveLeft:
        mov ecx, 'a'
        jmp Done

    MoveRight:
        mov ecx, 'd'

    Done:
        push enemyPosition  ; Enemy's position
        push ecx            ; Random moving direction
        call Move           ; Move outcome in eax 

        ; Update map
        mov cl, kEmptySpace     ; Set previous position to empty space
        mov edx, enemyPosition
        mov [esi+edx], cl

        mov cl, kEnemySymbol    ; Set new position to enemy       
        mov [esi+eax], cl       ; Put enemy into map

        ; Update enemy position
        mov edx, offset enemyPosition
        mov [edx], eax

        ;------------------------------------------------------------------------
        ; Clean
        ;------------------------------------------------------------------------
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret
MoveEnemy ENDP


END
