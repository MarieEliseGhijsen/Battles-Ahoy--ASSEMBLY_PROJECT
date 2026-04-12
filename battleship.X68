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

    ;INITIALIZING GAME
    JSR INIT_GAME
    JSR PLACE_SHIPS_P1
    JSR PLACE_SHIPS_P2
    
    ;GAMEPLAY
GAME_LOOP:
    JSR GAME_TURN
    
    TST.B D6
    BEQ GAME_LOOP

    ;RESULT
    ;JSR PRINT_ALL_COORDS
    ;JSR PRINT_ALL_BOARDS

END_LOOP:
    BRA END_LOOP

*-----------------------------------------------------------
*sub-routines
*-----------------------------------------------------------
*-----------------------------------------------------------
*init
*-----------------------------------------------------------
INIT_GAME: ;clear both boards (16 bytes each)
    CLR.B CURRENT_PLAYER

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

    MOVE #4, D4
    
P1_LOOP:
    JSR ENTER_COORDINATE
    
    LEA BOARD_P1, A0
    JSR VALIDATE_PLACEMENT
    
    CMP.B #1, D7
    BNE P1_LOOP
    
    JSR STORE_SHIP_P1
    
    SUBQ #1, D4
    BNE P1_LOOP
    
    JSR CLEAR_SCREEN
    
    RTS

PLACE_SHIPS_P2:
    MOVE #13, D0
    LEA MSG_P2_ENTER_SHIP, A1
    TRAP #15

    MOVE #4, D4
    
P2_LOOP:
    JSR ENTER_COORDINATE
    
    LEA BOARD_P2, A0
    JSR VALIDATE_PLACEMENT
    
    CMP.B #1, D7
    BNE P2_LOOP
    
    JSR STORE_SHIP_P2
    
    SUBQ #1, D4
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
    MOVE #5, D0
    TRAP #15

    CLR.L D0
    MOVE.B D1, D0
    SUB.B #'1', D0
    
    MOVE.B D0, D5
    
    ;READ SECOND CHAR (COLUM)
    MOVE #5, D0
    TRAP #15

    MOVE.L D1, D6
    CLR.L D1
    MOVE.B D6, D1
    SUB.B #'A', D1
    
    MOVE.B D5, D0

    RTS
    
VALIDATE_COORDINATE:
    *D0 = row (0–3)
    *D1 = col (0–3)
    
    *bounds check
    CMP.B #0, D0
    BLT INVALID

    CMP.B #3, D0
    BGT INVALID

    CMP.B #0, D1
    BLT INVALID

    CMP.B #3, D1
    BGT INVALID
    
    *compute offset
    MOVE.B D0, D5
    MOVE.B D1, D6
    JSR GET_OFFSET

    *check board
    MOVE.B (A0,D2.W), D3

    CMP.B #3, D3
    BEQ DUPLICATE

    CMP.B #4, D3
    BEQ DUPLICATE
    
    *valid
    MOVEQ #1, D7
    
    RTS

DUPLICATE:
    MOVE #6, D0
    MOVE #10, D1
    TRAP #15

    MOVE #13, D0
    LEA MSG_ALREADY, A1
    TRAP #15

    CLR.L D7
    
    RTS
    
INVALID:
    MOVE #6, D0
    MOVE #10, D1
    TRAP #15

    MOVE #13, D0
    LEA MSG_INVALID_INPUT, A1
    TRAP #15

    CLR.L D7
    
    RTS
    
VALIDATE_PLACEMENT:
    *bounds check
    CMP.B #0, D0
    BLT INVALID
    CMP.B #3, D0
    BGT INVALID

    CMP.B #0, D1
    BLT INVALID
    CMP.B #3, D1
    BGT INVALID
    
    ; get offset
    MOVE.B D0, D5
    MOVE.B D1, D6
    JSR GET_OFFSET
    
    MOVE.B (A0,D2.W), D3
    
    CMP.B #1, D3 ;ship already exists
    BEQ DUPLICATE_PLACEMENT
    
    MOVEQ #1, D7
    
    RTS
    
