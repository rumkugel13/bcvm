module alu;

import memory, opcode;

struct ExecutionUnit
{
    StackUnit operands, callStack, frameStack;
    MemoryUnit globals, locals;
    ubyte[] instructions;
    size_t instructionPointer = 0;
    int exitCode = 0;
    bool isRunning = true;

    public void run()
    {
        while (isRunning && instructionPointer < instructions.length)
        {
            ubyte opCode = instructions[instructionPointer];
            instructionPointer++;

            switch (opCode)
            {
            case OpCode.imm_i8:
                imm!byte();
                break;
            case OpCode.imm_i16:
                imm!short();
                break;
            case OpCode.imm_i32:
                imm!int();
                break;
            case OpCode.imm_i64:
                imm!long();
                break;

            case OpCode.drop_i8:
                drop!byte();
                break;
            case OpCode.drop_i16:
                drop!short();
                break;
            case OpCode.drop_i32:
                drop!int();
                break;
            case OpCode.drop_i64:
                drop!long();
                break;

            case OpCode.call_abs_i32:
                call!int();
                break;
            case OpCode.ret:
                ret();
                break;

            case OpCode.store_i32_i32:
                store!(int, int)();
                break;
            case OpCode.load_i32_i32:
                load!(int, int)();
                break;
            case OpCode.store_global_i32_i32:
                store_global!(int, int)();
                break;
            case OpCode.load_global_i32_i32:
                load_global!(int, int)();
                break;
            case OpCode.dup_i32:
                dup!int();
                break;

            case OpCode.cmp_lt_i32:
                cmp_lt!int();
                break;
            case OpCode.cmp_gt_i32:
                cmp_gt!int();
                break;
            case OpCode.cmp_le_i32:
                cmp_le!int();
                break;
            case OpCode.cmp_ge_i32:
                cmp_ge!int();
                break;
            case OpCode.cmp_eq_i32:
                cmp_eq!int();
                break;
            case OpCode.cmp_neq_i32:
                cmp_neq!int();
                break;
            case OpCode.cmp_ze_i32:
                cmp_ze!int();
                break;
            case OpCode.cmp_nze_i32:
                cmp_nze!int();
                break;

            case OpCode.log_and_i32:
                log_and!int();
                break;
            case OpCode.log_or_i32:
                log_or!int();
                break;
            case OpCode.log_not_i32:
                log_not!int();
                break;

            case OpCode.jmp_nz_i32_abs_i32:
                jmp_nz_abs!(int, int)();
                break;
            case OpCode.jmp_z_i32_abs_i32:
                jmp_z_abs!(int, int)();
                break;
            case OpCode.jmp_abs_i32:
                jmp_abs!(int)();
                break;

            case OpCode.ext_i8_i32:
                ext!(byte, int)();
                break;

            case OpCode.add_i32:
                add!int();
                // const string[] ops = ["+"];
                // binOp!(ops[0], int)();
                break;
            case OpCode.sub_i32:
                sub!int();
                break;
            case OpCode.mul_i32:
                mul!int();
                break;
            case OpCode.div_i32:
                div!int();
                break;
            case OpCode.rem_i32:
                rem!int();
                break;
            case OpCode.mod_i32:
                mod!int();
                break;
            case OpCode.shl_i32:
                shl!int();
                break;
            case OpCode.shr_i32:
                shr!int();
                break;
            case OpCode.sar_i32:
                sar!int();
                break;
            case OpCode.and_i32:
                and!int();
                break;
            case OpCode.or_i32:
                or!int();
                break;
            case OpCode.xor_i32:
                xor!int();
                break;
            case OpCode.neg_i32:
                neg!int();
                break;
            case OpCode.not_i32:
                not!int();
                break;

            case OpCode.pow_i32:
                pow!int();
                break;
            case OpCode.min_i32:
                min!int();
                break;
            case OpCode.max_i32:
                max!int();
                break;

            case OpCode.mul_u32:
                mul!uint();
                break;
            case OpCode.div_u32:
                div!uint();
                break;
            case OpCode.rem_u32:
                rem!uint();
                break;

            case OpCode.inc_i32:
                inc!int();
                break;
            case OpCode.dec_i32:
                dec!int();
                break;

            case OpCode.exit:
                exit!int(); // refactor: assume we return int as return code
                break;
            case OpCode.no_op:
                break;
            default:
                assert(false, "Unknown / Not implemented Instruction: " ~ opCode);
            }

            // debugPrint("SP: ", operands.stackPointer, " FP: ", operands.framePointer);
        }
    }

