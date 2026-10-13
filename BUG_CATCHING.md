# BugCatching.lua — daily hunt, False Swipe slot 1

Load `BugCatching.lua` trong thư mục clone; giữ sibling `Lib/BugCatchingScore.lua`.
Không cần Pathfinder. NPC release trong Area đã bị xóa; theo xác nhận mới của
người dùng, có **PC trong Bug Catching Contest Hall**, và ra/vào Hall **vẫn giữ lượt
thi cũ, timer và catches**. Script dùng PC thật ở Hall để release con thường
kém best rồi quay lại hunt. Không dùng menu NPC release cũ hoặc đoán box row.
Bạn tự vào thi, check điểm NPC và nộp bài. Không tương tác NPC Hall `(12,12)`,
không mua đồ, không relog, không ghi trạng thái tài khoản.

## Chạy

1. Mang catcher khỏe, biết **False Swipe ở slot 1**, cùng đủ bóng. Lần đầu
   vào thi chỉ mang catcher; các slot 2–6 được script coi là catches của lượt
   hiện tại, không tự xác minh Pokémon đó có hợp lệ để nộp hay không.
   **Không mang Pokémon ngoài lượt contest ở slot 2–6**: các con thường kém
   best ở các slot này có thể bị release vĩnh viễn khi bật PC cleanup.
2. Tự vào **Bug Catching Area**, bắt đầu script ngay khi vào.
3. Chỉnh đầu file:
   - `RECTANGLE = {30,45,42,45}`: giữ cấu hình bãi cỏ hiện tại của bạn;
     chưa xác minh walkable live. Đổi thành bãi cỏ bạn chọn.
   - `MINUTES_REMAINING = 20`: **thời gian còn lại thực tế**, không phải thêm
     20 phút vào lượt đã chạy. Nếu vào được 5 phút thì đặt `15` trước khi load.
   - `ENABLED_TIERS`: mặc định **cả 1/2/3/4 bật**. Tier 1–2 chỉ bắt nhóm HP
     cao nhất có thể theo species + level (HP weight=1). Tier 3–4 **ném bóng
     ngay**, không False Swipe, không lọc HP hay score upper bound.
   - `AUTO_PC_CLEANUP = true`: mặc định dùng PC Hall. Tọa độ bạn cung cấp:
     Hall vào Area `(24,5)`, khu PC `(10,10)`. Cache Area có cửa ra
     `(36,56)` / `(37,56)` nên `AREA_EXIT={36,56}`. Theo báo cáo người dùng,
     `(25,6)` là vị trí xuất hiện trong Hall, không phải cửa ra của Area.
     `usePC()` tự tìm ô đứng mở PC thực tế, không cố đứng trên sprite PC.
     Cache hiện tại nhận diện tile PC `(10,11)` và ô access `(10,12)`;
     cache không chứng minh khả dụng/quy tắc contest live.
   - Các quota dưới đây **chỉ áp dụng khi `AUTO_PC_CLEANUP=false`**:
     `MAX_LOW_TIER_CATCHES = 2`: tổng tối đa **2 con thường tier 1 + tier 2**
     trước giai đoạn cuối. Nếu vào chỉ có catcher, còn 3 chỗ cho tier 3–4 hoặc
     shiny/form. Đây không phải 2 con mỗi tier. Giá trị hợp lệ `0..5`.
   - `LOW_TIER_FILL_LAST_MINUTES = 3`: trong 3 phút cuối theo timer local,
     cho phép tier 1–2 dùng chỗ trống còn lại để tránh hết giờ mà chưa có mẫu.
     Vẫn giữ lọc HP cao nhất và score upper bound; không bắt bừa cho đầy.
     Đặt `0` để giữ quota đến hết lượt, không mở chỗ cho tier thấp.
   - `STOP_AT_SCORE = 0`: hunt tiếp; đặt ví dụ `250` để dừng khi đã bắt được
     con đạt ít nhất 250 điểm. Chỉ kiểm tra sau battle, không bỏ dở capture.
4. Đọc log `BAT ... IV=... score=...`; dòng `NOP slot ...` chỉ con điểm cao
   nhất **đang trong party**, không cộng điểm nhiều con lại với nhau.
5. Có best mới cao điểm hơn hoặc đầy đội: nếu có con thường kém best, script
   ra Hall, mở PC, release từng con, rồi vào lại Area. Không tốn chuyến Hall
   sau mỗi catch kém điểm khi chưa đầy. Giữ catcher/best/shiny/form/con chưa
   tính được score. Nếu đầy đội mà chỉ còn các con được bảo vệ thì dừng báo best;
   không bắt tràn PC. Khi tắt cleanup, đầy đội luôn dừng cho bạn tự nộp.
