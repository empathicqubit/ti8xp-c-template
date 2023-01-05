# make -p ist ein Freund
SHELL := bash.exe

PROGNAME?=CRACKERS
PLATFORM?=ti8x
SUBTYPE?=mirage

# Comment this out to disable debugging completely
DEBUG=1

# Comment this out if you don't want to include the GDB debugger
# This requires DEBUG
GDB=1

CC=$(shell which zcc z88dk.zcc | head -1)
LD=$(CC)

BASE_CFLAGS=-Wall
BASE_CFLAGS_DEBUG=$(BASE_CFLAGS) -debug -g -O0
BASE_CFLAGS_RELEASE=$(BASE_CFLAGS) -O3 --opt-code-speed

ifdef DEBUG
	ifdef GDB
LDFLAGS?=$(BASE_CFLAGS_DEBUG) -L$(GDB_PATH)/build -lgdb
LIBCFLAGS?=$(BASE_CFLAGS_RELEASE) -DGDB_ENABLED
	else
LDFLAGS?=$(BASE_CFLAGS_DEBUG)
	endif
CFLAGS?=$(BASE_CFLAGS_DEBUG)
else
CFLAGS?=$(BASE_CFLAGS_RELEASE)
LDFLAGS?=$(BASE_CFLAGS_RELEASE)
endif

LIBCFLAGS?=$(BASE_CFLAGS_RELEASE)

BUILD=build

BRIDGE_PATH=3rdparty/ticables-gdb-bridge
GDB_PATH=3rdparty/z88dk-gdbstub
TIKEYS=$(BRIDGE_PATH)/build/tikeys

wilder_card=$(wildcard $(1)/**/$(2)) $(wildcard $(1)/$(2))
define source_directory
$(eval $(1)=$(2))
$(eval $(1)_FILES=$(call wilder_card,$(2),*.s) $(call wilder_card,$(2),*.c))
$(eval $(1)_OBJECT_FILES=$$(subst $(2)/,$$(BUILD)/$(2)/,$$(patsubst %.s,%.o,$$(patsubst %.c,%.o,$$($(1)_FILES)))))
$(eval vpath %.c $(2))
$(eval vpath %.s $(2))
endef

$(call source_directory,SRC,src)
$(call source_directory,LIB,lib)

.ONESHELL:

all: $(BUILD)/program.8xp

install: $(BUILD)/program.8xp ${HOME}/.tilp
	sed -i 's/auto_detect[[:space:]]*=[[:space:]]*1/auto_detect=0/g' "${HOME}/.tilp"
	$(TIKEYS) --reset-ram
	tilp -n --calc=83p "$<"

${HOME}/.tilp: ./.tilp
	if [[ ! -e "$@" ]] ; then
		cp "$<" "$@"
	fi

start: $(TIKEYS) install
	"$<" --program=$(PROGNAME)

bridge: $(BRIDGE_PATH)/build/tibridge
	echo "<<<STARTED BRIDGE>>>"
	"$<" --port=$${TIBRIDGE_PORT:-8998} --log-level=trace 2>$(shell tty)

vbshared: /vbshared/_.8xp

clean:
	rm -rf build

$(BUILD)/program.8xp: $(BUILD)/program.bin
	bash ./bashpac8x.sh "$<" "$(PROGNAME)" > "$@"

$(BUILD)/program.bin: $(BUILD)/program.bip
	cat header_bytes.bin "$<" > "$@"

$(BUILD)/program.bip: $(SRC_OBJECT_FILES) $(LIB_OBJECT_FILES)
	$(LD) +ti8x -subtype=$(SUBTYPE) $(LDFLAGS) -o "$@" $(filter %.o,$^)

# It's extremely important that the source file paths are absolute, otherwise the
# extension will have trouble mapping the paths.
define source_compile
	mkdir -p "$(dir $@)"
	if [ ! -z "$(filter $(LIB_FILES),$<)" ] ; then
		$(CC) +$(PLATFORM) $(LIBCFLAGS) $(1) -o "$@" "$(realpath $<)"
	else
		$(CC) +$(PLATFORM) $(CFLAGS) $(1) -o "$@" "$(realpath $<)"
	fi
endef

$(BUILD)/%.o: $(BUILD)/%.o.asm | $(BUILD)
	mkdir -p "$(dir $@)"
	if [ ! -z "$(filter $(LIB_OBJECT_FILES),$@)" ] ; then
		$(CC) +$(PLATFORM) $(LIBCFLAGS) -c -o "$@" "$<"
	else
		$(CC) +$(PLATFORM) $(CFLAGS) -c -o "$@" "$<"
	fi

.PRECIOUS: $(BUILD)/%.o.asm
$(BUILD)/%.o.asm: $(BUILD)/%.i.asm | $(BUILD)
# Inserts NOPs into the assembly so we have space to debug
# Only insert one nop group per block of C_LINEs (sometimes there's a lot)
# Only count C_LINEs which aren't at the top level 0
	CLINE_MATCHER='^[[:space:]]*[0-9]*[[:space:]]*C_LINE.*::[1-9][0-9]*::.*'
	sed -f <(
		nl -b a "$<" | tac | uniq -f1 -d |
			grep -o "$$CLINE_MATCHER" |
			awk '{print $$1}' |
			while read LINE ; do
				NL=$$((LINE+1)) ;
				echo "$$NL"'i nop\nnop\nnop' ;
				echo "$${NL}{/$${CLINE_MATCHER}/d;}" ;
			done
	) "$<" > "$@"

.PRECIOUS: $(BUILD)/%.i.asm
$(BUILD)/%.i.asm: %.s | $(BUILD)
	$(call source_compile,-S)

.PRECIOUS: $(BUILD)/%.i.asm
$(BUILD)/%.i.asm: %.c | $(BUILD)
	$(call source_compile,-S)

$(BUILD): $(GDB_PATH)/build/gdb.lib
	@mkdir -p "$@"

$(GDB_PATH)/build/gdb.lib: $(GDB_PATH)
	$(MAKE) -C "$(GDB_PATH)"

$(BRIDGE_PATH)/build/tibridge: $(BRIDGE_PATH)/build/tikeys

$(BRIDGE_PATH)/build/tikeys: $(BRIDGE_PATH)/build/Makefile
	$(MAKE) -C "$(dir $<)"

$(BRIDGE_PATH)/build/Makefile: $(BRIDGE_PATH)/CMakeLists.txt | $(BRIDGE_PATH)/build
	cd $(BRIDGE_PATH)/build
	cmake ..

$(BRIDGE_PATH)/build:
	@mkdir -p "$@"

$(BRIDGE_PATH)/CMakeLists.txt: submodules

$(GDB_PATH): submodules

submodules:

/vbshared/_.8xp: $(BUILD)/program.8xp
	cp "$<" "$@"