DUPLICATE_PLACEMENT:
    MOVE #6, D0
    MOVE #10, D1
    TRAP #15

    MOVE #13, D0
    LEA MSG_ALREADY_PLACED, A1
    TRAP #15

    CLR.L D7
    
    RTS

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
    CLR.L D2
    MOVE.B D5, D2 ;row
    MULU #4, D2 ;row*4
    
    CLR.L D3
    MOVE.B D6, D3 ;col
    ADD.L D3, D2 ;+ col
    
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
    
    ;JSR WAIT_FOR_KEY

    MOVE #13, D0
    LEA MSG_P2_SHOW, A1
    TRAP #15
    
    LEA BOARD_P2, A0
    JSR PRINT_BOARD_GRID
    
    RTS
    
PRINT_BOARD_GRID:
    MOVE #13, D0
    LEA GRID_COL_HEADER, A1
    TRAP #15
    
    MOVEQ #0, D3 ;index

PRINT_GRID_LOOP:
    CMP #16, D3
    BEQ DONE_GRID_PRINT
    
    MOVE.W D3, D5
    AND.W #3, D5
    CMP #0, D5
    BNE SKIP_ROW_LABEL

    ;row = (D3 / 4) + '1'
    MOVE.W D3, D6
    DIVU #4, D6 ;quotient = row
    AND.W #$00FF, D6
    ADD.B #'1', D6

    MOVE.B D6, D1
    MOVE #6, D0
    TRAP #15
    
    ;print space after row number
    MOVE.B #' ', D1
    MOVE #6, D0
    TRAP #15

SKIP_ROW_LABEL:
    MOVE.B (A0,D3.W), D4

    CMP.B #1, D4
    BEQ PRINT_SHIP

    CMP.B #3, D4
    BEQ PRINT_MISS

    CMP.B #4, D4
    BEQ PRINT_HIT

    MOVE.B #'0', D4
    BRA PRINT_CHAR
        
PRINT_SHIP:
    MOVE.B #'S', D4
    BRA PRINT_CHAR

PRINT_MISS:
    MOVE.B #'M', D4
    BRA PRINT_CHAR

PRINT_HIT:
    MOVE.B #'H', D4
    BRA PRINT_CHAR

PRINT_CHAR:
    ;print char
    MOVE.B D4, D1
    MOVE #6, D0
    TRAP #15
    
    ;print space
    MOVE.B #' ', D1
    MOVE #6, D0
    TRAP #15
    
    ADDQ #1, D3
    
    ;newline every 4 cells
    MOVE.W D3, D5
    AND.W #3, D5
    CMP #0, D5
    BNE PRINT_GRID_LOOP
    
    MOVE #6, D0
    MOVE #13, D1
    TRAP #15
    
    MOVE #6, D0
    MOVE #10, D1
    TRAP #15
    
    BRA PRINT_GRID_LOOP

DONE_GRID_PRINT:
    MOVE #6, D0 ;CR
    MOVE #10, D1 ;LF
    TRAP #15
    
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
WAIT_FOR_KEY:
    MOVE #5, D0
    TRAP #15
    
    RTS

CONTINUE:
    MOVE #13, D0
    LEA MSG_CONTINUE, A1
    TRAP #15
    
    MOVE #5, D0
    TRAP #15

CLEAR_SCREEN:
    MOVE #11, D0
    MOVE.W #$FF00, D1
    TRAP #15
    
    RTS
    
RESET_CURSOR:
    MOVE #11, D0
    MOVE.W #$0000, D1 ;row=0 col=0
    TRAP #15
    
    RTS
    
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*-----------------------------------------------------------
*----------------------------------------------------------- 
GAME_TURN:
    TST.B CURRENT_PLAYER
    BEQ P1_TURN

P2_TURN:
    LEA BOARD_P1, A0
    BRA INPUT_LOOP

P1_TURN:
    LEA BOARD_P2, A0
    
INPUT_LOOP:
    JSR PRINT_TURN

    *get input
    JSR ENTER_COORDINATE
    JSR VALIDATE_COORDINATE

    CMP.B #1, D7
    BNE INPUT_LOOP
    
    *bomb coordinates 
    JSR CHECK_COORDINATES
    
    *check win condition
    JSR CHECK_BATTLESHIPS
    
    TST.B D6
    BNE GAME_END

    *switch player
    NOT.B CURRENT_PLAYER
    
    JSR CONTINUE
    
    RTS
    
    GAME_END:
    RTS
    
