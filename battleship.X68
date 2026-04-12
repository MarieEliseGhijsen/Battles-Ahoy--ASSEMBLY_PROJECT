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
    ;LEA MSG_INIT, A1
    ;JSR PRINT_MSG
    JSR INIT_GAME
    JSR PRINT_GAME_TITLE

    LEA BOARD_P1, A0
    LEA MSG_P1_ENTER_SHIP, A1
    JSR PLACE_SHIPS

    LEA BOARD_P2, A0
    LEA MSG_P2_ENTER_SHIP, A1
    JSR PLACE_SHIPS
    
    ;GAMEPLAY
GAME_LOOP:
    JSR GAME_TURN

    TST.B GAME_OVER
    BEQ GAME_LOOP

    JSR CLEAR_SCREEN
    JSR PRINT_WINNER
    JSR PRINT_ALL_BOARDS

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
    CLR.B GAME_OVER

    LEA BOARD_P1, A0
    MOVEQ #15, D3
CLR1:
    CLR.B (A0)+
    DBF D3, CLR1

    LEA BOARD_P2, A0
    MOVEQ #15, D3
CLR2:
    CLR.B (A0)+
    DBF D3, CLR2

    RTS
    
*-----------------------------------------------------------
*get-coordinates (row column format, e.g. 1A)
*-----------------------------------------------------------
ENTER_COORDINATE: 
    *OUT : D5 = row, D6 = col
    
    LEA MSG_ENTER_COORD, A1
    JSR PRINT_MSG

    ;READ FIRST CHAR (ROW)
    MOVE #5, D0
    TRAP #15

    CLR.L D5
    MOVE.B D1, D5
    SUB.B #'1', D5
    
    ;READ SECOND CHAR (COLUM)
    MOVE #5, D0
    TRAP #15

    CLR.L D6
    MOVE.B D1, D6
    SUB.B #'A', D6
    
    JSR PRINT_NEWLINE

    RTS
    
*-----------------------------------------------------------
*offset
*-----------------------------------------------------------
GET_OFFSET:
    *IN : D5 = row, D6 = col
    *OUT : D2 = offset
    
    CLR.L D2
    MOVE.B D5, D2 ;row
    MULU #4, D2 ;row * 4
    
    CLR.L D3
    MOVE.B D6, D3 ;col
    ADD.L D3, D2 ;+ col
    
    RTS
    
*-----------------------------------------------------------
*place-ships
*-----------------------------------------------------------
PLACE_SHIPS:
    *IN : A0 = board, A1 = message
    *TRASHES : D0-D4
    *PRESERVES : D5-D7
    
    MOVEM.L D5-D7, -(A7)

    JSR PRINT_MSG

    MOVE #4, D4 ;num ships
    
PLACE_LOOP:
    JSR ENTER_COORDINATE
    JSR VALIDATE_PLACEMENT
    
    CMP.B #1, D7
    BNE PLACE_LOOP

    JSR STORE_SHIP
    
    SUBQ #1, D4
    BNE PLACE_LOOP
    
    JSR CLEAR_SCREEN
    
    MOVEM.L (A7)+, D5-D7
    
    RTS
    
*-----------------------------------------------------------
*validate ship placement
*-----------------------------------------------------------
VALIDATE_PLACEMENT:
    *IN : D5 = row, D6 - col, A0 - board
    *OUT : D7 = result

    *bounds check
    CMP.B #0, D5
    BLT INVALID
    CMP.B #3, D5
    BGT INVALID

    CMP.B #0, D6
    BLT INVALID
    CMP.B #3, D6
    BGT INVALID
    
    ; get offset
    JSR GET_OFFSET
    
    MOVE.B (A0,D2.W), D3
    
    CMP.B #1, D3 ;ship already exists
    BEQ DUPLICATE_PLACEMENT
    
    MOVEQ #1, D7
    
    RTS
    
DUPLICATE_PLACEMENT:
    LEA MSG_ALREADY_PLACED, A1
    JSR PRINT_MSG

    CLR.L D7
    
    RTS

