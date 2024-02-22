import std/[strformat, strutils, httpclient, os, random]

randomize()

proc newCaptchaUrl: string = 
  let n = rand 0..100
  "https://eduportal.shahed.ac.ir/frm/captcha/captcha.ashx?rr=1&x" & $n

proc batchDownload(limit: Slice[int]) =
  var
    lastImageLen = 0
    i = limit.a

  while i in limit:
    sleep 100
    let 
      c = newHttpClient()
      image = c.getContent newCaptchaUrl()
    if lastImageLen != len image:
      writeFile fmt"./temp/c-{i:05}.gif", image
      echo i
      inc i
      lastImageLen = len image

when isMainModule:
  if paramCount() != 2:
    quit "USAGE: app <start-number> <end-number>"
  else:
    let
      a = parseInt paramStr 1
      b = parseInt paramStr 2

    batchDownload a .. b
