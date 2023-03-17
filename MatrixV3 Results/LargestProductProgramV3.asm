;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Computer Science Assembly Language  							   ;;
;; Program: Finds the largest product of four numbers that can be  ;;
;; in a (row, column, or diagonally).                              ;;
;; Requires: Input file, output file.                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE Irvine32.inc

.data
;---Control Characters---;
NULL	 EQU 00h         
LF		 EQU 0ah         
CR		 EQU 0dh         
SPC 	 EQU 20h

;---Storage for Numerical Values---;
TEN			dword	10							
TWO			dword	2

;---Input and Output filenames and handles---;
outFN		byte	"BDahmer_ResultsV2.txt", NULL			;output filename.
inFN     	byte	"MatrixV3.dat", NULL					;input filename.
infile		dword	?										;input file handle, value holder.
outfile		dword	?										;output file handle, value holder.

;---Strings---;
fline       byte  "=================================================================", CR, LF, NULL
Msg0	    byte  "Largest Product of Four Numbers Program Created by: bdahmerj", CR, LF, NULL
MsgV2		byte  "This was calculated using MatrixV2.dat (used [0,0] to [19,19])", CR, LF, NULL
MsgV3		byte  "This was calculated using MatrixV3.dat (used [0,0] to [19,19])", CR, LF, NULL
SumMsg1	    byte  "The Largest Product of Four Numbers is: ", NULL
NumMsg1		byte  "The four numbers are: ", NULL
NumMsg2     byte  "The location of the fourth value is: ",  NULL
RMsg	    byte  "At Location (row ", NULL
CMsg		byte  ",column ", NULL
bestStr     byte	 8 dup(?), NULL					;will contain the sum of the best value.

;---Format Strings---;
nline		byte   CR, LF, NULL						;new line string.
numStr		byte  2 dup(?), NULL
commaStr	byte  ",",NULL
colonStr	byte  "): ",NULL
;---Storage For Ary1 and Buffer---;
BUFF	 	byte	 6000 dup(?), CR, CR			;size of the buffer (might be overkill).
Ary1		dword    1000 dup(' '), CR				;size of the array.(might be overkill).
          
byteCount	dword ?				;stores the total bytes from the Buffer.
valCtr		dword ?				;stores the number of values in Ary1, used as a counter for filling the array.

;-----Storage for BestSum and position--------------------;
BestSum		dword 0				;store the best Sum value.
sRow		dword 0				;saved row.
sCol		dword 0				;saved column.

;---Shift Values-----;
nCol		dword 4				;diagonal shifting value.
nPos		dword 0				;new position to start on for next product iteration.
nRow		dword 80			;row change offset of 12. used for ROW_LR
ctr			dword 4				;counter for how many values to add together.
ROW			dword 80			;row OFFSET
COL			dword 4				;column OFFSET
r_ctr		dword 0				;row ctr.
c_ctr		dword 0				;column ctr.
cLimit		dword 17			;bounds 17. 
dLimit		dword 17			;bounds 17.
blRow		dword 1520			;bottom left row.
brRow		dword 1596			;bottom right row.

;---Storing Numbers From Best Product---;
numA		dword NULL			;holds the first number
numB		dword NULL			;holds the second number
numC		dword NULL			;holds the third number.
numD		dword NULL			;holds the fourth number.
.code
main PROC
	call ReadFileIntoBuffer				;reads an input file into a buffer.

	lea esi, BUFF						;point to buffer
	lea edi, Ary1						;point to Ary1.
	call FillAry						;fills the array with dword size values from the buffer.

	call Diagonal_UD_LR					;Diagonal up to down left to right check.
	call Reset_ShiftValues				;resetting shift values.

	call Diagonal_DU_LR					;Diagonal down to up left to right check.
	call Reset_ShiftValues				;resetting shift values.

	call Diagonal_DU_RL					;Diagonal down to up right to left check.
	call Reset_ShiftValues				;resetting shift values.

	call Diagonal_UD_RL					;Diagonal up to down left to right check.
	call Reset_ShiftValues				;resetting shift values.
	
	call Row_LR							;Row from Left to right check goes from index 0 to bounds of array.
	call Reset_ShiftValues				;resetting shift values.

	call Col_LR							;Column from left to right check goes from index 0 to boudns of array (per check).	
 
	call OutputFileOpenSetup			;opens output file and sets it up.

	call Print_Title					;prints the title to the output file.
	
	lea esi, MsgV2						;swap out to MsgV3 for MatrixV3.dat, when needed
	call PrinttoFile
	
	call PrintResults					;prints the values and results to the output file.

	mov eax, outfile					;moving handle into eax register for output file.
	call CloseFile						;closing output file.   
	
	invoke ExitProcess, 0
main endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PrintResults will print out the results from     ;;
;; the calculations performed in the matrix.        ;;
;; when finished returns to main procedure.	        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintResults proc
	lea esi, fline					;point to format line '==',etc.
	call PrintToFile				;print to a file.

	lea esi, SumMsg1				;String for the largest product number.
	call PrintToFile				;print to a file.
	
	lea esi, bestStr				;point at bestStr (will hold the largest product in ascii form later).
	mov ecx, 8						;setting blankout counter.
	call BlankOut					;call to blankout to clear the bestStr.
	mov eax, BestSum				;moving BestSum into the eax register for ITOA conversion.
	call ITOA						;Integer to Ascii call.
	
	lea esi, bestStr				;point to bestStr (holds largest product now in ASCII form).
	call PrintToFile				;print to a file.
	
	lea esi, nline					;point to nline "new line" holds control characters (CR, LF).
	call PrintToFile				;print to a file.
		
    lea esi, NumMsg1				;point to NumMsg1, holds "The four numbers are: ", string.
	call PrintToFile				;print to a file.

;first number
	lea esi, numStr					;point to numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, numA					;move integer into eax register, required for ITOA call.
	call ITOA						;Integer to Ascii call.
	lea esi, numStr					;points to numStr.
	call PrintToFile				;prints to a file.

	lea esi, commaStr				;points at a comma string ",".
	call PrintToFile				;print to a file.

;second number
	lea esi, numStr					;point to numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, numB					;move integer into eax register, required for ITOA call.
	call ITOA						;Integer to Ascii call.
	lea esi, numStr					;point to numStr.
	call PrintToFile				;prints to a file.

	lea esi, commaStr				;points to a comma string.
	call PrintToFile				;prints to file.

;third number
	lea esi, numStr					;point to numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, numC					;move integer into eax register, required for ITOA call.
	call ITOA						;Integer to Ascii call.
	lea esi, numStr					;point to numStr.
	call PrintToFile				;print to a file

	lea esi, commaStr				;points to a comma string.
	call PrintToFile				;prints to file.

;fourth number
	lea esi, numStr					;point to numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, numD					;move integer into eax register, required for ITOA call.
	call ITOA						;Integer to Ascii call.

	lea esi, numStr					;point to numStr.
	call PrintToFile				;print to a file.

	lea esi, nline					;point to nline "new line" holds control characters (CR, LF).
	call PrintToFile				;print to a file.

	lea esi, RMsg					;point to RMsg "At Location (row ".
	call PrintToFile				;print to a file.

	lea esi, numStr					;point to numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, sRow					;move sRow into eax register (holds row of the fourth values location from the best product).
	call ITOA						;Integer to Ascii call.
	lea esi, numStr					;point to numStr.
	call PrintToFile				;print to a file.

	lea esi, CMsg					;point to CMsg ",column ".
	call PrintToFile				;print to a file.

	lea esi, numStr					;point to numStr
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, sCol					;move sCol into eax register (holds column of the fourth values location from the best product).
	call ITOA						;Integer to Ascii call.
	lea esi, numStr					;points to numStr.
	call PrintToFile				;prints to file.

	lea esi, colonStr				;points to colon string.
	call PrintToFile				;prints to file.

	lea esi, numStr					;points at numStr.
	mov ecx, 2						;number of locations to blank.
	call BlankOut					;blanks out an array.
	mov eax, numD					;move area into eax register, required for ITOA call.
	call ITOA						;Integer to Ascii call.

	lea esi, numStr					;points at numStr.
	call PrintToFile				;prints to a file.
	
	lea esi, nline					;point new line contains control chars.
	call PrintToFile				;print to a file.
	
	lea esi, fline					;point to format line contains '==',etc.
	call PrintToFile				;print to a file.
	ret								;returns to main proc.
PrintResults endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reset_ShiftValues will reset values to default   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reset_ShiftValues proc
	mov nCol, 4						;resetting nCol to 4.
	mov nPos, NULL					;resetting nPos.
	mov ctr, 4						;resetting ctr back to 4.
	mov ROW, 80						;moving default value into ROW.
	mov COL, 4						;moving default value into COL.
	mov r_ctr, NULL					;resetting row counter.
	mov c_ctr, NULL					;resetting column counter.
	ret								;return to main proc.
