# CSS 422 Final project: Disassembler
By Martin Huang, Tien Huynh and Jeremy Luxon

## Program Description: 
 This program is written in motorola 68k assembly language on PC using easy68k. 
 The purpose of this program is to disassemble the data stored in the memory location and finally revert it into 
 human-readable operation code and effective access mode.
 
## Specifications: 

  The program runs in the following order:
  * The program prints out a Welcoming page at the begining.
  * The program askS users to input start address and end address. The start address is no less than $1000 and the end address is no greatere than $FFFFFF
  * The program then reads the address and opcodes. It displays the opcode if it can, otherwaise it will display "DATA"
  * the program ends when the starting address reach the ending address.
  
## Supported OP codes:
TABLE | FOR | OPCODE | CODE
------ | --- | ------------- | -------------
DATA  | NOP | RTS | JSR
ASR | ASL  | LSR | LSL |
ROR |  ROL | NEG  | ORI
CMPI | BRA | BCS | BGE 
BLT  | BVC | 


Register Use:
  
  
Current Subroutines:
  

  
  
