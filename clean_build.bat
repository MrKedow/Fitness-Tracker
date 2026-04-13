@echo off
echo 正在清理构建文件...

echo 1. 停止所有正在运行的Flutter进程...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter_tools*.exe 2>nul

echo 2. 删除构建目录...
if exist build rmdir /s /q build
if exist windows\build rmdir /s /q windows\build

echo 3. 删除CMake缓存文件...
del CMakeCache.txt 2>nul
del cmake_install.cmake 2>nul
if exist CMakeFiles rmdir /s /q CMakeFiles

echo 4. 清理Flutter缓存...
flutter clean

echo 5. 清理pub缓存...
del /q pubspec.lock 2>nul
if exist .dart_tool rmdir /s /q .dart_tool

echo 清理完成！
echo 现在请运行: flutter pub get
pause