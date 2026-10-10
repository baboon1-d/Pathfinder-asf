# Changelog

Chỉ ghi các thay đổi có trong repo này. Nền thư viện vẫn mang version 2.6.5;
ngày bên dưới là ngày publish, không phải version mới của client.

## 2026-10-10

### Cập nhật Daily Solaceon và Floaroma Meadow

- Thêm script tùy chọn `DailySolaceon.lua` và helper
  `Lib/DailySolaceonHunt.lua`; không đưa các script cá nhân khác vào bundle.
- Daily dùng multi-target search hiện có để chọn node spawn gần nhất theo chi
  phí Pathfinder, giờ và membership; loại fishing-only và bỏ cap 50 map.
- Sửa fall-through tìm cỏ tại map sai khi vừa chọn bãi hoặc travel thất bại;
  chỉ săn khi đã tới chính xác node, không chỉ cùng map vật lý.
- Đổi bãi khi travel bị từ chối lặp lại ở cùng vị trí; patrol hai ô encounter
  liền kề thay vì chạy ngẫu nhiên khắp map. Giới hạn công việc tìm đường mỗi
  callback; giữ luồng quest, bắt Pokémon, PC và file trạng thái.
- Floaroma_B: thêm hàng `(13..35,24)` vào vùng dưới đồi, sửa lỗi lookup tại
  `(24,24)`. Không mở rộng B qua hàng rào lên A.
- Sửa cấu trúc checkpoint Town → Meadow_B thành `{{12,4,13,4}}`.
- Thêm MapLink/MapException A → B tới dải đáp `(20..34,23)`; giữ một chiều,
  B → A vẫn đi vòng qua Route 205 / Fuego Ironworks.
- Bổ sung hướng dẫn update/reload, giới hạn node/`moveToGrass()` và `.gitignore`
  cho Accounts, log, cache, trạng thái cá nhân và backup.
- Giữ nguyên `MoveTo.lua`/CellCrawl, graph-cost-only, cấu hình public default-only
  và dữ liệu không liên quan đã có trên remote; không chép đè snapshot desktop.

#### Kiểm tra đợt cập nhật

- MoonSharp syntax: **49/49 file Lua**; liên kết tài liệu nội bộ hợp lệ.
- Daily regression và real Pathfinder/spawn loader smoke: PASS với chính
  bundle publish, bao gồm `MoveTo.lua` của repo này.
- Floaroma Lua regression/cache: PASS; 23 ô B bổ sung có thể tới từ Town,
  chiều lên trực tiếp bị chặn, link Town khớp cache và tuyến vòng qua Fuego.
- **Chưa xác nhận live sau sửa**. Cache không chứng minh NPC đang hoạt động
  hoặc điều kiện quest/dialog của server. Không đổi protocol, crypto, auth,
  Lua API hoặc thuật toán Pathfinder để vượt rào.

### Bản publish đầu (giữ lịch sử)

#### Đã thêm

- Publish thư mục `Pathfinder/` và `Settings/` từ bản làm việc desktop.
- README: cấu trúc, cài đặt, API tích hợp, cấu hình, xử lý lỗi map và quy tắc publish.
- CHANGELOG theo dõi thay đổi và phân biệt kiểm tra offline với xác nhận live.

#### Feral Site

- Thay phân vùng tọa độ cũ bằng các component của cached map hiện tại.
- Xác định `(13,24)` là `Feral Site_A`, tránh yêu cầu sai tuyến B → A.
- MapExceptions dùng `(19,22)` cho A → B và `(19,24)` cho B → A.
- Thêm ô reset `(19,21)` / `(19,25)` khi người chơi đã đứng trên ô link.
- Bổ sung phân vùng cho các ô excavation NPC không thể đứng trực tiếp lên.

#### Làm sạch bản publish

- `Static_Settings.lua` chỉ giữ profile `default`; bỏ profile/ID cá nhân.
- Không thay đổi cấu hình tài khoản trong bản local khi xuất bản sạch.
- Không publish `Script.lua`, script bên ngoài thư mục hoặc ba file backup.

#### Giới hạn

- CellCrawl đang tắt trong `MoveTo.lua`; bản publish này không tự học map/link.

#### Kiểm tra

- MoonSharp: **47/47 file Lua** qua kiểm tra cú pháp.
- Cấu hình default-only: qua kiểm tra với các tên tài khoản giả lập.
- JSON/Python: parse thành công.
- Feral: 25 excavation NPC xác định được submap; phân vùng A/B không chồng nhau.
- Index Git của lần publish code: 57 file, chỉ thuộc `Pathfinder/` và `Settings/`.

#### Chưa xác nhận live

- Chuyển vùng Feral A ↔ B và bước reset link sau bản sửa.
- Toàn bộ hành trình giữa các map và các dịch vụ transport trên server hiện tại.
