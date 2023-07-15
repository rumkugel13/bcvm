import std.stdio;

import memory, opcode, alu, assembler, disassembler;

void main()
{
    writeln("ByteCode VM");

    StackUnit m;
    m.push!uint(32);
    m.push!uint(64);

    assert(m.peek!uint() == 64);
    m.push!byte(77);
    assert(m.stackPointer == 9);
    assert(m.pop!byte() == 77);

    auto val = m.pop!uint();
    assert(val == 64);
    assert(m.pop!uint() == 32);

    writeln("MemoryUnit OK");

    string program = ":main
    immi 32
    immi 64
    addi
    immb 37
    b2i
    subi
    ret";

    auto bytecode = assemble(program);

    writeln("Assembler OK");

    ExecutionUnit alu;
    alu.instructions = bytecode;
    alu.run();
    assert(alu.exitCode == 59);

    writeln("ExecutionUnit OK");

    auto assembly = disassemble(bytecode);
    write(assembly);

    writeln("Disassembler OK");

    string program2 = ":main
        immi 55
        storei 0
        immi 30
        storei 4
        loadi 4
        loadi 0
        call something
        ret
        :something
        storei 0
        storei 4
        loadi 0
        loadi 4
        subi
        ret
    ";

    auto bytecode2 = assemble(program2);
    write(bytecode2);
    stdout.flush();

    writeln("Assembler OK");

    auto assembly2 = disassemble(bytecode2);
    write(assembly2);
    stdout.flush();

    writeln("Disassembler OK");

    ExecutionUnit alu2;
    alu2.instructions = bytecode2;
    alu2.run();
    assert(alu2.exitCode == 25);

    writeln("ExecutionUnit OK");

    import std.conv : to;
    int number = 10;
    string fib = ":main
    immi " ~ to!string(number) ~ "
    call fibonacci
    ret
    :fibonacci
    storei 0
    loadi 0
    immi 1
    cmp_gt
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
    writeln(fibass);
    auto fibdis = disassemble(fibass);
    writeln(fibdis);
    stdout.flush();
    ExecutionUnit fibalu;
    fibalu.instructions = fibass;
    fibalu.run();
    writeln("Fib of ", number, " is ", fibalu.exitCode);
}