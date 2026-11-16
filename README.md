# HTDC Daniel Mod (Full Source & Backup)

Bản Mod toàn diện cho Hải Tặc Đại Chiến / Legendary Pirates:
- **Giao diện Modern Glass (DirectX 11 / ImGui)**: Tăng tốc game (1x - 1000x), Cap FPS (30/60/120/144/Mở khóa), Nút avatar nổi kéo thả tự do.
- **Tích hợp trọn bộ 10 tính năng HTDC Clean (Vinh)**: Nạp qua IL2CPP runtime `LuaEnv.DoString` không crash, không dependency.
- **Tự động săn Mảnh Vàng / Mảnh Đỏ**: Nút native trong game hiển thị trực tiếp số lượng nhặt được `(+%d Mảnh) [Dừng]`.

## Cách cài đặt:
1. Copy `release/version.dll` và `release/daniel_mod.dll` vào thư mục game chứa `LegendaryPirates.exe`.
2. Khởi động game và tận hưởng!

## Cách tự biên dịch (Build):
Chạy `build_mod.bat` bằng Zig C++:
```cmd
build_mod.bat
```
