AS=nasm # Assembly compiler
ASFLAGS=-f elf64
LD=ld # Linker
LDFLAGS=-m 
SOURCES=$(wildcard ./src/*.c)
OBJECTS=$(SOURCES:.asm=.o) # Object files
EXECUTABLE=asmserv

# Check version
all: $(SOURCES) $(EXECUTABLE)

# Create executable
$(EXECUTABLE): $(OBJECTS) 
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

# Compile assembly program
$(OBJECTS): $(SOURCES)
	$(AS) $(ASFLAGS) $(SOURCES)
 
# Clean folder
clean:
	rm -rf *o $(EXECUTABLE)