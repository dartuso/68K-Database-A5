;Purpose: Demonstration program for a movie database, 
;supports listing database, finding entries by year, and deleteing entries.

;Details:
;Input: loads from file "movie_db.dat - from the filename variable
;	User inputs menu choices, years they want to see and entry to delete
;Output: Prints info to screen, saves final database to movie.out from outfile var  
;Formula: Horner rule for year selection and delete selection, divide by 10 and  
;reverse numbers (using stack) for year
;Quirks: Ok for some reason when program is compiled address of a4 = a5
;this address is set at the end of e_msg var in a5lib, 
;so if any chars are pushed into a4/a5 this will affect e_msg
;this effectly makes a4/a5 unusable, and can cause crashes if harmful data
;is placed at the end of e_msg (based on first hand experience)

;Status: All operations are tested and working 
;Testing plan
;List by year 
;Tried multiples entries correct year and correctly printed
;1957,2013,1954 - lowest, highest and multiple item year
;Reason: Since we know these should return something
;Tried multiple incorrect entries and correctly did not print
;0000,9999,1956- Reason: lowest, highest, similar values
;List - tried multiple list and correctly printed
;1 - Reason: make sure it work correctly and pause correct
;Delete and List - Deleted multiple elements and correctly listed with result
;12,01,05- Reason: Last,first and middle
;-Tried multiple invalid inputs and check that not deleted
;00,14,99 - Reason: lowest, first wrong, highest
;Delete and Exit - Deleted multiple element and loaded output file and listed correctly
;12,01,06 - Reason: delete front, last and middle
;also check out file size and successfully compared to expected

;Register Table
;d0 - input/output values also various
;d1-3 - various
;a2 - usually database and string to output
;a0 - various
;a3-4 - used in delete for offset arrays
;a6 - frames 

;movie struct
MOVIE	equ	62
TITLE	equ	0
YEAR	equ	52
TIME	equ	54
RATING	equ	56

ARRAY	equ	15
MAXSIZE	equ	MOVIE*ARRAY

RECORD	equ	8
RECPLLG	equ	12 ;record plus long = 12

NULL	equ	0
CR	equ	13
LF	equ	10

	xref	read_file
	xref	write_file
	xref	read_char
	xref	write_char
	xref	exit

start:	move.l	#MAXSIZE,-(sp)
	pea	charsreadin
	pea	database
	pea	filename
	jsr	read_file
	add.l	#16,sp
	move.l	(charsreadin),d2 ;d2 = number item (temp)
	divu.w	#MOVIE,d2
	move.b	d2,numberitem
readopt:			;get switch choice
	jsr escape_screen
	pea	menu
	jsr	print_string
	add.l	#4,sp
	move.b 	#00,-(sp)
	jsr	read_char
	move.b	(sp)+,d0
	jsr	print_crlf

op1:	cmp.b   #'1',d0		;option 1:list
	bne	op2
	pea	database
	move.b	(numberitem),-(sp)
	jsr	list
	add.l	#6,sp
	jsr	print_crlf
	jsr	sys_wait
	bra	readopt
op2:
	cmp.b   #'2',d0		;option 2:list by year
	bne	op3
	pea	database
	move.b	(numberitem),-(sp)
	jsr	listbyyear
	add.l	#6,sp
	jsr	print_crlf
	jsr	sys_wait
	bra	readopt
op3:
	cmp.b   #'3',d0		;option 3:delete
	bne	op4
	pea	database
	move.l	(charsreadin),-(sp)
	move.l	#0,-(sp)
	move.w	#0,-(sp)	
	jsr	delete
	move.l	(sp)+,d0
	move.l	d0,charsreadin
	move.b	(sp)+,d0
	move.b	d0,numberitem
	add.l	#8,sp
	jsr	print_crlf
	jsr	sys_wait
	bra	readopt
op4:
	cmp.b   #'4',d0		;option 4: quit
	bne	readopt		;default: return to top
	move.l	charsreadin,-(sp)
	pea	database
	pea	outfile
	jsr	quit
	add.l	#12,sp
	move.l	#0,-4(sp)
	jsr	exit
	
;void	list (database, numberitem)
list:	link	a6,#0
	movem.l	d0-4/a2,-(sp)
	
	move.b	RECORD(a6),d2
	movea.l	10(a6),a2
	clr.l 	d0		;d0 = input/output & temp stuff
	clr.l   d1		;d1 = entry counter
	clr.l	d3		;d3 = entry offset
