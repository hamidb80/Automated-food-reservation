import std/[
    unittest, 
    sugar, 
    json, 
    browsers,
    os]

import utils/[client, common]
import api/food

# import karax/vdom


const captchaPath = "./temp/capcha.jpg"
import print

proc main(usr, pass: string) =
  var c = initCustomHttpClient()
  
  login c, usr, pass, proc(captchaBin: string): string =
    writeFile captchaPath, captchaBin
    echo "enter captcha saved in ", captchaPath, " :"
    readLine stdin

  dump c.credit
  dump pretty c.personalInfo
  dump pretty c.availableBanks

  let weekRevs = c.reservation 0
  print weekRevs

  echo reserve(c, cancel, "1402/12/09", 12, lunch, 1)
  echo reserve(c, rsv, "1402/12/09", 12, lunch, 1)

  # writeFile "temp.json", pretty rvdata

  # let invoice = c.registerInvoice(1, 10000.Rial)
  # dump invoice.pretty

  # let t = c.prepareBankTransaction(
  #   invoice["InvoiceNumber"].getInt,
  #   100000.Rial)

  # writeFile "./temp/form.html", $t.genRedirectTransactionForm
  # openDefaultBrowser "./temp/form.html"

when isMainModule:
  refreshDir "./temp/test"
  main getEnv "FOOD_USER", getEnv "FOOD_PASS"
