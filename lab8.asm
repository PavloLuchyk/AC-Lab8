IDEAL			; Директива - тип Асемблера tasm 
MODEL small		; Директива - тип моделі пам’яті 
STACK 1024	; Директива - розмір стеку 

MACRO M_Init ; init macros
    mov ax, @data
    mov ds, ax
    mov es, ax
ENDM M_Init
				
		
DATASEG
	TOPROW EQU 08  
	BOTTOMROW EQU 13
	LEFTCOL EQU 20
	CURRENTROW db 00		
    string db 254

	menu db 0c9h, 25 DUP(0cdh),0bbh			; задаємо саме меню
            db 0bah, 'Show team                ',0bah
            db 0bah, 'Count                    ', 0bah
            db 0bah, 'Beep                     ', 0bah
            db 0bah, 'Exit                     ', 0bah
            db 0c8h, 25 DUP(0cdh),0bch
	PROMPT DB 'To select an item, use <Up/Down Arrow>'
            DB ' and press <Enter>.'
            DB 13, 10, 'Press <Esc> to exit.'
	team_ db "Team 5: Pavlo Luchyk, Yakubov Dmytro, Tajibaev Shamil",10,13,'$' ; дані групи
	

    ;------Константи для функції звуку
    NUMBER_CYCLES EQU 2000
    FREQUENCY EQU 600
    PORT_B EQU 61H
    COMMAND_REG EQU 43H ; Адреса командного регістру 
    CHANNEL_2 EQU 42H ; Адреса каналу 2

	exCode db 0 ; вихідний код
CODESEG

Start:
M_Init
	call clrscr		
	call display_menu  
	interface:
        call wait	
        call clrscr		
        call display_menu		
        cmp CURRENTROW,TOPROW+1		
        je team_show
        cmp CURRENTROW,TOPROW+2
        je expr_count					
        cmp CURRENTROW,TOPROW+3
        je sound					
        cmp CURRENTROW,TOPROW+4
        je exit						
        jmp interface				
	
	team_show:
        mov CURRENTROW, 0			
        call show					
        jmp interface				
	
	expr_count:
        mov CURRENTROW, 0			
        call count				
        jmp interface
	
	sound:
        mov CURRENTROW, 0
        call beep					; створюємо звук
        jmp interface
	
	exit:
        mov ah,4ch					; завершуємо програму
        mov al,[exCode]
        int 21h
