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

PrettyPrint.pprint_impl(io, data::DConst{Bool}, a, b) where T = begin
    print(io, "Rupy.DConst(v=")
    pprint(io, data.v ? "True" : "False")
    print(io, ")")
end

codegen(source_code :: String, fname :: String, target::Symbol) = codegen(source_code, fname, Val(target))
codegen(source_code :: String, fname :: String, target::String) = codegen(source_code, fname, Symbol(target))
codegen(source_code :: String, fname :: String, target::Val{:py}) =
    let rexp =
            try
                runparser(source_code, :rexp)
            catch e
                println(e)
                exit(1)
            end,
        lexp = to_lexp(rexp),
        scope = global_scope(),
        modules = OrderedDict("main" => new_module_spec("main", fname))
        try
            pformat(scoping_analysis(scope, lexp, modules))
        catch e
            if e isa RupyCompileError
                print_exc(stdout, e)
            else
                println("Not covered exception")
                println(e)
            end
            exit(1)
        end
    end
