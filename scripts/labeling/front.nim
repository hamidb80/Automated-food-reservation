import std/[
  dom,
  jsfetch,
  asyncjs,
  sugar]

include karax/prelude

## --- global states

var currentImage = cstring""

## --- actions

proc updateImage(s: cstring) =
  currentImage = s
  redraw()

proc nextImage =
  discard fetch(cstring "/next-image")
  .then((r: Response) => r.text())
  .then((t: cstring) => updateImage t)

proc saveImage(value: cstring) =
  discard fetch("/save/" & currentImage & "/" & value)

## --- views

proc createDom: VNode =
  result = buildHtml main:
    tdiv(class = "frame"):
      img(src = "/get-image/" & currentImage)

    form(class = "user"):
      input(placeholder = "enter captcha", id = "x")
      button:
        text "next"

      proc onsubmit(e: Event; n: VNode) =
        preventDefault e
        let
          el = document.getElementById("x")
          val = el.value
        el.value = ""
        el.focus
        saveImage val
        nextImage()

## --- setup

echo "what the hell"
nextImage()
setRenderer createDom
