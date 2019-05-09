abstract type RupyCompileError <: Exception end
struct Positioned <: RupyCompileError
    lineno :: Int
    colno  :: Int
    err    :: RupyCompileError
end

struct NameUnresolved <: RupyCompileError
    name :: String
end

struct SimpleMessage <: RupyCompileError
    msg :: String
end

struct ModulePathNotFound <: RupyCompileError
    path    :: String
    modname :: String
end

struct ComposeExc <: RupyCompileError
    first :: RupyCompileError
    next  :: RupyCompileError
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
        println(io, "Path of module $(a.modname) didn't exist at $(a.path)")
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