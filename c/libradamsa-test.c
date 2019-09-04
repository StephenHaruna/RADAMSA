#include <radamsa.h>
#include <stdio.h>
#include <inttypes.h>
#include <string.h>

void printbs(uint8_t *data, size_t len) {
   printf("{ ");
   while(len--) {
      printf("%d ", *data++);
   }
   printf("}\n");
}

char *s1 = "Hello <b>HAL</b> 9000\0";
char *s2 = "Hello, world!\0";
#define BUFLEN 64 

/* temporary test */
int main(int nargs, char **argv) {
   uint8_t foo[BUFLEN+1];
   int seed = 1;
   init();
   while(seed++ < 10000) {
      size_t n;
      uint8_t *sample = (uint8_t *) ((seed & 1) ? s1 : s2);
      size_t sample_len = strlen((char *) sample);
      memset(&foo, 0, BUFLEN);
      memcpy(foo, sample, sample_len);
      n = radamsa_inplace((uint8_t *) &foo, sample_len, BUFLEN, seed);
      foo[BUFLEN] = 0;
      printf("%d -> '%s'\n", seed, (char *) &foo);
   }
   printf("library test passed\n");
   return 0;
}


