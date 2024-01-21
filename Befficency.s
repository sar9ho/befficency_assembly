
.data
done:  .asciiz "DONE"
space: .asciiz " "
lineBreak: .asciiz "\n"
buildingp: .asciiz "Building name: "    #char , 64 bytes, [0]
buildingnamein: .space 64           
sqrtftp: .asciiz "Sqrft: "              #int , 4 bytes ,
annualelecp: .asciiz "Annual Electricity: "     #float , 4 bytes
zeroAsFloat: .float 0.0                
#ratio                                  #float, 4 bytes, [68]
#next                                   #pointer, 4 bytes [72]
                                        #total = 72
testout: .asciiz "test"

.text

main: #which t registers are improtant to you and where

    addi $sp, $sp, -4
    sw $ra, ($sp)    

    ###############################################################################
    #CREATE HEAD - set to null

    li $a0, 76   # $a0 contains the number of bytes you need. This must be a multiple of four.
    li $v0,9     # code 9 == allocate memory
    syscall      # call the service.

    move $s0, $v0  #overwrite so that s0 is the address of first byte
    move $s3, $s0 #save null struct - ACTUAL HEAD POINTER ILL BE USING
    move $s4, $s0 #save null struct

    # set name to null
    sw $0, 0($s3)
    # set ratio to null
    sw $0, 64($s3)
    # set next to null
    sw $0, 68($s3)

    ###############################################################################

    #REFERENCE
    #S3 = HEADPOINTER - DONT CHANGE
    #S4 = NULL STRUCT - DONT CHANGE
    #S6 = NEWNODE - DONT CHANGE

    #CREATES NODES OF "LINKED LIST"

    CreateStruct:

        #tempnodeforname
       # move $t3, $s4
        

        #CREATE STRUCT/MALLOC SPACE
        li $a0, 76                          # $a0 contains the number of bytes you need. This must be a multiple of four.
        li $v0,9                            # code 9 == allocate memory
        syscall                             # call the service.

        move $s6, $v0                       #overwrite so that s6 is the address of first byte
                                            #basically, newnode is s6
        sw $0, 72($s6)                      #newb -> next = NULL; 


        #PROMPT USER FOR BUILDING NAME
        li $v0, 4
        la $a0, buildingp
        syscall

        #GET TEXT USER INPUT
        li $v0, 8 
        la $a0, 0($s6)
        li $a1, 64
        syscall

        addi $sp, $sp, -4
        sw $ra, ($sp) 
        jal rmnewln
        lw $ra, ($sp)                     #retrieve ra from stack
        addi $sp, $sp, 4

        la $a0, 0($s6)                      #a0 stores input for name - to be used in strcmp
        la $a1, done                        #load done into a1 to use for strcmp
        addi $sp, $sp, -4
        sw $ra, ($sp) 
        jal strcmp                          #compare if DONE
        lw $ra, ($sp)                       #retrieve ra from stack
        addi $sp, $sp, 4  
    #   la $a0, ($s3)
        beqz $v0, prepprint                 #if result of strcmp 0, branch to printlist
        j sq

        prepprint:
        move $a3, $s3
        j printlist
    #USER DOESNT ENTER DONE SO SCAN FOR OTHER INPUTS:


    sq:
        #PROMPT USER FOR SQRFT
        li $v0, 4
        la $a0, sqrtftp                     #display message
        syscall

        li $v0, 5                           #read user input
        syscall

        move $s2, $v0                       #s2 CONTAINS SQRFT INPUT

        #PROMPT USER FOR ELECTRICITY

        li $v0, 4
        la $a0, annualelecp                 #display message
        syscall

        li $v0, 6                           #read user input
        syscall                             #ELECTRICITY STORED IN f0 REGISTER

        #CHECK IF ELECTRICITY IS 0:
        l.s $f4, zeroAsFloat
        c.eq.s $f0, $f4
        bc1t effzero

        #check if sqrft is 0:
        beqz $s2, effzero                   #if sqrt 0, efficiency is 0

        #IF ELECT. & SQRFT IS NOT 0: CALCULATE AND STORE EFFICIENCY -- elec/sqrft
        mov.s $f6, $f0
        mtc1 $s2, $f1                       #Move INT (SQRFT) TO fp register
        cvt.s.w $f5, $f1                    #convert from int to fp - store in f5 (sqrft)   
        div.s $f3, $f6, $f5                 #f3 stores efficiency (elec/sqrft)
        s.s $f3, 68($s6)                    #store efficiency into struct/node
        
        j prepsort

    effzero:
        s.s $f4, 68($s6)                    #store efficiency of ZERO into struct/node
        j prepsort

    prepsort:
        move $a0, $s3                       #argument0 stroes HEAD (originally at null)
        move $a1, $s6                       #argument1 stores NEWNODE
        addi $sp, $sp, -4
        sw $ra, ($sp)  
        jal insertsorted                    #SORT - CALL INSERTSORTED
        lw $ra, ($sp)                       #retrieve ra from stack
        addi $sp, $sp, 4  
        move $s3, $v0                       #head = result of insertsorted (head = insertsorted(head,newb);

        j CreateStruct                      #jump back to beginning and create another struct

#   INSERT SORT---------------------------------------------------------------

