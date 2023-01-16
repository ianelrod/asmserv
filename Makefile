# -----------------------------------------
# 64-bit program that handles HTTP requests
# Author: Ian Goforth
# 
# A 3-second Makefile
# -----------------------------------------

TARGET	= asmserv
AS		= nasm
ASFLAGS = -f elf64
LD		= ld

SRCDIR  = src
OBJDIR  = obj
BINDIR  = bin

SRCS    := $(wildcard $(SRCDIR)/*.asm)
OBJS    := $(SRCS:$(SRCDIR)/%.asm=$(OBJDIR)/%.o)
rm      = rm -f

$(BINDIR)/$(TARGET): $(OBJS)
	@mkdir -p $(@D)
	@$(LD) -o $@ $(OBJS)

$(OBJS): $(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(@D)
	@$(AS) $(ASFLAGS) -o $@ $<

.PHONY: clean
clean:
	@$(rm) $(OBJS)

.PHONY: remove
remove: clean
	@$(rm) $(BINDIR)/$(TARGET)