Reset_ShiftValues endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Col_LR UP/DOWN LEFT/RIGHT					    ;;
;; Checks columns Up to down from left to right.    ;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Col_LR proc
	XOR eax, eax
	push ctr
	mov ecx, dLimit					;move dlimit left-->right into ecx register.
	mov edx, cLimit					;move cLimit going down a row into edx register.
	lea edi, Ary1					;point at Ary1 (THE MATRIX 20x20).
	L00:
		mov eax, [edi]				;move value edi is pointing to into eax register.
		dec ctr						;moved one of four values into the eax register (the first value).
	L0:
		add edi, ROW				;shift down one row.
		mov ebx, [edi]				;move value edi pointing to into ebx register.
		imul eax, ebx				;multiply values and store in eax register.
		inc r_ctr					;increment row counter (starting is 0).
		dec ctr						;decrement 4 value counter.
		cmp ctr, NULL				;compare to null.
	jne L0
		cmp BestSum, eax			;checking for better product.
	jg L1
		mov BestSum, eax			;move eax register value into BestSum, eax was greater.
		mov ebx, [edi]				;moving back into ebx register
		mov ebx, r_ctr				;moving row count into ebx register.
		mov sRow, ebx				;storing value in memory sRow. ("Saved Row").
		mov ebx, c_ctr				;moving column count into ebx register.
		mov sCol, ebx				;storing value in memory sCol. ("Saved Column").
		
		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		sub edi, ROW				;shift shift one row.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		sub edi, ROW				;shift up one row.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		sub edi, COL				;shift up one row.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.			
	L1:
	    mov eax, ROW				;move ROW (80) into eax register.
		mov ebx, nPos				;move nPos(0) starts at 0 into ebx register.
		add eax, ebx				;add each register ROW + nPos.
		mov nPos, eax				;store new value into nPos memory location.
		XOR eax, eax				;clear register eax.
		XOR ebx, ebx				;clear register ebx.

		pop ctr						;getting counter from stack, returns it back to (4).
		push ctr					;push to the stack, so my pops keep giving me (4).
		lea edi, Ary1				;point at first position in Ary1.
		add edi, nPos				;moving right one column, because nPos holds offset of new position.
		
		sub r_ctr, 2				;get offset position(starting position is 0).
		dec ecx						;dec ecx (boundary counter).
		cmp ecx, NULL				;checking to see if at end of bounds.
	jne L00							;return to L00 which puts first value into eax register.
		pop ctr						;releasing ctr so the stack is back on the return address.
		push ctr					;pushing ctr back onto the stack.
		mov ecx, dLimit				;resetting limiter.
		
		mov ebx, nCOL				;moving offset into ebx register 4 bytes column shift right.
		mov nPos, ebx				;moving offset into nPos (new position).
		lea edi,[Ary1 + ebx] 		;offsetting location by increments of 4 for each column.
		add nCol, 4					;increase offset of Col for next column check.
		mov r_ctr, NULL				;resetting row location.
		inc c_ctr					;increment column counter moving to next column for calculations.
		dec edx 					;number of times the columns can safely shift within bounds.
		cmp edx, NULL				;if null it will return out of the procedure.
	jne L00
		pop ctr						;getting back to return address on the stack by releasing ctr.	
		ret							;return to main proc.
