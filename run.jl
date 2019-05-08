using Rupy

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    inputfilename = ARGS[1]
    outputfilename = ARGS[2]
    json = open(inputfilename) do f
        codegen(read(f, String), :json)
    end
    open(outputfilename, "w") do f
        write(f, json)
    end
    return 0
end