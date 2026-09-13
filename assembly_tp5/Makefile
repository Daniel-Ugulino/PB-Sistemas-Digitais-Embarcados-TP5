# Road Shield — ARM64, sem libc
#
#   *.s            -> módulos da aplicação (incluindo keyboard.s, spi.s)
#   lib/concat.s   -> lib/concat.a
#   lib/parse.s    -> lib/parse.a
#   lib/arith.s    -> lib/arith.a

UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),aarch64)
  PREFIX :=
else
  PREFIX := aarch64-linux-gnu-
endif

AS  := $(PREFIX)as
AR  := $(PREFIX)ar
LD  := $(PREFIX)ld

ASFLAGS := -Iinclude
BUILD   := build
BIN     := road_shield
LIBDIR  := lib

APP_SRCS := $(wildcard *.s)
APP_OBJS := $(patsubst %.s,$(BUILD)/%.o,$(APP_SRCS))

LIB_CONCAT := $(LIBDIR)/concat.a
LIB_PARSE  := $(LIBDIR)/parse.a
LIB_ARITH  := $(LIBDIR)/arith.a
LIBS       := $(LIB_CONCAT) $(LIB_PARSE) $(LIB_ARITH)

.PHONY: all clean run

all: $(BIN)

$(BIN): $(APP_OBJS) $(LIBS)
	$(LD) -o $@ $(APP_OBJS) $(LIBS)

$(BUILD)/%.o: %.s include/macros.inc include/syscall.inc
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD)/lib/%.o: lib/%.s include/macros.inc include/syscall.inc
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

$(LIB_CONCAT): $(BUILD)/lib/concat.o
	$(AR) rcs $@ $^

$(LIB_PARSE): $(BUILD)/lib/parse.o
	$(AR) rcs $@ $^

$(LIB_ARITH): $(BUILD)/lib/arith.o
	$(AR) rcs $@ $^

run: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BUILD) $(BIN) $(LIBS)
