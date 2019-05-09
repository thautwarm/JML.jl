using PrettyPrint
PrettyPrint.pprint_impl(io, data::DConst{Nothing}, _, _) where T = begin
    print(io, "Rupy.DConst(v=None)")
end

PrettyPrint.pprint_impl(io, data::DConst{T}, _, _) where T = begin
    print(io, "Rupy.DConst(v=")
    pprint(io, data.v)
    print(io, ")")
end

PrettyPrint.pprint_impl(io, data::AbstractDict{T}, a, b) where T = begin
    PrettyPrint.pprint_impl(io, collect(data), a, b)
end

codegen(source_code :: String, target::Symbol) = codegen(source_code, Val(target))
codegen(source_code :: String, target::String) = codegen(source_code, Symbol(target))
codegen(source_code :: String, target::Val{:py}) =
    let rexp = runparser(source_code, :rexp),
        lexp = to_lexp(rexp),
        scope = global_scope(),
        modules = OrderedDict("main" => new_module_spec("main"))
        try
            pformat(scoping_analysis(scope, lexp, modules))
        catch e
            println(string(e))
            exit(1)
        end
    end