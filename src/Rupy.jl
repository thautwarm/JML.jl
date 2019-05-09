module Rupy
export to_lexp
export runparser
export sa
export global_scope
export codegen

include("Parser.jl")
include("LExp.jl")
include("OpReduction.jl")
include("DExp.jl")
include("Codegen.jl")

function runparser(source_code::String, ::Val{:lexp})
    to_lexp(runparser(source_code, :rexp))
end
end # module
