* -----------------------------------------------------------
* Title      :  Dissassembler
* Written by :  Tien Huynh, Jeremy Luxon and Martin
* Date       :  12/01/2017 (v1)
* Description:  Read in ASCII char input, convert to Hex value to use as starting & ending address
*
* Update     :  12/02/2017 (v1.1) - Tien Huynh
*                   + Add current address display
*                   + Decode: NOP, RTS, JSR, ASR, ASL, NEG, ORI, CMPI, DATA, BRA, BCS, BGE, BLT, BVC
*               12/03/2017 (v1.2) - Tien Huynh
*                   + Decode: LSR, LSL, ROR, ROL
*                   + Fix: ASR, ASL
*                   + Useful function: DISPLAY_DATA_REGISTER (possibly for EA mode)
*               12/08/2017 (v1.3) - Jeremy Luxon
*                   + Improved formatting
*                   + Added check for word-aligned addresses
*               12/09/2017 (v1.4)
*                   + Tien Huynh: Added address displacement for branching OpCodes (BRA, BCS, BGE, BLT, BVC)
*                   + Jeremy Luxon: Added EA mode handling
*               12/14/2017 (v1.5)
*                    + Tien Huynh: EA works now. The EA flag must be put into D6 for DISPLAY_EA to works
*                                    EA flags:   DIRECT_DATAREG: #1
*                                                DIRECT_ADDREG: #2
*                                                INDIRECT_ADDREG: #3
*                                                INCREMENT_ADDREG: #4
*                                                DECREMENT_ADDREG: #5  
*                                                IMMEDIATE_DATA: #6
*                                                ABSOLUTE_WORD: #7
*                                                ABSOLUTE_LONG: #8
*                                   OpCode Size (B, W, L) also has a flag now in D6
*                                               B: #1
*                                               W: #2
*                                               L: #3
*                                    Decoded: BCLR, DIVS, MULS, LEA   
*               12/14/2017  
*                   + Martin Huang: Added source EA on opCode like MOVE.
*                                   Decoded: MOVE
* -----------------------------------------------------------


    ORG    $1000

START

* testing code here
    BRA     START_INPUT
    *JSR     START_INPUT
    *BRA.B   BRATEST
    *JSR   TEST_MOVE
    ASR.L   #2, D6     * TESTING
    ASR.W   D2, D7
    ASR.B   #7, D1

BRATEST    
    *MOVE.W  #$1022, A5
    *MOVE.W  #$2000, A6
    MOVE.W  D4, D3
    
    MOVE.B  D3, D5
    JMP     DECODE    
    LSR.L   #2, D6     * TESTING
    LSR.W   D2, D7
    LSR.B   #7, D1

    JMP TEST_JMP
    JSR (A6)
    JSR $1000395
    JSR $10
    MULS    #$40, D2
    DIVS    D3, D2
    LEA     PRINT_LEA, A4
    BCLR    D4, D3
    BCLR    D2, (A2)
    BCLR    #$04, (A0)
	ASL (A3)
	ASR (A4)
	LSL (A5)
	LSR (A6)
	ROL (A0)
	ROR (A1)
	ASL (A3)+
	ASR (A4)+
	LSL (A5)+
	LSR (A6)+
	ROL (A0)+
	ROR (A1)+
	ASL -(A3)
	ASR -(A4)
	LSL -(A5)
	LSR -(A6)
	ROL -(A0)
	ROR -(A1)
	ASL $11
	ASR $22
	LSL $33
	LSR $44
	ROL $55
	ROR $66
TEST_JMP
    ASL.L   #2, D6     * TESTING
    ASL.W   D2, D7
    ASL.B   #7, D1

    LSL.L   #2, D6     * TESTING
    LSL.W   D2, D7
    LSL.B   #7, D1

    ROR.L   #2, D6     * TESTING
    ROR.W   D2, D7
    ROR.B   #7, D1

    ROL.L   #2, D6     * TESTING
    ROL.W   D2, D7
    ROL.B   #7, D1

    NEG.L   D7
    ORI.B   #2, D2
TEST_MOVE
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    MOVE.L  #$2, D2
    
* start of disassembler
    LEA     welcomeMsg, A1      * Display welcome message
    MOVE.B  #14, D0
    TRAP    #15


* -------------------------------------------------------------------------------------
* Loop to read and check STARTING address input, then put okay address into A5 register
START_INPUT
    LEA     startInput, A1      * Prompt input for start address
    MOVE.B  #14, D0
    TRAP    #15

    SUBA.L  A1, A1              * Clear A1 buffer for input with TRAP task #2
    MOVE.B  #2, D0
    TRAP    #15

    CLR.L   D5                  * Use D5 as buffer for input address configuration
    CLR.B   D2                  * Use D2 as flag for error in input (out of range OR non-Hex char): 1 == error, 0 == okay

    JSR     FIRST_INPUT_CHECK   * Jump to subroutine for checking Hex char input

    CMP.B   #1, D2              * Check D2 error flag, if errored go back to start
    BEQ     START_INPUT

    JSR     ADDRESS_RANGE_CHECK * Jump to subroutine for checking out of range input (1000 to FFFFFF?)

    CMP.B   #1, D2              * Check D2 error flag, if errored go back to start
    BEQ     START_INPUT

    SUBA.L  A1, A1              * Clear A1 buffer
    MOVE.L  D5, A5              * Load accepted STARTING address into A5


* -------------------------------------------------------------------------------------
* Loop to read and check ENDING address input, then put okay address into A6 register
END_INPUT
    LEA     endInput, A1        * Prompt input for end address
    MOVE.B  #14, D0
    TRAP    #15

    SUBA.L  A1, A1              * Clear A1 buffer for input with TRAP task #2
    MOVE.B  #2, D0
    TRAP    #15

    CLR.L   D5                  * Use D5 as buffer for input address configuration
    CLR.B   D2                  * Use D2 as flag for error in input (out of range OR non-Hex char): 1 == error, 0 == okay

    JSR     FIRST_INPUT_CHECK   * Jump to subroutine for checking Hex char input

    CMP.B   #1, D2              * Check D2 error flag, if errored go back to start
    BEQ     END_INPUT

    JSR     ADDRESS_RANGE_CHECK * Jump to subroutine for checking out of range input (1000 to FFFFFF?)

    CMP.B   #1, D2              * Check D2 error flag, if errored go back to start
    BEQ     END_INPUT

    JSR     ADDRESS_DIFFERENCE_CHECK     * Jump to subroutine for checking difference in address (end <= start)

    CMP.B   #1, D2              * Check D2 error flag, if errored go back to start
    BEQ     END_INPUT

    SUBA.L  A1, A1              * Clear A1 buffer
    MOVE.L  D5, A6              * Load accepted ENDING address into A6


* -------------------------------------------------------------------------------------
* Start decoding OpCodes
DECODE
    LEA     NEWLINE, A1         * display a newline
    MOVE.B  #14, D0
    TRAP    #15
    
    JSR     LC

    CMP.L   A5, A6              * if address pointer has reached end, stop
    BLE     STOP
    MOVE.L  A5, D3              * set up buffers for DISPLAY_ADDRESS (See subroutine for detail)
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS     * display address in Hex (8-character address)
    MOVE.W  (A5), D5            * set up buffers for OpCode decoding, D5 to store original 16-bit data
    MOVE.W  D5, D3              * D3 used for masking information
    LEA     SIZE_DEFAULT, A2    * A2 used as buffer to hold size (B, W, L) if necessary, default is blank


