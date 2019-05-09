using Rupy
using Test

@testset "Rupy.jl" begin
    ENV["RUPYPATH"] = "./ruml"
    @test nothing !== codegen(raw"""
       module S where
       import A
       def y = 1 `fst` 2
       """, :py)
    # Write your own tests here.
end
