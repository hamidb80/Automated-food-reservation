import std/[strformat, strutils, sequtils, json, nre, uri, htmlparser, xmltree,
    random, macros]
import client, std/httpclient
import utils
import macroplus, iterrr

# ----- types -----

type
  Rial* = distinct int

  FinancialInfoState* = enum
    fisAll = 1
    fisLast = 2

# ----- consts -----

const
  baseUrl* = "https://food.shahed.ac.ir"
  apiv0* = baseUrl & "/api/v0"

  foods = {
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
  s.replace(re"&(\w+);", repl)

# ----- working with data objects -----

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

func extractLoginUrl(loginPageData: JsonNode): string =
  baseUrl & loginPageData["loginUrl"].getStr

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

# ----- convertors -----

func toBool*(i: int): bool =
  i == 1

func parseBool*(s: string): bool =
  toBool parseInt s

func parseRial*(s: string): Rial =
  Rial parseInt s

# ----- meta programming -----

template convertFn(t: type bool): untyped = parseBool
template convertFn(t: type int): untyped = parseInt
template convertFn(t: type Rial): untyped = parseRial
template convertFn(t: type JsonNode): untyped = parseJson


macro defAPI(pattern, typecast, url): untyped =
  let
    (name, extraArgs) =
      case pattern.kind
      of nnkIdent: (pattern, @[])
      of nnkObjConstr: (pattern[ObjConstrIdent], pattern[ObjConstrFields])
      else: raise newException(ValueError,
        "invalid API pattern: " & treeRepr pattern)

    body = quote:
      let data = c.request(apiv0 & `url`, accept = cJson).body
      convertFn(`typecast`)(data)

    args = extraArgs.mapIt newIdentDefs(it[0], it[1])

  newProc(name.exported,
    @[typecast, newIdentDefs(
      ident "c",
      newTree(nnkVarTy, ident "CustomHttpClient"))] & args,
    body)

# ----- API -----

const userPage* = baseUrl & "/#!/UserIndex"

proc freshCaptchaUrl*: string =
  apiv0 & "/Captcha?id=" & $(rand 1..1000000)

# --- json API

defAPI isCaptchaEnabled, bool, "/Captcha?isactive=wehavecaptcha"
defAPI personalInfo, JsonNode, "/Student"
defAPI credit, Rial, "/Credit"
defAPI personalNotifs, JsonNode, "/PersonalNotification?postname=LastNotifications"
defAPI instantSale, JsonNode, "/InstantSale"
defAPI financialInfo(state: FinancialInfoState), JsonNode:
  fmt"/ReservationFinancial?state={state.int}"
defAPI reservation(week: int), JsonNode:
  fmt"/Reservation?lastdate=&navigation={week*7}"

# defAPI availableBanks, JsonNode, "/Chargecard"
# defAPI purchaseInvoice(bid: int, amount: Rial), JsonNode:
#   fmt"/Chargecard?IpgBankId={bid}&amount={amount.int}"
# func goPurchase(c: var CustomHttpClient): string =
#   c.request("https://sadad.shaparak.ir/purchase", HttpPost).body
  # CardAcqID
  # AmountTrans
  # ORDERID
  # TerminalID
  # TimeStamp
  # FP
  # RedirectURL
  # CustomerEmailAddress
  # OptionalPaymentParameter

# --- login API

proc loginBeforeCaptcha*(c: var CustomHttpClient
  ): tuple[loginPageData: JsonNode, captchaBinary: string] =

  let resp = c.request(baseUrl, HttpGet)
  assert resp.code.is2xx

  result.loginPageData = extractLoginPageData resp.body
  result.captchaBinary = c.request(
    freshCaptchaUrl(),
    HttpGet,
    tempHeaders = {"Referer": c.history.last}
  ).body.cleanLoginCaptcha

proc loginAfterCaptcha*(c: var CustomHttpClient,
  loginPageData: JsonNode,
  uname, pass, capcha: string
) =

  let resp = c.request(
    extractLoginUrl loginPageData,
      HttpPost,
      encodeQuery loginForm(
        uname, pass, capcha,
        extractLoginXsrfToken loginPageData),
      content = cForm)

  assert resp.code.is2xx

  let
    form = resp.body.parsehtml.findAll("form")[0]
    url = form.attr "action"
    inputs = form.findall("input").items.iterrr:
      map el => (el.attr("name"), el.attr("value"))
      toseq()

  if url.startsWith "{{":
    raise newException(ValueError, "login failed")

  else:
    let resp = c.request(url, HttpPost, inputs.encodeQuery, content = cForm)
    assert resp.code.is2xx
