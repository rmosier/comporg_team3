
# Filename: libRSA.s
# Author: Team3
# Date: 4/14/2024
# Purpose: Functions for RSA Encryption

.global modulus
.global gcd

#Purpose: find modulus of number 
#Inputs: r0 - input number, r1 - divisor
# Output: r0 - modulus of input
.text
modulus:
    # push stack
    SUB sp, sp, #4
    STR lr, [sp, #0]
    
    # save original input
    MOV r4, r0    

    # finds modulus
    BL __aeabi_idiv
    MUL r2, r0, r1
    SUB r0, r4, r2

    # pop stack
    LDR lr, [sp, #0]
    ADD sp, sp, #4
    MOV pc, lr
# END modulus


#iPurpose: find gcd between two numbers 
#Inputs: r0 - number 1 (a), r1 - number 2 (b)
#Output: r0 - gcd of input
.text
gcd:
    # push stack
    SUB sp, sp, #4
    STR lr, [sp, #0]    

    # save copy of r0, r1
    MOV r4, r0
    MOV r5, r1

    # if a mod b is 0, return b
    BL modulus
    CMP r0, #0
    BNE ElseIf
        MOV r0, r5
        B Return
    # if a mod b is 1, return 1
    ElseIf:
        CMP r0, #1
        BNE Else
            MOV r0, #1
            B Return
    # else return gcd(b, r)
    Else: 
        # set r1 to r0
        MOV r1, r0
        # set b to r0
        MOV r0, r5      
        BL gcd
    EndIf:   

    # pop stack
    Return:
    LDR lr, [sp, #0]
    ADD sp, sp, #4
    MOV pc, lr
# END gcd

