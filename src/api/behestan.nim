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

  NavParams* = object
    f, `seq`, su, nf: int


const
  apiRoot = "https://eduportal.shahed.ac.ir/frm"

  homeNavParams = NavParams(
    f: 1,
    `seq`: 1,
    su: 0,
    nf: 11130)

  stdInfoNavParams = NavParams(
    f: 11147,
    `seq`: 5,
    su: 3,
    nf: 11121)

  # "f": "11130",
  # "seq": "3",
  # "su": "3",

template toStr(smth): untyped = $(smth)


# proc inspect(j: JsonNode): JsonNode =
#   echo "-------------"
#   echo pretty j
#   j

func extractBehestanMust*(j: JsonNode): BehestanMust =
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


proc apiGetCapcha*(c: var CustomHttpClient): tuple[image, sessionId: string] =
  let
    resp = request(c, fmt"{apiRoot}/captcha/captcha.ashx", HttpGet)
    ck = initCookie resp.headers["Set-Cookie"]

  (resp.body, ck.value)

proc apiLogin*(c: var CustomHttpClient, username, password,
    capcha: string): JsonNode =
  func payload(username, password, capcha: string): JsonNode =
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
    $payload(username, password, capcha),
    accept = cJson,
    content = cJson)


proc apiNav*(c: var CustomHttpClient, np: NavParams,
    bm: BehestanMust): JsonNode =

  func payload(np: NavParams, bm: BehestanMust): JsonNode =
    %* {
      "r": {
        "act": ""},
      "aut": {
        "u": bm.userId,
        "ft": "0",
        "f": toStr np.f,
        "seq": toStr np.seq,
        "subfrm": "",
        "su": toStr np.su,
        "tck": bm.ticket,
        "ut": "0",
        "ttyp": "",
        "ri": "",
        "actsign": "1",
        "sid": bm.sessionId,
        "nft": "0",
        "nf": toStr np.nf,
        "sguid": "5a4e3d7e-4243-427b-9d5a-32b9eea3df71",
        "b": "0",
        "l": "0"}}

  parseJson body request(
    c,
    fmt"{apiRoot}/nav/nav.svc/",
    HttpPost,
    $payload(np, bm),
    accept = cJson,
    content = cJson)

proc apiProcessSysMenu0*(c: var CustomHttpClient, bm: BehestanMust): JsonNode =
  func payload(bm: BehestanMust): JsonNode =
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
    $payload(bm),
    accept = cJson,
    content = cJson)

proc apiProcessStdTotalInfoTrmStat*(c: var CustomHttpClient, bm: BehestanMust,
    username: string): JsonNode =
  func payload(bm: BehestanMust,
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
    $payload(bm, username),
    accept = cJson,
    content = cJson)

proc apiProcessStdPersonallyBh*(c: var CustomHttpClient, bm: BehestanMust,
    username: string): JsonNode =
  func payload(bm: BehestanMust,
      username: string): JsonNode =
    %* {
      "act": "08",
      "r": {
        "AUWs": username},
      "aut": {
        "u": bm.userId,
        "ft": "0",
        "f": "11121",
        "seq": "6",
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
    fmt"{apiRoot}/F1809_PROCESS_STD_Personally_BH/F1809_PROCESS_STD_Personally_BH.svc/",
    HttpPost,
    $payload(bm, username),
    accept = cJson,
    content = cJson)

proc apiEdu0301TermsTrmNoLookup*(c: var CustomHttpClient,
    bm: BehestanMust): JsonNode =
  func payload(bm: BehestanMust): JsonNode =
    %* {
      "act": "20",
      "r": {},
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
    fmt"{apiRoot}/Edu0301_Terms_TrmNo_Lookup/Edu0301_Terms_TrmNo_Lookup.svc/",
    HttpPost,
    $payload(bm),
    accept = cJson,
    content = cJson)

proc apiEdu1002UnvFacFacNoLookup*(c: var CustomHttpClient,
    bm: BehestanMust): JsonNode =
  func payload(bm: BehestanMust): JsonNode =
    %* {
      "act": "20",
      "r": {
        "A3zg": "1",
        "v1n": "1",
        "MaxHlp": 200},
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
    fmt"{apiRoot}/Edu1002_UnvFac_FacNo_Lookup/Edu1002_UnvFac_FacNo_Lookup.svc/",
    HttpPost,
    $payload(bm),
    accept = cJson,
    content = cJson)

proc apiEdu1021UnvBranchesBrnnoLookup*(c: var CustomHttpClient,
    bm: BehestanMust): JsonNode =
  func payload(bm: BehestanMust): JsonNode =
    %* {
      "act": "20",
      "r": {},
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
    fmt"{apiRoot}/Edu1021_UNVBRANCHES_Brnno_Lookup/Edu1021_UNVBRANCHES_Brnno_Lookup.svc/",
    HttpPost,
    $payload(bm),
    accept = cJson,
    content = cJson)


# XXX sguid: just random uuid4
# XXX calling APIs without calling nav API does not work

when isMainModule:
  var c = initCustomHttpClient()
  c.httpc.headers = defaultBehestanHeaders()

  writeFile "./temp.captcha.gif", c.apiGetCapcha.image

  let
    stdid = getEnv "BEHESTAN_STD_ID" 
    pass = getEnv "BEHESTAN_PASS"
  echo "pass: '", pass, "'"
  echo "capcha: "
  let
    aa = apiLogin(c, stdid, pass, readLine stdin)
    bb = apiNav(c, homeNavParams, extractBehestanMust aa)
    cc = apiProcessSysMenu0(c, extractBehestanMust bb)
    dd = apiNav(c, stdInfoNavParams, extractBehestanMust cc)
    # dd = apiNav(c, stdInfoNavParams, extractBehestanMust cc)
    ee = apiProcessStdTotalInfoTrmStat(c, extractBehestanMust dd, "992164019")

  writeFile "./temp/aa.json", pretty aa
  writeFile "./temp/bb.json", pretty bb
  writeFile "./temp/cc.json", pretty cc
  writeFile "./temp/dd.json", pretty dd
  writeFile "./temp/ee.json", pretty ee
