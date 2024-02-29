import cv2
import numpy as np
import matplotlib.pyplot as plt
import stow
import random
import sys

# [y, x]

moves = [
  (+1, 0),
  (-1, 0),
  (0, -1),
  (0, +1)]

def validBound(img, pos):
  by, bx = img.shape
  px, py = pos
  return px in range(bx) and py in range(by)

def options(img, pos):
  px, py = pos
  o = 0
  for dx, dy in moves:
    vx, vy = px+dx, py+dy
    if \
      validBound(img, (vx, vy)) and \
      (img[vy, vx] == 0):
      o += 1
  return o

def dfsImg(img, pos, seen):
  seq = []


  def validPoint(pos):
    px, py = pos
    return \
        validBound(img, pos) and \
        (img[py, px] == 0) and \
        (pos not in seen)

  def dfsImgImpl(x, y):
    def stupid(n):
      pp = [s for s in seq[-n:]]
      g = [options(img, s) for s in pp]
      return g

    for (dx, dy) in moves:
      p = dx+x, dy+y
      px, py = p
      if validPoint(p):
        if len(seq) < 8 or \
          len([1 for s in stupid(10) if s >= 3]) >= 2:
          seen.add(p)
          seq.append(p)
          dfsImgImpl(px, py)

  x, y = pos
  dfsImgImpl(x, y)
  return seq


def showClean(path):
  img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
  cpimg = img.copy()
  opimg = img.copy()
  
  cpimg[:] = 255
  opimg[:] = 0

  print(img.shape)

  seen = set()
  for x in range(img.shape[1]):
    for y in range(img.shape[0]):
      if img[y, x] == 0 and opimg[y, x] == 0:
        opimg[y, x] = 250 * options(img, (x,y)) / 4

      d = dfsImg(img, (x, y), seen)
      if 14 <= len(d):
        # color = random.randint(140, 200)
        for px, py in d:
          # img[py, px] = color
          cpimg[py, px] = 0

  # last = []
  # for x in range(img.shape[1]):
  #   c = 0
  #   for y in range(img.shape[0]):
  #     if cpimg[y, x] == 0:
  #       c += 1

  #   if c < 2:
  #     c = 0
  #   c = min(c, 6)

  #   m = (1 - c / 6) * 250
  #   last.append(c)
    
  #   for i in range(1, 4):
  #     cpimg[-i, x] = m

  # lval = 0
  # fff = []
  # for i in range(0, len(last)):
  #   val = last[i]

  #   if lval > 3 and val < 2 or (val == 0 and lval != 0):
  #     fff.append(i)

  #   lval = val

  # print(fff)
  # Display the image
  # img_concatenated = np.concatenate((opimg, img, cpimg), axis=0)
  # plt.imshow(cv2.cvtColor(img_concatenated, cv2.COLOR_BGR2RGB))
  # plt.title('Image with Average Color Bars')
  # plt.show()
  return cpimg

def show(path):
  img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
  plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
  plt.show()

if __name__ == "__main__":
  for f in stow.ls("./temp/captchas/"):
    try:
      cv2.imwrite(f.path, showClean(f.path))
    except:
      pass

  # if len(sys.argv) > 1:
  #   show("./temp/line.png")
  # else:
  #   showClean("./temp/line.png")