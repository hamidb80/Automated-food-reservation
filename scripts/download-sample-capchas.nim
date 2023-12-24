import std/[httpclient, os, strutils, strformat]


func toStr(bytes: openArray[byte]): string =
  for b in bytes:
    result.add b.char

func cutAfter(s: string, patt: openArray[byte]): string =
  let i = s.rfind patt.toStr
  s[0..<i+patt.len]


when isMainModule:
  discard existsOrCreateDir "./temp"

  var
    howMany = parseInt paramStr 1
    client = newHttpClient(headers = newHttpHeaders {
      "Referer": "https://food.shahed.ac.ir/identity/login?signin=4921d8f61dbd48652f48ef179f186d5d"})

  for i in 1..howMany:
    let
      resp = client.request("https://food.shahed.ac.ir/api/v0/Captcha?id=1", HttpGet)
      name = fmt"./temp/capcha-{i:05}.jpg"

    writeFile name, resp.body.cutAfter([byte 0xff, 0xd9])
    echo name
