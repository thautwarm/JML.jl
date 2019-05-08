# no closure / lifted

Hash = Dict{String, String}

abstract type AbstractScope end

struct Scope <: AbstractScope
    count    :: Ref{Int}
    freevars :: Hash
    bounds   :: Hash
    parent   :: Union{Nothing, AbstractScope}
end

function lookup(d::Hash, k::String)
    get(d, k, nothing)
end

function lookup(d::Scope, k::String) where T
    v = lookup(d.bounds, k)
    v !== nothing && return v
    v = lookup(d.freevars, k)
    v !== nothing && return v
    nothing
end

function new!(scope::Scope)
    Scope(scope.count, Hash(), Hash(), scope)
end

function enter!(scope::Scope, k)
    c = scope.count.x
    scope.count.x = c + 1
    name = "$k._$(string(c, base=32))"
    scope.bounds[k] = name
    name
end

function require!(scope::Scope, k::String)
    v = lookup(scope, k)
    v !== nothing && return v
    required_scopes = [scope]
    scope = scope.parent

    while scope !== nothing
        v = lookup(scope, k)
        v !== nothing && begin
            for each in required_scopes
                each.freevars[k] = v
            end
            return v
        end
        push!(required_scopes, scope)
        scope = scope.parent
    end
    throw("unknown name $k")
end

@data DExp begin
    DAssign(reg::String, val::DExp)
    DClosure(freevars::Vector{String}, argnames::Vector{String}, body::DExp)
    DIf(cond::DExp, br1::DExp, br2::DExp)
    DConst{T} :: (v::T) => DExp
    DVar(sym::String)
    DBlock(elts::Vector{DExp})
    DCall(f::DExp, args::Vector{DExp})
    DList(elts::Vector{DExp})
    DLoc(lineno::Int, colno::Int, val::DExp)
    DStaged(val :: Any)
    DImport(paths::Vector{String}, name::String, actual::String)
    DModule(modname::String, exports::Vector{Tuple{String, String}}, stmts::Vector{DExp})
end

global_scope(shallow_buitins::Dict{String, String}) = Scope(Ref(0), shallow_buitins, Hash(), nothing)

function sa(scope::Scope, lexp::LExp)
    @match lexp begin
        LLoc(l, v) => DLoc(l.lineno, l.colno, sa(scope, v))
        LStaged(v) => DStaged(v)
        # LDefine(s, v) =>
        #     let s = enter!(scope, s), ns = new!(scope)
        #         DAssign(s, sa(ns, v))
        #     end
        LList(elts) => DList([sa(scope, elt) for elt in elts])
        LCall(f, args) => DCall(sa(scope, f), [sa(scope, arg) for arg in args])
        LBlock(elts) => DBlock([sa(scope, elt) for elt in elts])
        LVar(s) => let s = require!(scope, s); DVar(s) end
        LConst(v) => DConst(v)
        LIf(a, b, c) => DIf(sa(scope, a), sa(scope, b), sa(scope, c))
        LLet(rec, binds, body) =>
            if rec
                ns = new!(scope)
                block = DExp[]
                binds2 :: Vector{Tuple{String, LExp}} = [(enter!(ns, k), v) for (k, v) in binds]
                for (unmangled_name, v) in binds2
                    push!(block, DAssign(unmangled_name, sa(ns, v)))
                end
                push!(block, sa(ns, body))
                DBlock(block)
            else
                ns = new!(scope)
                block :: Vector{DExp} = [
                    DAssign(enter!(ns, k), sa(new!(scope), v)) for (k, v) in binds
                ]
                push!(block, sa(ns, body))
                DBlock(block)
            end
        LFun(args, body) =>
            let ns = new!(scope),
                args = [enter!(ns, arg) for arg in args],
                body = sa(ns, body)
                DClosure(collect(values(ns.freevars)), args, body)
            end
        LModule(modname, args, seq) =>
            let block = [],
                pairs = Dict{String, String}()
                map(seq) do each
                    @match each begin
                        LDefine(s, v) => let ss = enter!(scope, s),
                                             _ = pairs[s] = ss,
                                             v = v
                                             () -> let ns = new!(scope)
                                                     DAssign(ss, sa(ns, v))
                                                   end
                                         end
                        LImport(paths, name) => let ss = enter!(scope, name)
                                                    () -> DImport(paths, name, ss)
                                                end
                        a => let a = a; () -> sa(scope, a) end
                    end
                end |> fs ->
                let _ = for each in fs
                            push!(block, each())
                        end
                    DModule(modname, [(a, b) for (a, b) in pairs] , block)
                end
            end
    end
end