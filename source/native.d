module native;

import alu, std.stdio, std.conv : to;

static int[string] funcMap;

enum NativeFunction
{
    _,
    putchar = -1
}

shared static this()
{
    funcMap = ["": NativeFunction._, "putchar": NativeFunction.putchar];
}

bool isNative(string name)
{
    return (name in funcMap) !is null;
}

int getNativeIndex(string name)
{
    return funcMap[name];
}

void callNative(NativeFunction index, ref ExecutionUnit e)
{
    switch (index)
    {
    case NativeFunction.putchar:
        int val = e.operands.pop!int();
        try
        {
            write(val.to!char);
            stdout.flush();
            e.operands.push!int(val);
        }
        catch (Exception _)
        {
            e.operands.push!int(-1);
        }
        break;
    default:
        assert(0);
    }
}
