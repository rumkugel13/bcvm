module disassembler;

import std.conv;
import std.array : appender;
import std.conv : to;
import std.bitmanip : peek;
import std.string : format, split;
import opcode, bytecode;

string disassemble(Bytecode bc)
{
    auto data = disassembleData(bc.dataSection);
    auto text = disassemble(bc.textSection);
    return data ~ text;
}

string disassembleData(ubyte[] data)
{
    auto app = appender!string();
    // todo: implement
    return app.opSlice;
}

string disassemble(ubyte[] machinecode)
{
    auto app = appender!string();

    foreach (ref i, ubyte code; machinecode)
    {
        auto op = cast(OpCode) code;
        app.put(makeByteOffsetHex(i) ~ " ");
        app.put(makeOpCodeString(op)); // refactor: print correct assembly text, not opcode from enum

        auto size = immediateOperandSize(op);
        if (size > 0)
        {
            switch (immediateOperandType(op))
            {
            case ImmType.i8:
                app.put(" " ~ makeOperandString!byte(machinecode, i));
                break;
            case ImmType.i16:
                app.put(" " ~ makeOperandString!short(machinecode, i));
                break;
            case ImmType.i32:
                app.put(" " ~ makeOperandString!int(machinecode, i));
                break;
            case ImmType.i64:
                app.put(" " ~ makeOperandString!long(machinecode, i));
                break;
            case ImmType.u8:
                app.put(" " ~ makeOperandString!ubyte(machinecode, i));
                break;
            case ImmType.u16:
                app.put(" " ~ makeOperandString!ushort(machinecode, i));
                break;
            case ImmType.u32:
                app.put(" " ~ makeOperandString!uint(machinecode, i));
                break;
            case ImmType.u64:
                app.put(" " ~ makeOperandString!ulong(machinecode, i));
                break;
            default:
                break;
            }
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
