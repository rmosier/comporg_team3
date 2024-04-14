All: GCD
LIB=libRSA.o
CC=gcc

GCD: GCD.o $(LIB)
	$(CC) $@.o $(LIB) -g -o $@

.s.o:
	$(CC) $(@:.o=.s) -g -c -o $@
