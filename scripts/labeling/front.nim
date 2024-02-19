import std/[dom, jsfetch, asyncjs, sugar]
include karax/prelude

var currentImage = cstring""

proc updateImage(s: cstring) =
  currentImage = s
  redraw()

proc nextImage = 
  discard fetch(cstring "/image/next")
  .then((r: Response) => r.text())
  .then((t: cstring) => updateImage t)


proc createDom: VNode =
  result = buildHtml main:
    tdiv(class = "frame"):
      img(src = "/image/" & currentImage)
    form(class = "user"):
      input(placeholder = "captcha", id = "x")
      button:
        text "next"

      proc onsubmit(e: Event; n: VNode) =
        preventDefault e 
        let el = document.getElementById("x")
        let val = el.value
        el.value = ""
        el.focus
        discard fetch("/save/" & currentImage & "/" & val & "/")
        nextImage()
        
proc start =
  nextImage()
  setRenderer createDom

discard settimeout(start, 1000)
