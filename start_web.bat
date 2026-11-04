@echo off
chcp 65001 > nul
echo ========================================================
echo   KHỞI CHẠY UNIPLAN AI - ĐẠI HỌC TÂY NGUYÊN (WEB SERVER)
echo ========================================================
echo.
echo Đang mở máy chủ Web tại cổng 8080...
echo Mở trình duyệt truy cập: http://localhost:8080
echo Nhấn Ctrl + C để dừng máy chủ.
echo.
python -m http.server 8080 --directory build/web
pause

