# bcvm
An experimental/toy bytecode interpreter including assembler/disassembler

## About
Bytecode Interpreter mainly built as a backend for [mcc](https://github.com/rumkugel13/mcc), as an alternative to the builtin AST interpreter.

Uses a stack-based vm to execute the instructions. See [source/opcode.d](source/opcode.d) for currently supported instructions, mostly for int/i32 manipulation for now.
