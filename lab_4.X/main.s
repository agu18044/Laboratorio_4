; Archivo:     main.S
; Dispositivo: PIC16F887
; Autor:       Diego Aguilar
; Compilador:  pic-as (v2.30), MBPLABX v5.40
;
; Programa:    contador 
; Hardware:    LEDs 
;
; Creado: 16 agosto, 2021
; Última modificación:  agosto, 2021

PROCESSOR 16F887
 #include <xc.inc>
 
;configuration word 1
    CONFIG FOSC=INTRC_NOCLKOUT  // Oscilador interno sin salidas
    CONFIG WDTE=OFF  // WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON  // PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF // El pin MCLR se utiliza como I/0
    CONFIG CP=OFF    // Sin proteccion de codigo
    CONFIG CPD=OFF   // Sin proteccion de datos
    
    CONFIG BOREN=OFF // Sin reinicio cuando el voltaje de alimentacion baja de 4V
    CONFIG IESO=OFF  // Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=OFF    // Programacion en bajo voltaje permitida
    
;configuration word 2
    CONFIG WRT=OFF   // Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V  // Reinicio abajo de 4V, (BOR21V=2.1V)
 
restart_tmr0 macro
    banksel PORTA
    movlw   61		; t = (4 * t_osc)(256-TMR0)(prescaler)
    movwf   TMR0	;ciclo de 50ms
    bcf	    T0IF
    endm
    
PSECT udata_bank0  ;common memory
    reg:    DS 2
    cont:   DS 2
    
PSECT udata_shr  ;common memory
    W_TEMP:	    DS 1
    STATUS_TEMP:    DS 1
    
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT resVect, class=CODE, abs, delta=2 
;----------- interupt vector------------;    
ORG 04h	    ;posicion 0004h para las interupciones
push:
    movf    W_TEMP
    swapf   STATUS, W
    movf    STATUS_TEMP

isr:
   btfsc    T0IF
   call	    int_t0
   
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

;----------subrutinas de interup.----------;
int_t0:   
    restart_tmr0    ;50ms
    incf    cont
    movf    cont, W
    sublw   10
    btfss   ZERO    ;STATUS, 2
    goto    return_t0
    clrf    cont
    incf    PORTA
return_t0:   
    return
    
PSECT code, delta=2, abs
 ;-----------	TABLA   ----------------;
ORG 100h    ; posicion para le codigo
 tabla:
    clrf    PCLATH
    bsf	    PCLATH, 0   ;PCLATH = 01
    andlw   0x0f
    addwf   PCL         ;PC = PCLATH + PCL
    ; se configura la tabla para el siete segmentos
    retlw   00111111B  ;0
    retlw   00000110B  ;1
    retlw   01011011B  ;2
    retlw   01001111B  ;3
    retlw   01100110B  ;4
    retlw   01101101B  ;5
    retlw   01111101B  ;6
    retlw   00000111B  ;7
    retlw   01111111B  ;8
    retlw   01100111B  ;9
    retlw   01110111B  ;A
    retlw   01111100B  ;B
    retlw   00111001B  ;C
    retlw   01011110B  ;D
    retlw   01111001B  ;E
    retlw   01110001B  ;F
    
 ;-----------configuracion--------------;

main:
    call    config_io
    call    config_reloj
    call    config_tmr0
    call    config_int_enable
    banksel PORTA

loop:
  
 
    goto    loop

config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bsf	    IRCF1
    bcf	    IRCF0	; 4 Mhz
    bsf	    SCS
    return
    
config_tmr0:
    banksel TRISA
    bcf	    T0CS
    bcf	    PSA
    bsf	    PS2		;asignar prescaler
    bsf	    PS1
    bsf	    PS0
    restart_tmr0
    return


config_int_enable:
    bsf	    GIE		;INTCON
    bsf	    T0IE
    bcf	    T0IF    
    return
    
config_io:
    ; Configuracion de los puertos
    banksel ANSEL	; Se selecciona bank 3
    clrf    ANSEL	; Definir puertos digitales
    clrf    ANSELH
    
    banksel TRISA	; Banco 01
    clrf    TRISA	;salida contador 1
    clrf    TRISC	;salida display 1
    bsf	    TRISB, 0
    bsf	    TRISB, 1
    clrf    TRISD	;salida display 2 
    clrf    TRISE	;salida contador 2
    
    banksel PORTA	; Banco 00
    clrf    PORTB
    clrf    PORTA
    clrf    PORTC
    clrf    PORTD
  
    return

end
