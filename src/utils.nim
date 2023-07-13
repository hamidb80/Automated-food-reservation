import std/[os, strutils]


const jpegTail* = [byte 0xff, 0xd9]


proc refreshDir*(path: string) =
  if dirExists path:
    removeDir path

  createDir path

func toStr(bytes: openArray[byte]): string =
  for b in bytes:
    result.add b.char

func cutAfter*(s: string, patt: openArray[byte]): string =
  let i = s.rfind patt.toStr
  s[0..<i+patt.len]

# func formatDate*(y,m,d: int): string = 
#   fmt"{y}/{m:02}/{d:02}"

template last*(s: seq): untyped = s[^1]
