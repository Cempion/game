
# Compiler and flags
AS = gcc
ASFLAGS = -I src -I src/wfc -I src/wfc/data -g

# Source files and output
SRC = src/main.s src/wfc/wfc.s
OUT = build

# Rule to build the executable
$(OUT): $(SRC)
	$(AS) $(ASFLAGS) -o $(OUT) $(SRC) -lopengl32 -lgdi32

# Clean rule to remove the compiled output
clean:
	rm -f $(OUT)