#include <stdio.h>

// nasm -f elf64 printf.s -o printf.o

// g++ -c cmain.cpp -o cmain.o

// g++ -o printf cmain.o printf.o -no-pie

// ./printf

extern "C" void my_printf(const char *format, ...);

int main()
{
    double y = -0.21;
    double y2 = -1.0 / 0.0;
    
    // printf(
        //     #include "bigstring.h"
        //     , 
        //     #include "test.h"
        // );
    int x = 3;
    int x2 = 5;
    my_printf("test: %b\n", 25);
    my_printf("pupupu %b %c\n", 25, 'r');
    my_printf("Test: 1: %f %d | 2: %f %d | 3: %f %d | 4: %f %d | \n5: %f %d | 6: %f %d | 7: %f %d | 8: %f %d | \n9: %f %d |\n%d %s %x %d%%%c %b\n", y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2, -1, "love", 3802, 100, 33, 126);
    // printf("Test: 1: %f %d | 2: %f %d | 3: %f %d | 4: %f %d | \n5: %f %d | 6: %f %d | 7: %f %d | 8: %f %d | \n9: %f %d |\n%d %s %x %d%%%c %b\n", y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2, y, x, y2, x2, -1, "love", 3802, 100, 33, 126);

    // return 0;
}