Col_LR endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Row_LR UP/DOWN LEFT/RIGHT					    ;;
;; Checks rows Up to down from left to right.		;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Row_LR proc
	XOR eax, eax
	push ctr
	add cLimit, 3					;get the full 20.
	mov ecx, dLimit					;move dlimit left-->right into ecx register.
	mov edx, cLimit					;move cLimit going down a row into edx register.
	lea edi, Ary1					;point at Ary1 (THE MATRIX 20x20).
	L00: 
		mov eax, [edi]				;move value edi is pointing to into eax register.
		dec ctr						;moved one of the four values into eax register (the first value).
	L0:
		add edi, COL				;shift over right one.
		mov ebx, [edi]				;move value edi is pointing to into ebx register.
		imul eax, ebx				;multiply values and store in eax register.
		inc c_ctr					;column counter. (shifting right one location for this numbers position).
		dec ctr						;decrement 4 value counter.
		cmp ctr, NULL				;compare to null.
	jne L0
		cmp BestSum, eax
	jg L1						
		mov BestSum, eax			;move eax register value into BestSum, eax was greater
		mov ebx, [edi]				;moving back into ebx register
		mov ebx, r_ctr				;moving row count into ebx register.
		mov sRow, ebx				;storing value in memory sRow. ("Saved Row").
		mov ebx, c_ctr				;moving column count into ebx register.
		mov sCol, ebx				;storing value in memory sCol. ("Saved Column").
		
		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		sub edi, COL				;shift back one col.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		sub edi, COL				;shift back one col.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		sub edi, COL				;shift back one col.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.		
	L1:
	    mov eax, COL				;move COL (4) into eax register.
		mov ebx, nPos				;move nPos(0) starts at 0 into ebx register.
		add eax, ebx				;add each register COL + nPos.
		mov nPos, eax				;store new value into nPos memory location.
		XOR eax, eax				;clear register eax.
		XOR ebx, ebx				;clear register ebx.

		pop ctr						;getting counter from stack, returns it back to (4).
		push ctr					;push to the stack, so my pops keep giving me (4).
		lea edi, Ary1				;point at first position in Ary1.
		add edi, nPos				;moving right one column, because nPos holds offset of new position.
		
		sub c_ctr, 2				;get offset position(starting position is 0).
		dec ecx						;dec ecx (boundary counter).
		cmp ecx, NULL				;checking to see if at end of bounds.
	jne L00							;return to L00 which puts first value into eax register.
		pop ctr						;releasing ctr so the stack is back on the return address.
		push ctr					;pushing ctr back onto the stack.
		mov ecx, dLimit				;resetting limiter.

		add nPos, 12				;offset by 12 (limit it goes to is 12 off from next row).
		mov ebx, nRow
		lea edi,[Ary1 + ebx] 		;offsetting location by increments of 4 for each column.
		add nRow, 80				;increase by 80.
		inc r_ctr					;increment row counter moving to next row for calculations.
		mov c_ctr, NULL				;resetting column location.
		dec edx 					;number of times the columns can safely shift within bounds.
		cmp edx, NULL				;if null it will return out of the procedure.
	jne L00
		pop ctr						;getting back to return address on the stack by releasing ctr.	
		ret							;return to main proc.
Row_LR endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagonal_UD_LR UP/DOWN LEFT/RIGHT			    ;;
;; Checks diagonally Up to down from left to right. ;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Diagonal_UD_LR Proc
	XOR eax, eax					;zero out register.
	push ctr						;push ctr to the stack.
	mov ecx, dLimit					;move dlimit (down limit) into ecx register.
	mov edx, cLimit					;move cLimit (column lmit) into edx register.
	lea edi, Ary1					;point at Ary1 (THE MATRIX 20x20).
	L00: 
		mov eax, [edi]				;move value edi is pointing to into eax register.
		dec ctr						;moved one of the four values into eax register (the first value).
	L0:
		add edi, ROW				;shift down one.
		add edi, COL				;shift right one.
		mov ebx, [edi]				;add value edi is pointing to into ebx.
		imul eax, ebx				;multiply values and store in eax register.
		inc r_ctr					;row counter.
		inc c_ctr					;column counter.
		dec ctr						;decrement 4 value counter.
		cmp ctr, NULL				;compare to null.
	jne L0
		cmp BestSum, eax			;compare eax register value to BestSum value
	
	jg L1						
		mov BestSum, eax			;move eax register value into BestSum, eax was greater
		mov ebx, [edi]				;moving back into ebx register
		mov ebx, r_ctr				;moving row count into ebx register.
		mov sRow, ebx				;storing value in memory sRow. ("Saved Row").
		mov ebx, c_ctr				;moving column count into ebx register.
		mov sCol, ebx				;storing value in memory sCol. ("Saved Column").

		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		sub edi, ROW				;shift one row up.
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		sub edi, ROW				;shift one row up.
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		sub edi, ROW				;shift one row up
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.
	L1:
	    mov eax, ROW				;move ROW (80) into eax register.
		mov ebx, nPos				;move nPos(0) starts at 0 into ebx register.
		add eax, ebx				;add each register ROW + nPos.
		mov nPos, eax				;store new value into nPos memory location.
		XOR eax, eax				;clear register eax.
		XOR ebx, ebx				;clear register ebx.

		pop ctr						;getting counter from stack, returns it back to (4).
		push ctr					;push to the stack, so my pops keep giving me (4).
		lea edi, Ary1				;point at first position in Ary1.
		add edi, nPos				;moving down 1 row, because nPos holds offset of new position.
		sub r_ctr, 2				;resetting row by 2. (because index is 0).
		sub c_ctr, 3				;resetting col by 2. (because index is 0).
		dec ecx						;dec ecx (boundary counter).
		cmp ecx, NULL				;checking to see if at end of bounds.
	jne L00							;return to L00 which puts first value into eax register.
		pop ctr						;releasing ctr so the stack is back on the return address.
		push ctr					;pushing ctr back onto the stack.
		mov ecx, dLimit				;resetting limiter.

		mov nPos, NULL				;set back to 0.
		mov ebx, nCol				;move nCol into ebx register to tack onto nPos.
		lea edi, [Ary1 + ebx] 		;offsetting location by increments of 4 for each column.
		mov nPos, ebx				;move ebx register value into nPos.
		add nCol, 4					;setup nCol for next column shift.
		mov r_ctr, NULL				;reset row counter.
		inc c_ctr					;increment to the next column right shift.
		dec edx 					;number of times the columns can safely shift within bounds.
		cmp edx, NULL				;if null it will return out of the procedure.
	jne L00
		pop ctr						;getting back to return address on the stack by releasing ctr.	
		ret							;return to main proc.
