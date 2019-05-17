using MLStyle
Slot = Union{Symbol, Int}

@data T begin
    TFunctor(kind :: Int, h::T, t::T)
    TArrow(T, T)
    TVar(Slot)
    TCtx(Set{T}, T)
    TApp(T, T)
    TFresh(Slot, T)
    TPrim(Any)
end

@generated function substitute(data :: T, pair :: Pair{T1, T2}, :: Type{A}) where {A, T <: A, T1 <: A, T2 <: A}
    names = fieldnames(T)
    if isempty(names)
        :data
    else
        call = Expr(:call, T, [:(data.$field isa $A ? substitute(data.$field, pair, $A) : data.$field) for field in names]...)
        quote
            if pair[1] === data
                return pair[2]
            end
            $call
        end
    end
end

struct TEnv
    term_scope    :: Dict{Union{Symbol, Int}, T}
    counter       :: Int
end

crate_env() = TEnv(Dict(), 0)

@as_record TEnv

term_scope!(env, f) = TEnv(f(env.term_scope), env.counter)
new_var!(env) = (TEnv(env.term_scope, env.counter + 1), env.counter)

"""
You know now that without Monad we're just weak.
Just too weak.
"""
prune(env :: TEnv, t :: T) =
    @match t begin
        TPrim(_) => (env, t)
        TFunctor(kind, a, b) =>
            let (env, a) = prune(env, a),
                (env, b) = prune(env, b)
                env, TFunctor(kind, a, b)
            end
        TArrow(a, b)   =>
            let (env, a) = prune(env, a)
                (env, b) = prune(env, b)
                env, TArrow(a, b)
            end
        TVar(slot)     =>
            let new_t = get(env.term_scope, slot, t)
                if new_t === t
                    env, t
                else
                    env, new_t = prune(env, new_t)
                    env = term_scope!(env, terms -> Dict(terms..., slot => new_t))
                    env, new_t
                end
            end
        TCtx(set, t) =>
            let (env, t) = prune(env, t)
                new_set = Set([])
                for each in set
                    env, each = prune(env, each)
                    push!(new_set, each)
                end
                env, TCtx(new_set, t)
            end
        TApp(a, b) =>
            let (env, a) = prune(env, a)
                (env, b) = prune(env, b)
                env, TApp(a, b)
            end
        TFresh(slot, t) =>
            let (env, t) = prune(env, t)
                env, TFresh(slot, t)
            end
    end

function occur_in(slot, t)
    let rec(t) =
        @match t begin
            TPrim(_) => false
            TFunctor(_, a, b) || TArrow(a, b) || TApp(a, b) => rec(a) || rec(b)
            TVar(slot!) && if slot === slot! end => true
            TVar(_) => false
            TCtx(set, t) => rec(t)
            TFresh(x, d) => rec(d)
        end

        rec(t)
    end
end

@data TErr begin
    NotMatch(Any, Any)
    RecurType(slot, T)
    KindNotMatch(T, T)
end

function unify(env :: TEnv, a, b)
    env, a = prune(env, a)
    env, b = prune(env, b)
    @match (a, b) begin
        (TPrim(a), TPrim(b)) => (env, a === b ? TPrim(a) : NotMatch(a, b))
        (TVar(a), TVar(b) && t) && if a === b end => (env, t)
        (TVar(a), t) && if occur_in(a, t) end => (env, RecurType(a, t))

        (TFresh(slot, t), b) =>
            let (env, new_slot) = new_var!(env),
                t = substitute(t, TVar(slot) => TVar(new_slot), T)
                unify(env, t, b)
            end
        (TVar(a), t) =>
            let env = term_scope!(env, terms -> Dict(terms..., a => t))
                env, t
            end
        (TFunctor(k1, a, b) && t1, TFunctor(k2, c, d) && t2) =>
            if k1 !== k2
                (env, KindNotMatch(t1, t2))
            else
                let env, a = unify(env, a, c),
                    env, b = unify(env, b, d)
                    env, TFunctor(k1, a, b)
                end
            end
        (TApp(a, b), TApp(c, d)) =>
            let env, a = unify(env, a, c),
                env, b = unify(env, b, d)
                env, TApp(a, b)
            end
        (TArrow(a, b), TArrow(c, d)) =>
            let env, a = unify(env, a, c),
                env, b = unify(env, b, d)
                env, TArrow(a, b)
            end
        (TCtx(seta, a), TCtx(setb, b)) =>
            let (env, a) = unify(env, a, b)
                env, TCtx(union(seta, setb), a)
            end
        (TCtx(seta, a), b) =>
            let (env, a) = unify(env, a, b)
                env, TCtx(seta, a)
            end

        (_, TVar(_) || TFresh(_) || TCtx(_)) => unify(env, b, a)
    end
end
