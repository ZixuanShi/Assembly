; Quick-sort assembly implementation
.586
.model flat, stdcall
option casemap:none

; Link in the CRT.
includelib libcmt.lib
includelib libvcruntime.lib
includelib libucrt.lib
includelib legacy_stdio_definitions.lib

; Extern functions
extern printf:NEAR                  ; Write to screen
extern system:NEAR      ; Clear screen and system pause

.data
    numArray  dd 45,11,2,8,9        ; The array to sort
    kSize     dd 5                  ; Size of the array. Must be exactly matched with the numArray's size
    resultStr db '%d', 0ah, 0       ; String to output elements in the array with Printf
    kPauseStr db 'pause', 0         ; system("pause")
.code

;-------------------------------------------------------------------------------------------
; int main()
;-------------------------------------------------------------------------------------------
main proc C
    ; Init startIndex and endIndex
    mov     eax, kSize
    dec     eax
    push    eax      ; endIndex will be kSize - 1
    push    0        ; startIndex will be zero
    call    QuickSort
    add     esp, 8

    ; Print the sorted array
    call    PrintArray
    call    PauseSystem

    xor     eax, eax
    ret     0
main endp

;-------------------------------------------------------------------------------------------
; Quick Sort Implementation
; Params:
; - startIndex: [ebp+8]
; - endIndex:   [ebp+12]
;
; Local variables:
; - pivotIndex: [ebp-4]
;-------------------------------------------------------------------------------------------
QuickSort proc
    push    ebp
    mov     ebp, esp

    ; Grab the startIndex and endIndex parameters
    mov     eax, DWORD PTR [ebp+8]     ; startIndex
    cmp     eax, DWORD PTR [ebp+12]    ; endIndex
    jl      QuickSortRecursion
    jmp     Done

QuickSortRecursion:
    ; Call partition with the start and end indices
    mov     ecx, DWORD PTR [ebp+12]
    push    ecx
    mov     edx, DWORD PTR [ebp+8]
    push    edx
    call    Partition
    add     esp, 8
    mov     DWORD PTR [ebp-4], eax  ; [ebp-4] now has the pivot index

    ; QuickSort(startIndex, pivotIndex - 1);
    mov     eax, DWORD PTR [ebp-4]
    dec     eax
    push    eax
    mov     ecx, DWORD PTR [ebp+8]
    push    ecx
    call    QuickSort
    add     esp, 8

    ; QuickSort(pivotIndex, endIndex);
    mov     edx, DWORD PTR [ebp+12]
    push    edx
    mov     eax, DWORD PTR [ebp-4]
    push    eax
    call    QuickSort
    add     esp, 8

Done:
    mov     esp, ebp
    pop     ebp
    ret     0
QuickSort endp

;-------------------------------------------------------------------------------------------
; Sort the array, return the pivot index
; Params:
; - startIndex: [ebp+8]
; - endIndex:   [ebp+12]
;
; Local variables:
; - &numArray:  esi       
; - j:          [ebp-4]
; - i:          [ebp-8]
; - pivotIndex: [ebp-12]
; - pivot:      [ebp-16]
;
; Returns:
; - pivotIndex: [eax]
;-------------------------------------------------------------------------------------------
Partition proc
    push    ebp
    mov     ebp, esp

    sub     esp, 16    

    ; esi = &numArray
    mov     esi, offset numArray

    ; Using the last element as the pivot. Stored in [ebp-16]
    mov     eax, DWORD PTR [ebp+12]     ; assign endIndex to eax
    mov     ecx, [esi + 4*eax]          ; ecx has the pivot, aka numArray[endIndex]
    mov     DWORD PTR [ebp-16], ecx     ; [ebp-16] has the pivot, aka numArray[endIndex]. ecx is free to use now

    ; i is the last element's index of region 1, which is less than the pivot. 
    mov     ebx, DWORD PTR [ebp+8]      ; ebx has the startIndex
    dec     ebx                         ; dec ebx
    mov     DWORD PTR [ebp-8], ebx      ; [ebp-8] has i

    ; j is the current processing element's index.
    mov     eax, DWORD PTR [ebp+8]      ; eax has startIndex, aka j
    mov     DWORD PTR [ebp-4], eax      ; [ebp-4] has j

LoopCompare:
    ; if j >= endIndex. Go to Done
    cmp eax, DWORD PTR [ebp+12]
    jge PartitionDone

PartitionLoop:
    ; Get numArray[j], See if current element should be placed to region one
    mov     edx, [esi + 4*eax]          ; edx has numArray[j]. Pivot is in [ebp-16]
    cmp     edx, DWORD PTR [ebp-16]     ; Compare numArray[j] with Pivot
    jg      UpdateLoop                  ; If numArray[j] is greater than pivot, skip to update loop

    ; Grow region 1
    inc ebx
    
    ; Swap last element in region 1 with current processing element.
    mov     edi, edx                    ; int temp = numArray[j]; edi has numArray[j], which is used for temp
    mov     ecx, [esi + 4*ebx]          ; ecx has numArray[i]
    mov     [esi + 4*eax], ecx          ; numArray[j] = numArray[i];
    mov     [esi + 4*ebx], edi          ; numArray[i] = temp;

UpdateLoop:
    ; ++j. Check loop condition
    inc eax
    jmp LoopCompare

PartitionDone:
    ; Everything is in its place except for the pivot. We swap the pivot with the first element of region 2.
    ; ++i
    inc ebx

    ; int temp = numArray[i];
    mov     edi, [esi + 4*ebx]          ; int temp = numArray[i];
    mov     eax, DWORD PTR [ebp-16]     ; eax has the pivot
    mov     [esi + 4*ebx], eax          ; numArray[i] = pivot;
    mov     eax, DWORD PTR [ebp+12]     ; eax has endIndex
    mov     [esi + 4*eax], edi          ; numArray[endIndex] = temp

    mov esp, ebp
    pop ebp        
    ret 0
Partition endp

;-------------------------------------------------------------------------------------------
; Print all the elements in the numArray
;-------------------------------------------------------------------------------------------
PrintArray proc
    push ebp
    mov ebp, esp

    ; ebx = kSize
    mov ebx, kSize  ; EBX = kSize

    ; int i = 0. Put value into edi
    xor edi, edi
    mov esi, offset numArray    ; ESI = &numArray

    ; Loop to print array elements
PrintLoop:
    ; Move the current element into EAX
    mov eax, [esi + edi*4]

    ; printf it
    push eax
    push offset resultStr
    call printf
    add esp, 4

    ; ++i
    inc edi

    ; if i < kSize * sizeof(int), jump back to PrintLoop
    cmp edi, ebx    ; Compare EDI with EBX
    jl PrintLoop    ; if EDI is less than EBX, go back to PrintLoop

    mov esp, ebp
    pop ebp    
    ret
PrintArray endp


;-------------------------------------------------------------------------------------------
; System("pause")
;-------------------------------------------------------------------------------------------
PauseSystem PROC
        ; set the up the stack
        push ebp
        mov ebp, esp

        push offset kPauseStr
        call system
        add esp, 4

        ; fully reset the stack and base pointers to whatever they were
        mov esp, ebp
        pop ebp
 
        ret
PauseSystem ENDP


END