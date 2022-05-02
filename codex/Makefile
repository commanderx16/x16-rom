
TESTDIR = test
SRCDIR  = src
INCDIR  = inc
KINCDIR = ../inc

BUILD_DIR    = ../build/x16
CFG_DIR      = $(BUILD_DIR)/cfg
OBJDIR       = $(BUILD_DIR)/codex
CFG_SUBDIR   = cfg

ROM_INCLUDE  = ../inc
KSUP_INCLUDE = ../kernsup

#AS=ca65 -D DEV

AS=ca65

DEV=1

$(OBJDIR)/%.o : $(SRCDIR)/%.s
	@mkdir -p $(OBJDIR)
	$(AS) -I $(INCDIR) -I $(KINCDIR) --listing $(SRCDIR)/$*.l $< -o $@

CX_SRCS = $(SRCDIR)/cx.s

CX_DC_SRCS  = $(SRCDIR)/cx-dc.s
CX_MII_SRCS = $(SRCDIR)/cx-mii.s
CX_SYM_SRCS = $(SRCDIR)/cx-sym.s

UT_SRCS = $(TESTDIR)/utest.s

CX_INCS = \
		 $(INCDIR)/x16_kernal.inc \
       $(INCDIR)/dbgctrl.inc \
	    $(INCDIR)/edit.inc \
	    $(INCDIR)/dispatch.inc \
		 $(INCDIR)/decoder.inc \
		 $(INCDIR)/encode.inc \
	    $(INCDIR)/meta.inc \
	    $(INCDIR)/meta_i.inc

BOOTSTRAP_OBJS = $(OBJDIR)/devrt0.o

PLUGIN_OBJS = $(OBJDIR)/plugin-load.o

COMMON_OBJS = \
      $(OBJDIR)/bank.o \
      $(OBJDIR)/bank_assy.o \
		$(OBJDIR)/bank_assy_vars.o \
      $(OBJDIR)/dbgctrl.o \
      $(OBJDIR)/decoder.o \
		$(OBJDIR)/decoder_vars.o \
      $(OBJDIR)/dispatch.o \
		$(OBJDIR)/dispatch_vars.o \
      $(OBJDIR)/edit.o \
      $(OBJDIR)/encode.o \
		$(OBJDIR)/encode_vars.o \
	   $(OBJDIR)/fio.o \
      $(OBJDIR)/meta.o \
      $(OBJDIR)/meta_i.o \
      $(OBJDIR)/petsciitoscr.o \
      $(OBJDIR)/screen.o \
		$(OBJDIR)/screen_vars.o \
      $(OBJDIR)/utility.o \
      $(OBJDIR)/vera.o \
		$(OBJDIR)/cx_vars.o

CX_OBJS = $(OBJDIR)/cx.o $(COMMON_OBJS) 

#
# TODO: Build better CFG to make the plugins as small as possible
#

CX_DC_OBJS = \
      $(OBJDIR)/bank.o \
      $(OBJDIR)/bank_assy.o \
		$(OBJDIR)/bank_assy_vars.o \
      $(OBJDIR)/cx-dc.o \
		$(OBJDIR)/decoder.o \
		$(OBJDIR)/fio.o \
		$(OBJDIR)/meta.o \
		$(OBJDIR)/meta_i.o \
      $(OBJDIR)/petsciitoscr.o \
		$(OBJDIR)/screen.o \
		$(OBJDIR)/utility.o \
		$(OBJDIR)/decoder_vars.o \
		$(OBJDIR)/dispatch_vars.o \
		$(OBJDIR)/encode_vars.o \
		$(OBJDIR)/screen_vars.o \
		$(OBJDIR)/cx_vars.o \
      $(OBJDIR)/vera.o

CX_MII_OBJS = \
      $(OBJDIR)/bank.o \
      $(OBJDIR)/bank_assy.o \
		$(OBJDIR)/bank_assy_vars.o \
      $(OBJDIR)/cx-mii.o \
		$(OBJDIR)/decoder.o \
		$(OBJDIR)/meta.o \
		$(OBJDIR)/meta_i.o \
      $(OBJDIR)/petsciitoscr.o \
		$(OBJDIR)/screen.o \
		$(OBJDIR)/utility.o \
		$(OBJDIR)/decoder_vars.o \
		$(OBJDIR)/dispatch_vars.o \
		$(OBJDIR)/encode_vars.o \
		$(OBJDIR)/screen_vars.o \
		$(OBJDIR)/cx_vars.o \
      $(OBJDIR)/vera.o

