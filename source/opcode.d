module opcode;

enum OpCode : ubyte
{
    no_op = 0,
    exit,

    imm_i8 = 4,
    imm_i16,
    imm_i32,
    imm_i64,

    drop_i8,
    drop_i16,
    drop_i32,
    drop_i64,

    call_abs_i8, // uses absolute address for now
    call_abs_i16,
    call_abs_i32,
    call_abs_i64,
    ret,

    store_i32_i32, // store i32 from stack into local address given by i32 in bytecode
    load_i32_i32, // load i32 from local address given by i32 in bytecode into stack
    store_global_i32_i32, // store i32 from stack into global address given by i32 in bytecode
    load_global_i32_i32, // load i32 from global address given by i32 in bytecode into stack

    jmp_nz_i32_abs_i32, // jump if not zero, reading i32 from stack, jumping to absolute address given by i32 in bytecode
    jmp_z_i32_abs_i32,
    jmp_abs_i32,
    jmp_rel_i8,
    jmp_rel_i16,

    cmp_lt_i32 = 64,
    cmp_lt_i64,
    cmp_gt_i32,
    cmp_gt_i64,
    cmp_le_i32,
    cmp_le_i64,
    cmp_ge_i32,
    cmp_ge_i64,
    cmp_eq_i32,
    cmp_eq_i64,
    cmp_neq_i32,
    cmp_neq_i64,
    cmp_ze_i32,
    cmp_ze_i64,
    cmp_nze_i32,
    cmp_nze_i64,

    log_and_i32,
    log_and_i64,
    log_or_i32,
    log_or_i64,
    log_not_i32,
    log_not_i64,

    dup_i32,
    dup_i64,

    ext_i8_i16 = 96,
    ext_i8_i32,
    ext_i8_i64,
    ext_i16_i32,
    ext_i16_i64,
    ext_i32_i64,
    sext_i8_i16,
    sext_i8_i32,
    sext_i8_i64,
    sext_i16_i32,
    sext_i16_i64,
    sext_i32_i64,
    trunc_i64_i32,
    trunc_i64_i16,
    trunc_i64_i8,
    trunc_i32_i16,
    trunc_i32_i8,
    trunc_i16_i8,

    add_i32 = 128,
    add_i64,
    sub_i32,
    sub_i64,
    mul_i32,
    mul_i64,
    div_i32,
    div_i64,
    rem_i32,
    rem_i64,
    mod_i32,
    mod_i64,

    shl_i32,
    shl_i64,
    shr_i32,
    shr_i64,
    sar_i32,
    sar_i64,

    and_i32,
    and_i64,
    or_i32,
    or_i64,
    xor_i32,
    xor_i64,

    neg_i32,
    neg_i64,
    not_i32,
    not_i64,

    inc_i32,
    inc_i64,
    dec_i32,
    dec_i64,

    pow_i32,
    pow_i64,
    min_i32,
    min_i64,
    max_i32,
    max_i64,

    mul_u32,
    mul_u64,
    div_u32,
    div_u64,
    rem_u32,
    rem_u64,

    min_u32,
    min_u64,
    max_u32,
    max_u64,
}

enum ImmType
{
    i0,
    i8,
    i16,
    i32,
    i64,
    u8,
    u16,
    u32,
    u64
}

auto immediateOperandSize(OpCode code)
{
    if (code >= 64 || (code >= OpCode.drop_i8 && code <= OpCode.drop_i64))
        return 0;
    else
    {
        import std.string : split;
        import std.conv : to;

        auto size = to!string(code).split('_')[$ - 1];
        switch (size)
        {
            case "i64": return long.sizeof;
            case "i32": return int.sizeof;
            case "i16": return short.sizeof;
            case "i8": return byte.sizeof;
            default: return 0;
        }
    }
}

auto immediateOperandType(OpCode code)
{
    if (code >= 64 || (code >= OpCode.drop_i8 && code <= OpCode.drop_i64))
        return ImmType.i0;
    else
    {
        import std.string : split;
        import std.conv : to;

        auto type = to!string(code).split('_')[$ - 1];
        return type.to!ImmType;
    }
}