Diagonal_UD_LR endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagonal_DU_LR DOWN/UP LEFT/RIGHT			    ;;
;; Checks diagonally Down to up from left to right. ;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Diagonal_DU_LR proc		
	XOR eax, eax					;zero out register.
	push ctr						;push ctr to the stack.
	mov r_ctr, 19					;bottom row.
	mov c_ctr, NULL					;bottom position.
	mov ecx, dLimit					;move limit on Up into ecx register.
	mov edx, cLimit					;move climit (column limit) into edx register.
	mov ebx, blRow					;move bottom left row index into ebx register.   
	lea edi, [Ary1 + ebx] 	
	M00:
		mov eax, [edi]				;move value edi is pointing to into eax register.
		dec ctr						;moved one of four values into eax register (the first value).
	M0:
		sub edi, ROW				;subtracting to shift up a row.
		add edi, COL				;adding to shift right a column.
		mov ebx, [edi]				;add value edi is pointing to into ebx.
		imul eax, ebx				;multiply values and store in eax register.
		dec r_ctr
		inc c_ctr
		dec ctr						;decrement counter.
		cmp ctr, NULL				;compare to null.
	jne M0
		cmp BestSum, eax			;compare eax register value to BestSum value.
	
	jg M1
		mov BestSum, eax			;move eax resigter value into BestSum, eax was greater.
		mov ebx, r_ctr				;move r_ctr into ebx register.
		mov sRow, ebx				;store in sRow.
		mov ebx, c_ctr				;move c_ctr into ebx register.
		mov sCol, ebx				;store in sCol.

		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		add edi, ROW				;shift one row up.
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		add edi, ROW				;shift one row up.
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		add edi, ROW				;shift one row up
		sub edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.
	M1:
		mov eax, ROW				;move ROW (80) into eax register.
		neg eax						;change to (-80) in eax register.
		mov ebx, nPos				;store new value into nPos memory location.
		add eax, ebx				;add eax and ebx registers together (stored in eax).
		mov nPos, eax				;move eax into nPos memory location.
		XOR eax, eax				;clear register.
		mov ebx, blRow				;ebx is set back to 1520		

		pop ctr						;pop counter from the stack. resets ctr to 4.
		push ctr					;push counter to the stack.
		lea edi, [Ary1+ebx]			;point at new location.
		add edi, nPos				;shift by nPos.
		add r_ctr, 2				;resetting row by 2. (because index is 0).
		sub c_ctr, 3				;resetting col by 3. (because index is 0).
		dec ecx						;decrement ecx register.
		cmp ecx, NULL				;compare to NULL.
	jne M00
		pop ctr						;pop counter from the stack.
		push ctr					;push counter to the stack.
		mov ecx, dLimit				;set ecx register to dLimit.
		
		mov nPos, NULL				;set back to 0.
		mov ebx, blRow				;reset to starting position (1520)
		add ebx, nCol				;offsetting by increments of 4 in the bottom row.
		mov blRow, ebx				;store new offset value in blRow (i.e. 1524, 1528...etc).
		lea edi, [Ary1 + ebx]		;pointing to next starting position.
		inc c_ctr					;offset by 1, moving start to right shift column.
		mov r_ctr, 19				;offset row counter to bottom row.
		dec edx						;decrement limit counter.
		cmp edx, NULL				;if null it will return out of the procedure.
	jne M00
		pop ctr						;getting back to return address on the stack by releasing ctr.
		ret							;return to main proc.
