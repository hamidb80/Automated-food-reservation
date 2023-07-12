import std/[unittest, httpclient, json, sugar]
import client, api, utils
import iterrr


let
  credit = hc.credit.int
  isCaptchaEnabled = hc.isCaptchaEnabled

echo "------------------"
dump credit
dump isCaptchaEnabled

for n in -1..3:
  let resv = hc.reservation n
  writefile fmt"./temp/reserve-{n}.json", resv.pretty

writefile fmt"./temp/banks.json", hc.availableBanks.pretty
writefile fmt"./temp/invoice.json", hc.purchaseInvoice(1, 10000.Rial).pretty
