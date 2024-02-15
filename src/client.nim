import std/[
  strutils,
  uri,
  tables,
  strtabs,
  cookies,
  strformat,
  httpclient,
  logging]

import iterrr


type
  Content* = enum
    cAnyThing = "*/*"
    cCsp = "application/csp-report"
    cForm = "application/x-www-form-urlencoded"
    cJson = "application/json"

  CustomHttpClient* = object
    httpc*: HttpClient
    counter*: int


var logger = newConsoleLogger(lvlInfo)
addHandler logger


func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(s: StringTableRef): string =
  s.pairs.iterrr:
    map (k, v) => toCookie(k, v)
    strjoin "; "

proc updateCookie*(c: var CustomHttpClient, resp: Response) =
  var q = parseCookies c.httpc.headers.getOrDefault "Cookie"

  if "set-cookie" in resp.headers.table:
    for c in resp.headers.table["set-cookie"]:
      let qq = parseCookies c

      for k, v in qq:
        q[k] = v

  c.httpc.headers["Cookie"] = toCookies q

proc initCustomHttpClient*: CustomHttpClient =
  result.httpc = newHttpClient(maxRedirects = 0)

proc request*(
  c: var CustomHttpClient,
  url: string,
  `method` = HttpGet,
  data = "",
  tempHeaders: openArray[tuple[header, value: string]] = @[],
  maxRedirects = 10,
  accept = cAnyThing,
  content = cAnyThing,
): Response =

  # apply temporary headers
  c.httpc.headers["Accept"] = $accept
  if data.len > 0:
    c.httpc.headers["Content-Type"] = $content


  for (h, v) in tempHeaders:
    c.httpc.headers[h] = v

  var
    currentUrl = url
    isRedirected = false

  for _ in 1..maxRedirects:
    let
      currentMethod =
        if isRedirected: HttpGet
        else: `method`

    result = c.httpc.request(currentUrl, currentMethod, data)

    when defined debug:
      info fmt"[{c.counter}]"
      info currentMethod, " to ", url
      info "Status: ", result.code
      debug "Sent Headers: "
      for k, h in c.httpc.headers.pairs:
        debug fmt"  {k} = {h}"
      if data.len > 0:
        debug "Body: " & data
      if result.body.len > 0:
        let p = "./temp/" / ($c.counter & ".html")
        writefile p, result.body
        debug "Result: ", p

    inc c.counter
    updateCookie c, result

    if result.code.is3xx:
      isRedirected = true
      currentUrl = result.headers["location"]
    else:
      break

  # remove temporary headers
  c.httpc.headers.del "content-type"
  c.httpc.headers.del "Accept"
  for (h, _) in tempHeaders:
    c.httpc.headers.del h
