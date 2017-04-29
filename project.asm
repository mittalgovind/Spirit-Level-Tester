
.model tiny
.data

;___________________________________
; assigning address for counters
; ------------------------------
count1 		db	 3
count2 		dw 	 0
count3		dw	 0
flag 		db	 0
seed 		dw 	 0abbah,0fafah,9876h,8e34h,3847h,9218h,0fadeh,0deafh
;--------------------------------
; Actual and entered word
; -----------------------
randdata 	db	 12	 dup(0)
test_input  db 	 "lkajdhfa"
keyboard_input db 12 dup(0)
randn dw 0
somechar db ?
;assigning port addresses 8255-1
; -------------------------------
porta 			equ 	10h
portb 			equ 	12h
portc 			equ 	14h
command_address equ 	16h
; _______________________________
; assigning port addresses for 8255-2
; -----------------------------------
porta2 equ 20h
portb2 equ 22h
portc2 equ 24h
command_address2 equ 26h
tableau     db        0eeh,0edh,0ebh,0e7h,0deh,0ddh
			db    	  0dbh,0d7h,0beh,0bdh,0bbh,0b7h
			db 		  07eh,07dh,07bh,077h


.code
.startup
		call lcd_init
		;int 3h
; SETTING INTERRUPT
; -----------------
; Interrupt vector number = 70h
; Therefore IP value at 70h*4 = 448
; And CS value at 70h*4 + 2 = 450
; Timeover is the procedure to handle 2 second time over


;cx value will change after every delay function hence declare cx in every function itself
try:	dec count1
			lea si,seed
			add si,count2
			mov dx,[si]
			add count2,2
			call random_in
			mov cx,[randn]
			lea si,seed
			add si,count2
			mov dx,[si]
			add count2,2
			call random_n
			call write_mem
			call delay
			call delay_2000
			call cls
			call port_init
			call port2_init
			;call get_time_start
			call inputfromkeypad
			;call get_time_end
			call comparison
			cmp flag,1
			jz reactiontime
			cmp count1,0
			jnz try
			jz  affirmative

affirmative: 	;call buzzer
		mov al,00000001b
		out porta2,al
		mov al,00000000b
		out portb2,al
		call cls
		call write_affirmative
		call delay_2000
		call cls
		jmp eop	

reactiontime: 
		call write_nd
		call cls

		mov al,00000000b
		out portb2,al

		;display reaction time on lcd
		call delay_2000
		call delay_2000
		call delay_2000
		call delay_2000
		call delay_2000
		jmp eop

inputfromkeypad proc near

		mov al,00000001b
		out portb2,al
; counter 3 used for randomized counter can hold any initial value
; ----------------------------------------------------------------
mov 		cx,12
lea 		di,keyboard_input
mov 		al,00h
cl0:		stosb
			loop cl0
mov 		al,0
lea 		di,count3
			stosb
mov          al,88h
out         command_address,al
mov         al,0ffh
out         portb,al
; control word for counter0-mode2
; control word for counter 1- mode2
; control word for counter2 - mode0
; loading words to counters
; -------------------------
; cascaded counter 0 and 1 count till 2 seconds
; input frequency to clock = 5 MHZ
; output frequency = 0.5HZ
; therefore counter 0 loaded with 10000 = 2710h and counter1 with 1000 = 03E8
; to give final N factor of 10^(7) thus reducing frequency to 0.5 hz
; --------------------------------------------------------------------------
x0:        mov            al,00h
out            portc,al
x1:        in           al, portc
and            al,0f0h
cmp            al,0f0h
jnz            x1
call        d20ms
mov            al,00h
out            portc ,al
x2:        in           al, portc
and            al,0f0h
cmp            al,0f0h
jz            x2
call        d20ms
mov            al,00h
out            portc ,al
in           al, portc
and            al,0f0h
cmp            al,0f0h
jz            x2
mov            al, 0eh
mov            bl,al
out            portc,al
in            al,portc
and            al,0f0h
cmp            al,0f0h
jnz            x3
mov            al, 0dh
mov            bl,al
out            portc ,al
in            al,portc
and            al,0f0h
cmp            al,0f0h
jnz            x3
mov            al, 0bh
mov            bl,al
out            portc,al
in            al,portc
and            al,0f0h
cmp            al,0f0h
jnz            x3
mov            al, 07h
mov            bl,al
out            portc,al
in            al,portc
and            al,0f0h
cmp            al,0f0h
jz            x2
x3:         or            al,bl
mov            cx,0fh
mov            di,00h
x4:       cmp  al,tableau[di]
jz            x5
inc            di
loop        x4
;x5:        lea          bx, table_d
;mov         al, cs:[bx+di]
;not         al
;out         portb,al
x5:		mov ax,di
		and ax,000ffh
		cmp al,0ah
		jae atofkey
		add al,48
		jmp display

atofkey:	add al,55
			jmp display

display:	;lea 	di,somechar
			;stosb
		lea di,keyboard_input
		add di,count3
		stosb
		inc count3
		call 	write_mem_kp
		mov bx,count3
		cmp bx,randn
		jz 	donewithinput
		jmp 	x0