Diagonal_DU_LR endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagonal_DU_RL DOWN/UP RIGHT/LEFT			    ;;
;; Checks diagonally Down to up from right to left. ;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Diagonal_DU_RL proc
	XOR eax, eax					;zero out register.
	push ctr						;push ctr to the stack.
	mov r_ctr, 19					;bottom row.
	mov c_ctr, 19					;bottom position.
	mov ecx, dLimit					;move limit on Up into ecx register.
	mov edx, cLimit					;move climit (column limit) into edx register.
	mov ebx, brRow					;move bottom right row index into ebx register.   
	lea edi, [Ary1 + ebx] 	
	M00:
		mov eax, [edi]				;move value edi is pointing to into eax register.	
		dec ctr						;moved one of four values into eax register (the first value).
	M0:
		sub edi, ROW				;subtracting to shift up a row.
		sub edi, COL				;adding to shift left a column. (SUBTRACTED FOR RIGHT TO LEFT OFFSET).
		mov ebx, [edi]				;add value edi is pointing to into ebx.
		imul eax, ebx				;multiply values and store in eax register.
		dec r_ctr					;shift left one row.
		dec c_ctr					;shift left one column.
		dec ctr						;decrement counter.
		cmp ctr, NULL				;compare to null.
	jne M0
		cmp BestSum, eax			;compare eax register value to BestSum value.
	
	jg M1
		mov BestSum, eax			;move eax resigter value into BestSum, eax was greater.
		mov ebx, r_ctr				;move r_ctr into ebx register.
		mov sRow, ebx				;store in sRow.
		mov ebx, c_ctr				;move c_ctr into ebx register.
		mov sCol, ebx				;store in sCol.

		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		add edi, ROW				;shift one row up.
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		add edi, ROW				;shift one row up.
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		add edi, ROW				;shift one row up
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.
	M1:
		mov eax, ROW				;move ROW (80) into eax register.
		neg eax						;change to (-80) in eax register.
		mov ebx, nPos				;store new value into nPos memory location.
		add eax, ebx				;add eax and ebx registers together (stored in eax).
		mov nPos, eax				;move eax into nPos memory location.
		XOR eax, eax				;clear register.
		mov ebx, brRow				;ebx is set back to 1520	

		pop ctr						;pop counter from the stack. resets ctr to 4.
		push ctr					;push counter to the stack.
		add r_ctr, 2				;resetting row by 2. (because index is 0).
		add c_ctr, 3				;resetting col by 3. (because index is 0).
		lea edi, [Ary1+ebx]			;point at new location.
		add edi, nPos				;shift by nPos.
		dec ecx						;decrement ecx register.
		cmp ecx, NULL				;compare to NULL.
	jne M00
		pop ctr						;pop counter from the stack.
		push ctr					;push counter to the stack.
		mov ecx, dLimit				;set ecx register to dLimit.
		
		mov nPos, NULL				;set back to 0.
		mov ebx, brRow				;reset to starting position (1596)
		sub ebx, nCol				;offsetting by increments of 4 in the bottom row.
		mov brRow, ebx				;store new offset value in blRow (i.e. 1524, 1528...etc).
		lea edi, [Ary1 + ebx]		;pointing to next starting position.
		dec c_ctr					;decrement column counter for new position in array.
		mov r_ctr, 19				;offset row counter to bottom row.
		dec edx
		cmp edx, NULL				;if null it will return out of the procedure.
	jne M00
		pop ctr						;getting back to return address on the stack by releasing ctr.
		ret							;return to main proc.
