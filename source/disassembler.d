module disassembler;

import std.conv;
import std.array : appender;
import std.conv : to;
import std.bitmanip : peek;
import std.string : format, split;
import opcode;

string disassemble(ubyte[] machinecode)
{
    auto app = appender!string();

    foreach (ref i, ubyte code; machinecode)
    {
        auto op = cast(OpCode) code;
        app.put(makeByteOffsetHex(i) ~ " ");
        app.put(makeOpCodeString(op)); // refactor: print correct assembly text, not opcode from enum

        // auto size = immediateOperandSize(op);
        // if (size > 0)
        // {

        // }

        with (OpCode) switch (op)
        {
        case imm_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case imm_i8:
            app.put(" " ~ makeOperandString!byte(machinecode, i));
            break;
        case load_i32_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case store_i32_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case call_abs_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case jmp_nz_i32_abs_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case jmp_z_i32_abs_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        case jmp_abs_i32:
            app.put(" " ~ makeOperandString!int(machinecode, i));
            break;
        default:
            break;
        }
        app.put("\n");
    }

    return app.opSlice();
}

string makeByteOffsetDec(size_t offset)
{
    return format("%04d", offset);
}

string makeByteOffsetHex(size_t offset)
{
    return format("0x%04X", offset);
}

string makeOpCodeString(OpCode op)
{
    return to!string(op);
}

string makeOperandString(T)(ubyte[] machinecode, ref size_t offset)
{
    auto str = to!string(machinecode.peek!T(offset + 1));
    offset += T.sizeof;
    return str;
}
