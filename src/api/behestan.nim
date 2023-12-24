import std/[
  strformat,
  httpclient,
  json,
  os]

import cookiejar

import ../client


type
  BehestanMust* = tuple
    sessionId, userId, ticket: string


const apiRoot = "https://eduportal.shahed.ac.ir/frm"


func extractBehestanMust(j: JsonNode): BehestanMust =
  (
    getStr j["aut"]["sid"],
    getStr j["aut"]["u"],
    getStr j["aut"]["tck"])

func defaultBehestanHeaders: HttpHeaders =
  newHttpHeaders {
    "Referer": "https://eduportal.shahed.ac.ir/index.html",
    "sec-ch-ua-mobile": "?0",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "sec-ch-ua-platform": "Windows"}


proc apiGetCapcha(c: var CustomHttpClient): tuple[image, sessionId: string] =
  let
    resp = request(c, fmt"{apiRoot}/captcha/captcha.ashx", HttpGet)
    ck = initCookie resp.headers["Set-Cookie"]

  (resp.body, ck.value)

proc apiLogin(c: var CustomHttpClient, username, password,
    capcha: string): JsonNode =
  func genData(username, password, capcha: string): JsonNode =
    %*{
      "act": "09",
      "r": {
        "l": username,
        "p": password,
        "c": capcha,
        "code": "",
        "ticket": "",
        "d": "0"},
      "aut": {
        "ft": "0",
        "f": "1",
        "u": "0",
        "seq": "1",
        "tck": "1",
        "lt": "1",
        "su": "1"}}

  parseJson body request(
    c,
    fmt"{apiRoot}/loginapi/loginapi.svc/",
    HttpPost,
    $genData(username, password, capcha),
    accept = cJson,
    content = cJson)

proc apiNav(c: var CustomHttpClient, bm: BehestanMust): JsonNode =
  func genData(bm: BehestanMust): JsonNode =
    %* {
      "r": {
        "act": ""},
      "aut": {
        "u": bm.userId,
        "ft": "0",
        "f": "1",
        "seq": "1",
        "subfrm": "",
        "su": "0",
        "tck": bm.ticket,
        "ut": "0",
        "ttyp": "",
        "ri": "",
        "actsign": "1",
        "sid": bm.sessionId,
        "nft": "0",
        "nf": "11130",
        "sguid": "5a4e3d7e-4243-427b-9d5a-32b9eea3df71",
        "b": "0",
        "l": "0"}}

  parseJson body request(
    c,
    fmt"{apiRoot}/nav/nav.svc/",
    HttpPost,
    $genData(bm),
    accept = cJson,
    content = cJson)

proc apiProcessSysMenu0(c: var CustomHttpClient, bm: BehestanMust): JsonNode =
  func genData(bm: BehestanMust): JsonNode =
    %* {
      "act": "10",
      "r": {},
      "aut": {
        "u": bm.userId,
        "ft": "0",
        "f": "11130",
        "seq": "2",
        "subfrm": "0",
        "su": "3",
        "tck": bm.ticket,
        "ut": "0",
        "ttyp": "",
        "ri": "",
        "actsign": "1",
        "sid": bm.sessionId,
        "incoaut": "1"}}

  parseJson body request(
    c,
    fmt"{apiRoot}/F0213_PROCESS_SYSMENU0/F0213_PROCESS_SYSMENU0.svc/",
    HttpPost,
    $genData(bm),
    accept = cJson,
    content = cJson)

proc apiProcessStdTotalInfoTrmStat(c: var CustomHttpClient, bm: BehestanMust,
    username: string): JsonNode =
  func genData(bm: BehestanMust,
      username: string): JsonNode =
    %* {
      "act": "20",
      "r": {
        "AUWo": username},
      "aut": {
        "u": bm.userId,
        "ft": "0",
        "f": "11147",
        "seq": "5",
        "subfrm": "0",
        "su": "3",
        "tck": bm.ticket,
        "ut": "0",
        "ttyp": "2",
        "ri": "",
        "actsign": "1",
        "sid": bm.sessionId}}

  parseJson body request(
    c,
    fmt"{apiRoot}/F1825_PROCESS_STDTOTALINFOTrmStat_BEH/F1825_PROCESS_STDTOTALINFOTrmStat_BEH.svc/",
    HttpPost,
    $genData(bm, username),
    accept = cJson,
    content = cJson)


when isMainModule:
  var c = initCustomHttpClient()
  c.httpc.headers = defaultBehestanHeaders()

  writeFile "./temp.png", c.apiGetCapcha.image

  echo "capcha: "
  let
    rr = apiLogin(c, "992164019", getEnv "SHAHED_PASS", readLine stdin)
    cc = apiNav(c, extractBehestanMust rr)
    dd = apiProcessSysMenu0(c, extractBehestanMust cc)
    ee = apiProcessStdTotalInfoTrmStat(c, extractBehestanMust dd, "992164019")

  writeFile "./temp/dd.json", pretty dd
  writeFile "./temp/ee.json", pretty ee