nxtent	add.b	#1,d1

	move.b 	#'#',d0		;write	# and number of item
	move.b	d0,-(sp)
	jsr	write_char
	add.l	#2,sp
	move.b 	d1,d0
	move.w	d0,-(sp)
	jsr	print_number
	add.l	#2,sp
	jsr	print_crlf

	pea	TITLE(a2,d3.l)	;load entry into print entry
	jsr	print_entry
	add.l	#4,sp
	add.w	#MOVIE,d3
	clr.l	d4

	move.b	d1,d4		;if divisible by 3 then wait for user input
	divu.w	#3,d4		;d4 = current item
	swap	d4
	cmp.b	#0,d4
	bne	skip
	jsr	sys_wait


skip	cmp.b	d1,d2
	bne	nxtent

	movem.l	(sp)+,d0-4/a2
	unlk	a6
	rts

;void listbyyear (char database[],int numberitem)
listbyyear:
	link	a6,#0
	movem.l d0-4/a2-3,-(sp)
	movea.l	10(a6),a2	;a2 = database

	pea	listbyyrmenu
	jsr	print_string
	add.l	#4,sp

	clr.l	d0
	move.l	#3,d2		;d2 - 4 char input counter
yrch:
	move.b #0,-(sp)		;user enter desire year
	jsr	read_char
	move.b	(sp)+,d0	;d0 = temp input values
	sub.b	#'0',d0
	move.b	d0,-(a2)
	add.l	#2,sp
	tst.b	d2
	dbeq	d2,yrch
	clr.l	d2

realyr:	move.b	(a2)+,d0	;reverse string and horner rule it
	move.b	(a2)+,d1	;d1-3 = temp values of digits
	mulu	#10,d1
	move.b	(a2)+,d2
	mulu	#100,d2
	move.b	(a2)+,d3
	mulu	#1000,d3
	add.w	d1,d0
	add.w	d2,d0
	add.w	d3,d0		;d0 - real value of input

	jsr	print_crlf
	clr.l	d1
	clr.l	d2
	clr.l	d3
	clr.l	d4		;d4=current entry offset
	move.b	RECORD(a2),d3	;d3=numberitem

nxtyear:
	add.b	#1,d1
	cmp.w	YEAR(a2,d4.l),d0 ;check if years are equal
	bne	count
	pea	TITLE(a2,d4.l)
	jsr	print_entry
	add.l	#4,sp
count:	add.l	#MOVIE,d4	;go to next entry and check if list is done
	cmp.b	d1,d3
	bne	nxtyear

	movem.l (sp)+,d0-4/a2-3
	unlk	a6
	rts

;(int number & int charsreadin)	delete(int charreadin,char database[])
;deletes an user selected entry
delete:
	link	a6,#0
	movem.l d0-4/a2-4,-(sp)

	move.l	14(a6),d4	;d4 - number of chars
	movea.l	18(a6),a2	;a2 - database

	move.l	#1,d2		;d2 - 2 character input counter

	pea	deletemenu
	jsr	print_string
	add.l	#4,sp
nxselec:
	move.b #0,-(sp)		;get user input
	jsr	read_char
	move.b	(sp)+,d0
	sub.b	#'0',d0
	move.b	d0,-(sp)
	tst.b	d2
	dbeq	d2,nxselec
	clr.l	d2
	move.b	(sp)+,d0	;get real value of input
	move.b	(sp)+,d1	
	mulu	#10,d1
	add.b	d0,d1		;d1 - value of selection
	sub.b	#1,d1		;since array starts at 0

	cmp.b	#0,d1		;make sure valid input
	blt	invalid

	move.w	d4,d3
	move.w	d1,d2
	mulu.w	#MOVIE,d1	;d1 = start of element for deletion
	add.w	#1,d2
	mulu.w	#MOVIE,d2	;d2 = start of next element
	
	cmp.w	d4,d1
	bhi	invalid		;make sure valid input
	bra	valid

invalid:nop			;deal with return values if invalid selection
	move.l	d4,RECORD(a6)	;return old values
	divu.w	#MOVIE,d4
	move.b	d4,RECPLLG(a6)
	bra endrm
valid:
	sub.w	d1,d4		;d4 = number of char in database - start of element
	sub.w	#MOVIE,d3	;d3 =  updated number of char in database
	move.l	d3,RECORD(a6)	
	move.l	d3,d0
	divu.w	#MOVIE,d0	;d0 - updated number items
	move.b	d0,RECPLLG(a6)	
			
	lea	TITLE(a2,d1),a3	;address register starting from element to be deleted
	lea	TITLE(a2,d2),a4	;address register starting from next element

	
lp	move.b	(a4)+,(a3)+	;copy all of a4 into a3 which removes the entry
	tst.w	d4
	dbeq	d4,lp		
