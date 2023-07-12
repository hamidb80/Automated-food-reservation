import std/[strutils, strformat, uri, httpclient, json, htmlparser, xmltree, sugar]
import client, api, utils
import iterrr


when isMainModule:
  var
    hc = initCustomHttpClient()
    url = baseUrl

  refreshDir "./temp"

  let resp = hc.sendData(url, HttpGet)

  assert resp.code.is2xx
  let
    data = extractLoginPageData resp.body
    raw = hc.sendData(freshCaptchaUrl(), HttpGet, tempHeaders = {
        "Referer": hc.history.last}).body

  # writeFile "./temp/login-data.json", data.pretty
  writeFile "./temp/capcha.jpeg", raw.cleanLoginCaptcha

  echo "code?: "
  let capcha = stdin.readline

  let resp1 = hc.sendData(
    extractLoginUrl data, HttpPost,
    encodeQuery loginForm(
      "992164019",
      "@123456789",
      capcha,
      extractLoginXsrfToken data),
    content = cForm)

  assert resp1.code.is2xx
  writeFile "./temp/submit.html", $resp1.body.parsehtml

  let
    form = resp1.body.parsehtml.findAll("form")[0]
    inputs = form.findall("input").items.iterrr:
      map el => (el.attr("name"), el.attr("value"))
      toseq()


  url = form.attr "action"

  if url.startsWith "{{":
    echo "invalid data"

  else:
    let resp2 = hc.sendData(url, HttpPost, inputs.encodeQuery, content = cForm)
    writeFile "./temp/cookie.txt", hc.httpc.headers["cookie"]
