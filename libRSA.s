
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

    # Return value in r7. Initialize as true
    MOV r7, #1

    # Check if input is <= 3
    CMP r0, #3
    BHI ElseTestReq
        # Return true
        B EndTestReqIf

    ElseTestReq:
        # Put value to check in r4
        MOV r4, r0
        # Put counter for TestRepeatLoop in r5
        MOV r5, #0

        # Set random seed
        MOV r0, #0
        BL time
        BL srand

        TestRepeatLoopStart:
            # End loop if count is reached
            CMP r5, #10
            BGE TestRepeatLoopEnd @ Break out of TestRepeatLoop

            # Get random value for a in r0
            BL rand
            # Adjust value so (1 < a < input)
            SUB r1, r4, #3 @ -2 for excluding 1 and input value, -1 b/c first possible mod value is 0
            BL modulus
            # Store value of a in r6
            ADD r6, r0, #2

            # Fermat test. Checking (a^p) = a mod p
            MOV r0, r6
            MOV r1, r4
            MOV r2, r4
            BL powmod
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
                MOV r8, #2
                # Logical variable for breaking loop in r9
                MOV r9, #0
                StartPowerLoop:
                    # Calculate next power of 2 in r1
                    MOV r1, r8, LSL #1
                    # (input - 1) in r0
                    SUB r0, r4, #1
                    # Check if power is greater than (input - 1)
                    CMP r0, r1
                    ORRLO r9, #1
                    # Check if power overflowed
                    CMP r1, #0
                    ORREQ r9, #1
                    # Check if divisible
                    BL modulus
                    CMP r0, #0
                    ORRNE r9, #1
                    # Break loop if r9 > 0
                    CMP r9, #0
                    BEQ BreakLoopElse
                        # Not divisible by next power or power is equal to (input - 1)
                        B EndPowerLoop @ Break out of PowerLoop

                    BreakLoopElse:
                        # Set power of two to the tested value
                        LSL r8, r8, #1

                    B StartPowerLoop @ Continue PowerLoop
                EndPowerLoop:
                
                # Put q (other factor for largest power of two) in r9
                SUB r0, r4, #1
                MOV r1, r8
                BL __aeabi_uidiv
                MOV r9, r0

                StartFalseRootLoop:
                    # Calculate (a^(currentPower * q)) mod input
                    MOV r0, r6
                    MUL r1, r8, r9
                    MOV r2, r4
                    BL powmod
                    # Check if result is not 1
                    CMP r0, #1
                    BEQ ResultElse
                        # If mod result is positive, must subtract input so it become negative
                        SUBGE r0, r0, r4
                        # Check if mod result is -1
                        CMP r0, #-1
                        MOVNE r7, #0
                        B EndFalseRootLoop @ Break out of FalseRootLoop

                    ResultElse:
                        LSR r8, #1
                        # Check that power of two is not 0
                        CMP r8, #0
                        BEQ EndFalseRootLoop @ Break out of FalseRootLoop

                    B StartFalseRootLoop @ Continue FalseRootLoop
                EndFalseRootLoop:

                # Check if input is known to be composite
                CMP r7, #0
                BEQ TestRepeatLoopEnd @ Break out of TestRepeatLoop

                ADD r5, #1
            B TestRepeatLoopStart @ Continue TestRepeatLoop
        TestRepeatLoopEnd:

    EndTestReqIf:

    # Move return value to r1
    MOV r1, r7

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
        MOV r1, r4
        LDR r0, =inputPrompt
        BL printf

        # Read input
        LDR r0, =formatStringInt
        LDR r1, =inputValue
        BL scanf

        # Find gcd of input and totient
        LDR r0, =inputValue
        LDR r0, [r0, #0]
        MOV r1, r4
        BL gcd

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
    SUB sp, #36
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

    # Initiallize values of x1, x2, y1, y2 in r4-r7
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
        ContinueLoop:
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
            MUL r2, r0, r4
            SUB r4, r1, r2

            # Old y2 in r1. Update value of y2 to y1
            MOV r1, r7
            MOV r7, r6
            # (oldy2 - q * y1) in r6
            MUL r2, r0, r6
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
    ADD sp, #36
    MOV pc, lr

# end cprivexp

# Function: genKeys
# Purpose: Generates n and the public/private keys. Restricts p,q >= 13
# Input:
#
# Output: r0 - n (integer)
#         r1 - public key (integer)
#         r2 - private key (integer)
#
.global genKeys
.text
genKeys:
    # Push to stack
    SUB sp, #16
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]

    GenInputLoopStart:
        # Prompt for input
        LDR r0, =inputPQPrompt
        BL printf

        # Read input
        LDR r0, =formatStrTwoInt
        LDR r1, =inputP
        LDR r2, =inputQ
        BL scanf

        # Check if numbers are valid
        LDR r1, =inputP
        LDR r1, [r1, #0]
        LDR r2, =inputQ
        LDR r2, [r2, #0]
        # Start if block; check if numbers are the same
            CMP r1, r2
            BNE RangeCheckP

            # p == q code block
            LDR r0, =notDistinctMessage
            BL printf
            B EndValidityChecks
        RangeCheckP:
            CMP r1, #13
            BGE RangeCheckQ

            # p outside of range code block
            LDR r0, =notInRangeMessage
            BL printf
            B EndValidityChecks
        RangeCheckQ:
            CMP r2, #13
            BGE CompCheckP

            # q outside of range code block
            LDR r0, =notInRangeMessage
            MOV r1, r2
            BL printf
            B EndValidityChecks
        CompCheckP:
            MOV r0, r1
            BL isPrime
            CMP r1, #1
            BEQ CompCheckQ

            # p is composite code block
            LDR r0, =notPrimeMessage
            LDR r1, =inputP
            LDR r1, [r1, #0]
            BL printf
            B EndValidityChecks
        CompCheckQ:
            LDR r0, =inputQ
            LDR r0, [r0, #0]
            BL isPrime
            CMP r1, #1
            BEQ CompCheckElse

            # q is composite code block
            LDR r0, =notPrimeMessage
            LDR r1, =inputQ
            LDR r1, [r1, #0]
            BL printf
            B EndValidityChecks
        CompCheckElse:
            B GenInputLoopEnd @ Break out of GenInputLoop

        EndValidityChecks:
        B GenInputLoopStart @ Continue GenInputLoop
    GenInputLoopEnd:

    # Modulus in r4
    LDR r0, =inputP
    LDR r0, [r0, #0]
    LDR r1, =inputQ
    LDR r1, [r1, #0]
    MUL r4, r0, r1
    
    # Totient in r5
    SUB r0, #1
    SUB r1, #1
    MUL r5, r0, r1
    
    # Public exp in r6
    MOV r0, r5
    BL cpubexp
    MOV r6, r1

    # Private exp in r2
    MOV r0, r5
    MOV r1, r6
    BL cprivexp

    # Move return values to correct registers
    MOV r0, r4
    MOV r1, r6

    # Return from stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    ADD sp, #16
    MOV pc, lr

.data
    # Input values
    inputP: .word 0
    inputQ: .word 0
    # Format string for two integers separated by a space
    formatStrTwoInt: .asciz "%d %d"
    # Prompt for input
    inputPQPrompt: .asciz "Enter two distinct prime numbers >= 13\n"
    # Error messages
    notInRangeMessage: .asciz "%d is not >= 13\n"
    notPrimeMessage: .asciz "%d is not prime\n"
    notDistinctMessage: .asciz "%d is equal to %d\n"
# end genKeys


