;*******************************************************************************
; Universidad del Valle de Guatemala
; Microcontroladores 
; Seccion 20
; Max de León Robles - 13012
; Programa: Proyecto 1 "Propeller Clock"
; Código utilizado para controlar el PIC16F84A para elaborar un Propeller Clock
; utilizando un fototransistor para determinar la frecuencia de giro del mismo
; y así llevar el control del tiempo del mismo. 
;*******************************************************************************	
	list      p=16F84A            ; list directive to define processor
	#include <p16F84A.inc>        ; processor specific variable definitions

	__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC
;***** DEFINICION DE VARIABLES
	UDATA_SHR 0x0C
contador res 1		    ; Se encarga de llevar el control de las columnas que se encienden
tiempo1 res 1		    ; Variable que lleva el control del tiempo	    
tiempo2 res 1
unidadS res 1		    ; Variables utilizadas para el control de segundos
decenaS res 1
unidadM res 1		    ; Variables utilizadas para el control de minutos
decenaM res 1
unidadH res 1		    ; Variables utilizadas para el control de horas
decenaH res 1
banderaTimer res 1	    ; Variable utilizada para el delay
delay1 res 1		    ; Contador utilizado para el delay final
numero res 1
banderaBoton res 1	    ; Variable para interrupción del botón
estado res 1		    ; Variable para determinar estado del reloj
; Variables para la alarma del reloj
alarmaDecenaM res 1
alarmaUnidadM res 1
alarmaDecenaH res 1
alarmaUnidadH res 1
; Variables para realizar el PUSH & POP de las variables importantes utilizadas
W_TEMP RES 1
STATUS_TEMP RES 1
;*******************************************************************************
ORG 0x0000
    NOP
    GOTO inicializacion
;*******************************************************************************
ORG 0x0004
    PUSH:
	MOVWF W_TEMP
	SWAPF STATUS, W
	MOVWF STATUS_TEMP
;*******************************************************************************    
    ISR:
; Revisión de posibles interrupciones ocurridas (botones o tiempo)
	BTFSS INTCON, T0IF		; Si T0IF = 1 , se activo interrupcion
	GOTO POP			; Si la interrupción fue por boton
	BCF INTCON, T0IF		; Regreso a cero la bandera
	MOVLW .248			; Se inicializa el prescaler con el valor de 61
	MOVWF TMR0
	BSF banderaTimer, 0		; Delay para determinar si paso 1 mS
	DECFSZ tiempo1, 1		; Compara el segundo
	GOTO POP			; Si no ha transcurrido un segundo sale
	MOVLW .100 
	MOVWF tiempo1
	BSF banderaBoton, 0
	DECFSZ tiempo2, 1
	GOTO POP
	MOVLW .10
	MOVWF tiempo2
; Empieza el conteo del tiempo
	CALL TIEMPO
; ******************************************************************************
    POP:
	SWAPF STATUS_TEMP, W
	MOVWF STATUS
	SWAPF W_TEMP, F
	SWAPF W_TEMP, W
    RETFIE
;*******************************************************************************
inicializacion:
    CLRW			; Se hace un clear del acumulador
    CLRF PORTA			; Inicializa el puerto A
    CLRF PORTB			; Inicializa el puerto B
    BSF STATUS,RP0		; Se selecciona el Banco 1	
; Se declaran como salida los pines del puerto A
    BSF TRISA, 0
    BSF TRISA, 1
    BSF TRISA, 2
    BSF TRISA, 3
; Selecciono los pines como salida los pines del puerto B
    BCF TRISB, 0
    BCF TRISB, 1
    BCF TRISB, 2
    BCF TRISB, 3
; Selecciono los pines como entrada los pines del puerto B
    BCF TRISB, 4
    BCF TRISB, 5
    BCF TRISB, 6
    BCF TRISB, 7
; Inicializacion del temporizador 
    BCF OPTION_REG, T0CS	; Lo coloco como temporizador
    BCF OPTION_REG, PSA		; Asigno Prescaler al Timer0
    BSF OPTION_REG, PS2		; Seleccion Prescaler 1:256 PS2:PS0 111
    BSF OPTION_REG, PS1
    BSF OPTION_REG, PS0
; Inicialización de interrumpciones
    BSF INTCON,GIE
    BSF INTCON,T0IE 
    BCF STATUS,RP0		; Se regresa al banco 0	
