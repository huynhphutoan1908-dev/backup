@echo off
cd /d "C:\Users\huynh\Downloads\htht by daniel"
zig c++ -shared -O2 -fms-extensions -Wno-dll-attribute-on-redeclaration -o daniel_mod.dll -I src -I minhook\include -I imgui -I imgui\backends src\version_proxy.cpp src\dx11_hook.cpp src\daniel_menu.cpp minhook\src\buffer.c minhook\src\hook.c minhook\src\trampoline.c minhook\src\hde\hde64.c imgui\imgui.cpp imgui\imgui_draw.cpp imgui\imgui_tables.cpp imgui\imgui_widgets.cpp imgui\backends\imgui_impl_win32.cpp imgui\backends\imgui_impl_dx11.cpp -ld3d11 -ldxgi -lgdi32 -luser32 -ldwmapi -ld3dcompiler_47
if %ERRORLEVEL% EQU 0 (
    copy /y daniel_mod.dll version.dll
    echo COMPILE_SUCCESS
) else (
    echo COMPILE_FAILED
)
