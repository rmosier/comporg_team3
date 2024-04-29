
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
    SUB sp, sp, #8
    STR lr, [sp, #0]
    STR r4, [sp, #4]

    # save original input
    MOV r4, r0

    # finds modulus
    BL __aeabi_uidiv
    MUL r2, r0, r1
    SUB r0, r4, r2

    # pop stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    ADD sp, sp, #8
    MOV pc, lr
# END modulus


#Purpose: find gcd between two numbers 
#Inputs: r0 - number 1 (a), r1 - number 2 (b)
#Output: r0 - gcd of input
.text
gcd:
    # push stack
    SUB sp, sp, #12
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]

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
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    ADD sp, sp, #12
    MOV pc, lr
# END gcd

#Purpose: find a*b mod c 
#Inputs: r0 - number 1 (a), r1 - number 2 (b), r2 - number 3 (c)
#Output: r0 - a*b mod c
.text
powmult:
    # push stack
    SUB sp, sp, #20
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]


    MOV r4, r0 // Current a
    MOV r5, r1 // Current b
    MOV r6, r2 // save c

    MOV r7, #0 // current product in r7

    StartLoopMult:
        # Use and to check if first bit is set in b
        AND r1, r5, #1
        CMP r1, #0
        BEQ NotInProduct
            # Add current a to product
            ADD r7, r7, r4

            # Reduce product using mod c
            MOV r0, r7
            MOV r1, r6
            BL modulus

            MOV r7, r0 // Update product value in r7
        NotInProduct:

        # Shift b to the right to check next bit
        LSR r5, #1
        CMP r5, #0
        BEQ EndLoopMult // No more bits in B; Break out of multloop

        # Mult a by 2 and reduce using mod c
        MOV r0, r4, LSL #1
        MOV r1, r6
        BL modulus

        MOV r4, r0 // Update value of a in r4

        B StartLoopMult
    EndLoopMult:

    MOV r0, r7 // Move return value

    # pop stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    ADD sp, sp, #20
    MOV pc, lr
# END powmult


