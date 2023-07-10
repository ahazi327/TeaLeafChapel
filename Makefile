CC = chpl
CFLAGS = --fast --debug
TARGET = tealeaf
TEST = test
MAIN_MODULE = --main-module

# Collect all the source files with a .chpl extension
SRCS = $(wildcard *.chpl)
TEST_SRC = $(TEST).chpl

# Compilation rule
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

# Run rule
run: $(TARGET)
	./$(TARGET)

# Test rule
test: $(TEST_SRC)
	$(CC) $(CFLAGS) $(MAIN_MODULE) $(TEST) -o $(TEST) $(TEST_SRC)
	./$(TEST)

# Record/report rule
report: $(TARGET)
	perf record ./$(TARGET) 
	perf report

# Clean rule
clean:
	rm -f $(TARGET) $(TEST)
