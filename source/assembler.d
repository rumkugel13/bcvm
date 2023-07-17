module assembler;

import std.bitmanip : write;
import std.string : split, splitLines, strip, startsWith, empty, isNumeric;
import std.algorithm : map;
import std.range : array;
import std.stdio : writeln;
import std.conv : to;
import std.array : appender;
import opcode, bytecode;

Bytecode assemble(string assembly)
{
    auto app = appender!(ubyte[])();
    auto dataAppender = appender!(ubyte[])();
    long[string] labelMap;
    string[long] missingAddressMap;
    Section section = Section.Text;

    void putOpWithLabel(T)(OpCode op, string label)
    {
        if (label in labelMap)
        {
            app.put(makeOpWithImm(op, to!T(labelMap[label])));
        }
        else
        {
            missingAddressMap[app.opSlice.length + 1] = label;
            labelMap[label] = 0; // mark as not found
            app.put(makeOpWithImm(op, 0));
        }
    }

    // refactor: use proper parser?
    foreach (line; assembly.splitLines())
    {
        line = line.strip();
        if (line.empty)
        {
            continue;
        }
        else if (line.startsWith(":"))
        {
            if (section == Section.Text)
                labelMap[line[1 .. $]] = app.opSlice.length;
            else
                labelMap[line[1 .. $]] = dataAppender.opSlice.length;
        }
        else if (line.startsWith("."))
        {
            auto parts = line.split();
            auto directive = parts[0];
            auto operand = parts.length > 1 ? parts[1] : "";

            switch (directive)
            {
            case ".data":
                section = Section.Data;
                break;
            case ".text":
                section = Section.Text;
                break;
            case ".int":
                dataAppender.put(makeImm(to!int(operand)));
                break;
            default:
                assert(false, "Unknown section/directive " ~ line);
            }
        }
        else
        {
            auto parts = line.split();
            auto op = parts[0];
            auto operand = parts.length > 1 ? parts[1] : "";

            switch (op)
            {
            case "immi":
                app.put(makeOpWithImm(OpCode.imm_i32, to!int(operand)));
                break;
            case "immb":
                app.put(makeOpWithImm(OpCode.imm_i8, to!byte(operand)));
                break;
            case "storei":
                app.put(makeOpWithImm(OpCode.store_i32_i32, to!int(operand)));
                break;
            case "loadi":
                app.put(makeOpWithImm(OpCode.load_i32_i32, to!int(operand)));
                break;
            case "storegi":
                if (operand.isNumeric)
                    app.put(makeOpWithImm(OpCode.store_global_i32_i32, to!int(operand)));
                else
                    putOpWithLabel!int(OpCode.store_global_i32_i32, operand);
                break;
            case "loadgi":
                if (operand.isNumeric)
                    app.put(makeOpWithImm(OpCode.load_global_i32_i32, to!int(operand)));
                else
                    putOpWithLabel!int(OpCode.load_global_i32_i32, operand);
                break;
            case "call":
                putOpWithLabel!int(OpCode.call_abs_i32, operand);
                break;
            case "jmp_nz":
                putOpWithLabel!int(OpCode.jmp_nz_i32_abs_i32, operand);
                break;
            case "jmp_z":
                putOpWithLabel!int(OpCode.jmp_z_i32_abs_i32, operand);
                break;
            case "jmp":
                putOpWithLabel!int(OpCode.jmp_abs_i32, operand);
                break;
            case "cmp_gt":
                app.put(makeOp(OpCode.cmp_gt_i32));
                break;
            case "cmp_ge":
                app.put(makeOp(OpCode.cmp_ge_i32));
                break;
            case "addi":
                app.put(makeOp(OpCode.add_i32));
                break;
            case "b2i":
                app.put(makeOp(OpCode.ext_i8_i32));
                break;
            case "subi":
                app.put(makeOp(OpCode.sub_i32));
                break;
            case "deci":
                app.put(makeOp(OpCode.dec_i32));
                break;
            case "ret":
                app.put(makeOp(OpCode.ret));
                break;
            default:
                assert(false, "Unknown / Not Implemented instruction: " ~ op);
            }
        }
    }

    foreach (offset, value; missingAddressMap)
    {
        if (value !in labelMap)
            assert(false, "Function/Jumplabel " ~ value ~ " not found");
        else
        {
            app.opSlice[offset .. offset + int.sizeof] = makeImm!int(cast(int) labelMap[value]);
        }
    }

    Bytecode bc;
    bc.textSection = app.opSlice;
    bc.dataSection = dataAppender.opSlice;
    return bc;
}

auto makeOp(OpCode op)
{
    return op;
}

auto makeOpWithImm(T)(OpCode op, T num)
{
    ubyte[] data = new ubyte[1 + T.sizeof];
    data[0] = op;
    data.write!T(num, 1);
    return data;
}

auto makeImm(T)(T num)
{
    ubyte[] data = new ubyte[T.sizeof];
    data.write!T(num, 0);
    return data;
}

unittest
{
    string program = ".data
    :someNumber
    .int 33
    .text
    :main
    immi 66
    loadgi 0
    addi
    ret";

    auto bc = assemble(program);

    import alu;

    ExecutionUnit e;
    e.loadBytecode(bc);
    e.run();
    assert(e.exitCode == 99);
}

unittest
{
    string program = ".data
    :someNumber
    .int 33
    .text
    :main
    immi 66
    loadgi someNumber
    addi
    ret";

    auto bc = assemble(program);

    import alu;

    ExecutionUnit e;
    e.loadBytecode(bc);
    e.run();
    assert(e.exitCode == 99);
}

unittest
{
    string program = ".data
    :someNumber
    .int 33
    :someOther
    .int 44
    .text
    :main
    loadgi someOther
    loadgi someNumber
    addi
    storegi someNumber
    loadgi someNumber
    ret";

    auto bc = assemble(program);

    import alu;

    ExecutionUnit e;
    e.loadBytecode(bc);
    e.run();
    assert(e.exitCode == 77);
}
