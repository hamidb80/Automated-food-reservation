import std/[httpclient, os]

var client = newHttpClient()
client.headers = newHttpHeaders({
  # "Host": "food.shahed.ac.ir",
  # "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0",
  # "Accept": "image/avif,image/webp,*/*",
  # "Accept-Language": "en-US,en;q=0.5",
  # "DNT": "1",
  # "Connection": "keep-alive",
  # "Cookie": "OpenIdConnect.nonce.oidc=d3dYMjc4QXBwMG0zMnBPaVBvbnQ2WS1RUWVZa3ZTNGp1UkNTRm00dm9GUVlmZFA1M3Jfb0FYeTliSWU4dXM0MjNtZDFYMjBva08tMW81VUl0SnRZU3dVU05Mb0VJejM4MFFROEFqWV9tQ1VFMUY4dEtuMDN5WnIzY2lpMGtKWHBaWUFIMjBUOTA2SV90eFRnTzhCNnZfSF85WU1UYkNSWm9hYnV1SEZ2ZXc2WV9xR2wzcWtuaFFMU2xwbzlpWVp1anM4NnJFbmtqbHAtamxnaWVoSjJsMHk2NEow",
  # "Sec-Fetch-Dest": "image",
  # "Sec-Fetch-Mode": "no-cors",
  # "Sec-Fetch-Site": "same-origin",
  # "Accept-Encoding": "gzip, deflate, br", # XXX dont add this

  "Referer": "https://food.shahed.ac.ir/identity/login?signin=4921d8f61dbd48652f48ef179f186d5d", ## mandatory
})


while true:
  let resp = client.request("https://food.shahed.ac.ir/api/v0/Captcha?id=2", HttpGet)
  writeFile "./temp/pin.jfif", resp.body
  sleep 1000