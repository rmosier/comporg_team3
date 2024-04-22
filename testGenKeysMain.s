# FileName: testGenKeysMain.s
# Author: Boleslaw Ruszowski
# Date: 4/19/24
# Purpose: Tests key generation in RSALib
#

.global main
.text
main:
    # Push to stack
    SUB sp, #4
    STR lr, [sp]

    BL genKeys

    MOV r3, r2
    MOV r2, r1
    MOV r1, r0
    LDR r0, =outputStr
    BL printf

    # Return from stack
    LDR lr, [sp]
    ADD sp, #4
    MOV pc, lr

.data
    # Output string
    outputStr: .asciz "N = %d; public = %d; private = %d\n"
