function toArray(something) {
  return Array.from(something)
}

function getName(elem, defaultName) {
  return elem ? elem.innerText : defaultName
}

function getFilesLink(elems) {
  return toArray(elems).map(a => a.href)
}


function extractInfo(elem) {
  let
    nameEl = elem.querySelector(".head .inline-label"),
    filesEl = elem.querySelectorAll(".vs-files a")

  return {
    name: getName(nameEl, "title"),
    files: getFilesLink(filesEl)
  }
}

function getAllMessages() {
  return toArray(
    document
      .querySelectorAll("#page_content_inner>div.uk-grid.uk-grid-collapse.forum")
  )
    .map(extractInfo)
}

console.log(getAllMessages())
