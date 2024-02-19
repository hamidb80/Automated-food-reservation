import std/[
  strformat,
  strutils,
  sequtils,
  json,
  nre,
  uri,
  htmlparser,
  xmltree,
  random,
  macros]

import ../client, std/httpclient
import ../utils

import karax/[karaxdsl, vdom]
import macroplus, iterrr

# ----- types -----

type
  Rial* = distinct int

  FinancialInfoState* = enum
    fisAll = 1
    fisLast = 2

# ----- consts -----

const
  foodsEmoji = {
    "ماکارونی": "🍝",  # Spaghetti
    "مرغ": "🍗",            # Chicken
    "کره": "🧈",            # Butter
    "ماهی": "🐟",          # Fish
    "برنج": "🍚",          # Rice
    "پلو": "🍚",            # Rice
    "میگو": "🦐",          # Shrimp
    "خورشت": "🍛",        # Stew
    "کوکو": "🧆",          # koo koooooo
    "کتلت": "🥮",          # cutlet
    "زیره": "🍘",          # Caraway
    "رشته": "🍜",          # String
    "کباب": "🥓",          # Kebab
    "ماهیچه": "🥩",      # Muscle
    "مرگ": "💀",            # Death
    "خالی": "🍽️",       # Nothing
    "گوجه": "🍅",          # Tomamto
    "سوپ": "🥣",            # Soup
    "قارچ": "🍄",          # Mushroom
    "کرفس": "🥬",          # Leafy Green
    "بادمجان": "🍆",    # Eggplant
    "هویج": "🥕",          # Carrot
    "پیاز": "🧅",          # Onion
    "سیب زمینی": "🥔", # Potato
    "سیر": "🧄",            # Garlic
    "لیمو": "🍋",          # Lemon
    "آلو": "🫐",            # Plum
    "زیتون": "🫒",        # Olive

    "دوغ": "🥛",            # Dough
    "ماست": "⚪",           # Yogurt
    "دلستر": "🍺",        # Beer
    "سالاد": "🥗",        # Salad
    "نمک": "🧂",            # Salt
    "یخ": "🧊",              # Ice
  }

# ----- utils -----

func repl(match: RegexMatch): string =
  match.captures[0].entityToUtf8

func toHumanReadable(s: string): string =
  {.cast(noSideEffect).}:
    s.replace(re"&(\w+);", repl)

# ----- working with data objects -----

# ----- API -----

const
  baseUrl* = "https://food.shahed.ac.ir"
  userPage* = baseUrl & "/#!/UserIndex"

func wrapUrl(path: string): string =
  baseUrl & path

proc freshCaptchaUrl*: string =
  wrapUrl "/api/v0/Captcha?id=" & $(rand 1..1000000)


proc extractLoginPageData*(htmlPage: string): JsonNode =
  const
    headSig = "{&quot;loginUrl&quot"
    tailSig = ",&quot;custom&quot;:null}"

  let
    s = htmlPage.find headSig
    e = htmlPage.find tailSig

  htmlPage[s ..< e + tailSig.len]
  .toHumanReadable
  .parseJson

func extractLoginPath(loginPageData: JsonNode): string =
  getStr loginPageData["loginUrl"]

func extractLoginXsrfToken(loginPageData: JsonNode): string =
  getStr loginPageData{"antiForgery", "value"}

func loginForm(user, pass, captcha, token: string): auto =
  {
    "username": user,
    "password": pass,
    "Captcha": captcha,
    "idsrv.xsrf": token}

func cleanLoginCaptcha(binary: string): string =
  binary.cutAfter jpegTail

func genRedirectTransactionForm*(data: JsonNode): VNode =
  ## Code: <StatusCode>,
  ## Result: <Msg>,
  ## Action: <RedirectUrl>,
  ## ActionType: <HttpMethod>,
  ## Tokenitems: Array[FormInput]
  ##    {"Name": "...", "Value": "..."}

  buildHtml tdiv:
    form(
      id = "X",
      action = getstr data["Action"],
      `method` = getstr data["ActionType"]
    ):
      for token in data["Tokenitems"]:
        input(
          name = getstr token["Name"],
          value = getstr token["Value"])

    script:
      verbatim "document.getElementById('X').submit()"

# ----- convertors -----

func toBool*(i: int): bool =
  i == 1

func parseBool*(s: string): bool =
  toBool parseInt s

