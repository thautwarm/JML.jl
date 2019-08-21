using DataStructures

module JMLJulia
end

function auto_to_julia(ex)
    @match ex begin
        :(!$a)          => :(to_julia($a))
        Expr(hd, tl...) => Expr(hd, map(auto_to_julia, tl)...)
        a               => a
    end
end

macro auto_to_julia(ex)
    auto_to_julia(ex) |> esc
end

@auto_to_julia to_julia(dexp :: DExp) =
    @match dexp begin
        DAssign(reg, val) =>
            let sym = Symbol(reg)
                :($sym = $(!val))
            end
        DClosure(freevars, argnames, body) =>
            # julia already has closures, so no need to create a new impl
            let binds = map((s -> :($s = $s)) ∘ Symbol, freevars),
                argnames = map(Symbol, argnames)

                Expr(:let,
                    Expr(:block, binds...),
                    Expr(:function,
                        Expr(:tuple, argnames...),
                        !body
                    )
                )
            end
        DIf(cond, trueClause, falseClause) =>
            :($(!cond) ? $(!trueClause) : $(!falseClause))
        DConst(v :: AbstractString) => Meta.parse(v)
        DConst(v) => v
        DVar(s) => Symbol(s)
        DBlock(elts) => Expr(:block, [!x for x in elts]...)
        DCall(f, args) => Expr(:call, !f, [!arg for arg in args]...)

        DAttr(sub, attr) => Expr(:., !sub, QuoteNode(Symbol(attr)))
        DList(elts) =>
            let elts = [!elt for elt in elts]
                foldr(elts, init = :($nil())) do elt, prev
                    :($cons($elt, $prev))
                end
            end
        # after generation, we will transform the LineNumberNode to
        # set correct file
        DLoc(l, c, exp) => Expr(:block, LineNumberNode(l, c), !exp)
        DStaged(v) => v
        DImport(paths, name, actual) =>
            let actual = Symbol(actual),
                syms = map(Symbol, [paths..., name]),
                mod = foldl((a, b) -> :($a.$b), syms),
                _ = JMLJulia.eval(:(using $(syms...))),
                mod = JMLJulia.eval(mod)

                :($actual = $mod)
            end
        DModule(modname, exports, stmts) =>
            let stmts = [!stmt for stmt in stmts]
                # mod = Expr(
                #     :tuple,
                #     [   let k = Symbol(k),
                #             v = Symbol(v)
                #             :($k = $v)
                #         end
                #         for (k, v) in exports
                #     ]...
                # )
                Expr(:block, stmts...)
            end
    end

to_julia(
    source_code :: AbstractString
    ;
    scope = global_scope(),
    mode :: Symbol = :module,
    fname :: AbstractString = "<repl>",
    modules = OrderedDict("main" => new_module_spec("main", fname))
) =
    let rexp = runparser(source_code, Val(:rexp), Val(mode)),
        lexp = to_lexp(rexp)
        to_julia(scoping_analysis(scope, lexp, modules))
    end