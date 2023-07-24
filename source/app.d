import std.stdio;

import memory, opcode, alu, assembler, disassembler;

int main(string[] args)
{
    if (args.length > 2 && args[1] == "-i")
    {
        try
        {
            auto bc = assemble(args[2]);
            ExecutionUnit alu;
            alu.loadBytecode(bc);
            alu.run();
            return alu.exitCode;
        }
        catch (Exception e)
        {
            writeln(e);
            stdout.flush();
            return -1;
        }
    }

    writeln("Run sample program: ");
    string program = "        .text
:main
        immi 0
        storei 0
        loadi 0
        cmp_ze
        jmp_nz .je0
        immi 1
        jmp .end_main
        jmp .j1
:.je0
        immi 2
        jmp .end_main
:.j1
        immi 0
:.end_main
        ret";

    writeln(program);
    auto bc = assemble(program);
    writeln(bc.dataSection);
    writeln(bc.textSection);
    writeln(disassemble(bc.textSection));
    stdout.flush();
    ExecutionUnit alu;
    alu.loadBytecode(bc);
    alu.run();

    return 0;
}
