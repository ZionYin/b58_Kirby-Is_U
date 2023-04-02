#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ziyao Yin
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. A. score [2 marks]
# 2. B. Fail condition [1 mark]
# 3. C. Win condition [1 mark]
# 4. K. Double jump [1 mark]
# 5. M. Start menu [1 mark]
# 6. O. Player clones [3 marks]
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
# https://www.youtube.com/watch?v=D8KDsqksc0w
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
# https://github.com/ZionYin/b58_Kirby-Is_U
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################


# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 512
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.eqv BASE_ADDRESS 0x10008000
.eqv BOUNDARY 0x10010000 # 128 * 64 * 4 + 0x10008000
.eqv	GRAY 		0x808080
.eqv	YELLOW		0xBABA30
.eqv    YELLOW1     0xBABA31
.eqv    YELLOW2     0xBABA32
.eqv	RED		    0xFF0000
.eqv	BLUE		0x2E2EB0
.eqv	WHITE		0xFFFFFF
.eqv	BLACK		0x000000
.eqv	GREEN		0x00FF00
.eqv    PINK        0xEB8DD7
.eqv    BRIGHT_PINK 0xFF00B9

.eqv    KEY_ADDR    0xFFFF0000
.eqv    KIRBY_LOC_OFFSET  27700
.eqv    STAR_LOC_OFFSET   3108
.eqv    SLEEP       100
.eqv    ROW_LEN     512
.eqv    JUMP        2
.eqv    K_JUMP_HEIGHT  10
.eqv    S_JUMP_HEIGHT  7

.eqv    STAR_CAGE_OFFSET  21200


#------------------------------------------------------------
# allocate space for star related variables
#------------------------------------------------------------
.data 
paddingl:	.space		1024
star:	  .space   12
tempra:   .space   4
paddingr:	.space		1024

.text
#------------------------------------------------------------
# macros for low-level functions 
#------------------------------------------------------------
.macro sleep
    li $v0, 32
    li $a0, SLEEP
    syscall
.end_macro

.macro move_offset($start, $x, $y)
    li $t9, 4
    li $t8, $x
    mul $t9, $t9, $t8
    li $t8, ROW_LEN
    li $t7, $y
    mul $t8, $t8, $t7
    add $start, $start, $t9 # add x offset
    add $start, $start, $t8 # add y offset
.end_macro

.macro print_int($num)
    li $v0, 1
    move $a0, $num
    syscall
.end_macro

.macro erase($start, $width, $height, $color)
    # $t9 stores the starting address of the current row
    # $t8 stores number of columns left to erase
    # $t7 stores number of rows left to erase
    # $t6 stores the current pointer
    # $t5 stores the color to erase with

    move $t9, $start # $t9 stores the pointer to the current pixel
    li $t7, $height # $t7 stores the number of rows left to erase
    li $t5, $color

    # for each row of the object
    erase_row:
        beq $t7, $zero, end_erase # if we have erased all rows, end
        li $t8, $width # $t8 stores the number of columns left to erase       
        move $t6, $t9 # $t6 stores the pointer to the current pixel

        erase_col:
            beq $t8, $zero, end_erase_col # if we have erased all columns, end
            # erase the current pixel
            sw $t5, 0($t6)
            # move to the next pixel
            addi $t6, $t6, 4 # move to the next pixel
            addi $t8, $t8, -1 # decrement the number of columns left to erase
            j erase_col # erase the next column

        end_erase_col:
            addi $t9, $t9, ROW_LEN # move to the next row
            addi $t7, $t7, -1 # decrement the number of rows left to erase
            j erase_row # erase the next row

    end_erase:
.end_macro

.macro check_color($start, $width, $height, $color)
    # $t9 stores the starting address of the current row
    # $t8 stores number of columns left to check
    # $t7 stores number of rows left to check
    # $t6 stores the current pointer
    # $t5 stores the color to check with
    # $t4 stores the current color

    move $t9, $start # $t9 stores the pointer to the current pixel
    li $t7, $height # $t7 stores the number of rows left to check
    li $t5, $color
    li $v0, 0

    # for each row of the object
    check_row:
        beq $t7, $zero, end_check # if we have checkd all rows, end
        li $t8, $width # $t8 stores the number of columns left to check       
        move $t6, $t9 # $t6 stores the pointer to the current pixel

        check_col:
            beq $t8, $zero, end_check_col # if we have checked all columns, end
            # check the current pixel
            lw $t4, 0($t6)
            beq $t4, $t5, color_found # if the color matches, end
            # move to the next pixel
            addi $t6, $t6, 4 # move to the next pixel
            addi $t8, $t8, -1 # decrement the number of columns left to check
            j check_col # check the next column

        end_check_col:
            addi $t9, $t9, ROW_LEN # move to the next row
            addi $t7, $t7, -1 # decrement the number of rows left to check
            j check_row # check the next row

        color_found:
            li $v0, 1

    end_check:
