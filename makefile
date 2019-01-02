
OBJ = sorthem.o asm_io.o 
CC = gcc
CFLAGS = -m32 -g

project: $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ) driver.c

driver.o: driver.c
	$(CC) $(CFLAGS) -c $?

sorthem.o: sorthem.asm
	nasm -f elf32 -o $@ $?

asm_io.o: asm_io.asm
	nasm -f elf32 -d ELF_TYPE -o $@ $?

clean:
	rm *.o
