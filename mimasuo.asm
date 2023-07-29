P4     DATA   0C0H  ; 端口寄存器的地址
P5     DATA   0C8H
P0M1    DATA    0x93    ; 
P0M0    DATA    0x94    ;        
P3M1	DATA	0xB1	; 设置端口模式寄存器的地址
P3M0	DATA	0xB2
P4M1	DATA	0xB3	
P4M0	DATA	0xB4	
P5M1	DATA	0xC9	
P5M0	DATA	0xCA
;*************	IO口定义	**************
HC595_SER      BIT  P4.0	           ;   串行数据输入引脚
HC595_RCLK    BIT  P5.4            ;   锁存时钟
HC595_SRCLK  BIT  P4.3            ;   移位时钟
STACK_P	EQU    0D0H           ;   堆栈开始地址
DIS_BLACK	EQU    10H              ;   消隐的索引值
;*************       本地变量声明	       ***********
LED8	DATA    30H             ;   显示缓冲 30H ~ 37H
disp_index	DATA    38H             ;   显示位索引
INT1_cnt	DATA    39H             ;   测试用的计数变量
second DATA 42H
halfsecond DATA 45H
MOD_123 DATA 40H
KEY_NUM8 DATA 60H
KEY_index DATA 43H
SCANCODE DATA 44H
PSW8 DATA 20H
R_T0 DATA 46H
R_T1 DATA 47H
Fre_WRONG DATA 48H
    ORG	0000H		; reset
	LJMP	Main
	ORG	0003H		; INT0 中断向量
	LJMP	INT0_ISR 
	ORG	0013H		; INT1 中断向量
	LJMP	INT1_ISR 
	ORG  000BH
			AJMP  T0_ISR
	ORG  001BH            ;T1中断向量
           	AJMP  T1_ISR
	ORG	0100H		; 主程序起始地址
Main:  CLR      A
		  MOV   P0M1, A 	;设置为准双向口
 	      MOV   P0M0, A
	      MOV   P3M1, A 	;设置为准双向口
 	      MOV   P3M0, A
	      MOV   P4M1, A 	 
 	      MOV   P4M0, A
	      MOV   P5M1, A 	
 	      MOV   P5M0, A
	      MOV   SP, #STACK_P
	      MOV   disp_index, #0
		MOV R3,#200
		MOV R4,#200
		MOV second,#0
		MOV halfsecond,#0
		MOV PSW8+0,#8
		MOV PSW8+1,#7
		MOV PSW8+2,#6
		MOV PSW8+3,#5
		MOV PSW8+4,#4
		MOV PSW8+5,#3
		MOV PSW8+6,#2
		MOV PSW8+7,#1
		MOV KEY_NUM8+0,#16
		MOV KEY_NUM8+1,#16
		MOV KEY_NUM8+2,#16
		MOV KEY_NUM8+3,#16
		MOV KEY_NUM8+4,#16
		MOV KEY_NUM8+5,#16
		MOV KEY_NUM8+6,#16
		MOV KEY_NUM8+7,#16
		MOV MOD_123,#1
		MOV Fre_WRONG,#0
		MOV   SCANCODE,#00H
		MOV   KEY_index,#0         
   		MOV	R0, #LED8
		MOV R1, #50
		MOV	R2, #8
		MOV  R_T0,  #14H       ;定时次数，每次50ms
		MOV  R_T1,  #14H
          		MOV  TMOD,  #00H ;T1方式0定时
           		MOV  TH1,  #3CH    ;50ms定时初值
           		MOV  TL1,  #0B0H
		SETB  ET1                  ;T1中断允许
		SETB  ET0
				MOV  TMOD,  #00H
				MOV  TH0,  #9EH
				MOV  TL0,  #58H
		
               		SETB  EA                   ;中断总允许
               		SETB  PT1                  ;T1高优先级
					SETB  PT0                  ;T1高优先级
               		SETB  TR1                  ;启动定时
               		SETB  TR0                  ;启动定时
				  SETB	EX1		  ;   INT1允许
				  SETB	EX0	  ;   INT0允许
	              SETB	IT1		  ;   INT1 下降沿中断
				  SETB	IT0		  ;   INT0 下降沿中断
	              SETB	EA		  ;   允许总中断	
                    SETB   PX1                           ;    高优先级
					SETB   PX0                          ;    高优先级

LCALL ClearLoop

Pre_loop1: 	                              ;开机流水灯循环
		
		LCALL   delay_ms1	
	    LCALL   Pre_DispScan1
		MOV A,MOD_123             
		CJNE A,#2,Pre_loop1        ;按下中断后进入下一个状态
	    LJMP Pre_loop2             
					
