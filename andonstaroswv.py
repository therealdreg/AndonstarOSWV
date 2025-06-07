#!/usr/bin/env python3

# MIT License
# 
# AndonstarOSWV - Andonstar Open Source Wifi Viewer
# https://github.com/therealdreg/AndonstarOSWV/
# Copyright (c) 2025 David Reguera Garcia aka Dreg
# twitter: @therealdreg
# dreg@rootkit.es
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import argparse, pathlib, re, signal, socket, sys
import cv2, numpy as np, requests

BOUNDARY = b"--arflebarfle"
USER_AGENT = "curl/8"

def preview(host, on=True):
    par = 1 if on else 0
    print(f"[DEBUG] Sending preview command to {host} with par={par}")
    requests.get(f"http://{host}/?custom=1&cmd=3001&par={par}", timeout=3)

def connect(host, port):
    get = (f"GET / HTTP/1.1\r\nHost: {host}:{port}\r\n"
           f"User-Agent: {USER_AGENT}\r\nConnection: close\r\n\r\n").encode()
    print(f"[DEBUG] Connecting to {host}:{port}")
    s = socket.create_connection((host, port), timeout=5)
    print("[DEBUG] Connection established, sending GET request")
    s.sendall(get)
    return s

def until(sock, token):
    print(f"[DEBUG] Waiting for token: {token}")
    data = b""
    while token not in data:
        chunk = sock.recv(4096)
        print(f"[DEBUG] Received chunk of {len(chunk)} bytes")
        data += chunk
    head, tail = data.split(token, 1)
    print(f"[DEBUG] Token found, head size: {len(head)}, tail starts with: {tail[:20]}")
    return head, tail

def stream(host, port, full, outdir):
    print("[DEBUG] Starting stream")
    sock = connect(host, port)
    header, buf = until(sock, b"\r\n\r\n")
    print(f"[DEBUG] HTTP header received, size: {len(header)}")
    m = re.search(rb"boundary=(\S+)", header)
    boundary = b"--" + m.group(1) if m else BOUNDARY
    print(f"[DEBUG] Using boundary: {boundary}")
    cv2.namedWindow("Andonstar_Open_Source_Wifi_Viewer_by_Dreg", cv2.WINDOW_NORMAL)
    if full:
        print("[DEBUG] Enabling fullscreen mode")
        cv2.setWindowProperty("Andonstar_Open_Source_Wifi_Viewer_by_Dreg",
                              cv2.WND_PROP_FULLSCREEN,
                              cv2.WINDOW_FULLSCREEN)
    idx = 0
    while True:
        print(f"[DEBUG] Waiting for frame boundary")
        _, buf = until(sock, boundary + b"\r\n")
        head, buf = until(sock, b"\r\n\r\n")
        m = re.search(rb"Content-Length:\s*(\d+)", head, re.I)
        if not m:
            print("[DEBUG] Content-Length not found, skipping")
            continue
        size = int(m.group(1))
        print(f"[DEBUG] Frame content-length: {size}")
        while len(buf) < size:
            print(f"[DEBUG] Buffer size {len(buf)} < {size}, receiving more")
            buf += sock.recv(4096)
        jpeg, buf = buf[:size], buf[size:]
        print(f"[DEBUG] JPEG image size: {len(jpeg)}")
        img = cv2.imdecode(np.frombuffer(jpeg, np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            print("[DEBUG] Failed to decode JPEG image, skipping")
            continue
        cv2.imshow("Andonstar_Open_Source_Wifi_Viewer_by_Dreg", img)
        if cv2.waitKey(1) == 27:
            print("[DEBUG] ESC pressed, exiting loop")
            break
        if outdir:
            path = outdir.joinpath(f"frame_{idx:06}.jpg")
            print(f"[DEBUG] Saving frame to {path}")
            path.write_bytes(jpeg)
        idx += 1
        print(f"[DEBUG] Frame {idx} processed")

def main():
    print("[DEBUG] Parsing arguments")
    ag = argparse.ArgumentParser()
    ag.add_argument("ip", nargs="?", default="192.168.1.254")
    ag.add_argument("--save", metavar="DIR")
    ag.add_argument("--fullscreen", action="store_true")
    args = ag.parse_args()
    outdir = pathlib.Path(args.save).expanduser() if args.save else None
    if outdir:
        print(f"[DEBUG] Creating output directory: {outdir}")
        outdir.mkdir(parents=True, exist_ok=True)
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
    preview(args.ip, True)
    try:
        stream(args.ip, 8192, args.fullscreen, outdir)
    finally:
        print("[DEBUG] Cleaning up, closing viewer")
        cv2.destroyAllWindows()
        preview(args.ip, False)

if __name__ == "__main__":
    print("[DEBUG] Running main()")
    main()
