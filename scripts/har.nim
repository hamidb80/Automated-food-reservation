import std/[json, options, uri, httpclient]
import questionable

## object types are created by `nimjson`

type
  NilType = ref object
  HarObject = ref object
    log: Log
  Log = ref object
    version: string
    creator: Creator
    browser: Browser
    pages: seq[Pages]
    entries: seq[Entries]
  Creator = ref object
    name: string
    version: string
  Browser = ref object
    name: string
    version: string
  Pages = ref object
    id: string
    pageTimings: PageTimings
    startedDateTime: string
    title: string
  PageTimings = ref object
    onContentLoad: int
    onLoad: int
  Entries = ref object
    startedDateTime: string
    request: Request
    response: Response
    cache: Cache
    timings: Timings
    time: int
    # `_securityState`: string
    pageref: string
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
    params: seq[NilType]
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
    text: string
  Cache = ref object
  Timings = ref object
    blocked: int
    dns: int
    ssl: int
    connect: int
    send: int
    wait: int
    receive: int



let
  j = to(parseJson readfile "eduportal.shahed.ac.ir.har", HarObject)
  c = newHttpClient()


for e in j.log.entries:
  echo e.request.url.parseUri.path

  case e.request.`method`
  of "POST":
    let d = e.request.postData.?text |? "null"
    # echo pretty parseJson d
    # echo ""
    echo c.post(e.request.url, d).body

  else:
    discard
