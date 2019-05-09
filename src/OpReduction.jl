#=
binary operation sequence reduction
=#
using DataStructures

mutable struct Doubly
    l
    v
    r
end

function chunkby(f, seq)
    if isempty(seq)
        return Tuple[]
    end
    chunk = [seq[1]]
    last = f(seq[1])
    chunks = Tuple[]
    for each in view(seq, 2:length(seq))
        cur = f(each)
        if cur == last
            push!(chunk, each)
        else
            push!(chunks, (last, chunk))
            chunk = [each]
        end
        last = cur
    end
    push!(chunks, (last, chunk))
    chunks
end

function binop_reduce(seq :: Vector{Union{LExp, Token}}, precedences::Dict{String, Int}, associations::Dict{String, Bool})
    start = Doubly(nothing, nothing, nothing)
    last = start
    ops = Doubly[]
    for each in seq
        cur = Doubly(last, each, nothing)
        if each isa Token
            push!(ops, cur)
        end
        last.r = cur
        last = cur
    end
    final = Doubly(last, nothing, nothing)
    last.r = final

    # precedences
    sort!(ops, by=x -> precedences[x.v.str], rev=true)

    # assocications
    op_chunks = chunkby(x -> (precedences[x.v.str], associations[x.v.str]), ops)
    ops = vcat([is_right_asoc ? reverse(chunk) : chunk for ((_, is_right_asoc), chunk) in op_chunks]...)

    for op in ops
        op_v = op.v
        op.v = LLoc((lineno=op_v.lineno, colno=op_v.colno), LCall(LVar(op_v.str), [op.l.v, op.r.v]))
        op.l = op.l.l
        op.r = op.r.r
        op.l.r = op
        op.r.l = op
    end
    final.l.v
end