#####################################################################
#
# CSC258H5S Winter 2021 Assembly Programming Project
# University of Toronto Mississauga
#
# Group members:
# - Student 1: Brytton Tsai, 1005727858
# - Student 2: Rahim Somjee. 1006239740
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
# - Milestone 5 Reached!
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Display the score on screen. The score should be constantly updated as the game progresses. The final score is displayed on the game-over screen.
# 2. Changing difficulty as game progresses: gradually increase the difficulty of the game (e.g., shrinking the platforms) as the game progresses.
# 3. Background music: add background music to the game.
#
#
# Any additional information that the TA needs to know:
# - Current level is displayed at the bottom left
# - Current score is displayed at the top right (Note first three platforms don't count since its practice)
# - Highest level is 7 :)
# - Enjoy the game with some top quality background music
# - Special sound effects for jumping and game end screen. 
#
#####################################################################
# - Constant Registers
# - $s0, displayAddress (Address)
# - $s1, checkKey (Address)
# - $s2, levelLength (int)
# - $s3, current Level (int), current score (int), level speed (int)
# - $s4, Frames per second
# - $s6,  Current Platform X locations (stack Pointer) 
# - $s7, Current Platform Y locations (stack Pointer)
# - $t7, Player coodinate X
# - $t8 Player coordinate Y
# - Color Codes
# - Sky Blue, ADE2FF
# - Green, 32FF00
# - Pink, FF9AFD
# 
# Current Platform x locations $s6 (stack pointer)
# plat1 = 0($s6), plat2 = 4($s6), plat3 = 8($s6)
#
# Current Platform y locations $s7 (stack pointer)
# plat1 = 0($s7), plat2 = 4($s7), plat3 = 8($s7)
#
# Level / Score / Speed
# level = 0($s3), score = 4($s3), speed = 8($s3)
#
# Player coordinates $t8 = x, $t9 = y
#

.data
	displayAddress:	.word	0x10008000
	keydisplayAddress: .word 0xffff000c
	checkKey: .word 0xffff0000
	n1: .byte 61
	n2: .byte 71
	n3: .byte 66
	inc: .word 0

.globl main

.text
main:
	lw $s0, displayAddress	# Load display address into register $t0
	lw $s1, checkKey # Load checkkey address
	li $s2, 10 # Load current platform length
	li $s4, -1 # Current frames
	
	# Push intial level settings onto the stack
	li $a0, 70
	jal push_stack # Push the current speed onto the stack
	li $a0, 0
	jal push_stack # Push the current score onto the stack
	li $a0, 1
	jal push_stack # Push the current level onto the stack
	move $s3, $sp
	
	# Push platform x locations onto stack	
	li $a0, 20
	jal push_stack
	li $a0, 5
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
		
		
		# add jump sound
	li $v0, 31
	li $a0, 73
	li $a1, 1000
	li $a2, 127
	li $a3, 170
			
	syscall
		
		# Moves the character up 14 pixels
		li $a0, 15 # How many pixels to jump up by
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
				li $t4, 14 # Decides how many times to move platform down when character is above certai y index
				bgt $t9, $t4, no_platform_movement
				jal move_platform_down
				j no_player_movement
				no_platform_movement:	
					# Check if key is pressed
					jal get_key_once
					# Paint the current level
					jal paint_current
					# Paint new character position
					addi $t9, $t9, -1
					move $a0, $t9 # Y coordinate
					jal push_stack
					move $a0, $t8 # X coordinate
					jal push_stack
					jal paint_character
					# Check if key is pressed
					jal get_key_once
					# Jump to end of loop
					j jump_loop_end
				
				no_player_movement:
					# Check if key is pressed
					jal get_key_once
					# Paint current
					jal paint_current
					move $a0, $t9 # Y coordinate
					jal push_stack
					move $a0, $t8 # X coordinate
					jal push_stack
					jal paint_character
					# Check if key is pressed
					jal get_key_once
					
				jump_loop_end:
				# Increment index /Load indexes from stack
				lw $t0, 0($sp)
				lw $t1, 4($sp)
				
				beq $t0, $t1 jump_loop_cleanup
				addi $t0, $t0, 1
				sw $t0, 0($sp)
				# Check if key is pressed
				jal get_key_once
				# Sleep timer
				lw $a0, 8($s3)
				li $v0, 32
				syscall
				j jump_loop
			jump_loop_cleanup:
				jal pop_stack
				jal pop_stack
		
		fall_down:
		# Move the character down and check for collision
			# Check if key is pressed
			jal get_key_once
			# Paint the current level
			jal paint_current
			
			# Paint new character position
			addi $t9, $t9, 1
			move $a0, $t9 # Y coordinate
			jal push_stack
			move $a0, $t8 # X coordinate
			jal push_stack
			jal paint_character
			
			# Check if key is pressed
			jal get_key_once
			
			# Sleep timer
			lw $a0, 8($s3)
			li $v0, 32
			syscall
		j main_loop	
		
