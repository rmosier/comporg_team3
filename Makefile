All: GCD PowerMod IsPrime
LIB=libRSA.o
CC=gcc

GCD: GCD.o $(LIB)
	$(CC) $@.o $(LIB) -g -o $@

PowerMod: PowerMod.o $(LIB)
	$(CC) $@.o $(LIB) -g -o $@


IsPrime: IsPrime.o $(LIB)
	$(CC) $@.o $(LIB) -g -o $@


.s.o:
	$(CC) $(@:.o=.s) -g -c -o $@
