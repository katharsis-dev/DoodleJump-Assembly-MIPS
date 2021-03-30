#####################################################################
#
# CSC258H5S Winter 2021 Assembly Programming Project
# University of Toronto Mississauga
#
# Group members:
# - Student 1: Brytton Tsai, 1005727858
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Player names. Allow the player to enter their name using the keyboard, and the name is displayed throughout the game as well as the game-over screen showing the final scores.
# 2. Display the score on screen. The score should be constantly updated as the game progresses. The final score is displayed on the game-over screen.
# 3. Changing difficulty as game progresses: gradually increase the difficulty of the game (e.g., shrinking the platforms) as the game progresses.
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################
# - Constant Register
# - $s0, displayAddress (Address)
# - $s1, checkKey (Address)
# - $s2, levelLength (int)
#
# - Color Codes
# - Sky Blue, ADE2FF
# - Green, 32FF00
# - Pink, FF9AFD
# 
# Current Platform x locations $s6 (stack pointer)
# Current Platform y locations $s7 (stack pointer)
# Player coordinates $t8 = x, $t9 = y

.data
	displayAddress:	.word	0x10008000
	keydisplayAddress: .word 0xffff000c
	checkKey: .word 0xffff0000
	keyStroke: .word 0xffff0004

.globl main

.text
main:
	lw $s0, displayAddress	# Load display address into register $t0
	lw $s1, checkKey # Load checkkey address
	li $s2, 10 # Load current platform length
	
	# Push platform x locations onto stack	
	li $a0, 10
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 10
	jal push_stack
	move $s6, $sp
	# Push platform y locations onto stack
	li $a0, 10
	jal push_stack
	li $a0, 20
	jal push_stack
	li $a0, 31
	jal push_stack
	move $s7, $sp
	
	li $t8, 15 # Load initial player coordinate
	li $t9, 31 # Load initial player coordinate
	jal paint_background # Jump t0 paintBackground function

	# Paint platform 1
	lw $a0, 0($s7) # Y coordinate
	jal push_stack
	lw $a0, 0($s6) # X coorinate
	jal push_stack
	jal paint_platform
	# Paint platform 2
	lw $a0, 4($s7) # Y coordinate
	jal push_stack
	lw $a0, 4($s6) # X coorinate
	jal push_stack
	jal paint_platform
	# Paint platform 3
	lw $a0, 8($s7) # Y coordinate
	jal push_stack
	lw $a0, 8($s6) # X coorinate
	jal push_stack
	jal paint_platform
	
	# Paint character
	li $a0, 31
	jal push_stack
	li $a0, 15
	jal push_stack
	jal paint_character
	
	# Check collision
	li $a0, 31 # Y coordinate
	jal push_stack
	li $a0, 15 # X coordinate
	jal push_stack
	jal check_collision
	# Print 1 if there is collision
	move $a0, $v0
	li $v0, 1 
	syscall
	
	main_loop:
		# Check if player has lost
		jal check_lose
		# Check if key is pressed
		jal get_key_once
		# Check collision
		move $a0, $t9 # Y coordinate
		jal push_stack
		move $a0, $t8 # X coordinate
		jal push_stack
		jal check_collision
		beqz $v0 fall_down

		jump_up:
		# Moves the character up 14 pixels
		li $a0, 14 # How many pixels to jump up by
		jal push_stack
		li $a0, 0
		jal push_stack
			jump_loop:
				
				# Check if key is pressed
				jal get_key_once
				# Load indexes
				lw $t0, 0($sp) # Load index
				lw $t1, 4($sp) # Load final index
				
				# Move platform down
				li $t3, 5
				li $t4, 14
				blt $t0, $t3, no_platform_movement
				bgt $t9, $t4, no_platform_movement
				jal move_platform_down
				j no_player_movement
				no_platform_movement:

				# Paint the current level
				jal paint_current
				# Paint new character position
				addi $t9, $t9, -1
				move $a0, $t9 # Y coordinate
				jal push_stack
				move $a0, $t8 # X coordinate
				jal push_stack
				jal paint_character
				j jump_loop_end
				
				no_player_movement:
					jal paint_current
					move $a0, $t9 # Y coordinate
					jal push_stack
					move $a0, $t8 # X coordinate
					jal push_stack
					jal paint_character
					
				jump_loop_end:
				# Increment index /Load indexes from stack
				lw $t0, 0($sp)
				lw $t1, 4($sp)
				
				beq $t0, $t1 jump_loop_cleanup
				addi $t0, $t0, 1
				sw $t0, 0($sp)
				# Sleep timer
				li $a0, 50
				li $v0, 32
				syscall
				j jump_loop
			jump_loop_cleanup:
				jal pop_stack
				jal pop_stack
		
		fall_down:
		# Move the character down and check for collision
			# Paint the current level
			jal paint_current
			# Paint new character position
			addi $t9, $t9, 1
			move $a0, $t9 # Y coordinate
			jal push_stack
			move $a0, $t8 # X coordinate
			jal push_stack
			jal paint_character
			
			# Sleep timer
			li $a0, 50
			li $v0, 32
			syscall
		j main_loop


