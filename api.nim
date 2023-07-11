import std/[strutils, json, nre, htmlparser, random]


const
  baseUrl* = "https://food.shahed.ac.ir"
  userPage* = "https://food.shahed.ac.ir/#!/UserIndex"
  capchaUrlRaw = "https://food.shahed.ac.ir/api/v0/Captcha?id="


proc freshCapchaUrl*: string =
  capchaUrlRaw & $(rand 1..1000000)


func repl(match: RegexMatch): string =
  match.captures[0].entityToUtf8

func toHumanReadable(s: string): string =
  s.replace(re"&(\w+);", repl)


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
