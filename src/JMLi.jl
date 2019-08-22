module JMLi
using DataStructures
using ReplMaker
using JML
using REPL.LineEdit

# a bug of julia? workaround:
Base.convert(::Type{Symbol}, a::Int) = Symbol(a)

const repl_scope = global_scope()
const repl_main = new_module_spec("main", "<repl>")
const repl_modules = OrderedDict("main" => repl_main)

function valid_expr(s)
    try
        str = String(take!(copy(LineEdit.buffer(s))))
        runparser(str, Val(:rexp), Val(:stmt)) !== nothing
    catch e
        if e isa JML.ParserFailed
            return false
        end
        rethrow(e)
    end
end

function parse_jml_expr(s)
    try
        to_julia(
            s;
            mode=:stmt,
            scope=repl_scope,
            modules=repl_modules
        )
    catch e
        println(string(e))
    end
end

initrepl(
    parse_jml_expr,
    valid_input_checker = valid_expr,
    prompt_text="jml> ",
    prompt_color = :light_blue,
    start_key="\\",
    mode_name="jml_mode"
)
end