import std/[strformat, strutils, httpclient, os]

proc batchDownload(limit: Slice[int]) =
  let c = newHttpClient()
  var
    lastImageLen = 0
    i = limit.a

  while i in limit:
    let image = getContent(c, "https://eduportal.shahed.ac.ir/frm/captcha/captcha.ashx")
    sleep 1000
    if lastImageLen != len image:
      writeFile fmt"./temp/c-{i:03}.gif", image
      echo i
      inc i
      lastImageLen = len image

when isMainModule:
  if paramCount() != 2:
    echo "expected 2 but got: ", paramCount() - 1
    quit "USAGE: app <start-number> <end-number>"
  else:
    let
      a = parseInt paramStr 1
      b = parseInt paramStr 2

    batchDownload a .. b
