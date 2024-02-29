import std/[json, uri]

# track request and response tokens ...

let entries = parseJson readfile "./scripts/working-test1.json"
var i = 0

for e in entries:
  let url = getStr e{"req", "url"}

  case getStr e{"req", "method"}
  of "POST":
    let
      reqd = e{"req", "payload"}
      resd = e{"resp", "data"}

    if "" != getStr reqd{"aut", "tck"}:
      echo "--------------------------------------- #", i, " -----"
      echo url["https://eduportal.shahed.ac.ir/".len .. ^1]

      echo "-- ", getStr reqd{"aut", "tck"}
      echo "++ ", getStr resd{"aut", "tck"}, "  aut.tck"

      let t2 = getStr resd{"oaut", "oa", "nmtck"}
      if t2.len != 0:
        echo "++ ", t2, "  oaut.oa.nmtck"

      inc i

  of "GET":
    discard
