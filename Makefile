DESTDIR=
PREFIX=/usr
BINDIR=/bin
CFLAGS?=-Wall -O2
LDFLAGS?=
OFLAGS=-O2
OWLURL=https://gitlab.com/owl-lisp/owl/uploads/38d13ea55860be90b8c0a4519810c6d5/ol-0.1.20.c.gz
USR_BIN_OL?=/usr/bin/ol

everything: bin/radamsa

build_radamsa:
	test -x $(USR_BIN_OL)
	$(USR_BIN_OL) $(OFLAGS) -o radamsa.c rad/main.scm
	mkdir -p bin
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/radamsa radamsa.c

bin/radamsa: radamsa.c
	mkdir -p bin
	$(CC) $(CFLAGS) $(LDFLAGS) -o bin/radamsa radamsa.c

radamsa.c: rad/*.scm
	test -x bin/ol || make bin/ol
	bin/ol $(OFLAGS) -o radamsa.c rad/main.scm

radamsa.fasl: rad/*.scm bin/ol
	bin/ol -o radamsa.fasl rad/main.scm

ol.c:
	test -f ol.c.gz || wget -O ol.c.gz $(OWLURL) || curl -L -o ol.c.gz $(OWLURL)
	gzip -d < ol.c.gz > ol.c

bin/ol: ol.c
	mkdir -p bin
	cc -O2 -o bin/ol ol.c

install: bin/radamsa
	-mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp bin/radamsa $(DESTDIR)$(PREFIX)/bin
	-mkdir -p $(DESTDIR)$(PREFIX)/share/man/man1
	cat doc/radamsa.1 | gzip -9 > $(DESTDIR)$(PREFIX)/share/man/man1/radamsa.1.gz

clean:
	-rm -rf owl-lisp
	-rm radamsa.c bin/radamsa .seal-of-quality
	-rm bin/ol ol.c.gz ol.c

mrproper: clean
	-rm -rf ol-*
	-rm -rf owl

test: .seal-of-quality

fasltest: radamsa.fasl
	sh tests/run owl-lisp/bin/vm radamsa.fasl

.seal-of-quality: bin/radamsa
	-mkdir -p tmp
	sh tests/run bin/radamsa
	touch .seal-of-quality

# standalone build for shipping
standalone:
	-rm radamsa.c # likely old version
	make radamsa.c
	# compile without seccomp and use of syscall
	diet gcc -DNO_SECCOMP -O3 -Wall -o bin/radamsa radamsa.c

# a quick to compile vanilla bytecode executable
bytecode: bin/ol
	bin/ol -O0 -x c -o - rad/main.scm | $(CC) -O2 -x c -o bin/radamsa -
	-mkdir -p tmp
	sh tests/run bin/radamsa

# a simple mutation benchmark
benchmark: bin/radamsa
	tests/benchmark bin/radamsa

future:
	test -d owl || git clone https://gitlab.com/owl-lisp/owl
	#cd owl && git pull
	-cd owl && make bin/ol
	cp owl/bin/ol bin/ol
	make

autofuzz: bin/radamsa
	echo '<html> <foo bar=baz>zeb</foo> <foo babar=lol></html>' > tmp/test.xmlish
	bin/radamsa -v -o tmp/out-%n -n 200 rad/* bin/* tmp/test.xmlish
	bin/radamsa -v -o tmp/out-2-%n -n 200 tmp/out-* tmp/test.xmlish
	bin/radamsa -v -o tmp/out-3-%n -n 200 tmp/out-2-* tmp/test.xmlish
	# fuzz a million outputs 
	bin/radamsa --seed 42 --meta million.meta -n 1000000
	echo autofuzz complete


## Library mode test

c/libradamsa.c: bin/ol c/lib.c rad/*.scm
	bin/ol -O1 --mode library -o c/libradamsa.c rad/libradamsa.scm
	sed -i 's/int main/int secondary/' c/libradamsa.c
	cat c/lib.c >> c/libradamsa.c

lib/libradamsa.a: c/libradamsa.c
	mkdir -p lib
	cc -O2 -I c -o lib/libradamsa.a -c c/libradamsa.c

bin/libradamsa-test: lib/libradamsa.a c/libradamsa-test.c
	mkdir -p tmp
	cc -O2 -Ic -o bin/libradamsa-test c/libradamsa-test.c -Llib -lradamsa

libradamsa-test: bin/libradamsa-test
	bin/libradamsa-test c/lib.c | grep "library test passed"


## Cleanup and Meta

uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/radamsa || echo "no radamsa"
	rm $(DESTDIR)$(PREFIX)/share/man/man1/radamsa.1.gz || echo "no manpage"

.PHONY: todo you install clean mrproper test bytecode uninstall get-owl standalone
