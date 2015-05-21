# Unit_Converter.s - a program for unit conversion.
# Detailed description:
# Has 3 options to convert user input in Meters into Feet and Inches (Imperial), Kilograms into Pounds and Ounces (Imperial), and Liters into Pints (Imperial).
# Upon initialization presents user with a choice of units he/she desires to convert allowing to select one of them as an option.
# It then asks for number of values user would like to convert and the values themselves. It then prints out the converted values.
# When more than 1 values has been input, the total and average statistics regarding both origianl and converted values is printed out.
# User is then presented with an option to either convert more numbers using the same conversion methods, different conversion methods, or quit the application.
#
# Registers used:
# $t1 - holds number of numbers to expect from user
# $t0 - used by loops to count by incrementing its value by 4 with each loop cycle. Counts bytes, instead of words. Also, used as adress value to access an element in an array.
# $t2 - stores an integer of user input, before moving it to the array
# $t3 - Total sum of numbers in an array
# $t4 - keeps an integer value of Pounds or Feet for conversions consisting of 2 parts (e.g. Pounds & Ounces, Feet & Inches)
# $t5 - keeps user's conversion choice made in the intro menu. Stays in $t5 throughout the program, until another choice is made.
# $t6 - a trigger that keeps a value of 0, 1 or 2, depending on the stage of algorithm.
#     Allows to achieve great efficiency by utilizing same code under different scenarios depending on the stage of the algorithm.
#     When user's input is being converted, keeps a value of 0 and code operates as expected.
#     However, when calculating & printing stats, takes value of 1 or 2 and allows to jump back and utilize
#     parts of existing code (conversion algorithm), convert certain values and then jump back to parts of code
#     where those values are needed. Parts of code it returns converted values to depend on the value stored in $t6.
# $f0 = primarily used to load in 1st conversion constant (Pounds, Feet, Pints). When not needed for that, is used to store some intermediate floating values.
# $f1 = Stores total sum value of converted inputs; later in the algorithm holds mean value.
# $f2 - intially store a 2nd conversion constant (Inches or Ounces) for conversions consisting of 2 parts (e.g. Pounds & Ounces, Feet & Inches)



.data
# All the strings accessed throughout the program are stored here. Also, an array that is used to store user input is initialized here specifiying number of bytes allocated in the memory for it.

  strChoice0: .asciiz "\nWhich unit conversion would you like me to do?\n
     1    Convert Metres (SI) to Feet and Inches (Imperial)
     2    Convert Kilograms (SI) to Pounds and Ounces (Imperial)
     3    Convert Litres (SI) to Pints (Imperial)
     4    Quit\n
Please, enter the number corresponding to the option next to it:  "
  strErr0:  .asciiz "There is no such option. Enter the number corresponding to the option next to it:  "
  str1:   .asciiz "\nHow many numbers would you like to convert? Enter an integer between 1 and 5:  "
  str2:   .asciiz "\nPlease enter an integer you would like to convert:  "
  newline:  .asciiz "\n"
  strTo:    .asciiz "\nTotal sum of original input values is:  "
  strTc:    .asciiz "\nTotal sum of converted values is:  "
  strMo:    .asciiz "\nThe mean of original input values is:  "
  strMc:    .asciiz "\nThe mean of converted values is:  "
  strErr:   .asciiz "Sorry, you can't enter more than 5 integers. Please choose a smaller amount:  "
  strErr1:  .asciiz "\nSorry, the value you've entered is not valid. Please enter an integer you would like to convert:  "
  strChoice:  .asciiz "\nYour input has been converted! What would you like to do now?\n
    1    Convert more numbers using the same conversion
    2    Convert more numbers using other conversion methods
    3    Quit\n
Please, enter the number corresponding to the option next to it:  "
  strHeader:  .asciiz "\n============== Your Output: ================ \n"
  strBreak: .asciiz "\n======================================= \n"

  strLength0:   .asciiz " Meter(s) convert(s) into "
  strLength1:   .asciiz " Feet and "
  strLength2:   .asciiz " Inches"

  strWeight0:   .asciiz " Kilogram(s) convert(s) into "
  strWeight1:   .asciiz " Pounds and "
  strWeight2:   .asciiz " Ounces"

  strVolume0:   .asciiz " Litre(s) convert(s) into "
  strVolume1:   .asciiz " Pints"

  strMeters:  .asciiz " Meters"
  strKilos: .asciiz " Kilograms"
  strLitres:  .asciiz " Litres"

  .align 2    # align to multiple of 2^2 bytes to make sure other variables start at proper addresses

  theArray:   # user's input will be stored in this array named theArray. This allows to record all users' input in one go into the memory, and later access individual elements in the array on demand. Efficiency is greatly achieved, since temporary registers, which are easily overwritable, are not filled with sensitive information (user input).
  .space 1000   # this line specifies amount in bytes allocated in the memory for use by the array