*-----------------------------------------------------------
*store-ships
*-----------------------------------------------------------
STORE_SHIP:
    ; IN: A0=board, D5=row, D6=col
    
    JSR GET_OFFSET
    MOVE.B #1, (A0,D2.W)
    
    RTS
    
*-----------------------------------------------------------
*validate guess
*-----------------------------------------------------------
VALIDATE_GUESS:
    *IN : D5 = row, D6 = col, A0 = board
    *OUT : D7 = valid/invalid

    *bounds check
    CMP.B #0, D5
    BLT INVALID
    CMP.B #3, D5
    BGT INVALID

    CMP.B #0, D6
    BLT INVALID
    CMP.B #3, D6
    BGT INVALID

    *compute offset
    JSR GET_OFFSET

    *check board
    MOVE.B (A0,D2.W), D4

    CMP.B #3, D4
    BEQ DUPLICATE_GUESS
    CMP.B #4, D4
    BEQ DUPLICATE_GUESS

    *valid
    MOVEQ #1, D7

    RTS

DUPLICATE_GUESS:
    LEA MSG_ALREADY, A1
    JSR PRINT_MSG

    CLR.L D7

    RTS

INVALID:
    LEA MSG_INVALID_INPUT, A1
    JSR PRINT_MSG

    CLR.L D7

    RTS  

*-----------------------------------------------------------
*game turn
*-----------------------------------------------------------
GAME_TURN:
    JSR CLEAR_SCREEN

    TST.B CURRENT_PLAYER
    BEQ P1_TURN

    LEA BOARD_P1, A0
    JSR PRINT_TURN_MSG
    BRA TURN

P1_TURN:
    LEA BOARD_P2, A0
    JSR PRINT_TURN_MSG
    
TURN:
    *get input
    JSR ENTER_COORDINATE
    JSR VALIDATE_GUESS

    CMP.B #1, D7
    BNE TURN
    
    *bomb coordinates 
    JSR CHECK_COORDINATES
    
    *check win condition
    JSR CHECK_WIN
    
    JSR CONTINUE
    
    TST.B GAME_OVER
    BNE END_TURN

    *switch player
    NOT.B CURRENT_PLAYER

END_TURN:
    RTS

*-----------------------------------------------------------
*check hit
*-----------------------------------------------------------
CHECK_COORDINATES:
    *IN : D5 = row, D6 = col, A0 = board

    JSR GET_OFFSET
    MOVE.B (A0,D2.W), D4
    
    CMP.B #1, D4
    BEQ HIT
    
MISS:
    MOVE.B #3, (A0,D2.W)

    LEA MSG_MISS, A1
    JSR PRINT_MSG
    
    RTS
    
HIT:
    MOVE.B #4, (A0,D2.W)

    LEA MSG_HIT, A1
    JSR PRINT_MSG

    RTS

*-----------------------------------------------------------
*check win condition
*-----------------------------------------------------------
CHECK_WIN:
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
    RTS
    
NO_SHIPS_LEFT:
    MOVE.B #1, GAME_OVER
    
    RTS
    
*-----------------------------------------------------------
*print-board-as-grid
*-----------------------------------------------------------G
PRINT_ALL_BOARDS:
    *TRASHES : D0-D4, A0-A1
    *PRESERVES : D5-D7
    
    MOVEM.L D5-D7, -(A7)

    LEA MSG_P1_SHOW, A1
    JSR PRINT_MSG
    
    LEA BOARD_P1, A0
    JSR PRINT_BOARD_GRID

    LEA MSG_P2_SHOW, A1
    JSR PRINT_MSG
    
    LEA BOARD_P2, A0
    JSR PRINT_BOARD_GRID
    
    MOVEM.L (A7)+, D5-D7
    
    RTS
    
PRINT_BOARD_GRID:
    *IN : A0 = board
    
    MOVEM.L D5-D7, -(A7)

    LEA GRID_COL_HEADER, A1
    JSR PRINT_MSG
    
    MOVEQ #0, D3 ;index

