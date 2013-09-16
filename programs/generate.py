#!/usr/bin/env python
import Image

cats = Image.open("cats0.png")

for i in range(1, 12):
    cats.rotate(30 * i).save("cats" + str(i) + ".png")

