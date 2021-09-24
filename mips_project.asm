		.data
file:		.space		100
buffer:		.space		512
number:		.space		513
newline:	.asciiz		"\n"
default:	.asciiz		"1"

		.text
main:
# read file name
# used registers:
# $t1 - register into which bytes from file are loaded
# $t2 - file iterator
		la	$a0, file
		li	$a1, 80
		li	$v0, 8
		syscall
	
		la	$t2, file
go_at_the_end:	lbu	$t1, ($t2)
		addiu	$t2, $t2, 1
		bne	$t1, 0, go_at_the_end
	
		subiu	$t2, $t2, 2
		sb	$zero, ($t2)
		
# open he file in append mode to create it when given file does not exists
# used registers:
# $t0 - registers stores file descriptor
# $t6 - contains the number of time that read_from_file occured
		li		$v0, 13			# load open file syscall parameter
		la		$a0, file		# load file name
		li		$a1, 9			# set append mode flag
		li		$a2, 0			# mode is ignored
		syscall
		
		# closeing the file
		move		$a0, $v0		# move file descriptor to close
		li		$v0, 16			# load close file syscall paramerer
		syscall
		
# reading from file
# used registers:
# $t0 - registers stores file descriptor
# $t1 - register stores the number of read bytes
# $t6 - contains the number of time that read_from_file occured
		# openning the file I want to read from
		li		$v0, 13			# load open file syscall parameter
		la		$a0, file		# load file name
		li		$a1, 0			# set read mode flag
		syscall

		move		$t0, $v0		# saving the file descriptor for later use
		li		$t6, 0			# set number of time that read_from_file occured
		
read_from_file:
		li		$v0, 14			# load read file syscall parameter
		move		$a0, $t0		# load file descriptor
		la		$a1, buffer		# load buffer address
		li		$a2, 512		# load buffer len
		syscall
		# remember numbers of read bytes
		move		$t1, $v0
		# branch to close file if nothing read
		beqz		$t1, close_file
		# increment the number of times that reading occured and any value was read
		addiu		$t6, $t6, 1

# used registers:
# $s0 - buffer iterator
# $t0 - registers stores file descriptor
# $t1 - register stores the number of read bytes 
# $t2 - register into which bytes from buffer are loaded
# $t3 - contains current substring length
# $t4 - contains the length of the last found and stored number
# $t5 - count the number of analyzed bytes
# $t6 - contains the number of time that read_from_file occured
# $t7 - number .asciiz iterator
		# preparing to analyze the buffer
		la		$s0, buffer		# buffer pointer
		li		$t3, 0			# current substring length
		li		$t4, 0			# last found number length
		li		$t5, 0
		la		$t7, number		# load number .space address, create a pointer

for:		# for loop - analizying the content inside the buffer
		lbu		$t2, 0($s0)		# load byte from buffer
		beq		$t5, $t1, check
		addiu		$t5, $t5, 1
		addiu		$s0, $s0, 1		# move buffer pointer forward
		bltu		$t2, '0', else		# branch if not a number
		bgtu		$t2, '9', else		# branch if not a number
		sb		$t2, ($t7)
		addiu		$t7, $t7, 1
		addiu		$t3, $t3, 1
		b		for
		
else:		# char different then digit found
		la		$t7, number
		beqz		$t3, for
		move		$t4, $t3
		li		$t3, 0
		b		for
		
check:		# checking whether anything left unread in the file
		beqz		$t3, continue
		move		$t4, $t3
continue:	bnez		$t1, read_from_file
		
close_file:	# closeing the file
		li		$v0, 16			# close file
		move		$a0, $t0		# file descriptor to close
		syscall

# used registers:
# $t0 - pointer to number .asciiz
# $t1 - carry value
# $t2 - register into which bytes from file are loaded
# $t4 - contains the length of the last found and stored number
# $t6 - contains the number of time that read_from_file occured
# $t7 - number .asciiz iterator
		beqz		$t4, open_file
		la		$t7, number
		addu		$t7, $t7, $t4		# move pointer to point at the last char stored in number .asciiz
		subiu		$t7, $t7, 1		# move pointer to point at the last char stored in number .asciiz
		la		$t0, number		# pointer to number .asciiz
		li		$t1, 1			# carry value
		
while:		bltu		$t7, $t0, open_file
		lbu		$t2, ($t7)
		addu		$t2, $t2, $t1
		bgtu		$t2, '9', new_carry
		li		$t1, 0
		sb		$t2, ($t7)
		b		open_file
			
new_carry:	li		$t2, '0'
		sb		$t2, ($t7)
		subiu		$t7, $t7, 1
		b		while	

open_file:
# used registers:
# $t0 - contains file descriptor
# $t1 - carry value
# $t4 - contains the length of the last found and stored number
# $t6 - contains the number of the times that read_from_file occured
		la		$a0, file
		li		$a1, 9
		li		$a2, 0
		li		$v0, 13
		syscall
		
		# saving the file descriptor
		move		$t0, $v0
		
		beqz		$t6, empty_file
		
		# appemd new line
		move		$a0, $t0
		la		$a1, newline
		li		$a2, 1
		li		$v0, 15
		syscall
		
		beqz		$t4, no_nums_found
		beqz		$t1, only_number
		
		# appending carry
		move		$a0, $t0
		la		$a1, default
		li		$a2, 1
		li		$v0, 15
		syscall
		
only_number:	# append - usual case
		# append incremented value
		move		$a0, $t0
		la		$a1, number
		move		$a2, $t4
		li		$v0, 15
		syscall
		# branch to close
		b		close

empty_file:	# when file is empty
		move		$a0, $t0
		la		$a1, default
		li		$a2, 1
		li		$v0, 15
		syscall
		# branch to close
		b		close
no_nums_found:	# file not empty, but no nums
		move		$a0, $t0
		la		$a1, default
		li		$a2, 1
		li		$v0, 15
		syscall
		
close:		# closing the file
		move		$a0, $t0
		li		$v0, 16
		syscall
		
		# exit / close program
		li		$v0, 10			# load exit syscall parameter
		syscall
