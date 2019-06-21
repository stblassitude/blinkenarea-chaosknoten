#! /usr/bin/env python3

import sys


def read_leds(filename):
    leds = {}
    err = 0
    with open(filename, "r") as f:
        for line in f:
            fields = line.split()
            ledno = int(fields[0])
            led = {
                "ledno": ledno,
                "x": int(fields[1]),
                "y": int(fields[2]),
                "type": fields[3],
                "copies": []
            }
            if led["type"] == "-":
                led["copies"].append({"x": led["x"] - 1, "y": led["y"]})
                led["copies"].append({"x": led["x"] + 1, "y": led["y"]})
            elif led["type"] == "|":
                led["copies"].append({"x": led["x"], "y": led["y"] - 1})
                led["copies"].append({"x": led["x"], "y": led["y"] + 1})
            elif led["type"] == "/":
                led["copies"].append({"x": led["x"] - 1, "y": led["y"] + 1})
                led["copies"].append({"x": led["x"] + 1, "y": led["y"] - 1})
            elif led["type"] == "\\":
                led["copies"].append({"x": led["x"] - 1, "y": led["y"] - 1})
                led["copies"].append({"x": led["x"] + 1, "y": led["y"] + 1})
            else:
                print(
                    "led {:d} unknown type \"{:s}\"".format(ledno,
                                                            led["type"]),
                    file=sys.stderr)
            leds[ledno] = led
    # assign indices
    leds2 = []
    for ledno in sorted(leds):
        led = leds[ledno]
        idx = len(leds2)
        led["idx"] = idx
        leds2.append(led)
    return leds2


def output(leds):
    cnt = 0
    for led in leds:
        cnt += 1 + len(led["copies"])
    print("    FixedPixel fixed[] = new FixedPixel [{:d}];".format(cnt))
    i = 0
    for led in leds:
        print("    fixed[{:d}] = new FixedPixel( {:d}, {:d}, 2, (byte)0 );".
              format(i, led["y"], led["x"]))
        i += 1
        for cpy in led["copies"]:
            print(
                "    fixed[{:d}] = new FixedPixel( {:d}, {:d}, 2, (byte)0 );".
                format(i, cpy["y"], cpy["x"]))
            i += 1
    print("    setFixed( fixed );")
    print("    ContentPixel content[] = new ContentPixel [{:d}];".format(
        len(leds)))
    for led in leds:
        print("    content[{:d}] = new ContentPixel( {:d}, {:d}, 1 );".format(
            led["idx"], led["y"], led["x"]))
    print("    setContent( content );")
    cnt = 0
    for led in leds:
        cnt += 1 + 2 * len(led["copies"])
    print("    CopyPixel copies[] = new CopyPixel [{:d}];".format(cnt))
    i = 0
    for led in leds:
        print("    copies[{:d}] = new CopyPixel( {:d}, {:d}, 0, {:d} );".
              format(i, led["y"], led["x"], led["idx"]))
        i += 1
        for cpy in led["copies"]:
            for chan in range(2):
                print(
                    "    copies[{:d}] = new CopyPixel( {:d}, {:d}, {:d}, {:d} );".
                    format(i, cpy["y"], cpy["x"], chan, led["idx"]))
                i += 1
    print("    setCopies( copies );")


def main():
    leds = read_leds("ledno_x_y_type.txt")
    output(leds)


if __name__ == "__main__":
    sys.exit(main())
