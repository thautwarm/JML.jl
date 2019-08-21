class Closure(tuple):
    def __call__(self, args):
        return self[1](self[0], args)

    def __repr__(self):
        return repr(self[1])


class LinkedList(tuple):
    def __hash__(self):
        x = self
        hash_ = hash
        ret = 1725144
        while x is not ():
            ret ^= hash_(x[0]) + 3
            x = x[1]
        return ret

    def __gt__(self, y):
        if isinstance(y, LinkedList):
            return False
        x = self
        while x is not () and y is not ():
            a, b = x[0], y[0]
            if a > b:
                return True

            x = x[1]
            y = y[1]
        return x is not ()

    def __eq__(self, y):
        if isinstance(y, LinkedList):
            return False
        x = self
        while x is not () and y is not ():
            a, b = x[0], y[0]
            if a < b or a > b:
                return False

            x = x[1]
            y = y[1]
        return y is () and x is ()

    def __iter__(self):
        xs = self
        while xs is not ():
            yield xs[0]
            xs = xs[1]

    def __repr__(self):
        ret = ', '.join(map(repr, self))
        return f"[{ret}]"


class Module:
    def __init__(self, a):
        name, exports = a
        self.name = name
        self.exports = exports
        self.glob = {}

    def do_export(self, kv):
        k, v = kv
        self.glob[k] = v

    def do_import(self, ks):
        k, = ks
        return self.glob[k]

    def __repr__(self):
        return f'<module {self.name}>'
