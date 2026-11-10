LS:RP — HƯỚNG DẪN CÀI ĐẶT OPEN.MP
======================================

NỀN TẢNG
--------
- Server target: open.mp Windows x86.
- Source chính: gamemodes/main.pwn.
- Compiler: qawno/pawncc.exe đi kèm bộ open.mp trong repo.
- Include open.mp, MySQL, BCrypt và YSI: qawno/include.
  Script build gọi compiler open.mp; không cần chép compiler Pawno vào repo.
- Runtime open.mp và các component nằm ở thư mục gốc và components/.

CÀI ĐẶT
-------
1. Cài MariaDB/MySQL và tạo user SQL. database_structure.sql sẽ tạo database lsrp.
2. Copy mysql.ini.example thành mysql.ini trong thư mục gốc, cạnh omp-server.exe.
   Đặt hostname, username, database và server_port theo file mẫu.
   Nếu tài khoản MySQL có mật khẩu, thêm dòng password = mat_khau_cua_ban.
   Nếu mật khẩu để trống (ví dụ root XAMPP mặc định), xóa hẳn dòng password;
   không ghi password = vì MySQL R41-4 từ chối giá trị cấu hình rỗng.
3. Import database_structure.sql vào MariaDB/MySQL trước.
4. Chạy lần lượt các file trong database/migrations:
   001_account_characters.sql
   002_character_profile.sql
   003_owned_vehicles.sql
   004_admin_system.sql
   005_character_jobs.sql
   006_job_employment.sql
   007_character_current_job.sql
   008_vehicle_fuel.sql
5. Chạy COMPILE.bat hoặc Ctrl+Shift+B để biên dịch main.pwn bằng compiler open.mp.
6. Chạy RUN_LSRP.bat. Lần đầu script cài MySQL R41-4, samp-bcrypt 0.4.1
   và YSI 5.10.0006 nếu thiếu; sau đó mở omp-server.exe.

Không cần thêm STREAMER, sscanf hoặc Pawn.CMD cho source hiện tại.
Chỉ thêm chúng nếu code bắt đầu include hoặc gọi chúng.

OPEN.MP
-------
- main.pwn include trực tiếp <open.mp>.
- config.json nạp main.amx và khai báo MySQL/BCrypt trong legacy_plugins.
- MySQL/BCrypt là plugin tương thích SA-MP cũ; open.mp tải chúng qua
  lớp tương thích. Chúng không phải open.mp components.
- Repo hiện đóng gói runtime Windows x86; nếu VPS là Linux, cần bộ runtime
  open.mp Linux và các plugin .so tương ứng.

SERVER LOCAL
------------
127.0.0.1:7777

RCON
----
RCON bị tắt mặc định. Nếu cần dùng, bật trong config.json và đặt password
riêng trước khi đưa server lên mạng. Không dùng mật khẩu mẫu công khai.
