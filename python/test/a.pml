module Main where

foreign rupy.api

foreign rupy.rt

def println = api.println

infix cons 5 right
def cons = rt.LinkedList

def main = fn _ ->
    let l = 1 `cons` "2" `cons` [3, 4] in
    println l

let _ = main () in ()

