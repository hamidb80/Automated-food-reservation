import std/[sugar, json, browsers]
import client, api, utils

import karax/vdom

when isMainModule:
  refreshDir "./temp/"

  var c = initCustomHttpClient()
  let (data, captchaBin) = loginBeforeCaptcha(c)

  writeFile "./temp/capcha.jpg", captchaBin
  echo "enter captcha: "
  let captcha = readLine stdin

  loginAfterCaptcha(c, data, "992164019", "@123456789", captcha)

  # ----- logged in now -----

  dump c.credit.int
  dump c.financialInfo fisLast
  dump c.personalInfo["LastName"]
  dump c.availableBanks.pretty
  
  let invoice = c.registerInvoice(1, 10000.Rial)
  dump invoice.pretty

  let t = c.prepareBankTransaction(
    invoice["InvoiceNumber"].getInt,
    10000.Rial)

  writeFile "./temp/form.html", $t.genRedirectTransactionForm
  openDefaultBrowser "./temp/form.html"
