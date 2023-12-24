import std/[httpclient, json, os]


type
  SubmittedWork = object
    name: string
    files: seq[string]


if paramCount() == 2:
  let
    jsonFilePath = paramStr 1
    workDir = paramStr 2
    forms = to(parseJson readFile jsonFilePath, seq[SubmittedWork])

  var client = newHttpClient()
  discard existsOrCreateDir workDir

  for f in forms:
    let dir = workDir / f.name
    createDir dir
    for i, url in f.files:
      downloadFile client, url, dir / $i & url.splitFile.ext

else:
  echo "USAGE:"
  echo "app OUTPUT_OF_INJECT_SCRIPT.json SAVE_DIR_PATH/"
