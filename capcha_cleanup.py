from PIL import Image
import os

html = ""

for file in os.listdir("./temp"):
    if file.endswith(".jpg") and file.startswith("capcha"):
        capcha = Image.open("./temp/" + file)
        cap_data = capcha.load()
        width, height = capcha.size
        reds = []
        img = Image.new('RGBA', (width, height), color='black')
        img_data = img.load()
        avg = Image.new('RGBA', (width, 1), color='black')
        avgdata = avg.load()

        for x in range(width):
            sum_red = 0
            for y in range(height):
                r, g, b= cap_data[x, y]
                if (r < 180 and g > r) or (r < 100 and g < 100) or (r > 180 and g > 180) or b > 150:
                    img_data[x, y] = (0, 0, 0, 0)
                else:
                    img_data[x, y] = (r, g, b)

                sum_red += img_data[x, y][0]
            avgdata[x, 0] = (sum_red//(height//4), 0, 0)

        a = f'bar_{file}.png'
        q = f'qualified_{file}.png'
        avg.save("./temp/" + a)
        img.save("./temp/" + q)

        html = html + f"""
      <div class="block">
        <img src="{file}" class="main">
        <img src="{q}" class="main">
        <img src="{a}" class="avg">
      </div>
      """

with open("./temp/acc.html", "w") as f:
    f.write("""
            <style>
            *{
              margin: 0;
              padding: 0;
            }
            .block{
              display: flex;
              flex-direction: column;
              border: 2px solid black;
            }
            .block img{
              margin: 10px;
              image-rendering: pixelated;
            }

            .block .avg{
              transform: scaleY(4);
            }

            .block{
              margin: 20px;
            }
            </style>
            """)
    f.write(html)