CHECK_COORDINATES:
    MOVE.B D0, D5
    MOVE.B D1, D6
    JSR GET_OFFSET
    
    MOVE.B (A0,D2.W), D4
    
    CMP.B #1, D4
    BEQ IS_HIT
    
IS_MISS:
    MOVE #6, D0 ;CR
    MOVE #10, D1 ;LF
    TRAP #15
    
    MOVE.B #3, (A0,D2.W)

    MOVE #13, D0
    LEA MSG_MISS, A1
    TRAP #15
    
    MOVEQ #1, D7

    RTS
    
IS_HIT:
    MOVE #6, D0 ;CR
    MOVE #10, D1 ;LF
    TRAP #15

    MOVE.B #4, (A0,D2.W)

    MOVE #13, D0
    LEA MSG_HIT, A1
    TRAP #15
    
    MOVEQ #1, D7

    RTS

CHECK_BATTLESHIPS:
    MOVEQ #0, D3
    
CHECK_LOOP:
    CMP #16, D3
    BEQ NO_SHIPS_LEFT
    
    MOVE.B (A0,D3.W), D4
    CMP.B #1, D4
    BEQ SHIP_FOUND
    
    ADDQ #1, D3
    BRA CHECK_LOOP

SHIP_FOUND:
    CLR.B D6
    
    RTS
    
NO_SHIPS_LEFT:
    MOVEQ #1, D6
    
    JSR PRINT_WINNER
    
    JSR PRINT_ALL_BOARDS
    
    RTS
    
PRINT_WINNER:
    JSR CLEAR_SCREEN

    TST.B CURRENT_PLAYER
    BEQ P1_WINS

P2_WINS:
    MOVE #13, D0
    LEA MSG_P2_WIN, A1
    TRAP #15
    RTS

P1_WINS:
    MOVE #13, D0
    LEA MSG_P1_WIN, A1
    TRAP #15
    RTS
    
CHANGE_TURN:
    MOVE #13, D0
    LEA MSG_CHANGE_TURN, A1
    TRAP #15
    
    RTS
    
PRINT_TURN:
    TST.B CURRENT_PLAYER
    BEQ P1_MSG

P2_MSG:
    MOVE #13, D0
    LEA MSG_P2_TURN, A1
    TRAP #15
    
    RTS

P1_MSG:
    MOVE #13, D0
    LEA MSG_P1_TURN, A1
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
    
    CURRENT_PLAYER: DC.B 0 ;0 = P1, 1 = P2

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
        
*grid header
    GRID_COL_HEADER:
        DC.B '  A B C D'
        DC.B 0
        
*turn message
    MSG_P1_TURN:
        DC.B 'Player 1 Turn'
        DC.B 13,10,0
    MSG_P2_TURN:
        DC.B 'Player 2 Turn'
        DC.B 13,10,0
        
*prompt messages
    MSG_P1_ENTER_SHIP:    
        DC.B 'Player One Place Ships'
        DC.B 13,10,0
    MSG_P2_ENTER_SHIP:    
        DC.B 'Player Two Place Ships'
        DC.B 13,10,0
        
    MSG_ENTER_COORD:    
        DC.B 'Enter coordinate (FROMAT EG. 1A) :'
        DC.B 13,10,0
    MSG_ALREADY:
        DC.B 'Already guessed that location!'
        DC.B 13,10,0
    MSG_ALREADY_PLACED:
        DC.B 'Ship slot already filled!'
        DC.B 13,10,0
    MSG_INVALID_INPUT:
        DC.B 'Invalid Input'
        DC.B 13,10,0
    MSG_MISS:
        DC.B 'Miss!'
        DC.B 13,10,0
    MSG_HIT:
        DC.B 'Hit!'
        DC.B 13,10,0
        
    MSG_P1_SHOW:
        DC.B 'Player Ones Coordinates are: '
        DC.B 13,10,0
    MSG_P2_SHOW:
        DC.B 'Player Twos Coordinates are: '
        DC.B 13,10,0
        
    MSG_CONTINUE:
        DC.B '[Press any key to continue]'
        DC.B 13,10,0
        
    MSG_P1_WIN:
        DC.B 'Player 1 Wins!'
        DC.B 13,10,0
    MSG_P2_WIN:
        DC.B 'Player 2 Wins!'
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