#Purpose: find a^b mod c 
#Inputs: r0 - number 1 (a), r1 - number 2 (b), r2 - number 3 (c)
#Output: r0 - a^b mod c
.text
powmod:
    # push stack
    SUB sp, sp, #32
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]
    STR r8, [sp, #20]
    STR r9, [sp, #24]
    STR r10, [sp, #28]

    MOV r4, r0 // Current power of a
    MOV r5, #1 // Current mask

    MOV r6, r2 // save copy of c
    MOV r7, r0 // save a

    MOV r8, r1 // save b

    MOV r9, #1 // current output in r9

    StartLoop:
        # Check if b has bit matching current power of 2 set
        AND r1, r8, r5
        CMP r1, #0
        BEQ NotInPower
            # Multiply running product
            MOV r0, r9
            MOV r1, r4
            MOV r2, r6
            BL powmult

            MOV r9, r0 // Update output in r9

        NotInPower:

        MOV r3, #0 // logical value in r3
        # Check if mask is the 31st bit
        MOV r1, #1
        AND r2, r5, r1, LSL #31 
        CMP r2, #0
        ORRNE r3, #1
        # Check if mask is greater than b
        CMP r5, r8
        ORRGT r3, #1
        CMP r3, #1
        BEQ EndLoop // Break out of loop

        # Double current power of a
        MOV r0, r4
        MOV r1, r4
        MOV r2, r6
        BL powmult

        MOV r4, r0 // Store in r4

        LSL r5, #1 // Move mask to next bit

        B StartLoop
    EndLoop:

    MOV r0, r9 // Move return value

    # pop stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    LDR r8, [sp, #20]
    LDR r9, [sp, #24]
    LDR r10, [sp, #28]
    ADD sp, sp, #32
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

    MOV r7, #1 // Return value in r7. Initialize as true

    # Check if input is <= 3
    CMP r0, #3
    BHI ElseTestReq
        B EndTestReqIf // Return true

    ElseTestReq:
        MOV r4, r0 // value to check in r4
        MOV r5, #0 // TestRepeatLoop counter in r5

        # Set random seed
        MOV r0, #0
        BL time
        BL srand

        TestRepeatLoopStart:
            # End loop if count is reached
            CMP r5, #10
            BGE TestRepeatLoopEnd @ Break out of TestRepeatLoop

            BL rand // random value for a in r0
            # Adjust value so (1 < a < min(input, 2^31 - 1))
            MOV r2, #1
            LSL r2, #31
            SUB r2, r2, #1
            CMP r4, r2
            MOVLE r1, r4
            MOVGT r1, r2
            SUB r1, #3 // Reduce mod range by three. - for removing 1; -1 for removing input; -1 for mod being zero indexed
            BL modulus
            # Store value of a in r6
            ADD r6, r0, #2 // Start mod range at 2

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

            FermatFailedElse: // Fermat test passed
                # Find largest power of 2 that divides (input - 1)
                MOV r8, #2 //last valid power in r8. Initialize to 2
                MOV r9, #0 // Logical variable for breaking loop in r9
                StartPowerLoop:
                    MOV r1, r8, LSL #1 // next power of 2 in r1
                    SUB r0, r4, #1 // input - 1 in r0
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
                    # Break loop if r9 is not 0
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
                        LSR r8, #1 // divide current power by 2
                        # Check that power of two is not 0
                        CMP r8, #0
                        BEQ EndFalseRootLoop @ Break out of FalseRootLoop

                    B StartFalseRootLoop @ Continue FalseRootLoop
                EndFalseRootLoop:

                # Check if input is known to be composite
                CMP r7, #0
                BEQ TestRepeatLoopEnd @ Break out of TestRepeatLoop

                ADD r5, #1 // increment loop counter
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
# Output: r0 - private key exponent (integer)
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
            BL __aeabi_uidiv

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

    MOV r0, r2

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
        LDR r0, =formatStrTwoInts
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
            BNE ModulusOverflowCheck

            # p == q code block
            LDR r0, =notDistinctMessage
            BL printf
            B EndValidityChecks
        ModulusOverflowCheck:
           # Use 64 bit mult to check for overflow
           MOV r3, #0
           UMULL r4, r5, r1, r2
           CMP r5, #0
           ORRNE r3, #1
           # Check that product of input numbers is >127
           CMP r4, #127
           ORRLE r3, #1
           CMP r3, #0
           BEQ RangeCheckP

           # overflowed code block
           LDR r0, =modulusOverflowMessage
           BL printf
           B EndValidityChecks
        RangeCheckP:
            LDR r0, =pqUpperLimit
            LDR r0, [r0, #0]
            CMP r1, r0
            BLE RangeCheckQ

            # p outside of range code block
            LDR r0, =notInRangeMessage
            BL printf
            B EndValidityChecks
        RangeCheckQ:
            LDR r0, =pqUpperLimit
            LDR r0, [r0, #0]
            CMP r1, r0
            BLE CompCheckP

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

    MOV r5, r0

    # Move return values to correct registers
    MOV r0, r4 // modulus
    MOV r1, r6 // public key
    MOV r2, r5 // private key

    # Return from stack
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    ADD sp, #16
    MOV pc, lr

.data
    pqUpperLimit: .word 2147483647
    # Input values
    inputP: .word 0
    inputQ: .word 0
    # Format string for two integers separated by a space
    formatStrTwoInts: .asciz "%d %d"
    # Prompt for input
    inputPQPrompt: .asciz "Enter two distinct prime numbers <= 2,147,483,647. The product must be less than 2^32 and greater than 127\n"
    # Output messages
    modulusOverflowMessage: .asciz "The product of %d and %d is not in the specified range\n\n"
    notInRangeMessage: .asciz "%d is not in the specified range\n\n"
    notPrimeMessage: .asciz "%d is not prime\n\n"
    notDistinctMessage: .asciz "%d is equal to %d\n\n"
# end genKeys


#Purpose: encrypt
#Input: r0 Modulus (integer)
#       r1 Public key (integer)
#
#Output:encrypt.txt

.global encrypt

.text

encrypt:
    # Push initial registers and link register onto stack
    SUB sp, sp, #32     @ Reserve stack space for 8 registers
    STR lr, [sp, #28]   @ Save link register
    STR r4, [sp, #24]   @ Save r4
    STR r5, [sp, #20]   @ Save r5
    STR r6, [sp, #16]   @ Save r6
    STR r7, [sp, #12]   @ Save r7
    STR r8, [sp, #8]    @ Save r8
    STR r9, [sp, #4]    @ Save r9
    STR r10, [sp]       @ Save r10

    MOV r4, r0
    MOV r5, r1

    # Prompt for message
    LDR r0, =msgPrompt
    BL printf

    # Read input message using read system call
    MOV r0, #0          @ File descriptor (0 = standard input)
    LDR r1, =buffer     @ Buffer to store input message
    MOV r2, #256        @ Maximum number of characters to read
    MOV r7, #3          @ System call number for read
    SVC 0               @ Invoke the system call

    # Remove the trailing newline character from the input
    LDR r1, =buffer     @ Buffer to store input message
    MOV r2, #0          @ Initialize index counter
RemoveNewline:
    LDRB r3, [r1, r2]   @ Load byte from buffer at index
    CMP r3, #'\n'       @ Compare with newline character
    MOVEQ r3, #0        @ If equal, replace with null terminator
    STRB r3, [r1, r2]   @ Store the modified byte back to buffer
    ADD r2, r2, #1      @ Increment index counter
    CMP r3, #0          @ Check if reached the end of string
    BNE RemoveNewline   @ If not, continue the loop

    # Open the output file for writing
    LDR r0, =outputFile
    LDR r1, =openMode
    BL fopen
    MOV r7, r0          @ Save the file handle

    # Initialize loop counter
    MOV r8, #0          @ Loop counter

    # Calculate the length of the message
    LDR r9, =buffer     @ Reset the buffer pointer to start of message
    MOV r10, #0         @ Initialize message length counter
LengthLoop:
    LDRB r1, [r9], #1   @ Load byte from buffer and increment pointer
    CMP r1, #0          @ Check if the byte is null terminator
    ADDNE r10, r10, #1  @ Increment message length if not null terminator
    BNE LengthLoop      @ Repeat until end of string

    # Allocate stack space for encrypted characters
    MOV r0, r10         @ Move the message length to r0
    LSL r0, r0, #2      @ Multiply by 4 to get the number of bytes needed
    SUB sp, sp, r0      @ Allocate stack space for encrypted characters

    # Encrypt each character
    LDR r9, =buffer     @ Reset the buffer pointer to start of message
    MOV r11, sp         @ Initialize the stack pointer for storing encrypted characters
EncryptLoop:
    LDRB r1, [r9], #1   @ Load byte from buffer and increment pointer
    CMP r1, #0          @ Check if the byte is null terminator
    BEQ WriteLoop       @ Exit loop if end of string

    # Encrypt character using the equation c = m^e mod n
    MOV r0, r1          @ Move the character to r0 (m)
    MOV r1, r5          @ Public key exponent e
    MOV r2, r4          @ Modulus n
    BL powmod           @ Assume powmod adjusts r0 = m^e mod n correctly

    # Store the encrypted character on the stack
    STR r0, [r11], #4   @ Store the encrypted character and increment the stack pointer

    # Increment the loop counter
    ADD r8, r8, #1      @ Increment the loop counter
    B EncryptLoop       @ Repeat for next character

WriteLoop:
    # Write the encrypted characters to the file
    MOV r10, r8         @ Move the loop counter to r10
    MOV r11, sp         @ Reset the stack pointer to the start of encrypted characters
WriteLoop2:
    CMP r10, #0         @ Check if the loop counter is zero
    BEQ CloseFile       @ Exit loop if all characters have been written

    # Load the encrypted character from the stack
    LDR r2, [r11], #4   @ Load the encrypted character and increment the stack pointer

    # Write the encrypted character to the file using fprintf
    MOV r0, r7          @ File handle
    LDR r1, =fprintfFormat  @ Format string for fprintf
    BL fprintf

    # Decrement the loop counter
    SUB r10, r10, #1    @ Decrement the loop counter
    B WriteLoop2        @ Repeat for next character

CloseFile:
    # Close the output file
    MOV r0, r7          @ File handle
    BL fclose

    # Clean up the stack
    MOV r0, r8          @ Move the loop counter to r0
    LSL r0, r0, #2      @ Multiply by 4 to get the number of bytes allocated
    ADD sp, sp, r0      @ Clean up the stack

    # Restore registers from stack
    LDR r10, [sp]       @ Restore r10
    LDR r9, [sp, #4]    @ Restore r9
    LDR r8, [sp, #8]    @ Restore r8
    LDR r7, [sp, #12]   @ Restore r7
    LDR r6, [sp, #16]   @ Restore r6
    LDR r5, [sp, #20]   @ Restore r5
    LDR r4, [sp, #24]   @ Restore r4
    LDR lr, [sp, #28]   @ Restore link register
    ADD sp, sp, #32     @ Clean up the stack

    # Finish the program
    MOV r0, #0          @ Standard return value for success
    MOV pc, lr          @ Return to calling process

.data
msgPrompt: .asciz "Enter a message to encrypt:\n"
outputFile: .asciz "encrypted.txt"
openMode: .asciz "w"
fprintfFormat: .asciz "%d "
buffer: .space 256

#Purpose decrypt
#Input: r0 Modulus (integer)
#       r1 Private key (integer)

.global decrypt

.text

decrypt:
    # Push initial registers and link register onto stack
    SUB sp, sp, #32     @ Reserve stack space for 8 registers
    STR lr, [sp, #28]   @ Save link register
    STR r4, [sp, #24]   @ Save r4
    STR r5, [sp, #20]   @ Save r5
    STR r6, [sp, #16]   @ Save r6
    STR r7, [sp, #12]   @ Save r7
    STR r8, [sp, #8]    @ Save r8
    STR r9, [sp, #4]    @ Save r9
    STR r10, [sp]       @ Save r10

    MOV r4, r0
    MOV r5, r1

    # Open the input file for reading
    LDR r0, =inputFile
    LDR r1, =readMode
    BL fopen
    MOV r7, r0          @ Save the file handle

    # Open the output file for writing
    LDR r0, =outputFiled
    LDR r1, =writeMode
    BL fopen
    MOV r8, r0          @ Save the file handle

    # Initialize loop counter
    MOV r9, #0          @ Loop counter

    # Calculate the number of encrypted characters in the file
    MOV r0, r7          @ File handle
    MOV r1, #0          @ Offset from the beginning of the file
    MOV r2, #2          @ Whence (0 = SEEK_SET, 1 = SEEK_CUR, 2 = SEEK_END)
    BL fseek            @ Move file pointer to the end of the file
    MOV r0, r7          @ File handle
    BL ftell            @ Get the current file position (number of characters)
    MOV r10, r0         @ Save the number of characters

    # Move file pointer back to the beginning of the file
    MOV r0, r7          @ File handle
    MOV r1, #0          @ Offset from the beginning of the file
    MOV r2, #0          @ Whence (0 = SEEK_SET)
    BL fseek

DecryptLoop:
    # Read an encrypted character from the file using fscanf
    MOV r0, r7          @ File handle
    LDR r1, =fscanfFormatd   @ Format string for fscanf
    LDR r2, =encryptedChar  @ Address to store the encrypted character
    BL fscanf

    # Check if fscanf reached the end of file
    CMP r0, #1          @ Compare return value with 1 (successful read)
    BNE CloseFiles      @ Exit loop if end of file or read error

    # Load the encrypted character into r1
    LDR r1, =encryptedChar
    LDR r1, [r1]

    # Decrypt character using the equation m = c^d mod n
    MOV r0, r1          @ Move the encrypted character to r0 (c)
    MOV r1, r5          @ Private key exponent d
    MOV r2, r4          @ Modulus n
    BL powmod           @ Assume powmod adjusts r0 = c^d mod n correctly

    # Write the decrypted character to the output file using fprintf
    MOV r2, r0          @ Decrypted character (m)
    MOV r0, r8          @ File handle
    LDR r1, =fprintfFormatd  @ Format string for fprintf
    BL fprintf

    # Increment the loop counter
    ADD r9, r9, #1      @ Increment the loop counter
    CMP r9, r10         @ Compare loop counter with the number of characters
    BLT DecryptLoop     @ Repeat for next character if loop counter < number of characters

CloseFiles:
    # Close the input file
    MOV r0, r7          @ File handle
    BL fclose

    # Close the output file
    MOV r0, r8          @ File handle
    BL fclose

    # Restore registers from stack
    LDR r10, [sp]       @ Restore r10
    LDR r9, [sp, #4]    @ Restore r9
    LDR r8, [sp, #8]    @ Restore r8
    LDR r7, [sp, #12]   @ Restore r7
    LDR r6, [sp, #16]   @ Restore r6
    LDR r5, [sp, #20]   @ Restore r5
    LDR r4, [sp, #24]   @ Restore r4
    LDR lr, [sp, #28]   @ Restore link register
    ADD sp, sp, #32     @ Clean up the stack

    # Finish the program
    MOV r0, #0          @ Standard return value for success
    MOV pc, lr          @ Return to calling process

.data
inputFile: .asciz "encrypted.txt"
readMode: .asciz "r"
outputFiled: .asciz "plaintext.txt"
writeMode: .asciz "w"
fscanfFormatd: .asciz "%d"
fprintfFormatd: .asciz "%c"
encryptedChar: .word 0
