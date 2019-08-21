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

void copy_list(uint8_t *ptr, word lispval, size_t max) {
   while(max-- && lispval != INULL) {
      *ptr++ = 255 & immval(G(lispval, 1)); // *ptr++ = car(list)
      lispval = G(lispval, 2);              // list   = cdr(list)
   }
}

void radamsa(uint8_t *ptr, size_t len, size_t max, unsigned int seed) {
   word *arg, res;
   arg = fp;
   fp += 5;
   arg[0] = make_header(5, TTUPLE);
   arg[1] = onum((word)ptr, 0);
   arg[2] = onum(len, 0);
   arg[3] = onum(max, 0);
   arg[4] = onum(seed, 0);
   res = library_call((word) arg);
   copy_list(ptr, res, max);
}

void printbs(uint8_t *data, size_t len) {
   printf("{ ");
   while(len--) {
      printf("%d ", *data++);
   }
   printf("}\n");
}

int main(int nargs, char **argv) {
   uint8_t foo[] = {0, 0, 0, 0, 0, 0, 0, 0};
   int seed = 1;
   init();
   while(seed++ < 1000) {
      printbs((uint8_t *) &foo, 8);
      radamsa((uint8_t *) &foo, 6, 8, seed);
   }
   return 0;
}


