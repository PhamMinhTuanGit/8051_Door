; Define LED pins
LED1 BIT P2.0
LED2 BIT P2.1
LED3 BIT P2.2
LED4 BIT P2.3
LED5 BIT P2.4
LED6 BIT P2.5
PIN_ID EQU 35H
ID EQU 32H
TEMP EQU 33H
CNT EQU 34H
; Define LED 7 segment display values
SU MACRO STR
	MOV R1,#0
	MOV DPTR, #STR
	ACALL TRANSMIT_STRING
ENDM


ORG 00H

START:
clr P1.5
clr P1.6
setb P2.7
MOV P0, #0FFH
MOV R7, #1
ACALL UART_SETUP
ACALL Enter
SU MSG_SELECT_MODE
START_1:
JNB P1.2, MAIN
JNB P1.3, ADMIN_VERIFY
Acall delay_100ms
SJMP START_1
MAIN:
;	SU MSG_SELECT_MODE
;	ACALL RECEIVE_CHARACTER
;	MOV CNT, #0
;	CJNE A, #32H, ADMIN_VERIFY
	;ACALL MODE_ENTER_PASSWORD
;	AJMP MODE_ENTER_PASSWORD
	MOV P0, #0
	ACALL MODE_ENTER_PASSWORD
	SJMP MAIN


;Admin verification for changing password
ADMIN_VERIFY:
	MOV CNT, #0
	ACALL ENTER
	SU SCREEN_PASSWORD
	MOV TEMP, #1
ADMIN_VERIFY_NEXT:
	JNB RI,$	
	MOV A, SBUF
	CLR RI
	MOV B, A
	MOV DPTR, #PIN
	MOV A, CNT
	MOVC A, @A+DPTR
	CJNE A, B, ADMIN_VERIFY_FAIL
	INC CNT
	MOV R0, CNT
	CJNE R0, #6, ADMIN_VERIFY_NEXT
	SJMP ADMIN_CORRECT
ADMIN_VERIFY_FAIL:
	MOV TEMP, #0
	INC CNT
	MOV R0, CNT
	CJNE R0, #6, ADMIN_VERIFY_NEXT
	SJMP ADMIN_CORRECT
ADMIN_VERIFY_FAIL_MSG:
	SU INCORRECT_PASS
	ACALL ENTER
	SJMP MAIN
ADMIN_CORRECT:
	MOV A, TEMP
	CJNE A, #0, ADMIN_CORRECT_NEXT
	SJMP ADMIN_VERIFY_FAIL_MSG
ADMIN_CORRECT_NEXT:	
	ACALL ENTER
	SU CORRECT_PASS
	SJMP MODE_SETUP_PASSWORD

;Password setting========================================
MODE_SETUP_PASSWORD:		
	ACALL ENTER					;Xuong dong
	SU SCREEN_MODE_SETUP		;Hien thi len Termianl
	ACALL ENTER					;Xuong dong
	SU SCREEN_ID				;Hien thi len Termianl
	ACALL SELECT_ID				;Goi chuong trinh SELECT_ID
	;ACALL ENTER
	SU SCREEN_PASSWORD			;Hien thi len Termianl
	ACALL SETUP_PASSWORD		;Goi chuong trinh SETUP_PASSWORD
	;SU SCREEN_ENTER_PASSWORD
	AJMP START
	;RET
SETUP_PASSWORD:				;Chuong trinh cai dat mat khau
	MOV CNT,#0
CONTINUE_RECEIVE:
	JNB RI,$
	MOV A,SBUF
	CLR RI
	CJNE A,#0DH,CONT_SETUP_PASSWORD
	SJMP OUT_SETUP_PASSWORD
CONT_SETUP_PASSWORD:
	MOV TEMP,A
	MOV B,ID
	MOV A,#6
	MUL AB
	ADD A,CNT
	ADD A,#46H
	MOV R0, A
	MOV @R0, TEMP
	INC CNT
	SJMP CONTINUE_RECEIVE
OUT_SETUP_PASSWORD:
	AJMP START					;Nhay den nhan START
	
;enter password for entrance==============================
MODE_ENTER_PASSWORD:
	MOV R0, #0
	ACALL ENTER
	SU SCREEN_MODE_ENTER
	SJMP id_enter
	RET
;enter id for entrance
id_enter:
	Acall check
	MOV CNT, #0
	JNB P1.3, pre_main
	sjmp id_enter
check:
	MOV DPTR, #LED_7DOAN	;Move address of LED_7DOAN to DPTR
    ACALL chinh_so			;Call adjust number function, the value eventually stored in R0
    ACALL clear_all_leds    ;Reset LED for privacy
    MOV A, R0               ;Transfer value of R0 to A
	MOV TEMP, R0
    MOVC A, @A+DPTR         ;Get the display code from the table LED_7DOAN
    SETB LED1               ;Turn on LED1
	MOV P0, A               ;Display number
	MOV R4, #0
	Ret
