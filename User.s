# FileName: User.s
# Author: Ting-Wei Wang
# Date: 4/24/24
# Purpose: Userinterface
#
 
.global main
.text
main:

    # Push link register onto stack
    STR lr, [sp, #-4]!

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

    # Compare user choice and branch accordingly
    CMP r4, #'a'
    BEQ GenerateKeys
    CMP r4, #'b'
    BEQ EncryptMessage
    CMP r4, #'c'
    BEQ DecryptMessage

    # Invalid choice, display error message
    LDR r0, =invalidChoice
    BL printf
    B Exit

GenerateKeys:
    # Call genKeys function to generate private and public keys
    BL genKeys
    B Exit

EncryptMessage:
    # Call encrypt function to encrypt a message
    BL encrypt
    B Exit

DecryptMessage:
    # Call decrypt function to decrypt a message
    BL decrypt
    B Exit

Exit:
    # Pop link register from stack and return
    LDR lr, [sp], #4
    MOV pc, lr

.data
prompt: .asciz "Select an action:\na. Generate Private and Public Keys\nb. Encrypt a Message\nc. Decrypt a Message\n"
formatChar: .asciz " %c"
userChoice: .byte 0
invalidChoice: .asciz "Invalid choice. Please try again.\n" 