Diagonal_DU_RL endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diagonal_UD_RL UP/DOWN RIGHT/LEFT			    ;;
;; Checks diagonally Up to down from right to left. ;;
;; uses edi.										;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Diagonal_UD_RL	proc
	push ctr						;push ctr to the stack.
	mov r_ctr, NULL					;bottom row.
	mov c_ctr, 19					;bottom position.
	mov nCol, NULL					;setting nCol to zero for start will increment by 4 to hold column offset.
	mov eax, COL					;put 80 in eax register.
	mov ebx, ROW					;put 4 in ebx register.
	sub ebx, eax					;gets me from 80 to 76 (starting position needed).
	mov ecx, dLimit					;move limit on Up into ecx register.
	mov edx, cLimit					;move climit (column limit) into edx register.   
	
	lea edi, [Ary1 + ebx] 	
	M00:
		mov eax, [edi]				;move value edi is pointing to into eax register.
		dec ctr						;moved one of four values into eax register (the first value).
	M0:
		add edi, ROW				;adding to shift down a row.
		sub edi, COL				;subtracting to shift right a column. 
		mov ebx, [edi]				;add value edi is pointing to into ebx.
		imul eax, ebx				;multiply values and store in eax register.
		inc r_ctr					;shift left by one row.
		dec c_ctr					;shift left by one column.
		dec ctr						;decrement counter.
		cmp ctr, NULL				;compare to null.
	jne M0
		cmp BestSum, eax			;compare eax register value to BestSum value.
	
	jg M1
		mov BestSum, eax			;move eax resigter value into BestSum, eax was greater.
		mov ebx, r_ctr				;move r_ctr into ebx register.
		mov sRow, ebx				;store in sRow.
		mov ebx, c_ctr				;move c_ctr into ebx register.
		mov sCol, ebx				;store in sCol.

		mov ebx, [edi]
		mov numD, ebx				;store num 4.
		sub edi, ROW				;shift one row up.
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 3.
		mov numC, ebx				;store num 3.
		sub edi, ROW				;shift one row up.
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 2.
		mov numB, ebx				;store num 2.
		sub edi, ROW				;shift one row up
		add edi, COL				;shift one column left.
		mov ebx, [edi]				;get num 1.
		mov numA, ebx				;store num 1.
	M1:
		mov eax, ROW				;move ROW (80) into eax register.
		mov ebx, nPos				;store new value into nPos memory location.
		add eax, ebx				;add eax and ebx registers together (stored in eax).
		mov nPos, eax				;move eax into nPos memory location.

		mov eax, COL				;put 80 in eax register.
		mov ebx, ROW				;put 4 in ebx register.
		sub ebx, eax				;gets me from 80 to 76 (starting position needed).		
		sub ebx, nCol		

		pop ctr						;pop counter from the stack. resets ctr to 4.
		push ctr					;push counter to the stack.
		lea edi, [Ary1+ebx]			;point at new location.
		add edi, nPos				;shift by nPos.
		sub r_ctr,2					;set back to next position.
		add c_ctr,3					;set back to next position.
		dec ecx						;decrement ecx register.
		cmp ecx, NULL				;compare to NULL.
	jne M00
		pop ctr						;pop counter from the stack.
		push ctr					;push counter to the stack.
		mov ecx, dLimit				;set ecx register to dLimit.
		
		mov nPos, NULL				;set back to 0.
		mov eax, COL				;move COL into eax register.
		mov ebx, ROW				;move ROW into ebx register.
		sub ebx, eax				;subtract the registers storing the value in ebx register.
		add nCol, 4					;increasing nCol for offset before subtracting from position.
		sub ebx, nCol				;offsetting by increments of 4 in the bottom row.
		
		lea edi, [Ary1 + ebx]		;pointing to next starting position.
		dec c_ctr					;shift left one column for new position.
		mov r_ctr,NULL				;reset row to start position.
		dec edx
		cmp edx, NULL				;if null it will return out of the procedure.
	jne M00
		pop ctr						;getting back to return address on the stack by releasing ctr.
		ret							;return to main proc.
Diagonal_UD_RL	endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Procedure to TITLE OF PROGRAM.         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Print_Title proc
		lea esi, fline					;format line bunch of ===.
		call PrintToFile				;prints to file.
		lea esi, Msg0					;The program Title.
		call PrintToFile				;prints to file.
		lea esi, fline					;format line bunch of ===.
		call PrintToFile				;prints to file.
		ret								;return to main proc.
