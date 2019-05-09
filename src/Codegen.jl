using PrettyPrint
PrettyPrint.pprint_impl(io, data::DConst{Nothing}, _, _) where T = begin
    print(io, "Rupy.DConst(v=None)")
end

PrettyPrint.pprint_impl(io, data::DConst{T}, _, _) where T = begin
    print(io, "Rupy.DConst(v=")
    pprint(io, data.v)
    print(io, ")")
end


codegen(source_code :: String, target::Symbol) = codegen(source_code, Val(target))
codegen(source_code :: String, target::String) = codegen(source_code, Symbol(target))
codegen(source_code :: String, target::Val{:py}) =
    let rexp = runparser(source_code, :rexp),
        lexp = to_lexp(rexp),
        scope = global_scope(),
        modules = Dict("main" => new_module_spec("main")),
        dexp = scoping_analysis(scope, lexp, modules)

        pformat(dexp)
    end