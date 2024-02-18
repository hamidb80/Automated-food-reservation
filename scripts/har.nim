import std/[
  json,
  options,
  strutils,
  mimetypes]


var db = block: 
  var t = newMimetypes()
  register t, "woff2", "application/font-woff2"
  register t, "woff", "font/x-woff"
  register t, "json", "application/json"
  t

proc ext(mime: string): string =
  getExt db, mime


proc summary(j: JsonNode): JsonNode =
  result = newJArray()

  for e in j{"log", "entries"}:
    let
      req = e["request"]
      url = getStr req["url"]
      m = req["method"]
      d =
        if "postData" in req:
          parseJson getStr req{"postData", "text"}
        else:
          newJNull()

      resp = e["response"]
      s = getint resp["status"]
      c = (getStr resp{"content", "mimeType"}).split(';')[0]
      co = resp{"content", "text"}
      r =
        if co == nil:
          newJNull()
        else:
          try:
            parseJson getStr co 
          except:
            co


    const useless = [
      "jpg", "jpeg", "png", "gif", "jfif", "ico",
      "html", "js", "css", "webmanifest",
      "ttf", "woff2", "woff"]
  
    if ("captcha.ashx" in url) or (c.ext notin useless): 
      result.add %*{
        "req": {
          "url": url,
          "method": m,
          "payload": d,
          "cookies": req["cookies"],
          # "headers": req["headers"],
        },
        "resp": {
          "status": s,
          "mime": c,
          "data": r,
          "cookies": resp["cookies"],
          # "headers": resp["headers"],
        }
      }


when isMainModule:
  writeFile "temp.json":
    pretty summary parseJson readfile "eduportal.shahed.ac.ir.har"