PRINT_GRID_LOOP:
    CMP #16, D3
    BEQ DONE_GRID_PRINT
    
    MOVE.W D3, D4
    AND.W #3, D4
    CMP #0, D4
    BNE SKIP_ROW_LABEL

    ;row = (D3 / 4) + '1'
    MOVE.W D3, D4
    DIVU #4, D4 ;quotient = row
    AND.W #$00FF, D4
    ADD.B #'1', D4

    MOVE.B D4, D1
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
    MOVE.W D3, D4
    AND.W #3, D4
    CMP #0, D4
    BNE PRINT_GRID_LOOP
    
    JSR PRINT_NEWLINE
    
    BRA PRINT_GRID_LOOP

DONE_GRID_PRINT:
    JSR PRINT_NEWLINE
    
    MOVEM.L (A7)+, D5-D7
    
    RTS
    
*-----------------------------------------------------------
*helpers
*-----------------------------------------------------------
PRINT_NEWLINE:
    MOVE #6, D0
    MOVE #13, D1
    TRAP #15
    
    MOVE #6, D0
    MOVE #10, D1
    TRAP #15
    
    RTS
    
CONTINUE:
    LEA MSG_CONTINUE, A1
    JSR PRINT_MSG
    
    MOVE #5, D0
    TRAP #15

CLEAR_SCREEN:
    MOVE #11, D0
    MOVE.W #$FF00, D1
    TRAP #15
    
    JSR PRINT_GAME_TITLE
    
    RTS
    
RESET_CURSOR:
    MOVE #11, D0
    MOVE.W #$0000, D1 ;row=0 col=0
    TRAP #15
    
    RTS

*-----------------------------------------------------------
*messages
*-----------------------------------------------------------
PRINT_MSG:
    *IN : A1 = null-terminated string
    *TRASHES : D0
    
    JSR PRINT_NEWLINE
    
    MOVE #13, D0
    TRAP #15
    
    RTS
    
PRINT_GAME_TITLE:
    LEA MSG_GAME_TITLE, A1
    JSR PRINT_MSG
    
    RTS
    
PRINT_TURN_MSG:
    *IN : CURRENT_PLAYER
    *TRASHES : D0, A1
    *PRESERVERS : D5-D7
    
    MOVEM.L D5-D7, -(A7)
    
    TST.B CURRENT_PLAYER
    BEQ P1_TURN_MSG

    LEA MSG_P2_TURN, A1
    JSR PRINT_MSG
    BRA DONE_TURN_MSG
    
P1_TURN_MSG:
    LEA MSG_P1_TURN, A1
    JSR PRINT_MSG
    
DONE_TURN_MSG:
    MOVEM.L (A7)+, D5-D7
    
    RTS

PRINT_WINNER:
    *IN : CURRENT_PLAYER
    *TRASHES : D0, A1
    *PRESERVERS : D5-D7
    
    MOVEM.L D5-D7, -(A7)

    JSR CLEAR_SCREEN

    TST.B CURRENT_PLAYER
    BEQ P1_WIN_MSG

    LEA MSG_P2_WIN, A1
    JSR PRINT_MSG
    BRA DONE_WIN_MSG
    
P1_WIN_MSG:
    LEA MSG_P1_WIN, A1
    JSR PRINT_MSG

DONE_WIN_MSG:
    MOVEM.L (A7)+, D5-D7
    RTS

CHANGE_TURN:
    *TRASHES: D0, A1
    *PRESERVES: D5-D7

    MOVEM.L D5-D7, -(A7)

    LEA MSG_CHANGE_TURN, A1
    JSR PRINT_MSG

    MOVEM.L (A7)+, D5-D7
    
    RTS
    
    SIMHALT             ; halt simulator

* Put variables and constants here
BOARD_P1:      DS.B 16
BOARD_P2:      DS.B 16
 
CURRENT_PLAYER: DC.B 0 ;0 = P1, 1 = P2
  
GAME_OVER: DC.B 0

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
        
*game header
    MSG_GAME_TITLE:
        DC.B '=== BATTLES-AHOY! A BATTLESHIP GAME ==='
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
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