    private void imm(T)()
    {
        assert(instructionPointer + T.sizeof < instructions.length);
        operands.pushRaw(instructions[instructionPointer .. instructionPointer + T.sizeof]);
        instructionPointer += T.sizeof;
        debugPrint("Imm: ", operands.peek!T());
    }

    private void drop(T)()
    {
        auto a = operands.pop!T();
        debugPrint("Drop: ", a);
    }

    private void call(T)()
    {
        auto addr = readImmediateOperand!T();
        uint ret = cast(uint) instructionPointer;
        callStack.push!uint(ret); // refactor: use u32 for values for now
        frameStack.push!uint(cast(uint)locals.usedBytes);
        assert(addr < instructions.length);
        instructionPointer = addr; // refactor: absolute value for now
        debugPrint("Call: ", addr);
    }

    private void ret()
    {
        if (callStack.stackPointer > 0)
        {
            uint addr = callStack.pop!uint();
            uint frame = frameStack.pop!uint();
            locals.usedBytes = frame;
            instructionPointer = addr;
            debugPrint("Ret: ", addr, ", ", operands.peek!int());
        }
        else
        {
            debugPrint("Ret: ");
            exit!int(); // refactor: ditto
        }
    }

    private void store(T, U)()
    {
        auto addr = readImmediateOperand!U();
        auto a = operands.pop!T();
        auto offset = frameStack.stackPointer > 0 ? frameStack.peek!uint() : 0;
        locals.store!T(a, addr + offset);
        debugPrint("Store: ", a, " at ", addr, " in frame ", callStack.stackPointer / uint.sizeof);
    }

    private void load(T, U)()
    {
        auto addr = readImmediateOperand!U();
        auto offset = frameStack.stackPointer > 0 ? frameStack.peek!uint() : 0;
        auto a = locals.load!T(addr + offset);
        operands.push!T(a);
        debugPrint("Load: ", a, " from ", addr, " in frame ", callStack.stackPointer / uint.sizeof);
    }

    private void store_global(T, U)()
    {
        auto addr = readImmediateOperand!U();
        auto a = operands.pop!T();
        globals.store!T(a, addr);
        debugPrint("Store_global: ", a, " at ", addr);
    }

    private void load_global(T, U)()
    {
        auto addr = readImmediateOperand!U();
        auto a = globals.load!T(addr);
        operands.push!T(a);
        debugPrint("Load_global: ", a, " from ", addr);
    }

    private void dup(T)()
    {
        operands.push!T(operands.peek!T());
        debugPrint("Dup: ", operands.peek!T());
    }

