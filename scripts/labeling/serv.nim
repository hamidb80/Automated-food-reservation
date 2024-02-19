import std/[os, htmlgen]
import jester

proc findFile(pat:string): string =
  for path in walkFiles pat:
    return path.splitPath.tail

const 
  finalDir = "./final/"
  assetsDir = "./assets/"
  imgsDir = "./temp/"

routes:
  get "/":
    resp html(
      head(
        script(src = "assets/front.js")),
      body(
        `div`(id = "ROOT")))

  get "/assets/@path":
    resp readFile assetsDir / @"path"

  get "/image/next":
    resp findFile imgsDir / "*.gif"

  get "/image/@name":
    resp readFile imgsDir / @"name"

  get "/save/@img/@label/":
    let 
      parts = splitFile @"img"
      imgPath = imgsDir / @"img"
      destPath = finalDir / @"label" & parts.ext
    moveFile imgPath, destPath
    resp Http200