display_final_score:
# Paint the final score onto the screen and a message
	
	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Paint the background
	jal paint_background
	
	# Print S
	li $a0, 123
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 4
	jal push_stack
	jal print_number
	# Print C
	li $a0, 103
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 9
	jal push_stack
	jal print_number
	# Print O
	li $a0, 117
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 14
	jal push_stack
	jal print_number
	# Print R
	li $a0, 122
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 19
	jal push_stack
	jal print_number
	# Print E
	li $a0, 105
	jal push_stack
	li $a0, 10
	jal push_stack
	li $a0, 24
	jal push_stack
	jal print_number
	
	# Print sore
	li $a0, 17
	jal push_stack
	li $a0, 11
	jal push_stack
	jal print_score
	
	# add end sound
	li $v0, 31
	li $a0, 73
	li $a1, 1300
	li $a2, 2
	li $a3, 170
	syscall

	li $v0, 31
	li $a0, 72
	syscall
	
	li $v0, 31
	li $a0, 71
	syscall
	
	li $v0, 31
	li $a0, 70
	syscall
	
	li $v0, 31
	li $a0, 69
	syscall
	
	# Clean up
	jal pop_stack
	jr $v0
	
paint_row:
# Paint a platform given coordinate and length
# $t0 = x, $t1 = y, $t2 = length $t3 = colour

	# Push return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Load arguements from stack
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	lw $t3, 16($sp)

	li $t4, 0 # Index for Loop
	
	paint_row_loop:
		beq $t4, $t2 paint_row_end # Loop end condition
		
		move $a0, $t4 # Push loop index onto stack
		jal push_stack
	
		# Push paint_coord arugements onto stack
		move $a0, $t3
		jal push_stack
		move $a0, $t1
		jal push_stack
		add $a0, $t0, $t4
		jal push_stack
		jal paint_coord
		
		jal pop_stack # Pop loop index off the stack
		move $t4, $v0
		
		lw $t0, 4($sp)
		lw $t1, 8($sp)
		lw $t2, 12($sp)
		lw $t3, 16($sp)
		addi $t4, $t4 1
	
		j paint_row_loop

	paint_row_end:
	# Final Clean up
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	jal pop_stack
	jal pop_stack
	move $ra, $fp
	jr $ra

update_score_difficulty:
# Updates the level and difficulty once the score reaches a certian point
# Update level every 10 points gain 1 everytime screen moves up
# level = 0($s3), score = 4($s3), speed = 8($s3)
# $t1 = level, $t2 = score, $t3 = speed
	# Move return address onto stack
	move $a0, $ra
	jal push_stack
	
	# Load registers with values
	lw $t1, 0($s3)
	lw $t2, 4($s3)
	lw $t3, 8($s3)
	
	# Increase score by 1 and save it back into its position
	addi $t2, $t2, 1
	sw $t2, 4($s3)
	
	# Updatae level according to score
	li $t0, 10
	div $t2, $t0
	mflo $t1
	beqz $t1 add_one
	sw $t1, 0($s3)
	j no_add
	add_one:
		addi $t1, $t1, 1
		sw $t1, 0($s3)
	no_add:
	
	# Update platform length according to level
	li $t0, 11
	sub $t0, $t0, $t1
	move $s2, $t0
	
	# Update speed according to level
	li $t0, 10
	beq $t3, $t0 update_end
	li $t0, 8
	sub $t0, $t0, $t1
	li $t5, 10
	mult $t0, $t5
	mflo $t3
	sw $t3, 8($s3)

	update_end:
	# Clean up
	jal pop_stack
	jr $v0

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
	# Check if any platforms need to be randomized
	jal randomize_platform
	# Clean up
	jal pop_stack
	jr $v0

randomize_platform:
# Checks all the platforms if one of them is == 0 then randomize its x value
	# Push return address onto the stack
	move $a0, $ra
	jal push_stack
	
	# Load y index of platforms
	lw $t1, 0($s7)
	lw $t2, 4($s7)
	lw $t3, 8($s7)
	
	# Load random value range
	li $a0, 0
	li $a1, 31
	li $v0, 42
	syscall
	platform1:
		bnez $t1, platform2
		sw $a0, 0($s6)
		jal update_score_difficulty
		j randomize_platform_end
	
	platform2:
		bnez $t2, platform3
		sw $a0, 4($s6)
		jal update_score_difficulty
		j randomize_platform_end
		
	platform3:
		bnez $t3, randomize_platform_end
		sw $a0, 8($s6)
		jal update_score_difficulty
	randomize_platform_end:
	jal pop_stack
	jr $v0