    private void cmp_lt(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a < b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " < ", b, " = ", operands.peek!T());
    }

    private void cmp_gt(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a > b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " > ", b, " = ", operands.peek!T());
    }

    private void cmp_le(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a <= b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " <= ", b, " = ", operands.peek!T());
    }

    private void cmp_ge(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a >= b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " >= ", b, " = ", operands.peek!T());
    }

    private void cmp_eq(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a == b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " == ", b, " = ", operands.peek!T());
    }

    private void cmp_neq(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a != b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " != ", b, " = ", operands.peek!T());
    }

    private void cmp_ze(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(a == 0); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " == 0 =", operands.peek!T());
    }

    private void cmp_nze(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(a != 0); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Cmp: ", a, " != 0 =", operands.peek!T());
    }

    private void log_and(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a && b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Log_and: ", a, " && ", b, " = ", operands.peek!T());
    }

    private void log_or(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a || b); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Log_or: ", a, " || ", b, " = ", operands.peek!T());
    }

    private void log_not(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(!a); // refactor: should we only push 1 byte here? since result is 0 or 1
        debugPrint("Log_not: !", a, " = ", operands.peek!T());
    }

    private void jmp_nz_abs(T, U)() // T is operand on stack, U is immediate operand in bytecode
    {
        auto a = operands.pop!T();
        auto jump = a != 0;

        auto addr = readImmediateOperand!U(); // increases instructionpointer by amount of bytes in T
        assert(addr < instructions.length);
        if (jump)
            instructionPointer = addr;
        debugPrint("Jmp_nz: ", jump, " ", addr);
    }

    private void jmp_z_abs(T, U)() // T is operand on stack, U is immediate operand in bytecode
    {
        auto a = operands.pop!T();
        auto jump = a == 0;

        auto addr = readImmediateOperand!U(); // increases instructionpointer by amount of bytes in T
        assert(addr < instructions.length);
        if (jump)
            instructionPointer = addr;
        debugPrint("Jmp_nz: ", jump, " ", addr);
    }

    private void jmp_abs(U)() // U is immediate operand in bytecode
    {
        auto addr = readImmediateOperand!U();
        assert(addr < instructions.length);
        instructionPointer = addr;
        debugPrint("Jmp: ", addr);
    }

    private void ext(T, U)()
    {
        assert(T.sizeof <= U.sizeof);
        operands.push!U(operands.pop!T());
        debugPrint("Ext: ", T.sizeof * 8, " ", U.sizeof * 8);
    }

    private void binOp(string op, T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(mixin("a " ~ op ~ " b"));
        debugPrint("BinOp: ", a, " ", op, " ", b, " = ", operands.peek!T());
    }

    private void add(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a + b);
        debugPrint("Add: ", a, " + ", b, " = ", operands.peek!T());
    }

    private void sub(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a - b);
        debugPrint("Sub: ", a, " - ", b, " = ", operands.peek!T());
    }

    private void mul(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a * b);
        debugPrint("Mul: ", a, " * ", b, " = ", operands.peek!T());
    }

    private void div(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a / b);
        debugPrint("Div: ", a, " / ", b, " = ", operands.peek!T());
    }

    private void rem(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a % b);
        debugPrint("Rem: ", a, " % ", b, " = ", operands.peek!T());
    }

    private void mod(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(((a % b) + b) % b);
        debugPrint("Mod: ", a, " mod ", b, " = ", operands.peek!T());
    }

    private void shl(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a << b);
        debugPrint("Shl: ", a, " << ", b, " = ", operands.peek!T());
    }

    private void shr(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a >> b);
        debugPrint("Shr: ", a, " >> ", b, " = ", operands.peek!T());
    }

    private void sar(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a >>> b);
        debugPrint("Sar: ", a, " >>> ", b, " = ", operands.peek!T());
    }

    private void and(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a & b);
        debugPrint("And: ", a, " & ", b, " = ", operands.peek!T());
    }

    private void or(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a | b);
        debugPrint("Or: ", a, " | ", b, " = ", operands.peek!T());
    }

    private void xor(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a ^ b);
        debugPrint("Xor: ", a, " ^ ", b, " = ", operands.peek!T());
    }

    private void pow(T)()
    {
        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(a ^^ b);
        debugPrint("Pow: ", a, " ^^ ", b, " = ", operands.peek!T());
    }

    private void min(T)()
    {
        import std.algorithm : min;

        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(min(a, b));
        debugPrint("Min: ", a, " <? ", b, " = ", operands.peek!T());
    }

    private void max(T)()
    {
        import std.algorithm : max;

        auto b = operands.pop!T();
        auto a = operands.pop!T();
        operands.push!T(max(a, b));
        debugPrint("Max: ", a, " >? ", b, " = ", operands.peek!T());
    }

    private void neg(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(-a);
        debugPrint("Neg: -", a, " = ", operands.peek!T());
    }

    private void not(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(~a);
        debugPrint("Comp: ~", a, " = ", operands.peek!T());
    }

    private void inc(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(a + 1);
        debugPrint("Inc: ", a, " + 1 = ", operands.peek!T());
    }

    private void dec(T)()
    {
        auto a = operands.pop!T();
        operands.push!T(a - 1);
        debugPrint("Dec: ", a, " - 1 = ", operands.peek!T());
    }

    private void exit(T)()
    {
        exitCode = operands.pop!T();
        isRunning = false;
        debugPrint("Exit: ", exitCode);
    }

    private T readImmediateOperand(T)()
    {
        auto op = peekImmediateOperand!T();
        instructionPointer += T.sizeof;
        return op;
    }

    private T peekImmediateOperand(T)()
    {
        import std.bitmanip : peek;

        assert(instructionPointer + T.sizeof < instructions.length);
        return instructions[instructionPointer .. instructionPointer + T.sizeof].peek!T(0);
    }

    private void debugPrint(T...)(T args)
    {
        import std.stdio : writeln;

        version (unittest)
        {
        }
        else
            debug writeln(args);
    }
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 32,
        OpCode.imm_i32, 0, 0, 0, 64,
        OpCode.add_i32,
        OpCode.imm_i32, 0, 0, 13, 37,
        OpCode.sub_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == -3269);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 32,
        OpCode.imm_i32, 0, 0, 0, 64,
        OpCode.add_i32,
        OpCode.imm_i8, 37,
        OpCode.ext_i8_i32,
        OpCode.sub_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 59);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 32,
        OpCode.imm_i32, 0, 0, 0, 64,
        OpCode.add_i32,
        OpCode.imm_i32, 0, 0, 0, 37,
        OpCode.sub_i32,
        OpCode.inc_i32,
        OpCode.dup_i32,
        OpCode.imm_i32, 0, 0, 0, 75,
        OpCode.cmp_lt_i32,
        OpCode.jmp_nz_i32_abs_i32, 0, 0, 0, 17,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 75);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 32,
        OpCode.rem_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 23);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 3,
        OpCode.shl_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 440);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 3,
        OpCode.shr_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 6);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 30,
        OpCode.and_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 22);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 30,
        OpCode.or_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 63);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 30,
        OpCode.xor_i32,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 41);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.imm_i32, 0, 0, 0, 30,
        OpCode.store_i32_i32, 0, 0, 0, 4,
        OpCode.store_i32_i32, 0, 0, 0, 0,
        OpCode.load_i32_i32, 0, 0, 0, 0,
        OpCode.load_i32_i32, 0, 0, 0, 4,
        OpCode.add_i32,
        OpCode.store_i32_i32, 0, 0, 0, 0,
        OpCode.load_i32_i32, 0, 0, 0, 0,
        OpCode.exit
    ];
    alu.run();
    assert(alu.exitCode == 85);
}

