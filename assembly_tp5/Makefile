# Road Shield — ARM64, sem libc
#
#   *.s            -> módulos da aplicação (incluindo keyboard.s, spi.s)
#   lib/string.s   -> lib/libutil.a
#   lib/format.s   -> lib/libparse.a
#   lib/saturate.s -> lib/libarith.a

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

LIB_UTIL  := $(LIBDIR)/libutil.a
LIB_PARSE := $(LIBDIR)/libparse.a
LIB_ARITH := $(LIBDIR)/libarith.a
LIBS      := $(LIB_UTIL) $(LIB_PARSE) $(LIB_ARITH)

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

$(LIB_UTIL): $(BUILD)/lib/string.o
	$(AR) rcs $@ $^

$(LIB_PARSE): $(BUILD)/lib/format.o
	$(AR) rcs $@ $^

$(LIB_ARITH): $(BUILD)/lib/saturate.o
	$(AR) rcs $@ $^

run: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BUILD) $(BIN) $(LIBS)