check_lose:
# Checks if the player has lost
	li $t0, 33
	bge $t9, $t0, lost
	j not_lost
	lost:
		jal display_final_score
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
	
	# Paint level number
	lw $a0, 0($s3)
	jal push_stack
	li $a0, 27
	jal push_stack
	li $a0, 0
	jal push_stack
	jal print_number
	
	# Paint score onto the screen
	li $a0, 0
	jal push_stack
	li $a0, 23
	jal push_stack
	jal print_score
	
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
	addi $t5, $t5, -4
	
	lw $t1, 0($t5)
	lw $t2, 4($t5)
	lw $t3, 8($t5)
	li $t4, 0x32FF00
	check_collision_if:
		beq $t1, $t4, check_collision_else
		beq $t2, $t4, check_collision_else
		beq $t3, $t4, check_collision_else
		li $v1, 0
		j check_collision_end
	check_collision_else:
		li $v1, 1
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
	
	# Check if frames is 0
	addi $s4, $s4, 1
	li $t0, 10
	div $s4, $t0
	mfhi $s4
	bnez $s4 no_music
	# add music
	play_music:
	li $v0, 31
	lw $t0, inc
	addi $t1, $zero, 1
	if:
		beq $t0, $zero, first
		beq $t0, $t1, second
		j third
	
	first:
		lbu $a0, n1
		addi $t0, $t0, 1
		sw $t0, inc
		j fourth
	
	second: 
		lbu $a0, n2
		addi $t0, $t0, 1
		sw $t0, inc
		j fourth
	third: 
		lbu $a0, n3
		sw $zero, inc
	fourth:
		li $a1, 1650
		li $a2, 96 # 48
		li $a3, 50
	syscall
	
	no_music:
	
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
	
	
	
print_score:
# Prints the score on the bottom right of the screen
# First coordinate (23, 0), (28, 0)
	# Move return address onto the stack
	move $a0, $ra
	jal push_stack
	
	# Load score into resgister
	lw $t0, 4($s3)
	# Load arguements into register
	lw $t4, 4($sp)
	lw $t5, 8($sp)
	

	li $t1, 10
	div $t0, $t1
	mfhi $t2
	mflo $t0
	div $t0, $t1
	mfhi $t3
	# Print the first number
	move $a0, $t2
	jal push_stack
	#li $a0, 0
	move $a0, $t5
	jal push_stack
	#li $a0, 28
	addi $a0, $t4, 5
	jal push_stack
	# Print second number
	move $a0, $t3
	jal push_stack
	#li $a0, 0
	move $a0, $t5
	jal push_stack
	#li $a0, 23
	move $a0, $t4
	jal push_stack
	
	jal print_number
	jal print_number
	
	# Clean up
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	
	jr $fp
	
	
print_number:
# Prints a number on the screen given coordinate and number
# x = $t1, y = $t2, num = $t3
	# Move reutrn address onto stack
	move $a0, $ra
	jal push_stack
	
	# Load registers with values
	lw $t1, 4($sp)
	lw $t2, 8($sp)
	lw $t3, 12($sp)
	
	# Make copy of display address
	move $t0, $s0
	
	# Load colour to paint
	li $t5, 0xFFFFFF
	
	# Determine which number to draw
	# Check if qual to 0
	li $t4, 0
	beq $t3, $t4 print_0
	# Check if qual to 1
	li $t4, 1
	beq $t3, $t4 print_1
	# Check if qual to 2
	li $t4, 2
	beq $t3, $t4 print_2
	# Check if qual to 3
	li $t4, 3
	beq $t3, $t4 print_3
	# Check if qual to 4
	li $t4, 4
	beq $t3, $t4 print_4
	# Check if qual to 5
	li $t4, 5
	beq $t3, $t4 print_5
	# Check if qual to 6
	li $t4, 6
	beq $t3, $t4 print_6
	# Check if qual to 7
	li $t4, 7
	beq $t3, $t4 print_7
	# Check if qual to 8
	li $t4, 8
	beq $t3, $t4 print_8
	# Check if qual to 9
	li $t4, 9
	beq $t3, $t4 print_9
	# Check if qual to S
	li $t4, 123
	beq $t3, $t4 print_S
	# Check if qual to C
	li $t4, 103
	beq $t3, $t4 print_C
	# Check if qual to O
	li $t4, 117
	beq $t3, $t4 print_0
	# Check if qual to R
	li $t4, 122
	beq $t3, $t4 print_R
	# Check if qual to E
	li $t4, 105
	beq $t3, $t4 print_E
	
	print_0:
		# Paint top 1
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		move $a0, $t2 # Load Y coordinate
		jal push_stack
		move $a0, $t1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint top 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint top 3
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint top 4
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 1 1
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 1 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 2 1
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 2 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 3 1
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint middle 3 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint bottom 1
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint bottom 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint bottom 2
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint bottom 3
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# End
		j print_end
	
	print_1:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	print_2:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	
	print_3:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	
	print_4:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	print_5:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	print_6:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	
	print_7:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	
	print_8:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	print_9:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	print_S:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		
		j print_end
		
	print_C:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		
		j print_end
	print_R:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		
		j print_end
		
	print_E:
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 0 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 1 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 2 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 3 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 0 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 1 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 2 # Load X coordinate
		jal push_stack
		jal paint_coord
		# Paint Top 
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		li $t5, 0xFFFFFF
		move $a0, $t5 # Load colour
		jal push_stack
		addi $a0, $t2, 4 # Load Y coordinate
		jal push_stack
		addi $a0, $t1, 3 # Load X coordinate
		jal push_stack
		jal paint_coord
		j print_end
	
	print_end:
	

				
	jal pop_stack
	move $fp, $v0
	jal pop_stack
	jal pop_stack
	jal pop_stack
	
	
	
	jr $fp
