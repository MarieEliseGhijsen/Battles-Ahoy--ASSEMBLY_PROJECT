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
    ;JSR PLACE_SHIPS_P1
    ;JSR PLACE_SHIPS_P2
    JSR LOAD_TEST_BOARDS

    ;JSR PRINT_ALL_COORDS
    JSR PRINT_ALL_BOARDS

END_LOOP:
    BRA END_LOOP

*-----------------------------------------------------------
*sub-routines
*-----------------------------------------------------------
*-----------------------------------------------------------
*load predetermined boards (for testing)
*-----------------------------------------------------------
LOAD_TEST_BOARDS:
    *Player 1 ships - A3, D2, B1
    
    *A3 row=2 col=0
    MOVE.B #2, D5
    MOVE.B #0, D6
    JSR GET_OFFSET
    LEA BOARD_P1, A0
    MOVE.B #1, (A0,D2.W)
    
    *D2 row=1 col=3
    MOVE.B #1, D5
    MOVE.B #3, D6
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)

    *B1 row=0 col=1
    MOVE.B #0, D5
    MOVE.B #1, D6
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)
    
    * Player 2 ships - B3, A1, C3
    LEA BOARD_P2, A0

    *B3 row=2 col=1
    MOVE.B #2, D5
    MOVE.B #1, D6
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)
    
    *A1 row=0 col=0
    MOVE.B #0, D5
    MOVE.B #0, D6
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)

    *C3 row=2 col=2
    MOVE.B #2, D5
    MOVE.B #2, D6
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)
    
    RTS

*-----------------------------------------------------------
*init
*-----------------------------------------------------------
INIT_GAME: ;clear both boards (16 bytes each)
    LEA BOARD_P1, A0
    MOVEQ #15, D0
    
    MOVE #13, D0
    LEA MSG_INIT, A1
    TRAP #15
    
CLR1:
    CLR.B (A0)+
    DBF D0, CLR1

    LEA BOARD_P2, A0
    MOVEQ #15, D0
    
CLR2:
    CLR.B (A0)+
    DBF D0, CLR2
    
    RTS
    
*-----------------------------------------------------------
*place-ships
*-----------------------------------------------------------
PLACE_SHIPS_P1:
    MOVE #13, D0
    LEA MSG_P1_ENTER_SHIP, A1
    TRAP #15

    MOVE #3, D7
    
P1_LOOP:
    JSR ENTER_COORDINATE
    JSR STORE_SHIP_P1
    
    SUBQ #1, D7
    BNE P1_LOOP
    
    JSR CLEAR_SCREEN
    
    RTS

PLACE_SHIPS_P2:
    MOVE #13, D0
    LEA MSG_P2_ENTER_SHIP, A1
    TRAP #15

    MOVE #3, D7
    
P2_LOOP:
    JSR ENTER_COORDINATE
    JSR STORE_SHIP_P2
    
    SUBQ #1, D7
    BNE P2_LOOP
    
    JSR CLEAR_SCREEN
    
    RTS
        
*-----------------------------------------------------------
*get-coordinates (row column format, e.g. 1A)
*-----------------------------------------------------------
ENTER_COORDINATE:
    MOVE #13, D0
    LEA MSG_ENTER_COORD, A1
    TRAP #15

    ;READ FIRST CHAR (ROW)
    MOVE #5, D0        ;read single char
    TRAP #15           ;result in D1
    MOVE.B D1, D0      ;move to D0
    AND.L #$000000FF, D0
    SUB.B #'1', D0     ;convert to 0–3
    
    ;READ SECOND CHAR (COLUM)
    ;CLR.L D1
    MOVE #5, D0
    TRAP #15
    AND.L #$000000FF, D1
    SUB.B #'A', D1     ;convert to 0–3

    RTS
    
*VALIDATE_PLACEMENT:
*    MOVE #13, D0
*    LEA MSG_VALIDATE_PLACE, A1
*    TRAP #15
*    RTS

*-----------------------------------------------------------
*store-ships
*-----------------------------------------------------------
STORE_SHIP_P1:
    MOVE.B D0, D5
    MOVE.B D1, D6
    
    JSR GET_OFFSET
    
    LEA BOARD_P1, A0
    MOVE.B #1, (A0,D2.W)
    
    RTS

STORE_SHIP_P2:
    MOVE.B D0, D5
    MOVE.B D1, D6
    
    JSR GET_OFFSET
    
    LEA BOARD_P2, A0
    MOVE.B #1, (A0,D2.W)
    
    RTS
    
*-----------------------------------------------------------
*offset
*-----------------------------------------------------------
GET_OFFSET:
    MOVE.B D5, D2 ;row
    MULU #4, D2 ;row*4
    ADD D6, D2 ;+ col
    
    RTS
    
*-----------------------------------------------------------
*print-board-as-grid
*-----------------------------------------------------------G
PRINT_ALL_BOARDS:
    MOVE #13, D0
    LEA MSG_P1_SHOW, A1
    TRAP #15
    
    LEA BOARD_P1, A0
    JSR PRINT_BOARD_GRID
    
    JSR WAIT_FOR_KEY

    MOVE #13, D0
    LEA MSG_P2_SHOW, A1
    TRAP #15
    
    LEA BOARD_P2, A0
    JSR PRINT_BOARD_GRID
    
    RTS
    
