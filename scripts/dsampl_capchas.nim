import std/[strformat, httpclient, os]


const url = "https://eduportal.shahed.ac.ir/frm/captcha/captcha.ashx"
let c = newHttpClient()
var 
  lastImage = ""
  i = 1

while i < 1000:
  let image = getContent(c, url)
  sleep 1000
  if lastImage.len != image.len:
    writeFile fmt"./temp/c-{i:03}.gif", image
    inc i
    lastImage = image   