.end_macro

.macro draw_star($start, $color)
    # set up location and colour
        move $a0, $start # $a0 stores the pointer to the star location
        move_offset($a0, -2, -4) # move to the correct location to start drawing
        li $t9, WHITE
        li $t8, $color

        # draw star
        sw $t9, 0($a0) # first row
        sw $t9, 4($a0)
        sw $t8, 8($a0)
        sw $t9, 12($a0)
        sw $t9, 16($a0)  

        addi $a0, $a0, ROW_LEN # second row
        sw $t9, 0($a0)
        sw $t8, 4($a0)
        sw $t8, 8($a0)
        sw $t8, 12($a0)
        sw $t9, 16($a0)

        addi $a0, $a0, ROW_LEN # third row
        sw $t8, 0($a0)
        sw $t8, 4($a0)
        sw $t8, 8($a0)
        sw $t8, 12($a0)
        sw $t8, 16($a0)

        addi $a0, $a0, ROW_LEN # fourth row
        sw $t9, 0($a0)
        sw $t8, 4($a0)
        sw $t8, 8($a0)
        sw $t8, 12($a0)
        sw $t9, 16($a0)

        addi $a0, $a0, ROW_LEN # fifth row
        sw $t9, 0($a0)
        sw $t8, 4($a0)
        sw $t9, 8($a0)
        sw $t8, 12($a0)
        sw $t9, 16($a0)
.end_macro

.macro draw_k($start)
    move $a0, $start # $a0 stores the pointer to the K location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 12($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 4($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 12($a0)
.end_macro

.macro draw_is($start)
    move $a0, $start # $a0 stores the pointer to the I location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

.end_macro

.macro draw_u($start)
    move $a0, $start # $a0 stores the pointer to the U location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 12($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 12($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 12($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 12($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)

.end_macro