Print_Title endp	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FillAry will convert size value from  ;;
;; byte to dword and put into an array.  ;;
;; returns with esi pointing to last     ;;
;; position used in the buffer (BUFF).   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FillAry Proc
	mov ecx, 20							;total character returns. Since 20 x 20 array.
	  L1:
		mov eax, [esi]					;move pointed to value into eax register.	
		cmp al, SPC						;compare al with space.
	 je	foundSpace					    ;looking to see if space was found.
									
		GoOn:
			cmp bl, CR					;checking to see if return character.
	 je	foundCR							;branches to the end of the procedures.

			call ATOI					;call ascii to integer, uses esi push to stack if needed later.
			mov [edi], eax				;move integer into Polygon1 (P1).
			inc valctr
			add edi, 4					;increment edi pointer.
			inc esi						;increment esi pointer, it is pointing to BUFF (the buffer).
		    jmp L1

	 foundSpace:
			inc esi 					;increment buff pointer..
			jmp L1						;branch to L1

	 foundCR:
			inc esi						;increment buff pointer.
			mov bl, 0					;clear bl register.
			dec ecx						;dec ecx register.
			cmp ecx, NULL				;compare to NULL, if not return to L1 branch.
	jne L1
		    ret							;return to main procedure.
FillAry endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedure OutputFileOpenSetup         ;;
;; Opens output file and stores handle   ;;
;; in outfile.                           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OutputFileOpenSetup Proc
		lea edx, outFN				    ;outfile 
		call CreateOutputFile           ;creating output file
		mov outfile, eax			    ;move the handle from eax into outfile to store.
		ret							    ;return to main procedure.
OutputFileOpenSetup endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedure ReadFileIntoBuffer          ;;
;; reads the input file into a buffer    ;;
;; returns to main procedure when done.  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ReadFileIntoBuffer Proc
		lea edx, inFN	                ;move inFN (input file) into edx for input file parameter.
		call OpenInputFile			    ;opening input file.
		mov infile, eax				    ;move the handle from eax into input file.
		mov ecx, 6000				    ;move buffer size into ecx counter.
		lea edx, BUFF		            ;buffer size in edx.
		mov eax, infile				    ;move handle for infile into eax.
		call ReadFromFile			    ;read file into buffer.
	    mov byteCount, eax
		mov eax, infile				    ;moving infile handle into eax.
		call CloseFile				    ;closing input file.
		ret							    ;return to main proc.
ReadFileIntoBuffer endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedure to ASCII to Integer.        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ATOI Proc
	mov eax, 0							;zero out eax register.
	mov ebx, 0							;zero out ebx register.
NextDigit:
		mov bl, [esi]					;move value esi points to into bl   
		cmp bl, '0'						;compare digit to 0 character
	jl getOut							;jump if less than
		cmp bl, '9'						;compare digit to 9 character
	jg getOut							;jump if greater than
		AND bl, 0Fh

	    imul eax, TEN					;multiply eax by 10
	    add eax, ebx					;add ebx register to eax register.
		inc esi							;increment the ptr
jmp NextDigit
	getOut:
		ret								;returns to main proc.
ATOI endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Procedure to Integer to ASCII.         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
ITOA Proc
	mov ebx, TEN						;setting base value for the ascii number.
	NextDigit: 
		mov edx, NULL					;setup for divide
		idiv ebx						;edx ax/ebx
		OR edx, '0'						;converting digit to ASCII by adding 30h or '0'
		dec esi							;decrementing the pointer to get to the next digit  <----goes backwards from LSB to MSB
		mov [esi],dl					;mov dl not location esi is pointing at.
		cmp eax, NULL					;compares eax to 0.
	jne NextDigit
	ret									;returns to main proc.
ITOA endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Procedure to BlankOut Memory.          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BlankOut Proc
	mov al, SPC							;moving a blank to al.
blank:
	mov[esi], al						;point to al.
	inc esi								;increment esi pointer.
	dec ecx								;decrement ecx counter.
	cmp ecx, NULL						;compare ecx to NULL.
jne blank
	ret									;return to main proc.
BlankOut endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedure to print data to file.      ;;
;; uses esi to print characters.         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintToFile Proc
next:
     mov dl, [esi]						;moving value esi points to into dl
     cmp dl, NULL						;comparing to 0.
     je outOfHere
		mov edx, esi					;mov esi into edx.
		mov ecx, 1						;move 1 into ecx.
		mov eax, outfile				;setting eax to handle for outfile.
		call WriteToFile				;calling WriteToFile proc.
		inc esi							;incrementing esi index.
jmp next
	outOfHere:
		ret								;returns to main proc.
PrintToFile endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;-----------END OF PROGRAM--------------;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end main