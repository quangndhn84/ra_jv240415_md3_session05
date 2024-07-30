create database HR_Salary_DB;
use HR_Salary_db;
create table Department(
	dept_id int primary key auto_increment,
    dept_name varchar(100) not null unique check(length(dept_name)>=6)
);
create table Levels(
	level_id int primary key auto_increment,
    level_name varchar(100) not null unique,
    level_basic_salary float not null check(level_basic_salary>=3500000),
    level_allowance_salary float default(500000)
);
create table Employee(
	emp_id int primary key auto_increment,
    emp_name varchar(150) not null,
    emp_email varchar(150) not null unique,
    emp_phone varchar(50) not null unique,
    emp_address varchar(255),
    emp_gender tinyint not null check(emp_gender between 0 and 2),
    emp_birthday date not null,
    level_id int not null,
    foreign key(level_id) references Levels(level_id),
    dept_id int not null,
    foreign key(dept_id) references Department(dept_id)
);
create table TimeSheets(
	ts_id int primary key auto_increment,
    ts_attendance_date date,
    emp_id int not null,
    foreign key(emp_id) references Employee(emp_id),
    ts_value float default(1) check(ts_value in (0,0.5,1))
);
DELIMITER &&
create trigger ts_default_attendance before insert on timesheets
for each row
BEGIN
	if new.ts_attendance_date is null then
		set new.ts_attendance_date = current_date();
    end if;
END &&
DELIMITER &&;
DELIMITER &&
create trigger ts_default_attendance_update before update on timesheets
for each row
BEGIN
	if new.ts_attendance_date is null then
		set new.ts_attendance_date = current_date();
    end if;
END &&
DELIMITER &&;
create table salary(
	salary_id int primary key auto_increment,
    emp_id int not null,
    foreign key(emp_id) references Employee(emp_id),
    salary_bonus_salary float default(0),
    salary_insurrance float not null
);
-- trigger thực hiện set salary_insurrance mặc định giá trị = 10% basic_salary
DELIMITER &&
create trigger before_insert_salary before insert on salary for each row
BEGIN
	-- lay basic salary
    declare  basic_salary float;
    set basic_salary = (select l.level_basic_salary 
						from Levels l join Employee e on l.level_id= e.level_id
                        where e.emp_id = new.emp_id);
	set new.salary_insurrance = 0.1*basic_salary;
END &&
DELIMITER &&;
-- Yêu cầu 1:
/*
	1.Lấy ra danh sách Employee có sắp xếp tăng dần theo Name gồm các cột sau: 
    Id, Name, Email, Phone, Address, Gender, BirthDay, Age, DepartmentName, LevelName
*/
select e.emp_id, e.emp_name, e.emp_email, e.emp_phone, e.emp_address, e.emp_gender,
		e.emp_birthday, year(current_date())-year(e.emp_birthday) as 'Age', d.dept_name, l.level_name
from employee e join department d on e.dept_id = d.dept_id join Levels l on e.level_id = l.level_id
order by e.emp_name;
/*
	4.	Cập nhật cột BonusSalary lên 10% cho tất cả các Nhân viên 
    có số ngày công >= 20 ngày trong tháng 10 năm 2020 
*/
-- Cập nhật bonus_salary lên 10%
update salary
set salary_bonus_salary = 1.1 * salary_bonus_salary
where emp_id in (
-- Câu lệnh truy vấn ra các nhân viên có số ngày công >= 20 ngày trong tháng 10 năm 2020
select ts.emp_id
from timesheets ts
where ts.ts_attendance_date between '2020-10-01' and '2020-10-31'
group by ts.emp_id
having count(ts.ts_id)>=20);
/*
	3.3.Thủ tục getEmployeePaginate lấy ra danh sách nhân viên có phân trang gồm:
    Id, Name, Email, Phone, Address, Gender, BirthDay, 
    Khi gọi thủ tuc truyền vào limit và page
*/
DELIMITER &&
create procedure getEmployeePaginate(
	limit_in int, -- số dữ liệu hiện thị trên 1 trang
    page_in int -- trang hiển thị dữ liệu
)
BEGIN
	declare offset_in int;
    set offset_in = (page_in-1)*limit_in;
	select e.emp_id,e.emp_name, e.emp_email, e.emp_phone, e.emp_address, e.emp_birthday
    from employee e
    limit limit_in offset offset_in;
END &&
DELIMITER &&;