move_platform_down:
# Moves all the platforms down to make it seem like character is going up
	# Move return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Division number
	li $t4, 31
	
	# Load y index of platforms
	lw $t1, 0($s7)
	lw $t2, 4($s7)
	lw $t3, 8($s7)
	# Increment platforms
	addi $t1, $t1, 1
	div $t1, $t4
	mfhi $t1
	addi $t2, $t2, 1
	div $t2, $t4
	mfhi $t2
	addi $t3, $t3, 1
	div $t3, $t4
	mfhi $t3
	
	# Save platforms back onto the stack
	sw $t1, 0($s7)
	sw $t2, 4($s7)
	sw $t3, 8($s7)
	# Clean up
	jal pop_stack
	jr $v0



check_lose:
# Checks if the player has lost
	li $t0, 33
	bge $t9, $t0, lost
	j not_lost
	lost:
		li $v0, 10
		syscall
	not_lost:
	jr $ra

paint_current:
# Repaint the current frame but without the character
	# Push return addresss onto the stack
	move $a0, $ra
	jal push_stack
	# Paint background
	jal paint_background
	
	# Paint platform 1
	lw $a0, 0($s7) # Y coordinate
	jal push_stack
	lw $a0, 0($s6) # X coorinate
	jal push_stack
	jal paint_platform
	# Paint platform 2
	lw $a0, 4($s7) # Y coordinate
	jal push_stack
	lw $a0, 4($s6) # X coorinate
	jal push_stack
	jal paint_platform
	# Paint platform 3
	lw $a0, 8($s7) # Y coordinate
	jal push_stack
	lw $a0, 8($s6) # X coorinate
	jal push_stack
	jal paint_platform
	
	# Clean up
	jal pop_stack
	jr $v0
	

check_collision:
# Checks if character is in collision with any platforms
# $t0 = x, $t1 = y
	
	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	# Load arguements onto stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	# Make copy of display address
	move $t5, $s0
	# Coordinate to check
	li $t2, 4
	li $t3, 128
	
	mult $t0, $t2
	mflo $t0 # Store x coord, $t0
	
	mult $t1, $t3
	mflo $t1 # Store y offset, $t1
	
	add $t4, $t0, $t1 # displayAddress offset to check
	add $t5, $t5, $t4 # displayAddress to change
	
	lw $t6, 0($t5)
	li $t7, 0x32FF00
	check_collision_if:
		bne $t6, $t7, check_collision_else
		li $v1, 1
		j check_collision_end
	check_collision_else:
		li $v1, 0
	check_collision_end:
	# Clean up
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	move $ra, $fp
	move $v0, $v1
	jr $ra
		
	


paint_platform:
# Paint a platform given coordinate and length
# $t0 = x, $t1 = y, $t2 = length

	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Load arguements from stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	move $t2, $s2

	li $t4, 0 # Index for Loop
	
	paint_platform_loop:
		beq $t4, $t2 paint_platform_end # Loop end condition
		
		move $a0, $t4 # Push loop index onto stack
		jal push_stack
	
		# Push paint_coord arugements onto stack
		li $a0, 0x32FF00
		jal push_stack
		move $a0, $t1
		jal push_stack
		add $t0, $t0, $t4
		move $a0, $t0
		jal push_stack
		jal paint_coord
		
		jal pop_stack
		move $t4, $v0
		
		lw $t0, 4($sp)
		lw $t1, 8($sp)
		move $t2, $s2
		addi $t4, $t4 1
	
		j paint_platform_loop

	paint_platform_end:
	# Final Clean up
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	move $ra, $fp
	jr $ra
	
