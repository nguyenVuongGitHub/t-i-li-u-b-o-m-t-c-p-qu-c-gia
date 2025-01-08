use master
drop database QLdulich2
create database QLdulich2
use QLdulich2
-- loại địa điểm
CREATE TABLE LOAIDD(
	MALDD NVARCHAR(10) PRIMARY KEY,
	TENLDD NVARCHAR(255) NOT NULL
)
-- địa điểm tham quan
create table DIADIEMTQ(
MADD NVARCHAR(10) PRIMARY KEY,
TENDD NVARCHAR(255) NOT NULL,
KHUVUC NVARCHAR(255) NOT NULL UNIQUE,
THONGTINGT NVARCHAR(255) NOT NULL,
NAMKT INT NOT NULL,
MALDD NVARCHAR(10),
foreign key(MALDD) REFERENCES LOAIDD(MALDD)
)
-- loại vé
CREATE TABLE LOAIVE(
MALV NVARCHAR(10) PRIMARY KEY,
TENLV NVARCHAR(255) NOT NULL,
GIAVE INT NOT NULL,
HANSD int NOT NULL
)

CREATE TABLE CTLOAIVE (
    MACTLV NVARCHAR(10), 
    MALV NVARCHAR(10) NOT NULL, 
    MALDD NVARCHAR(10) NOT NULL,
    
    CONSTRAINT PK_CTLOAIVE PRIMARY KEY (MALV, MALDD), 
    CONSTRAINT FK_CTLOAIVE_LOAIVE FOREIGN KEY (MALV) REFERENCES LOAIVE(MALV), 
    CONSTRAINT FK_CTLOAIVE_LOAIDD FOREIGN KEY (MALDD) REFERENCES LOAIDD(MALDD)
);
-- bán vé
CREATE TABLE BANVE(
	MABV NVARCHAR(10) PRIMARY KEY,
	MALV NVARCHAR(10) NOT NULL,
	FOREIGN KEY (MALV) REFERENCES LOAIVE(MALV),

	SOLUONG INT NOT NULL,
	TRIGIA INT,
	NGAYBAN DATE NOT NULL,
	NGAYHH DATE
);

-- Insert values for LOAIDD
INSERT INTO LOAIDD (MALDD, TENLDD) VALUES
('LDD01', 'Khu vui chơi'),
('LDD02', 'Công viên'),
('LDD03', 'Bảo tàng'),
('LDD04', 'Khu nghỉ dưỡng'),
('LDD05', 'Khu di tích');

-- Insert values for DIADIEMTQ
INSERT INTO DIADIEMTQ (MADD, TENDD, KHUVUC, THONGTINGT, NAMKT, MALDD) VALUES
('DD01', 'Công viên Văn hóa', 'Quận 1', 'Khu vui chơi giải trí nổi tiếng', 1995, 'LDD02'),
('DD02', 'Bảo tàng Lịch sử', 'Quận 3', 'Nơi trưng bày hiện vật lịch sử', 1980, 'LDD03'),
('DD03', 'Khu nghỉ dưỡng Biển Xanh', 'Thành phố Biển', 'Khu nghỉ dưỡng cao cấp', 2005, 'LDD04'),
('DD04', 'Khu vui chơi Giải trí ABC', 'Quận 7', 'Khu vui chơi hiện đại', 2010, 'LDD01'),
('DD05', 'Khu di tích Văn Miếu', 'Hà Nội', 'Khu di tích lịch sử quốc gia', 1985, 'LDD05');

-- Insert values for LOAIVE (HANSD now represents validity days: 0, 1, or 2)
INSERT INTO LOAIVE (MALV, TENLV, GIAVE, HANSD) VALUES
('LV01', 'Vé người lớn', 100000, 1),
('LV02', 'Vé trẻ em', 50000, 0),
('LV03', 'Vé tham quan theo nhóm', 80000, 2),
('LV04', 'Vé VIP', 200000, 2),
('LV05', 'Vé miễn phí', 0, 0);

-- Insert values for CTLOAIVE
INSERT INTO CTLOAIVE (MACTLV, MALV, MALDD) VALUES
('CT01', 'LV01', 'LDD01'),
('CT02', 'LV02', 'LDD02'),
('CT03', 'LV03', 'LDD03'),
('CT04', 'LV04', 'LDD04'),
('CT05', 'LV05', 'LDD05');

-- Insert values for BANVE (NGAYHH computed as NGAYBAN + HANSD)
INSERT INTO BANVE (MABV, MALV, SOLUONG, TRIGIA, NGAYBAN, NGAYHH) VALUES
('BV01', 'LV01', 2, 200000, '2025-01-01', DATEADD(DAY, 1, '2025-01-01')), -- 1-day validity
('BV02', 'LV02', 3, 150000, '2025-01-02', DATEADD(DAY, 0, '2025-01-02')), -- same-day validity
('BV03', 'LV03', 5, 400000, '2025-01-03', DATEADD(DAY, 2, '2025-01-03')), -- 2-day validity
('BV04', 'LV04', 1, 200000, '2025-01-04', DATEADD(DAY, 2, '2025-01-04')), -- 2-day validity
('BV05', 'LV05', 0, 0, '2025-01-05', DATEADD(DAY, 0, '2025-01-05')); -- same-day validity


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

create login User2 with password = 'USER2';
create user User2 for login User2;
create role DateEntry;
alter role DateEntry add member User2;

grant select, insert, update on SCHEMA::dbo TO DateEntry;
