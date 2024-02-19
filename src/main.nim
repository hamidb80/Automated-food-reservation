import std/[sugar, json, browsers, os]
import client, api/food, utils

import karax/vdom

const captchaPath = "./temp/capcha.jpg"

proc main(usr, pass: string) = 
  var c = initCustomHttpClient()
  let 
    (data, captchaBin) = loginBeforeCaptcha(c)
    cap = 
      if c.isCaptchaEnabled:
        writeFile captchaPath, captchaBin

        echo "enter captcha saved in ", captchaPath, " :"
        readLine stdin
        
      else: ""

  c.loginAfterCaptcha(data, usr, pass, cap)
  
  # ----- logged in now -----

  dump c.ping 0
  dump c.credit.int
  dump c.financialInfo fisLast
  dump c.personalInfo.pretty
  dump c.centerInfo.pretty
  dump c.rolePermissions.pretty
  dump c.availableBanks.pretty
  
  let invoice = c.registerInvoice(1, 10000.Rial)
  dump invoice.pretty

  let t = c.prepareBankTransaction(
    invoice["InvoiceNumber"].getInt,
    100000.Rial)

  writeFile "./temp/form.html", $t.genRedirectTransactionForm
  openDefaultBrowser "./temp/form.html"


when isMainModule:
  refreshDir "./temp/"
  main getEnv "FOOD_USER", getEnv "FOOD_PASS"
  