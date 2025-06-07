#!/bin/bash

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

echo "-"
echo "you must be connected to ANDONSTAR WIFI!"
echo "-"

set -x 

# Enable preview mode
curl "http://192.168.1.254/?custom=1&cmd=3001&par=1"

# Open VLC (or ffplay if preferred)
vlc http://192.168.1.254:8192/ 

# Wait for user to press enter
read -p "Press ENTER to disable preview and exit..."

# Disable preview mode
curl "http://192.168.1.254/?custom=1&cmd=3001&par=0"