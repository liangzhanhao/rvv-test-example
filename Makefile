#Makefile for rvv-test-example
#-----------------------------------------------------------------------

XLEN ?= 64

default: all

src_dir = .

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

examples = vvaddint32 \

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -march=rv64imafdcv
RISCV_LINK ?= $(RISCV_GCC) -T $(src_dir)/common/test.ld $(incs)
RISCV_LINK_OPTS ?= -static -nostdlib -nostartfiles -lm -lgcc -T $(src_dir)/common/test.ld
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data
RISCV_SIM ?= spike --isa=rv$(XLEN)gcv --varch=v64:e64:s64

incs  += -I$(src_dir)/env -I$(src_dir)/common $(addprefix -I$(src_dir)/, $(examples))
objs  :=

define compile_template
$(1).riscv: $(wildcard $(src_dir)/$(1)/*) $(wildcard $(src_dir)/common/*)
	$$(RISCV_GCC) $$(incs) $$(RISCV_GCC_OPTS) -o $$@ $(wildcard $(src_dir)/$(1)/*.c) $(wildcard $(src_dir)/$(1)/*.S) $(wildcard $(src_dir)/common/*.c) $(wildcard $(src_dir)/common/*.S) $$(RISCV_LINK_OPTS)
endef

$(foreach example,$(examples),$(eval $(call compile_template,$(example))))

#------------------------------------------------------------
# Build and run example on riscv simulator

bmarks_riscv_bin  = $(addsuffix .riscv,  $(examples))
bmarks_riscv_dump = $(addsuffix .riscv.dump, $(examples))
bmarks_riscv_out  = $(addsuffix .riscv.out,  $(examples))

$(bmarks_riscv_dump): %.riscv.dump: %.riscv
	$(RISCV_OBJDUMP) $< > $@

$(bmarks_riscv_out): %.riscv.out: %.riscv
	$(RISCV_SIM) $< > $@

riscv: $(bmarks_riscv_dump)
run: $(bmarks_riscv_out)

junk += $(bmarks_riscv_bin) $(bmarks_riscv_dump) $(bmarks_riscv_hex) $(bmarks_riscv_out)

#------------------------------------------------------------
# Default

all: riscv

# Clean up

clean:
	rm -rf $(objs) $(junk)
