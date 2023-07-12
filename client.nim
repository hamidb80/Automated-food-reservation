import std/[strutils, uri, tables, strtabs, os, cookies, strformat, httpclient]
import std/logging
import iterrr


type
  Content* = enum
    cNot = ""
    cCsp = "application/csp-report"
    cForm = "application/x-www-form-urlencoded"

  CustomHttpClient* = object
    httpc*: HttpClient
    counter*: int
    history*: seq[string]


var logger = newConsoleLogger()
addHandler logger


func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(s: StringTableRef): string =
  s.pairs.iterrr:
    map (k, v) => toCookie(k, v)
    strjoin "; "


proc initCustomHttpClient*: CustomHttpClient =
  result.httpc = newHttpClient(maxRedirects = 0)


proc updateCookie*(c: var CustomHttpClient, resp: Response) =
  var q = parseCookies c.httpc.headers.getOrDefault "Cookie"

  if "set-cookie" in resp.headers.table:
    for c in resp.headers.table["set-cookie"]:
      let qq = parseCookies c

      for k, v in qq:
        q[k] = v

  c.httpc.headers["Cookie"] = toCookies q


proc sendData*(
  c: var CustomHttpClient,
  url: string,
  `method`: HttpMethod,
  content: Content = cNot,
  data: string = "",
  tempHeaders: openArray[tuple[header, value: string]] = @[],
  maxRedirects = 10,
  ): Response =

  # apply temporary headers
  if data.len > 0:
    c.httpc.headers["Content-Type"] = $content

  for (h, v) in tempHeaders:
    c.httpc.headers[h] = v

  var
    currentUrl = url
    isRedirected = false

  for _ in 1..maxRedirects:
    c.history.add currentUrl

    let
      currentMethod =
        if isRedirected: HttpGet
        else: `method`

    result = c.httpc.request(currentUrl, currentMethod, data)

    info fmt"[{c.counter}]"
    info "URL: ", url
    info "Method: ", currentMethod
    info "Status: ", result.code
    info "Sent Headers: "
    for k, h in c.httpc.headers.pairs:
      info fmt"  {k} = {h}"
    # info "Resp Headers: "
    # for k, h in result.headers.pairs:
    #   info fmt"  {k} = {h}"
    if data.len > 0:
      info "Body: " & data

    if result.body.len > 0:
      let p = "./temp/" / ($c.counter & ".html")
      writefile p, result.body
      info "Result: ", p

    echo "\n"
    inc c.counter
    updateCookie c, result

    if result.code.is3xx:
      isRedirected = true
      currentUrl = result.headers["location"]
    else:
      break


  # remove temporary headers
  for (h, _) in tempHeaders:
    c.httpc.headers.del h
  c.httpc.headers.del "content-type"
