@echo off
REM ---------------------------------------------------------
REM MIT License
REM 
REM AndonstarOSWV - Andonstar Open Source Wifi Viewer
REM https://github.com/therealdreg/AndonstarOSWV/
REM Copyright (c) 2025 David Reguera Garcia aka Dreg
REM twitter: @therealdreg
REM dreg@rootkit.es
REM 
REM Permission is hereby granted, free of charge, to any person obtaining a copy
REM of this software and associated documentation files (the "Software"), to deal
REM in the Software without restriction, including without limitation the rights
REM to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
REM copies of the Software, and to permit persons to whom the Software is
REM furnished to do so, subject to the following conditions:
REM 
REM The above copyright notice and this permission notice shall be included in all
REM copies or substantial portions of the Software.
REM 
REM THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
REM IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
REM FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
REM AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
REM LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
REM OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
REM SOFTWARE.
REM ---------------------------------------------------------

echo ----------------------------------------
echo You must be connected to ANDONSTAR WiFi!
echo ----------------------------------------

@echo on

REM Enable preview mode
curl "http://192.168.1.254/?custom=1&cmd=3001&par=1"

set VLC="C:\Program Files\VideoLAN\VLC\vlc.exe"

set OPTS=--http-continuous ^
         --http-reconnect ^
         --input-repeat=65535 ^
         --network-caching=150      rem prueba 150-300 ms; si va a saltos, sube

:loop
%VLC% %OPTS% http://192.168.1.254:8192/
timeout /t 1 >nul
goto loop

echo.
pause

REM Disable preview mode
curl "http://192.168.1.254/?custom=1&cmd=3001&par=0"
