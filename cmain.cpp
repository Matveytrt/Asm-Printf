#include <stdio.h>

// nasm -f elf64 printf.s -o printf.o

// g++ -c cmain.cpp -o cmain.o

// g++ -o program cmain.o printf.o -no-pie

// ./program

extern "C" void my_printf(const char *format, ...);

int main()
{
    // #include "test.h"
    my_printf("pupupu %d %c\n", 25, 'r');
    return 0;
}