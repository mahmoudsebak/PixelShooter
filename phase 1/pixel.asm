include 'pixel.inc'

.MODEL huge
.STACK 64        
                    
.DATA
;wall paper
wallpaper db   "                  _          _       _                 _                        "
          db   "                 (_)        | |     | |               | |                       "
          db   "            _ __  ___  _____| |  ___| |__   ___   ___ | |_ ___ _ __             "
          db   "           | '_ \| \ \/ / _ \ | / __| '_ \ / _ \ / _ \| __/ _ \ '__|            "
          db   "           | |_) | |>  <  __/ | \__ \ | | | (_) | (_) | ||  __/ |               "
          db   "           | .__/|_/_/\_\___|_| |___/_| |_|\___/ \___/ \__\___|_|               "
          db   "           | |                                                                  "
          db   "           |_|                                                                  ",'$'
 
;bullets 
xBullets  dw  100 DUP(0)
yBullets  dw  100 DUP(0)
BDir      dw  100 DUP(0)      
;obstacles
Obstaclehealth dw 100 dup(100)
ObstacleXposition dw 100 dup(0) 
Obstacleyposition dw 100 dup(0)

BNUM      dw  0   ;bullets number
xtemp     dw  ?  
ytemp     dw  ? 
Ocolor    equ  7   ;obstacle color 

Auxulary  dw 10 dup('0')
temp dw ?
x dw 3h
y dw 221d
;time variables 
Display db ?,?,'$'
currenttime db ?
timetodisplay db 60 
;menu vars
mes1 db 'Start chatting ','$'
mes2 db 'Start game ','$'
mes3 db 'End game','$'
winMes db ' won','$'
mes6 db 'Draw :)','$' 
;players name
msg0 db 'All names should start with a letter $'
msg1 db 'Enter First Player Name:$'
msg2 db 'Enter Second Player Name:$'
FirstPName  db  16,?,16 dup('$')
SecondPName db  16,?,16 dup('$')
;positions and constants
PxWindowWidth equ 320
PxWindowLength equ 200
TxWindowWidth equ 40
TxWindowLength equ 25
cannonWidth equ 5*PxWindowWidth/320  ;x
cannonLength equ 3*PxWindowLength/200  ;y
tankWidth equ 2*cannonWidth
tankLength equ 3*cannonLength
lBarrageX equ 3*PxWindowWidth/8
rBarrageX equ 5*PxWindowWidth/8
TopLineY equ PxWindowLength/10
BottomLineY equ 4*PxWindowLength/5
leftLineX equ 0
rightLineX equ PxWindowWidth-1 
bwidth     equ 7
bheight    equ 3
;scan codes
w equ 11h         
a equ 1Eh
s equ 1Fh
d equ 20h 
up equ 48h
left equ 4bh
down equ 50h
right equ 4dh 
lfireb db 71h ;'Q' ASCII code 
rfireb db 02fh;'/' ASCII code 
tempa dw ?
tempb dw ?
counter dw ?
rTankX dw ?  ;right tank x position (upper left x of its cannon)
rTankY dw ?   ;upper y of the cannon
lTankX dw ?   ;left tank x position (upper right x of its cannon)
lTankY dw ?

tempX dw ?
tempY dw ? 
state db ?

