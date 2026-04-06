*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVE.L #$2000, A7

    JSR INIT_GAME
    JSR PLACE_SHIPS

GAME_LOOP:
    JSR GAME_TURN
    BRA GAME_LOOP

*-----------------------------------------------------------
*sub-routines
*-----------------------------------------------------------
INIT_GAME:
    MOVE #13, D0
    LEA MSG_INIT, A1
    TRAP #15
    RTS
    
PLACE_SHIPS:
    MOVE #4, D7 ;num ships
    
PLACE_LOOP:
    JSR ENTER_COORDINATE
    JSR VALIDATE_PLACEMENT
    JSR STORE_SHIP

    SUBQ #1, D7
    BNE PLACE_LOOP

    RTS
    
ENTER_COORDINATE:
    MOVE #13, D0
    LEA MSG_ENTER_COORD, A1
    TRAP #15
    RTS
    
VALIDATE_PLACEMENT:
    MOVE #13, D0
    LEA MSG_VALIDATE_PLACE, A1
    TRAP #15
    RTS


STORE_SHIP:
    MOVE #13, D0
    LEA MSG_STORE_SHIP, A1
    TRAP #15
    RTS
    
GAME_TURN:
    MOVE #13, D0
    LEA MSG_GAME_LOOP, A1
    TRAP #15

    JSR ENTER_COORDINATE
    JSR CHECK_COORDINATES
    JSR CHECK_BATTLESHIPS
    JSR CHANGE_TURN

    RTS
    
CHECK_COORDINATES:
    MOVE #13, D0
    LEA MSG_CHECK_COORD, A1
    TRAP #15
    RTS


CHECK_BATTLESHIPS:
    MOVE #13, D0
    LEA MSG_CHECK_SHIPS, A1
    TRAP #15
    RTS
    
CHANGE_TURN:
    MOVE #13, D0
    LEA MSG_CHANGE_TURN, A1
    TRAP #15
    RTS
    
    SIMHALT             ; halt simulator

* Put variables and constants here
    MSG_INIT: 
        DC.B 'Initializing game...'
        DC.B 13,10,0
    MSG_ENTER_COORD:    
        DC.B 'Entering coordinate...'
        DC.B 13,10,0
    MSG_VALIDATE_PLACE: 
        DC.B 'Validating placement...'
        DC.B 13,10,0
    MSG_STORE_SHIP:     
        DC.B 'Storing ship...'
        DC.B 13,10,0
    MSG_GAME_LOOP:      
        DC.B 'In game loop...'
        DC.B 13,10,0
    MSG_CHECK_COORD:    
        DC.B 'Checking coordinates...'
        DC.B 13,10,0
    MSG_CHECK_SHIPS:    
        DC.B 'Checking remaining battleships...'
        DC.B 13,10,0
    MSG_CHANGE_TURN:    
        DC.B 'Changing turn...'
        DC.B 13,10,0

    END    START        ; last line of source
    
*-----------------------------------------------------------
*work trhough
*-----------------------------------------------------------

;INIT:
;clear memory
;place ships

;SHIP_PLACE
;loop [
;enter coordinate
;validate placement
;store ship
;loop increment
; ]

;ENTER_COORDINATE
;read row
;read colum

;VALIDATE_PLACEMENT
;check inside bounds
;check not already occupied
;if valid continue
;else go to ship place

;STORE_SHIP
;store the ship in memory

;GAME_LOOP:
;enter coordinates
;check coordinates

;CHANGE_TURN:
;makes it opponents turn
;go to game loop

;CHECK_COORDINATES:
;check valid coordinate
;coordinates checked against enemy array
;if true check battleships
;else change whose turn it is

;VALLID_COORDINATE
;check inside bounds
;check not already guessed
;if valid continue
;else go to game loop

;CHECK_BATTLESHIPS:
;check if opponent has battleships left
;if true change whose turn it is
;else won

;WON:
;win message out to console
;go to init

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
