using JSON2

codegen(source_code :: String, target::Symbol) = codegen(source_code, Val(target))
codegen(source_code :: String, target::String) = codegen(source_code, Symbol(target))
codegen(source_code :: String, target::Val{:json}) =
    let rexp = runparser(source_code, :rexp),
        lexp = to_lexp(rexp),
        scope = global_scope(Dict("print" => "print")),
        dexp = sa(scope, lexp)

        JSON2.write(dexp)
    end