import std/[strutils, json, nre, htmlparser, random]
import client, std/httpclient
import utils


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

func extractLoginUrl*(loginPageData: JsonNode): string =
  baseUrl & loginPageData["loginUrl"].getStr

func extractLoginXsrfToken*(loginPageData: JsonNode): string =
  getStr loginPageData{"antiForgery", "value"}

func loginForm*(user, pass, captcha, token: string): auto =
  {
    "username": user,
    "password": pass,
    "Captcha": captcha,
    "idsrv.xsrf": token}

func cleanLoginCapcha*(binary: string): string =
  binary.truncOn jfifTail

# ----- meta programming -----

template convertFn(t: type bool): untyped = toBool
template convertFn(t: type int): untyped = parseInt
template convertFn(t: type JsonNode): untyped = parseJson


template staticApi(name, typecast, url): untyped =
  proc name*(c: CustomHttpClient): typecast =
    convertFn(typecast)(c.httpc.getcontent url)

# ----- API -----

const
  baseUrl* = "https://food.shahed.ac.ir"
  userPage* = baseUrl & "/#!/UserIndex"

proc freshCapchaUrl*: string =
  baseUrl & "/api/v0/Captcha?id=" & $(rand 1..1000000)

staticApi isCapchaEnabled, bool, baseUrl & "/api/v0/Captcha?isactive=wehavecaptcha"
staticApi credit, int, baseUrl & "/api/v0/Credit"
