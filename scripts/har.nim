import std/[
  json,
  options,
  uri,
  httpclient,
  strutils,
  sugar]

import questionable

import ../src/client
import ../src/api/behestan

## object types are created by `nimjson`

type
  NilType = ref object
  HarObject = ref object
    log: Log
  Log = ref object
    version: string
    entries: seq[Entries]
  Entries = ref object
    request: Request
    response: Response
  Request = ref object
    bodySize: int
    `method`: string
    url: string
    httpVersion: string
    headers: seq[Headers]
    cookies: seq[Cookie]
    queryString: seq[NilType]
    headersSize: int
    postData: Option[PostData]
  Headers = ref object
    name: string
    value: string
  Cookie = ref object
    name: string
    value: string
  PostData = ref object
    mimeType: string
    text: string
  Response = ref object
    status: int
    statusText: string
    httpVersion: string
    headers: seq[Headers]
    cookies: seq[Cookie]
    content: Content
    redirectURL: string
    headersSize: int
    bodySize: int
  Content = ref object
    mimeType: string
    size: int
    text: ?string


func toHttpMethod(m: string): HttpMethod =
  case m
  of "POST": HttpPost
  else: HttpGet

# func deepUpdateImpl(j: var JsonNode, u: JsonNode) =
#   for k, v in u:

proc deepUpdate(j, u: JsonNode) =
  for k, v in u:
    case v.kind
    of JObject:
      deepUpdate j[k], v
    else:
      j[k] = v

func toJson(bm: BehestanMust): JsonNode = %*{
  "aut": {
    "sid": bm.sessionId,
    "u": bm.userId,
    "tck": bm.ticket}}

when isMainModule:
  var
    c = initCustomHttpClient()
    bh: BehestanMust = ("1", "1", "1")
    tck2 = ""
  let
    j = to(parseJson readfile "eduportal.shahed.ac.ir.har", HarObject)

  for e in j.log.entries:
    let
      u = e.request.url
      p = u.parseUri.path
      m = toHttpMethod e.request.`method`
      d = e.request.postData.map(p => parseJson p.text)

    # case p
    # of "/frm/loginapi/loginapi.svc/":
    #   discard

    # of "/frm/nav/nav.svc":
    #   discard

    # else:
    #   discard

    if endsWith(u, ".js") or endsWith(u, ".css") or endsWith(u, ".png"):
      continue
    else:
      let 
        resp = request(c, u, m, if issome d: $d.get else: "")
        ct = resp.headers["content-type"]
        data = body resp
        jdata = 
          if ct == "application/json": parseJson data
          else: nil

      if nil != jdata:
        bh = extractBehestanMust jdata

      case p
      of "/frm/captcha/captcha.ashx":
        writefile "./temp/capcha.png", data

      of "/frm/loginapi/loginapi.svc/":
        discard

      of "/frm/nav/nav.svc":
        tck2 = getStr data.parseJson{"oaut", "oa", "nmtck"}

      else:
        discard
