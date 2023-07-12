import std/[os, strutils]


const jfifTail = [byte 0xff, 0xd9]


proc refreshDir*(path: string) =
  if dirExists path:
    removeDir path

  createDir path


func toStr(bytes: openArray[byte]): string =
  for b in bytes:
    result.add b.char

func truncOn*(s: string, patt: openArray[byte]): string =
  let i = s.rfind patt.toStr
  s[0..<i+patt.len]