rectempx dw ?
rectempy dw ?
;Health bars
lhealthbarx dw 0003d,0017d,0031d,0045d,0059d,0073d,0087d,0101d
rhealthbarx dw 0209d,0223d,0237d,0251d,0265d,0279d,0293d,0307d
rcurrentbar dw 8
lcurrentbar dw 8  
;lines and barrages
horizontalLinesY dw 0, ToplineY, BottomLineY
verticalLinesX dw leftLineX, lBarrageX, rBarrageX, rightLineX
mainmenuresult dw ? 
.code
main proc far
    mov ax, @data 
    mov ds, ax
    
    mov ax, 0003h
    int 10h
    call drawWallpaper
    
    call takeNames
    
    menu:    
    call drawMenu
    cmp mainmenuresult,1
    jz exitGame
    cmp mainmenuresult,2
    jz exitGame
    
    startGame:
    ;initilization 
    call clearBullets
    mov timetodisplay,60d
    mov lcurrentbar,8
    mov rcurrentbar,8 
    mov rTankX , PxWindowWidth-tankWidth-cannonWidth-10  ;right tank x position (upper left x of its cannon)
    mov rTankY , (BottomLineY-TopLineY)/2   ;upper y of the cannon
    mov lTankX , tankWidth+cannonWidth+10   ;left tank x position (upper right x of its cannon)
    mov lTankY , (BottomLineY-TopLineY)/2
    ;graphics mode
    mov ah, 0
    mov al, 13h
    int 10h
    ;set time to current time
    mov ah,2ch
    int 21h
    mov currenttime,dh ;get current time 
    call prepareObstacles
    gameLoop:
    call clearScreen

    call drawLines
    call DRAWOBSTACLES
    call drawLtank
    call drawRtank
       
    ;take input
    mov ah, 1
    int 16h
    jz cont
     
    lUp:       
    cmp ah, w 
    jnz lDown 
    call flush  
        ;check if the area where the tank move is black
        ;upper right point of the cannon 
        dec lTankY  
        check lTankX, lTankY, state, 0 
        inc lTankY
        cmp state, 1    
        jnz cont
        ;upper right point of the tank
        sub lTankY, cannonlength+1
        sub lTankX, cannonWidth
        check lTankX, lTankY, state, 0
        add lTankY, cannonlength+1
        add lTankX, cannonWidth 
        cmp state, 1
        jnz cont
        ;upper left point of the tank 
        sub lTankY, cannonLength+1
        sub lTankX, tankWidth+cannonWidth
        check lTankX, lTankY, state, 0
        add lTankY, cannonLength+1      ;return original value
        add lTankX, cannonWidth+tankWidth
        cmp state, 1
        jnz cont 
    dec lTankY
    jmp cont
    
    lDown:    
    cmp ah, s 
    jnz lRight
    call flush
        ;lower right point of the cannon
        add lTankY, cannonLength+1
        check lTankX, lTankY, state, 0
        sub lTankY, cannonLength+1
        cmp state, 1
        jnz cont
        ;lower right point of the tank
        add lTankY, cannonLength*2+1  
        sub lTankX, cannonWidth
        check lTankX, lTankY, state, 0
        sub lTankY, cannonLength*2+1  
        add lTankX, cannonWidth
        cmp state, 1    
        jnz cont               
        ;lower left point of the tank
        sub lTankX, tankWidth+cannonWidth
        add lTankY, cannonLength*2+1
        check lTankX, lTankY, state, 0   
        add lTankX, tankWidth+cannonWidth
        sub lTankY, cannonLength*2+1
        cmp state, 1
        jnz cont
    inc lTankY
    jmp cont
    
    lRight:    
    cmp ah, d
    jnz lLeft 
    call flush        
        ;upper right point of the tank
        sub lTankX, cannonWidth-1
        sub lTankY, cannonLength
        check lTankX, lTankY, state, 0
        add lTankX, cannonWidth-1
        add lTankY, cannonLength
        cmp state, 1
        jnz cont 
        ;upper right point of the cannon
        inc lTankX
        check lTankx, lTankY, state, 0
        dec lTankX 
        cmp state, 1    
        jnz cont
        ;lower right point of the cannon
        inc lTankX
        add lTankY, cannonLength
        check lTankx, lTankY, state, 0
        dec lTankX
        sub lTankY, cannonLength 
        cmp state, 1    
        jnz cont
        ;lower right point of the tank
        sub lTankX, cannonWidth-1
        add lTankY, cannonLength*2
        check lTankX, lTankY, state, 0
        add lTankX, cannonWidth-1
        sub lTankY, cannonLength*2
        cmp state, 1
        jnz cont
    inc lTankX
    jmp cont
    
    lLeft: 
    cmp ah, a
    jnz lshoot  
    call flush 
        ;upper left point of the tank
        sub lTankX, tankWidth+cannonWidth+1
        sub lTankY, cannonLength 
        check lTankX, lTankY, state, 0
        add lTankX, tankWidth+cannonWidth+1
        add lTankY, cannonLength
        cmp state, 1    
        jnz cont
        ;lower left point of the tank
        sub lTankX, tankWidth+cannonWidth+1
        add lTankY, cannonLength*2
        check lTankX, lTankY, state, 0 
        add lTankX, tankWidth+cannonWidth+1
        sub lTankY, cannonLength*2
        cmp state, 1    
        jnz cont
    dec lTankX
    jmp cont

    lshoot:             
    cmp al, lfireb 
    jnz rUp
    call flush
    pusha
    mov bx,ltankx
    mov xtemp,bx 
    mov cx,ltanky 
    mov ytemp,cx 
    popa
    call ADDBULLET 
    jmp cont
    
    rUp:    
    cmp ah, up
    jnz rDown 
    call flush 
        ;upper left point of the cannon
        dec rTankY
        check rTankX, rTankY, state, 0
        inc rTankY 
        cmp state, 1    
        jnz cont 
        ;upper left point of the tank
        sub rTankY, cannonLength+1
        add rTankX, cannonWidth
        check rTankx, rTankY, state, 0
        add rTankY, cannonLength+1
        sub rTankX, cannonWidth
        cmp state, 1
        jnz cont 
        ;upper right point of the tank
        sub rTankY, cannonLength+1
        add rTankX, cannonWidth+tankWidth
        check rTankx, rTankY, state, 0
        add rTankY, cannonLength+1
        sub rTankX, cannonWidth+tankWidth
        cmp state, 1
        jnz cont
    dec rTankY 
    jmp cont 
    
    rDown:    
    cmp ah, down
    jnz rRight
    call flush
        ;lower right point of the cannon
        add rTankY, cannonLength+1  
        check rTankX, rTankY, state, 0 
        sub rTankY, cannonLength+1
        cmp state, 1    
        jnz cont 
        ;lower right point of the tank
        add rTankX, cannonWidth
        add rTankY, cannonLength*2+1
        check rTankX, rTankY, state, 0
        sub rTankX, cannonWidth
        sub rTankY, cannonLength*2+1
        cmp state, 1
        jnz cont
        ;lower left point of the tank
        add rTankX, cannonWidth+tankWidth
        add rTankY, cannonLength*2+1
        check rTankX, rTankY, state, 0
        sub rTankX, cannonWidth+tankWidth
        sub rTankY, cannonLength*2+1
        cmp state, 1
        jnz cont
    inc rTankY 
    jmp cont
    
    rRight:
    cmp ah, right
    jnz rLeft 
    call flush
        ;upper right point of the tank
        add rTankX, cannonWidth+tankWidth+1
        sub rTankY, cannonLength 
        check rTankX, rTankY, state, 0
        sub rTankX, cannonWidth+tankWidth+1
        add rTankY, cannonLength
        cmp state, 1    
        jnz cont 
        ;lower right point of the tank
        add rTankX, cannonWidth+tankWidth+1
        add rTankY, cannonLength*2 
        check rTankX, rTankY, state, 0
        sub rTankX, cannonWidth+tankWidth+1
        sub rTankY, cannonLength*2
        cmp state, 1    
        jnz cont
    inc rTankX 
    jmp cont

    rLeft:         
    cmp ah, left
    jnz rshoot 
    call flush 
        ;upper left point of the cannon
        dec rTankX
        check rTankX, rTankY, state, 0
        inc rTankX
        cmp state, 1    
        jnz cont       
        ;upper left point of the tank
        sub rTankY, cannonLength
        add rTankX, cannonWidth-1
        check rTankX, rTankY, state, 0
        add rTankY, cannonLength
        sub rTankX, cannonWidth-1
        cmp state, 1
        jnz cont
        ;lower left point of the tank 
        add rTankY, cannonLength*2
        add rTankX, cannonWidth-1
        check rTankX, rTankY, state, 0
        sub rTankY, cannonLength*2
        sub rTankX, cannonWidth-1
        cmp state, 1
        jnz cont
        ;lower left point of the cannon
        dec rTankX
        add rTankY, cannonLength
        check rTankX, rTankY, state, 0
        inc rTankX
        sub rTankY, cannonLength
        cmp state, 1    
        jnz cont 
    dec rTankX
    jmp cont
    
    
    rshoot:    
    call flush     
    cmp al, rfireb
    jnz cont
    pusha
    mov bx,rtankx
    mov xtemp,bx
    sub xtemp,bwidth
    ;bullet width
    mov cx,rtanky 
    mov ytemp,cx
    popa
    call ADDBULLET


    cont:
    cmp lcurrentbar,0
    jz rwin
    cmp rcurrentbar,0
    jz lwin 
    call DrawHealthBar     
    call DrawBullets
    pusha
    mov cx,2
    looop:
    call MoveBullets   
    loop looop
    popa
    call timer 
    ;check who won
    cmp timetodisplay,0ffh
    jz checkwinning
    continue:         
    call wait
    jmp gameLoop
    
    checkwinning:
    mov di,lcurrentbar
    
    cmp di,rcurrentbar                
    jb rwin
    cmp di,rcurrentbar                
    je draw
    
    lwin: 
    call clearScreen 
    DisplayMessage 0a0eh,FirstPname+2
    DisplayMessage 0c0eh,winMes
    ;wait for any key press
    Sebak:mov ah,0h
    int 16h
    cmp al,0dh
    jnz sebak 
    jmp menu
    
     
    rwin:
    call clearScreen
    DisplayMessage 0a0eh,SecondPname+2
    DisplayMessage 0c0eh,winMes
    ;wait for any key press
    Sebak2:mov ah,0h
    int 16h
    cmp al,0dh
    jnz sebak2 
    jmp menu
    
    draw:
    call clearScreen
    DisplayMessage 0a0eh,mes6
    ;wait for any key press
    Sebak3:mov ah,0h
    int 16h
    cmp al,0dh
    jnz sebak3 
    jmp menu
    
    
    exitGame: 
    mov ax, 0003h
    int 10h
    mov ah, 4ch
    int 21h
