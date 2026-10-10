# Changelog

Chỉ ghi các thay đổi có trong repo này. Nền thư viện vẫn mang version 2.6.5;
ngày bên dưới là ngày publish, không phải version mới của client.

## 2026-10-10

### Đã thêm

- Publish thư mục `Pathfinder/` và `Settings/` từ bản làm việc desktop.
- README: cấu trúc, cài đặt, API tích hợp, cấu hình, xử lý lỗi map và quy tắc publish.
- CHANGELOG theo dõi thay đổi và phân biệt kiểm tra offline với xác nhận live.

### Feral Site

- Thay phân vùng tọa độ cũ bằng các component của cached map hiện tại.
- Xác định `(13,24)` là `Feral Site_A`, tránh yêu cầu sai tuyến B → A.
- MapExceptions dùng `(19,22)` cho A → B và `(19,24)` cho B → A.
- Thêm ô reset `(19,21)` / `(19,25)` khi người chơi đã đứng trên ô link.
- Bổ sung phân vùng cho các ô excavation NPC không thể đứng trực tiếp lên.

### Làm sạch bản publish

- `Static_Settings.lua` chỉ giữ profile `default`; bỏ profile/ID cá nhân.
- Không thay đổi cấu hình tài khoản trong bản local khi xuất bản sạch.
- Không publish `Script.lua`, script bên ngoài thư mục hoặc ba file backup.

### Giới hạn

- CellCrawl đang tắt trong `MoveTo.lua`; bản publish này không tự học map/link.

### Kiểm tra

- MoonSharp: **47/47 file Lua** qua kiểm tra cú pháp.
- Cấu hình default-only: qua kiểm tra với các tên tài khoản giả lập.
- JSON/Python: parse thành công.
- Feral: 25 excavation NPC xác định được submap; phân vùng A/B không chồng nhau.
- Index Git của lần publish code: 57 file, chỉ thuộc `Pathfinder/` và `Settings/`.

### Chưa xác nhận live

- Chuyển vùng Feral A ↔ B và bước reset link sau bản sửa.
- Toàn bộ hành trình giữa các map và các dịch vụ transport trên server hiện tại.
