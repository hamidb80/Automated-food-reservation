import std/[
  strutils,
  json, 
  xmltree, 
  xmlparser]


var j = parseJson "temp.txt".readFile.replace("&quot;", "\"")

for e in mitems j:
  var ee22 = parseJson getStr e["PARAM"]

  for g in mitems ee22:
    let s = g["ScrOpenParam"].getStr
      .replace("&lt;", "<")
      .replace("&gt;", ">")

    echo parseXml s

  e["PARAM"] = ee22

writeFile "temp.json", pretty j