import std/json

# track request and response tokens ...

let j = parseJson readfile "eduportal.shahed.ac.ir.har"

for e in j{"log", "entries"}:
  let url = getStr e{"request", "url"}


  echo "-------------"
  echo url["https://eduportal.shahed.ac.ir/".len .. ^1]
  
  case getStr e{"request", "method"}
  of "POST":
    let
      reqt = e{"request", "postData", "text"}
      rest = e{"response", "content", "text"}
      reqd = parseJson getStr reqt
      resd = parseJson getStr rest

    echo ">> ", getStr reqd{"aut", "tck"}
    echo "<< ", getStr resd{"aut", "tck"}
    echo "<< ", getStr resd{"oaut", "oa", "nmtck"}
  
  of "GET":
    discard
