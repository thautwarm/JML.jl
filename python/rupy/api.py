def println(args):
    print(*args)


def py_call(args):
    f, args, kwargs = args
    args = list(args)
    kwargs = dict([tuple(e) for e in kwargs])
    return f(*args, **kwargs)