6. Hết giờ, đạt điểm cấu hình hoặc server đưa ra khỏi area: script dừng,
   bạn tự nộp. Nếu đang battle lúc deadline, bạn xử lý battle đó thủ công.

**Timer:** đồng hồ local tính cả lúc pause/Stop; Stop/Start trong cùng Lua VM
không gia hạn. **Reload file/khởi động lại client tạo timer mới**, vì vậy phải
đặt lại `MINUTES_REMAINING` theo lượt hiện tại. Script không có API đọc timer
contest server; timer/map transition của server mới là chuẩn. Không dùng cho
weekly multiplayer 60 phút. Không tự vào lại contest khi bị disconnect.
Stop/Start trong Hall chỉ tiếp tục nếu cùng Lua VM còn lưu luồng cleanup;
load mới khi đang ở Hall sẽ dừng, không tự nhận/vào một lượt contest mới.

## Calculator

Theo [luật daily trên PRO Wiki](https://wiki.pokemonrevolution.net/Bug_Catching_Area):

```text
score = (min(level, 25) + tổng 6 IV + tierBonus) × (shiny ? 1.5 : 1)
tierBonus: 1=50, 2=75, 3=100, 4=130
```

Không bỏ phần level khỏi điểm; chỉ cap ở 25. Giữ điểm `.5` cho shiny, chưa
giả định cách NPC làm tròn. Đối chiếu NPC nếu luật server thay đổi.

Host hiện có `getOpponentHealth()` (HP hiện tại) và `getOpponentMaxHealth()`
(HP tối đa), **không có global `GetOpponentHP()`**. Trước khi bắt, module dùng
**max HP**, level và base HP để liệt kê mọi IV `0..31` thỏa mãn:

```text
maxHP = floor((2 × baseHP + HP_IV) × level / 100) + level + 10
```

Giả định wild EV HP=0, stat không bị biến đổi. Base HP đối chiếu dữ liệu game
local `PROProtocol/Resources/PokemonData.json`, không lấy current HP sau damage.
Phép tính này chạy ngay đầu `onBattleAction()` ở bước chọn encounter,
**trước False Swipe và trước ném bóng**, không cần bắt Pokémon trước:

```text
TRUOC BAT Caterpie | HP battle=65/65 | baseHP=45 | lv25 => HP IV=30..31 | HP weight=1.000 (topHP=65)
```

Trọng số HP chuẩn hóa theo **cùng loài + level**:

```text
lowHP = HP theo IV=0; topHP = HP theo IV=31 (EV=0)
HP weight = (maxHP wild - lowHP) / (topHP - lowHP)
```

Nếu `topHP==lowHP` thì mọi IV cho cùng HP, weight=1 nhưng không phân biệt
được IV. Tier 1–2 chỉ nhận **maxHP wild == topHP**, không so raw HP của hai
loài/level khác nhau. Ví dụ Caterpie lv25 HP65 là nhóm IV **30..31**; HP64
là IV26..29 và bị bỏ qua. Weight=1 **không khẳng định IV31**. HP cao không
bảo đảm tổng 6 IV cao; heuristic này vẫn có thể bỏ một con tổng điểm tốt.

Năm IV còn lại chưa biết (`0..155` tổng); log trước bắt là **khoảng điểm có
thể**, không phải điểm chính xác. Tier 1–2 cũng bỏ nếu upper bound không hơn
best. Tier 3–4 bỏ qua cả hai bộ lọc, bắt ngay theo yêu cầu. Thiếu/mâu thuẫn HP
data thì không loại vì HP; form không giả định base HP dạng thường.

Sau khi server cập nhật party, lấy đủ 6 `getPokemonIndividualValue()` để tính
điểm, chọn best. Ball được gửi không được coi là bắt thành công: nếu kết thúc
battle mà chưa có catch trong party, chờ tối đa 3 giây rồi dừng kiểm tra.

## Hall PC cleanup — mặc định bật

- Chỉ release **party slot hiện tại**, không gọi `releasePokemonFromPC`,
  deposit/withdraw hoặc duyệt dữ liệu storage. Box chứa Pokémon ngoài contest
  không bị chọn để release. Guard bắt buộc đúng Hall, gần khu PC, `isPCOpen()`
  và `isCurrentPCBoxRefreshed()` đều ready, cùng `getCurrentPCBoxSize()>=0`
  xác nhận đã có storage snapshot (size 0 hợp lệ) trước mỗi lệnh. Không coi
  refresh timeout tự hết là PC đã sẵn sàng để release.
- Giữ catcher slot 1, con điểm cao nhất (giữ winner cũ khi hòa), mọi shiny/form
  và con chưa tính được score. Dọn các con thường còn lại thấp điểm nhất trước.
- ID phải nguyên, duy nhất, biểu diễn chính xác trong Lua (`1..2^53-1`). Gửi
  **một lệnh release**, chờ server bỏ đúng ID và giữ đúng thứ tự/ID còn lại;
  sau đó chờ PC refresh và tính lại slot. Không tự xóa local party hoặc gửi lại
  release khi phản hồi chậm. Party/best/target thay đổi ngoài dự kiến thì dừng.
- Timeout mỗi chặng exit/PC/return là 60 giây; chờ xác nhận release 10 giây.
  Deadline, catcher KO/đổi slot, map sai hoặc PC từ chối đều dừng. Các timeout
  kiểm tra ở callback tiếp theo; nếu server không trả callback, Stop thủ công.
- Di chuyển từ PC về cửa Hall dùng luồng host bình thường để đóng PC; không
  giả trạng thái PC hoặc thêm API đóng không tồn tại. Timer không reset khi
  sang Hall hay trở lại Area. Khi hết giờ/đạt STOP_AT_SCORE thì ưu tiên dừng,
  không bắt đầu thêm chuyến dọn đội. Không rollback release đã gửi.
- Wild thường trên đường ra Hall thì chạy để hoàn tất chuyến dọn đội;
  shiny/form vẫn bắt nếu còn chỗ, đầy đội thì dừng để bạn xử lý thủ công.

## Ngân sách chỗ trong party — fallback khi tắt PC cleanup

- Quota tính từ **party server hiện tại** ở slot 2–6, không đếm số bóng đã
  gửi. Catch tier 1–2 vẫn tính quota dù IV chưa đủ để chấm điểm. Stop/Start
  hoặc reload không làm quota về 0 khi các con đã bắt vẫn còn trong party.
- Shiny/form bỏ qua quota/tier/HP/score và được ném bóng ngay nếu còn chỗ.
  Chúng không tính là catch thường tier 1–2, nhưng **vẫn chiếm một slot**.
  Vì vậy 3 chỗ dành tier cao không phải cam kết luôn còn trống sau catch đặc biệt.
- Tier 3–4 bật thì ném bóng ngay, kể cả điểm upper bound không hơn best theo
  chính sách đã chọn. Khi tắt PC cleanup thì không thể tự loại con cũ.
- Mở quota cuối giờ chỉ áp dụng khi chọn **encounter mới**, không đổi quyết
  định giữa các lượt của cùng encounter. Timer local vẫn chịu giới hạn reload
  đã nêu ở trên. Có thể đặt `MAX_LOW_TIER_CATCHES=0` và fill `0` để chỉ hunt
  tier cao/shiny/form, hoặc quota `5` để không dành chỗ trước giờ cuối.
- Đây là heuristic cân bằng số mẫu và chỗ cho loài hiếm, **không bảo đảm điểm
  tối ưu**. HP không cho biết 5 IV còn lại; đầy party phải dừng dù còn thời gian.
- Khi tắt cleanup, không gọi PC/release hoặc tự rời Area. Đã bỏ hoàn toàn
  cấu hình/callback/menu NPC release cũ.

## Battle guards

- Với tier 1–2, False Swipe tối đa 3 lần gửi thành công mỗi encounter; HP1/hết PP/không dùng
  được move thì ném bóng, không lặp vô hạn. Không gọi attack hoặc switch sang
  Pokémon vừa bắt. Catcher KO/slot thay đổi thì dừng.
- Bóng: Ultra Ball → Great Ball → Pokeball. Tier 3–4 và shiny/form bắt trực
  tiếp; shiny/form bỏ qua lọc tier/IV/điểm/quota nhưng vẫn chịu giới hạn party.
- Hết bóng/không gửi được action thì dừng, không run/đánh chết mục tiêu.
- Log 1 lần quyết định mỗi encounter và 1 lần mỗi catch, không mỗi battle tick.

## Xác minh

Từ `D:\proshine`:

```powershell
& tests\BugCatchingRegression.ps1 -ScriptRoot D:\Pathfinder-main1
```

Offline: đối chiếu 21 base HP; 67.200 tổ hợp species/level/IV; khoảng IV,
score bounds, trọng số/nhóm HP tối đa, tier 3–4 ném bóng ngay, False Swipe/PP,
tier toggle, quota chung/party khi restart, mốc mở quota cuối giờ, giữ bộ lọc,
shiny/form, đầy đội không tràn PC, winner, timer pause/Stop, party update chậm,
cấu hình sai; luồng Hall/PC ready/release/party ack/đổi slot, timeout, bảo vệ
catcher/best/shiny/form và actual Lua host load. Test PC dùng state mô phỏng,
không kết nối game hoặc thực hiện release live.
Chưa xác minh live rectangle, HP/maxHP, điểm NPC hay lượt ra Hall/release/vào lại.
Quy tắc giữ lượt khi đi Hall dựa trên xác nhận của bạn, không phải trace mới
do mình chạy. Không tự động nhận/nộp contest.
