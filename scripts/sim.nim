import std/[
  json,
  os,
  httpclient,
  uri,
  tables,
  strtabs,
  strutils]

type
  Ctx = Table[string, string]

## $SESSION
##
## $STD_NUMBER
## $PASSWORD
## $CAPTCHA
##
## $USER_ID
## $LT
## $CK_STD_NO
##
## $TCK_<N>

proc applyCtx(j: JsonNode, ctx: Ctx): JsonNode =
  case j.kind
  of JObject:
    var acc = newJObject()
    for k, v in j:
      acc[k] = applyCtx(v, ctx)
    acc

  of JArray:
    var acc = newJArray()
    for v in j:
      add acc, applyCtx(v, ctx)
    acc

  of JString:
    let s = getstr j
    if startsWith(s, '$'): %ctx[s]
    else: j

  else: j

func updateCtxByBody(mock, src: JsonNode, ctx: var Ctx) =
  case mock.kind
  of JObject:
    for k, m in mock:
      # if k in src:
      updateCtxByBody(m, src[k], ctx)

  of JArray:
    for i in 0 ..< len mock:
      updateCtxByBody(mock[i], src[i], ctx)

  of JString:
    let m = getstr mock
    if startsWith(m, '$'):
      ctx[m] = getstr src

  else: 
    discard

proc updateCtxByCookie(
  cookiesMock: JsonNode,
  src: StringTableRef,
  ctx: var Ctx
) =
  for ck in cookiesMock:
    let
      name = getstr ck["name"]
      val = getstr ck["value"]

    if startsWith(val, '$'):
      ctx[val] = src[name]


func joinCookieHeader(cks: JsonNode, ctx: Ctx): string =
  for ck in cks:
    add result, getstr ck["name"]
    add result, "="
    add result, ctx[getstr ck["value"]]
    add result, "; "

func makeHeaders(cookies: string): HttpHeaders =
  newHttpHeaders {
    "Cookie": cookies,
    "content-type": "application/json",
    # "Host": "eduportal.shahed.ac.ir",
    # "User-Agent" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0",
    # "Connection":"keep-alive",
    # "Referer": "https://eduportal.shahed.ac.ir/index.html",
    # "sec-ch-ua-mobile": "?0",
    # "sec-ch-ua-platform": "Windows"
  }

func parseSetCookie(s: string): tuple[name, val: string] =
  let
    parts = s.split(';')
    single = parts[0].split('=')

  (single[0], single[1])

func accSetCookie(resp: Response): StringTableRef = 
  if "set-cookie" in resp.headers.table:
    var acc = newStringTable()
    for ck in seq[string](resp.headers["set-cookie"]):
      let (name, val) = parseSetCookie ck
      acc[name] = val

    acc
  else:
    newStringTable()

proc run(
  client: HttpClient,
  ctx: var Ctx,
  entry: JsonNode,
  answers: var seq[JsonNode]
) =
  let
    url = getstr entry["req"]["url"]
    mthd = getstr entry["req"]["method"]

    bdy = block: # req.payload <-
      let t = entry["req"]["payload"]
      if t == newJNull(): ""
      else: $applyCtx(t, ctx)

    # req.cookies <-
    cksstr = joinCookieHeader(entry["req"]["cookies"], ctx)
    hds = makeHeaders(cksstr)

  echo "------------------------"
  echo mthd, ' ', url
  let resp = request(client, url, mthd, bdy, hds)

  # resp.cookies ->
  let h = accSetCookie resp
  # debugecho "headers: ", resp.headers.table
  # debugecho "expected cookies": entry["resp"]["cookies"]
  updateCtxByCookie(
    entry["resp"]["cookies"],
    h,
    ctx)

  if "captcha.ashx" in url:
    writeFile "temp.captcha.gif", body resp
    echo "enter captcha: "
    ctx["$CAPTCHA"] = readLine stdin

  else:
    # resp.body ->
    let b = parseJson body resp
    add answers, b
    # debugecho "\n::::::::::::::::::\n"
    # debugecho "expected data: ", pretty entry["resp"]["data"]
    # debugecho "\n>>>>>>>>>>>>>>>>>>\n"
    # debugecho "response data: ", pretty b
    # debugecho "\n<<<<<<<<<<<<<<<<<<\n"
    updateCtxByBody entry["resp"]["data"], b, ctx

## in windows use $env:VARNAME=...
## in linux   use export VARNAME=...

proc simulate(summary: JsonNode) =
  var
    client = newHttpClient()
    acc: seq[JsonNode]
    ctx = toTable {
      "$STD_NUMBER": getenv "BEHESTAN_STD_ID",
      "$PASSWORD": getenv "BEHESTAN_PASS",
      "$CAPTCHA": ""}

  for entry in summary:
    run client, ctx, entry, acc

  writeFile "temp.result.json", pretty %acc
  # var acc2: seq[JsonNode]
  # var acc3: string
  # for j in acc[^1]["rset"]["grd"]:
  #   add acc2, parseJson getStr j["struc"]
  #   add acc3, getStr j["xml"]
  # writeFile "temp.result.final.json", pretty %acc2
  # writeFile "temp.result.final.xml",  acc3
  echo "DONE !!!!"

when isMainModule:
  simulate parseJson readFile "./scripts/working-test1.json"
