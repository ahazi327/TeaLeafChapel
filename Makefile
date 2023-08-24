CC = chpl
CFLAGS = --fast --debug
TARGET_DIR = ./objects
TARGET = $(TARGET_DIR)/tealeaf
TEST_DIR = ./tests
TEST = $(TEST_DIR)/test
MAIN_MODULE = --main-module
TEST_MOD = test
MULTI = 4 # Number of locales to use 

# Collect all the source files with a .chpl extension
SRCS = $(wildcard *.chpl)
TEST_SRC = $(TEST).chpl

# Create the target directory if it doesn't exist
$(shell mkdir -p $(TARGET_DIR))

# Compilation rule
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

# Compile without running
comp: $(TARGET)

# Run rule
run: $(TARGET)
	$(TARGET)

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
