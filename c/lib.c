void init() {
   int nobjs=0, nwords=0;
   hp = (byte *) &heap; /* builtin heap */
   state = IFALSE;
   heap_metrics(&nwords, &nobjs);
   max_heap_mb = (W == 4) ? 4096 : 65535;
   nwords += nobjs + INITCELLS;
   memstart = genstart = fp = (word *) realloc(NULL, (nwords + MEMPAD)*W);
   if (!memstart) return;
   memend = memstart + nwords - MEMPAD;
   state = (word) load_heap(nobjs);
}

/* bvec → value library call test with preserved state */
word library_call(word val) {
   word program_state = state;
   word res;
   state = IFALSE; 
   if (program_state == IFALSE) {
      exit(1);
   }
   res = vm((word *) program_state, val);
   return res;
}

size_t list_length(word lispval) {
   size_t l = 0;
   while(lispval != INULL) {
      lispval = G(lispval, 2);
      l++;
   }
}

size_t copy_list(uint8_t *ptr, word lispval, size_t max) {
   size_t n = 0;
   while(pairp(lispval) && max-- && lispval != INULL) {
      *ptr++ = 255 & immval(G(lispval, 1)); // *ptr++ = car(list)
      n++;
      lispval = G(lispval, 2);              // list   = cdr(list)
   }
   if (lispval != INULL) {
      printf("ERROR: lisp return value was not a proper list. Trailing %d\n", lispval);
   }
   return n;
}

// fuzz data at *ptr of length len, write fuzzed data to *ptr and return its length (which is at most max)
size_t radamsa_inplace(uint8_t *ptr, size_t len, size_t max, unsigned int seed) {
   word *arg, res;
   arg = fp;
   fp += 5;
   arg[0] = make_header(5, TTUPLE);
   arg[1] = onum((word)ptr, 0);
   arg[2] = onum(len, 0);
   arg[3] = onum(max, 0);
   arg[4] = onum(seed, 0);
   res = library_call((word) arg);
   return copy_list(ptr, res, max);
}

/* size_t radamsa_malloc(void *ptr, size_t len, void *target, size_t &target_len) {
   word *arg, res;
   arg = fp;
   fp += 5;
   arg[0] = make_header(5, TTUPLE);
   arg[1] = onum((word)ptr, 0);
   arg[2] = onum(len * sizeof(void), 0);
   arg[3] = onum(max, 0);
   arg[4] = onum(seed, 0);
   res = library_call((word) arg);
   return copy_list(ptr, res, max);
} */

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
   uint8_t foo[BUFLEN];
   int seed = 1;
   init();
   while(seed++ < 100) {
      size_t n;
      uint8_t *sample = (uint8_t *) ((seed & 1) ? s1 : s2);
      size_t sample_len = strlen((char *) sample);
      memset(&foo, 0, BUFLEN);
      memcpy(foo, sample, sample_len);
      n = radamsa_inplace((uint8_t *) &foo, sample_len, BUFLEN, seed);
      printf("%d -> %.*s\n", seed, n, (char *) &foo);
   }
   printf("library test passed\n");
   return 0;
}


