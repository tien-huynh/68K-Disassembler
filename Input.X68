*-----------------------------------------------------------
* Title      :  Input
* Written by :  Tien Huynh
* Date       :  12/01/2017
* Description:  Read in ASCII char input, convert to Hex value to use as starting & ending address
*-----------------------------------------------------------




    ORG    $1000
START:                  ; first instruction of program

* Put program code here

                *LEA     $FFFFFFFF, SP      *Setup start of stack pointer
                LEA     welcomeMsg, A1      *Display welcome message
                MOVE.B  #14, D0
                TRAP    #15

*-------------------------------------------------------------------------------------
*Loop to read and check STARTING address input, then put okay address into A5 register                
START_INPUT     LEA     startInput, A1      *Prompt input for start address
                MOVE.B  #14, D0
                TRAP    #15
                              
                SUBA.L  A1, A1              *Clear A1 buffer for input with TRAP task #2
                MOVE.B  #2, D0
                TRAP    #15
                
                CLR.L   D5                  *Use D5 as buffer for input address configuration
                CLR.B   D2                  *Use D2 as flag for error in input (out of range OR non-Hex char): 1 == error, 0 == okay
                
                JSR     FIRST_INPUT_CHECK   *Jump to subroutine for checking Hex char input
                
                CMP.B   #1, D2              *Check D2 error flag, if errored go back to start
                BEQ     START_INPUT
                
                JSR     ADDRESS_RANGE_CHECK     *Jump to subroutine for checking out of range input (1000 to FFFFFF?)
                
                CMP.B   #1, D2              *Check D2 error flag, if errored go back to start
                BEQ     START_INPUT
                
                SUBA.L  A1, A1              *Clear A1 buffer
                MOVE.L  D5, A5              *Load accepted STARTING address into A5
                

*-------------------------------------------------------------------------------------                
*Loop to read and check ENDING address input, then put okay address into A6 register                  
END_INPUT       LEA     endInput, A1        *Prompt input for end address
                MOVE.B  #14, D0
                TRAP    #15
                
                SUBA.L  A1, A1              *Clear A1 buffer for input with TRAP task #2
                MOVE.B  #2, D0
                TRAP    #15
                
                CLR.L   D5                  *Use D5 as buffer for input address configuration
                CLR.B   D2                  *Use D2 as flag for error in input (out of range OR non-Hex char): 1 == error, 0 == okay
                
                JSR     FIRST_INPUT_CHECK   *Jump to subroutine for checking Hex char input
                
                CMP.B   #1, D2              *Check D2 error flag, if errored go back to start
                BEQ     END_INPUT
                
                JSR     ADDRESS_RANGE_CHECK     *Jump to subroutine for checking out of range input (1000 to FFFFFF?)
                
                CMP.B   #1, D2              *Check D2 error flag, if errored go back to start
                BEQ     END_INPUT
                
                SUBA.L  A1, A1              *Clear A1 buffer
                MOVE.L  D5, A6              *Load accepted ENDING address into A5

                
              SIMHALT  
*================================================================================================================================================
*SUBROUTINE SECTION
*================================================================================================================================================

*--------------------------------------------------
*Check for out of range address
ADDRESS_RANGE_CHECK     CMP.L   #$FFFFFF, D5        *Check > FFFFFF address
                        BGT     ADDRESS_RANGE_ERROR
                        CMP.L   #$1000, D5          *Check < 1000 address
                        BLT     ADDRESS_RANGE_ERROR
                        MOVE.B  #0, D2              *Set error flag
                        RTS

*--------------------------------------------------
*1st Input check: for lowercase a-f ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2                                           
FIRST_INPUT_CHECK   CMP.B   #$66, (A1)      *Check upper boundary for lowercase f in ASCII == 0x66; definitely not Hex value if above
                    BGT     TYPE_INPUT_ERROR
                    CMP.B   #$61, (A1)      *Check lower boundary for lowercase a in ASCII == 0x61; IS a-f Hex value if above, keep checking for A-F Hex value if below 
                    BLT     SECOND_INPUT_CHECK
                    SUB.B   #$57, (A1)      *Subtract 0x57 to convert a-f to equivalent Hex value
                    
                    JSR     ADDRESS_CONFIGURE   *Jump to subroutine for properly configure the address
                    
                    SUB.B   #1, D1          *Use D1 as a counter to check next char in user input
                    ADDQ.L  #1, A1          *Increment address pointer
                    CMP.B   #0, D1          *Check if all chars were checked, if not continue to check
                    BGT     FIRST_INPUT_CHECK
                    RTS


