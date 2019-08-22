using RBNF
using MLStyle
using PrettyPrint
using DataStructures

struct ReMLLang
end

second((a, b)) = b
second(vec::V) where V <: AbstractArray = vec[2]

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

get_list(::Some{Nothing}) = []
get_list(a::Some) = let (a, b) = a.value; [a, b...] end
join_rule(sep, x) = begin
    :([$x, ([$sep, $x] % second){*}].? % get_list)
end

Token = RBNF.Token

get_loc(token::Token{T}) where T = (t=T, lineno=token.lineno, colno=token.colno)
get_str(token::Token{T}) where T = token.str
RBNF.typename(name:: Symbol, ::Type{ReMLLang}) = Symbol(:R, name)

RBNF.@parser ReMLLang begin
    # define the ignores
    ignore{space, comment}

    # define keywords
    reserved = [true, false]

    @grammar
    # necessary

    Bind      := [name=id %get_str, '=', value=Exp]
    Let       := [loc=:let %get_loc, rec=:rec.? % maybe_to_bool,
                        binds=join_rule(:and, Bind),
                     :in, body=Exp]

    Fun       := [loc=:fn %get_loc, "(", args=join_rule(",", (id % get_str)), ")", "->", body=Exp]
    Match     := [loc=:match %get_loc, sc=Exp, :with,
                        cases=(['|', Comp, "->", Exp] % ((_, case, _, body), ) -> (case, body)){*},
                    :end.?] # end for nested match
    If        := [loc=:if %get_loc, cond=Exp, :then,
                        br1=Exp,
                     :else,
                        br2=Exp]
    NestedExpr = ['(', value=Exp, ')'] => _.value
    Var       := value=id %get_str
    Block     := [loc='{' %get_loc, stmts=Stmt{*}, '}']
    Atom      =  Nil | NestedExpr | Num | Str | Boolean | Var | List
    Attr      := [value=Atom, attrs=(['.', id % get_str] % second){*}]
    Call      := [fn=Attr, ['(', args = join_rule(",", Exp), ')'].?]
    List      := [loc='[', elts=join_rule(',', Exp), ']']
    Comp      = Call | Let | Fun | Match | If | Block
    Op        := ['`', name=_, '`']
    Top       := [hd=Comp, tl=[Op, Comp]{*}]
    Custom    := [value=Exp, [',', next=Custom].?] | [kw=id, value=Exp, [',', next=Custom].?]
    Exp       := [top=Top, [do_custom::Bool='{' => true, [custom=Custom].?, '}'].?]

    id_str    = id%get_str
    Define    := [loc=:def %get_loc, name=id_str, '=', value=Exp]
    Infix     := [loc=:infix %get_loc, name=id_str, prec=integer %get_str, is_right="right".? % maybe_to_bool]
    Foreign   := [loc=:foreign %get_loc, paths=join_rule('.', id_str)]
    Import    := [loc=:import %get_loc, is_qual=:qualified.? %maybe_to_bool, paths=join_rule('.', id_str)]
    Ops       := [loc=:export %get_loc, names=id_str{*}]

    Stmt      =  [Exp | Import | Module, ';'.?] % first
    TopStmt   = Define | Import | Infix | Stmt | Foreign | Ops
    Module    := [loc=:module %get_loc, name=id_str, params=id_str{*}, :where, stmts=TopStmt{*}, :end.?]

    Str       :=  value=str
    Nil       := ["()"]
    Num       := [neg="-".? % maybe_to_bool, (int=integer) | (float=float)]
    Boolean   := value=("true" | "false")

    @token
    comment   := @quote ("(*", "\\*)", "*)")
    str       := @quote ("\"", "\\\"", "\"")
    id        := r"\G[A-Za-z_]{1}[A-Za-z0-9_\!]*"
    float     := r"\G([0-9]+\.[0-9]*|[0-9]*\.[0.9]+)([eE][-+]?[0-9]+)?"
    integer   := r"\G([1-9]+[0-9]*|0)"
    space     := r"\G\s+"
end

function runparser(a, v :: Symbol)
    runparser(a, Val(v))
end

function runparser(a, v :: String)
    runparser(a, Symbol(v))
end

struct ParserFailed <: Exception
    msg :: String
end

function runparser(parser :: F, source_code :: String, ::Val{:rexp}) where F <: Function
    tokens = RBNF.runlexer(ReMLLang, source_code)
    ast, ctx = RBNF.runparser(parser, tokens)
    if ctx.maxfetched >= ctx.tokens.length
        return ast
    end
    token = tokens[ctx.maxfetched]
    lineno = token.lineno
    colno = token.colno
    str   = token.str
    throw(ParserFailed("parsing error at $(repr(str)) at lineno $lineno, colno $colno"))
end

function runparser(source_code :: String, repr_form::Val, mode::Val{:module})
    runparser(Module, source_code, repr_form)
end

function runparser(source_code :: String, repr_form::Val, mode::Val{:stmt})
    runparser(TopStmt, source_code, repr_form)
end

function runparser(source_code :: String, repr_form::Symbol, mode::Symbol)
    runparser(Module, source_code, Val(repr_form), Val(mode))
end
