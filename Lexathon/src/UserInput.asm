#  --------------------------------------------------------------------------------
# | FILE: UserInput.asm								  |
# | AUTHOR: Julian McNichols							  |
# | DESCRIPTION: The basic shell for the game, provides a user interface for the  |
# |	       		player to interact with. Shows a grid of letters for use  |
# |			by entering number keys on the keypad. 			  |
# |			1) Enter desired grid letter with NumPad		  |
# |			2) Enter zero for an "Enter Command" Currently only resets|
# |										  |
# |			Setup: 	Open Tools<Keyboard and Display MMIO Simulator    |
# |				Click "Connect to MIPS" button			  |
# |				Input numbers into the bottom field		  |
# |				Non-number inputs ignored			  |
#  --------------------------------------------------------------------------------

.data

Hud1:		.byte						 '-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-','-',0
Hud2:		.asciiz						 "#									#"
Hud3:		.asciiz						 "#			 _______ _______ _______			#"
Hud4:		.byte						 '#','	','	','	','|',' ',' ',' ','G',' ',' ',' ','|',' ',' ',' ','H',' ',' ',' ','|',' ',' ',' ','I',' ',' ',' ','|','	','	','	','#',0
Hud5:		.byte						 '#','	','	','	','|',' ',' ',' ','D',' ',' ',' ','|',' ',' ',' ','E',' ',' ',' ','|',' ',' ',' ','F',' ',' ',' ','|','	','	','	','#',0
Hud6:		.byte						 '#','	','	','	','|',' ',' ',' ','A',' ',' ',' ','|',' ',' ',' ','B',' ',' ',' ','|',' ',' ',' ','C',' ',' ',' ','|','	','	','	','#',0
Hud7:		.asciiz						 "#			|_______|_______|_______|			#"
Hud8: 		.asciiz						 "-------------------------------------------------------------------------"

NewLine:		.asciiz		"\n"

Input:			.byte		0:10

Letters:		.byte		'A','B','C','D','E','F','G','H','I'
Words:			.space		1000		#100 10-Word Slots
				

#REGISTER USE:
# $s0 - Timer (in seconds)
# $s1 - Logic Bits (0-8: Input Bits, 9: Timer On, 10: Waiting For Reset, 11-31 UNUSED)
# $s2 - Start Frame (when timer was last checked)

.text
	li $s0,5			#Default Timer Setup


	li $t0,0xffff0000		#Keyboard and Display MMIO Receiver RControl Register
	lw $t1,0($t0)
	ori $t1,$t1,0x00000002		#Check Bit Position 1 (Interrupt-Enable Bit) true
	sw $t1,0($t0)
	
	ori $s1,$s1,0x00000200		#Checks true that the timer is active
	
	#-------------------------------------------------------------------------------------------------------#
	#					Main Program Execution						#				
	#	Setup should be completed before this point. Once the interruptable bit is saved, the		#
	#	program will start executing interrupts.							#				
	#-------------------------------------------------------------------------------------------------------#
	
	
	li $v0, 30			#Fetches system time, miliseconds since Jan 1 1970
	syscall
	add $s2,$zero,$a0		#Move current system time to start time
	
	
	
	Redraw:				#Return here whenever you need to redraw screen
	jal DrawScreen

	MainLoop:			#Standard waiting and time checking while player isn't providing input
	
	
	andi $t0,$s1,0x00000200		#Transfers the timer active bit
	beq $t0,$zero,TimerOff		#Leave the timer alone if the timer is off, do not process time
	jal CheckTime
	
	TimerOff:
	
	#-------------------------------------------------------------------------------------------------------#
	#					Time Wasting Loop						#				#
	#	Wastes a certain number of cycles on addition executions. These are desireable for their	#
	#	consistent execution time.									#
	#-------------------------------------------------------------------------------------------------------#
	
	#NOTE: COULD BE OPTMIZED BY ADJUSTING CYLCE LENGTH TO DESIRED WAIT TIME ON PRESENT SYSTEM
	
	li $t5,450			#This value is ARBITRARY, measures 1 ms on Julian's computer but could be different for others!
	WasteTime:
	addi $t5,$t5,-1
	bne $t5,$zero,WasteTime
	
	j MainLoop

#---------------------------------------------------------------------------------------------------------------#
#	Subroutine: CheckTime											#
#		Use: 		Checks the number of miliseconds that have passed since the program started 	#
#				and generates a trap if the timer has run out.					#
#														#
#		Inputs:		NONE										#
#		Ouptuts: 	NONE										#
#														#
#		Notes: 		Debug this to make sure the user can't prevent check by holding num key, etc.	#
#				Time can be added or taken away by changing max timer in $s0			#
#---------------------------------------------------------------------------------------------------------------#

CheckTime:
	li $v0, 30			#Fetches system time, miliseconds since Jan 1 1970
	syscall
	sub $t0,$a0,$s2
	
	slti $t1,$t0,1000
	bne $t1,$zero,NoFullSecond
	subi $s0,$s0,1
	
	subi $t0,$t0,1000		#Make sure any few miliseconds over a second are retained on point of comparison
	sub $s2,$a0,$t0
	
	addi $sp,$sp,-4			#Draw the appropriate timer
	sw $ra,0($sp)
	jal DrawScreen
	lw $ra,0($sp)
	addi $sp,$sp,4
	
	tlti $s0,1			#Generate a trap if the timer has run out
	
	NoFullSecond:
	
	jr $ra
	
#---------------------------------------------------------------------------------------------------------------#
#	Subroutine: DrawTimer											#
#		Use: 		Draws the appropriate timer in five digits.					#
#														#
#		Inputs:		NONE										#
#		Ouptuts: 	NONE										#
#														#
#---------------------------------------------------------------------------------------------------------------#
		