;Pass_display:
;	MOV A, R0
;	MOV B, #6
;	MUL AB
;	add A, R4
;	add A, #46H
;	MOV R1, A
;	MOV A, @R1
;	Acall UART_Transmit
;	inc r4
;	cjne R4, #6, Pass_display
;	RET

	

	
;Clear Leds
clear_r4:
	mov R4, #0
clear_all_leds:
    CLR LED1
    CLR LED2
    CLR LED3
    CLR LED4
    CLR LED5
    CLR LED6
    RET

; Main loop
pre_main:
	JNB P1.3,$
	MOV R7, #1
	MOV A, #0
	mov R4, #0
	MOV R0, #0                 ; Kh?i t?o giá tr? R0 là 0
	ACALL delay_100ms
main_loop:
	JNB P1.3, main_increment   ; Ki?m tra tr?ng thái P1.3, n?u 1 thì tang giá tr? R7
	JNB P1.4, RESET
	SJMP check_1
    SJMP main_loop            ; L?p l?i main_loop
RESET: 
	AJMP START
mocua:
	JNB P2.7, bell
	setb P1.5          ; Ð?t chân P1.5 lên m?c cao
	SU CORRECT_PASS
	ACALL ENTER
    ACALL DELAY_500MS    ; G?i hàm delay 500ms
    ACALL DELAY_500MS    ; G?i hàm delay 500ms
	ajmp START
main_increment:
	JNB P1.3,$
    ACALL delay_100ms
	INC R7 	; Tang giá tr? R7 
    ACALL check_pin
	Mov R0, #0
	CJNE R7, #7, main_loop	  ; N?u R7 không ph?i 7 thì d?i
	Acall mocua						  ; N?u R7 là 7 thì reset v? 1
    sjmp main_loop
main_wait:
    ACALL delay_100ms
	NOP
    sjmp main_loop
bell:
	SU INCORRECT_PASS
	setb P1.6          ; Ð?t chân P1.5 lên m?c cao
    ACALL DELAY_500MS    ; G?i hàm delay 500ms
    ACALL DELAY_500MS    ; G?i hàm delay 500ms
	ajmp START
;7SEG_Display============================================================================
;=========================================================================================
check_1:  
	MOV DPTR, #LED_7DOAN	;Move address of LED_7DOAN to DPTR
    CJNE R7, #1, check_2    ;Check R7, the value of R7 equivalent to the controlled LED 
    ACALL chinh_so			;Call adjust number function, the value eventually stored in R0
    ACALL clear_all_leds    ;Reset LED for privacy
    MOV A, R0               ;Transfer value of R0 to A
    MOVC A, @A+DPTR         ;Get the display code from the table LED_7DOAN
    SETB LED2               ;Turn on LED1
	MOV P0, A               ;Display number
	SJMP main_loop
check_2:
	MOV DPTR, #LED_7DOAN
	CJNE R7, #2, check_3      
    ACALL chinh_so
    ACALL clear_all_leds     
    MOV A, R0                
    MOVC A, @A+DPTR        
    SETB LED2               
    MOV P0, A               
	SJMP main_loop

check_3:
	MOV DPTR, #LED_7DOAN
	CJNE R7, #3, check_4      
    ACALL chinh_so
    ACALL clear_all_leds      
    MOV A, R0              
    MOVC A, @A+DPTR          
    MOV B, #10
	SETB LED2                
    MOV P0, A                
	SJMP main_loop

check_4:
	MOV DPTR, #LED_7DOAN
	CJNE R7, #4, check_5      
    ACALL chinh_so
    ACALL clear_all_leds      
    MOV A, R0                
    MOVC A, @A+DPTR          
    SETB LED2                
	MOV P0, A                
	AJMP main_loop

check_5:
	MOV DPTR, #LED_7DOAN
	CJNE R7, #5, check_6     
    ACALL chinh_so
    ACALL clear_all_leds      
    MOV A, R0               
    MOVC A, @A+DPTR          
    SETB LED2             
    MOV B, #10
	MOV P0, A             
	AJMP main_loop

check_6:
	MOV DPTR, #LED_7DOAN
	ACALL chinh_so
    ACALL clear_all_leds     
    MOV A, R0                
    MOVC A, @A+DPTR         
    SETB LED2               
    MOV P0, A               
	AJMP main_loop
;Adjust number function==============================
chinh_so:
    JNB P1.2, increment  ; Ki?m tra tr?ng thái P1.2
    ACALL delay_100ms
	SJMP chinh_so_exit
increment:
	JNB P1.2,$
    ACALL delay_100ms
	INC R0                   ; Tang giá tr? R0
    CJNE R0, #10, chinh_so_exit  ; N?u R0 không ph?i 10 thì thoát
    MOV R0, #0               ; N?u R0 là 10 thì reset v? 0
	chinh_so_exit:
    NOP
    RET