insertsorted:
    addi $sp, $sp, -12
    sw $s2, ($sp)
    sw $s5, 4($sp)
    sw $s4, 8($sp)

    move $s2, $a0  #save head - will be modified in comp
    move $s5, $a1  #save newnode - will be modified in comp

    beqz $a0, headnull  

    addi $sp, $sp, -4
    sw $ra, ($sp)           #save ra onto stack
    jal comp                #comp(newnode, head)
    lw $ra, ($sp)           #retrieve ra from stack
    addi $sp, $sp, 4        #add 4 back to stack     
    bnez $v0, newnodefirst  #if result of comp 1 (newnode first) 

    move $t4, $s2           #t4 = current = head
    move $t5, $s4           #t5 = previous = null

    whilel:
        beqz $t4, currentnull
        move $a0, $s5
        move $a1, $t4
        addi $sp, $sp, -12
        sw $ra, ($sp) 
        sw $t4, 4($sp)
        sw $t5, 8($sp) 
        jal comp       
        lw $ra, ($sp)           #retrieve ra from stack
        lw $t4, 4($sp)
        lw $t5, 8($sp)
        addi $sp, $sp, 12        #add 4 back to stack      
        beqz $v0, currentnull   #if result of comp not 1 (current bigger), exit whileloop
        move $t5, $t4           #if loop conditions satisfied, previous = current 
        lw $t4, 72($t4)         #Current = current -> next
        j whilel

    currentnull:
    bnez $t4, elsenz
    sw $s5, 72($t5)     #if current == null, Previous -> next = newnode
    j ret

    elsenz:
    sw $s5, 72($t5)     #Previous -> next = newnode
    sw $t4, 72($s5)     #Newnode -> next = current
    j ret 

    ret:
    move $v0, $s2       #return head (end of insertsort)
    lw $s2, ($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    addi $sp, $sp, 12
    jr $ra

    newnodefirst:
    sw $s2, 72($s5)         #newnode -> next = head
    move $v0, $s5           #return newnode
    lw $s2, ($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    addi $sp, $sp, 12
    jr $ra 


    headnull:
    move $v0, $a1  #if head == null, return newnode (stored in a1)
    lw $s2, ($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    addi $sp, $sp, 12
    jr $ra


#COMPARATOR (COMP) --- IF NEWNODE FIRST, RETURN 1 -----------------------

comp:
    lw $t3, 68($a1)                  #t3 = newnode ->ratio
    lw $t8, 68($a0)                  #t8 = head -> ratio
    beq $t3, $t8, ratiosequal
    slt $v0, $t8, $t3                #if $t3 (newnode ratio) > $t8 (input ratio), return 1 
    jr $ra 

    ratiosequal:
    la $a1, 0($a1)                  #load newnode's name for strcmp
    la $a0, 0($a0)                  #load head's name for strcmp
    addi $sp, $sp, -12
    sw $ra, ($sp)
    sw $t3, 4($sp)
    sw $t8, 8($sp)
    jal strcmp
    lw $ra, ($sp)                   #retrieve ra from stack
    lw $t3, 4($sp)
    lw $t8, 8($sp)
    addi $sp, $sp, 12                #add 4 back to stack  
    #if result of strcmp -1, return 1, else 0 
    li $t6, -1
    beq $v0, $t6, newfirst          #if strcmp return -1, return 1 (newnode first)
    li $v0, 0                       #else return 0
    jr $ra

    newfirst:
    li $v0, 1
    jr $ra

#END OF SORTING-----------

#END OF FILE - USER ENTERS DONE - PRINT LINKED LIST
printlist:


    beqz $a3, EndOfLinkedList           #if head = NULL

    move $t3, $a3

    move $t5, $a3
    la $a0, 0($t5)                       #a0 stores input for name - to be used in strcmp

    la $a1, done                        #load done into a1 to use for strcmp

    addi $sp, $sp, -8
    sw $ra, ($sp)
    sw $t5, 4($sp)
    jal strcmp                      #compare if DONE
    lw $ra, ($sp)                   #retrieve ra from stack
    lw $t5, 4($sp)
    addi $sp, $sp, 8  
    beqz $t3, EndOfLinkedList     

    li $v0, 4 
    la $a0, 0($a3)                   # print string
    syscall

    li $v0, 4
    la $a0, space                    #print space
    syscall

    li $v0, 2
    l.s $f1, 68($a3) 
    mov.s $f12, $f1                  #print efficiency
    syscall

    li $v0, 4
    la $a0, lineBreak                    #print newline
    syscall

    move $t7, $s4                   #t7 = new empty struct (temp)
    lw $t7, 72($a3)                 #struct BuildEff* temp = head->next;
    move $a3, $t7                   #head is now next node
    j printlist                     #restart while loop till head = null


    EndOfLinkedList:            #END OF PROGRAM

        lw $ra, ($sp)               #retrieve ra from stack
        addi $sp, $sp, 4            #add 4 back to stack
        jr $ra 


##HELPER FUNCTION - REMOVE NEW LINE
rmnewln:                            # removes new line 
    lb $t0, 0($a0) 
    addi $a0, $a0,1
    bnez $t0, rmnewln
    addi $a0, $a0, -2            # go back 2 bytes and set the "\" from "\n" to 0. 
    sb $0, 0($a0)
    jr $ra

#compare strings 
strcmp:
    iterate:
    lb $t2, 0($a1)              #first char of newnode
    lb $t3, 0($a0)              #first char of head

    beq $t2, $zero, _equal      
    blt $t2, $t3, _less         #if newnode less than head, return -1 (NEWNODE FIRST)
    bgt $t2, $t3, _greater      #if newnode greater than head, return 1
    beq $t2, $t3, _increment    #if newnode equals head, keep incrementing
    
    _increment:
        addi $a1, $a1, 1
        addi $a0, $a0, 1
        j iterate 
    _equal:
        li $v0, 0          #compares strings and gives back outputs
        jr $ra
    _less:
        li $v0, -1
        jr $ra

    _greater:
        li $v0, 1
        jr $ra