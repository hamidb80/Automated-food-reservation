import std/[strutils, uri, tables, strtabs, times, random,
  nre, htmlparser, json, os, cookies, strformat, httpclient]

import iterrr


type Content = enum
  cNot = ""
  cCsp = "application/csp-report"
  cForm = "application/x-www-form-urlencoded"


func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(s: StringTableRef): string =
  s.pairs.iterrr:
    map (k, v) => toCookie(k, v)
    strjoin "; "


proc applyHeaders(c: var HttpClient) =
  c.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/113.0"
  c.headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
  c.headers["Content-Type"] = "application/x-www-form-urlencoded"
  c.headers["Upgrade-Insecure-Requests"] = "1"
  c.headers["Sec-Fetch-Dest"] = "document"
  c.headers["Sec-Fetch-Mode"] = "navigate"
  c.headers["Sec-Fetch-Site"] = "same-origin"
  c.headers["Sec-Fetch-User"] = "?1"

proc updateCookie(client: var HttpClient, resp: Response) =
  var q = parseCookies client.headers.getOrDefault("Cookie").toString

  if "set-cookie" in resp.headers.table:
    for c in resp.headers.table["set-cookie"]:
      let qq = parseCookies c

      for k, v in qq:
        q[k] = v

  client.headers["Cookie"] = toCookies q

proc sendData*(
  client: var HttpClient,
  url: string,
  `method`: HttpMethod,
  content: Content = cNot,
  data: string = ""): Response =

  client.headers["Content-Type"] = $content
  result = client.request(url, `method`, data)
  client.headers.del "content-type"

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
