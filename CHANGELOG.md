# Changelog

Chỉ ghi các thay đổi có trong repo này. Nền thư viện vẫn mang version 2.6.5;
ngày bên dưới là ngày publish, không phải version mới của client.

## 2026-10-12

### DigRework và policy di chuyển

- Thêm `digrework.lua` + `Lib/ActiveHarvestRoute.lua`: thu gom Dig/PokeStop/Berry
  chung tuyến, không Excavation; lịch Kanto → Johto → Hoenn → Sinnoh.
- Giữ đích ổn định, lưu kiến thức node đã kiểm tra và hoãn điểm lỗi mà không
  ghi DONE. Không quay lại vùng đã kết thúc chỉ vì timer skip ngắn hết hạn.
- Thêm `getRegion` từ nguồn graph authored; giữ định dạng ba file tiến trình
  và cooldown. Không kèm file trạng thái hay tài khoản thật.
- Policy opt-in `preferTransport`: ưu tiên Subway/Transmat được bật cho hành
  trình tới đích cố định, kể cả cost cao hơn đi bộ; không tạo vòng ga cho công
  việc local. Không thay trọng số, không vượt `USE_SUBWAY`/`USE_TELEPORT`.
- Policy opt-in `digFallback`: skip cạnh Dig một chiều khi tương tác không
  khả dụng hoặc outlet từ chối đã biết; yield rồi tính lại tới cùng đích.
  Giữ các cạnh Dig khác, không ép cửa ngược và không ghi DONE giả.
- `requireActionable` cho phép tour bỏ cạnh thiếu checkpoint/handler trước
  khi đi xa. Preview/dispatch dùng cùng policy, cache phân biệt các options.

### Helper/map đi kèm

- Đồng bộ module điều hướng đang hoạt động và dialog solver từ workspace
  chính. Giữ **graph-cost-only** và **CellCrawl tắt**; không chép đè module
  discovery đang không dùng, dữ liệu Excavation hoặc database spawn trên remote.
- Alias Meteor Falls 1F 1R giữ subnode; sửa snapshot inventory restriction
  tránh mất Bicycle ở các lần tính tuyến xen kẽ.
- Dùng checkpoint LinkExceptions khi thiếu MapLink, giảm spam progress/
  checkpoint bằng các kênh chống lặp độc lập.
- Export `setMount`, `setWaterMount`, `useMount`; tái sử dụng API host,
  không tự dùng water mount trên đất hoặc sửa hành vi Surf của client.
- Route 16 Stop House: sửa hướng cửa A/B. Mt. Mortar 1F: gán NPC DigSpot
  `(57,36)` vào C, không sửa collider/walkability.
- Giữ Daily/Floaroma đã publish và Settings **default-only**. Bổ sung README,
  ignore file tiến trình harvest và backup JSON. Không kèm script cá nhân khác.

### Xác minh

- MoonSharp syntax: **51/51 file Lua PASS**, kiểm tra chính clone publish.
- **9 regression PASS**: Dig travel fallback, transport preference, combined
  harvest, region schedule, actionable routes, navigation log, Meteor alias,
  Daily Solaceon và Floaroma Meadow (bao gồm cache check).
- Mount API smoke PASS: Surf/shore, một action/frame, 1000 mounted ticks,
  cấu hình lỗi/disable/restart. Map smoke PASS: Route 16 B → Stop House → A →
  house và lookup NPC Mt. Mortar `(57,36)`; movement/server được giả lập.
- Real graph Cinnabar → Maze: tuyến cost thường **7.4**, tuyến policy dịch vụ
  **8.3** qua Fuchsia/Pewter Subway; Forest → Maze vẫn trực tiếp cost **1**.
  Route 3 → Route 4: Dig bị từ chối chuyển từ cost **1** sang đường bộ **6.7**,
  giữ cùng đích. Đây là graph cost, không phải thời gian đo trên server.
- 1000 cached dispatch ticks không lặp planning/log/DONE; phép đo offline lần
  publish: **104 ms CPU** tổng, preferred cold query **475 ms CPU**. Không phải
  latency hoặc benchmark UI/live.
- Source host **WPF Debug/Release** và **Avalonia Desktop Debug/Release** build
  PASS trong output riêng; không sửa source host để publish bundle.
- **Chưa xác nhận live sau publish**. Không thay Core, protocol, crypto, auth,
  Lua API host, battle hoặc thuật toán tìm đường theo ô của client.

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