main endp         

clearScreen proc  
    pusha
    mov ax, 0600h
    mov bh, 00h
    mov cx, 0
    mov dl, TxWindowWidth-1
    mov dh, TxWindowLength-1
    int 10h 
    popa
    ret
clearScreen endp     

TakeNames proc 
    pusha
    again:
    pusha
    mov ax,0600h 
    mov bh,07 
    mov cx,0 
    mov dx,184FH 
    int 10h 
    popa        
    ;move cursor to 0,0
    mov ah,2
    mov bh,0
    mov dx,0h
    int 10h 
    ;view head Message
    mov ah, 9
    mov dx, offset msg0 
    int 21h
    ;move cursor to 0,2
    mov ah,2
    mov bh,0
    mov dx,0200h
    int 10h 
    ;view First Message
    mov ah, 9
    mov dx, offset msg1 
    int 21h
    ;take first player name
    mov ah,0AH
    mov dx,offset FirstPName 
    int 21h
      
    mov al,FirstPName[2]
    cmp al,41h
    jb  again
    cmp al,5ah
    ja  check
    jmp forward
    check: cmp al,61h
           jb  again
           cmp al,7ah
           ja  again
           
    forward:
    ;second name
    ;move cursor to 0,4
    mov ah,2
    mov bh,0
    mov dx,0400h
    int 10h 
    ;view second Message
    mov ah, 9
    mov dx, offset msg2 
    int 21h
    ;take second player name
    mov ah,0Ah
    mov dx,offset SecondPName 
    int 21h
      
    mov al,SecondPName[2]
    cmp al,41h
    jb  again
    cmp al,5ah
    ja  check1
    jmp forward1
