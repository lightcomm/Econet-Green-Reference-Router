####################################################
# Makefile to compile java source code for the GUI
#
# Author: Jad Naous
#


# Directories
SRC := src
BIN := bin
LIB := lib

COMMON_C := ../../../../lib/C/common
REG_C := ../../../../projects/ref_router_r_limiter/lib/C 

NF2LIB_NAME := libnf2.so

JAVAC := javac
JAVA := java
JAR := jar

JAVA_SRC_FILES := $(wildcard $(SRC)/org/netfpga/backend/*.java)
JAVA_SRC_FILES += $(wildcard $(SRC)/org/netfpga/graphics/*.java)
JAVA_SRC_FILES += $(wildcard $(SRC)/org/netfpga/mdi/*.java)
JAVA_SRC_FILES += $(wildcard $(SRC)/org/netfpga/router/*.java)

CONSTANTS_JAVA := $(SRC)/org/netfpga/backend/NFDeviceConsts.java

NF2LIB := $(LIB)/$(NF2LIB_NAME)

# utils
EMPTY =
SPACE = $(EMPTY) $(EMPTY)

# setup the classpath
CLASSPATH := $(subst $(SPACE),:,$(wildcard $(LIB)/*.jar))

# compiler options
JAVAC_OPTIONS := -d $(BIN) -classpath $(CLASSPATH) -sourcepath $(SRC)

# rules
all: registers $(NF2LIB) $(CONSTANTS_JAVA) router.sh 

# registers
registers:
	$(NF2_ROOT)/bin/nf2_register_gen.pl --project router_buffer_sizing
	ln -f -s ../../lib/C/reg_defines_ref_router_r_limiter.h reg_defines.h


$(NF2LIB): $(COMMON_C)/$(NF2LIB_NAME)
	@cp $< $@

$(COMMON_C)/$(NF2LIB_NAME):
	@$(MAKE) -C $(dir $@) $(notdir $@)

java: $(CONSTANTS_JAVA) $(JAVA_SRC_FILES)
	@echo Building java...
	@$(JAVAC) $(JAVAC_OPTIONS) $(JAVA_SRC_FILES)
	@echo Done

$(CONSTANTS_JAVA): reg_defines.h
	@echo "/**********************************************************************" > $@
	@echo " * File generated using the Makefile from $<." >> $@
	@echo " * Author: Jad Naous" >> $@
	@echo " */" >> $@
	@echo "" >> $@
	@echo "package $(patsubst %.,%;,$(subst /,.,$(subst $(SRC)/,$(EMPTY),$(dir $@))))" >> $@
	@echo "" >> $@
	@echo "public class $(notdir $(basename $@)) {" >> $@
	@awk '(NF == 3) && ($$1 == "#define") && (length($$3) < 11) {printf "   public static final int %-50s = %s;\n", $$2, $$3}' $< >> $@
	@echo "}" >> $@
	@echo "" >> $@

$(BIN)/router-manifest.mf:
	@echo "Writing router gui manifest..."
	@echo "Main-Class: org.netfpga.router.RouterMainFrame" > $@
	@echo "Class-Path: $(wildcard $(LIB)/*.jar)" >> $@	
	@echo >> $@

router_gui.jar: $(NF2LIB) java $(BIN)/router-manifest.mf
	@echo "Building router jar..."
	@cd $(BIN); $(JAR) cfm ../$@ router-manifest.mf org
	@rm -f $(BIN)/router-manifest.mf

router.sh: router_gui.jar
	@echo "Writing script to start router gui..."
	@echo "$(JAVA) -Djava.library.path=$(LIB) -Djna.library.path=$(LIB) -jar router_gui.jar --no_download" > $@
	@echo >> $@
	@chmod +x $@

install:

clean: 
	@rm -rf $(COMMON_C)/$(NF2LIB_NAME) 
	@rm -rf $(BIN)/* router_gui.jar router.sh
	@rm -rf $(CONSTANTS_JAVA)
	@rm -rf $(NF2LIB)
