#include <stdio.h>
#include <stddef.h>
#include <inttypes.h>

void print_int_in_binary(uint64_t ull);
size_t count_of_bit_with_1(uint64_t num);

int main(void)
{
    uint64_t num = 0;
    while (1 == scanf("%llu", &num))
    {
        print_int_in_binary(num);
        printf(" - %d\n", count_of_bit_with_1(num));
    }

    return 0;
}

void print_int_in_binary(uint64_t ull)
{
    static uint64_t left_bit_is_1 = 1ull << 63;
    size_t bits_count = 64;
    int is_zero = 1;
    char binary_number_string[2] = {'0', '1'};
    size_t index = 0;
    printf("0b");
    while (bits_count--)
    {
        index = (size_t)((left_bit_is_1 & ull) / left_bit_is_1);
        if ((index != 0) && (1 == is_zero))
        {
            is_zero = 0;
        }
        if (!is_zero)
        {
            printf("%c", binary_number_string[index]);
        }
        ull <<= 1;
    }
    if (is_zero)
    {
        printf("0");
    }
    return;
}

size_t count_of_bit_with_1(uint64_t num)
{
    const unsigned char bit_1 = 0b10000000;
    const unsigned char bit_2 = 0b01000000;
    const unsigned char bit_3 = 0b00100000;
    const unsigned char bit_4 = 0b00010000;
    const unsigned char bit_5 = 0b00001000;
    const unsigned char bit_6 = 0b00000100;
    const unsigned char bit_7 = 0b00000010;
    const unsigned char bit_8 = 0b00000001;
    size_t count = 0;
    size_t bits_of_uint8 = 8;
    size_t bits_of_uint64 = 64;
    size_t count_of_uint8_in_uint64 = bits_of_uint64 / bits_of_uint8;
    while (count_of_uint8_in_uint64--)
    {
        uint8_t uint8_num = (uint8_t)(0xffull & num);
        num >>= bits_of_uint8;
        count += (((uint8_num & bit_1) / bit_1) +
        ((uint8_num & bit_2) / bit_2) +
        ((uint8_num & bit_3) / bit_3) +
        ((uint8_num & bit_4) / bit_4) +
        ((uint8_num & bit_5) / bit_5) +
        ((uint8_num & bit_6) / bit_6) +
        ((uint8_num & bit_7) / bit_7) +
        ((uint8_num & bit_8) / bit_8));
    }
    return count;
}