check1: cmp al,61h
       jb  again
       cmp al,7ah
       ja  again
       
forward1:  
    popa
    ret
TakeNames ENDP

drawRtank proc 
    drawRect RTankX, RTankY, cannonWidth, cannonLength, 01h
    mov ax, RTankX
    add ax, cannonWidth
    mov bx, RTankY
    sub bx, cannonLength
    mov tempX, ax
    mov tempY, bx
    drawRect tempX, tempY, tankWidth, tankLength, 01h 
    ret
drawRtank endp

drawLtank proc     
    mov ax, lTankX
    sub ax, cannonWidth
    mov tempX, ax
    drawRect tempX, lTankY, cannonWidth, cannonLength, 01h
    mov ax, lTankX
    sub ax, tankWidth + cannonWidth
    mov bx, lTankY
    sub bx, cannonLength
    mov tempX, ax
    mov tempY, bx
    drawRect tempX, tempY, tankWidth, tankLength, 01h
    ret 
drawLtank endp


DrawLines proc 

	mov al,0fh
	mov ah,0ch
    mov dx,0   ;row
    
    ;horizontal lines 
    mov si, 0 
    horizontal:
        mov cx, 0
        mov dx, horizontalLinesY[si]
        hline:
            int 10h
            inc cx
            cmp cx,PxwindowWidth
            jnz hline     
        add si, 2
        cmp si, 6
        jnz horizontal
    
    mov si, 0    
    vertical:
        mov dx, 0
        mov cx, verticalLinesX[si]
        vline:
            int 10h
            inc dx
            cmp dx, bottomLineY
            jnz vline
        add si, 2
        cmp si, 8
        jnz vertical 
	mov dx,0 
    ret
