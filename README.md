BÁO CÁO DỰ ÁN FLUTTER - "demo"
1. Thông tin chung

- Tên repo: demo
- Chủ sở hữu: Khanh02-vin (https://github.com/Khanh02-vin)
- Ngôn ngữ chính: Dart
- Framework: Flutter
- Mục tiêu: Ứng dụng mẫu phát triển bằng Flutter.

2. Cấu trúc thư mục chính
Thư mục / File	Mô tả
lib/	Mã nguồn chính của ứng dụng
components/	Các widget hoặc phần tử UI tái sử dụng
constants/	Các giá trị hằng số như màu sắc, kích thước, API endpoint
utils/	Hàm tiện ích (helper functions)
hooks/	Các hook logic/phản ứng UI
assets/	Tài nguyên: hình ảnh, icon, JSON...
pubspec.yaml	Tệp khai báo gói và tài nguyên chính của Flutter
test/	Bài kiểm thử đơn vị
3. Các thành phần nổi bật
Ví dụ các component trong components/:
⦁	- custom_button.dart: Nút bấm được tùy biến
⦁	- image_preview.dart: Hiển thị ảnh
⦁	- camera_input.dart: Chụp ảnh từ camera

Constants:
⦁	- AppColors: Hằng số màu sắc
⦁	- AppTextStyles: Kiểu chữ thống nhất toàn app

Utils:
⦁	- image_utils.dart: Chuyển đổi và xử lý ảnh
⦁	- file_utils.dart: Đọc/ghi file ảnh, JSON...
4. Luồng hoạt động chính (giả định)
1.	Người dùng mở ứng dụng Flutter
2.	Giao diện chính cho phép chọn ảnh hoặc chụp ảnh
3.	Hình ảnh được gửi tới hệ thống xử lý (có thể dùng AI)
4.	Kết quả nhận dạng/trích xuất hiển thị lên màn hình
5.	Cho phép lưu kết quả hoặc chia sẻ
5. Gợi ý tạo tài liệu chuyên sâu hơn

Cách 1: Tạo bằng dartdoc:
- Cài: dart pub global activate dartdoc
- Chạy: dart pub global run dartdoc
- Mở: doc/api/index.html → In thành PDF

Cách 2: Dùng trình tạo báo cáo tự động (thủ công):
- Tên file, mô tả file
- Các hàm, class quan trọng
- Mối quan hệ giữa các phần
- Ảnh giao diện (nếu có thể)
