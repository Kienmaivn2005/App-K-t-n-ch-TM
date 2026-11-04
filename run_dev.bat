@echo off
chcp 65001 > nul
echo ========================================================
echo   KHỞI CHẠY UNIPLAN AI - CHẾ ĐỘ PHÁT TRIỂN (FLUTTER RUN)
echo ========================================================
echo.
set FLUTTER_BIN=E:\flutter_windows_3.44.9-stable\flutter\bin\flutter.bat

if exist "%FLUTTER_BIN%" (
    "%FLUTTER_BIN%" run -d chrome
) else (
    flutter run -d chrome
)
pause

