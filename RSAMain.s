# FileName: RSAMain.s
# Author: Team3
# Date: 4/24/24
# Purpose: User interface
#

.global main
.text
main:

    # Push link register onto stack
    SUB sp, #20
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]

    # Initialize saved modulus and key values to 0
    MOV r5, #0
    MOV r6, #0
    MOV r7, #0

    InputLoopStart:
        # Display prompt for user actions
        LDR r0, =prompt
        BL printf

        # Read user input
        LDR r0, =formatChar
        LDR r1, =userChoice
        BL scanf

        # Load user choice into r4
        LDR r4, =userChoice
        LDRB r4, [r4]

        # Compare user choice
        CMP r4, #'a'
        BNE EncryptMessage
            # Call genKeys function to generate private and public keys
            BL genKeys

            # Save modulus and keys in r5, r6, and r7
            MOV r5, r0
            MOV r6, r1
            MOV r7, r2

            # Print keys to console
            LDR r0, =keysOutput
            MOV r1, r5
            MOV r2, r6
            MOV r3, r7
            BL printf

            B SwitchEnd
        EncryptMessage:
            CMP r4, #'b'
            BNE DecryptMessage

            CMP r5, #0 // Check if saved modulus and keys exist
            BNE SetModAndPub
                # No keys; prompt user
                LDR r0, =keysPrompt
                BL printf

                # Read input
                LDR r0, =formatStrTwoInt
                LDR r1, =inputMod
                LDR r2, =inputKey
                BL scanf

                # Load input into correct registers for encrypt
                LDR r0, =inputMod
                LDR r0, [r0]
                LDR r1, =inputKey
                LDR r1, [r1]
                B CallEncrypt
            SetModAndPub:
                # Saved keys exist; Load into correct registers
                MOV r0, r5
                MOV r1, r6

            CallEncrypt:
            # Call encrypt function to decrypt a message
            BL encrypt

            # Print message to indicate encryption completed
            LDR r0, =encryptionOutput
            BL printf
            B SwitchEnd
        DecryptMessage:
            CMP r4, #'c'
            BNE ClearKeys

            CMP r5, #0
            BNE LoadModAndPriv
                # No keys; prompt user
                LDR r0, =keysPromptd
                BL printf

                # Read input
                LDR r0, =formatStrTwoInt
                LDR r1, =inputMod
                LDR r2, =inputKey
                BL scanf

                # Load input into correct registers for decrypt
                LDR r0, =inputMod
                LDR r0, [r0]
                LDR r1, =inputKey
                LDR r1, [r1]
                B CallDecrypt
            LoadModAndPriv:
                # Saved keys exist; Load into correct registers
                MOV r0, r5
                MOV r1, r7

            CallDecrypt:
            # Call decrypt function to decrypt a message
            BL decrypt

            # Print message to indicate decryption complete
            LDR r0, =decryptionOutput
            BL printf
            B SwitchEnd
        ClearKeys:
            CMP r4, #'d'
            BNE ExitCheck

            # Clear saved values of modulus, public key, and private key
            MOV r5, #0
            MOV r6, #0
            MOV r7, #0

            # Print message to indicate keys cleared
            LDR r0, =clearOutput
            BL printf
            B SwitchEnd
        ExitCheck:
            CMP r4, #'e'
            BNE SwitchElse

            # Print message to indicate exit
            LDR r0, =exitOutput
            BL printf
            B InputLoopEnd @ Break out of InputLoop
        SwitchElse:
            # Invalid choice, display error message
            LDR r0, =invalidChoice
            BL printf
        SwitchEnd:

        B InputLoopStart
    InputLoopEnd:

    Exit:
    # Pop link register from stack and return
    LDR lr, [sp, #0]
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    ADD sp, #20
    MOV pc, lr

.data
inputMod: .word 0
inputKey: .word 0
prompt: .asciz "Select an action:\na. Generate Private and Public Keys\nb. Encrypt a Message\nc. Decrypt a Message\nd. Clear Saved Keys\ne. Exit\n\n"
formatChar: .asciz " %c"
userChoice: .byte 0
keysOutput: .asciz "The modulus is %d, the public key is %d, and the private key is %d. Values will be saved for encryption and decryption\n\n"
encryptionOutput: .asciz "Encrypted message written to 'encrypted.txt'\n\n"
decryptionOutput: .asciz "Decrypted message written to 'plaintext.txt'\n\n"
clearOutput: .asciz "Saved keys cleared\n\n"
exitOutput: .asciz "Exiting\n"
invalidChoice: .asciz "Invalid choice. Please try again.\n\n"
keysPrompt: .asciz "Enter modulus n and public key exponent e (separated by space):\n"
keysPromptd: .asciz "Enter modulus n and private key exponent d (separated by space):\n"
formatStrTwoInt: .asciz "%d %d"
