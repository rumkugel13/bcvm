module memory;

import std.bitmanip : peek, write;

const size_t initialCapacity = 16;

struct MemoryUnit
{
    ubyte[] memory; // note: creating with initial capacity has been moved to reserve to avoid pointing to the same memory area
    size_t usedBytes = 0;

    public void store(T)(T data, size_t addr)
    {
        ensureCapacity(addr + T.sizeof);
        assert(addr + T.sizeof <= memory.length);
        memory.write!T(data, addr);
        import std.algorithm : max;
        usedBytes = max(usedBytes, addr + T.sizeof);
    }

    public T load(T)(size_t addr)
    {
        assert(addr + T.sizeof <= memory.length);
        return memory.peek!T(addr);
    }

    private void ensureCapacity(size_t totalBytes)
    {
        if (memory.length == 0)
        {
            memory.length = initialCapacity;    // note: initialize min amount of bytes available
        }
        
        while (totalBytes > memory.length)
        {
            memory.length *= 2;
        }
    }
}

struct StackUnit
{
    ubyte[] memory; // note: creating with initial capacity has been moved to reserve to avoid pointing to the same memory area
    size_t stackPointer = 0;

    public T pop(T)()
    {
        assert(stackPointer >= T.sizeof);
        stackPointer -= T.sizeof;
        return memory.peek!T(stackPointer);
    }

    public T peek(T)()
    {
        return memory.peek!T(stackPointer - T.sizeof);
    }

    public void push(T)(T data)
    {
        reserve(T.sizeof);
        memory.write!T(data, stackPointer);
        stackPointer += T.sizeof;
    }

    public void pushRaw(ubyte[] data)
    {
        reserve(data.length);
        memory[stackPointer .. stackPointer + data.length] = data;
        stackPointer += data.length;
    }

    private void reserve(size_t bytes)
    {
        if (memory.length == 0)
        {
            memory.length = initialCapacity;    // note: initialize min amount of bytes available
        }
        
        while (stackPointer + bytes > memory.length)
        {
            memory.length *= 2;
        }
    }
}

struct GenericStack(T)
{
    T[] memory;
    size_t size;

    void push(T data)
    {
        reserve(T.sizeof);
        memory[size] = data;
        size += T.sizeof;
    }

    T pop()
    {
        assert(size >= T.sizeof);
        size -= T.sizeof;
        return memory[size];
    }

    T peek()
    {
        assert(size >= T.sizeof);
        return memory[size - T.sizeof];
    }

    private void reserve(size_t bytes)
    {
        if (memory.length == 0)
        {
            memory.length = initialCapacity;    // note: initialize min amount of bytes available
        }
        
        while (size + bytes > memory.length)
        {
            memory.length *= 2;
        }
    }
}

unittest
{
    StackUnit m;
    m.push!uint(32);
    m.push!uint(64);
    assert(m.stackPointer == 8);
    assert(m.peek!uint() == 64);
    m.push!byte(77);
    assert(m.stackPointer == 9);
    assert(m.pop!byte() == 77);

    auto val = m.pop!uint();
    assert(val == 64);
    assert(m.pop!uint() == 32);
    assert(m.stackPointer == 0);
}

unittest
{
    MemoryUnit m;
    m.store!uint(32, 0);
    m.store!uint(64, 4);
    assert(m.load!uint(0) == 32);
    assert(m.load!uint(4) == 64);

    m.store!uint(55, 0);
    assert(m.load!uint(0) == 55);

    m.store!uint(77, 8);
    m.store!uint(2123, 12);
    assert(m.load!uint(12) == 2123);
}

unittest
{
    GenericStack!int stack;
    stack.push(5);
    stack.push(44);
    assert(stack.pop() == 44);
    assert(stack.size == int.sizeof * 1);
    assert(stack.peek() == 5);
    assert(stack.pop() == 5);
    assert(stack.size == 0);
}