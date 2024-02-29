import std/[strformat, strutils, httpclient, os, random]

randomize()


proc newCaptchaUrl: string = 
  let n = rand 0..100
  "https://eduportal.shahed.ac.ir/frm/captcha/captcha.ashx?rr=1&x" & $n

proc startDownload(dest: string, bound: Slice[int]) =
  let c = newHttpClient()
  var i = bound.a

  while i in bound:
    try:
      let image = c.getContent newCaptchaUrl()
      writeFile dest / fmt"c-{i:05}.gif", image
      echo i
      inc i

    except:
      echo "Error: ", getCurrentExceptionMsg()
      
when isMainModule:
  if paramCount() != 3:
    quit "USAGE: app <dest-dir> <start-number> <end-number>"
  else:
    let
      dest = paramStr 1
      a = parseInt paramStr 2
      b = parseInt paramStr 3

    startDownload dest, a .. b