Pre_loop2:                                                       ;数码管全亮闪烁后2s后进入小数点闪烁状态
	
		LCALL   delay_ms1
		LCALL   Pre_DispScan2
		MOV A,halfsecond
		CJNE A,#4,Pre_loop2
	    LJMP Pre_loop3

Pre_loop3:					;小数点闪烁状态

		LCALL   delay_ms1	
	    LCALL   Pre_DispScan3
		MOV A,MOD_123
		CJNE A,#3,Pre_loop3		;按下中断后进入按键输入状态
	    LJMP Key_loop 
		
Key_loop:
		DJNZ	R1,Key_loop1	
		LCALL   KeyScan
		MOV		R1,#50		;50ms扫描一次
Key_loop1:
		LCALL   delay_ms1		
		LCALL   Key_DispScan		;输出数字
		MOV A,MOD_123
		CJNE A,#4,Key_loop
	    LJMP Indentify

Indentify:
		
		LCALL   delay_ms1
		MOV A,KEY_NUM8+0
		CJNE A,PSW8+0,WRONG
		MOV A,KEY_NUM8+1
		CJNE A,PSW8+1,WRONG
		MOV A,KEY_NUM8+1
		CJNE A,PSW8+1,WRONG
		MOV A,KEY_NUM8+2
		CJNE A,PSW8+2,WRONG
		MOV A,KEY_NUM8+2
		CJNE A,PSW8+2,WRONG
		MOV A,KEY_NUM8+3
		CJNE A,PSW8+3,WRONG
		MOV A,KEY_NUM8+3
		CJNE A,PSW8+3,WRONG
		MOV A,KEY_NUM8+4
		CJNE A,PSW8+4,WRONG
		MOV A,KEY_NUM8+5
		CJNE A,PSW8+5,WRONG
		MOV A,KEY_NUM8+6
		CJNE A,PSW8+6,WRONG
		MOV A,KEY_NUM8+7
		CJNE A,PSW8+7,WRONG
		LJMP RIGHT
		
WRONG:
			MOV KEY_NUM8+0,#16
			MOV KEY_NUM8+1,#16
			MOV KEY_NUM8+2,#16
			MOV KEY_NUM8+3,#16
			MOV KEY_NUM8+4,#16
			MOV KEY_NUM8+5,#16
			MOV KEY_NUM8+6,#16
			MOV KEY_NUM8+7,#16
			LCALL delay_ms1
			LCALL W_DispScan
			MOV A,Fre_WRONG
			CJNE A,#4,GOON
			LJMP CLOSED
GOON:		MOV A,halfsecond
			CJNE A,#6,WRONG
			INC Fre_WRONG
			LJMP Pre_loop1
RIGHT:
			MOV KEY_NUM8+0,#16
			MOV KEY_NUM8+1,#16
			MOV KEY_NUM8+2,#16
			MOV KEY_NUM8+3,#16
			MOV KEY_NUM8+4,#16
			MOV KEY_NUM8+5,#16
			MOV KEY_NUM8+6,#16
			MOV KEY_NUM8+7,#16
			LCALL delay_ms1
			LCALL R_DispScan
			MOV A,halfsecond
			CJNE A,#6,RIGHT
			LJMP Pre_loop1
			
CLOSED:
			LCALL delay_ms1
			LCALL C_DispScan						
			LJMP CLOSED
W_DispScan:
				MOV LED8+0,#0
				MOV LED8+1,#1
				MOV LED8+2,#2
				MOV LED8+3,#3
				MOV LED8+4,#4
				MOV LED8+5,#5
				MOV LED8+6,#6
				MOV LED8+7,#7
				MOV R7,#8

W_NEXT:
			MOV	DPTR, #W_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #W_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, W_NEXT
MOV	disp_index, #0 ; 8位结束回0
RET

R_DispScan:
				MOV LED8+0,#0
				MOV LED8+1,#1
				MOV LED8+2,#2
				MOV LED8+3,#3
				MOV LED8+4,#4
				MOV LED8+5,#5
				MOV LED8+6,#6
				MOV LED8+7,#7
				MOV R7,#8
				
R_NEXT:
			MOV	DPTR, #R_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #R_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, R_NEXT
MOV	disp_index, #0 ; 8位结束回0
RET

C_DispScan:
				MOV LED8+0,#0
				MOV LED8+1,#1
				MOV LED8+2,#2
				MOV LED8+3,#3
				MOV LED8+4,#4
				MOV LED8+5,#5
				MOV LED8+6,#6
				MOV LED8+7,#7
				MOV R7,#8

