import std/[json, uri]

# track request and response tokens ...

let j = parseJson readfile "eduportal.shahed.ac.ir.har"
var i = 0

for e in j{"log", "entries"}:
  let url = getStr e{"request", "url"}

  case getStr e{"request", "method"}
  of "POST":
    let
      reqt = e{"request", "postData", "text"}
      rest = e{"response", "content", "text"}
      reqd = parseJson getStr reqt
      resd = parseJson getStr rest

    if "" != getStr reqd{"aut", "tck"}:
      echo "--------------------------------------- #", i, " -----"
      echo url["https://eduportal.shahed.ac.ir/".len .. ^1]
    
      echo "-- ", getStr reqd{"aut", "tck"}
      echo "++ ", getStr resd{"aut", "tck"}
      echo "++ ", getStr resd{"oaut", "oa", "nmtck"}
      inc i
    
  of "GET":
    discard
