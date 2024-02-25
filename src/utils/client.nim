import std/[
  tables,
  strtabs,
  cookies,
  strformat,
  httpclient]

import iterrr


type
  Content* = enum
    cAnyThing = "*/*"
    cCsp = "application/csp-report"
    cForm = "application/x-www-form-urlencoded"
    cJson = "application/json"

  CustomHttpClient* = object
    h*: HttpClient
    cookies*: Table[string, string]

func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(stab: StringTableRef): string =
  iterrr stab.pairs:
    map (k, v) => toCookie(k, v)
    strjoin "; "

proc initCustomHttpClient*: CustomHttpClient = 
  CustomHttpClient(
    h: newHttpClient("Firefox Gecko", 0))

proc updateCookie*(h: var HttpClient, resp: Response) =
  var q = parseCookies h.headers.getOrDefault "Cookie"

  if "set-cookie" in resp.headers.table:
    for c in resp.headers.table["set-cookie"]:
      let qq = parseCookies c

      for k, v in qq:
        q[k] = v

  h.headers["Cookie"] = toCookies q

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
  c.h.headers["Accept"] = $accept
  if data.len > 0:
    c.h.headers["Content-Type"] = $content

  for (h, v) in tempHeaders:
    c.h.headers[h] = v

  var
    currentUrl = url
    isRedirected = false

  for _ in 1..maxRedirects:
    let
      currentMethod =
        if isRedirected: HttpGet
        else: `method`

    result = c.h.request(currentUrl, currentMethod, data)
    updateCookie c.h, result

    if is3xx code result:
      isRedirected = true
      currentUrl = result.headers["location"]
    else:
      break

  # remove temporary headers
  c.h.headers.del "content-type"
  c.h.headers.del "Accept"
  for (h, _) in tempHeaders:
    c.h.headers.del h