d20ms:    ;mov              cx,2220 ; delay generated will be approx 0.45 secs
			mov 		cx,220
xn:        loop          xn

donewithinput:
;jmp            x0
mov al,00000000b
out portb2,al
ret
inputfromkeypad endp

comparison proc near

	lea si,randdata
	lea di,keyboard_input
	mov cx,randn

c1:		mov al,[si]
		mov bl,[di]
		cmp al,bl
		jnz eoproc
		inc si
		inc di
		loop c1

cmp 	cx,0
		jz equal
		;is this really required?

equal:	mov flag,1
		jmp eoproc

eoproc:

ret
comparison endp

write_mem_kp proc near 
	;call port_init
	lea di,keyboard_input
	call cls
	mov cx,count3
	;mov cl,4
	;mov ch,0
	mov si,cx
inp11:	mov al, [di] 
		call datwrit ;issue it to lcd
		;trying to reduce the delay here
		call delay ;wait before issuing the next character
		;call delay ;wait before issuing the next character
		inc di
		;int 3h
		dec si
		jnz inp11
		ret
write_mem_kp endp
	
write_mem proc near 
	lea di,randdata
	call cls
	mov cx,randn
	;mov cl,4
	;mov ch,0
	mov si,cx
x10:mov al, [di] 
	call datwrit ;issue it to lcd
	call delay ;wait before issuing the next character
	call delay ;wait before issuing the next character
	inc di
	;int 3h
	dec si
	jnz x10
	ret
write_mem endp

datwrit proc
	push dx  ;save dx
	mov dx,porta  ;dx=port a address
	out dx, al ;issue the char to lcd
	mov al, 00000101b ;rs=1, r/w=0, e=1 for h-to-l pulse
	mov dx, portb ;port b address
	out dx, al  ;make enable high
	mov al, 00000001b ;rs=1,r/w=0 and e=0 for h-to-l pulse
	out dx, al
	pop dx
	ret
datwrit endp ;writing on the lcd ends 

;delay in the circuit here the delay of 20 millisecond is produced
delay proc
	mov cx, 1325 ;1325*15.085 usec = 20 msec
	w1: 
		nop
		nop
		nop
		nop
		nop
	loop w1
	ret
delay endp

;-------------------------------------------------------------------------------

;delay in the circuit here the delay of 2000 millisecond is produced
delay_2000 proc
	mov cx,2220
	t1: 
	loop t1
	ret
delay_2000 endp

;random no generator, value of 'n' is in cx, dx value should also be initialized with a different seed everytime

random_in proc
	lea di,randn
	mov ax,dx
	mov bx,31
	mul bx
	add ax,13
	mov bx,19683
	div bx
	mov ax,dx
	mov cl,07h
	and ax,00ffh
	div cl
	mov al,ah
	add al,6
	stosb
	ret
random_in endp
	


random_n proc
	mov cx,randn
	lea di,randdata
r1:	mov ax,dx
	mov bx,31
	mul bx
	add ax,13
	mov bx,19683
	div bx
	mov bx,dx
	and bx,000fh
	mov al,bl
	cmp al,0ah
	jae atof
	add al,48
	jmp store

atof:	add al,55
		jmp store

store:	stosb	
		loop r1
		ret
random_n endp

port_init proc near
	mov al,10001000b
	out command_address,al
	ret
port_init endp

lcd_init proc near
	mov al, 38h ;initialize lcd for 2 lines & 5*7 matrix
	call comndwrt ;write the command to lcd
	call delay ;wait before issuing the next command
	call delay ;this command needs lots of delay
	call delay
	mov al, 0eh ;send command for lcd on, cursor on	
	call comndwrt
	call delay
	mov al, 01  ;clear lcd
	call comndwrt	
	call delay
	mov al, 06  ;command for shifting cursor right
	call comndwrt
	call delay
	ret
lcd_init endp

cls proc 
	mov al, 01  ;clear lcd
	call comndwrt
	call delay
	call delay
	ret
cls endp

comndwrt proc ;this procedure writes commands to lcd
	mov dx, porta
	out dx, al  ;send the code to port a
	mov dx, portb 	
	mov al, 00000100b ;rs=0,r/w=0,e=1 for h-to-l pulse
	out dx, al
	nop
	nop	
	mov al, 00000000b ;rs=0,r/w=0,e=0 for h-to-l pulse
	out dx, al
	ret
comndwrt endp	

write_affirmative proc near
	call cls
	mov al, 'd' ;display ‘d’ letter
	call datwrit 
	call delay 
	call delay 
	mov al, 'r' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'u' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'n' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'k' 
	call datwrit 
	call delay 
	call delay 
	ret
write_affirmative endp

write_nd proc near
	call cls
	mov al, 'n' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'o' 
	call datwrit 
	call delay 
	call delay 
	mov al, 't' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'd' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'r' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'u' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'n' 
	call datwrit 
	call delay 
	call delay 
	mov al, 'k' 
	call datwrit 
	call delay 
	call delay 
	ret
write_nd endp

port2_init proc near

	mov al,10001001b
	out command_address2,al

	mov al,00000000b
	out porta2,al

	mov al,00000000b
	out portb2,al

	ret
port2_init endp

eop:

.exit
end