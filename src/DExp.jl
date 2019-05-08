# no closure / lifted

Hash = Dict{String, String}
Asoc = NTuple{Pair{String, String}}

abstract type AbstractScope{C} end

struct Scope{C} <: AbstractScope{C}
    count    :: Ref{Int}
    freevars :: C
    bounds   :: C
    parent   :: Union{Nothing, AbstractScope{C}}
end

function lookup(d::Hash, k::String)
    get(d, k, nothing)
end

function lookup(d::Asoc, k::String)
    for (k!, v) in d
        k! == k && return v
    end
end

function lookup(d::Scope{T}, k::String) where T
    v = lookup(d.bounds, k)
    v !== nothing && return v
    v = lookup(d.freevars, k)
    v !== nothing && return v
end

function new!(scope::Scope{Hash}, k)
    Scope(scope.count, Hash(), Hash(), scope)
end

function enter!(scope::Scope{Hash}, k)
    c = scope.count
    scope.count = c + 1
    name = "$k.$c"
    scope.bounds[k] = c
    nothing
end

function require!(scope::Scope{Hash}, k::String)
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
const _count = Ref(0)

function fixed(scope::Scope{Hash})
    Scope(_count, Tuple(Scope.freevars), Tuple(scope.bounds), nothing)
end


@data LLExp begin
    LLAssign(String, LLExp)
    LLClosure(Vector{String}, Vector{String}, LLExp)
    LLIf(LLExp, LLExp, LLExp)
    LLConst{T} :: T => LLExp
    LLBlock(Vector{LExp})
    LLVar(String)
    LList(Vector{LLExp})
    LLCall(LLExp, Vector{LLExp})
    LLLoc(Any, LExp)
    LLStaged(Any)

    LLet(Bool, Vector{Tuple{String, LExp}}, LExp)
    LFun(Vector{String}, LExp)
    LMatch(LExp, Vector{Tuple{LExp, LExp}})       # *
    LIf(LExp, LExp, LExp)
    LConst{T} :: T => LExp
    LVar(String)
    LBlock(Vector{LExp})
    LAttr(LExp, String)                           # *
    LCall(LExp, Vector{LExp})
    LList(Vector{LExp})
    LBin(Vector{Union{LExp, Token}})              # *
    LInfix(String, Int, Bool)
    LDefine(String, LExp)
    LModule(String, Vector{String}, Vector{LExp}) # *
    LCustom(LExp, Vector{Tuple{String, LExp}})
    LLoc(Any, LExp)
    LScope(Scope{Asoc}, LExp)
    LImport(Vector{String}, String)
    LStaged(Any)
end
