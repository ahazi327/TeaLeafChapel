CC = chpl
CFLAGS = --fast $(VERBOSE) $(LOCALEINFO)
TARGET_DIR = ./objects
TARGET = $(TARGET_DIR)/tealeaf
TEST_DIR = ./tests
TEST = $(TEST_DIR)/test
MAIN_MODULE = --main-module
TEST_MOD = test

# config params
BLOCK = -s useBlockDist=true
STENCIL = -s useStencilDist=true
VERBOSE = -s verbose=true
LOCALEINFO = -s printLocaleInfo=true

# Collect all the source files with a .chpl extension
SRCS = $(wildcard *.chpl)
TEST_SRC = $(TEST).chpl

# Create the target directory if it doesn't exist
$(shell mkdir -p $(TARGET_DIR))

# Compilation rule for local version
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET_DIR)/tealeaflocal $(SRCS)

# Compile the block distribution version
block: $(SRCS)
	$(CC) $(CFLAGS) $(BLOCK) -o $(TARGET_DIR)/tealeafblock $(SRCS)

# Compile the stencil distribution version
stencil: $(SRCS)
	$(CC) $(CFLAGS) $(STENCIL) -o $(TARGET_DIR)/tealeafstencil $(SRCS)
	
# Test rule
test: $(TEST_SRC)
	$(CC) $(CFLAGS) $(MAIN_MODULE) $(TEST_MOD) -o $(TEST) $(TEST_SRC)
	$(TEST)

# Record/report rule
report: $(TARGET)
	perf record $(TARGET)
	perf report

# Clean rule
clean:
	rm -f $(TARGET) $(TEST)
