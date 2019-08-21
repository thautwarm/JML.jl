import ast
import importlib
import time
from functools import reduce
from pathlib import Path
from rupy.Rupy import *


class Builder:
    def __init__(self):
        self.fc = {}
        self.c = 0

    def new_id(self):
        c = self.c
        self.c += 1
        return f"tmp.{c}"

    @staticmethod
    def load(s: str):
        return ast.Name(s, ctx=ast.Load())

    @staticmethod
    def store(s: str, v):
        return ast.Assign(targets=[ast.Name(s, ctx=ast.Store())], value=v)

    @staticmethod
    def branch(r1: ast.expr, block1: List, block2: List):
        return ast.If(r1, block1, block2)

    @staticmethod
    def loop(r1: ast.expr, block: List):
        return ast.While(r1, block, None)

    @staticmethod
    def attr(value: ast.expr, attr: str):
        return ast.Attribute(value=value, attr=attr, ctx=ast.Load())

    def make_fn(self,
                freevars: List[str],
                args: List[str],
                block,
                name: str = None):
        name = name or self.new_id()
        name = f"lifted.{name}"
        paramlist = [f"{name}.args"]

        lhs_args = ast.Tuple(
            elts=[ast.Name(each, ast.Store()) for each in args],
            ctx=ast.Store())
        decons_args = ast.Assign(
            targets=[lhs_args], value=ast.Name(f"{name}.args", ast.Load()))

        if freevars:
            paramlist = [f"{name}.freevars", paramlist[0]]

            lhs_freevars = ast.Tuple(
                elts=[ast.Name(each, ast.Store()) for each in freevars],
                ctx=ast.Store())

            decons_freevars = ast.Assign(
                targets=[lhs_freevars],
                value=ast.Name(f"{name}.freevars", ast.Load()))

            block = [decons_freevars, decons_args, *block]
        else:
            block = [decons_args, *block]

        f = ast.FunctionDef(
            name=name,
            args=ast.arguments(
                args=[
                    ast.arg(arg=each, annotation=None) for each in paramlist
                ],
                vararg=None,
                kwonlyargs=[],
                kw_defaults=[],
                kwarg=None,
                defaults=[],
            ),
            body=block,
            decorator_list=[],
            returns=None,
        )
        self.fc[name] = f
        fp = ast.Name(name, ast.Load())

        if freevars:
            rhs_freevars = ast.Tuple(
                elts=[ast.Name(each, ast.Load()) for each in freevars],
                ctx=ast.Load())
            closure_f = ast.Name("Closure", ast.Load())

            return Builder.call(closure_f, [rhs_freevars, fp])
        else:
            return fp

    @staticmethod
    def call(f: ast.expr, args: List):
        return ast.Call(
            func=f, args=[ast.Tuple(elts=args, ctx=ast.Load())], keywords=[])

    @staticmethod
    def ret(v: ast.expr):
        return ast.Return(v)


def compile_to(dexp: DExp, filename: str, outfile: str):
    bd: Builder = Builder()

    def rec(dexp, code):
        if isinstance(dexp, DAssign):
            code.append(bd.store(dexp.reg, rec(dexp.val, code)))
            return ast.Constant(None)

        if isinstance(dexp, DClosure):
            new_code = []
            ret = rec(dexp.body, new_code)
            new_code.append(bd.ret(ret))
            return bd.make_fn(dexp.freevars, dexp.argnames, new_code, None)

        if isinstance(dexp, DIf):
            b1 = []
            b2 = []
            n = bd.new_id()
            cond = rec(dexp.cond, code)
            b1.append(bd.store(n, rec(dexp.br1, b1)))
            b2.append(bd.store(n, rec(dexp.br2, b2)))
            code.append(bd.branch(cond, b1, b2))
            return bd.load(n)
        if isinstance(dexp, DConst):
            v = dexp.v
            if isinstance(v, str):
                v = eval(v)
            return ast.Constant(v)

        if isinstance(dexp, DVar):
            return bd.load(dexp.sym)

        if isinstance(dexp, DBlock):
            elts = dexp.elts
            if not elts:
                return ast.Constant(None)
            hd, *tl = elts
            ret = rec(hd, code)
            for e in tl:
                code.append(ast.Expr(ret))
                ret = rec(e, code)
            return ret

        if isinstance(dexp, DCall):
            f = rec(dexp.f, code)
            args = [rec(arg, code) for arg in dexp.args]
            return bd.call(f, args)

        if isinstance(dexp, DList):
            elts = dexp.elts
            init = ast.Constant(())

            def reducer(a, b):
                b = rec(b, code)
                return bd.call(bd.load("LinkedList"), [b, a])

            return reduce(reducer, elts[::-1], init)

        if isinstance(dexp, DImport):
            return ast.Import(names=[
                ast.alias(
                    name=".".join((*dexp.paths, dexp.name)),
                    asname=dexp.actual)
            ])

        if isinstance(dexp, DAttr):
            return bd.attr(rec(dexp.subject, code), dexp.attr)

        if isinstance(dexp, DModule):
            code.append(
                bd.store(
                    dexp.modname,
                    bd.call(
                        bd.load("Module"), [
                            ast.Constant(dexp.modname),
                            ast.Constant(tuple(dexp.exports))
                        ])))
            for each in dexp.stmts:
                each = rec(each, code)
                if isinstance(each, ast.expr):
                    each = ast.Expr(each)
                code.append(each)
            for k1, k2 in dexp.exports:
                code.append(bd.store(k1, bd.load(k2)))

            return bd.load(dexp.modname)

        if isinstance(dexp, DLoc):
            v = rec(dexp.val, code)
            v.lineno = dexp.lineno
            v.col_offset = dexp.colno
            return v

    code = []
    rec(dexp, code)
    hd = ast.ImportFrom(
        module='rupy.rt',
        names=[
            ast.alias(name='Closure', asname=None),
            ast.alias(name='Module', asname=None),
            ast.alias(name='LinkedList', asname=None)
        ],
        level=0)
    mod = ast.Module([hd] + [v for k, v in bd.fc.items()] + code)
    ast.fix_missing_locations(mod)
    # from astpretty import pprint
    # pprint(mod)
    code_obj = compile(mod, filename, "exec")

    bytecode = importlib._bootstrap_external._code_to_timestamp_pyc(
        code_obj, time.time())
    with Path(outfile).open('wb') as f:
        f.write(bytecode)
