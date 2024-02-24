import std/[
    unittest, 
    sugar, 
    json, 
    browsers,
    httpclient,
    os]

import utils/[client, common]
import api/behestan

when isMainModule:
  var c = initCustomHttpClient()
  c.h.headers = defaultBehestanHeaders()

  writeFile "./temp.captcha.gif", c.apiGetCapcha.image

  let
    stdid = getEnv "BEHESTAN_STD_ID" 
    pass = getEnv "BEHESTAN_PASS"
  echo "pass: '", pass, "'"
  echo "capcha: "
  let
    aa = apiLogin(c, stdid, pass, readLine stdin)
    bb = apiNav(c, homeNavParams, extractBehestanMust aa)
    cc = apiProcessSysMenu0(c, extractBehestanMust bb)
    dd = apiNav(c, stdInfoNavParams, extractBehestanMust cc)
    # dd = apiNav(c, stdInfoNavParams, extractBehestanMust cc)
    ee = apiProcessStdTotalInfoTrmStat(c, extractBehestanMust dd, "992164019")

  writeFile "./temp/aa.json", pretty aa
  writeFile "./temp/bb.json", pretty bb
  writeFile "./temp/cc.json", pretty cc
  writeFile "./temp/dd.json", pretty dd
  writeFile "./temp/ee.json", pretty ee