main:
;*******************************************************************************
; Ciclo principal que va llevar el control del contador aumentando la variable 
;*******************************************************************************
    MOVLW .0
    MOVWF contador
    MOVLW .0
    MOVWF numero
    MOVLW .100			; Valor inicial del primer digito de segundos
    MOVWF tiempo1
    MOVLW .10
    MOVWF tiempo2
    MOVLW .0			; Se carga el valor de 0 para el estado normal
    MOVWF estado		; del reloj
    MOVLW .248			; Se inicializa el prescaler con el valor de 61
    MOVWF TMR0			; Se inicializa el prescaler para 1 mS
    MOVLW .0			; Unidad de segundos
    MOVWF unidadS
    MOVLW .0	    		; Decenas de segundos
    MOVWF decenaS
    MOVLW .8			; Unidad de minutos
    MOVWF unidadM
    MOVLW .5	    		; Decenas de minutos
    MOVWF decenaM
    MOVLW .0			; Unidad de horas
    MOVWF unidadH
    MOVLW .0	    		; Decenas de horas
    MOVWF decenaH
; Se inicializan las variables para la alarma del reloj
    MOVLW .0			; Unidad de minutos
    MOVWF alarmaUnidadM
    MOVLW .0	    		; Decenas de minutos
    MOVWF alarmaDecenaM
    MOVLW .0			; Unidad de horas
    MOVWF alarmaUnidadH
    MOVLW .0	    		; Decenas de horas
    MOVWF alarmaDecenaH
loop:
;*******************************************************************************
; Despliegue de la hora presentando los números que deben 
;*******************************************************************************
    infrarrojo:
    BTFSC PORTA, 3
    GOTO salto
    GOTO infrarrojo
    salto:
    MOVF unidadS, 0		; Se carga el valor del número que se desea imprimir
    MOVWF numero		; Se guarda en otra variable
    CALL COMPARACION		; Se compara el valor de la variable
    MOVF decenaS, 0
    MOVWF numero
    CALL COMPARACION 
    CALL DOS_PUNTOS
    MOVF unidadM, 0
    MOVWF numero
    CALL COMPARACION 
    MOVF decenaM, 0
    MOVWF numero
    CALL COMPARACION
    CALL DOS_PUNTOS
    MOVF unidadH, 0
    MOVWF numero
    CALL COMPARACION
    MOVF decenaH, 0
    MOVWF numero
    CALL COMPARACION
; Delay final para no imprimir en la parte de atras del reloj
    MOVLW .16
    MOVWF delay1
    ciclo_delay:
	CALL DELAY
	DECFSZ delay1
	GOTO ciclo_delay
    BTFSC unidadS, 0
    GOTO IMPAR
    CALL PRIMERO
    GOTO revision_boton
    IMPAR:
    CALL SEGUNDO
    GOTO revision_boton
; Se revisa si un botón fue presionado
; Delay final para no imprimir en la parte de atras del reloj
    revision_boton:
    MOVLW B'00000000'
    MOVWF PORTB
    BTFSS banderaBoton, 0
    GOTO loop
    CALL BOTON
GOTO loop
;*******************************************************************************
; Subrutina de comparación para determinar que número se va a imprimir
;*******************************************************************************
COMPARACION
    INCF numero,1
    DECFSZ numero,1
    GOTO C_1
    CALL CERO
    RETURN
    C_1:
	DECFSZ numero,1
	GOTO C_2
	CALL UNO
    RETURN
    C_2:
	DECFSZ numero,1
	GOTO C_3
	CALL DOS
    RETURN
    C_3:
	DECFSZ numero, 1
	GOTO C_4
	CALL TRES
    RETURN
    C_4:
	DECFSZ numero,1
	GOTO C_5
	CALL CUATRO
    RETURN
    C_5:
	DECFSZ numero,1
	GOTO C_6
	CALL CINCO
    RETURN
    C_6:
	DECFSZ numero, 1
	GOTO C_7
	CALL SEIS
    RETURN
    C_7:
	DECFSZ numero,1
	GOTO C_8
	CALL SIETE
    RETURN
    C_8:
	DECFSZ numero,1
	GOTO C_9
	CALL OCHO
    RETURN
    C_9:
	CALL NUEVE
    RETURN
