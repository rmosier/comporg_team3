
# Filename: libRSA.s
# Author: Team3
# Date: 4/14/2024
# Purpose: Functions for RSA Encryption

.global modulus
.global gcd
.global powmod

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


#Purpose: find gcd between two numbers 
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


#Purpose: find a^b mod c 
#Inputs: r0 - number 1 (a), r1 - number 2 (b), r2 - number 3 (c)
#Output: r0 - a^b mod c
.text
powmod:
    # push stack
    SUB sp, sp, #12
    STR lr, [sp, #0]
    STR r4, [sp, #4] 
    STR r5, [sp, #8]   

    MOV r4, #1 // loop counter
    MOV r5, r1 // loop limit

    MOV r1, r0 // set r1 to a
    MOV r6, r2 // save copy of c    

    StartLoop:
        # check limit
        CMP r4, r5
        BGE EndLoop

        MUL r1, r0, r1 // multiply a*a
        
        # get next value
        ADD r4, r4, #1
        B StartLoop
    EndLoop:

    # compute modulus
    MOV r0, r1
    MOV r1, r6
    BL modulus
    
    # pop stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    ADD sp, sp, #12
    MOV pc, lr
# END powmod


# Function: isPrime
# Purpose: Checks if the input number is prime using the Rabin-Miller test. Repeats 10 times
# Input: r0 - value to check (unsigned integer)
#
# Output: r1 - 1 if test passed, else 0
#
.global isPrime
.text
isPrime:
    # Push to stack
    SUB sp, #28
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]
    STR r8, [sp, #20]
    STR r9, [sp, #24]

    # Check if input is <= 2
    CMP r0, #2
    BHI ElseTestReq
        # Return true
        MOV r1, #1
        B EndTestReqIf

    ElseTestReq:
        # Put value to check in r4
        MOV r4, r0
        # Put counter for TestRepeatLoop in r5
        MOV r5, #0
        # Test results in r7. Initialize to true
        MOV r7, #1

        TestRepeatLoopStart:
            # End loop if count is reached
            CMP r5, #10
            BGE TestRepeatEnd @ Break out of TestRepeatLoop

            # Set random seed
            MOV r0, #0
            BL time
            BL srand
            # Get random value for a in r0
            BL rand
            # Adjust value so (1 < a < input)
#TODO update mod function registers. Assumed to be r0 and r1
            SUB r1, r4, #1
            BL mod
#TODO update return register. Assumed to be r0
            # Store value of a in r6
            ADD r6, r0, #1

            # Fermat test. Checking (a^p) = a mod p
#TODO update pow function registers. Assumed to be r0, r1, and r2
            MOV r0, r6
            MOV r1, r4
            MOV r2, r4
            BL pow
#TODO update return register. Assumed to be r0. Update mod registers
            MOV r1, r4
            BL mod
#TODO update return register for mod
            # Check if Fermat test failed
            CMP r0, r6
            BEQ FermatFailedElse
                # Input is composite
                MOV r7, #0
                B TestRepeatLoopEnd @ Break out of TestRepeatLoop

            FermatFailedElse:
                # Fermat test passed. Do second part
                # Find largest power of 2 that divides (input - 1)
                # Keep last valid power in r8. Initialize to 2
#TODO update power checks if potentially larger than int max
                MOV r8, #2
                # Logical variable for breaking loop in r9
                MOV r9, #0
                StartPowerLoop:
                    # Calculate next power of 2
                    MOV r0, r8, LSL #1
                    # (input - 1) in r0
                    SUB r0, r4, #1
                    # Check if power is greater than (input - 1)
                    CMP r0, r1
                    ADDLO r9, #1
                    # Check if power overflowed
                    CMP r0, #0
                    ADDEQ r9, #1
                    # Check if divisible
                    MOV r1, r0
                    BL mod
#TODO update mod return
                    # Check if divided evenly
                    CMP r0, #0
                    ADDNE r9, #1
                    # Check loop if r9 > 0
                    CMP r9, #0
                    BNE BreakLoopElse
                        # Not divisible by next power or power is equal to (input - 1)
                        B EndPowerLoop @ Break out of PowerLoop

                    BreakLoopElse:
                        LSL r8, r8, #1

                    B StartPowerLoop @ Continue PowerLoop
                EndPowerLoop:
                
                # Put q (other factor for largest power of two) in r9
                SUB r0, r4, #1
                MOV r1, r8
                BL __aeabi_uidiv
                MOV r9, r0

                StartFalseRootLoop:
                    # Calculate (a^currentPower * q) mod input
#TODO update pow registers
                    MOV r0, r5
                    MUL r1, r8, r9
                    MOV r2, r4
                    # Check if result is not 1
                    CMP r0, #1
                    BEQ ResultElse
                        CMP r0, #-1
                        MOVNE r7, #0
                        B EndFalseRootLoop @ Break out of FalseRootLoop

                    ResultElse:
                        LSR r8, #1
                        # Check if power of two is now 0
                        CMP r8, #0
                        BEQ EndFalseRootLoop # Break out of FalseRootLoop

                    B StartFalseRootLoop @ Continue FalseRootLoop
                EndFalseRootLoop:

                # Check if input is known to be composite
                CMP r7, #0
                BEQ TestRepeatLoopEnd @ Break out of TestRepeatLoop
            B TestRepeatLoopStart @ Continue TestRepeatLoop
        TestRepeatLoopEnd:

    EndTestReqIf:

    # Return from stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    LDR r8, [sp, #20]
    LDR r9, [sp, #24]
    ADD sp, #28
    MOV pc, lr

# end isPrime


# Function: cpubexp
# Purpose: Prompts for and validates value for public key exponent
# Input: r0 - totient value (integer)
#
# Output: r1 - public key exponent (integer)
#
.global cpubexp
.text
cpubexp:
    # Push to stack
    SUB sp, #8
    STR lr, [sp, #0]
    STR r4, [sp, #4]

    # Store totient value in r4
    MOV r4, r0

    # Begin input checking loop
    InputLoopStart:
        # Print prompt
        LDR r0, =inputPrompt
        BL printf

        # Read input
        LDR r0, =formatStringInt
        LDR r1, =inputValue
        BL scanf

        # Find gcd of input and totient
#TODO Change registers based on function. Assumed to be r0 and r1
        LDR r0, =inputValue
        LDR r0, [r0, #0]
        MOV r1, r4
        BL gcd

#TODO Change return register. Assumed to be r0
        # Check if coprime (gcd is 1)
        CMP r0, #1
        BNE InvalidInput
            LDR r1, =inputValue
            LDR r1, [r1, #0]

            B InputLoopEnd @ Break out of InputLoop

        InvalidInput:
            # Print error message
            LDR r0, =invalidInputMessage
            LDR r1, =inputValue
            LDR r1, [r1, #0]
            MOV r2, r4
            BL printf

        B InputLoopStart @ Continue InputLoop
    InputLoopEnd:

    # Return from stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    ADD sp, #8
    MOV pc, lr

.data
    # Value of input
    inputValue: .word 0
    # Format string for an integer
    formatStringInt: .asciz "%d"
    # Prompt string for input
    inputPrompt: .asciz "Enter a value coprime to %d for the public key exponent\n"
    # Invalid input message that echoes input and totient
    invalidInputMessage: .asciz "%d is not coprime with %d\n"
# end cpubexp


# Function: cprivexp
# Purpose: Calculates the value for the private key exponent
# Input: r0 - totient value (integer)
#        r1 - public key exponent (integer)
#
# Output: r2 - private key exponent (integer)
#
.global cprivexp
.text
cprivexp:
    # Push to stack
    SUB sp, #32
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]
    STR r8, [sp, #20]
    STR r9, [sp, #24]
    STR r10, [sp, #28]
    STR r11, [sp, #32]

    # Store initial value of a in r11, working value of a in r9 and working value of b in r10
    MOV r11, r0
    MOV r9, r0
    MOV r10, r1

    # Initiallize values of x1, x2, y1, y2 in r4-r8
    MOV r4, #0
    MOV r5, #1
    MOV r6, #1
    MOV r7, #0

    NonzeroBLoopStart:
        CMP r10, #0
        BGT ContinueLoop
            # Adjust r7 (y2) if negative by adding totient and move to output register
            CMP r7, #0
            ADDLT r7, r11
            MOV r2, r7

            B NonzeroBLoopEnd @ Break out of NonzeroBLoop
        ContinueLoop
            # Calculate q or (a/b) in r0
            MOV r0, r9
            MOV r1, r10
            BL __aeabi_idiv

            # Old value of a in r1. Update value of a to b
            MOV r1, r9
            MOV r9, r10
            # (olda - q * b) in r10
            MUL r2, r0, r10
            SUB r10, r1, r2

            # Old x2 in r1. Update value of x2 to x1
            MOV r1, r5
            MOV r5, r4
            # (oldx2 - q * x1) in r4
            MUL r2, r0, r2
            SUB r4, r1, r2

            # Old y2 in r1. Update value of y2 to y1
            MOV r1, r7
            MOV r7, r6
            # (oldy2 - q * y1) in r6
            MUL r2, r0, r2
            SUB r6, r1, r2

        B NonzeroBLoopStart @ Continue NonzeroBLoop
    NonzeroBLoopEnd:

    # Return from stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    LDR r8, [sp, #20]
    LDR r9, [sp, #24]
    LDR r10, [sp, #28]
    LDR r11, [sp, #32]
    ADD sp, #32
    MOV pc, lr

# end cprivexp

