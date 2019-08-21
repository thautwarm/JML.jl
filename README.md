JML: A ML dialect based on Julia
=========================================

P.S: The python backend is broken.

The Syntax rules of JML could be found at [Parser.jl](https://github.com/thautwarm/JML.jl/blob/master/src/Parser.jl).
Not all valid syntax constructs are implemented in the compiler yet.
Type checker is WIP.

Features
===================

- [x] infix operators with custom associativities and precendences:
    ```
        infix add 5
        infix cons 2 right
    ```

- [x] pure lexical scope, and distinguish `let-in` bindings from `let rec - in`  bindings.

- [x] FFI via `foreign` keyword

    ```
        foreign Base
        def p = Base.getproperty
    ```

- [x] provide accurate source code positions when reporting errors

- [ ] match expression
- [ ] type inference with type classes
- [ ] parameterised modules

Usage
===================

Press `\` to enter `jml`  mode.

```
julia> \
jml>
```

![jml](https://raw.githubusercontent.com/thautwarm/JML.jl/master/jml.png)


Constructs Support Status
================================

- [x] `Str       :=  value=str`
- [x] `Nil       := ["()"]`
- [x] `Bind      := [name=id %get_str, '=', value=Exp]`
- [x] `Let       := [loc=:let %get_loc, rec=:rec.? % maybe_to_bool, ...`
- [x] `Fun       := [loc=:fn %get_loc, "(", args=join_rule(",", ...`
- [ ] `Match     := [loc=:match %get_loc, sc=Exp, :with,`
- [x] `If        := [loc=:if %get_loc, cond=Exp, :then, ...`
- [x] `Num       := [neg="-".? % maybe_to_bool, (int=integer) | (float=float)]`
- [x] `Boolean   := value=("true" | "false")`
- [x] `NestedExpr = ['(', value=Exp, ')'] => _.value`
- [x] `Var       := value=id %get_str`
- [x] `Block     := [loc='{' %get_loc, stmts=Stmt{*}, '}']]`
- [x] `Atom      =  Nil | NestedExpr | Num | Str | Boolean | Var | List`
- [x] `Attr      := [value=Atom, attrs=(['.', id % get_str] % second){*}]`
- [x] `Call      := [fn=Attr, ['(', args = join_rule(",", Attr), ')'].?]`
- [x] `List      := [loc='[', elts=join_rule(',', Exp), ']']`
- [x] `Comp      = Call | Let | Fun | Match | If | Block`
- [x] `Op        := ...`
- [x] `Top       := [hd=Comp, tl=[Op, Comp]{*}]`
- [ ] `Custom    := [value=Exp, [',', next=Custom].?] | [kw=id, value=Exp, [',', next=Custom].?]`
- [x] `Exp       := [top=Top, [do_custom::Bool='{' => true, [custom=Custom].?, '}'].?]`
- [x] `Define    := [loc=:def %get_loc, name=id_str, '=', value=Exp]`
- [x] `Infix     := [loc=:infix %get_loc, name=id_str, prec=integer %get_str, is_right="right".? % maybe_to_bool]`
- [x] `Foreign   := [loc=:foreign %get_loc, paths=join_rule('.', id_str)]`
- [x] `Import    := [loc=:import %get_loc, is_qual=:qualified.? %maybe_to_bool, paths=join_rule('.', id_str)]`
- [x] `Ops       := [loc=:export %get_loc, names=id_str{*}]`
- [x] `Stmt      =  [Exp | Import | Module, ';'.?] % first`
- [x] `TopStmt   = Define | Import | Infix | Stmt | Foreign | Ops`
- [?] `Module    := [loc=:module %get_loc, name=id_str, params=id_str{*}, :where, stmts=TopStmt{*}, :end.?]`