#include <radamsa.h>
#include <stdio.h>
#include <inttypes.h>
#include <string.h>

#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

size_t filesize(char* filename) {
    struct stat st;
    stat(filename, &st);
    return st.st_size;
}

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
   char *spath = argv[1];
   int fd = open(spath, O_RDONLY, 0);
   size_t len = filesize(spath);
   if (fd < 0) {
      printf("cannot open %s", spath);
      return(1);
   }
   int seed = 1;
   init();
   while(seed++ < 100) {
      size_t n;
      void* data = mmap(NULL, len, PROT_READ | PROT_WRITE , MAP_PRIVATE | MAP_POPULATE, fd, 0);
      printf("orig> ");
      fflush(stdout);
      write(1, (char *) data, len);
      printf("\n");
      if (data == MAP_FAILED) {
         printf("failed to mmap %s\n", spath);
         return(1);
      }
      n = radamsa_inplace((uint8_t *) data, len, len, seed);
      printf("fuzzed< ");
      fflush(stdout);
      write(1, (char *) data, n);
      printf("\n");
      munmap(data, len);
   }
   printf("library test passed\n");
   return 0;
}


