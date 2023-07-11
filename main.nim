import std/[strutils, uri, tables, strtabs, times, random,
  nre, htmlparser, json, os, cookies, strformat, httpclient]

import iterrr


when isMainModule:
  var
    client = newHttpClient(maxRedirects = 0)
    url = baseUrl
    counter = 0

  refreshDir "./temp"
  discard tryRemoveFile "./out.txt"

  echo "Time-Line ", now()
  applyHeaders client

  while true:
    let resp = client.sendData(url, HttpGet)
    updateCookie client, resp

    if resp.code.is2xx:
      let data = extractLoginPageData resp.body
      # writeFile "./temp/capcha.jfif", client.sendData(imgUrl, HttpGet).body

      let resp = client.sendData(
        extractLoginUrl data, HttpPost, 
        cForm, encodeQuery loginForm(
          "992164019",
          "@123456789",
          "@123456789",
          extractLoginXsrfToken data))

      url = userPage
      # break

    elif counter >= 10:
      quit "I give up trying ..."

    elif resp.code.is3xx:
      url = resp.headers["location"]

    elif resp.code.is4xx:
      discard

    else:
      quit "Error"


  # let el = resp.body.q.select("input")
  # writeFile "login.html", resp.body
  # echo el.l