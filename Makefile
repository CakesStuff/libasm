ASMC = nasm
ASMFLAGS = -felf64 -Iinclude -MD
AR = ar
ECHO = echo

SRC = $(wildcard src/*.asm)
OBJ = $(SRC:src/%.asm=build/obj/%.o)
DEP = $(OBJ:%.o=%.d)

LIB = libasm.a

default: debug

debug: ASMFLAGS += -g -O0
release: ASMFLAGS += -Ox

debug release: build/$(LIB)
	@$(ECHO) Build complete

-include $(DEP)

build:
	@$(ECHO) Creating folder $@
	@mkdir -p $@
build/obj: | build
	@$(ECHO) Creating folder $@
	@mkdir -p $@

build/obj/%.o: src/%.asm | build/obj
	@$(ECHO) Compiling $<
	@$(ASMC) $< $(ASMFLAGS) -o $@

build/$(LIB): $(OBJ) | build
	@$(ECHO) Linking $@
	@$(AR) rcs $@ $^

clean:
	@rm -rf build
	@$(ECHO) Clean complete

.PHONY: default debug release clean