C_NEXT:
			MOV	DPTR, #C_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #C_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, C_NEXT
MOV	disp_index, #0 ; 8位结束回0
RET

Pre_DispScan1: 
		
		MOV A,second
		
	              MOV	LED8+3, A    
				  
	              MOV	LED8+7, A
				  INC A
				  MOV	LED8+2, A
				  
				  MOV	LED8+6, A
				  INC A
				  MOV	LED8+1, A
				  
				  MOV	LED8+5, A
				  INC A
				  MOV	LED8+0, A
				 
				  MOV	LED8+4, A
				  
	              MOV        R7, #8          ; 2个数码管

Pre_NEXT1:	
			
			MOV	DPTR, #P1_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #P1_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, Pre_NEXT1
MOV	disp_index, #0 ; 8位结束回0
RET
; HC595串行移位输出一个字符

Pre_DispScan2:
MOV A,halfsecond
MOV	LED8+0, A
MOV	LED8+1, A
MOV	LED8+2, A
MOV	LED8+3, A
MOV	LED8+4, A
MOV	LED8+5, A
MOV	LED8+6, A
MOV	LED8+7, A

 MOV        R7, #8          ; 2个数码管

Pre_NEXT2:	
			
			MOV	DPTR, #P2_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #P2_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, Pre_NEXT2
MOV	disp_index, #0 ; 8位结束回0
RET
; HC595串行移位输出一个字符

Pre_DispScan3:

MOV LED8+0,halfsecond
MOV R7,#1

Pre_NEXT3:

MOV	DPTR, #P3_COM   ; 位码表头   
	        MOV	A, disp_index      ;  数码管号
	        MOVC	A, @A+DPTR
	        CPL 	A                        ; 595级联时用的/Q7
	        LCALL	Send_595	; 输出位码
	        MOV	DPTR, #P3_Disp ; 7段码表头
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0               ; 待显示的数
MOVC	A, @A+DPTR
LCALL	Send_595	; 输出段码
CLR	 HC595_RCLK	; 产生锁存时钟
SETB	HC595_RCLK

INC	 disp_index      ; 下一数码管
DJNZ    R7, Pre_NEXT3
MOV	disp_index, #0 ; 8位结束回0
RET

Key_DispScan:       
	              
	              MOV	LED8+0, KEY_NUM8+7
				  MOV	LED8+1, KEY_NUM8+6
				  MOV	LED8+2, KEY_NUM8+5
				  MOV	LED8+3, KEY_NUM8+4
				  MOV	LED8+4, KEY_NUM8+3
				  MOV	LED8+5, KEY_NUM8+2
				  MOV	LED8+6, KEY_NUM8+1
				  MOV	LED8+7, KEY_NUM8+0
 	              MOV        R7, #8
	
Key_NEXT:	
			
			MOV	DPTR, #K_COM   
	        MOV	A, disp_index     
	        MOVC	A, @A+DPTR
	        CPL 	A                      
	        LCALL	Send_595	
	        MOV	DPTR, #K_Disp 
	        MOV	A, disp_index
	        ADD	A, #LED8
	        MOV	R0, A
	        MOV	A, @R0
MOVC	A, @A+DPTR
LCALL	Send_595	
CLR	 HC595_RCLK	
SETB	HC595_RCLK

INC	 disp_index     
DJNZ    R7, Key_NEXT
MOV	disp_index, #0 
RET

Send_595:   MOV   R2, #8
Send_Loop: RLC      A
	                  MOV  HC595_SER, C
	                  CLR    HC595_SRCLK 
                      SETB  HC595_SRCLK  ; 产生移位脉冲
	                  DJNZ  R2, Send_Loop
	                  RET

   KeyScan:
  		SETB P4.6
		MOV P0,#0FFH
		
		MOV P0,#0EFH
		MOV A,P0
		ANL A,#0FH
		ADD A,#0E0H
		CJNE A,#0EFH,ON
		
		MOV P0,#0FFH
		
		MOV P0,#0DFH
		MOV A,P0
		ANL A,#0FH
		ADD A,#0D0H
		CJNE A,#0DFH,ON  
		
		MOV P0,#0FFH
		
		MOV P0,#0BFH
		MOV A,P0
		ANL A,#0FH
		ADD A,#0B0H
		CJNE A,#0BFH,ON
		
		MOV P0,#0FFH
			
		MOV P0,#7FH
		MOV A,P0
		ANL A,#0FH
		ADD A,#70H
		CJNE A,#7FH,ON
		RET
		
		ON:MOV SCANCODE,A
		
			
   KEYLOOP:
		  
		  MOV DPTR,#KEYCODE
		  MOV  A, KEY_index
          MOVC  A, @A+DPTR
          CJNE  A, SCANCODE, NEXTKEY
		  CLR P4.6
		  MOV	A,KEY_index
		  CJNE	A,KEY_NUM8+0, ZUOYI
		  RET
