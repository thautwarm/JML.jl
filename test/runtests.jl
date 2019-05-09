using Rupy
using Test
using  PrettyPrint

@testset "snooping" begin
    @test 2 == Rupy.second([1, 2, 3])
    @test "2" == Rupy.second(["1", "2", "3"])
    @test "3" == Rupy.LConst("3")._1
    @test 3 == Rupy.LConst(3)._1
    @test 1.0 == Rupy.LConst(1.0)._1
    @test nothing == Rupy.LConst(nothing)._1
    err1 = Rupy.SimpleMessage("aaaaa")
    err2 = Rupy.ModulePathNotFound("a.pml", "b")
    err3 = Rupy.NameUnresolved("var")
    err4 = Rupy.Positioned(1, 2, err3)
    err5 = Rupy.ComposeExc(err1, Rupy.ComposeExc(err2, err4))
    Rupy.print_exc(stdout, err5)
end


@testset "Rupy.jl" begin
    ENV["RUPYPATH"] = "./path"
    println(codegen(raw"""
       module S where
       import A
       def y = 1 `fst` 2 `fst` 3
       """, "a", :py))
    # Write your own tests here.
end
