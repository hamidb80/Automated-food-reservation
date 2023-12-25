import std/json

# track request and response tokens ...

let j = parseJson readfile "eduportal.shahed.ac.ir.har"

for e in j{"log", "entries"}:
  let url = getStr e{"request", "url"}

  if "POST" == getStr e{"request", "method"}:
    let
      reqt = e{"request", "postData", "text"}
      rest = e{"response", "content", "text"}
      reqd = parseJson getStr reqt
      resd = parseJson getStr rest

    echo "-------------"
    echo url.substr(len "https://eduportal.shahed.ac.ir/frm")
    echo ">> ", getStr reqd{"aut", "tck"}
    echo "<< ", getStr resd{"aut", "tck"}
    echo "<< ", getStr resd{"oaut", "oa", "nmtck"}
