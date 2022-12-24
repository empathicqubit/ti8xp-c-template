CFLAGS?=-g --opt-code-speed
#-debug -Cs--debug
LDFLAGS?=-g 
#-debug
CC=$(shell which z88dk.zcc zcc)
LD=$(shell which z88dk.zcc zcc)

BUILD=build
SRC=src
SRC_FILES=$(wildcard $(SRC)/*.c) $(wildcard $(SRC)/*.s)
OBJECT_FILES=$(subst $(SRC)/,$(BUILD)/,$(patsubst %.s,%.o,$(patsubst %.c,%.o,$(SRC_FILES))))

vpath %.c src
vpath %.s src
vpath %.h src

.ONESHELL:

all: $(BUILD)/program.8xp

tilp: $(BUILD)/program.8xp
	tilp --calc=83p "$<"

vbshared: /vbshared/template.8xp

/vbshared/template.8xp: $(BUILD)/program.8xp
	cp "$<" "$@"

clean:
	rm -rf build

$(BUILD)/%.o: %.s | $(BUILD)
	$(CC) +ti8x $(CFLAGS) -c -o "$@" "$<"

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) +ti8x $(CFLAGS) -c -o "$@" "$<"

$(BUILD):
	mkdir -p "$(BUILD)"

$(BUILD)/program.bip: $(OBJECT_FILES)
	$(LD) +ti8x -subtype=mirage $(LDFLAGS) -o "$@" $^

$(BUILD)/program.bin: $(BUILD)/program.bip
	cat header_bytes.bin "$<" > "$@"

$(BUILD)/program.8xp: $(BUILD)/program.bin
	bash ./binpac8x.sh "$<" PROGRAM > "$@"