* -------------------------------
* Check for NOP (fixed 16-bit data), no EA
    CMP.W   #NOP, D5
    BNE     OP_RTS
    LEA     PRINT_NOP, A1
    JSR     DISPLAY_OP
    ADDQ.L  #2, A5      * increment address pointer, word size
    JMP     DECODE


* -------------------------------
* Check for RTS (fixed 16-bit data), no EA
OP_RTS
    CMP.W   #RTS, D5
    BNE     OP_JSR
    LEA     PRINT_RTS, A1
    JSR     DISPLAY_OP
    ADDQ.L  #2, A5      * increment address pointer, word size
    JMP     DECODE


* -------------------------------
* Check for OpCodes with fixed first 10 bits and variable last 6 bits (5 to 0)

OP_JSR

    ANDI.W  #mask_5to0, D3      * Check for JSR
    CMP.W   #JSR, D3
    BNE     OP_BCLR_IMMEDIATE
    LEA     PRINT_JSR, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE     

*-----------------------------
* EA for destination     

IMMEDIATE_DATA_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to0, D3
    CMP.W   #EAmode_immediate, D3
    BEQ     IMMEDIATE_DATA_EA_CONFIRMED     
    RTS

ABSOLUTE_WORD_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to0, D3
    CMP.W   #EAmode_absolute_word, D3
    BEQ     ABSOLUTE_WORD_EA_CONFIRMED    
    RTS

ABSOLUTE_LONG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to0, D3
    CMP.W   #EAmode_absolute_long, D3
    BEQ     ABSOLUTE_LONG_CONFIRMED    
    RTS
    
DIRECT_DATAREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to3, D3
    CMP.W   #EAmode_data, D3
    BEQ     DIRECT_DATAREG_EA_CONFIRMED    
    RTS

DIRECT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to3, D3
    CMP.W   #EAmode_address, D3
    BEQ     DIRECT_ADDREG_EA_CONFIRMED    
    RTS    

INDIRECT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to3, D3
    CMP.W   #EAmode_indirect, D3
    BEQ     INDIRECT_ADDREG_EA_CONFIRMED  
    RTS

INCREMENT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to3, D3
    CMP.W   #EAmode_increment, D3
    BEQ     INCREMENT_ADDREG_EA_CONFIRMED
    RTS
    
DECREMENT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_5to3, D3
    CMP.W   #EAmode_decrement, D3
    BEQ     DECREMENT_ADDREG_EA_CONFIRMED
    RTS
    
DIRECT_DATAREG_EA_CONFIRMED
    MOVE.B  #1, D6
    RTS
    
DIRECT_ADDREG_EA_CONFIRMED
    MOVE.B  #2, D6
    RTS

INDIRECT_ADDREG_EA_CONFIRMED
    MOVE.B  #3, D6
    RTS

INCREMENT_ADDREG_EA_CONFIRMED
    MOVE.B  #4, D6
    RTS
    
DECREMENT_ADDREG_EA_CONFIRMED
    MOVE.B  #5, D6
    RTS    

IMMEDIATE_DATA_EA_CONFIRMED
    MOVE.B  #6, D6
    RTS
    
ABSOLUTE_WORD_EA_CONFIRMED
    MOVE.B  #7, D6
    RTS

ABSOLUTE_LONG_CONFIRMED
    MOVE.B  #8, D6
    RTS

*---------------------------------
* EA for source

S_IMMEDIATE_DATA_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_11to6, D3
    CMP.W   #S_EAmode_immediate, D3
    BEQ     S_IMMEDIATE_DATA_EA_CONFIRMED     
    RTS

S_ABSOLUTE_WORD_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_11to6, D3
    CMP.W   #S_EAmode_absolute_word, D3
    BEQ     S_ABSOLUTE_WORD_EA_CONFIRMED    
    RTS

S_ABSOLUTE_LONG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_11to6, D3
    CMP.W   #S_EAmode_absolute_long, D3
    BEQ     S_ABSOLUTE_LONG_CONFIRMED    
    RTS
    
S_DIRECT_DATAREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_8to6, D3
    CMP.W   #EAmode_data, D3
    BEQ     S_DIRECT_DATAREG_EA_CONFIRMED    
    RTS

S_DIRECT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_8to6, D3
    CMP.W   #S_EAmode_address, D3
    BEQ     S_DIRECT_ADDREG_EA_CONFIRMED    
    RTS    

S_INDIRECT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_8to6, D3
    CMP.W   #S_EAmode_indirect, D3
    BEQ     S_INDIRECT_ADDREG_EA_CONFIRMED  
    RTS

S_INCREMENT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_8to6, D3
    CMP.W   #S_EAmode_increment, D3
    BEQ     S_INCREMENT_ADDREG_EA_CONFIRMED
    RTS
    
S_DECREMENT_ADDREG_EA_CHECK
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.W  #maskExcept_8to6, D3
    CMP.W   #S_EAmode_decrement, D3
    BEQ     S_DECREMENT_ADDREG_EA_CONFIRMED
    RTS
 
*-------------------------
* store source EA mode in D4 buffer   
S_DIRECT_DATAREG_EA_CONFIRMED
    MOVE.B  #1, D4
    RTS
    
S_DIRECT_ADDREG_EA_CONFIRMED
    LEA     'HAHA',A1
    MOVE    #14,D0
    TRAP    #15
    MOVE.B  #2, D4
    RTS

S_INDIRECT_ADDREG_EA_CONFIRMED
    MOVE.B  #3, D4
    RTS

S_INCREMENT_ADDREG_EA_CONFIRMED
    MOVE.B  #4, D4
    RTS
    
S_DECREMENT_ADDREG_EA_CONFIRMED
    MOVE.B  #5, D4
    RTS    

S_IMMEDIATE_DATA_EA_CONFIRMED
    MOVE.B  #6, D4
    RTS
    
S_ABSOLUTE_WORD_EA_CONFIRMED
    MOVE.B  #7, D4
    RTS

S_ABSOLUTE_LONG_CONFIRMED
    MOVE.B  #8, D4
    RTS



OP_BCLR_IMMEDIATE
    CMP.W   #BCLR_IMMEDIATE, D3
    BNE     OP_ASR_MEM
    LEA     PRINT_BCLR, A1
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     BCLR_SIZE_CHECK
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    MOVE.W  D6, -(SP)
    MOVE.B  #1, D7
    JSR     EA_IMMEDIATE
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D6
    MOVE.W  (SP)+, D5      
    JSR     DISPLAY_EA   
    JMP     DECODE


* check for which shift opcode it is (if any) and load corresponding name, then display
OP_ASR_MEM
    CMP.W   #ASR_MEMORY, D3     * Check for ASR (memory shift)
    BNE     OP_ASL_MEM
    LEA     PRINT_ASR, A1       * load opcode name to display
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE
    
    
OP_ASL_MEM
    CMP.W   #ASL_MEMORY, D3     * Check for ASL (memory shift)
    BNE     OP_LSR_MEM
    LEA     PRINT_ASL, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE
    