PRINT_BOARD_GRID:
    MOVEQ #0, D3 ;index

PRINT_GRID_LOOP:
    CMP #16, D3
    BEQ DONE_GRID_PRINT

    MOVE.B (A0,D3.W), D4
    CMP.B #1, D4
    BEQ PRINT_ONE
    MOVE.B #'0', D4
    BRA PRINT_CHAR
    
PRINT_ONE:
    MOVE.B #'1', D4

PRINT_CHAR:
    LEA OUT_BUF, A1
    MOVE.B D4, (A1)
    MOVE.B #0, 1(A1) ;null-terminate
    MOVE #13, D0
    TRAP #15

    ADDQ #1, D3

    ;newline every 4 cells
    MOVE.W D3, D5
    AND.W #3, D5
    CMP #0, D5
    BNE PRINT_GRID_LOOP
    
    MOVE #6, D0 ;CR
    MOVE #10, D1 ;LF
    TRAP #15
    BRA PRINT_GRID_LOOP

DONE_GRID_PRINT:
    MOVE #6, D0 ;CR
    MOVE #10, D1 ;LF
    TRAP #15
    
    RTS
    
WAIT_FOR_KEY:
    MOVE #5, D0 ;read single character
    TRAP #15 ;wait until key pressed

    RTS
       
*-----------------------------------------------------------
*print-all-coordinates
*-----------------------------------------------------------
PRINT_ALL_COORDS:
    MOVE #13, D0
    LEA MSG_P1_SHOW, A1
    TRAP #15

    LEA BOARD_P1, A0
    JSR PRINT_COORDS

    MOVE #13, D0
    LEA MSG_P2_SHOW, A1
    TRAP #15
        
    LEA BOARD_P2, A0
    JSR PRINT_COORDS

    RTS
    
PRINT_COORDS: 
    MOVEQ #0, D3
 
PRINT_COORDS_LOOP: 
    CMP #16, D3 
    BEQ DONE_COORDS_PRINT
    
    MOVE.B (A0,D3.W), D4 
    CMP.B #1, D4 
    BNE NEXT_COORDS_PRINT 
    
    ;calculate row and column 
    MOVE.W D3, D5 
    DIVU #4, D5 ;D5 = [remainder | quotient] 
    MOVE.W D5, D6 ;copy result 
    
    AND.W #$00FF, D5 ;quotient (row 0–3) 
    ADD #'1', D5 ;convert to ASCII row
    
    SWAP D6 ;remainder now in low word 
    AND.W #$00FF, D6 ;column (0–3) 
    ADD #'A', D6 ;convert to ASCII column 

    ;store into OUT_BUF 
    LEA OUT_BUF, A1 
    MOVE.B D5, (A1) ;row 
    MOVE.B D6, 1(A1) ;column 
    MOVE.B #' ', 2(A1) ;space 
    MOVE.B #0, 3(A1) ;null terminator
    
    ;print 
    MOVE #13, D0 
    LEA OUT_BUF, A1 
    TRAP #15 

NEXT_COORDS_PRINT: 
    ADDQ #1, D3 
    BRA PRINT_COORDS_LOOP
    
DONE_COORDS_PRINT: 
    MOVE #6, D0 
    MOVE #10, D1 
    TRAP #15 

    RTS
    
*-----------------------------------------------------------
*clear-screen
*-----------------------------------------------------------
CLEAR_SCREEN:
    MOVE #11, D0
    MOVE.W #$FF00, D1
    TRAP #15
    
    RTS
    
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*----------------------------------------------------------- 
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

*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
* Put variables and constants here
    BOARD_P1:      DS.B 16
    BOARD_P2:      DS.B 16

    INPUT_BUF:     DS.B 4
    OUT_BUF:       DS.B 4

*function messages
    MSG_INIT: 
        DC.B 'Initializing game'
        DC.B 13,10,0
    MSG_VALIDATE_PLACE: 
        DC.B 'Validating placement'
        DC.B 13,10,0
    MSG_STORE_SHIP:     
        DC.B 'Storing ship'
        DC.B 13,10,0
    MSG_GAME_LOOP:      
        DC.B 'In game loop'
        DC.B 13,10,0
    MSG_CHECK_COORD:    
        DC.B 'Checking coordinates'
        DC.B 13,10,0
    MSG_CHECK_SHIPS:    
        DC.B 'Checking remaining battleships'
        DC.B 13,10,0
    MSG_CHANGE_TURN:    
        DC.B 'Changing turn'
        DC.B 13,10,0
        
*prompt messages
    MSG_ENTER_COORD:    
        DC.B 'Enter coordinate (FROMAT EG. 1A) :'
        DC.B 13,10,0
    MSG_P1_ENTER_SHIP:    
        DC.B 'Player One Place Ships'
        DC.B 13,10,0
    MSG_P2_ENTER_SHIP:    
        DC.B 'Player Two Place Ships'
        DC.B 13,10,0
    MSG_P1_SHOW:
        DC.B 'Player Ones Coordinates are: '
        DC.B 13,10,0
    MSG_P2_SHOW:
        DC.B 'Player Twos Coordinates are: '
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