*--------------------------------------------------
*2nd Input check: for uppercase A-F ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2    
SECOND_INPUT_CHECK  CMP.B   #$46, (A1)      *Check upper boundary for uppercase F in ASCII == 0x46; definitely not Hex value if above  
                    BGT     TYPE_INPUT_ERROR
                    CMP.B   #$41, (A1)      *Check lower boundary for uppercase A in ASCII == 0x41; IS A-F Hex value if above, keep checking for numeric Hex value if below 
                    BLT     THIRD_INPUT_CHECK
                    SUB.B   #$37, (A1)      *Subtract 0x37 to convert A-F to equivalent Hex value
                    
                    JSR     ADDRESS_CONFIGURE   *Jump to subroutine for properly configure the address
                    
                    SUB.B   #1, D1          *Similar to 1st input check
                    ADDQ.L  #1, A1
                    CMP.B   #0, D1
                    BGT     FIRST_INPUT_CHECK
                    RTS

                    
*--------------------------------------------------
*3rd Input check: for numeric 0-9 ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2                        
THIRD_INPUT_CHECK   CMP.B   #$39, (A1)      *Check upper boundary for 9 in ASCII == 0x39; definitely not Hex value if above    
                    BGT     TYPE_INPUT_ERROR
                    CMP.B   #$30, (A1)      *Check lower boundary for 0 A in ASCII == 0x30; definitely not Hex value if below    
                    BLT     TYPE_INPUT_ERROR
                    SUB.B   #$30, (A1)      *Subtract 0x30 to convert 0-9 to equivalent Hex value
                    
                    JSR     ADDRESS_CONFIGURE     *Jump to subroutine for properly configure the address 
                    
                    SUB.B   #1, D1          *Similar to 1st input check
                    ADDQ.L  #1, A1
                    CMP.B   #0, D1
                    BGT     FIRST_INPUT_CHECK
                    RTS
              
                
*--------------------------------------------------
*Display error message for wrong input Hex and set error flag                
TYPE_INPUT_ERROR    LEA     typeInputError, A1
                    MOVE.B  #14, D0
                    TRAP    #15
                    MOVE.B  #1, D2      *use D2 as a flag to check input
                    RTS     


*--------------------------------------------------
*Display error message for out of range address and set error flag   
ADDRESS_RANGE_ERROR     LEA     addressRangeError, A1
                        MOVE.B  #14, D0
                        TRAP    #15
                        MOVE.B  #1, D2      *use D2 as a flag to check input
                        RTS     


*--------------------------------------------------
*Properly configure address 
ADDRESS_CONFIGURE   MOVE.B  (A1), D3    *put the converted Hex value into D3, this is in Byte so 0x0n => need to remove the preceding 0(nibble size) by bit shifting
                    MOVE.B  D1, D4      *move the current position of the converted Hex value to D4 buffer
                    SUB.B   #1, D4      *subtract 1 position for proper shifting
                    MULS    #4, D4      *multiply by 4 because of nibble shifting
                    LSL.L   D4, D3      *logical bit shift left to proper position, store in D3
                    ADD.L   D3, D5      *adding D3 to D5 as a way to transfer bits. D5 is the final configured address value
                    CLR.L   D3
                    RTS


     
*=============================================================================================================================================================
* Put variables and constants here
*=============================================================================================================================================================
CR              EQU     $0D     *carriage return
LF              EQU     $0A     *line feed
welcomeMsg      DC.B    'Welcome to the 68K Disassembler', CR, LF, 0
startInput      DC.B    'Please enter starting address in Hex: ', 0
endInput        DC.B    'Please enter ending address in Hex: ', 0
typeInputError  DC.B    'ERROR: Entered address NOT in Hex', CR, LF, 0
addressRangeError   DC.B    'ERROR: Address is out of range (1000 to FFFFFF)', CR, LF, 0
                    
CHECK           DC.B    'CHECK', 0
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
