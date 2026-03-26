#include <stdio.h>

// nasm -f elf64 printf.s -o printf.o

// g++ -c cmain.cpp -o cmain.o

// g++ -o program cmain.o printf.o -no-pie

// ./program

extern "C" void my_printf(const char *format, ...);

int main()
{
    // #include "test.h"
    // my_printf("pupupu %d %c\n", 25, 'r');
    double y = 1.25;
    int x = 3;
    my_printf("Test: 1: %f %d | 2: %f %d | 3: %f %d | 4: %f %d | \n5: %f %d | 6: %f %d | 7: %f %d | 8: %f %d | \n\n", y, x, y, x, y, x, y, x, y, x, y, x, y, x, y, x);
    return 0;
}