;-------------Процедури----------------
	proc clrscr
        push ax 	
        push cx
        push bx
        push dx
        mov ax, 0600h			
        mov bh, 23h				
        mov cx,00				
        mov dx, 184Fh			
        int 10h					; викликаємо функцію очистки
        mov ax,1300h			; задаємо функцію виведення рядка на екран
        mov bx,71h				; колір рядка
        lea bp,[PROMPT]			; вводимо адресу рядка
        mov cx, 78				; довжина рядка
        mov dh,BOTTOMROW+8			
        mov dl, 0				; колонка, де знаходиться перший символ рядка
        int 10h					; викликаємо функцію виводу
        pop dx					; повертаємо значення
        pop bx
        pop cx
        pop ax
        ret
	endp
	
	proc display_menu
        push ax				
        push cx
        push bx
        push dx
        mov ax,1300h			; задаємо функцію виводу рядка
        mov bx,71h				; зажаємо колір рядка
        lea bp,[menu]			; адреса рядка
        mov cx, 27				; його довжина
        mov dh,TOPROW			; координати початку
        mov dl, LEFTCOL
        Q: 
        int 10h					; виклик функції
        add bp,27				; перехід до наступного рядка
        inc dh					; зміщення на рядок на екрані
        cmp dh,BOTTOMROW+1			; поки не дійде до останнього - 
        jne Q					; повторююємо виклик
        pop dx
        pop bx
        pop cx
        pop ax
        ret
	endp
	
	proc wait
	mov CURRENTROW,TOPROW			; задаємо початкови рядок
        w: mov ah, 08h				; задаємо функцію очікування клавіші
        int 21h						; викликаємо її
        cmp al,0					; визначаємо це клавіша відповідає стандартному кодуванню ASCII
        jne skip					; якщо, то переходимо до пункту перевірки таких клавіш
        int 21h						; якщо клавіша відповідає розшареному коду ASCII, визначаємо його
        cmp al,50h					; якщо клавіша - стрілка вниз, переходимо до нижнього рядка
        je up
        cmp al,48h					; якщо стрілка вгору - до попереднього рядка
        je down
	skip:						; якщо ж клавіша з стандартного кодування
        cmp al,1Bh					; якщо це ESC - виходимо з програми
        jne skip2
        mov ah, 4ch
        mov al,[exCode]
        int 21h
	skip2:
        cmp al, 0Dh					; якщо це Enter -  повертаємось в точку виклику даної процедури
        jne w
        ret
	
	up:
        mov bh,CURRENTROW   			; записуємо в регістр поточний рядок
        inc bh						; збільшуємо його номер
        cmp bh,BOTTOMROW				; перевіряємо, чи не виходить він за межі
        jnl zero
        mov CURRENTROW,bh				; задаємо нове значення поточного рядка
        jmp last					; переходимо до його вибору
	
	down:
        mov bh,CURRENTROW				
        dec bh						; так само вибираємо рядок, але зменшуємо його номер
        cmp bh,TOPROW				; перевіряємо чи не виходить він за межі
        jng max
        mov CURRENTROW,bh				; задаємо нове значення
        jmp last
        
	max:
        mov CURRENTROW,BOTTOMROW-1		; при досягненні верхньої межі, задаємо найнижчий рядок
        jmp last
	
	zero:
        mov CURRENTROW,TOPROW+1		; при досягненні нижньої - задаємо верхній рядок
        last:
        push dx						
        push bx
        push ax
        push cx
        mov ax,1300h				; задаємо функцію, яка перемальовує меню, всі параметри аналогічні попереднім
        lea bp,[menu]				
        mov dh, TOPROW
        mov cx, 27
        mov dl, LEFTCOL
        Q1:
        mov bx,71h					; задаємо колір за замовчуванням
        cmp dh,CURRENTROW				; коли доходимо до вибраного рядка, інвертуємо кольори
        jne stateColor
        mov bx,17h
        stateColor:
        int 10h						
        add bp,27
        inc dh
        cmp dh,BOTTOMROW+1
        jne Q1
        pop cx
        pop ax
        pop bx
        pop dx
        jmp w
	endp
	
	proc show
        push ax
        push cx
        push bx
        push dx
        mov ax,1300h			; задаємо функцію виводу рядка
        mov bx,71h				; задаємо колір
        lea bp,[team_]			; задаємо зміщення
        mov cx, 55				; встановлюємо довжину
        mov dh,TOPROW-4			; координати початку
        mov dl, 10
        int 10h					; вивід даних
        pop dx
        pop bx
        pop cx
        pop ax
        ret
	endp

	

	PROC count
        ; Вираз ((a1-a2)*a3*a4+a5)	a1=-1, a2=2, a3=1,	a4=2,	a5=3
		mov al, -1 ; запис а1 до ах
		mov bl, 2 ; записл а2 до bx
		sub al, bl 
		mov bl, 1 ; запис а3 до bx
		imul bl 
		mov bl, 2 ; запис а4 до bl
		imul bl 
		mov bl, 3 ; запис а5 до bl
		add al, bl
		add al, 065h ; переведення у строку 
		mov [ES:0201h], ' ' ; запис виводу до ES
		mov [ES:0202h], ' ' ; запис виводу до ES
		mov [ES:0203h], al ; запис виводу до ES
		mov [ES:0204h], ' ' ; запис виводу до ES
		mov [ES:0205h], ' ' ; запис виводу до ES
		push ax
		push cx
		push bx
		push dx
		mov ax,1300h		
		mov bx,71h			
		lea bp,[ES:0201h]	
		mov cx, 5			
		mov dh,TOPROW-4		
		mov dl, 10				
		int 10h				
		pop dx
		pop bx
		pop cx
		pop ax
		ret
	endp count

	PROC beep
		;Встановлення частоти 440 гц
        ;--- дозвіл каналу 2 встановлення порту В мікросхеми 8255
        IN AL,PORT_B ;Читання
        OR AL,3 ;Встановлення двох молодших бітів
        OUT PORT_B,AL ;пересилка байта в порт B мікросхеми 8255
        ;--- встановлення регістрів порту вводу-виводу
        MOV AL,10110110B ;біти для каналу 2
        OUT COMMAND_REG,AL ;байт в порт командний регістр
        ;--- встановлення лічильника 
        MOV AX,2945 ;лічильник = 1190000/440
        OUT CHANNEL_2,AL ;відправка AL
        MOV AL,AH ;відправка старшого байту в AL
        OUT CHANNEL_2,AL ;відправка старшого байту 
        
        mov cx, 200 
        L1:
            mov bx, cx
            mov  ah,86h
            xor cx, cx
            mov  dx,25000
            int  15h
            mov cx, bx 
        loop L1

        ;--- виключення звуку 
        IN AL,PORT_B ;отримуємо байт з порту В
        AND AL,11111100B ;скидання двох молодших бітів
        OUT PORT_B,AL ;пересилка байтів в зворотному напрямку
        ret
	endp beep
END Start