OP_LSR_MEM
    CMP.W   #LSR_MEMORY, D3     * Check for LSR (memory shift)
    BNE     OP_LSL_MEM
    LEA     PRINT_LSR, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE

OP_LSL_MEM
    CMP.W   #LSL_MEMORY, D3     * Check for LSL (memory shift)
    BNE     OP_ROR_MEM
    LEA     PRINT_LSL, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE
    
OP_ROR_MEM
    CMP.W   #ROR_MEMORY, D3     * Check for ROR (memory rotate)
    BNE     OP_ROL_MEM
    LEA     PRINT_ROR, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE

OP_ROL_MEM
    CMP.W   #ROL_MEMORY, D3     * Check for ROL (memory rotate)
    BNE     MASK_7t0 
    LEA     PRINT_ROL, A1
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE


* -------------------------------
* Check for OpCodes with fixed first 8 bits and variable last 8 bits (7 to 0)
MASK_7t0
    MOVE.W  D5, D3          * use D3 as buffer for masking
    ANDI.L  #mask_7to0, D3  * mask bits 7 to 0

    CMP.W   #NEG, D3    * Check for NEG
    BEQ     OP_NEG

    CMP.W   #ORI, D3    * Check for ORI
    BEQ     OP_ORI

    CMP.W   #CMPI, D3   * Check for CMPI
    BEQ     OP_CMPI

    CMP.W   #BRA, D3    * Check for BRA
    BEQ     OP_BRA

    CMP.W   #BCS, D3    * Check for BCS
    BEQ     OP_BCS

    CMP.W   #BGE, D3    * Check for BGE
    BEQ     OP_BGE

    CMP.W   #BLT, D3    * Check for BLT
    BEQ     OP_BLT

    CMP.W   #BVC, D3    * Check for BVC
    BEQ     OP_BVC

* -------------------------------
* check for register versions of the shift opcodes

    MOVE.W  D5, D3              * use D3 as buffer for masking
    ANDI.L  #mask_11to9_7to5_2to0, D3   * mask the bits for the register shift opcodes

    CMP.W   #ASR_REGISTER, D3   * Check for ASR (register shift)
    BEQ     OP_ASR_REG

    CMP.W   #ASL_REGISTER, D3   * Check for ASL (register shift)
    BEQ     OP_ASL_REG

    CMP.W   #LSR_REGISTER, D3   * Check for LSR (register shift)
    BEQ     OP_LSR_REG

    CMP.W   #LSL_REGISTER, D3   * Check for LSL (register shift)
    BEQ     OP_LSL_REG

    CMP.W   #ROR_REGISTER, D3   * Check for ROR (register rotate)
    BEQ     OP_ROR_REG

    CMP.W   #ROL_REGISTER, D3   * Check for ROL (register rotate)
    BEQ     OP_ROL_REG

* -------------------------------
* check for OpCodes with fixed bits in 15-12 and 8-6: MULS, DIVS, BCLR, LEA

    MOVE.W  D5, D3              * use D3 as buffer for masking
    ANDI.L  #mask_11to9_5to0, D3   * mask the bits for the register shift opcodes

    CMP.W   #BCLR_REGISTER, D3   * Check for BCLR (register)
    BEQ     OP_BCLR_REG

    CMP.W   #MULS, D3   * Check for MULS
    BEQ     OP_MULS

    CMP.W   #DIVS, D3   * Check for DIVS
    BEQ     OP_DIVS

    CMP.W   #LEA, D3   * Check for LEA
    BEQ     OP_LEA


* ++++++++++++++++++++++++++
* +                        +
* + REMAINING OPCODES HERE +
* +                        +
* ++++++++++++++++++++++++++
*--------------------------------
* check for OpCodes  MOVE in 15-12 : MOVE.B, MOVE.W, MOVE.L
    MOVE.W D5, D3
    ANDI.L  #maskExcept_15to12, D3
    
    CMP.W   #MOVE_B, D3
    BEQ     OP_MOVEB
    
    CMP.W   #MOVE_W, D3
    BEQ     OP_MOVEW
    
    CMP.W   #MOVE_L, D3
    BEQ     OP_MOVEL
    
    
    
* -------------------------------
* DATA: Unknown OpCode or random data
OP_DATA
    LEA     PRINT_DATA, A1
    LEA     SIZE_DEFAULT, A2
    JSR     DISPLAY_OP
    MOVE.W  D5, D3            * set up buffers for DISPLAY_ADDRESS (See subroutine for detail)
    MOVE.B  #4, D4
    JSR     DISPLAY_ADDRESS     * display data in Hex (4-character data)

    ADDQ.L  #2, A5          * increment address pointer, word size


    JMP     DECODE


STOP
    SIMHALT


* ================================================================================================================================================
* SUBROUTINE SECTION
* ================================================================================================================================================