func parseRial*(s: string): Rial =
  Rial parseInt s

# ----- meta programming -----

template self(smth): untyped = smth

template convertFn(t: type string): untyped = self
template convertFn(t: type bool): untyped = parseBool
template convertFn(t: type int): untyped = parseInt
template convertFn(t: type Rial): untyped = parseRial
template convertFn(t: type JsonNode): untyped = parseJson


macro staticAPI(pattern, typecast, url): untyped =
  let
    (name, extraArgs) =
      case pattern.kind
      of nnkIdent: (pattern, @[])
      of nnkObjConstr: (pattern[ObjConstrIdent], pattern[ObjConstrFields])
      else: raise newException(ValueError,
        "invalid API pattern: " & treeRepr pattern)

    body = quote:
      let data = c.request(baseUrl & `url`, accept = cJson).body
      try:
        convertFn(`typecast`)(data)
      except:
        raise newException(ValueError, "the data was: " & data)

    args = extraArgs.mapIt newIdentDefs(it[0], it[1])

  newProc(name.exported,
    @[typecast, newIdentDefs(
      ident "c",
      newTree(nnkVarTy, ident "CustomHttpClient"))] & args,
    body)

# --- json API

staticAPI isCaptchaEnabled, bool, "/api/v0/Captcha?isactive=wehavecaptcha"
staticAPI rolePermissions, JsonNode, "/api/v0/RolePermissions"
staticAPI personalInfo, JsonNode, "/api/v1/Student/GetCurrent"
staticAPI centerInfo, JsonNode, "/api/v0/CenterInfo"
staticAPI credit, Rial, "/api/v0/Credit"
staticAPI personalNotifs, JsonNode, "/api/v0/PersonalNotification?postname=LastNotifications"
staticAPI instantSale, JsonNode, "/api/v0/InstantSale"
staticAPI availableBanks, JsonNode, "/api/v0/Chargecard"
staticAPI ping(unixtime: int), JsonNode, fmt"/signalr/ping?_={unixtime}"
staticAPI financialInfo(state: FinancialInfoState), JsonNode,
  fmt"/api/v0/ReservationFinancial?state={state.int}"

staticAPI reservation(week: int), JsonNode,
  fmt"/api/v0/Reservation?lastdate=&navigation={week*7}"

staticAPI registerInvoice(bid: int, amount: Rial), JsonNode,
  fmt"/api/v0/Chargecard?IpgBankId={bid}&accommodationId=0&amount={amount.int}&type=1"

proc prepareBankTransaction*(c: var CustomHttpClient,
    invoiceId: int,
    amount: Rial
): JsonNode =

  let
    data = %* {
      "Applicant": "web",
      "amount": $amount.int,
      "invoicenumber": invoiceId}

    req = request(
      c,
      wrapUrl "/api/v0/Chargecard", HttpPost,
      $data,
      content = cJson,
      accept = cJson)

  parseJson body req

# --- login API

proc loginBeforeCaptcha*(c: var CustomHttpClient
  ): tuple[loginPageData: JsonNode, captchaBinary: string] =

  let resp = c.request(wrapUrl "", HttpGet)
  assert resp.code.is2xx

  result.loginPageData = extractLoginPageData body resp
  result.captchaBinary = cleanLoginCaptcha body request(
    c,
    freshCaptchaUrl(),
    HttpGet,
    tempHeaders = {"Referer": "https://food.shahed.ac.ir/identity/login?"})

proc loginAfterCaptcha*(c: var CustomHttpClient,
  loginPageData: JsonNode,
  uname, pass, capcha: string
) =

  let
    loginurl = wrapUrl extractLoginPath loginPageData
    xsrf = extractLoginXsrfToken loginPageData
    data = loginForm(uname, pass, capcha, xsrf)
    resp = c.request(loginurl, HttpPost, encodeQuery data, content = cForm)

  assert is2xx code resp

  let
    form = resp.body.parsehtml.findAll("form")[0]
    submitUrl = form.attr "action"
    inputs = form.findall("input").items.iterrr:
      map el => (el.attr("name"), el.attr("value"))
      toseq()

  if submitUrl.startsWith "{{":
    raise newException(ValueError, "login failed")

  else:
    let resp = c.request(submitUrl, HttpPost, encodeQuery inputs,
        content = cForm)
    assert is2xx code resp