unittest
{
    ExecutionUnit alu;
    alu.instructions = [
        OpCode.imm_i32, 0, 0, 0, 55,
        OpCode.store_i32_i32, 0, 0, 0, 0,
        OpCode.imm_i32, 0, 0, 0, 30,
        OpCode.store_i32_i32, 0, 0, 0, 4,
        OpCode.load_i32_i32, 0, 0, 0, 4,
        OpCode.load_i32_i32, 0, 0, 0, 0,
        OpCode.call_abs_i32, 0, 0, 0, 36,
        OpCode.ret,
        OpCode.store_i32_i32, 0, 0, 0, 0,
        OpCode.store_i32_i32, 0, 0, 0, 4,
        OpCode.load_i32_i32, 0, 0, 0, 0,
        OpCode.load_i32_i32, 0, 0, 0, 4,
        OpCode.sub_i32,
        OpCode.ret,
    ];
    alu.run();
    assert(alu.exitCode == 25);
}

auto makeFibRec(int n = 10)
{
    import std.conv : to;
    import assembler;

    string fib = ":main
    immi "
        ~ to!string(n) ~ "
    call fibonacci
    ret
    :fibonacci
    storei 0
    loadi 0
    immi 1
    cmp_gt      #if (n <= 1) ret n
    jmp_nz L1
    loadi 0
    ret
    :L1
    loadi 0
    deci
    call fibonacci
    loadi 0
    deci 
    deci
    call fibonacci
    addi
    ret";

    auto fibass = assemble(fib);
    ExecutionUnit fibalu;
    fibalu.instructions = fibass;
    return fibalu;
}

auto makeFibLoop(int n = 10)
{
    import std.conv : to;
    import assembler;

    string fib = ":main
    immi 0
    storei 0
    immi 1
    storei 4
    loadi 0
    loadi 4
    addi
    storei 8
    immi "
        ~ to!string(n) ~ "
    storei 12
    loadi 12
    immi 1
    cmp_gt      #if (n <= 1) ret n
    jmp_nz LOOP
    loadi 12
    ret
    :LOOP
    loadi 12
    immi 3
    cmp_ge
    jmp_z END
    loadi 4
    storei 0
    loadi 8
    storei 4
    loadi 0
    loadi 4
    addi
    storei 8
    loadi 12
    deci
    storei 12
    jmp LOOP
    :END
    loadi 8
    ret";

    auto fibass = assemble(fib);
    ExecutionUnit fibalu;
    fibalu.instructions = fibass;
    return fibalu;
}

unittest
{
    import std.conv : to;

    ExecutionUnit fibalu = makeFibRec();
    fibalu.run();
    assert(fibalu.exitCode == 55, "Expected: " ~ 55.to!string ~ " Actual: " ~ fibalu
            .exitCode.to!string);
}

unittest
{
    import std.conv : to;

    ExecutionUnit fibalu = makeFibLoop();
    fibalu.run();
    assert(fibalu.exitCode == 55, "Expected: " ~ 55.to!string ~ " Actual: " ~ fibalu
            .exitCode.to!string);
}

unittest
{
    import std.datetime.stopwatch : benchmark;
    import std.stdio;

    const auto n = 10;
    void f1()
    {
        makeFibRec(n).run();
    }

    void f2()
    {
        makeFibLoop(n).run();
    }

    const auto number = 1_000;
    auto times = benchmark!(f1, f2)(number);
    writeln("Fibonacci(", n, ") ", number, " times:");
    writeln("FibRec: ", times[0].total!"msecs", "ms");
    writeln("FibLoop: ", times[1].total!"msecs", "ms");
}