CX_SYM_OBJS = \
      $(OBJDIR)/bank.o \
      $(OBJDIR)/bank_assy.o \
		$(OBJDIR)/bank_assy_vars.o \
      $(OBJDIR)/cx-sym.o \
		$(OBJDIR)/decoder.o \
		$(OBJDIR)/dispatch.o \
		$(OBJDIR)/meta.o \
		$(OBJDIR)/meta_i.o \
      $(OBJDIR)/petsciitoscr.o \
		$(OBJDIR)/screen.o \
		$(OBJDIR)/utility.o \
		$(OBJDIR)/decoder_vars.o \
		$(OBJDIR)/dispatch_vars.o \
		$(OBJDIR)/encode_vars.o \
		$(OBJDIR)/screen_vars.o \
		$(OBJDIR)/cx_vars.o \
      $(OBJDIR)/vera.o

KSUP_VECS = \
	   $(OBJDIR)/cx_vecs.o \
		$(OBJDIR)/kernsup_cx.o

KSUP_DEFS = -D CPU_65C02=1  -g -D MACHINE_X16=1 --cpu 65SC02

UT_INCS=$(TESTDIR)/assert.s

all: $(BUILD_DIR)/codex.bin cx-dc cx-mii cx-sym utest $(BUILD_DIR)/codex.bin

clean:
	rm -f *.o *.l *.sym *.map *.bin
	rm -f $(CX_OBJS)
	rm -f test/*.o test/*.l

$(BUILD_DIR)/codex.bin: $(CX_SRCS) $(CX_INCS) $(CX_OBJS) $(KSUP_VECS) $(CFG_DIR)/codex-x16.cfg
	ld65 --config $(CFG_DIR)/codex-x16.cfg --mapfile $(BUILD_DIR)/codex.map -Ln $(BUILD_DIR)/codex.sym -o $(BUILD_DIR)/codex.bin $(CX_OBJS) $(KSUP_VECS)

cx-dc: $(CX_DC_SRCS) $(CX_INCS) $(CX_DC_OBJS) $(PLUGIN_OBJS) $(CFG_SUBDIR)/cx-plugin.cfg
	ld65 --config $(CFG_SUBDIR)/cx-plugin.cfg --mapfile cx-dc.map -Ln cx-dc.sym -o cx-dc $(CX_DC_OBJS) $(PLUGIN_OBJS)

cx-mii: $(CX_MII_SRCS) $(CX_INCS) $(CX_MII_OBJS) $(PLUGIN_OBJS) $(CFG_SUBDIR)/cx-plugin.cfg
	ld65 --config $(CFG_SUBDIR)/cx-plugin.cfg --mapfile cx-mii.map -Ln cx-mii.sym -o cx-mii $(CX_MII_OBJS) $(PLUGIN_OBJS) 

cx-sym: $(CX_SYM_SRCS) $(CX_INCS) $(CX_SYM_OBJS) $(PLUGIN_OBJS) $(CFG_SUBDIR)/cx-plugin.cfg
	ld65 --config $(CFG_SUBDIR)/cx-plugin.cfg --mapfile cx-sym.map -Ln cx-sym.sym -o cx-sym $(CX_SYM_OBJS) $(PLUGIN_OBJS) 

$(OBJDIR)/kernsup_cx.o : $(SRCDIR)/kernsup_cx.s
	$(AS) --verbose -I $(ROM_INCLUDE) -I $(KSUP_INCLUDE) $(KSUP_DEFS) --listing $(SRCDIR)/kernsup_cx.l -o $(OBJDIR)/kernsup_cx.o $(SRCDIR)/kernsup_cx.s

utest: $(UT_SRCS) $(CX_INCS) $(UT_INCS) $(CFG_SUBDIR)/utest.cfg $(BOOTSTRAP_OBJS) $(COMMON_OBJS)
	$(AS) -I $(INCDIR) -I $(KINCDIR) test/utest.s -l utest.l
	ld65 --config $(CFG_SUBDIR)/utest.cfg --mapfile utest.map -o utest $(TESTDIR)/utest.o $(BOOTSTRAP_OBJS) $(COMMON_OBJS)

codex.img: cx-dc cx-mii cx-sym
	dd if=/dev/zero of=codex.img bs=1M count=100
	mformat -F -v CODEX -i codex.img ::
	mcopy -i codex.img cx-dc ::
	mcopy -i codex.img cx-sym ::
	mcopy -i codex.img cx-mii ::
	mcopy -i codex.img examples/HW.* ::
	mcopy -i codex.img examples/x16skel.* ::
	mdir -i codex.img ::
