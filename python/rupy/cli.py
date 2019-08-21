from wisepy2 import wise
from pathlib import Path
from subprocess import check_call
import sys
import os


@wise
def rupy(filename: str, *, I: str = "./", out: str = "",run: bool = False):
    """
    I: include path
    """
    include_path = str(Path(I).expanduser())
    file = Path(filename)
    if out:
        out = Path(out).expanduser()
    else:
        out = file
    py_out = out.with_suffix(".py")
    pyc_out = out.with_suffix(".pyc")
    env = os.environ.copy()
    env['RUPYPATH'] = include_path
    check_call(["rml", str(file), str(py_out), str(pyc_out)], env=env)
    check_call([sys.executable, str(py_out)])
    if run:
        check_call([sys.executable, str(pyc_out)])

def runrupy():
    rupy(sys.argv[1:])