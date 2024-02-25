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

  CookieTab = Table[string, string]

  CustomHttpClient* = object
    http*: HttpClient
    cookies*: CookieTab

func toCookie(name, val: string): string =
  fmt"{name}={val}"

func toCookies(stab: CookieTab): string =
  iterrr stab.pairs:
    map (k, v) => toCookie(k, v)
    strjoin "; "

proc initCustomHttpClient*: CustomHttpClient = 
  CustomHttpClient(
    http: newHttpClient("Firefox Gecko", 0))

proc updateCookie*(cookies: var CookieTab, resp: Response) =
  for c in resp.headers.table.getOrDefault "set-cookie":
    for k, v in parseCookies c:
      cookies[k] = v

proc request*(
  c: var CustomHttpClient,
  url: string,
  mthd = HttpGet,
  data = "",
  tempHeaders: sink HttpHeaders = newHttpHeaders(),
  accept = cAnyThing,
  content = cAnyThing,
  maxRedirects = 10,
): Response =
  var
    currentUrl = url
    isRedirected = false

  if data.len > 0:
    tempHeaders["Content-Type"] = $content
  tempHeaders["Accept"] = $accept

  for _ in 1..maxRedirects:
    let currentMethod =
      if isRedirected: HttpGet
      else: mthd

    tempHeaders["Cookie"] = toCookies c.cookies
    result = c.http.request(currentUrl, currentMethod, data, tempHeaders)
    updateCookie c.cookies, result

    if is3xx code result:
      isRedirected = true
      currentUrl = result.headers["location"]
    else:
      break
