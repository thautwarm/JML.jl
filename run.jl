using JML
using PrettyPrint

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    inputfilename = ARGS[1]
    midfilename = ARGS[2]
    outputfilename = ARGS[3]
    python = open(inputfilename) do f
        codegen(read(f, String), inputfilename, :py)
    end
    open(midfilename, "w") do f
        println(f, "from rupy import Rupy")
        println(f, "from rupy.pythonize import compile_to")
        print(f, "dexp = ")
        println(f, python)
        println(f, "filename = $(repr(inputfilename))")
        println(f, "compile_to(dexp, filename, $(repr(outputfilename)))")
    end
    return 0
end