paint_coord:
# Paints the specific coordinate with specified color
# $t0 = x, $t1 = y, $t2 = color
	move $a0, $ra # Store return address in stack
	jal push_stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	
	move $t3, $s0 # Make copy of display address, $t3
	li $t4, 4
	li $t5, 128
	
	mult $t0, $t4
	mflo $t6 # Store x offset, $t6
	
	mult $t1, $t5
	mflo $t7 # Store y offset, $t7
	
	add $t6, $t6, $t7
	add $t3, $t3, $t6 # displayAddress to change
	
	sw $t2, 0($t3) # Change color of displayAddress
	
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	jal pop_stack
	move $ra, $fp
	jr $ra
	
get_key_once:
# Returns value of key pressed and 0 if none pressed
	
	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Check is key is pressed
	move $t0, $s1
	lw $t1, 0($t0)
	andi $t1, $t1, 0x1
	beqz $t1, no_key_pressed
	lw $v0, 4($t0) # Load key stroke into $v0
	# Edit value
	li $t0, 106
	li $t1, 107
	beq $v0, $t0, j_key_pressed
	beq $v0, $t1, k_key_pressed
	j no_key_pressed
	j_key_pressed:
		addi $t8, $t8, -1
		j no_key_pressed
	k_key_pressed:
		addi $t8, $t8, 1
		j no_key_pressed
	no_key_pressed:
		jal pop_stack
		jr $v0
	
get_key:
# Returns the value of the key detected in $v0
	move $t0, $s1
	check_key:
		lw $t1, 0($t0) # Load 1 if key is pressed, $t1
		andi $t1, $t1, 0x1 # Mask the result so only keeps last 16 bits
		beqz $t1, check_key # Branch back to check_key if key is not pressed

	lw $a0, 4($t0) # Load key stroke into $v0
	li $v0, 11
	syscall
	move $v0, $a0
	jr $ra # Jump back to origin
		

paint_background:
# Paints the background
	# display address, $s0
	# For Loop to set the backgorund colour
	move $t3, $s0 # Make a copy of the display address, $t3
	li $t7, 0xADE2FF # Load (sky blue), $t7
	li $t1, 0 # Index, $t1
	li $t2, 4096 # End Index, $t2
	FOR:
		beq $t1, $t2, END # End loop condition
		sw $t7, 0($t3) # Save skyblue color into the address
		addi $t1, $t1, 4 # Increase Index
		addi $t3, $t3, 4 # Increase address
		j FOR
	END:
		jr $ra # jump back to origin

push_stack:
# Given a value in $a0 push it on to the stack
	addi $sp, $sp, -4 # Move the stack pointed to make space
	sw $a0, 0($sp)
	jr $ra
	
pop_stack:
# Pops one item of the stack and returns the result in $v0
	lw $v0, 0($sp)
	addi $sp, $sp, 4
	jr $ra


paint_character:
# Paint the character given coordinate
# $t0 = x, $t1 = y

	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	# Load arguments from stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	# Paint left leg
	addi $t0, $t0, -1
	addi $t1, $t1, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint right leg
	addi $t0, $t0, 2
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Middle Right
	addi $t1, $t1, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Middle
	addi $t0, $t0, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Middle left
	addi $t0, $t0, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Top left
	addi $t1, $t1, -1
	li $a0, 0x000000
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Top middle
	addi $t0, $t0, 1
	li $a0 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Top right
	addi $t0, $t0, 1
	li $a0 0x000000
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Cap right
	addi $t1, $t1, -1
	li $a0 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Cap Middle
	addi $t0, $t0, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Paint Cap Left
	addi $t0, $t0, -1
	li $a0, 0xFF9AFD
	jal push_stack
	move $a0, $t1
	jal push_stack
	move $a0, $t0
	jal push_stack
	jal paint_coord
	# Clean up
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	move $ra, $fp
	jr $ra
	

		
	
		
		
		
		
	
	
