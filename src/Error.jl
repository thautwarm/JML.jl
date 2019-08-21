abstract type JMLCompilerError <: Exception end
struct Positioned <: JMLCompilerError
    lineno :: Int
    colno  :: Int
    err    :: JMLCompilerError
end

struct NameUnresolved <: JMLCompilerError
    name :: String
end

struct SimpleMessage <: JMLCompilerError
    msg :: String
end

struct ModulePathNotFound <: JMLCompilerError
    modname :: String
end

struct ComposeExc <: JMLCompilerError
    first :: JMLCompilerError
    next  :: JMLCompilerError
end

print_exc(io, a :: Positioned) =
     begin
        println(io, "line $(a.lineno), column $(a.colno)")
        print_exc(io, a.err)
     end
print_exc(io, a :: NameUnresolved) =
     begin
        println(io, "Name $(a.name) not found")
     end

print_exc(io, a :: ModulePathNotFound) =
     begin
        println(io, "Path of module $(a.modname) didn't exist in current JMLPATH")
     end
print_exc(io, a :: SimpleMessage) =
     begin
        println(io, a.msg)
     end
print_exc(io, a :: ComposeExc) =
     begin
        print_exc(io, a.first)
        print_exc(io, a.next)
     end

Base.show(io::IO, a::JMLCompilerError) = print_exc(io, a)