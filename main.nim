import std/[uri, times, os, httpclient, json]
import utils, client, api

type
  State = enum
    sInit
    sGetCapcha
    sDoLogin


when isMainModule:
  var
    hc = initCustomHttpClient()
    url = baseUrl
    state = sInit

  refreshDir "./temp"

  echo "Time-Line ", now()

  while true:
    # case state
    # of sInit:
    # of sGetCapcha:
    # of sDoLogin:

    if hc.counter >= 10:
      quit "I quit..."

    else:
      sleep 100
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

      url = userPage