endrm	nop


	movem.l (sp)+,d0-4/a2-4
	unlk	a6
	rts

;void	quit (char outfile[],char database[],int charsreadin)
quit:
	;print database to output file
	link	a6,#0
	movem.l	d0,-(sp)

	move.b	#0,-(sp)
	move.l	16(a6),-(sp)		;push charsreadin
	move.l	RECPLLG(a6),-(sp)		;push database
	move.l	RECORD(a6),-(sp)	;push outfile
	jsr	write_file		;all move since we already passed by reference
	move.b	(sp)+,d0
	add.l	#12,sp
	
	movem.l	(sp)+,d0
	unlk	a6
	rts

;helpers subroutines
;void print_entry (char database[]) - print an entry from the database
print_entry:
	

	link	a6,#0
	movem.l	d0/a2,-(sp)

	movea.l	RECORD(a6),a2	;a2 - used for database

	pea	TITLE(a2)	;print title
	jsr	print_string
	addq.l	#4,sp
				
	move.w	YEAR(a2),d0	;print year
	move.w	d0,-(sp)
	jsr	print_number
	addq.l	#2,sp
	jsr	print_crlf

	
	move.w	TIME(a2),d0	;print time
	rol.w	#8,d0
	move.w	d0,-(sp)
	jsr	print_number
	addq.l	#2,sp
	jsr	print_crlf

	pea	RATING(a2)	;print rating
	jsr	print_string
	addq.l	#4,sp
	jsr	print_crlf

	movem.l	(sp)+,d0/a2
	unlk	a6
	rts

;void print_number (int number) - seperates number into seperate digits and prints
print_number:
	link 	a6,#0
	movem.l	d0-1/a0,-(sp)
	move.w	RECORD(a6),d1	;d1 - real value of number

nextyr:	divu.w	#10,d1
	swap	d1
	move.b	d1,d0
	add.b	#'0',d0
	move.b	d0,-(a0)
	clr.w	d1
	swap	d1
	tst.w	d1
	bne	nextyr		;divide by 10 until empty

rvr:	tst.b	(a0)	
	beq	lstdgt

	move.b 	(a0)+,d0	;reverse order and print
	move.b	d0,-(sp)
	jsr	write_char
	add.l	#2,sp
	bra	rvr
lstdgt:	nop

	movem.l	(sp)+,d0-1/a0
	unlk	a6
	rts

;void print_string (char string[]) -prints passed string and newline
print_string:
	;print each character until null terminator
	link	a6,#0
	movem.l	d0/a2,-(sp)
	movea.l	RECORD(a6),a2	;a2 - string to print
nextchr move.b	(a2)+,d0
	cmp.b	#NULL,d0
	beq	donestr
	move.b	d0,-(sp)
	jsr	write_char
	add.l	#2,sp
	bra	nextchr
donestr	jsr	print_crlf
	movem.l	(sp)+,d0/a2
	unlk	a6
	rts

;void print_crlf() - prints newline
print_crlf:
	link	a6,#0
	move.b	#CR,-(sp)
	jsr	write_char
	add.l	#2,sp

	move.b	#LF,-(sp)
	jsr	write_char
	add.l	#2,sp
	unlk	a6
	rts

;void escape_screen() -clears screen
escape_screen:
	link	a6,#0
	pea	escape
	move.w	#9,-(a7)
	trap	#1
	addq.l	#6,a7
	unlk	a6
	rts

;void sys_wait() - print a message and wait for input
sys_wait:
	link	a6,#0
	move.l	d0,-(sp)
	pea	PressAnyKey
	jsr	print_string
	add.l	#4,sp

	move.b	#0,-(sp)
	jsr	read_char
	move.b	(sp)+,d0

	move.l	(sp)+,d0
	unlk	a6
	rts

;variables
PressAnyKey:	dc.b	"Press any key to continue",CR,LF,NULL
menu:		dc.b	"1 - List",CR,LF,"2 - List by Year",CR,LF,"3 - Delete",CR,LF,"4 - Quit",CR,LF,"Enter Key:",NULL
listbyyrmenu:	dc.b	"Enter year to filter by: ",CR,LF,NULL
deletemenu:	dc.b	"Enter database item to delete (must be exactly two digits ex 02 or 11): ",CR,LF,NULL
filename:	dc.b	"movie_db.dat",NULL
;filename	dc.b	"movie.out",NULL	;swap this with other file if you want to load previous output
outfile:	dc.b	"movie.out",NULL

escape:		dc.b	27,"E",NULL


charsreadin:	ds.l	1
database:	ds.l	MAXSIZE
numberitem:	ds.b	1