# Pathfinder-asf

Thư viện điều hướng Lua dựa trên Pathfinder 2.6.5, dành cho môi trường
Basculegion/PROShine có API Lua tương thích. Repo cung cấp module, dữ liệu map
và cấu hình dùng chung; **không phải một script bot chạy độc lập**.

## Nội dung

```text
Pathfinder/
  MoveToApp.lua          -- Entry point cho script sử dụng thư viện
  Lib/                  -- Điều hướng, hội thoại và helper
  Maps/                 -- Graph, checkpoint, submap và exception
  Spawn/                -- Dữ liệu spawn và công cụ chỉnh sửa
Settings/
  Static_Settings.lua   -- Cấu hình mặc định, không có profile tài khoản
  WorkSettings.lua      -- Cấu hình công việc/berries
README.md
CHANGELOG.md
```

Không đưa `Script.lua`, script cá nhân nằm ngoài hai thư mục, bản backup,
log hoặc ID tài khoản vào bản phát hành.

## Cài đặt

1. Tải repo hoặc clone:
   ```sh
   git clone https://github.com/shades1325-art/Pathfinder-asf.git
   ```
2. Đặt hai thư mục `Pathfinder/` và `Settings/` cạnh script của bạn.
   Giữ nguyên cấu trúc; chỉ chép `MoveToApp.lua` là không đủ.
3. Nạp module ở đầu script, trước khi bot bắt đầu chạy.
4. Sau khi cập nhật module/cấu hình, nạp lại script để tránh dùng module đã cache.

Thư viện cần các API do client cung cấp như `registerHook`, `getMapName`,
`getPlayerX`, `getPlayerY`, `moveToCell` và `talkToNpcOnCell`.
Không chạy trực tiếp bằng trình thông dịch Lua thông thường.

## Sử dụng

Đoạn tích hợp tối thiểu bên trong script riêng:

```lua
local pf = require "Pathfinder/MoveToApp"

function onPathAction()
    return pf.moveTo(getMapName(), "Lilycove City")
end
```

Đây chỉ là ví dụ điều hướng. Script gọi thư viện phải tự xử lý battle,
hồi phục và công việc sau khi đến đích.

| API | Mục đích |
| --- | --- |
| `pf.moveTo(currentMap, destination)` | Tiếp tục hành trình đến map hoặc node đích. |
| `pf.getPath(startNode, destination)` | Lấy tuyến graph, không thực hiện di chuyển. |
| `pf.getMapNode(map, x, y)` | Xác định node/submap tại tọa độ. |
| `pf.mapName()` | Lấy node hiện tại của người chơi. |
| `pf.moveToMapCell(currentMap, destinationMap, x, y)` | Điều hướng đến một ô trên map đích. |

Chỉ thực hiện **một action mỗi callback**. Khi lời gọi trả `true`, hãy kết thúc
callback ngay; action được gửi/queued không đồng nghĩa server đã hoàn tất.
`false` cũng không tự chứng minh đã đến đích: kiểm tra map/node và vị trí thực tế.

Tên node `_A`, `_B`, `_C` là phân vùng của Pathfinder, không nhất thiết là tên
map server. Dùng `getMapNode` thay vì tự chia map chỉ theo trục Y.

## Cấu hình

Chỉnh profile `default` trong `Settings/Static_Settings.lua`:

| Tùy chọn | Ý nghĩa |
| --- | --- |
| `MOUNT` | Mount dùng khi di chuyển. |
| `DISCOVER`, `HARVEST`, `HEADBUTT`, `DIG` | Bật/tắt công việc tương ứng khi đi đường. |
| `USE_SUBWAY` | Cho phép các cạnh subway. |
| `USE_TELEPORT` | Cho phép các cạnh teleport/Transmat. |
| `K_SUBWAY`, `J_SUBWAY`, `H_SUBWAY` | Trọng số tuyến subway theo vùng. |
| `J_TO_K`, `H_TO_KJ` | Trọng số kết nối liên vùng được cấu hình trong graph. |

Trọng số là chi phí đánh giá tuyến, **không phải số tiền bị trừ**. Tăng trọng số
không đồng nghĩa cấm tuyến. Nếu tài khoản không dùng được subway/Transmat,
đặt tùy chọn `USE_*` tương ứng thành `false`.

Bản công khai chỉ giữ `default`. Nếu cần profile theo tài khoản, thêm ở bản local
và loại bỏ trước khi commit; không đưa tên/ID cá nhân hoặc thông tin đăng nhập lên Git.

## Chỉnh map và xử lý lỗi

- `Maps/{region}/*Map.lua`: các node, cạnh, trọng số và điều kiện của graph.
- `Maps/MapLink.lua`: checkpoint nguồn cho các cạnh di chuyển thông thường.
- `Maps/MapExceptions/SubstituteMaps.lua`: vùng tọa độ của từng submap.
- `Maps/MapExceptions/MapExceptions.lua`: action cho các cạnh đặc biệt cùng map.
- `Maps/MapExceptions/NpcExceptions.lua`: tương tác NPC và hội thoại theo tuyến.

Graph có cạnh chưa đủ để bot đi được: checkpoint cũng phải đúng và có thể tiếp cận
từ node nguồn. `MapExceptions` được xử lý trước `MapLink`; chỉ sửa
`LinkExceptions.lua` không đảm bảo thay đổi action đang thực hiện.

### Feral Site

- A là component có lối vào/cart; `(13,24)` vẫn thuộc **A**.
- A → B đi vào `(19,22)`; B → A đi vào `(19,24)`.
- Nếu đã đứng trên ô link, exception dùng ô reset `(19,21)` hoặc `(19,25)`
  để bước ra trước khi bước lại vào link.
- Không thay phân vùng hiện tại bằng một đường cắt Y đơn giản.

### Giới hạn hiện tại

- CellCrawl tự học link đang **tắt trong `MoveTo.lua`**, dù file module vẫn có trong repo.
- Dữ liệu map là dữ liệu authored, không tự đồng bộ khi server đổi map.
- Kiểm tra cú pháp/offline không chứng minh mọi tuyến hoạt động trên server.
- Chuyển vùng Feral A ↔ B sau bản sửa vẫn cần xác nhận bằng trace live mới.

Khi báo lỗi, gửi tên script/module đang nạp, map/node nguồn và đích, tọa độ người
chơi, checkpoint bị lỗi và một đoạn log ngắn. Không gửi thông tin đăng nhập.

## Kiểm tra và đóng góp

Bản publish đầu đã qua kiểm tra cú pháp MoonSharp **47/47 file Lua**, cấu hình
default-only và parse JSON/Python. Không có bộ test live-server tự động trong repo.

Giữ thay đổi nhỏ, kiểm tra đúng call chain và chỉ stage các đường dẫn cần thiết:

```sh
git add -- Pathfinder Settings README.md CHANGELOG.md
```

Trước khi push, kiểm tra `git diff --cached` và làm sạch profile cá nhân trong
`Static_Settings.lua`. Không dùng `git add .` để gom script/log ngoài phạm vi.

Xem [CHANGELOG.md](CHANGELOG.md) để biết lịch sử bản phát hành.
