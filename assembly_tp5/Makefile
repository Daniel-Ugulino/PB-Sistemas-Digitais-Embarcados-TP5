# Road Shield — ARM64, sem libc

AS := as
LD := ld

ASFLAGS := -Iinclude
BUILD   := build
BIN     := road_shield

OBJS := $(patsubst %.s,$(BUILD)/%.o,$(wildcard *.s)) \
        $(patsubst lib/%.s,$(BUILD)/lib/%.o,$(wildcard lib/*.s))

.PHONY: all clean run

all: $(BIN)

$(BIN): $(OBJS)
	$(LD) -o $@ $^

$(BUILD)/%.o: %.s include/macros.inc include/syscall.inc
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD)/lib/%.o: lib/%.s include/macros.inc include/syscall.inc
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -o $@ $<

run: $(BIN)
	./$(BIN)

clean:
	rm -rf $(BUILD) $(BIN) lib/*.a
