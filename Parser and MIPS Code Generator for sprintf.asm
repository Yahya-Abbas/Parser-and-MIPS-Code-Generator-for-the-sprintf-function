.data
outputlength:	.asciiz "\nNumber of characters in the output string of sprintf is : "
str:	.asciiz "Good morning."
user_input: .space 10000
outbuf: .space 100000
format: .asciiz ""
.text
.globl main
main:
		li	$t5, -50735
		li	$t6, 3435
		li	$t7, -400721
		li	$t8, 0xccccc
		li	$t9, 0xFFFFFE9D
		la	$a0, user_input		
		li	$a1, 10000
		li	$v0, 8
		syscall
		jal	Parser			#Go to parser and store the address of the next instruction in $ra
		la	$v0, outbuf		#link outbuf string to register $v0 to store the result, remember format address is in $s1
		jal	sprintf			#Call sprintf function and store the address of the next instruction in $ra (arguments are stored in $a0-$a3 and any more argument are stored in the stack	
		la	$a0, outbuf
		li	$a1, 10000
		li	$v0, 4
		syscall
		la	$a0, outputlength
		li	$v0, 4
		syscall
		move	$a0, $t3
		li	$v0, 1
		syscall
		li	$v0, 10
		syscall
			
	Parser:
			la	$s0, user_input		#link user input string to register $s0
			li	$t0, -1			#initialize a counter = 0 in $t0 to traverse the user input
			la	$s1, format		#link format string address to register $s1
			li	$t2, 0			#initialize a counter=0 in $t2 to move in format string
	traverse:	
			addi 	$t0, $t0, 1
			add	$t1, $t0, $s0		#get the address of the next character in the user string
			lbu	$t1, 0($t1)		#load the ith char from user string
			beq	$t1, ')', ParsFinish	#if you finished parsing the user string go to the function sprintf()
			beq	$t1, '"', getformat	#get the format string between the quotation marks
			beq	$t1, ',', traverse	#if the current char is ',' get the next char
			beq	$t1, ' ', traverse	#if the current char is a space get the next char
			beq	$t1, 'a', arguments	#if the current char is one of our variable we go to arguments to store it
			beq	$t1, 'b', arguments	#if the current char is one of our variable we go to arguments to store it
			beq	$t1, 'c', arguments	#if the current char is one of our variable we go to arguments to store it
			beq	$t1, 'd', arguments	#if the current char is one of our variable we go to arguments to store it
			beq	$t1, 'e', arguments	#if the current char is one of our variable we go to arguments to store it
			j	traverse
		getformat:	
				addi	$t0, $t0, 1		#increment user string counter by 1
				add	$t1, $t0, $s0		#get address of the first char after " sign in the user string
				lbu	$t1, 0($t1)		#get the first char after " sign in the user string
				beq	$t1, '"', $t2Counter	#if we reached another " that means the format string is finished. we need to traverse the rest of the user string to get the arguments
				add	$t3, $t2, $s1		#get address of next position in format string
				sb	$t1, 0($t3)
				addi	$t2, $t2, 1		#increment format string counter by 1
				j	getformat		
			$t2Counter:	
					add	$t3, $t2, $s1		#get address of next position in format string
					sb	$t1, 0($t3)		#we store the last " in the format string to use it as indication that format string has ended
					li	$t2, 0			#when we finish using $t2 counter to get format string we initialize it to zero so we can use it again
					j	traverse				
		arguments:	
				addi	$t2, $t2, 1
				bgt  	$t2, 4, ArgToStack	#if the arguments are more than 4 we go to store the rest in stack
				beq	$t2, 1, FirstArg
				beq	$t2, 2, SecondArg
				beq	$t2, 3, ThirdArg
				beq	$t2, 4, FourthArg
			FirstArg:
					move	$a0, $t1		#save the first argument in $a0
					j	traverse
			SecondArg:
					move	$a1, $t1		#save the second argument in $a1
					j	traverse
			ThirdArg:
					move	$a2, $t1		#save the third argument in $a2
					j	traverse
			FourthArg:
					move	$a3, $t1		#save the fourth argument in $a3
					j	traverse
			ArgToStack:
					addi	$sp, $sp, -1
					sb	$t1, 0($sp)		#save any more arguments in the stack
					j	traverse
		ParsFinish:
				jr	$ra			#since we didn't use jal inside parser, $ra still contains the address of the next instruction to do after parsing
	sprintf:	
			li	$t0, 0			#when we finish using $t0 counter to traverse user input we initialize it to 0 so we can use it again to go through format string
			li	$t3, 0			#$t3 is only used in parsing, we use it again as a counter to output in the buffer
			li	$t4, 0			#we initialize $t4 to 0 to keep track of how many % we encountered (tells us which argument to process and helps us retrieve arguments from the stack)
			move	$s0, $v0
		loop:		
								#$t2 is still carrying how many arguments we have
				add	$t1, $t0, $s1		#get the address of the next character in the format string ($s1 has the address of the format string)
				lb	$t1, 0($t1)		#load the ith char from format string
				beq	$t4, $t2, sprintfFin	#if number of % we encountered equals the number of arguments we have that means we finished formating
				beq	$t1, 37, Formating
				beq	$t1, 92, Enter 						
				add	$s6, $t3, $s0		#save the address of the next char in the outbuf in $s6
				sb	$t1, 0($s6)		#if we didn't encounter a % sign, store the current char in the outbuf string		
				addi	$t0, $t0, 1
				addi	$t3, $t3, 1
				j 	loop			#loop the format string
			Enter:	
					li	$t1, 10
					add	$s6, $t3, $s0
					sb	$t1, 0($s6)
					addi	$t3, $t3, 1
					addi	$t0, $t0, 2
					j	loop
			sprintfFin:
					jr	$ra
			Formating:	
					addi	$t4, $t4, 1		#increment $t4 counter by 1 whenever encountering a % to know which argument to format
					bgt	$t4, 4, GetArg		#if the number of % encountered is more than 4 this means we are dealing with arguments stored in the stack, GetArg gets the required argument and stores it in $a0(assuming it was already processed and stored in outbuf)
					beq	$t4, 2, a1_setter
					beq	$t4, 3, a2_setter
					beq	$t4, 4, a3_setter
					beq	$a0, 'a', a_value0	#we get the value corresponding to char stored in $a0
					beq	$a0, 'b', b_value0	#we get the value corresponding to char stored in $a0
					beq	$a0, 'c', c_value0	#we get the value corresponding to char stored in $a0
					beq	$a0, 'd', d_value0	#we get the value corresponding to char stored in $a0
					beq	$a0, 'e', e_value0	#we get the value corresponding to char stored in $a0
					j	GetArgRet
			a1_setter:					#after we set the value corresponding to char in $a0, we return here to get the value corresponding to char stored in $a1
					beq	$a1, 'a', a_value1	#we get the value corresponding to char stored in $a1
					beq	$a1, 'b', b_value1	#we get the value corresponding to char stored in $a1
					beq	$a1, 'c', c_value1	#we get the value corresponding to char stored in $a1
					beq	$a1, 'd', d_value1	#we get the value corresponding to char stored in $a1
					beq	$a1, 'e', e_value1	#we get the value corresponding to char stored in $a1
					j	GetArgRet
			a2_setter:					#after we set the value corresponding to char in $a1, we return here to get the value corresponding to char stored in $a2
					beq	$a2, 'a', a_value2	
					beq	$a2, 'b', b_value2	
					beq	$a2, 'c', c_value2	#we get the value corresponding to char stored in $a2
					beq	$a2, 'd', d_value2	
					beq	$a2, 'e', e_value2	
					j	GetArgRet
			a3_setter:					#after we set the value corresponding to char in $a2, we return here to get the value corresponding to char stored in $a3
					beq	$a3, 'a', a_value3
					beq	$a3, 'b', b_value3
					beq	$a3, 'c', c_value3	#we get the value corresponding to char stored in $a3
					beq	$a3, 'd', d_value3
					beq	$a3, 'e', e_value3
					j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
				a_value0:
						move	$a0, $t5
						move	$s3, $a0
						j	GetArgRet		#after we set the value corresponding to char in $a0, we go to a1_setter to get the value corresponding to char stored in $a1
				b_value0:
						move	$a0, $t6
						move	$s3, $a0
						j	GetArgRet		#after we set the value corresponding to char in $a0, we go to a1_setter to get the value corresponding to char stored in $a1
				c_value0:
						move	$a0, $t7
						move	$s3, $a0
						j	GetArgRet		#after we set the value corresponding to char in $a0, we go to a1_setter to get the value corresponding to char stored in $a1
				d_value0:
						move	$a0, $t8
						move	$s3, $a0
						j	GetArgRet		#after we set the value corresponding to char in $a0, we go to a1_setter to get the value corresponding to char stored in $a1
				e_value0:
						move	$a0, $t9
						move	$s3, $a0
						j	GetArgRet		#after we set the value corresponding to char in $a0, we go to a1_setter to get the value corresponding to char stored in $a1
				a_value1:
						move	$a1, $t5
						move	$s3, $a1
						j	GetArgRet		#after we set the value corresponding to char in $a1, we go to a2_setter to get the value corresponding to char stored in $a2
				b_value1:
						move	$a1, $t6
						move	$s3, $a1
						j	GetArgRet		#after we set the value corresponding to char in $a1, we go to a2_setter to get the value corresponding to char stored in $a2
				c_value1:
						move	$a1, $t7
						move	$s3, $a1
						j	GetArgRet		#after we set the value corresponding to char in $a1, we go to a2_setter to get the value corresponding to char stored in $a2
				d_value1:
						move	$a1, $t8
						move	$s3, $a1
						j	GetArgRet		#after we set the value corresponding to char in $a1, we go to a2_setter to get the value corresponding to char stored in $a2
				e_value1:
						move	$a1, $t9
						move	$s3, $a1
						j	GetArgRet		#after we set the value corresponding to char in $a1, we go to a2_setter to get the value corresponding to char stored in $a2
				a_value2:
						move	$a2, $t5
						move	$s3, $a2
						j	GetArgRet		#after we set the value corresponding to char in $a2, we go to a3_setter to get the value corresponding to char stored in $a3
				b_value2:
						move	$a2, $t6
						move	$s3, $a2
						j	GetArgRet		#after we set the value corresponding to char in $a2, we go to a3_setter to get the value corresponding to char stored in $a3
				c_value2:
						move	$a2, $t7
						move	$s3, $a2
						j	GetArgRet		#after we set the value corresponding to char in $a2, we go to a3_setter to get the value corresponding to char stored in $a3
				d_value2:
						move	$a2, $t8
						move	$s3, $a2
						j	GetArgRet		#after we set the value corresponding to char in $a2, we go to a3_setter to get the value corresponding to char stored in $a3
				e_value2:
						move	$a2, $t9
						move	$s3, $a2
						j	GetArgRet		#after we set the value corresponding to char in $a2, we go to a3_setter to get the value corresponding to char stored in $a3
				a_value3:
						move	$a3, $t5
						move	$s3, $a3
						j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
				b_value3:
						move	$a3, $t6
						move	$s3, $a3
						j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
				c_value3:
						move	$a3, $t7
						move	$s3, $a3
						j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
				d_value3:
						move	$a3, $t8
						move	$s3, $a3
						j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
				e_value3:
						move	$a3, $t9
						move	$s3, $a3
						j	GetArgRet		#after we finish setting the coreesponding values of chars in $a0-$a3 we go to GetArgRet so we can start formating those numbers
			GetArgRet:	
					addi	$t0, $t0, 1
					add	$t1, $t0, $s1
					lbu	$t1, 0($t1)		#those 3 lines get the next char after the % sign
			Which_Arg_To_Ret:	
					beq	$t1, 'd', DecInt	#if the char after % is d deal with the corresponding argument as signed int and output in decimal format
					beq	$t1, 'u', DecIntU	#if the char after % is u deal with the corresponding argument as unsingend int and output in decimal format	
					beq	$t1, 'b', Binary	#if the char after % is d deal with the corresponding argument as unsingend int and output in Binary format		
					beq	$t1, 'x', LowHex	#if the char after % is x deal with the corresponding argument as unsingend int and output in lowercase hex format		
					beq	$t1, 'X', UpHex 	#if the char after % is X deal with the corresponding argument as unsingend int and output in uppercase hex format	
					beq	$t1, 'o', Octal		#if the char after % is o deal with the corresponding argument as unsingend int and output in octal format	
					beq	$t1, 'c', Char		#if the char after % is c deal with the low byte of the corresponding argument as char and copy it to ouptput	
					beq	$t1, 's', String	#if the char after % is s deal with the corresponding argument as pointer to null terminated string to copy to ouptput
					j	loop			#here we are supposed to have finished formating the required argument, so we 
				GetArg:
									#since $t2 has how many arguments we have and $t0 tells us which argument we are dealing with we can calculate the offset to retrieve that element from the stack by ($t2-$t0)*4
						sub	$s2, $t2, $t4
						#sll	$s2, $s2, 1		#multiply the difference between $t2 and $t0 by 4
						add	$s2, $s2, $sp		#get the address of the argument in the stack by adding the address of stack pointer to ($t2-$t0)*4
						lb	$a0, 0($s2)		
						beq	$a0, 'a', a_value0	
						beq	$a0, 'b', b_value0
						beq	$a0, 'c', c_value0
						beq	$a0, 'd', d_value0
						beq	$a0, 'e', e_value0
						j	GetArgRet		#after getting the required argument from the stack, return to the formating part
				DecInt:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 10
						slt	$s7, $s3, $0
						bgt	$s3, 0, DecIntloop
						neg	$s3, $s3
					DecIntloop:	
						div	$s3, $s5
						mfhi	$s6
						addi	$s6, $s6, 48
						mflo	$s3
						addi	$sp, $sp, -1
						sb	$s6, 0($sp)
						addi	$s4, $s4, 1
						bgt	$s3, 0, DecIntloop
						bne	$s7, 1, L1
						li	$s7, 45
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
					L:	
						lb	$s7, 0($sp)
						addi	$t3, $t3, 1
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4, L
						addi	$t3, $t3, 1
						j	endDecInt
					L1:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,L1
					endDecInt:
						addi	$t0, $t0, 1
						j	loop
						
				DecIntU:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 10
					UDecIntloop:	
						divu	$s3, $s5
						mfhi	$s6
						addi	$s6, $s6, 48
						mflo	$s3
						addi	$sp, $sp, -1
						sb	$s6, 0($sp)
						addi	$s4, $s4, 1
						bgt	$s3, 0, UDecIntloop
					UL:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,UL
					#endUDecInt:
						addi	$t0, $t0, 1
						j	loop
				Binary:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 2
					BLpos:	
						remu	$s7, $s3, $s5
						addi	$s7, $s7, 48
						divu	$s3, $s3, $s5
						addi	$sp, $sp, -1
						sb	$s7, 0($sp)
						addi	$s4, $s4, 1
						bnez	$s3, BLpos
					BinStck:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,BinStck
					#endUDecInt:
						addi	$t0, $t0, 1
						j	loop	
				LowHex:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 16
					LowHexloop:	
						divu	$s3, $s5
						mfhi	$s6
						blt	$s6, 10, LThan10
						addi	$s6, $s6, 39
					LThan10:
						addi	$s6, $s6, 48
						mflo	$s3
						addi	$sp, $sp, -1
						sb	$s6, 0($sp)
						addi	$s4, $s4, 1
						bgt	$s3, 0, LowHexloop
					LowHexL:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,LowHexL
					#endUDecInt:
						addi	$t0, $t0, 1
						j	loop
				UpHex:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 16
					UpHexloop:	
						divu	$s3, $s5
						mfhi	$s6
						blt	$s6, 10, LThan10Up
						addi	$s6, $s6, 7
					LThan10Up:
						addi	$s6, $s6, 48
						mflo	$s3
						addi	$sp, $sp, -1
						sb	$s6, 0($sp)
						addi	$s4, $s4, 1
						bgt	$s3, 0, UpHexloop
					UpHexL:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,UpHexL
					#endUDecInt:
						addi	$t0, $t0, 1
						j	loop
				Octal:
						li	$s4, 0			#counter of chars stored in stack
						li	$s5, 8
					Octloop:	
						remu 	$s6, $s3, $s5
						divu 	$s3, $s3, $s5
						addi	$s6, $s6, 48
						addi	$sp, $sp, -1
						sb	$s6, 0($sp)
						addi	$s4, $s4, 1
						bgt	$s3, 0, Octloop
					OL:	
						lb	$s7, 0($sp)
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$sp, $sp, 1
						addi	$s4, $s4, -1
						bnez 	$s4,OL
					#endOct:
						addi	$t0, $t0, 1
						j	loop

				Char:
						and	$s3, 0xff
						add	$s6, $t3, $s0
						sb	$s3, 0($s6)
						addi	$t3, $t3, 1	
						addi	$t0, $t0, 1
						j	loop
				String:
						li	$s4, 0		#here we use $s4 as a counter to traverse the null terminated string pointed to by $s3
					SL:	add	$s7, $s4, $s3
						lb	$s7, 0($s7)
						beqz	$s7, endString
						add	$s6, $t3, $s0
						sb	$s7, 0($s6)
						addi	$t3, $t3, 1
						addi	$s4, $s4, 1
						j	SL
					endString:
						addi	$t0, $t0, 1
						j	loop
