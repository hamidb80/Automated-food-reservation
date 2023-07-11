import std/[os]

proc refreshDir*(path: string) =
  if dirExists path:
    removeDir path

  createDir path