DrawLines endp

flush proc 
    mov ah, 0
    int 16h   
    ret
flush endp

wait proc
    waitForNewVR:
    mov dx, 3dah
    
    ;Wait for bit 3 to be zero (not in VR).
    ;We want to detect a 0->1 transition.
    _waitForEnd:
    in al, dx
    test al, 08h
    jnz _waitForEnd
    
    ;Wait for bit 3 to be one (in VR)
    _waitForNew:
    in al, dx
    test al, 08h
    jz _waitForNew
    ret
wait endp
timer proc
        pusha
        mov al,timetodisplay
    	aam
    	mov display[0],ah
    	add display[0],'0'
    	mov display[1],al
    	add display[1],'0'
    	
    	mov ah,2
    	mov bh,0
    	mov dx,0113h
    	int 10h
    	
    	
        mov ah,9
        mov dx,offset display
        int 21h
         
        mov ah,2ch
    	int 21h
    	cmp dh,currenttime
    	jnz go
    	jmp texit
    go: dec timetodisplay
        mov currenttime,dh        
    texit:
        popa    
        ret
timer endp  
drawMenu proc    ;0: Start game 1:End game 2:Chatting
        mov ah, 0
        mov al, 13h
        int 10h
        DisplayMessage 0a0dh,mes1 
        DisplayMessage 0c0dh,mes2
        DisplayMessage 0e0dh,mes3
        ;move cursor to move between choices
	    mov dh,0ah
	    mov bx,0
	    mov cx,0a0bh 
	    mov si,0a0bh
	    
l20:    mov dx,cx
        mov ah,2
        int 10h 
        
	    mov ah,2
	    mov dl,00h
	    int 21h
	    
        mov dx,si
        mov ah,2
        int 10h
        
	    mov ah,2
	    mov dl,10h
	    int 21h 
	    
	    mov dl,0bh
	    mov si,dx
	     
	    
        ;L2: 
        mov ah,0 
	    int 16h 
	    ;jz l2
        cmp ah,50h
        jz Down1
        cmp ah,48h
        jz up1 
        cmp ah,1ch
        jz Enter1

UP1:    cmp dh,0ah
        ja up2
        jmp l20         
UP2:    mov cx,dx
        sub dh,2 
        mov si,dx
        jmp l20
Down1:   cmp dh,0eh
        jb down2
        jmp l20         
Down2:  mov cx,dx
        add dh,2
        mov si,dx
        jmp l20  
Enter1: cmp si,0c0bh
        jz enter2
        cmp si,0e0bh
        jz enter3  
        ;cmp si,0a11h
;        jz enter4
        jmp l20
Enter2:	  
         mov mainmenuresult,0
         ret
Enter3:  
         mov mainmenuresult,1 
;Enter4:  
;         mov mainmenuresult,2
         ret
drawMenu ENDP 
DRAWOBSTACLES  proc 
    pusha
    mov si,offset obstaclexposition
    mov di,offset obstacleyposition
    mov bx,offset obstaclehealth
    cmp [si],0
    jz leave 
    loop123: 
    pusha
    mov ax,[si]
    mov bx,[di]
    mov rectempx,ax
    mov rectempy,bx
    drawrect rectempx,rectempy,30,30,ocolor
    popa
    add si,2
    add di,2
    cmp [si],0
    jnz loop123
leave:popa
    ret
DRAWOBSTACLES  ENDP



DrawHealthBar proc 
    
    cmp lcurrentbar,0
    jz k
    pusha 
    mov di,lcurrentbar 
    add di,di 
    mov si,0
