DEBUG = false
DEBUG_FLAGS =
ifeq ($(DEBUG), true)
	DEBUG_FLAGS := -ggdb
endif

TARGET_EXEC = lang
TEST_EXEC = test
BUILD_DIR = build
SRC_DIR = src

ALL_SRCS := $(shell find $(SRC_DIR) -name *.cpp -or -name *.c -or -name *.s)
MAIN_SRCS := $(shell find $(SRC_DIR) \( -not -name test.c \) -and \( -name *.cpp -or -name *.c -or -name *.s \) )
TEST_SRCS := $(shell find $(SRC_DIR) \( -not -name lang.cpp \) -and \( -name *.cpp -or -name *.c -or -name *.s \) )

ALL_OBJS := $(ALL_SRCS:%=$(BUILD_DIR)/%.o)
MAIN_OBJS := $(MAIN_SRCS:%=$(BUILD_DIR)/%.o)
TEST_OBJS := $(TEST_SRCS:%=$(BUILD_DIR)/%.o)

DEPS := $(ALL_OBJS:.o=.d)

#invert comments in 3 lines below to use a dedicated directory for headers
#HEAD_DIRS ?= ./include
INC_DIRS := $(shell find $(SRC_DIR) -type d)
#INC_DIRS := $(shell find $(HEAD_DIRS) -type d)

# Flags
#  -Wall -Werror
CFLAGS = -std=c99 -pedantic -Wall -O3 -march=native -flto -pipe -fstack-protector-strong --param=ssp-buffer-size=4
CXXFLAGS = -march=native -std=c++11 -O3 -flto -pipe -fstack-protector-strong --param=ssp-buffer-size=4 -ferror-limit=100
LDFLAGS = -Wl -O3 -flto -lpthread -ldl -lz -lncurses -rdynamic

#uncomment below if shared library target
#CFLAGS += -shared -undefined dynamic_lookup
INC_FLAGS := $(addprefix -I,$(INC_DIRS))
CPPFLAGS = $(INC_FLAGS) -MMD -MP

# main target
# `llvm-config --libs core jit native --cxxflags --ldflags`
$(BUILD_DIR)/$(TARGET_EXEC): $(MAIN_OBJS)
	$(CXX) $(MAIN_OBJS) -o $@ $(LDFLAGS) $(shell llvm-config --libs --cxxflags --ldflags)

# test target
$(BUILD_DIR)/$(TEST_EXEC): $(TEST_OBJS)
	$(CC) $(TEST_OBJS) -o $@ $(LDFLAGS)

# assembly
$(BUILD_DIR)/%.s.o: %.s
	$(MKDIR_P) $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

# c source
$(BUILD_DIR)/%.c.o: %.c
	$(MKDIR_P) $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(DEBUG_FLAGS) -c $< -o $@

# c++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(shell llvm-config --cxxflags) $(DEBUG_FLAGS) -c $< -o $@

#parser c file and header
$(SRC_DIR)/parser/parser.cpp: $(SRC_DIR)/parser/parser.y
	$(YACC) -d $< -o $@

# parser object file
$(BUILD_DIR)/src/parser/parser.cpp.o: $(SRC_DIR)/parser/parser.cpp
	mkdir -p $(BUILD_DIR)/src/parser
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(shell llvm-config --cxxflags) $(DEBUG_FLAGS) -c $< -o $@

# tokenizer c file and header
$(SRC_DIR)/lexer/tokens.cpp: $(SRC_DIR)/lexer/tokens.l $(SRC_DIR)/parser/parser.cpp
	$(LEX) -o $@ --header-file=$(SRC_DIR)/lexer/tokens.hpp $<

# tokenizer object file
$(BUILD_DIR)/src/lexer/tokens.cpp.o: $(SRC_DIR)/lexer/tokens.cpp
	mkdir -p $(BUILD_DIR)/src/lexer
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(shell llvm-config --cxxflags) $(DEBUG_FLAGS) -c $< -o $(BUILD_DIR)/src/lexer/tokens.cpp.o


.PHONY: clean all test run install uninstall gen

clean:
	$(RM) -r $(BUILD_DIR) src/lexer/tokens.cpp src/lexer/tokens.hpp src/parser/parser.cpp src/parser/parser.hpp

all:	$(BUILD_DIR)/$(TEST_EXEC) $(BUILD_DIR)/$(TARGET_EXEC)

gen: src/parser/parser.cpp src/lexer/tokens.cpp

run: $(BUILD_DIR)/$(TARGET_EXEC)
	$(BUILD_DIR)/$(TARGET_EXEC)

test: $(BUILD_DIR)/$(TEST_EXEC)
	$(BUILD_DIR)/$(TEST_EXEC)

install: $(BUILD_DIR)/$(TARGET_EXEC)
	cp $(BUILD_DIR)/$(TARGET_EXEC) /usr/local/bin/$(TARGET_EXEC)

uninstall:
	rm /usr/local/bin/$(TARGET_EXEC)

-include $(DEPS)

MKDIR_P ?= mkdir -p

