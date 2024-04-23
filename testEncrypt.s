# FileName: testEncrypt.s
# Author: Ting-Wei Wang
# Date: 4/23/24
# Purpose: Tests Encrypt in RSALib
#
 
.global main
.text
main:
    # Push to stack
    SUB sp, #4
    STR lr, [sp]
 
    BL encrypt
 
    # Return from stack
    LDR lr, [sp]
    ADD sp, #4
    MOV pc, lr
 
 
