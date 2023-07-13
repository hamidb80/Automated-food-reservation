import std/[sugar, json]
import client, api, utils

when isMainModule:
  refreshDir "./temp/"

  var c = initCustomHttpClient()
  let (data, captchaBin) = loginBeforeCaptcha(c)

  writeFile "./temp/capcha.jpg", captchaBin
  echo "enter captcha: "
  let captcha = readLine stdin

  loginAfterCaptcha(c, data, "992164019", "@123456789", captcha)

  dump c.credit.int
  dump c.financialInfo fisLast
  dump c.personalInfo["LastName"]
