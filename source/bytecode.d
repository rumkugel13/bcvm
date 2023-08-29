module bytecode;

import std.stdio : File;
import std.bitmanip : peek, write;

enum Section
{
    Text,
    Data,
    BSS
}

enum Datatype : ubyte
{
    i8,
    i16,
    i32,
    i64,
    u8,
    u16,
    u32,
    u64,
    f32,
    f64
}

size_t immediateDataSize(Datatype type)
{
    import std.conv: to;
    return type.to!string()[1..$].to!ubyte()/8;
}

struct Bytecode
{
    ubyte[] textSection, dataSection, metaDataSection;
    size_t mainAddress;

    void serialize(string filePath)
    {
        File file = File(filePath, "wb");
        file.rawWrite("bcvm");

        ubyte[] buf = new ubyte[4];
        buf.write!uint(cast(uint) metaDataSection.length, 0);
        file.rawWrite(buf);
        buf.write!uint(cast(uint) dataSection.length, 0);
        file.rawWrite(buf);
        buf.write!uint(cast(uint) textSection.length, 0);
        file.rawWrite(buf);
        buf.write!uint(cast(uint) mainAddress, 0);

        file.rawWrite(metaDataSection);
        file.rawWrite(dataSection);
        file.rawWrite(textSection);
        file.flush();
        file.close();
    }

    void deserialize(string filePath)
    {
        File file = File(filePath, "rb");
        char[4] textBuf;
        auto magic = file.rawRead(textBuf);
        assert(magic == "bcvm");
        
        ubyte[] buf = new ubyte[4];
        metaDataSection.length = file.rawRead(buf).peek!uint(0);
        dataSection.length = file.rawRead(buf).peek!uint(0);
        textSection.length = file.rawRead(buf).peek!uint(0);
        mainAddress = file.rawRead(buf).peek!uint(0);

        file.rawRead(metaDataSection);
        file.rawRead(dataSection);
        file.rawRead(textSection);
        file.close();
    }
}

unittest
{
    import assembler;
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

    string filePath = "test.bcvm";
    bc.serialize(filePath);

    Bytecode bcIn;
    bcIn.deserialize(filePath);
    assert(bc.textSection.length == bcIn.textSection.length);
    assert(bc.dataSection.length == bcIn.dataSection.length);
    assert(bc.metaDataSection.length == bcIn.metaDataSection.length);

    import std.file : remove;
    remove(filePath);
}