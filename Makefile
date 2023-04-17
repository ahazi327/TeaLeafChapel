CC = chpl
CFLAGS = --fast --static --debug
TARGET = tealeaf

# Collect all the source files with a .chpl extension
SRCS = $(wildcard *.chpl)

# Compilation rule
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

# Run rule
run: $(TARGET)
	./$(TARGET)

# Clean rule
clean:
	rm -f $(TARGET)