lHealthBars:
    pusha
    DRAWRECT lhealthbarx[si],2,9,16,2
    popa
    inc si 
    inc si
    cmp si,di
    jnz lHealthBars  
    ;popa
    ;pusha
    cmp rcurrentbar,0
    jz k
    mov di,rcurrentbar
    add di,di
    mov si,0
rHealthBars: 
    pusha
    DRAWRECT rhealthbarx[si],2,9,16,2
    popa
    inc si 
    inc si
    cmp si,di
    jnz rHealthBars
    DisplayMessage 1700h,FirstPname+2 
    DisplayMessage 1719h,SecondPname+2 

    popa 
 k:  ret
DrawHealthBar ENDP

AddBullet proc
    pusha  
    mov si,BNUM
    add si,si 
    mov di,ytemp
    mov yBULLETS[si],di
    mov di,xtemp
    mov xBULLETS[si],di
    cmp xBULLETS[si],120
    jb  onleft
    cmp xBULLETS[si],200
    ja  onright
    jmp exit
    onleft:
    mov BDir[si],1
    jmp exit
    onright:
    mov BDir[si],2
    exit: 
    inc BNUM
    popa
    ret
AddBullet ENDP 
MoveBullets proc 
    ;move bullets 
    mov si,0
    label2:
        
        mov state,0
        ;check if there are Bullets left
        cmp xBULLETS[si],0
        jz  Bfinished
        ;check direction
        cmp BDir[si],1  ;means the direction is right
        jz r
        cmp BDir[si],2  ;means the direction is left
        jz l
        
 
        r:
            mov di,xBULLETS[si];mov di x position of bullet[i] (i.e the initial x of bullet)
            add di,bwidth ;add bullets length 
            
            check di,yBULLETS[si],state,Ocolor ;mov to check in macro file to see whether it hit something or not
            mov xtemp,di      
            mov al,state      
            mov bx,yBULLETS[si]
            add bx,bheight 
            mov ytemp,bx
            check xtemp,ytemp,state,Ocolor ;mov to check in macro file to see whether it hit something or not
            or al,state                        
                   
            cmp al,1;means it faced an obstacle 
            jz  BRemove     ;remove it from the array
            
            cmp xtemp,lBarragex
            jz pr1
            cmp xtemp,rBarragex
            jz pr1
            jmp pr2
            pr1:
                inc xBULLETS[si]
                jmp nextB
            pr2:
            cmp xtemp,leftlinex
            jz goon2
            cmp xtemp,rightlinex
            jz goon2     
            
            check xtemp,yBULLETS[si],state,1 ;mov to check in macro file to see whether it hit something or not 
            mov al,state
            mov bx,yBULLETS[si]
            add bx,bheight
            check xtemp,bx,state,1 ;mov to check in macro file to see whether it hit something or not
            or al,state 
            cmp al,1    ;means it faced a tank
            jz hit2
            inc xBULLETS[si]    ;it doesnt face any thing so move it one step right
            jmp nextB
            hit2:dec rcurrentbar
            jmp goon2
        l:  
            ;check next step            
            mov di,xBULLETS[si]
            dec di     
            check di,yBULLETS[si],state,Ocolor ;mov to check in macro file to see whether it hit something or not
            mov xtemp,di         
            mov al,state  
            mov bx,yBULLETS[si]
            add bx,bheight
            mov ytemp,bx
            check xtemp,ytemp,state,Ocolor ;mov to check in macro file to see whether it hit something or not
            or al,state  
            
            cmp al,1     ;means it faced an obstacle 
            jz  BRemove     ;remove it from the array
            
            cmp xtemp,lBarragex
            jz pl1
            cmp xtemp,rBarragex
            jz pl1
            jmp pl2
            pl1:
                dec xBULLETS[si]
                jmp nextB
            pl2:
            cmp xtemp,leftlinex
            jz goon2
            cmp xtemp,rightlinex
            jz goon2 
            
            check xtemp,yBULLETS[si],state,1 ;mov to check in macro file to see whether it hit something or not
            mov al,state
            mov bx,yBULLETS[si]
            add bx,bheight
            check xtemp,bx,state,1 ;mov to check in macro file to see whether it hit something or not
            or al,state 
            cmp al,1    ;means it faced a tank
            jz hit
            dec xBULLETS[si] 
            jmp nextB
            hit:dec lcurrentbar
            jmp goon2
               
        BRemove:;remove the bullet from array and remove the obstacle from its array if its health is equal 1 
            pusha
            mov dx,yBULLETS[si];save value of y-cordinate of bullet in register(dx)
            mov tempb,dx;save this value in temprerory variable in memory to be used later
            mov tempa,si;save the value of si as it will bu used belw and  it has important value to complete the loop
            ;get the offset for both x and y arrays for obstacle to search amonng them
            mov bx,offset obstaclexposition
            mov si,offset obstacleyposition
            mov counter,0;this cunter used the track the index of (x or y) in their arrays
        find:;loop among the obstacle to find the  obstacle that was hit by bullet
            ;first case for x if it come from left
             cmp [bx],0;check if there is any obstacle in array
             jz goon;jump mean there is no obstacle found in array so mov out of remove loop of obstacle and delete the rest
             mov cx,di; move ax the x-position of bulltet in addition to its length 
             mov dx,[bx];mov dx x-position of obstacle 
             mov auxulary ,bx;save offset of current obstacle x-postion to be used again in shift if the obstacle will be deleted
             cmp cx,dx ;compare obstacle x with bullet x 
             jz pass ;this jump means that this scenario of x is correct then we move to check the y
             ;second case of x
             add dx,29  ;this add is resulted from case that if the bullet came from the left so ,we add the width of obstacle assuming that all of them is 30 unit width
             cmp cx,dx;compare the same x-cordinate, of bullet with the second case of x-cordinate of obstacle
             pushf;psuhf is used to save the flag register as after compare as we execute instructions after compare
             add bx,2;this case of add 2 assume that this isnt the wanted obstacle so we inc index inside array and  do the loop again at find
             add si,2;this as befor but for y -cordinate
             add counter,2;to keep track of index which we are in
             popf
             jnz find
             sub bx,2;subtract mean that our assumption was wrong and we need  to backtrack our mistake 
             sub si,2 ;this as prevoius line but for x-cordinate
             sub counter,2
             sub dx,29;return to the orifinal point (i.e Remember we add 29 to value of x psition  so after check succed we need to subtract it to complete the loop smoothly 
         pass:;compare possible y scenarios//compare the upper left corner of bullet with the range of obstacle y (i.e ybullet>upperleft y of obstacle and ybullet< dwonleft y of obstacle)
             mov cx,tempb;We get the previous saved temp to getback the y
             mov auxulary+2,si;save offset of current obstacle y-postion
             cmp cx,[si]
             jb blowerpointcheck 
             mov di,si
             add [di],30
             cmp cx,[di]
             ja blowerpointcheck 
             mov di,si
             sub [di],30;original y of abstacle
             jmp goahead  
blowerpointcheck:;the scond check as befor but for the down left corner of bullet
             add cx,bheight
             cmp cx,[si]
             pushf
             add bx,2 
             add si,2
             add counter,2
             popf
             jb find 
             sub bx,2
             sub si,2
             sub counter,2
             mov di,si
             add [di],30
             cmp cx,[di]
             pushf
             add bx,2
             add si,2
             add counter,2
             popf
             ja find 
             sub bx,2
             sub si,2
             sub counter,2
             mov di,si
             sub [di],30;original y of abstacle  
             
       goahead:;------------------------------------------------------------------ 
             mov bx,[di];mov y to bx 
             mov temp,dx;mov x to temp
             ;compare health to check health of obstacle and remove from the array the obstacle that we need to move
             mov si,counter;remeber counter tto kkep track of index
             add counter,offset obstaclehealth;now add the offset so that make delete obstacle health with zero and remove for the end of array
             cmp Obstaclehealth[si],1
             pushf
             dec Obstaclehealth[si]
             popf
             jnz goon
             
             
        ;shift obstacle (x,y) to the end of array
        ;clear x of destroyed obstacle
             mov bx,auxulary
        removeFromArray:
             mov [bx],0 
             mov cx,[bx+2]
             mov [bx],cx
             add bx,2
             cmp [bx],0
             jnz removeFromArray
             
             mov bx,auxulary+2
        ;clear y of destroyed obstacle
        removeagain: 
             mov [bx],0 
             mov cx,[bx+2]
             mov [bx],cx
             add bx,2
             cmp [bx],0
             jnz removeagain      
            ;todo  
        ;shift health to the end of array and set to zero of destroyed obstacle
        mov bx,counter
        removeagain1: 
             mov [bx],0 
             mov cx,[bx+2]
             mov [bx],cx
             add bx,2
             cmp [bx],100
             jnz removeagain1      
  
                                       
       goon: 
         ;now lets remove the buulet from array                               
               popa
       goon2:
               mov xBULLETS[si],0
               mov yBULLETS[si],0
               mov BDir[si],0 
               dec BNUM
               pusha
               labelx:
                    cmp xBULLETS[si+2],0
                    jz d1
                    mov di,xBULLETS[si]
                    xchg di,xBULLETS[si+2]
                    mov xBULLETS[si],di 
                    add si,2
                    jmp labelx
                    d1:popa
                pusha    
                labely:
                    cmp yBULLETS[si+2],0
                    jz d2
                    mov di,yBULLETS[si]
                    xchg di,yBULLETS[si+2]
                    mov yBULLETS[si],di 
                    add si,2
                    jmp labely
                    d2:popa
                pusha    
                labeld:
                    cmp BDir[si+2],0
                    jz d3
                    mov di,BDir[si]
                    xchg di,BDir[si+2]
                    mov BDir[si],di 
                    add si,2
                    jmp labeld
                    d3:popa         
            sub si,2
        nextB: 
        add si,2
    jmp label2   
    Bfinished:
    ret
MoveBullets ENDP        
DrawBullets proc 
    pusha
    mov si,0
    D:
        cmp xBULLETS[si],0
        jz E 
        DRAWRECT xBULLETS[si],yBULLETS[si],bwidth,bheight,4 
        add si,2
    jmp D    
    E: 
    popa
    ret
DrawBullets ENDP     
ClearBullets proc 
    pusha
    mov si,0
    clearb:
        cmp xBULLETS[si],0
        jz exitb 
        mov xBULLETS[si],0
        mov yBULLETS[si],0 
        add si,2
    jmp clearb   
    Exitb:
    mov bnum,0 
    popa
    ret
ClearBullets ENDP 

prepareObstacles  proc
    ;define obstacke positions
    ;1st                         
    mov obstaclexposition,50;mov x position in firstbyte
    mov obstacleyposition,30;mov y position in secondbyte
    mov obstaclehealth,3h
    ;2nd
    mov obstaclexposition+2,40;mov x position in firstbyte
    mov obstacleyposition+2,80;mov y position in secondbyte
    mov obstaclehealth+2,3h
    ;3rd
    mov obstaclexposition+4,60;mov x position in firstbyte
    mov obstacleyposition+4,120;mov y position in secondbyte
    mov obstaclehealth+4,3h
    ;4th     
    mov obstaclexposition+6,240;mov x position in firstbyte
    mov obstacleyposition+6,80;mov y position in secondbyte
    mov obstaclehealth+6,3h
    ;5th
    mov obstaclexposition+8,250;mov x position in firstbyte
    mov obstacleyposition+8,30;mov y position in secondbyte
    mov obstaclehealth+8,3h
    ;6th     
    mov obstaclexposition+10,210;mov x position in firstbyte
    mov obstacleyposition+10,120;mov y position in secondbyte
    mov obstaclehealth+10,3h
    ret
prepareObstacles  ENDP

drawWallPaper proc
pusha 

;text mode
mov ax, 0003h
int 10h

;clear screan and set fore color red    
mov ah, 07h
mov bh, 0ch
mov cx, 0
mov dl, 79
mov dh, 24 
mov al, 0
int 10h

Displaymessage 0000h,wallpaper    
mov si, 0
;scroll down one line 25 times
mov al, 1
wallDraw:             
    int 10h
        push cx
        mov cx, 0fffh
        walldelay1:          
        push cx
        mov cx, 0ffh
            walldelay2:
            loop walldelay2
        pop cx    
        loop walldelay1 
        pop cx
    inc si
    cmp si, 25
    jnz wallDraw 
    popa
    ret    
drawWallPaper endp 

end main 
