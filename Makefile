# Copyright (c) 2015 by Wojciech A. Koszek
CFLAGS+= -Wall -pedantic

all: rcd

rcd:	rcd.c
	$(CC) $(CFLAGS) $< -o $@

tests:	rcd
	./rcd test/data.i > sed.script
	chmod 755 sed.script
	./sed.script < test/data.i > data.o

check:
	@echo "# Checking result (no output means it was ok)"
	diff -u test/data.t data.o

clean:
	rm -rf rcd data.o sed.script
