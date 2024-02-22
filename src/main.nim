import std/[sugar, json, browsers, os]
import client, api/food, utils

# import karax/vdom


const captchaPath = "./temp/capcha.jpg"

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
  echo weekRevs[mon][lunch].selected

  discard reserve(c, cancel, "1402/12/02", 44, lunch, 1)
  discard reserve(c, rsv, "1402/12/02", 44, lunch, 1)

  # writeFile "temp.json", pretty rvdata

  # let invoice = c.registerInvoice(1, 10000.Rial)
  # dump invoice.pretty

  # let t = c.prepareBankTransaction(
  #   invoice["InvoiceNumber"].getInt,
  #   100000.Rial)

  # writeFile "./temp/form.html", $t.genRedirectTransactionForm
  # openDefaultBrowser "./temp/form.html"


when isMainModule:
  refreshDir "./temp/"
  main getEnv "FOOD_USER", getEnv "FOOD_PASS"
