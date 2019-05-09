module Rupy
export to_lexp
export runparser
export scoping_analysis
export global_scope
export codegen

include("Error.jl")
include("Parser.jl")
include("LExp.jl")
include("OpReduction.jl")
include("DExp.jl")
include("Codegen.jl")

function runparser(source_code::String, ::Val{:lexp})
    to_lexp(runparser(source_code, :rexp))
end
end # module
