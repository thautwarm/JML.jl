from typing import *
from dataclasses import dataclass


class DExp:
    pass


@dataclass
class DAssign(DExp):
    reg: str
    val: DExp


@dataclass
class DClosure(DExp):
    freevars: List[str]
    argnames: List[str]
    body: DExp


@dataclass
class DIf(DExp):
    cond: DExp
    br1: DExp
    br2: DExp


@dataclass
class DConst(DExp):
    v: Any


@dataclass
class DVar(DExp):
    sym: str


@dataclass
class DBlock(DExp):
    elts: List[DExp]


@dataclass
class DCall(DExp):
    f: DExp
    args: List[DExp]


@dataclass
class DList(DExp):
    elts: List[DExp]


@dataclass
class DLoc(DExp):
    lineno: int
    colno: int
    val: DExp


@dataclass
class DImport(DExp):
    paths: List[str]
    name: str
    actual: str


@dataclass
class DAttr(DExp):
    subject: DExp
    attr: str


@dataclass
class DModule(DExp):
    modname: str
    exports: List[Tuple[str, str]]
    stmts: List[DExp]
