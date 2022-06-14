TARGET	= search

NASM	= nasm
LD	= ld

$(TARGET): search.o
	$(LD) -m elf_i386 -o $@ $<

search.o: search.asm
	$(NASM) -g -f elf $<

.PHONY: clean
clean:
	rm -f *~ *.o $(TARGET)
