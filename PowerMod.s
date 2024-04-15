# Filename: PowerMod.s
# Author: Rebecca Mosier
# Date: 4/14/2024
# Purpose: An assembly program to test powmod function
.text
.global main

main:
# Save return to os on stack
    sub sp, sp, #4
    str lr, [sp, #0]

# Prompt for an input value
    ldr r0, =prompt
    bl printf

# Scanf
    ldr r0, =input
    ldr r1, =val1
    ldr r2, =val2
    ldr r3, =val3
    bl scanf

# Find largest
    ldr r0, =val1
    ldr r0, [r0]
    ldr r1, =val2
    ldr r1, [r1]
    ldr r2, =val3
    ldr r2, [r2]
    bl powmod
    mov r1, r0
 
#print output
    ldr r0, =output
    bl printf

# Return to the OS
    ldr lr, [sp, #0]
    add sp, sp, #4
    mov pc, lr

.data
    prompt: .asciz "Enter three ints: \n"
    input: .asciz "%d %d %d"
    val1: .word 0
    val2: .word 0
    val3: .word 0
    output: .asciz "%d is a^b mod c.\n"
