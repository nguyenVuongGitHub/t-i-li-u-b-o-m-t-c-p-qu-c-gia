--Tạo View cho biết mã loại vé (MALV), tên loại vé (TENLV), tổng lượng vé bán
--ra của các loại vé mà có tổng số lượng vé bán ra lớn hơn 200 vé. Lấy dữ liệu từ
--View này sắp xếp giảm dần theo tổng số lượng vé bán ra.
CREATE VIEW dbo.TongLuongVeLonHon200
AS
    Select  b.MALV, l.TENLV, sum(b.SOLUONG) as [Tong loai ve]
	from dbo.BANVE b
	join dbo.LOAIVE l on l.MALV = b.MALV
	group by  b.MALV, l.TENLV
	having sum(b.SOLUONG) > 2
	order by sum(b.SOLUONG) desc

--Viết thủ tục tên sp_SoLuongLoaiVeDaBanTheoThoiGian có tham số đầu vào
--là thời điểm ngày 1 (date1), thời điểm ngày 2 (date2). Sau khi thực thi thủ tục sẽ
--in ra nội dung cho biết có bao nhiêu loại vé đã được bán và tổng trị giá thu được
--từ ngày 1 cho tới ngày 2.
create proc sp_SoLuongLoaiVeDaBanTheoThoiGian(@from date, @to date)
as
begin
	select count(distinct b.MALV), SUM(b.TRIGIA)
	from BANVE b
	where b.NGAYBAN between @from and @to
end;

exec sp_SoLuongLoaiVeDaBanTheoThoiGian '2025-01-01', '2037-01-01'

--Viết một trigger tên trg_TaoThongTinMuaVe để khi thao tác thêm mới hoặc
--cập nhật 1 dòng dữ liệu thông tin bán vé trong quan hệ BANVE chỉ với các thuộc
--tính sau: MABV, MALV, SOLUONG, NGAYBAN thì sẽ tự động thực hiện các
--công việc sau:
--a) Kiểm tra giá trị của NGAYBAN phải lớn hơn hoặc bằng ngày hiện tại. Nếu
--không thỏa mãn điều kiện sẽ báo lỗi và thao tác sẽ bị hủy bỏ.
--b) Nếu thỏa điều kiện ở câu a thì tự động cập nhật giá trị của TRIGIA =
--SOLUONG * GIAVE và cập nhật giá trị NGAYHH theo nội dung mô tả trong
--quan hệ BANVE.
CREATE TRIGGER trg_TaoThongTinMuaVe
ON [dbo].[BANVE]
after INSERT, UPDATE
AS
BEGIN
    declare @ngayban date;
	declare @mabv nvarchar(10);
	declare @malv nvarchar(10);

	select @ngayban = i.NGAYBAN, @mabv = i.MABV, @malv = i.MALV
	from inserted i

	if (@ngayban < GETDATE())
	begin
		print('ngay ban phai lon hon hoac bang ngay hien tai')
		rollback tran;
		return;
	end
	else
	begin
		update BANVE
		set TRIGIA = SOLUONG * (select GIAVE from LOAIVE where MALV = @malv)
		where @mabv = MABV

		update BANVE
		set NGAYHH = DATEADD(day,(select HANSD from LOAIVE where MALV = @malv), @ngayban)
		where @mabv = MABV
	end
END

insert into BANVE(MABV,MALV,NGAYBAN,SOLUONG) values
('BV10','LV01','2025-01-07',100);
insert into BANVE(MABV,MALV,NGAYBAN,SOLUONG) values
('BV11','LV01','2024-01-07',100);
insert into BANVE(MABV,MALV,NGAYBAN,SOLUONG) values
('BV12','LV01','2026-01-07',100);

--Tạo Function F1 có tham số vào là: Mã loại vé. Function trả về tổng doanh thu
--của loại vé đó mang lại. (Chú ý: Nếu mã loại vé đó không tồn tại thì phải trả về 0)
drop function f1
CREATE FUNCTION [dbo].[F1] (@maLoaiVe nvarchar(10))
RETURNS INT
AS
BEGIN
	declare @tongDoanhThu int;
	select @tongDoanhThu = isnull(sum(b.TRIGIA),0)
	from BANVE b
	where MALV = @maLoaiVe

    RETURN @tongDoanhThu 
END

select dbo.F1('LV09')

--a) Tạo người dùng User1 có thông tin đăng nhập:
--Login = ‘User1’; Password = “USER1”
--b) Tạo vai trò người dùng (Role) như sau: DataEntry
--c) Gán User1 vào vai trò DataEntry
--Cho vai trò DataEntry các quyền SELECT, INSERT, và UPDATE trên quan hệ

-- Nếu bạn chỉ muốn cấp quyền cho một bảng cụ thể (ví dụ: BANVE), dùng:
-- GRANT SELECT, INSERT, UPDATE ON BANVE TO DataEntry;
create login User2 with password = 'USER2';
create user User2 for login User2;
create role DateEntry;
alter role DateEntry add member User2;

grant select, insert, update on SCHEMA::dbo TO DateEntry;
