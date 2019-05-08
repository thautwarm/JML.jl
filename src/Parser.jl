using RBNF
using MLStyle
using PrettyPrint
using DataStructures

struct ReMLLang
end

second((a, b)) = b
second(vec::V) where V <: AbstractArray = vec[2]

escape(a) = @match a begin
    '\\'  => '\\'
    '"'   => '"'
    'a'   => '\a'
    'n'   => '\n'
    'r'   => '\r'
    a     => throw(a)
end

join_token_as_str = xs -> join(x.str for x in xs)

maybe_to_bool(::Some{Nothing}) = false
maybe_to_bool(::Some{T}) where T = true

"""
nonempty sequence
"""
struct GoodSeq{T}
    head :: T
    tail :: Vector{T}
end

join_rule(sep, x) = begin
    :([$x, ([$sep, $x] % second){*}] % x -> [x[1], x[2]...])
end

Token = RBNF.Token

get_loc(token::Token{T}) where T = (t=T, lineno=token.lineno, colno=token.colno)
get_str(token::Token{T}) where T = token.str
RBNF.typename(name:: Symbol, ::Type{ReMLLang}) = Symbol(:R, name)

RBNF.@parser ReMLLang begin
    # define the ignores
    ignore{space}

    # define keywords
    reserved = [true, false]

    @grammar
    # necessary
    Str       :=  [loc='"' %get_loc, value = Escape{*} % join_token_as_str, '"']
    Escape    =  (('\\', _) % (escape ∘ second)) | !'"'

    Bind      := [name=id %get_str, '=', value=Exp]
    Let       := [loc=:let %get_loc, rec=:rec.? % maybe_to_bool,
                        binds=join_rule(:and, Bind),
                     :in, body=Exp]

    Fun       := [loc=:fn %get_loc, args=(id % get_str){*}, "->", body=Exp]
    Match     := [loc=:match %get_loc, sc=Exp, :with,
                        cases=(['|', Comp, "->", Exp] % ((_, case, _, body), ) -> (case, body)){*},
                    :end.?] # end for nested match
    If        := [loc=:if %get_loc, cond=Exp, :then,
                        br1=Exp,
                     :else,
                        br2=Exp]
    Num       := [[neg="-"].? % maybe_to_bool, (int=integer) | (float=float)]
    Boolean   := value=("true" | "false")
    NestedExpr = ['(', value=Exp, ')'] => _.value
    Var       := value=id %get_str
    Block     := [loc='{' %get_loc, stmts=Stmt{*}, '}']
    Nil       := ['(', ')']
    Atom      =  NestedExpr | Num | Str | Boolean | Var | List
    Attr      := [value=Atom, [loc='.', attr=id % get_str].?]
    Call      := [fn=Attr, args=Attr{*}]
    List      := [loc='[', elts=Exp{*}, ']']
    Comp      = Call | Let | Fun | Match | If | Block
    Op        := ['`', name=_, '`']
    Top       := [hd=Comp, tl=[Op, Comp]{*}]
    Custom    := [value=Exp, [',', next=Custom].?] | [kw=id, value=Exp, [',', next=Custom].?]
    Exp       := [top=Top, [do_custom::Bool='{' => true, [custom=Custom].?, '}'].?]

    id_str    = id%get_str
    Define    := [loc=:def %get_loc, name=id %get_str, '=', value=Exp]
    Infix     := [loc=:infix %get_loc, name=id %get_str, prec=integer %get_str, is_right="right".? % maybe_to_bool]
    Stmt      = Define | Exp | Infix | Module
    Module    := [loc=:module %get_loc, name=id_str, params=id_str{*}, :where, stmts=Stmt{*}, :end.?]

    @token
    id        := r"\G[A-Za-z_]{1}[A-Za-z0-9_]*"
    float     := r"\G([0-9]+\.[0-9]*|[0-9]*\.[0.9]+)([eE][-+]?[0-9]+)?"
    integer   := r"\G([1-9]+[0-9]*|0)"
    space     := r"\G\s+"
end

function parse(a, v :: Symbol)
    parse(a, Val(v))
end

function parse(a, v :: String)
    parse(a, Symbol(v))
end


function parse(source_code :: String, ::Val{:source_code})
    tokens = RBNF.runlexer(ReMLLang, source_code)
    ast, ctx = RBNF.runparser(Module, tokens)
    if ctx.maxfetched >= ctx.tokens.length
        return ast
    end
    token = tokens[ctx.maxfetched]
    lineno = token.lineno
    colno = token.colno
    str   = token.str
    throw("parsing error at $(repr(str)) at lineno $lineno, colno $colno")
end
