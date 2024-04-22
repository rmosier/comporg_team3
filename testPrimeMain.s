# FileName: testPrimeMain.s
# Author: Boleslaw Ruszowski
# Date: 4/15/24
# Purpose: Tests isPrime in RSAlib
#

.global main
.text
main:
    # Push to stack
    SUB sp, #4
    STR lr, [sp, #0]

    # test cpubexp
#    MOV r0, #616
#    BL cpubexp

    # test cprivexp
#    MOV r0, #616
#    MOV r1, #5
#    BL cprivexp

    # print
#    MOV r1, r2
#    LDR r0, =outputStr
#    BL printf

    # loop prime check
    LoopStart:
        # Print prompt
        LDR r0, =inputPrompt
        BL printf

        # Read two integers
        LDR r0, =formatStr
        LDR r1, =inputVal
        BL scanf

        LDR r0, =inputVal
        LDR r0, [r0]
        CMP r0, #-1
        BNE ContLoop
            # Exit condition
            B LoopEnd
        ContLoop:
            BL isPrime

            CMP r1, #1
            BNE CompCase
                LDR r0, =isPrimeStr
                LDR r1, =inputVal
                LDR r1, [r1]
                BL printf
                B EndIf

            CompCase:
                LDR r0, =isCompStr
                LDR r1, =inputVal
                LDR r1, [r1]
                BL printf

            EndIf:

        B LoopStart
    LoopEnd:

    # Pop from stack
    LDR lr, [sp, #0]
    ADD sp, #4
    MOV pc, lr

.data
    # input value
    inputVal: .word 0
    # Prompt for input
    inputPrompt: .asciz "Enter an integer to check or -1 to exit\n"
    # Output string for one int
    outputStr: .asciz "output value %d\n"
    # Format string for one int
    formatStr: .asciz "%d"
    # output messages
    isPrimeStr: .asciz "%d is prime\n\n"
    isCompStr: .asciz "%d is comp\n\n"

