import std/strutils

type
  Rial* = distinct int


func toBool*(i: int): bool =
  i == 1

func toBool*(s: string): bool =
  toBool parseInt s

func parseRial*(s: string): Rial = 
  Rial parseInt s
