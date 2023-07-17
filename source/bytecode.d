module bytecode;

enum Section
{
    Text,
    Data,
    BSS
}

struct Bytecode
{
    ubyte[] textSection, dataSection;
}
