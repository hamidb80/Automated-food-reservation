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

  WeekDayId* = enum
    sat = 0
    sun = 1
    mon = 2
    tue = 3
    wed = 4
    thu = 5
    fri = 6

  DayState* = enum
    can = 0
    what1 = 1
    today = 2
    what3 = 3
    off = 4
    cannot = 5

  MealId* = enum
    breakfast = 1
    lunch = 2
    dinner = 3

  MealState* = enum
    can = 0
    what1 = 1
    what2 = 2
    what3 = 3
    what4 = 4
    undefined = 5
    reserved = 6
    maybe = 7


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

func `$`*(r: Rial): string =
  $r.int & "Rials"

# ----- API -----

const
  baseUrl* = "https://food.shahed.ac.ir"
  userPage* = baseUrl & "/#!/UserIndex"

func wrapUrl(path: string): string =
  baseUrl & path

proc freshCaptchaUrl*: string =
  wrapUrl "/api/v0/Captcha?id=" & $(rand 1..1000000)

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
    (apiName, extraArgs) =
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

    moreArgs = extraArgs.mapIt newIdentDefs(it[0], it[1])

    firstArg = newIdentDefs(
      ident "c",
      newTree(nnkVarTy, ident "CustomHttpClient"))

  newProc(
    exported apiName,
    @[typecast, firstArg] & moreArgs,
    body)

# --- json API

staticAPI isCaptchaEnabled, bool, "/api/v0/Captcha?isactive=wehavecaptcha"

staticAPI personalInfo, JsonNode, "/api/v1/Student/GetCurrent"

staticAPI credit, Rial, "/api/v0/Credit"

staticAPI availableBanks, JsonNode, "/api/v0/Chargecard"

staticAPI reservationImpl(week: int), JsonNode,
  fmt"/api/v0/Reservation?lastdate=&navigation={week*7}"

staticAPI registerInvoice(bid: int, amount: Rial), JsonNode,
  fmt"/api/v0/Chargecard?IpgBankId={bid}&accommodationId=0&amount={amount.int}&type=1"

type ResvrAction* = enum
  cancel = 0
  rsv = 1

func `not`(ra: ResvrAction): ResvrAction = 
  case ra:
  of cancel: rsv
  of rsv: cancel

proc reserve*(
  c: var CustomHttpClient,

  action: ResvrAction,
  jalalidate: string,

  foodId: int,
  mealId: MealId,
  selfId: int,
): JsonNode =

  let 
    data = %* [{
      "Date": jalalidate,
      "FoodId": foodId,
      "MealId": int mealId,
      "SelfId": selfId,
      "Counts": int action,
      "PriceType":2,
      "Provider": 1,
      "OP": 1}]

    req = request(
      c,
      wrapUrl "/api/v0/Reservation", HttpPost,
      $data,
      content = cJson,
      accept = cJson)

  parseJson body req


proc loginBeforeCaptcha(c: var CustomHttpClient
  ): tuple[loginPageData: JsonNode, captchaBinary: string] =

  let resp = c.request(wrapUrl "", HttpGet)
  assert resp.code.is2xx

  result.loginPageData = extractLoginPageData body resp
  result.captchaBinary = cleanLoginCaptcha body request(
    c,
    freshCaptchaUrl(),
    HttpGet,
    tempHeaders = {"Referer": "https://food.shahed.ac.ir/identity/login?"})

proc loginAfterCaptcha(c: var CustomHttpClient,
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

proc login*(
  c: var CustomHttpClient,
  usr, pass: string,
  captchaSolver: proc(captchaImageBinary: string): string
) =
  let
    (data, captchaBin) = loginBeforeCaptcha c
    cap =
      if isCaptchaEnabled c:
        captchaSolver captchaBin
      else:
        ""

  c.loginAfterCaptcha(data, usr, pass, cap)

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


type
  Restaurant* = object
    id*: int
    name*: string

  RevFoodSelfPack = object
    self: Restaurant
    price: Rial

  FoodState* = enum
    what0 = 0
    what1 = 1
    # what2 = 2
    reserved = 2
    what3 = 3
    what4 = 4
    what5 = 5
    what6 = 6

  RevFood* = object
    id*: int
    state*: FoodState
    name*: string
    orders*: seq[RevFoodSelfPack]

  LastReservedFood = object
    factor*: int
    selfId*: int
    foodId*: int
    selfname*: string
    foodname*: string

  RevMeal* = object
    id*: MealId
    wid*: int # id in whole week
    state*: MealState
    foods*: seq[RevFood]
    selected*: Option[LastReservedFood]

  RevDay* = object
    id*: WeekDayId
    state*: DayState
    date: string
    meals*: seq[RevMeal]

  RevWeek = seq[RevDay]


func `[]`*(week: RevWeek, id: WeekDayId): RevDay =
  for d in week:
    if d.id == id:
      return d
  raise newException(ValueError, "Cannot find day: " & $id)

func `[]`*(day: RevDay, mealId: MealId): RevMeal =
  for meal in day.meals:
    if meal.id == mealId:
      return meal
  raise newException(ValueError, "Cannot find meal: " & $mealId)


func parseRevFoodOrderData(menu: JsonNode): RevFoodSelfPack =
  RevFoodSelfPack(
    price: Rial getInt menu["ShowPrice"],
    self: Restaurant(
      id: getInt menu["SelfId"],
      name: getStr menu["SelfName"]))

func parseRevFoodData(food: JsonNode): RevFood =
  RevFood(
    id: getInt food["FoodId"],
    state: FoodState getInt food["FoodState"],
    name: getStr food["FoodName"],
    orders: food["SelfMenu"].mapit parseRevFoodOrderData it)


func parseLastReservedData(lastReservedArr: JsonNode): Option[LastReservedFood] =
  if 0 < len lastReservedArr:
    let r = lastReservedArr[0]
    some LastReservedFood(
      factor: parseInt getStr r["ReserveNumber"],
      foodId: getInt r["FoodId"],
      selfId: getInt r["SelfId"],
      foodName: getStr r["FoodName"],
      selfName: getStr r["SelfName"])
  else:
    none LastReservedFood

func parseRevMealData(meal: JsonNode): RevMeal =
  RevMeal(
    id: MealId getInt meal["MealId"],
    wid: getInt meal["Id"],
    state: MealState getInt meal["MealState"],
    selected: parseLastReservedData meal["LastReserved"],
    foods: meal["FoodMenu"].mapit parseRevFoodData it)

func parseRevDayData(day: JsonNode): RevDay =
  RevDay(
      id: WeekDayId getInt day["DayId"],
      state: DayState getInt day["DayState"],
      date: getStr day["DayDate"],
      meals: day["Meals"].mapit parseRevMealData it)

func parseRevervationData(days: JsonNode): RevWeek =
  days.mapit parseRevDayData it

proc reservation*(c: var CustomHttpClient, week: int): RevWeek =
  parseRevervationData c.reservationImpl(week)
