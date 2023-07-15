module assembler;

import std.bitmanip : write;
import std.string : split, splitLines, strip, startsWith, empty;
import std.algorithm : map;
import std.range : array;
import std.stdio : writeln;
import std.conv : to;
import std.array : appender;
import opcode;

ubyte[] assemble(string assembly)
{
    auto app = appender!(ubyte[])();
    long[string] labelMap;
    string[long] missingAddressMap;

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

    foreach (line; assembly.splitLines())
    {
        line = line.strip();
        if (line.empty)
        {
            continue;
        }
        else if (line.startsWith(":"))
        {
            labelMap[line[1 .. $]] = app.opSlice.length;
        }
        else if (line.startsWith("."))
        {
            assert(false, "Not implemented");
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

    return app.opSlice;
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