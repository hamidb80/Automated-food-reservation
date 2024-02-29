import std/[os, strformat, strutils]
import mummy, mummy/routers


proc findFile(pat:string): string =
  for path in walkFiles pat:
    return path.splitPath.tail

template resp(content): untyped {.dirty.} = 
  respond request, 200, emptyHttpHeaders(), content

proc genHandlr(assetsDir, imgsDir, finalDir : string): RequestHandler = 
  proc(request: Request) =
    let secs = request.path.split '/'
    resp:
      case secs[1]
      of "": """<!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <script src="/assets/front.js" defer></script>
        </head>
        <body>
          <div id="ROOT"></div>
        </body>
        </html>"""
      
      of "assets":
        readFile assetsDir / secs[2]

      of "next-image": 
        findFile imgsDir / "*.gif"

      of "get-image":
        readFile imgsDir / secs[2]

      of "save":
        let 
          ext = splitFile(secs[2]).ext
          imgPath = imgsDir / secs[2]
          destPath = finalDir / secs[3] & ext
        moveFile imgPath, destPath
        ""

      else:
        raise newException(ValueError, "did not match")

when isMainModule:
  if paramCount() != 4:
    quit "USAGE: app <port> <assets-dir> <raw-images-dir> <dest-dir>"
  
  let 
    p = parseint paramStr 1
    assetsDir = paramStr 2
    rawImgDir = paramStr 3
    destDir = paramStr 4
    router = Router(notFoundHandler: genHandlr(
      assetsDir, 
      rawImgDir, 
      destDir))
  
  echo fmt"Serving on http://localhost:{p}"
  serve newServer router, Port p