ZUOYI:		  
		  MOV	KEY_NUM8+7,KEY_NUM8+6		
		  MOV	KEY_NUM8+6,KEY_NUM8+5
		  MOV	KEY_NUM8+5,KEY_NUM8+4
		  MOV	KEY_NUM8+4,KEY_NUM8+3
		  MOV	KEY_NUM8+3,KEY_NUM8+2
		  MOV	KEY_NUM8+2,KEY_NUM8+1
		  MOV	KEY_NUM8+1,KEY_NUM8+0
		  MOV	KEY_NUM8+0,KEY_index
          RET
  NEXTKEY:INC KEY_index
	      LJMP KEYLOOP
		
ClearLoop: MOV	@R0, #DIS_BLACK  ;  上电消隐
	              INC	 R0
	              DJNZ	R2,  ClearLoop	
				  RET


delay_ms10: MOV      R7,#50    ;延时50mS子程序
DL1:   MOV      R6,#2
DL2:   MOV      R5,#248

       DJNZ     R5,$

       DJNZ     R6,DL2

       DJNZ     R7,DL1

       RET
	   
delay_ms1: MOV      R7,#100    ;延时1mS子程序

       DJNZ     R7,$

       RET
	   
	   delay_s1:MOV      R7,#10    ;延时1S子程序

DL3:   MOV      R6,#200

DL4:   MOV      R5,#248

       DJNZ     R5,$

       DJNZ     R6,DL4

       DJNZ     R7,DL3

       RET



P1_Disp:DB  08H,10H,20H,01H,02H,04H,08H,10H,20H,01H,02H,04H
		
P1_COM:DB   01H,02H,04H,08H,10H,20H,40H,80H         

P2_Disp:DB 0FFH,00H,0FFH,00H,0FFH,00H,0FFH,00H,0FFH,00H,0FFH,00H

P2_COM:DB 01H,02H,04H,08H,10H,20H,40H,80H

P3_Disp:DB 80H,00H,80H,00H,80H,00H,80H,00H,80H,00H,80H,00H,80H,00H,80H,00H

P3_COM:DB 80H,80H,80H,80H,80H,80H,80H
	
C_Disp:DB 39H,30H,3FH,6DH,79H,0DEH,80H,80H
	
C_COM:DB 01H,02H,04H,08H,10H,20H,40H,80H

W_Disp:DB 79H,31H,31H,3FH,0B1H,80H,80H,80H
	
W_COM:DB 01H,02H,04H,08H,10H,20H,40H,80H

R_Disp:DB 3FH,73H,79H,37H,3FH,73H,79H,37H

R_COM:DB 01H,02H,04H,08H,10H,20H,40H,80H

K_Disp:DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH,77H,7CH,39H,5EH,79H,71H,00H

K_COM: DB 01H,02H,04H,08H
       DB 10H,20H,40H,80H

KEYCODE:DB 0EEH,0EDH,0EBH,0E7H
		DB 0DEH,0DDH,0DBH,0D7H
	    DB 0BEH,0BDH,0BBH,0B7H
		DB 07EH,07DH,07BH,077H

T0_ISR:DJNZ  R_T0,  EXIT          ; 1s未到，退出中断
              MOV  R_T0,  #14H
    
	MOV A,halfsecond
	CJNE A,#6,HALFSECOND_ADD
	MOV halfsecond,#0
	
	EXIT: RETI
	HALFSECOND_ADD:		INC halfsecond  
	
	RETI

T1_ISR: DJNZ  R_T1,  EX1T          ; 1s未到，退出中断
              MOV  R_T1,  #14H
    
	MOV A,second
	CJNE A,#6,SECOND_ADD
	MOV second,#0
	
	EX1T: RETI
	SECOND_ADD:		INC second  
	
	RETI
	
 
INT0_ISR:  SETB  ET1  
			MOV  TMOD,  #00H 
           		MOV  TH1,  #0ECH    
           		MOV  TL1,  #078H
	              RETI	

INT1_ISR:  
			MOV R1,#KEY_NUM8
			MOV halfsecond,#0
			MOV A,MOD_123
			CJNE A,#5,MOD_ADD
			MOV MOD_123,#1
			RETI
			MOD_ADD:INC MOD_123
				  RETI	

 
 END
