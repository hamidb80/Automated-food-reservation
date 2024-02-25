import std/[os, strformat, strutils]
import mummy, mummy/routers


template resp(content): untyped {.dirty.} = 
  respond request, 200, emptyHttpHeaders(), content

when isMainModule:
  let p = 5000
  echo fmt"Serving on http://localhost:{p}"
  serve newServer Router(notFoundHandler: here), Port p
