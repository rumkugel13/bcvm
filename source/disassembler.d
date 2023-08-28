module disassembler;

import std.conv;
import std.array : appender;
import std.conv : to;
import std.bitmanip : peek;
import std.string : format, split;
import opcode, bytecode;

string disassemble(Bytecode bc)
{
    auto data = disassembleData(bc.dataSection, bc.metaDataSection);
    auto text = disassemble(bc.textSection);
    return data ~ text;
}

string disassembleData(ubyte[] data, ubyte[] metadata)
{
    auto app = appender!string();
    auto dataIndex = 0;

    app.put("Data Section\n");

    foreach (meta; metadata)
    {
        app.put(makeByteOffsetHex(dataIndex));
        app.put(" ");
        Datatype type = cast(Datatype)meta;
        app.put(type.to!string());
        app.put(": ");
        switch (type)
        {
            case Datatype.i8: 
                app.put(to!string(data.peek!byte(dataIndex)));
                dataIndex += 1;
                break;
            case Datatype.i16: 
                app.put(to!string(data.peek!short(dataIndex)));
                dataIndex += 2;
                break;
            case Datatype.i32: 
                app.put(to!string(data.peek!int(dataIndex)));
                dataIndex += 4;
                break;
            case Datatype.i64: 
                app.put(to!string(data.peek!long(dataIndex)));
                dataIndex += 8;
                break;
            case Datatype.u8: 
                app.put(to!string(data.peek!ubyte(dataIndex)));
                dataIndex += 1;
                break;
            case Datatype.u16: 
                app.put(to!string(data.peek!ushort(dataIndex)));
                dataIndex += 2;
                break;
            case Datatype.u32: 
                app.put(to!string(data.peek!uint(dataIndex)));
                dataIndex += 4;
                break;
            case Datatype.u64: 
                app.put(to!string(data.peek!ulong(dataIndex)));
                dataIndex += 8;
                break;
            case Datatype.f32: 
                app.put(to!string(data.peek!float(dataIndex)));
                dataIndex += 4;
                break;
            case Datatype.f64: 
                app.put(to!string(data.peek!double(dataIndex)));
                dataIndex += 8;
                break;
            default: throw new Exception("Unknown datatype: " ~ meta);
        }

        app.put("\n");
    }

    return app.opSlice;
}

string disassemble(ubyte[] machinecode)
{
    auto app = appender!string();

    app.put("Text Section\n");

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

    import assembler, std.stdio;
    auto bc = assemble(program);
    auto disassembly = disassemble(bc);
    writeln(disassembly);
    stdout.flush();
}