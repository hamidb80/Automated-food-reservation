import std/[
  json,
  options,
  uri,
  httpclient,
  strutils,
  os,
  sugar]

# import questionable

import ../src/client
import ../src/api/behestan


func toHttpMethod(m: string): HttpMethod =
  case m
  of "POST": HttpPost
  else: HttpGet

# func deepUpdateImpl(j: var JsonNode, u: JsonNode) =
#   for k, v in u:

proc deepUpdate(j, u: JsonNode) =
  for k, v in u:
    case v.kind
    of JObject:
      deepUpdate j[k], v
    else:
      j[k] = v

func toJson(bm: BehestanMust): JsonNode = %*{
  "aut": {
    "sid": bm.sessionId,
    "u": bm.userId,
    "tck": bm.ticket}}


proc summary(j: JsonNode): JsonNode =
  result = newJArray()

  for e in j{"log", "entries"}:
    let
      req = e["request"]
      url = getStr req["url"]
      m = toHttpMethod getStr req["method"]
      d =
        if "postData" in req:
          parseJson getStr req{"postData", "text"}
        else:
          newJObject()

      resp = e["response"]
      s = getint resp["status"]
      # h = getint resp["headers"]
      # c = getint resp["cookies"]

      r =
        try:
          parseJson getStr resp{"content", "text"}
        except:
          newJNull()


    case url.parseUri.path.splitFile.ext.toLowerAscii
    of ".jpg", ".png", ".js", ".css", ".gif", ".ttf", ".woff2", ".ico": discard
    else:
      result.add %*{
        "req": {
          "url": url,
          "method": $m,
          "payload": d,
          "headers": 1,
          "cookies": 1,
        },
        "resp": {
          "status": s,
          "data": r,
          "headers": 1,
          "cookies": 1,
        }
      }

proc simulate =
  discard
  # case url.parseUri.path
  # of "/frm/loginapi/loginapi.svc/":
  #   discard

  # of "/frm/nav/nav.svc":
  #   discard

  # else:
  #   discard

  # if endsWith(u, ".js") or endsWith(u, ".css") or endsWith(u, ".png"):
  #   continue
  # else:
  #   let
  #     resp = request(c, u, m, if issome d: $d.get else: "")
  #     ct = resp.headers["content-type"]
  #     data = body resp
  #     jdata =
  #       if ct == "application/json": parseJson data
  #       else: nil

  #   if nil != jdata:
  #     bh = extractBehestanMust jdata

  #   case p
  #   of "/frm/captcha/captcha.ashx":
  #     writefile "./temp/capcha.png", data

  #   of "/frm/loginapi/loginapi.svc/":
  #     discard

  #   of "/frm/nav/nav.svc":
  #     tck2 = getStr data.parseJson{"oaut", "oa", "nmtck"}

  #   else:
  #     discard


when isMainModule:
  writeFile "temp.json", pretty summary parseJson readfile "eduportal.shahed.ac.ir.har"