* --------------------------------------------------
* Print OpCode ASR (register shift), go back to DECODE loop           [Don't need EA]
OP_ASR_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_ASR, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0

    ADDQ.L  #2, A5          * increment address pointer, word size


    JMP     DECODE

* --------------------------------------------------
* Print OpCode ASL (register shift), go back to DECODE loop           [Don't need EA]
OP_ASL_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_ASL, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0

    ADDQ.L  #2, A5          * increment address pointer, word size


    JMP     DECODE

* --------------------------------------------------
* Print OpCode LSR (register shift), go back to DECODE loop           [Don't need EA]
OP_LSR_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_LSR, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0

    ADDQ.L  #2, A5          * increment address pointer, word size


    JMP     DECODE

* --------------------------------------------------
* Print OpCode LSL (register shift), go back to DECODE loop           [Don't need EA]
OP_LSL_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_LSL, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DECODE

* -------------------------------------------------
* Print OpCode ROR (register shift), go back to DECODE loop           [Don't need EA]
OP_ROR_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_ROR, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0

    ADDQ.L  #2, A5          * increment address pointer, word size


    JMP     DECODE

* --------------------------------------------------
* Print OpCode ROL (register shift), go back to DECODE loop           [Don't need EA]
OP_ROL_REG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_ROL, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     CHECK_INSTRUCTION_BIT5
    JSR     DISPLAY_COMMA
    JSR     CHECK_REGISTER_BIT_2TO0
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DECODE

* --------------------------------------------------
* Print OpCode NEG (register shift), go back to DECODE loop           [NEED EA]
OP_NEG
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_NEG, A1   * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JMP     DECODE

* --------------------------------------------------
* Print OpCode ORI (register shift), go back to DECODE loop           [NEED EA]
OP_ORI
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_ORI, A1   * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    MOVE.W  D6, -(SP)
    JSR     EA_IMMEDIATE
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D6
    MOVE.W  (SP)+, D5     
    JSR     DISPLAY_EA
    JMP     DECODE


* --------------------------------------------------
* Print OpCode CMPI (register shift), go back to DECODE loop           [NEED EA]
OP_CMPI
    JSR     SIZE_7_TO_6     * check operand size (B, W, L)
    CMP.B   #1, D2          * check invalid size, if yes branch to DATA
    BEQ     OP_DATA
    LEA     PRINT_CMPI, A1  * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    MOVE.W  D6, -(SP)
    JSR     EA_IMMEDIATE
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D6
    MOVE.W  (SP)+, D5     
    JSR     DISPLAY_EA
    JMP     DECODE

* --------------------------------------------------
* Print OpCode BRA, go back to DECODE loop           [NEED EA]
OP_BRA
    JSR     SIZE_7_TO_0     * check operand size (B, W, L)
    LEA     PRINT_BRA, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     LOAD_ADDRESS_DISPLACEMENT
    CLR.L   D4
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS * display address to branch to in Hex (8-character address)
    JMP     DECODE

* --------------------------------------------------
* Print OpCode BCS, go back to DECODE loop           [NEED EA]
OP_BCS
    JSR     SIZE_7_TO_0     * check operand size (B, W, L)
    LEA     PRINT_BCS, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     LOAD_ADDRESS_DISPLACEMENT
    CLR.L   D4
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS * display address to branch to in Hex (8-character address)
    JMP     DECODE


* --------------------------------------------------
* Print OpCode BGE, go back to DECODE loop           [NEED EA]
OP_BGE
    JSR     SIZE_7_TO_0     * check operand size (B, W, L)
    LEA     PRINT_BGE, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     LOAD_ADDRESS_DISPLACEMENT
    CLR.L   D4
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS * display address to branch to in Hex (8-character address)
    JMP     DECODE


* --------------------------------------------------
* Print OpCode BLT, go back to DECODE loop           [NEED EA]
OP_BLT
    JSR     SIZE_7_TO_0     * check operand size (B, W, L)
    LEA     PRINT_BLT, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     LOAD_ADDRESS_DISPLACEMENT
    CLR.L   D4
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS * display address to branch to in Hex (8-character address)
    JMP     DECODE

* --------------------------------------------------
* Print OpCode BVC, go back to DECODE loop           [NEED EA]
OP_BVC
    JSR     SIZE_7_TO_0     * check operand size (B, W, L)
    LEA     PRINT_BVC, A1   * load OpCode to display
    JSR     DISPLAY_OP
    JSR     LOAD_ADDRESS_DISPLACEMENT
    CLR.L   D4
    MOVE.B  #8, D4
    JSR     DISPLAY_ADDRESS * display address to branch to in Hex (8-character address)
    JMP     DECODE

OP_BCLR_REG
    LEA     PRINT_BCLR, A1  * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     BCLR_SIZE_CHECK
    JSR     DISPLAY_OP
    JSR     DISPLAY_DATAREG_11t9
    JSR     DISPLAY_COMMA   
    JSR     DISPLAY_EA   
    JMP     DECODE

BCLR_SIZE_CHECK
    CMP.B   #1, D6
    BEQ     LOAD_L_SIZE
    JMP     LOAD_B_SIZE


OP_MULS
    MOVE.B  #2, D7  *size is always W
    LEA     PRINT_MULS, A1  * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    JSR     IMMEDIATE_DATA_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D5
    JSR     DISPLAY_DATAREG_11t9   
    JMP     DECODE
    
OP_DIVS
    MOVE.B  #2, D7  *size is always W
    LEA     PRINT_DIVS, A1  * load OpCode to display
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    JSR     IMMEDIATE_DATA_EA_CHECK
    CMP.B   #0, D6
    BEQ     OP_DATA
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D5
    JSR     DISPLAY_DATAREG_11t9   
    JMP     DECODE
    
OP_LEA
    MOVE.B  #3, D7  *size is always W
    LEA     PRINT_LEA, A1  * load OpCode to display
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    
    CMP.B   #0, D6
    BEQ     OP_DATA
    
    JSR     DISPLAY_OP
    MOVE.W  D5, -(SP)
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA
    MOVE.W  (SP)+, D5
    JSR     DISPLAY_ADDREG_11t9   
    JMP     DECODE
    
    
*---------------------------------------------------
* Move opcode

OP_MOVEB
    MOVE.B  #1, D7  *size is always B
    LEA     PRINT_MOVE, A1  * load OpCode to display
    JSR     LOAD_B_SIZE
    LEA     PRINT_DATA,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    JSR     IMMEDIATE_DATA_EA_CHECK
    JSR     DIRECT_ADDREG_EA_CHECK
    
    JSR     S_DIRECT_DATAREG_EA_CHECK
    JSR     S_INDIRECT_ADDREG_EA_CHECK
    JSR     S_INCREMENT_ADDREG_EA_CHECK
    JSR     S_DECREMENT_ADDREG_EA_CHECK
    JSR     S_ABSOLUTE_WORD_EA_CHECK
    JSR     S_ABSOLUTE_LONG_EA_CHECK

    CMP.B   #0, D6          * check destination EA
    BEQ     OP_DATA
    
    CMP.B   #0, D4          * check source EA
    BEQ     OP_DATA
    
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA   
    JSR     S_DISPLAY_EA   
    JMP     DECODE

OP_MOVEW
    MOVE.B  #2, D7  *size is always W
    LEA     PRINT_MOVE, A1  * load OpCode to display
    JSR     LOAD_W_SIZE
    
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    JSR     IMMEDIATE_DATA_EA_CHECK
    JSR     DIRECT_ADDREG_EA_CHECK
    
    JSR     S_DIRECT_DATAREG_EA_CHECK
    JSR     S_INDIRECT_ADDREG_EA_CHECK
    JSR     S_INCREMENT_ADDREG_EA_CHECK
    JSR     S_DECREMENT_ADDREG_EA_CHECK
    JSR     S_ABSOLUTE_WORD_EA_CHECK
    JSR     S_ABSOLUTE_LONG_EA_CHECK
    

    CMP.B   #0, D6          * check destination EA
    BEQ     OP_DATA
    
    
    
    CMP.B   #0, D4          * check source EA
    BEQ     OP_DATA
    
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA   
    JSR     S_DISPLAY_EA   
    JMP     DECODE

OP_MOVEL
    MOVE.B  #3, D7  *size is always W
    LEA     PRINT_MOVE, A1  * load OpCode to display
    JSR     LOAD_L_SIZE
    
    JSR     DIRECT_DATAREG_EA_CHECK
    JSR     INDIRECT_ADDREG_EA_CHECK
    JSR     INCREMENT_ADDREG_EA_CHECK
    JSR     DECREMENT_ADDREG_EA_CHECK
    JSR     ABSOLUTE_WORD_EA_CHECK
    JSR     ABSOLUTE_LONG_EA_CHECK
    JSR     IMMEDIATE_DATA_EA_CHECK
    JSR     DIRECT_ADDREG_EA_CHECK
    
    JSR     S_DIRECT_DATAREG_EA_CHECK
    JSR     S_INDIRECT_ADDREG_EA_CHECK
    JSR     S_INCREMENT_ADDREG_EA_CHECK
    JSR     S_DECREMENT_ADDREG_EA_CHECK
    JSR     S_ABSOLUTE_WORD_EA_CHECK
    JSR     S_ABSOLUTE_LONG_EA_CHECK

    CMP.B   #0, D6          * check destination EA
    BEQ     OP_DATA
    
    CMP.B   #0, D4          * check source EA
    BEQ     OP_DATA
    
    JSR     DISPLAY_OP
    JSR     DISPLAY_EA
    JSR     DISPLAY_COMMA   
    JSR     S_DISPLAY_EA   
    JMP     DECODE

* --------------------------------------------------
* Determine size (B, W, or L) of OpCodes whose size bits are in bit 7 and 6. Store size information in D3
SIZE_7_TO_6
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.L  #maskExcept_7to6, D3    * mask everything except the size bit 7-6
    CMP.W   #sizeB_7to6, D3         * check for size B (00)
    BEQ     LOAD_B_SIZE
    CMP.W   #sizeW_7to6, D3         * check for size W (01)
    BEQ     LOAD_W_SIZE
    CMP.W   #sizeL_7to6, D3         * check for size L (10)
    BEQ     LOAD_L_SIZE
    MOVE.B  #1, D2                  * [CHECK LAST CASE (11)] D2 flags unknown size
    RTS


* --------------------------------------------------
* Determine size (B, W, or L) of OpCodes whose size bits are determined based on bit 7 and 0 (displacement field). Store size information in D3
SIZE_7_TO_0
    MOVE.W  D5, D3                  * D3 as buffer for masking
    ANDI.L  #maskExcept_7to0, D3    * mask everything except the size bit 7-0
    CMP.W   #sizeW_7to0, D3         * check for size W (0x00 i.e. all 0s in bit 7-0)
    BEQ     LOAD_W_SIZE
    CMP.W   #sizeL_7to0, D3         * check for size L (0xFF i.e. all 1s in bit 7-0)
    BEQ     LOAD_L_SIZE
    JMP     LOAD_B_SIZE             * else it is size B



LOAD_B_SIZE
    LEA     PRINT_B, A2
    MOVE.B  #1, D7
    RTS



LOAD_W_SIZE
    LEA     PRINT_W, A2
    MOVE.B  #2, D7
    RTS


LOAD_L_SIZE
    LEA     PRINT_L, A2
    MOVE.B  #3, D7
    RTS

LOAD_ADDRESS_DISPLACEMENT
    CMP.B   #1, D7
    BEQ     BYTE_DISPLACEMENT
    CMP.B   #2, D7
    BEQ     WORD_DISPLACEMENT
    JMP     LONG_DISPLACEMENT  
    
BYTE_DISPLACEMENT
    MOVE.B  D5, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  A5, D4
    CMP.B   #byteNegative, D3
    BHS     TWO_COMPLEMENT_BYTE
    ADD.L   D4, D3
    RTS

WORD_DISPLACEMENT
    MOVE.W  D5, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  A5, D4
    MOVE.W  (A5), D3
    CMP.W   #wordNegative, D3
    BHS     TWO_COMPLEMENT_WORD
    ADD.L   D4, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    RTS

LONG_DISPLACEMENT
    MOVE.W  D5, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  A5, D4
    MOVE.L  (A5), D3
    CMP.L   #longNegative, D3
    BHS     TWO_COMPLEMENT_LONG
    ADD.L   D4, D3
    ADDQ.L  #4, A5          * increment address pointer, long size
    RTS
    

TWO_COMPLEMENT_BYTE
    NEG.B   D3
    SUB.L   D3, D4
    MOVE.L  D4, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    RTS

TWO_COMPLEMENT_WORD
    NEG.W   D3
    SUB.L   D3, D4
    MOVE.L  D4, D3
    ADDQ.L  #2, A5          * increment address pointer, word size
    RTS

TWO_COMPLEMENT_LONG
    NEG.L   D3
    SUB.L   D3, D4
    MOVE.L  D4, D3
    ADDQ.L  #4, A5          * increment address pointer, long size
    RTS

DISPLAY_DATAREG_11t9
    MOVE.W  D5, D7              * D7 as buffer for masking for register display
    ANDI.L  #maskExcept_11to9, D7   * prepare buffer for display
    LSR.L   #8, D7
    LSR.L   #1, D7
    JMP     DISPLAY_DATA_REGISTER
    
DISPLAY_ADDREG_11t9
    MOVE.W  D5, D7              * D7 as buffer for masking for register display
    ANDI.L  #maskExcept_11to9, D7   * prepare buffer for display
    LSR.L   #8, D7
    LSR.L   #1, D7
    JMP     DISPLAY_ADDR_REGISTER

CHECK_INSTRUCTION_BIT5
    MOVE.W  D5, D3              * D3 as buffer for masking for instruction check
    MOVE.W  D5, D7              * D7 as buffer for masking for register/count display
    ANDI.L  #maskExcept_11to9, D7   * prepare buffer for display
    LSR.L   #8, D7
    LSR.L   #1, D7
    ANDI.L  #maskExcept_5, D3       * determine instruction
    CMP.L   #maskExcept_5, D3
    BEQ     DISPLAY_DATA_REGISTER
    JMP     DISPLAY_COUNT


CHECK_REGISTER_BIT_2TO0
    MOVE.W  D5, D7                  * D7 as buffer for masking for register display
    ANDI.L  #maskExcept_2to0, D7    * prepare buffer for display
    JMP     DISPLAY_DATA_REGISTER



* MASK_5_TO_0         ANDI.L  #mask_5to0, D3
*
* MASK_7_TO_0         ANDI.L  #mask_7to0, D3
*
* MASK_10_5_TO_0      ANDI.L  #mask_10and5to0, D3
*
* MASK_11_TO_9_5_TO_0     ANDI.L  #mask_11to9and5to0, D3
*
* MASK_11_TO_9_5_2_TO_0     ANDI.L  #mask_11to9_5and2to0, D3
*
* MASK_13_TO_0        ANDI.L  #mask_13to0, D3
*
* MASK_13_TO_9_5_TO_0     ANDI.L  #mask_13to9and5to0, D3


* --------------------------------------------------
* Convert address from Hex value to ASCII char to display to console
* Address to be converted needs to load in D3, the number of character in address needs to load in D4
DISPLAY_ADDRESS
    SUB.B   #1, D4      * subtract 1 position for proper shifting
    MOVE.B  D4, D5      * move the position currently pointed address char to D5 buffer
    MOVE.L  D3, D6      * move the whole Hex address value to D6 buffer for masking
    MULS    #4, D5      * multiply by 4 because of nibble shifting
    LSR.L   D5, D6      * logical bit shift right to proper position (i.e. last nibble), store in D6
    MOVE.L  D6, D1      * move shifted bit to D1 for TRAP task #6 char display
    JSR     HEX_CHAR_TO_ASCII   * jump to subroutine to convert hex to ASCII
    CMP.B   #0, D4      * use D4 as counter to run through the whole address, reaching 0 value mean finished
    BNE     DISPLAY_ADDRESS     * loop back
    RTS


* --------------------------------------------------
* Convert Hex value (only A-F) to ASCII char
HEX_CHAR_TO_ASCII
    ANDI.L  #bitmaskConversion, D1      * mask everythign except the last Byte (storing the single nibble value to be converted)
    CMP.B   #$A, D1                     * compare with 0xA, smaller mean numeric hex, so jump to numeric subroutine
    BLT     HEX_NUM_TO_ASCII
    ADD.B   #$37, D1                    * add 0x37 to convert A-F Hex to equivalent ASCII value
    MOVE.B  #6, D0                      * display char to console
    TRAP    #15
    RTS

* --------------------------------------------------
* Convert numeric Hex value (only 0-9) to ASCII char
HEX_NUM_TO_ASCII
    ADD.B   #$30, D1        * add 0x30 to convert 0-9 Hex to equivalent ASCII value
    MOVE.B  #6, D0          * display char to console
    TRAP    #15
    RTS



* --------------------------------------------------
* Check for difference in address (end <= start)
ADDRESS_DIFFERENCE_CHECK
    CMP.L   A5, D5
    BLE     ADDRESS_DIFFERENCE_ERROR
    MOVE.B  #0, D2              * Set error flag as okay
    RTS


* --------------------------------------------------
* Check for out of range address
ADDRESS_RANGE_CHECK
    CMP.L   #$FFFFFF, D5        * Check > FFFFFF address
    BGT     ADDRESS_RANGE_ERROR
    CMP.L   #$1000, D5          * Check < 1000 address
    BLT     ADDRESS_RANGE_ERROR
    MOVE.L  D5, D6              * copy to D6 and mask with 1 to check if it's odd (should be even to align to word)
    AND.L   #$01, D6
    BHI     ADDRESS_ODD_ERROR
    MOVE.B  #0, D2              * Set error flag as okay
    RTS

* --------------------------------------------------
* 1st Input check: for lowercase a-f ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2
FIRST_INPUT_CHECK
    CMP.B   #$66, (A1)      * Check upper boundary for lowercase f in ASCII == 0x66; definitely not Hex value if above
    BGT     TYPE_INPUT_ERROR
    CMP.B   #$61, (A1)      * Check lower boundary for lowercase a in ASCII == 0x61; IS a-f Hex value if above, keep checking for A-F Hex value if below
    BLT     SECOND_INPUT_CHECK
    SUB.B   #$57, (A1)      * Subtract 0x57 to convert a-f to equivalent Hex value

    JSR     ADDRESS_CONFIGURE   * Jump to subroutine for properly configure the address

    SUB.B   #1, D1          * Use D1 as a counter to check next char in user input
    ADDQ.L  #1, A1          * Increment address pointer
    CMP.B   #0, D1          * Check if all chars were checked, if not continue to check
    BGT     FIRST_INPUT_CHECK
    RTS


* --------------------------------------------------
* 2nd Input check: for uppercase A-F ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2
SECOND_INPUT_CHECK
    CMP.B   #$46, (A1)      * Check upper boundary for uppercase F in ASCII == 0x46; definitely not Hex value if above
    BGT     TYPE_INPUT_ERROR
    CMP.B   #$41, (A1)      * Check lower boundary for uppercase A in ASCII == 0x41; IS A-F Hex value if above, keep checking for numeric Hex value if below
    BLT     THIRD_INPUT_CHECK
    SUB.B   #$37, (A1)      * Subtract 0x37 to convert A-F to equivalent Hex value

    JSR     ADDRESS_CONFIGURE   * Jump to subroutine for properly configure the address

    SUB.B   #1, D1          * Similar to 1st input check
    ADDQ.L  #1, A1
    CMP.B   #0, D1
    BGT     FIRST_INPUT_CHECK
    RTS


* --------------------------------------------------
* 3rd Input check: for numeric 0-9 ASCII chars, then convert them to Hex values. Operate char by char, user input length is in D1 based on TRAP #2
THIRD_INPUT_CHECK
    CMP.B   #$39, (A1)      * Check upper boundary for 9 in ASCII == 0x39; definitely not Hex value if above
    BGT     TYPE_INPUT_ERROR
    CMP.B   #$30, (A1)      * Check lower boundary for 0 A in ASCII == 0x30; definitely not Hex value if below
    BLT     TYPE_INPUT_ERROR
    SUB.B   #$30, (A1)      * Subtract 0x30 to convert 0-9 to equivalent Hex value

    JSR     ADDRESS_CONFIGURE     * Jump to subroutine for properly configure the address

    SUB.B   #1, D1          * Similar to 1st input check
    ADDQ.L  #1, A1
    CMP.B   #0, D1
    BGT     FIRST_INPUT_CHECK
    RTS


* --------------------------------------------------
* Display error message for wrong input Hex and set error flag
TYPE_INPUT_ERROR
    LEA     typeInputError, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.B  #1, D2      * use D2 as a flag to check input
    RTS


* --------------------------------------------------
* Display error message for out of range address and set error flag
ADDRESS_RANGE_ERROR
    LEA     addressRangeError, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.B  #1, D2      * use D2 as a flag to check input
    RTS


* --------------------------------------------------
* Display error message for odd address and set error flag
ADDRESS_ODD_ERROR
    LEA     addressOddError, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.B  #1, D2      * use D2 as a flag to check input
    RTS


* --------------------------------------------------
* Display error message for address difference (end <= start) and set error flag
ADDRESS_DIFFERENCE_ERROR
    LEA     addressDifferentError, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.B  #1, D2      * use D2 as a flag to check input
    RTS


* --------------------------------------------------
* Properly configure address
ADDRESS_CONFIGURE
    MOVE.B  (A1), D3    * put the converted Hex value into D3, this is in Byte so 0x0n => need to remove the preceding 0(nibble size) by bit shifting
    MOVE.B  D1, D4      * move the current position of the converted Hex value to D4 buffer
    SUB.B   #1, D4      * subtract 1 position for proper shifting
    MULS    #4, D4      * multiply by 4 because of nibble shifting
    LSL.L   D4, D3      * logical bit shift left to proper position, store in D3
    ADD.L   D3, D5      * adding D3 to D5 as a way to transfer bits. D5 is the final configured address value
    CLR.L   D3
    RTS


* --------------------------------------------------
* Print out OpCode and Size if necessary, OpCode in A1, Size in A2
DISPLAY_OP
    MOVE.B  #14, D0     * print opcode from A1
    TRAP    #15

    MOVE.L  A2, A1      * print size from A2
    MOVE.B  #14, D0
    TRAP    #15

    *ADDQ.L  #2, A5      * increment address pointer, word size

    RTS

* --------------------------------------------------
* Print out Data Register as 'D[number]', 3 bits that represent the value of the register must be stored in D7
DISPLAY_DATA_REGISTER
    MOVE.B  #$44, D1            * 0x44 is hex value for 'D' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    MOVE.L  D7, D1              * print the number value
    MOVE.B  #3, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* Print out address register as 'A[number]', 3 bits that represent the value of the register must be stored in D7
DISPLAY_ADDR_REGISTER
    MOVE.B  #$41, D1            * 0x41 is hex value for 'A' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    MOVE.L  D7, D1              * print the number value
    MOVE.B  #3, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* Print out address register as '(A[number])', 3 bits that represent the value of the register must be stored in D7
DISPLAY_ADDR_INDIRECT
    MOVE.B  #$28, D1            * 0x28 is hex value for '(' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    JSR DISPLAY_ADDR_REGISTER

    MOVE.L  #$29, D1            * 0x28 is hex value for ')' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* Print out address register as '(A[number])+', 3 bits that represent the value of the register must be stored in D7
DISPLAY_ADDR_INCREMENT
    JSR     DISPLAY_ADDR_INDIRECT

    MOVE.L  #$2B, D1            * 0x2B is hex value for '+' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* Print out address register as '-(A[number])', 3 bits that represent the value of the register must be stored in D7
DISPLAY_ADDR_DECREMENT   
    MOVE.L  #$2D, D1            * 0x2D is hex value for '-' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    JSR     DISPLAY_ADDR_INDIRECT

    RTS

* --------------------------------------------------
* Print out immediate as '#[number]', 3 bits that represent the value of the register must be stored in D7
* NOTE: Used in shifting OpCodes (ASR, ASL, LSR, LSL, ROR, ROL) and for EA
DISPLAY_COUNT
    MOVE.B  #$23, D1    * 0x23 is hex value for '#' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    MOVE.L  D7, D1      * print the number value
    MOVE.B  #3, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* Print out immediate as '$[value]', value must be stored in D7
DISPLAY_HEX
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    MOVE.B  #16, D2     * print in base 16
    MOVE.L  D7, D1      * print the number value
    MOVE.B  #15, D0
    TRAP    #15

    RTS

* --------------------------------------------------
* print EA info for opcode
DISPLAY_EA

    CMP.B   #1, D6
    BEQ     EA_DATAREG
    CMP.B   #2, D6
    BEQ     EA_ADDREG
    CMP.B   #3, D6
    BEQ     EA_INDIRECT
    CMP.B   #4, D6
    BEQ     EA_INCREMENT
    CMP.B   #5, D6
    BEQ     EA_DECREMENT
    CMP.B   #6, D6
    BEQ     EA_IMMEDIATE
    CMP.B   #7, D6
    BEQ     EA_ABS_WORD
    JMP     EA_ABS_LONG

S_DISPLAY_EA
    CMP.B   #1, D4
    BEQ     S_EA_DATAREG
    CMP.B   #2, D4
    BEQ     S_EA_ADDREG
    CMP.B   #3, D4
    BEQ     S_EA_INDIRECT
    CMP.B   #4, D4
    BEQ     S_EA_INCREMENT
    CMP.B   #5, D4
    BEQ     S_EA_DECREMENT
    CMP.B   #6, D4
    BEQ     S_EA_IMMEDIATE
    CMP.B   #7, D4
    BEQ     S_EA_ABS_WORD
    JMP     S_EA_ABS_LONG
    
EA_DATAREG
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_2to0, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_DATA_REGISTER

EA_ADDREG
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_2to0, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_REGISTER
    
EA_INDIRECT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_2to0, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_INDIRECT  

EA_INCREMENT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_2to0, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_INCREMENT  
    
EA_DECREMENT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_2to0, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_DECREMENT  

EA_IMMEDIATE
    MOVE.B  #$23, D1    * 0x23 is hex value for '#' ACSII char
    MOVE.B  #6, D0
    TRAP    #15
    
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15
    
    CMP.B   #1, D7
    BEQ     DISPLAY_BYTE_IMMEDIATE_DATA
    CMP.B   #2, D7
    BEQ     DISPLAY_WORD_IMMEDIATE_DATA
    JMP     DISPLAY_LONG_IMMEDIATE_DATA


DISPLAY_BYTE_IMMEDIATE_DATA
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.W  (A5), D3
    MOVE.B  #2, D4
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDRESS

DISPLAY_WORD_IMMEDIATE_DATA
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.W  (A5), D3
    MOVE.B  #4, D4
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDRESS


DISPLAY_LONG_IMMEDIATE_DATA    
    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  (A5), D3
    MOVE.B  #8, D4
    ADDQ.L  #4, A5          * increment address pointer, long size
    JMP     DISPLAY_ADDRESS
    
    
* -------------------------------------------
* EA display desntination 
S_EA_DATAREG
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_11to9, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_DATA_REGISTER

S_EA_ADDREG
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_11to9, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_REGISTER
    
S_EA_INDIRECT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_11to9, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_INDIRECT  

S_EA_INCREMENT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_11to9, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_INCREMENT  
    
S_EA_DECREMENT
    MOVE.W  D5, D7                  * put EA register in D7
    ANDI.W  #maskExcept_11to9, D7
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDR_DECREMENT  

S_EA_IMMEDIATE
    MOVE.B  #$23, D1    * 0x23 is hex value for '#' ACSII char
    MOVE.B  #6, D0
    TRAP    #15
    
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15
    
    CMP.B   #1, D7
    BEQ     DISPLAY_BYTE_IMMEDIATE_DATA
    CMP.B   #2, D7
    BEQ     DISPLAY_WORD_IMMEDIATE_DATA
    JMP     DISPLAY_LONG_IMMEDIATE_DATA

S_EA_ABS_WORD
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.W  (A5), D3
    MOVE.B  #4, D4
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDRESS

S_EA_ABS_LONG
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  (A5), D3
    MOVE.B  #8, D4
    ADDQ.L  #4, A5          * increment address pointer, long size
    JMP     DISPLAY_ADDRESS




EA_ABS_WORD
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.W  (A5), D3
    MOVE.B  #4, D4
    ADDQ.L  #2, A5          * increment address pointer, word size
    JMP     DISPLAY_ADDRESS

EA_ABS_LONG
    MOVE.B  #$24, D1    * 0x24 is hex value for '$' ACSII char
    MOVE.B  #6, D0
    TRAP    #15

    ADDQ.L  #2, A5          * increment address pointer, word size
    MOVE.L  (A5), D3
    MOVE.B  #8, D4
    ADDQ.L  #4, A5          * increment address pointer, long size
    JMP     DISPLAY_ADDRESS



* --------------------------------------------------
* Print out a comma and space ', '
DISPLAY_COMMA
    LEA     PRINT_COMMA, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
* -----------------------------------------------------
* STOP WHEN REACH THE END OF LINE
LC   LEA     lines,A4    * A4 stack
            ADDI.B  #$1,(A4)    * +1 when the is called
            CMP.B   #30,(A4)    * each the end of page which is 30 will stop
            BEQ     stopHERE        
            RTS                 
*------------------------------
* will stop the program here            
stopHERE
            CLR     D1
            MOVE.B  #00,(A4)     * reset
            LEA     EnterMSG,A1  * load msg to window
            MOVE.B  EB,D1  
            MOVE.L  #1,D0        
            TRAP    #15          
            LEA     Halt,A1    * Load address to store user input
            MOVE.L  #2,D0       * Load task code for user input
            TRAP    #15         * Retrieve input
            RTS                 * Return to the main program loop

* ==================================================================================================================
* variables and constants
* ==================================================================================================================
CR              EQU     $0D     * carriage return
LF              EQU     $0A     * line feed
welcomeMsg      DC.B    'Welcome to the 68K Disassembler', CR, LF, 0
startInput      DC.B    'Please enter starting address in Hex(Range from $1000 to $FFFFFF): ', 0
endInput        DC.B    'Please enter ending address in Hex: ', 0
typeInputError  DC.B    'ERROR: Entered address NOT in Hex', CR, LF, 0
addressRangeError       DC.B    'ERROR: Address is out of range (1000 to FFFFFF)', CR, LF, 0
addressDifferentError   DC.B    'ERROR: Ending address must be larger than Starting address', CR, LF, 0
addressOddError         DC.B    'ERROR: Address must be even (word aligned)', CR, LF, 0


bitmaskConversion           EQU       $0000000F
mask_5to0                   EQU       %1111111111000000
mask_7to0                   EQU       %1111111100000000
mask_10_6to0                EQU       %1111101110000000
mask_11to9_5to0             EQU       %1111000111000000
mask_11to9_7to5_2to0        EQU       %1111000100011000
mask_13to0                  EQU       %1100000000000000
mask_13to9and5to0           EQU       %1100000111000000

maskExcept_7to6             EQU       %0000000011000000
maskExcept_7to0             EQU       %0000000011111111
maskExcept_5                EQU       %0000000000100000
maskExcept_11to9            EQU       %0000111000000000
maskExcept_2to0             EQU       %0000000000000111
maskExcept_5to3             EQU       %0000000000111000
maskExcept_5to0             EQU       %0000000000111111
maskExcept_15to12           EQU       %1111000000000000
maskExcept_11to6            EQU       %0000111111000000
maskExcept_8to6             EQU       %0000000111000000

sizeB_7to6          EQU     %0000000000000000
sizeW_7to6          EQU     %0000000001000000
sizeL_7to6          EQU     %0000000010000000

sizeW_7to0          EQU     %0000000000000000
sizeL_7to0          EQU     %0000000011111111

byteNegative        EQU     $80
wordNegative        EQU     $8000
longNegative        EQU     $80000000

* SOURCE EA MASK
EAmode_data             EQU     %0000000000000000

EAmode_address          EQU     %0000000000001000

EAmode_direct           EQU     %0000000000100000

EAmode_indirect         EQU     %0000000000010000
EAmode_increment        EQU     %0000000000011000
EAmode_decrement        EQU     %0000000000100000
EAmode_displacement     EQU     %0000000000101000   * not implemented yet
EAmode_disp_index       EQU     %0000000000110000   * not implemented yet
EAmode_register         EQU     %0000000000111000


EAmode_absolute_word    EQU     %0000000000111000
EAmode_absolute_long    EQU     %0000000000111001
EAmode_immediate        EQU     %0000000000111100

* DESTINATION EA MASK

S_EAmode_address          EQU     %0000000001000000

S_EAmode_direct           EQU     %0000000100000000

S_EAmode_indirect         EQU     %0000000010000000
S_EAmode_increment        EQU     %0000000011000000
S_EAmode_decrement        EQU     %0000000100000000
S_EAmode_absolute_word  EQU     %0000000111000000
S_EAmode_absolute_long  EQU     %0000001111000000
S_EAmode_immediate      EQU     %0000100111000000

EAmode_pc               EQU     %0000000000000010   * not implemented yet
EAmode_pc_index         EQU     %0000000000000011   * not implemented yet


NOP             EQU     $4E71
RTS             EQU     $4E75
JSR             EQU     %0100111010000000
ASR_MEMORY      EQU     %1110000011000000
ASL_MEMORY      EQU     %1110000111000000
LSR_MEMORY      EQU     %1110001011000000
LSL_MEMORY      EQU     %1110001111000000
ROR_MEMORY      EQU     %1110011011000000
ROL_MEMORY      EQU     %1110011111000000

ASR_REGISTER    EQU     %1110000000000000
ASL_REGISTER    EQU     %1110000100000000
LSR_REGISTER    EQU     %1110000000001000
LSL_REGISTER    EQU     %1110000100001000
ROR_REGISTER    EQU     %1110000000011000
ROL_REGISTER    EQU     %1110000100011000

BCLR_REGISTER   EQU     %0000000110000000
BCLR_IMMEDIATE  EQU     %0000100010000000
MULS            EQU     %1100000111000000
DIVS            EQU     %1000000111000000
LEA             EQU     %0100000111000000

NEG             EQU     %0100010000000000
ORI             EQU     %0000000000000000   * Immediate Data follow
CMPI            EQU     %0000110000000000   * Immediate Data follow
BRA             EQU     %0110000000000000   * CHECK
BCS             EQU     %0110010100000000   * CHECK
BGE             EQU     %0110110000000000   * CHECK
BLT             EQU     %0110110100000000   * CHECK
BVC             EQU     %0110100000000000   * CHECK

MOVE_B          EQU     %0001000000000000   
MOVE_W          EQU     %0011000000000000
MOVE_L          EQU     %0010000000000000

CMP             EQU     %1011000000000000   *CMP


PRINT_DATA      DC.B    '  DATA', 0
PRINT_NOP       DC.B    '  NOP', 0
PRINT_RTS       DC.B    '  RTS', 0
PRINT_JSR       DC.B    '  JSR', 0
PRINT_ASR       DC.B    '  ASR', 0
PRINT_ASL       DC.B    '  ASL', 0
PRINT_LSR       DC.B    '  LSR', 0
PRINT_LSL       DC.B    '  LSL', 0
PRINT_ROR       DC.B    '  ROR', 0
PRINT_ROL       DC.B    '  ROL', 0
PRINT_NEG       DC.B    '  NEG', 0
PRINT_ORI       DC.B    '  ORI', 0
PRINT_CMP       DC.B    '  CMP', 0          *NOT FINISHED
PRINT_CMPI      DC.B    '  CMPI', 0
PRINT_BRA       DC.B    '  BRA', 0
PRINT_BCS       DC.B    '  BCS', 0
PRINT_BGE       DC.B    '  BGE', 0
PRINT_BLT       DC.B    '  BLT', 0
PRINT_BVC       DC.B    '  BVC', 0

PRINT_BCLR      DC.B    '  BCLR', 0
PRINT_MULS      DC.B    '  MULS', 0
PRINT_DIVS      DC.B    '  DIVS', 0
PRINT_LEA       DC.B    '  LEA', 0

*OPCODE BELOW NOT FINISHED
PRINT_MOVE      DC.B    '  MOVE', 0     
PRINT_MOVEA     DC.B    '  MOVEA', 0
PRINT_MOVEM     DC.B    '  MOVEM', 0
PRINT_ADD       DC.B    '  ADD', 0
PRINT_ADDA      DC.B    '  ADDA', 0
PRINT_SUB       DC.B    '  SUB', 0
PRINT_SUBQ      DC.B    '  SUBQ', 0

lines           DS.B 1
halt       DS.B 1
EnterMSG        DC.B 'Hit enter to display'
EB        DC.B EB-EnterMSG

SIZE_DEFAULT    DC.B    '     ', 0
PRINT_B         DC.B    '.B   ', 0
PRINT_W         DC.B    '.W   ', 0
PRINT_L         DC.B    '.L   ', 0
PRINT_COMMA     DC.B    ', ', 0
NEWLINE         DC.B    CR, LF, 0

    END    START        ; last line of source




<<<<<<< HEAD



=======
>>>>>>> 26e7e9946b3c006a98c1d7b945ae3814fa894f0f







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