.macro draw_0($start)
    move $a0, $start # $a0 stores the pointer to the 0 location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # sixth row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # seventh row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # eighth row
    sw $t9, 0($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # ninth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)
.end_macro

.macro draw_1($start)
    move $a0, $start # $a0 stores the pointer to the 1 location
    li $t9, BLACK

 # first row

    sw $t9, 8($a0)


    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 4($a0)
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 8($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 8($a0)


    addi $a0, $a0, ROW_LEN # sixth row
    sw $t9, 8($a0)


    addi $a0, $a0, ROW_LEN # seventh row
    sw $t9, 8($a0)


    addi $a0, $a0, ROW_LEN # eighth row
    sw $t9, 8($a0)


    addi $a0, $a0, ROW_LEN # ninth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

.end_macro

.macro draw_2($start)
    move $a0, $start # $a0 stores the pointer to the 2 location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # sixth row
    sw $t9, 0($a0)

    addi $a0, $a0, ROW_LEN # seventh row
    sw $t9, 0($a0)

    addi $a0, $a0, ROW_LEN # eighth row
    sw $t9, 0($a0)

    addi $a0, $a0, ROW_LEN # ninth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)
.end_macro

.macro draw_3($start)
    move $a0, $start # $a0 stores the pointer to the 3 location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # sixth row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # seventh row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # eighth row
    sw $t9, 16($a0)

    addi $a0, $a0, ROW_LEN # ninth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)
.end_macro

.macro draw_win($start)
    move $a0, $start # $a0 stores the pointer to the win location
    li $t9, BLACK

    sw $t9, 0($a0) # first row
    sw $t9, 16($a0)
    sw $t9, 28($a0)
    sw $t9, 40($a0)
    sw $t9, 44($a0)
    sw $t9, 48($a0)
    sw $t9, 52($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 8($a0)
    sw $t9, 16($a0)
    sw $t9, 40($a0)
    sw $t9, 52($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 8($a0)
    sw $t9, 16($a0)
    sw $t9, 28($a0)
    sw $t9, 40($a0)
    sw $t9, 40($a0)
    sw $t9, 52($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 8($a0)
    sw $t9, 16($a0)
    sw $t9, 28($a0)
    sw $t9, 40($a0)
    sw $t9, 40($a0)
    sw $t9, 52($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)
    sw $t9, 16($a0)
    sw $t9, 28($a0)
    sw $t9, 40($a0)
    sw $t9, 40($a0)
    sw $t9, 52($a0)

.end_macro

.macro draw_lose($start)
    move $a0, $start # $a0 stores the pointer to the lose location
    li $t9, BLACK

    # fill all the rows
    sw $t9, 0($a0)

    sw $t9, 16($a0)
    sw $t9, 20($a0)
    sw $t9, 24($a0)

    sw $t9, 32($a0)
    sw $t9, 36($a0)
    sw $t9, 40($a0)

    sw $t9, 48($a0)
    sw $t9, 52($a0)
    sw $t9, 56($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)

    sw $t9, 16($a0)
    sw $t9, 24($a0)

    sw $t9, 32($a0)
    
    sw $t9, 48($a0)


    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)

    sw $t9, 16($a0)
    sw $t9, 24($a0)

    sw $t9, 32($a0)
    sw $t9, 36($a0)
    sw $t9, 40($a0)

    sw $t9, 48($a0)
    sw $t9, 52($a0)
    sw $t9, 56($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)

    sw $t9, 16($a0)
    sw $t9, 24($a0)

    sw $t9, 40($a0)
    
    sw $t9, 48($a0)


    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)

    sw $t9, 16($a0)
    sw $t9, 20($a0)
    sw $t9, 24($a0)

    sw $t9, 32($a0)
    sw $t9, 36($a0)
    sw $t9, 40($a0)

    sw $t9, 48($a0)
    sw $t9, 52($a0)
    sw $t9, 56($a0)

.end_macro

.macro draw_play($start)
    move $a0, $start # $a0 stores the pointer to the play location
    li $t9, BLACK


    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)

    sw $t9, 16($a0)


    sw $t9, 32($a0)

    sw $t9, 52($a0)
    sw $t9, 60($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    sw $t9, 16($a0)

    sw $t9, 32($a0)
    sw $t9, 36($a0)

    sw $t9, 52($a0)
    sw $t9, 56($a0)
    sw $t9, 60($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)

    sw $t9, 16($a0)

    sw $t9, 32($a0)
    sw $t9, 40($a0)

    sw $t9, 56($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)

    sw $t9, 16($a0)

    sw $t9, 32($a0)
    sw $t9, 36($a0)
    sw $t9, 40($a0)
    sw $t9, 44($a0)

    sw $t9, 56($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)

    sw $t9, 16($a0)
    sw $t9, 20($a0)
    sw $t9, 24($a0)

    sw $t9, 32($a0)
    sw $t9, 44($a0)

    sw $t9, 56($a0)

.end_macro

.macro draw_quit($start)
    move $a0, $start # $a0 stores the pointer to the quit location
    li $t9, BLACK

    # fill all the rows
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)

    sw $t9, 20($a0)
    sw $t9, 28($a0)

    sw $t9, 36($a0)

    sw $t9, 44($a0)
    sw $t9, 48($a0)
    sw $t9, 52($a0)

    addi $a0, $a0, ROW_LEN # second row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    sw $t9, 20($a0)
    sw $t9, 28($a0)

    sw $t9, 36($a0)

    sw $t9, 48($a0)

    addi $a0, $a0, ROW_LEN # third row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    sw $t9, 20($a0)
    sw $t9, 28($a0)

    sw $t9, 36($a0)

    sw $t9, 48($a0)

    addi $a0, $a0, ROW_LEN # fourth row
    sw $t9, 0($a0)
    sw $t9, 8($a0)

    sw $t9, 20($a0)
    sw $t9, 28($a0)

    sw $t9, 36($a0)

    sw $t9, 48($a0)

    addi $a0, $a0, ROW_LEN # fifth row
    sw $t9, 0($a0)
    sw $t9, 4($a0)
    sw $t9, 8($a0)
    sw $t9, 12($a0)

    sw $t9, 20($a0)
    sw $t9, 24($a0)
    sw $t9, 28($a0)

    sw $t9, 36($a0)

    sw $t9, 48($a0)

.end_macro

.macro play_cursor
    # draw play cursor
        li $t0, BASE_ADDRESS
        move_offset($t0, 50, 45)
        li $t1, BLACK

        sw $t1, 0($t0)
        sw $t1, 16($t0)

        addi $t0, $t0, ROW_LEN
        sw $t1, 4($t0)
        sw $t1, 12($t0)

        addi $t0, $t0, ROW_LEN
        sw $t1, 8($t0)

        # clear quit cursor
        li $t0, BASE_ADDRESS
        move_offset($t0, 75, 45)
        erase($t0, 5, 3, WHITE)
.end_macro

.macro quit_cursor
    # draw quit cursor
        li $t0, BASE_ADDRESS
        move_offset($t0, 75, 45)
        li $t1, BLACK

        sw $t1, 0($t0)
        sw $t1, 16($t0)

        addi $t0, $t0, ROW_LEN
        sw $t1, 4($t0)
        sw $t1, 12($t0)

        addi $t0, $t0, ROW_LEN
        sw $t1, 8($t0)

        # clear play cursor
        li $t0, BASE_ADDRESS
        move_offset($t0, 50, 45)
        erase($t0, 5, 3, WHITE)
.end_macro




    







#------------------------------------------------------------
# global variables
# $s0: kirby location
# $s1: old kirby location
# $s2: on platform (0 as in the air, 1 as on platform, 2 as on ceiling)
# $s3: vertical velocity 
# $s4: remaining jump ability
# $s5: score
# $s6: star location
# $s7: old star location
# star[0-3]: clone enabled
# star[4-7]: star on platform
# star[8-11]: star vertical velocity
#------------------------------------------------------------


.globl main
main:
    main_menu_init:
        li $a0, BASE_ADDRESS
        erase($a0, 128, 64, WHITE)
        # draw kk is u
        li $t0, BASE_ADDRESS
        move_offset($t0, 50, 20)
        draw_k($t0)

        move_offset($t0, 5, 0)
        draw_k($t0)

        move_offset($t0, 7, 0)
        draw_is($t0)

        move_offset($t0, 8, 0)
        draw_u($t0)

        # draw play
        li $t0, BASE_ADDRESS
        move_offset($t0, 45, 50)
        draw_play($t0)

        # draw quit
        li $t0, BASE_ADDRESS
        move_offset($t0, 70, 50)
        draw_quit($t0)

        # draw play cursor
        play_cursor

    menu_loop:
        jal menu_control
        sleep
        j menu_loop


    main_start:
        # initialize kirby related variables
        li $t0, KIRBY_LOC_OFFSET
        addi $t0, $t0, BASE_ADDRESS
        move $s0, $t0
        move $s1, $t0
        li $s4, JUMP
        li $s5, 0

        # initialize star related variables
        li $t0, STAR_LOC_OFFSET
        addi $t0, $t0, BASE_ADDRESS
        move $s6, $t0
        move $s7, $t0
        la $t0, star
        li $t1, 0
        li $t2, 0
        li $t3, 0
        sw $t1, 0($t0) # clone not enabled
        sw $t2, 4($t0) # star not on platform
        sw $t3, 8($t0) # star vertical velocity 0


        # initialize display
        li $a0, BASE_ADDRESS
        erase($a0, 128, 64, WHITE)

        # add boundary wall left
        li $t0, BASE_ADDRESS
        move_offset($t0, 0, 12)
        erase($t0, 1, 52, BLACK)

        # add boundary wall left ceiling
        erase($t0, 44, 1, BLACK)

        # close off star cage
        move_offset($t0, 44, -12)
        erase($t0, 1, 13, BLACK)

        # draw is right beside star
        li $t0, BASE_ADDRESS
        move_offset($t0, 18, 3)
        draw_is($t0)

        # draw win
        move_offset($t0, 10, 0)
        draw_win($t0)

        # add floor
        li $t0, BASE_ADDRESS
        move_offset($t0, 0, 63)
        erase($t0, 41, 1, BLACK)

        # add wall
        move_offset($t0, 40, -12)
        erase($t0, 1, 12, BLACK)

        # add ceiling
        move_offset($t0, -20, 0)
        erase($t0, 20, 1, BLACK)

        # add platform 1
        move_offset($t0, 34, -12)
        erase($t0, 18, 1, BLACK)

        # add platform 2
        move_offset($t0, 26, -18)
        erase($t0, 8, 1, BLACK)

        # draw star 1 on platform 2
        li $t0, BASE_ADDRESS
        move_offset($t0, 84, 20)
        draw_star($t0, YELLOW1)

        # add platform 3
        move_offset($t0, 0, 23)
        erase($t0, 16, 1, BLACK)

        # draw star 2 on platform 3
        li $t0, BASE_ADDRESS
        move_offset($t0, 92, 42)
        draw_star($t0, YELLOW2)

        # draw kk is u
        li $t0, BASE_ADDRESS
        move_offset($t0, 102, 58)
        draw_k($t0)

        move_offset($t0, 5, 0)
        draw_k($t0)

        move_offset($t0, 7, 0)
        draw_is($t0)

        move_offset($t0, 8, 0)
        draw_u($t0)

        # draw is
        move_offset($t0, 0, -7)
        draw_is($t0)

        # draw star cage
        jal draw_star_cage
        


        




    # start main game loop
    main_loop:
        # update old player location
        move $s1, $s0
        move $s7, $s6

        # check if player character is standing on a platform
        # if so, allow jumping and prevent falling
        # if not, allow falling
        jal check_platform

        # check for keyboard input, update game state accordingly
        jal check_keypress

        # update player, platforms, power ups, etc.
        jal update

        # check for collisions (e.g., between player and enemies)
        # if a collision occurs, update game state accordingly
        jal check_collision

        

        # check if the game is over (e.g., player has reached void or collected all stars)
        # if so, exit loop
        jal check_game_over

        # erase objects from old position on the screen
        # (this is done by drawing the background colour over the old position)
        
        jal clear

        # redraw objects in new position on the screen
        jal draw

        

        # delay for a short period of time to control game speed
        sleep

        # jump back to the beginning of the loop
        j main_loop
    
    win_game:
        li $t0, BASE_ADDRESS
        erase($t0, 128, 64, GREEN)
        li $a3, 1 # set win to 1
        jal print_score
        j end_loop

    lose_game:
        li $t0, BASE_ADDRESS
        erase($t0, 128, 64, RED)
        li $a3, 0 # set win to 0
        jal print_score
        j end_loop


    end_loop:
        jal check_keypress
        sleep
        j end_loop
    # display end of game screen
    # allow player to restart or quit game

#------------------------------------------------------------
# high-level helper functions
#------------------------------------------------------------
menu_control:
    li $a0, KEY_ADDR
    lw $t0, 0($a0)
    bne $t0, 1, end_menu_control
    lw	$t0, 4($a0)
    beq	$t0, 0x77, select
    beq	$t0, 0x61, select_play
    beq	$t0, 0x64, select_quit
    j end_menu_control

    select:
        beq $s0, 0, main_start
        # quit the program
        li $v0, 10
        syscall

    select_play:
        li $s0, 0
        play_cursor
        j end_menu_control
        
    select_quit:
        li $s0, 1
        quit_cursor
        j end_menu_control
       
    end_menu_control:
        jr $ra


check_keypress:
    li $a0, KEY_ADDR
    lw $t0, 0($a0)
    bne $t0, 1, end_keypress
    lw	$t0, 4($a0)

    la $t4, star
    lw $t1, 0($t4) # clone enabled
    lw $t2, 4($t4) # star on platform
    lw $t3, 8($t4) # star vertical velocity

    # print $t1 below
    # print_int($t1)


    beq	$t0, 0x77, onW
    beq	$t0, 0x73, onS
    beq	$t0, 0x61, onA
    beq	$t0, 0x64, onD
    beq	$t0, 0x70, onP
    j end_keypress

    onW:
        # check if player has remaining jump ability
        beq	$s4, 0, end_keypress    # if $s4 is 0, don't jump
        addi	$s4, $s4, -1				# else, decrement $s4
        addi	$s3, $s3, K_JUMP_HEIGHT				# increment $s3 by jump height
        beq $t1, 0, end_keypress # if clone not enabled, end
        # if clone enabled, jump clone
        addi $t3, $t3, S_JUMP_HEIGHT # increment clone vertical velocity by jump height
        sw $t3, 8($t4) # store clone vertical velocity
        j end_keypress

    onS:
        # debug key
        li $t1, 1
        sw $t1, 0($t4) # clone enabled
        j end_keypress

    # go left
    onA:
        k_onA:
            move $t0, $s0
            move_offset($t0, -5, -8) # $t0 stores the pointer to the column to the left of the player
            check_color($t0, 1, 9, BLACK) # check if the column to the left of the player has platform color
            beq $v0, 1, s_onA # if the column to the left of the player has platform color, don't go left
            addi	$s0, $s0, -4    # else, move left
            j s_onA
        s_onA:
            beq $t1, 0, end_keypress # if clone not enabled, end
            move $t0, $s6
            move_offset($t0, -3, -4) # $t0 stores the pointer to the column to the left of the star
            check_color($t0, 1, 5, BLACK) # check if the column to the left of the star has platform color
            beq $v0, 1, end_keypress # if the column to the left of the star has platform color, don't go left
            addi	$s6, $s6, -4    # else, move left
            j end_keypress



    # go right
    onD:
        k_onD:
            move $t0, $s0
            move_offset($t0, 5, -8) # $t0 stores the pointer to the column to the right of the player
            check_color($t0, 1, 9, BLACK) # check if the column to the right of the player has platform color
            beq $v0, 1, s_onD # if the column to the right of the player has platform color, don't go right
            addi	$s0, $s0, 4    # else, move right
            j s_onD
        s_onD:
            beq $t1, 0, end_keypress # if clone not enabled, end
            move $t0, $s6
            move_offset($t0, 3, -4) # $t0 stores the pointer to the column to the right of the star
            check_color($t0, 1, 5, BLACK) # check if the column to the right of the star has platform color
            beq $v0, 1, end_keypress # if the column to the right of the star has platform color, don't go right
            addi	$s6, $s6, 4    # else, move right
            j end_keypress
    



    onP:
        # restart game
        j main_start

    end_keypress:
        jr $ra



        
check_platform:
    k_check:
        move $t0, $s0 # $t0 stores the pointer to the player location
        move_offset($t0, -4, 1) # move the pointer to the row below the player

        # check if the player is on a platform
        check_color($t0, 9, 1, BLACK) # check if the row below the player is black
        beq $v0, 1, k_on_platform

        # check if the player is on a ceiling
        move $t0, $s0 # $t0 stores the pointer to the player location
        move_offset($t0, -4, -9) # move the pointer to the row above the player
        check_color($t0, 9, 1, BLACK) # check if the row above the player is black
        beq $v0, 1, k_on_ceiling

        k_in_air:
            li $s2, 0 # set $s2 to 0 to indicate the player is in the air
            j end_k_check

        k_on_platform:
            li $s2, 1 # set $s2 to 1 to indicate the player is on a platform
            li $s4, JUMP # reset $s4 to 2 to indicate the player has full jump ability
            j end_k_check

        k_on_ceiling:
            li $s2, 2 # set $s2 to 2 to indicate the player is on ceiling
            j end_k_check
    
        end_k_check:
            la $t0, star # load the address of the star related variables into $t0
            lw $t1, 0($t0) # $t1 stores clone enable
            
    
    s_check:
        beq $t1, 0, end_check_platform # if clone is not enabled, don't check star
        move $t1, $s6 # $t1 stores the pointer to the star location
        move_offset($t1, -2, 1) # move the pointer to the row below the star

        # check if the star is on a platform
        check_color($t1, 5, 1, BLACK) # check if the row below the star is black
        beq $v0, 1, s_on_platform

        # check if the star is on a ceiling
        move $t1, $s6 # $t1 stores the pointer to the star location
        move_offset($t1, -2, -5) # move the pointer to the row above the star
        check_color($t1, 5, 1, BLACK) # check if the row above the star is black
        beq $v0, 1, s_on_ceiling

        s_in_air:
            li $t2, 0 # set $t2 to 0
            sw $t2, 4($t0) # store $t2 into the star on platform variable
            j end_check_platform

        s_on_platform:
            li $t2, 1 # set $t2 to 1
            sw $t2, 4($t0) # store $t2 into the star on platform variable
            j end_check_platform

        s_on_ceiling:
            li $t2, 2 # set $t2 to 2
            sw $t2, 4($t0) # store $t2 into the star on platform variable
            j end_check_platform

    end_check_platform:
        jr $ra

update:
    # $s0 stores kirby's location
    # $s2 stores whether kirby is on a platform
    # $s3 stores players's vertical velocity
    # $s6 stores star's location
    # star[0-3] stores clone enable
    # star[4-7] stores star on platform
    # star[8-11] stores star vertical velocity

    k_update:

        # print_int($s3) # print the player's vertical velocity

        # if kirby is on ceiling, vertical velocity is 0
        li $t1, 2 # $t1 stores 2
        beq $s2, $t1, k_update_ceiling
        # if kirby has vertical velocity, move it up
        bgt $s3, $zero, k_move_up
        
        # if the player is in the air and velocity 0, move the player down
        beq $s2, $zero, k_move_down
        # if the player is on a platform and velocity 0, don't move the player down
        j end_k_update

        k_update_ceiling:
            li $s3, 0 # set the player's vertical velocity to 0
            addi $s0, $s0, ROW_LEN # move the player down
            j end_k_update

        k_move_up:
            addi $s3, $s3, -1 # decrement the player's vertical velocity
            li $t1, 2 # $t1 stores 2
            beq $s2, $t1, end_k_update # if the player is on a ceiling, don't move the player up
            
            addi $s0, $s0, -ROW_LEN # move the player up
            
            j end_k_update

        

        k_move_down:
            # move kirby down
            addi $s0, $s0, ROW_LEN # move the player down
            j end_k_update

        end_k_update:
            # check if clone is enabled
            la $t0, star # load the address of the star related variables into $t0
            lw $t1, 0($t0) # $t1 stores clone enable
            

    s_update:
        beq $t1, 0, end_update # if clone is not enabled, don't update star
        lw $t2, 4($t0) # $t2 stores star on platform
        lw $t3, 8($t0) # $t3 stores star vertical velocity

        # if star is on ceiling, vertical velocity is 0
        li $t4, 2 # $t4 stores 2
        beq $t2, $t4, s_update_ceiling
        # if star has vertical velocity, move it up
        bgt $t3, $zero, s_move_up
        # if the star is in the air, move the star down
        beq $t2, $zero, s_move_down
        # if the star is on a platform and velocity 0, don't move the star down
        j end_s_update

        s_update_ceiling:
            li $t3, 0 # set the star's vertical velocity to 0
            addi $s6, $s6, ROW_LEN # move the star down
            j end_s_update


        s_move_up:
            addi $t3, $t3, -1 # decrement the star's vertical velocity
            sw $t3, 8($t0) # store $t3 into the star vertical velocity variable
            li $t4, 2 # $t1 stores 2
            beq $t2, $t4, end_s_update # if the star is on a ceiling, don't move the star up
            
            addi $s6, $s6, -ROW_LEN # move the star up
            
            j end_s_update

        s_move_down:
            # move star down
            addi $s6, $s6, ROW_LEN # move the star down
            j end_s_update

        end_s_update:
            j end_update

    end_update:
        jr $ra

check_game_over:
    # check if the player has collected all stars
    li $t0, 3
    beq $s5, $t0, win_game # if the player has collected all stars, end the game
    # check if the player is about to go off the screen
    move $t0, $s1 # $t0 stores the pointer to the player location
    addi $t0, $t0, ROW_LEN # move the pointer to the row below the player



    li $t1, BOUNDARY # $t1 stores the base address of the screen
    bgt $t0, $t1, lose_game # if the player is about to go off the screen, end the game
    jr $ra # else, continue the game

clear:
    k_clear:
        move $t0, $s1
        move_offset($t0, -4, -8) # prepare player location for erasing
        erase($t0, 9, 9, WHITE)
        la $t4, star
        lw $t1, 0($t4) # $t1 stores clone enabled
        

    s_clear:
        beq $t1, $zero, end_clear # if clone is not enabled, don't erase the clone
        move $t0, $s7
        move_offset($t0, -2, -4) # prepare star location for erasing
        erase($t0, 5, 5, WHITE)
        j end_clear


    end_clear:
        jr $ra


check_collision:
    # check star collision
    move $t0, $s0 # $t0 stores the pointer to the player location
    move_offset($t0, -5, -9) # move the pointer to the top left corner of the player
    check_color($t0, 10, 10, YELLOW) # check if the player is touching a yellow pixel
    beq $v0, 1, star0 # if the player is touching a yellow pixel, add score and win the game

    # check star1 collision
    check_color($t0, 10, 10, YELLOW1) # check if the player is touching a yellow1 pixel
    beq $v0, 1, star1 # if the player is touching a yellow1 pixel, clean star1 and add score

    # check star2 collision
    check_color($t0, 10, 10, YELLOW2) # check if the player is touching a yellow2 pixel
    beq $v0, 1, star2 # if the player is touching a yellow2 pixel, clean star2 and add score

    # check box collision
    check_color($t0, 10, 10, GRAY) # check if the player is touching a gray pixel
    beq $v0, 1, box # if the player is touching a gray pixel, clean box and enable clone

    j end_collision

    star0:
        addi $s5, $s5, 1
        j win_game

    star1:
        li $t0, BASE_ADDRESS
        move_offset($t0, 84, 20)
        move_offset($t0, -2, -4)
        erase($t0, 5, 5, WHITE)
        addi $s5, $s5, 1
        j end_collision

    star2:
        li $t0, BASE_ADDRESS
        move_offset($t0, 92, 42)
        move_offset($t0, -2, -4)
        erase($t0, 5, 5, WHITE)
        addi $s5, $s5, 1
        j end_collision
    box:
        la $t0, tempra
        sw $ra, 0($t0)

        jal clean_star_cage
        jal draw_solid_star_cage
        la $t0, star
        li $t1, 1
        sw $t1, 0($t0)

        la $t0, tempra
        lw $ra, 0($t0)
        j end_collision

    end_collision:
        jr $ra

    


draw:
    draw_kirby:
        # set up location and colour
        move $a0, $s0 # $a0 stores the pointer to the player location
        move_offset($a0, -4, -8) # move to the correct location to start drawing
        li $t0, WHITE
        li $t1, PINK
        li $t2, BLUE
        li $t3, BRIGHT_PINK
        li $t4, RED

        # draw player
        sw $t0, 0($a0) # first row
        sw $t0, 4($a0)
        sw $t0, 8($a0)
        sw $t0, 12($a0)
        sw $t0, 16($a0)
        sw $t0, 20($a0)
        sw $t0, 24($a0)
        sw $t0, 28($a0)
        sw $t0, 32($a0)  

        addi $a0, $a0, ROW_LEN # second row
        sw $t0, 0($a0) 
        sw $t0, 4($a0)
        sw $t1, 8($a0)
        sw $t1, 12($a0)
        sw $t1, 16($a0)
        sw $t1, 20($a0)
        sw $t1, 24($a0)
        sw $t0, 28($a0)
        sw $t0, 32($a0)  

        addi $a0, $a0, ROW_LEN # third row
        sw $t0, 0($a0)
        sw $t1, 4($a0)
        sw $t1, 8($a0)
        sw $t2, 12($a0)
        sw $t1, 16($a0)
        sw $t2, 20($a0)
        sw $t1, 24($a0)
        sw $t1, 28($a0)
        sw $t0, 32($a0)  

        addi $a0, $a0, ROW_LEN  # fourth row
        sw $t1, 0($a0)
        sw $t1, 4($a0)
        sw $t1, 8($a0)
        sw $t2, 12($a0)
        sw $t1, 16($a0)
        sw $t2, 20($a0)
        sw $t1, 24($a0)
        sw $t1, 28($a0)
        sw $t1, 32($a0)

        addi $a0, $a0, ROW_LEN # fifth row
        sw $t1, 0($a0)
        sw $t1, 4($a0)
        sw $t3, 8($a0)
        sw $t1, 12($a0)
        sw $t1, 16($a0)
        sw $t1, 20($a0)
        sw $t3, 24($a0)
        sw $t1, 28($a0)
        sw $t1, 32($a0)

        addi $a0, $a0, ROW_LEN # sixth row
        sw $t1, 0($a0)
        sw $t1, 4($a0)
        sw $t1, 8($a0)
        sw $t1, 12($a0)
        sw $t1, 16($a0)
        sw $t1, 20($a0)
        sw $t1, 24($a0)
        sw $t1, 28($a0)
        sw $t1, 32($a0)

        addi $a0, $a0, ROW_LEN # seventh row
        sw $t0, 0($a0)
        sw $t1, 4($a0)
        sw $t1, 8($a0)
        sw $t1, 12($a0)
        sw $t1, 16($a0)
        sw $t1, 20($a0)
        sw $t1, 24($a0)
        sw $t1, 28($a0)
        sw $t0, 32($a0)  

        addi $a0, $a0, ROW_LEN # eighth row
        sw $t0, 0($a0)
        sw $t0, 4($a0)
        sw $t1, 8($a0)
        sw $t1, 12($a0)
        sw $t1, 16($a0)
        sw $t1, 20($a0)
        sw $t1, 24($a0)
        sw $t0, 28($a0)
        sw $t0, 32($a0)   

        addi $a0, $a0, ROW_LEN # ninth row
        sw $t0, 0($a0)
        sw $t4, 4($a0)
        sw $t4, 8($a0)
        sw $t4, 12($a0)
        sw $t0, 16($a0)
        sw $t4, 20($a0)
        sw $t4, 24($a0)
        sw $t4, 28($a0)
        sw $t0, 32($a0)

    # draw the star character
    draw_star($s6, YELLOW)

jr $ra

draw_star_cage:
    li $t0, BASE_ADDRESS
    move_offset($t0, 121, 35)
    erase($t0, 7, 7, GRAY)
    move_offset($t0, 3, 5)
    draw_star($t0, YELLOW)
    jr $ra

clean_star_cage:
    li $t0, BASE_ADDRESS
    move_offset($t0, 121, 35)
    erase($t0, 7, 7, WHITE)
    jr $ra

draw_solid_star_cage:
    li $t0, BASE_ADDRESS
    move_offset($t0, 121, 41)
    erase($t0, 7, 7, BLACK)
    move_offset($t0, 3, 5)
    draw_star($t0, YELLOW)
    jr $ra

print_score:
    li $t0, BASE_ADDRESS
    move_offset($t0, 50, 35)
    erase($t0, 20, 25, WHITE)
    move_offset($t0, 5, 3)
    beq $s5, 0, print_0
    beq $s5, 1, print_1
    beq $s5, 2, print_2
    beq $s5, 3, print_3

    print_0:
        draw_0($t0)
        j print_star

    print_1:
        draw_1($t0)
        j print_star

    print_2:
        draw_2($t0)
        j print_star
    
    print_3:
        draw_3($t0)
        j print_star
    
    print_star:
        move_offset($t0, 8, 5)
        draw_star($t0, YELLOW)
        j print_result

    print_result:
        move_offset($t0, -10, 10)
        beq $a3, 0, print_lose
        beq $a3, 1, print_win

        print_lose: 
            draw_lose($t0)
            j print_end

        print_win:
            draw_win($t0)
            j print_end
        
        print_end:
            jr $ra