;Check password function=========================================
check_pin:
	MOV A, R0
	MOV TEMP, A
	MOV B, ID
	MOV A, #6
	MUL AB
	add A, R4
	add A, #46H
	mov R1, A
	MOV A, TEMP
	ADD A, #30H
	MOV B, A
	MOV A, @R1
	CJNE A, B, sai_pin
	Acall r4_inc
	sjmp out_check_pin
sai_pin:
	CLR P2.7
out_check_pin:
	RET
r4_inc:
	inc r4
	cjne r4, #6, chinh_so_exit
	mov r4, #0
	ret
;UART============================================================
;Set up UART
UART_SETUP:						;Initial set up UART
	MOV SCON,#50H				;UART Mode 1 (8bit), REN=1
	MOV TMOD,#20H				;Timer 1 Mode 2, Timer 0 Mode 0
	MOV TH1,#0FDH				;Baud rate = 9600bps w Osc.fred = 11.0592MHz
	;MOV TH1,#0FAH				;Baud rate ~ 9600bps w Osc.fred = 12MHz
	;ORL PCON,#80H
	SETB TR1					;Enable Timer 1
	RET
;select mode function: 1 for setup pass, 2 for enter pass
RECEIVE_CHARACTER:			
	JNB RI,$	;If RI 
	MOV A, SBUF
	CLR RI
	RET
;Truyen ky tu xuong dong den may tinh
ENTER:						
	MOV A,#0DH
	MOV SBUF,A
	JNB TI,$
	CLR TI
	RET
UART_Transmit:
    MOV SBUF, A
    JNB TI, $
    CLR TI
    RET

;Chuong trinh lua chon ID
SELECT_ID:					
	JNB RI,$
	MOV A,SBUF
	CLR RI
	CJNE A,#0DH,CONT_SELECT_ID
	SJMP OUT_SELECT_ID
CONT_SELECT_ID:
	subb A, #48
	MOV ID,A
	SJMP SELECT_ID
OUT_SELECT_ID:
	RET
;Truyen chuoi ky tu tu ROM den may tinh
TRANSMIT_STRING:			
	MOV A,R1
	MOVC A,@A+DPTR
	CJNE A,#47,CONTINUE_TRANSMIT			
	SJMP STOP_TRANSMIT
CONTINUE_TRANSMIT: 
	MOV SBUF,A
	JNB TI,$
	CLR TI
	INC R1
	SJMP TRANSMIT_STRING
STOP_TRANSMIT: 
	RET

; Delay 100ms=====================================================
delay_100ms:
    MOV R2, #250          ; Chu k? l?p ngoài d? t?o 0.1s
outer_loop:
    MOV R1, #250         ; Chu k? l?p bên trong
inner_loop:
    NOP                  ; No Operation (1 chu k? máy)
    DJNZ R1, inner_loop
    DJNZ R2, outer_loop
    RET  
; Hàm delay 500ms
DELAY_500MS:
    MOV R0, #25          ; 25 vòng l?p (m?i vòng ~20ms)
DELAY_LOOP1:
    MOV R1, #250         ; 250 vòng l?p
    MOV R2, #250         ; 250 chu k? máy (tuong duong ~1ms)
INNER_LOOP1:
    DJNZ R2, INNER_LOOP1  ; Gi?m R2, l?p d?n khi R2 = 0
    DJNZ R1, DELAY_LOOP1 ; Gi?m R1, l?p d?n khi R1 = 0
    DJNZ R0, DELAY_LOOP1  ; Gi?m R0, l?p 25 l?n
    RET 	

;DEFINE==========================================================
LED_7DOAN: DB 0C0H, 0F9H, 0A4H, 0B0H, 099H, 092H, 082H, 0F8H, 080H, 090H
PIN: DB "123456"
MSG_SELECT_MODE: DB 'CHOOSE MODE (1-CHANGE PASS or 2-ENTER PASS): /'
CORRECT_PASS: DB "MAT KHAU DUNG/"
INCORRECT_PASS: DB "MAT KHAU SAI/"
SCREEN_ID: DB "USER ID: /"
SCREEN_PASSWORD: DB "MAT KHAU: /"
SCREEN_ENTER_PASSWORD: DB "NHAP MAT KHAU: /"
SCREEN_SELECT_MODE:DB "LUA CHON CHE DO (1-NHAP MAT KHAU, 2-CAI DAT MAT KHAU): /"
SCREEN_MODE_ENTER: DB "CHE DO NHAP MAT KHAU, HAY NHAP ID BANG PHIM BAM /"
SCREEN_MODE_SETUP: DB "CHE DO CAI DAT MAT KHAU /"
SCREEN_ID_NOT_SETUP: DB "ID NAY CHUA DUOC CAI DAT MAT KHAU /"
END
