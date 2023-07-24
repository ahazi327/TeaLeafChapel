CC = chpl
CFLAGS = --fast --debug
TARGET = tealeaf
TEST = ./tests/test
MAIN_MODULE = --main-module
TEST_MOD = test
MULTI = 4 # Number of locales to use 

# Collect all the source files with a .chpl extension
SRCS = $(wildcard *.chpl)
TEST_SRC = $(TEST).chpl

# Compilation rule
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

# Compile without running
comp: $(TARGET)

# Run rule
run: $(TARGET)
	./$(TARGET) 

# Test rule
test: $(TEST_SRC)
	$(CC) $(CFLAGS) $(MAIN_MODULE) $(TEST_MOD) -o $(TEST) $(TEST_SRC)
	./$(TEST)

# Record/report rule
report: $(TARGET)
	perf record ./$(TARGET) 
	perf report

# Clean rule
clean:
	rm -f $(TARGET) $(TEST)