RETURN
;*******************************************************************************
; Subrutina para revisar el estado del botón presionado y determinar la acción 
; que se va a realizar
;*******************************************************************************
BOTON
    BTFSC PORTA, 0
    GOTO revision1
    BTFSC PORTA, 1
    GOTO estado_10
    BCF banderaBoton, 1
    BCF banderaBoton, 0
    RETURN
    revision1:
	BTFSC PORTA, 1
	;GOTO estado_11
	NOP
	GOTO estado_01
    ;estado_11:
	;BTFSC estado,0		; Verifica que si el PORTA esta en cero salte a esta_on sino salta y lo pone en 0
	;GOTO cambio	
	;BSF estado,0			; Cambia al estado de alarma
	;RETURN
    ;cambio:
	;BCF estado,0			; Regresa al estado de reloj
	;RETURN
    estado_01:
	BTFSC estado, 0
	GOTO alarmaHoras
	CALL minutos
	RETURN
    estado_10:
	BTFSC estado, 0
	GOTO alarmaMinutos
	CALL horas
	RETURN
    alarmaMinutos:
	INCF alarmaUnidadM, 1
	BTFSS alarmaUnidadM, 3
	RETURN
	BTFSS alarmaUnidadM, 1
	RETURN
	MOVLW .0
	MOVWF alarmaUnidadM
	INCF alarmaDecenaM
	BTFSS alarmaDecenaM, 2
	RETURN
	BTFSS alarmaDecenaM, 1
	RETURn
	MOVLW .0
	MOVWF alarmaDecenaM
	RETURN
    alarmaHoras:
	BTFSS alarmaDecenaH, 1 
	GOTO aumento_hora1
	INCF alarmaUnidadH
	BTFSS alarmaUnidadH, 2
	RETURN
	MOVLW .0
	MOVWF alarmaUnidadH
	MOVLW .0
	MOVWF alarmaDecenaH
	RETURN
	aumento_hora1:
	    INCF alarmaUnidadH
	    BTFSS alarmaUnidadH, 3
	    RETURN
	    BTFSS alarmaUnidadH, 1
	    RETURN
	    INCF alarmaDecenaH
	    MOVLW .0
	    MOVWF alarmaUnidadH
	RETURN
RETURN
;*******************************************************************************
; Subrutina utilizada para el aumento de tiempo
;*******************************************************************************  
TIEMPO
    segundos:
	INCF unidadS, 1
	BTFSS unidadS, 3
	RETURN
	BTFSS unidadS, 1
	RETURN
	MOVLW .0
	MOVWF unidadS
	INCF decenaS, 1
	BTFSS decenaS, 2
	RETURN
	BTFSS decenaS, 1
	RETURN
	MOVLW .0
	MOVWF decenaS
    ; Empieza el aumento de minutos
    minutos:
	INCF unidadM, 1
	BTFSS unidadM, 3
	RETURN
	BTFSS unidadM, 1
	RETURN
	MOVLW .0
	MOVWF unidadM
	INCF decenaM
	BTFSS decenaM, 2
	RETURN
	BTFSS decenaM, 1
	RETURN
	MOVLW .0
	MOVWF decenaM
    ; Empieza el aumento de horas
    horas:
	BTFSS decenaH, 1 
	GOTO aumento_hora
	INCF unidadH
	BTFSS unidadH, 2
	RETURN
	MOVLW .0
	MOVWF unidadH
	MOVLW .0
	MOVWF decenaH
	RETURN
	aumento_hora:
	    INCF unidadH
	    BTFSS unidadH, 3
	    RETURN
	    BTFSS unidadH, 1
	    RETURN
	    INCF decenaH
	    MOVLW .0
	    MOVWF unidadH
RETURN
;*******************************************************************************
; Subrutina donde se guardan los valores de los LED's para encender y mostrar
; los distintos números cada uno distinto cargando en todo PORTB
;*******************************************************************************   
CERO
    MOVLW B'11111110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10000010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10000010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
UNO
    MOVLW B'00000010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11111110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01000010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
DOS
    MOVLW B'01100010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10001010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01000110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
TRES
    MOVLW B'01101100'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01000100'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
CUATRO
    MOVLW B'00010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11110000' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
CINCO
    MOVLW B'10011110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11110010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
SEIS
    MOVLW B'01001100'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01111100' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
SIETE
    MOVLW B'00010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010000' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10000000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
OCHO
    MOVLW B'11111110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010010'
    MOVWF PORTB
    CALL DELAY   
    MOVLW B'11111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
NUEVE
    MOVLW B'11111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10010000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'11110000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
DOS_PUNTOS			    ; Subrutina para impresión de dos puntos
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN 
;*******************************************************************************
; Subrutinas utilizadas para el dibujo de la animación
;*******************************************************************************
PRIMERO
    MOVLW B'10000111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01011111' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00111111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01111111' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100111' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00111111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01011111' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10000111'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
SEGUNDO
    MOVLW B'10000110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01011110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01111110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01100110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00111110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'01011110' 
    MOVWF PORTB
    CALL DELAY
    MOVLW B'10000110'
    MOVWF PORTB
    CALL DELAY
    MOVLW B'00000000'
    MOVWF PORTB
    CALL DELAY
RETURN
;*******************************************************************************
; Subrutina para el delay para encender los LED's
;*******************************************************************************
DELAY
    BCF banderaTimer,0
    ciclo:
    BTFSS banderaTimer, 0
    GOTO ciclo
    BCF banderaTimer, 0
RETURN
END