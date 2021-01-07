# Parser-and-MIPS-Code-Generator-for-the-sprintf-function
A parser and MIPS code generator for the *sprintf* function using MARS simulator
## Background
*printf* is a C function that prints any sequence of characters on the console output (like cout in C++). 
*sprintf* has basically the same behavior as *printf* except that the whole output string is put into a buffer instead of the console output. 
In other words, *sprintf* composes a string with the same text that would be printed with *printf*, but instead of being printed on the screen, the text is stored as a C string.
**For example, if we have x = -17,y = 43,z = 104;** 
*printf*(“x = %d, y = %x, z = %c”, x, y, z); Output on the console is: x = -17, y = 2b, z = h Here x is printed as a signed decimal integer, y is printed as an unsigned hexadecimal integer, and z is printed as an ASCII code character, that is according to the format specifiers %d, %x, and %c, respectively. 

*sprintf* does the same operation except that it stores the output text “x = -17, y = 2b, z = h” in an output string, instead of displaying it on the console output.