DrawTimer:
	li $a0,48
	li $v0,11

	slti $t1,$s0,10000
	bne $t1,$zero,NotFiveDigit
	li $v0,1
	move $a0,$s0
	syscall
	j TimerPrintDone
	
	NotFiveDigit:
	syscall
	
	slti $t1,$s0,1000
	bne $t1,$zero,NotFourDigit
	li $v0,1
	move $a0,$s0
	syscall
	j TimerPrintDone
	
	NotFourDigit:
	syscall
	
	slti $t1,$s0,100
	bne $t1,$zero,NotThreeDigit
	li $v0,1
	move $a0,$s0
	syscall
	j TimerPrintDone
	
	NotThreeDigit:
	syscall
	
	slti $t1,$s0,10
	bne $t1,$zero,NotTwoDigit
	li $v0,1
	move $a0,$s0
	syscall
	j TimerPrintDone
	
	NotTwoDigit:
	syscall
	li $v0,1
	move $a0,$s0
	syscall
	j TimerPrintDone
	
	TimerPrintDone:
	
	jr $ra
	

#---------------------------------------------------------------------------------------------------------------#
#	Subroutine: DrawScreen											#
#		Use: 		Redraws screen with stored string values in data section.			#
#														#
#		Inputs:		NONE										#
#		Ouptuts: 	NONE										#
#														#
#---------------------------------------------------------------------------------------------------------------#

DrawScreen:
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud1
	syscall
	
	addi $sp,$sp,-4			#Draw the appropriate timer
	sw $ra,0($sp)
	jal DrawTimer
	lw $ra,0($sp)
	addi $sp,$sp,4
	
	li $v0,4
	la $a0,Hud1
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud2
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud3
	syscall	
			
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud4
	syscall			
					
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud7
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud5
	syscall					
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud7
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud6
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud7
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Hud8
	syscall
	
	li $v0,4
	la $a0,NewLine
	syscall
	
	li $v0,4
	la $a0,Input
	syscall
	
	jr $ra

Exit:


.ktext 0x80000180

	#---------------------------------------#
	#	Keyboard Input Handler		#
	#---------------------------------------#

	mfc0 $k0,$13			#Retrieve Cause
	andi $k0,$k0,0x0000017C		#Transfer 1s on bits 2-6 and 8
	li $k1,0x00000100		#Check for 1 at bit 8 and zeroes in bits 2-6
	bne $k0,$k1,NotKeyboard
	
	li $k1,0xffff0004		#Address of Receiver Data
	lb $a0,0($k1)
	
	
	slti $k0,$a0,58			# Check that input is in range of numbers 0 to 9
	beq $k0,$zero,UnusedKey
	li $k0,47
	slt $k0,$k0,$a0
	beq $k0,$zero,UnusedKey
	
	subi $a0,$a0,49			#Now we have reduced it to iterate across the loaded letters, and we have -1 if the entry was 0
	slt $k1,$a0,$zero
	bne $k1,$zero,EnterEvent
	
	li $k1,1			#Check that the input key is not in use
	sllv $k1,$k1,$a0
	and $k1,$k1,$s1
	
	bne $k1,$zero,LetterInUse
	
	li $k1,1			#Now flag that digit as being in use
	sllv $k1,$k1,$a0
	or $s1,$k1,$s1
	
	la $k0, Letters			#Add the indicated letter to the input string
	add $k0,$k0,$a0
	lb $a0,0($k0)
	
	#NOTE: COULD BE OPTIMIZED IF WE SAVE THE LENGTH OF INPUT
	la $k0,Input			#Finds the end of the string. 
	FindInput:
	lb $k1,0($k0)
	addi $k0,$k0,1
	bne $k1,$zero,FindInput
	sb $zero,0($k0)
	addi $k0,$k0,-1
	
	sb $a0,0($k0)
	
	la $k0,Redraw
	mtc0 $k0,$14
	
	eret
	
	#-----------------------------------------------#
	#	Input Letter Already Being Used		#
	#-----------------------------------------------#
LetterInUse:
	eret
	
	#-------------------------------#
	#	User Hit Enter Key	#
	#-------------------------------#
EnterEvent:
	
	li $s1,0
	
	la $k0,Input
	sb $zero,0($k0)
	
	la $k0,Redraw
	mtc0 $k0,$14

	#-------------------------------#
	#	Non-Implemented Key	#
	#-------------------------------#
UnusedKey:
	eret


NotKeyboard:	#Continue To Other Handlers

	#-------------------------------#
	#	Timer End Detected	#
	#-------------------------------#
	li $k1,0x00000034		#This is the bit pattern for the timer trap
	bne $k0,$k1,NotTimer
	
	li $v0,4
	la $a0,Output1
	syscall
	
	la $a0,NewLine
	syscall
	
	la $a0,Words
	syscall
	
	la $a0,NewLine
	syscall
	
	andi $s1,$s1,0xFFFFFDFF		#Switch timer bit off, stopping the timer
	
	li $t0,0xffff0000		#Keyboard and Display MMIO Receiver RControl Register
	lw $t1,0($t0)
	ori $t1,$t1,0xFFFFFFFD		#Check Bit Position 1 (Interrupt-Enable Bit) FALSE (Disables interrupts)
	sw $t1,0($t0)
	
	la $k0,MainLoop			#Program will not process time or update screen till a new game is started
	mtc0 $k0,$14
	
	eret

		
	
NotTimer:

	la $k0,Exit
	mtc0 $k0,$14

	eret





.kdata

Output1:		.asciiz		"Time Out!"
