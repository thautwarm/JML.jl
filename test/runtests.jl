using JML
using Test
using  PrettyPrint

@testset "snooping" begin
    @test 2 == JML.second([1, 2, 3])
    @test "2" == JML.second(["1", "2", "3"])
    @test "3" == JML.LConst("3")._1
    @test 3 == JML.LConst(3)._1
    @test 1.0 == JML.LConst(1.0)._1
    @test nothing == JML.LConst(nothing)._1
    err1 = JML.SimpleMessage("aaaaa")
    err2 = JML.ModulePathNotFound("a.pml", "b")
    err3 = JML.NameUnresolved("var")
    err4 = JML.Positioned(1, 2, err3)
    err5 = JML.ComposeExc(err1, JML.ComposeExc(err2, err4))
    JML.print_exc(stdout, err5)
end


@testset "JML.jl" begin
    ENV["RUPYPATH"] = "./path"
    println(codegen(raw"""
       module S where
       import A
       def y = 1 `fst` 2 `fst` 3
       """, "a", :py))
    # Write your own tests here.
end
