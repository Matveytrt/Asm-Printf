#include <stdio.h>

// nasm -f elf64 printf.s -o printf.o

// g++ -c cmain.cpp -o cmain.o

// g++ -o printf cmain.o printf.o -no-pie

// ./printf

extern "C" void my_printf(const char *format, ...);

int main()
{
    // #include "test.h"
    // my_printf("pupupu %d %c\n", 25, 'r');
    double y = 1.25;
    double y2 = 0.48;
    int x = 3;
    int x2 = 5;
    my_printf("Test: 1: %f %d | 2: %f %d | 3: %f %d | 4: %f %d | \n5: %f %d | 6: %f %d | 7: %f %d | 8: %f %d | \n9: %f %d |\n\n", y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2);
    
    return 0;
}