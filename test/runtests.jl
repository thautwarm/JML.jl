using Rupy
using Test
using  PrettyPrint

@testset "Rupy.jl" begin
    ENV["RUPYPATH"] = "./path"
    println(codegen(raw"""
       module S where
       import A
       def y = 1 `fst` 2 `fst` 3
       """, :py))
    # Write your own tests here.
end
