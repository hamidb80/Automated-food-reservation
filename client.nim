import std/[strutils, uri, tables, strtabs, os, cookies, strformat, httpclient]

import iterrr


type Content* = enum
  cNot = ""
  cCsp = "application/csp-report"
  cForm = "application/x-www-form-urlencoded"


func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(s: StringTableRef): string =
  s.pairs.iterrr:
    map (k, v) => toCookie(k, v)
    strjoin "; "


proc updateCookie*(client: var HttpClient, resp: Response) =
  var q = parseCookies client.headers.getOrDefault "Cookie"

  if "set-cookie" in resp.headers.table:
    for c in resp.headers.table["set-cookie"]:
      let qq = parseCookies c

      for k, v in qq:
        q[k] = v

  client.headers["Cookie"] = toCookies q


var counter = 0

proc sendData*(
  client: var HttpClient,
  url: string,
  `method`: HttpMethod,
  content: Content = cNot,
  data: string = "", 
  tempHeaders: openArray[tuple[header, value: string]] = @[]): Response =

  client.headers["Content-Type"] = $content
  var 
    varUrl = url
    redirected = false

  # apply temporary headers
  for (h,v) in tempHeaders:
    client.headers[h] = v

  while true:
    let m = 
      if redirected: HttpGet
      else: `method`
    
    result = client.request(varUrl, m, data)
    # client.headers.del "content-type"

    echo fmt"[{counter}]"
    echo "URL: ", url
    echo "Method: ", `method`
    echo "Status: ", result.code
    echo "Headers: "
    for k, h in client.headers.pairs:
      echo "  ", k, " = ", h
    if data.len > 0:
      echo "Body: ", data

    if result.body.len > 0:
      let p = "./temp/" / ($counter & ".html")
      writefile p, result.body
      echo "Result: ", p

    echo "\n"
    inc counter


    updateCookie client, result

    if result.code.is3xx:
      varUrl = result.headers["location"]
      redirected = true
    else:
      break

  # remove temporary headers
  for (h, _) in tempHeaders:
    client.headers.del h