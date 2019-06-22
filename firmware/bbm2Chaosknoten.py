#! /usr/bin/env python3

import argparse
import struct
import sys


class Movie(object):
    class Frame(object):

        # offsets (y * width(66) + x) of the pixels whose green value
        # is taken from the *.bbm frames for the LEDs
        LED_COORDS = [
            408, 414, 420, 468, 492, 677, 684, 863, 945, 951, 957, 963, 971,
            975, 1034, 1209, 1215, 1221, 1227, 1259, 1299, 1304, 1373, 1469,
            1476, 1497, 1572, 1633, 1656, 1680, 1728, 1734, 1740, 1832, 1968,
            2106, 2163, 2225, 2365, 2559, 2620, 2956
        ]

        # offsets (y * width(66) + x) of the pixels whose color is set to
        # the LED brightness in the *.bbm frames on output
        # (multiple (-> list) per LED)
        LED_COORDS_OUT = [
            [408, 407, 409], [414, 413, 415], [420, 419, 421], [468, 533, 403],
            [492, 425, 559], [677, 610, 744], [684, 617, 751], [863, 797, 929],
            [945, 944, 946], [951, 950, 952], [957, 956, 958], [963, 962, 964],
            [971, 904, 1038], [975, 908, 1042], [1034, 967, 1101],
            [1209, 1208, 1210], [1215, 1214, 1216], [1221, 1220, 1222],
            [1227, 1226, 1228], [1259, 1193, 1325], [1299, 1298, 1300],
            [1304, 1369, 1239], [1373, 1438, 1308], [1469, 1534, 1404],
            [1476, 1541, 1411], [1497, 1496, 1498], [1572, 1637, 1507],
            [1633, 1698, 1568], [1656, 1589, 1723], [1680, 1745, 1615],
            [1728, 1727, 1729], [1734, 1733, 1735], [1740, 1739, 1741],
            [1832, 1897, 1767], [1968, 1901, 2035], [2106, 2105, 2107],
            [2163, 2097, 2229], [2225, 2290, 2160], [2365, 2299, 2431],
            [2559, 2493, 2625], [2620, 2619, 2621], [2956, 2889, 3023]
        ]

        def __init__(self):
            self.duration = 100
            self.leds = len(self.LED_COORDS) * [0]

        def from_frame_data(self, duration, data):
            """parse frame from duration and *.bbm pixel data"""
            self.duration = duration
            for i in range(len(self.LED_COORDS)):
                ledno = self.LED_COORDS[i]
                self.leds[i] = data[ledno * 3 + 1]

        def to_frame_data(self):
            """convert frame to *.bbm frame data,
               return duation and pixel data"""
            pixels = 51 * 66 * [0, 0, 255]
            for i in range(len(self.LED_COORDS_OUT)):
                for ledno in self.LED_COORDS_OUT[i]:
                    pixels[ledno * 3 + 0] = self.leds[i]
                    pixels[ledno * 3 + 1] = self.leds[i]
                    pixels[ledno * 3 + 2] = 0
            data = bytes(pixels)
            return self.duration, data

        def to_firmware_data(self):
            """convert a frame to firmware data"""
            # duration: in 6ms steps, 12 bits
            duration = (self.duration + 3) // 6
            if duration < 1:
                duration = 1
            if duration > 0x3FF:
                duration = 0x3FF
            # use shorter encoding
            plain = self._fw_pix_data_plain()
            rle = self._fw_pix_data_rle()
            if len(rle) < len(plain):
                code = 0x10 # rle compressed
                data = rle
            else:
                code = 0x00 # plain
                data = plain
            # encode code and duration at begin of data
            dur_h = (duration >> 8) & 0x0F
            dur_l = duration & 0xFF
            return [code | dur_h, dur_l] + data

        def _fw_pix_data_plain(self):
            """return pixel data, plain, no compression"""
            data = []
            half = None
            for led in self.leds:
                val = (led >> 4) & 0x0F
                if half is None:
                    half = val
                else:
                    data.append(half << 4 | val)
                    half = None
            return data

        def _fw_pix_data_rle(self):
            """return pixel data, compressed using run length encoding"""
            data = []
            val = (self.leds[0] >> 4) & 0x0F
            cnt = 0
            for led in self.leds:
                ledval = (led >> 4) & 0x0F
                if val == ledval and cnt < 0x10:  # same value -> count
                    cnt += 1
                else:
                    data.append((cnt - 1) << 4 | val)  # append RLE item
                    val = ledval
                    cnt = 1
            data.append((cnt - 1) << 4 | val)  # last RLE item
            return data

    def __init__(self):
        self.frames = []
        self.main_hdr = struct.Struct("!LHHHH")
        self.main_info = struct.Struct("!LLL")
        self.subhdr_magic = struct.Struct("!L")
        self.subhdr_size = struct.Struct("!H")
        self.frame_hdr = struct.Struct("!H")

    def read_bbm(self, filename):
        """read movie from *.bbm file"""
        try:
            with open(filename, "rb") as f:
                # main header
                magic, height, width, channels, maxval = self.main_hdr.unpack(
                    f.read(12))
                if magic != 0x23542666:
                    raise ValueError(
                        "invalid magic 0x%X != 0x23542666".format(magic))
                if height != 51 or width != 66 or channels != 3 or maxval != 255:
                    raise ValueError(
                        "invalid format {:d}x{:d}-{:d}/{:d} != 66x51-3/256".
                        format(width, height, channels, maxval - 1))
                # main information
                framecnt, duration, frameptr = self.main_info.unpack(
                    f.read(12))
                # skip additional headers until frame start marker
                while True:
                    subhdr_magic, = self.subhdr_magic.unpack(f.read(4))
                    if subhdr_magic == 0x66726d73:
                        break
                    subhdr_size, = self.subhdr_size.unpack(f.read(2))
                    if subhdr_size < 6:
                        raise ValueError("truncated sub-header")
                    f.read(subhdr_size - 6)
                # read frames
                frames = []
                for frameno in range(framecnt):
                    duration, = self.frame_hdr.unpack(f.read(2))
                    n = height * width * channels
                    framedata = f.read(n)
                    if len(framedata) != n:
                        raise ValueError("truncated frame")
                    frame = self.Frame()
                    frame.from_frame_data(duration, framedata)
                    frames.append(frame)
            self.frames = frames
            return True
        except Exception as e:
            print(str(e), file=sys.stderr)
            return False

    def write_bbm(self, filename):
        """write movie as *.bbm file"""
        with open(filename, "wb") as f:
            # main header
            f.write(self.main_hdr.pack(0x23542666, 51, 66, 3, 255))
            # main information
            duration = 0
            for frame in self.frames:
                duration += frame.duration
            f.write(self.main_info.pack(len(self.frames), duration, 24))
            # frame start marker
            f.write(self.subhdr_magic.pack(0x66726d73))
            # write frames
            for frame in self.frames:
                duration, data = frame.to_frame_data()
                f.write(self.frame_hdr.pack(duration))
                f.write(data)

    def write_firmware(self, filename):
        """write movie as firmware (assembly include file)"""
        # convert all frames to firware data
        fw_frames = []
        fw_len = 0
        for frame in self.frames:
            fw_data = frame.to_firmware_data()
            # search for identical frame before
            id_len = 0
            for id_frame in fw_frames:
                if id_frame == fw_data and id_frame[0] & 0xE0 == 0x00:
                    # identical frame found (and code is 0x00 or 0x10)
                    # -> replace data with back reference
                    back = fw_len - id_len + 2
                    if back <= 0x3FF:
                        back_h = (back >> 8) & 0x0F
                        back_l = back & 0xFF
                        fw_data = [0x20 | back_h, back_l]
                        break
                id_len += len(id_frame)
            # append frame to list
            fw_frames.append(fw_data)
            fw_len += len(fw_data)
        # build firmware data
        fw_data = []
        for fw_frame in fw_frames:
            fw_data += fw_frame
        fw_data.append(0xF0) # end marker
        if len(fw_data) & 1 != 0:
            fw_data.append(0) # ensure even length
        # write firmware data as assembly
        with open(filename, "w") as f:
            for i in range(0, len(fw_data), 8):
                vals = ["0x{:02X}".format(v) for v in fw_data[i:i + 8]]
                print("        .db     {:s}".format(",".join(vals)), file=f)


def parse_arguments():
    """parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="convert *.bbm to Chaosknoten")
    parser.add_argument(
        "-i",
        "--input",
        metavar="BBM_FILE",
        type=str,
        required=True,
        dest="input",
        help="input binary blinken movie (*.bbm, required)")
    parser.add_argument(
        "-o",
        "--output",
        metavar="BBM_FILE",
        type=str,
        dest="output",
        help="output binary blinken movie (*.bbm, optional)")
    parser.add_argument(
        "-f",
        "--firmware",
        metavar="INC_FILE",
        type=str,
        dest="firmware",
        help="output firmware data (*.inc, optional)")
    try:
        args = parser.parse_args()
    except:
        return None
    return args


def main():
    args = parse_arguments()
    if args is None:
        return 2
    movie = Movie()
    if not movie.read_bbm(args.input):
        return 3
    if args.output is not None:
        movie.write_bbm(args.output)
    if args.firmware is not None:
        movie.write_firmware(args.firmware)
    return 0


if __name__ == "__main__":
    sys.exit(main())
