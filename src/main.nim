import std/[uri, times, os, httpclient, json, htmlparser, xmltree, sugar]
import utils, client, api
import iterrr


when isMainModule:
  var
    hc = initCustomHttpClient()
    url = baseUrl

  refreshDir "./temp"

  echo "Time-Line ", now()

  let resp = hc.sendData(url, HttpGet)

  assert resp.code.is2xx
  let
    data = extractLoginPageData resp.body
    raw = hc.sendData(freshCapchaUrl(), HttpGet, tempHeaders = {
        "Referer": hc.history.last}).body

  # writeFile "./temp/login-data.json", data.pretty
  writeFile "./temp/capcha.jpeg", raw.cleanLoginCapcha

  echo "code?: "
  let capcha = stdin.readline

  let resp1 = hc.sendData(
    extractLoginUrl data, HttpPost,
    cForm, encodeQuery loginForm(
      "992164019",
      "@123456789",
      capcha,
      extractLoginXsrfToken data))

  assert resp1.code.is2xx
  writeFile "./temp/submit.html", $resp1.body.parsehtml

  let
    form = resp1.body.parsehtml.findAll("form")[0]
    inputs = form.findall("input").items.iterrr:
      map el => (el.attr("name"), el.attr("value"))
      toseq()


  url = form.attr "action"
  # echo ":: ", url
  let resp2 = hc.sendData(url, HttpPost, cForm, inputs.encodeQuery)
  writeFile "./temp/cookie.txt", hc.httpc.headers["cookie"]

  echo "\n\n"
  dump hc.credit
  dump hc.isCapchaEnabled
