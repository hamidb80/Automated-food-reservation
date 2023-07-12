import std/[os, strutils]


const jpegTail* = [byte 0xff, 0xd9]


func toBool*(i: int): bool =
  i == 1

func toBool*(s: string): bool =
  toBool parseInt s

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


template last*(s: seq): untyped = s[^1]