.text

main:
  li $t6, 0       # set trigger value to 0. For explanation of trigger refer to $t6 description in header

  #######################################
  #############    Menu     #############
  #######################################


  li $v0, 4       # Print out menu String
  la $a0, strChoice0
  syscall

  choose:
  # get a choice input from user, store in $t5. To be remembered throughout. Do not overwrite
    li $v0, 5
    syscall
    move $t5, $v0

  # Exit if choose to do so. Jumps to exit command if users inputs 4.
  beq $t5, 4, quit

  # if user has input a random character or choice value of 0 or more than 4 , print error message, then jump and wait for user input again
  # if user's choice is within the range (less than 4), go to prompt and ask for numbers to convert
    beq $t5, 0, error
    ble $t5, 4, prompt
      error:
      li $v0, 4
      la $a0, strErr0
      syscall
      j choose



  #######################################
  ######### PROMPT FOR AMOUNT ###########
  #######################################
  prompt:
  li $t6, 0         # set trigger value to 0, so when same conversion option is used again, stats are displayed. For explanation of trigger refer to $t6 description in header.

  # prompt user for an integer, i.e. how many values the user wants to convert. The integer will be used by the loop in the next section to prompt that many times for values to convert.
    li $v0, 4
    la $a0, str1
    syscall

  # read user's input on how many values he'd like to convert and store it in $t1
  read:
    li $v0, 5
    syscall
    move $t1, $v0     # store user input in $t1

    mul $t1, $t1, 4     # multiply the integer representing expected number of user inputs by 4, to represent it in bytes.
                # this allow us later to be more efficient and use variable $t0, which is used to access values in the array by holding an integer representing their byte address in the array, to compare it against $t1 and see if all the user inputs have been converted and it's time to exit the loop while2. For the same purpose it is used in loop while1.


  li $t0, 0         # set value $t0 to 0. Will be incremented by 4 with each while1 and while2 loop cycle, until equals to $t1. Then exit the loop.

  # if user wants to convert more than 5 numbers, as specified by CA, print error message and ask for a smaller integer. Then jump to read input again
    beq $t1, 0, error1
    ble $t1, 20, while1   # we say more than 20 not 5, since $t1 counts number of bytes, not integers (5x4=20)
      error1:
      li $v0, 4
      la $a0, strErr
      syscall
      j read






  #######################################
  ###### ASK USER'S INPUT N-times #######
  #######################################

  # ask user for values to convert number of times stored in $t1
  # the loop will repeat until value stored in $t0 equals to value stored in $t1

  while1:
    beq $t0, $t1, endwhile      # jump to endwhile (exit the loop), when condition is met

      # prompt for an input, print str2
        li $v0, 4
        la $a0, str2
        syscall

      # get an input from user, store in $t2
        get:
        li $v0, 5
        syscall
        move $t2, $v0

  # if user has input a random character, print error message, then jump and wait for user input again
      bgtz $t2, store       # if user inputs a positive number, jump to label store and store it as input in theArray
        li $v0, 4       # else (e.g. inputs a character) print an error message, jump to get and wait for a valid input
        la $a0, strErr1
        syscall
        j get

      store:
      # store user's input from $t2 in an array address $t0, since with each loop value in $t0 is incremented by 4, every following input will be stored in a different address
        sw $t2, theArray($t0)


      # increment value in $t0 by 4, so that the loop can stop when $t0 = $t1
      # since $t0 is also used as the address in theArray where user's input is stored, incrementing it by 4 alows to reserve 4 bytes in the array for each value input by the user
      addi $t0, $t0, 4

    j while1            # repeat the loop, jump back to while1






  endwhile:



  li $v0, 4             # print out berak line
  la $a0, strHeader
  syscall

  li $v0, 4             # print a new line
  la $a0, newline
  syscall

  #######################################
  ########## CONVERT AND PRINT ##########
  ########### LITERS TO PINTS ###########
  #######################################

  li $t0, 0             # set value in $t0 to 0. Will be incremented by 4 with each while1 and while2 loop cycle, until equals to $t1. Then exit the loop.
  li $t3, 0             # $t3 will hold the sum of all elements in array theArray. Set to 0, so that when user wants to convert more numbers, old value of $t3 is zeroed-out


  # loop while2 operates on each element in theArray converting it into units chosen by user (stored in $t5) and prints out original and converted value
  # the loop will repeat until value stored in $t0 equals to value stored in $t1

  while2: # repeat n-times
    beq $t0, $t1, stats

      lw $t2, theArray($t0) # load an ellement indexed $t0, from the array

      # depending on choice made by user earlier, jumps to appropriate labels where conversion constants are loaded in $f0 and $f2
      junction:
      beq $t5, 1, length
      beq $t5, 2, weight
      beq $t5, 3, volume


      length:
      li.s $f0, 3.2808399     # load in conversion constant 1 (Feet in 1 Meter)
      li.s $f2, 12.0        # load in conversion constant 2 (Inches in 1 Feet)
      j convert         # initialize conversion algorithm by jumping to label convert

      weight:
      li.s $f0, 2.2046226     # load in conversion constant 1 (Pounds in 1 Kilo)
      li.s $f2, 16.0        # load in conversion constant 2 (Ounces in 1 Pound)
      j convert         # initialize conversion algorithm by jumping to label convert

      volume:
      li.s $f0, 1.75975     # load in conversion constant 1 (Pints in 1 Liter)


      # under label convert, user input is converted into units specified by user using constants assigned above
      # Upon completion, values converted into Pounds/Feet are stored as integers in $t4; Pints/Inches/Ounces are stored as floats in $f1

      convert:

        mtc1 $t2, $f1     # convert user integer input to single-precision float in $f1
        cvt.s.w $f1, $f1    # convert user integer input to single-precision float in $f1

        mul.s $f1, $f1, $f0   # $f1 x $f0 = Pounds in Kilos. Store in $f1



        # If volume is being converterd, there's only 1 conversion constant and the following computations are not necessary, jump straight to printing algorithm
        beq $t5, 3, print

        #  This part of code is executed for conversions composed of 2 parts Pounds/Ounces & Feet/Inch
        #  It takes the remained from Pounds or Feet and converts it into Ounces or Inches, as specified by user
        # In the end you get an integer value of Pounds & Feet stored in $t4, and the Feet/Inch bit stored as a float in $f1

        cvt.w.s $f0, $f1    # convert floating Pounds / Feet to integer
        mfc1 $t4, $f0     # store converted integer in $t4
        mtc1 $t4, $f0     # convert integer in $t4 to a single-precision float in $f0
        cvt.s.w $f0, $f0    # convert integer in $t4 to a single-precision float in $f0

        sub.s $f0, $f1, $f0   # Substract from converted float value of Pounds/Feet its rounded to the integer version. Get a float remainder, to convert into Inches/Ounces
        mul.s $f1, $f2, $f0   # Convert the remainder into Ounces/Inches by multiplying it by conversion constant stored in $f2

        # if trigger value is set to 1 (we are converting Total Array sum), jump straight to printJunction label
        beq $t6, 1, printJunction


      #######################################
      #############    PRINT     ############
      #######################################

          #  under this label the computed and original values are being printed to the user
          print:

          # in case we are printing the converted Total value of Pints, jump to label printVolume
          beq $t6, 1, printVolume


          # Print original user input value
          li $v0, 1
          move $a0, $t2
          syscall


          # depending on the conversion method user has specified at the beggining, jump to print the appropriate information
          printJunction:
          beq $t5, 1, printLength
          beq $t5, 2, printWeight
          beq $t5, 3, printVolume


          # if converting Length, print length-specific strings (strLength0, strLength1, strLength2) and converted values in Feet and Inches
          printLength:
            beq $t6, 1, Length    # in case we are printing the converted Total value of Feet and Inches, jump to label Length
            beq $t6, 2, Length1   # in case we are printing the Mean of converted values of Feet and Inches, jump to label Length1

            li $v0, 4       # Print strLength0
            la $a0, strLength0
            syscall

            Length:         # print integer value of Feet
            li $v0, 1
            move $a0, $t4
            syscall

            Length1:        # Print strLength1
            li $v0, 4
            la $a0, strLength1
            syscall

            li $v0, 2       # print float value of Inches
            mov.s $f12, $f1
            syscall

            li $v0, 4       # Print strLength2
            la $a0, strLength2
            syscall

            beq $t6, 2, exit    # if we are done printing the Mean of converted values of Feet and Inches, jumpt to exit
            beq $t6, 1, stats1    # if we are done printing converted Total value of Feet and Inches, jump to label stats1 and also print the Mean
            j endloop       # if we are done printing the converted values of user input, jump to endloop



          printWeight:
            beq $t6, 1, Weight    # in case we are printing the converted Total value of Pounds and Ounces, jump to label Weight
            beq $t6, 2, Weight1   # in case we are printing the Mean of converted values of Pounds and Ounces, jump to label Weight1

            li $v0, 4       # Print strWeight0
            la $a0, strWeight0
            syscall

            Weight:         # print integer value of Pounds
            li $v0, 1
            move $a0, $t4
            syscall

            Weight1:        # Print strWeight1
            li $v0, 4
            la $a0, strWeight1
            syscall

            li $v0, 2       # print float value of Ounces
            mov.s $f12, $f1
            syscall

            li $v0, 4       # Print strWeight2
            la $a0, strWeight2
            syscall

            beq $t6, 2, exit    # if we are done printing the Mean of converted values of Pounds and Ounces, jumpt to exit
            beq $t6, 1, stats1    # if we are done printing converted Total value of Pounds and Ounces, jump to label stats1 and also print the Mean
            j endloop       # if we are done printing the converted values of user input, jump to endloop


          printVolume:
            beq $t6, 1, Volume    # in case we are printing the converted Total value of Pints, jump to label Weight

            li $v0, 4       # Print strVolume0
            la $a0, strVolume0
            syscall

            Volume:         # print float value of Pints
            li $v0, 2
            mov.s $f12, $f1
            syscall

            li $v0, 4       # Print strVolume1
            la $a0, strVolume1
            syscall

            beq $t6, 2, exit    # if we are done printing the Mean of converted values of Pints, jumpt to exit
            beq $t6, 1, stats1    # if we are done printing converted Total value of Pints, jump to label stats1 and also print the Mean
            j endloop       # if we are done printing the converted values of user input, jump to endloop


      #######################################
      ###########    END PRINT     ##########
      #######################################


      endloop:

      li $v0, 4             # print a new line
      la $a0, newline
      syscall

      # Increment $t0 by immediate 4, incrementing by 4 not 1 since we are counting number of bytes
      addi $t0, $t0, 4

      # if $t1 less or equals to 4, (user has input no values or just 1 value) jump straight to exit, since there's no need to print the stats.
      # Else add user input to the Total sum value of user inputs ($t3)
      ble $t1, 4, exit
        add $t3, $t3, $t2   # summing up original values in array

    j while2            # jump back to while2 to repeat the loop or exit it





  #######################################
  #############   Stats   ###############
  #######################################


  stats:

  ##### ORIGINAL STATS #####
  # Compute and print out statistics for original values

        ## Printing Total of Original user input values##

        li $v0, 4       # print string strTo
        la $a0, strTo
        syscall

        li $v0, 1       # print the sum of original inputs
        move $a0, $t3
        syscall


        # The following code prints appropriate Unit name after the stats value is printed
        printUnit:
        beq $t5, 1, meters
        beq $t5, 2, kilos
        beq $t5, 3, litres

          meters:
            li $v0, 4       # Print strMeters String
            la $a0, strMeters
            syscall
            beq $t6, 1, cstats    # if printing unit name after meters mean, jump to cstats
            j mean          # once unit name is printed, jump to compute mean

          kilos:
            li $v0, 4       # Print strMeters String
            la $a0, strKilos
            syscall
            beq $t6, 1, cstats    # if printing unit name after kilograms mean, jump to cstats
            j mean          # once unit name is printed, jump to compute mean

          litres:
            li $v0, 4       # Print strMeters String
            la $a0, strLitres
            syscall
            beq $t6, 1, cstats    # if printing unit name after liters mean, jump to cstats
            j mean          # once unit name is printed, jump to compute mean



        mean:

        li $t6, 1       # set off the trigger by loading one into it. For explanation of trigger please refer to $t6 description in header or program descriptin in the report.

        ##### ORIGINAL MEAN #####
        # Calculate Original Mean
        # The following code converts Total sum of original inputs and number of inputs into float numbers (since dividing both will likely be a float number)
        # Then computes the mean by dividing former by the later and prints out the value. Depending on units being converted appropriate unit name is printed

        mtc1 $t3, $f1     # convert Total value in $t3 into single-precision float in $f1
        cvt.s.w $f1, $f1    # convert Total value in $t3 into single-precision float in $f1
        div $t1, $t1, 4     # converting byte number of $t1, into number of integers input by dividing by 4
        mtc1 $t1, $f0     # convert Total value in $t1 into single-precision float in $f0
        cvt.s.w $f0, $f0    # convert Total value in $t1 into single-precision float in $f0
        div.s $f1, $f1, $f0   # divide Total sum of original inputs ($f1) by number of inputs ($f0). Store the result (Mean) in $f1

        li $v0, 4       # Print strMo String
        la $a0, strMo
        syscall

        li $v0, 2       # Print the Mean value
        mov.s $f12, $f1
        syscall

        # jump to printUnit junction to print off Unit name following the Mean value
        j printUnit

        cstats:



  ##### CONVERTED STATS #####
  # Compute and print out statistics for converted values


        ### Printing the Total sum of converted inputs ###

        li $v0, 4       # print string strTc
        la $a0, strTc
        syscall


        # The following 2 lines move Total sum of original inputs value from $t3 to $t2. It then jumps to label junction, and converts Total sum of original inputs into the units user has       specified earlier using the same very code used to convert individual user inputs. Since trigger is set to 1 in $t6, once value in $t2 is computed it will jump right back to stats1      label with converted value of Total sum of converted inputs. This allows for great efficiency, since existing code is utilized again and there's no need to write convertion      algorithm again, or sum up all converted inputs.

        move $t2, $t3
        j junction




        ### Computing and Printing the Mean value of converted inputs ###


        stats1:
        add $t6, $t6, 1     # set trigger to 2 by adding 1. Under trigger value 2, existing code under label printJunction will be executed under different scenario printing only                  strings specifically needed for displaying the mean of converted values

        li $v0, 4       # print string strMc
        la $a0, strMc
        syscall

        mtc1 $t1, $f0     # convert integer number of user inputs in $t1 into single-precision float in $f0
        cvt.s.w $f0, $f0    # convert integer number of user inputs in $t1 into single-precision float in $f0

        div.s $f1, $f1, $f0   # at this stage $f1 holds either a float value of total Pints, Ounces or Inches. By dividing it by number of user inputs, we get a mean value of either total                   Pints or Total Ounces or Total Inches. Store the result (Mean of converted inputs) in $f1

        beq $t5, 3, Volume    # if converting Volume, there's no need to do next computations. Therefore, jump right to label Volume and print appropriate strings

        # However, if converting Length or Weight, that consist of two parts Pounds/Ounces & Feet/Inches, find the mean of the 1st part of conversion value (Total Pounds or Feet)
        mtc1 $t4, $f2     # convert integer values of Pounds/Feet stored in $t4 into single-precision float in $f2
        cvt.s.w $f2, $f2

        div.s $f2, $f2, $f0   # find the mean of Total value of Pounds and Feet.

        li $v0, 2       # Prit out the mean value of the first part of conversion (Pounds or Feet), then jump to printJunction to print out 2nd part of conversion and appropriate                  strings with the help of trigger being set to 2.
        mov.s $f12, $f2
        syscall

        j printJunction




  #######################################
  #############   Exit   ################
  #######################################

  exit:

  li $v0, 4             # print out berak line
  la $a0, strBreak
  syscall

  li $v0, 4             # print strings asking what user wants to do now
  la $a0, strChoice
  syscall

  choice2:
  li $v0, 5             # prompt user for input to choose one of the options, store user's choice in $t0
  syscall
  move $t0, $v0

  beq $t0, 1, prompt          # if user wants to convert more units using same conversion method jump to prompt and ask for such values
  beq $t0, 2, main          # if user wants to convert more units using other conversion method jump to menu and ask for conversion methods
  beq $t0, 3, quit          # if user wants to leave the app jump to quit

  # if user has input a random character or choice value of 0 or more than 4 , print error message, then jump and wait for user input again
  li $v0, 4
  la $a0, strErr0
  syscall
  j choice2

  quit:
  li $v0, 10
  syscall