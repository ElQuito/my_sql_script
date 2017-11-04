if not exists (select name from sys.databases where name = N'Test_Data_BI')
	create database [Test_Data_BI];
GO



drop table [Test_Data_BI].[dbo].[diff_time_approval];
go

create table [Test_Data_BI].[dbo].diff_time_approval(
	InstanceID uniqueidentifier not null ,
	CreationDateTime datetime,
	ApprovalDate datetime,
    DisplayString nvarchar(100),
	Name nvarchar(max),
    DateDiffTime int,
	NamberDoc nvarchar(100));
go

insert into [Test_Data_BI].[dbo].diff_time_approval 
select  CardTask_TaskData.InstanceID
		,cast(CardTask_TaskData.CreationDateTime as datetime) as CreationDateTime 
		,cast(CardResolutio_Data.ApprovalDate as datetime) as ApprovalDate
		,RefStaff_Employees.DisplayString
		,RefStaff_Units.Name
		,DATEDIFF (hour ,CardTask_TaskData.CreationDateTime,CardResolutio_Data.ApprovalDate) as DateDiffTime
		,isnull(CardRegistration_DDMSystem.RegistrationNumber,CardRegistration_DDMSystem.SystemNumber) as NamberDoc
from [dbo].[dvtable_{794E3A56-36F4-4A48-AC56-4CE21C794E26}] as CardTask_TaskData
inner join [dbo].[dvtable_{C2821C8E-510A-437D-B9FC-1F1E4B283C50}] as CardResolutio_Data
on CardTask_TaskData.Resolution = CardResolutio_Data.InstanceID 
	and CardResolutio_Data.ApprovalDate is not null
inner join [dbo].[dvtable_{DBC8AE9D-C1D2-4D5E-978B-339D22B32482}] as RefStaff_Employees
on CardTask_TaskData.Executes = RefStaff_Employees.RowID
inner join [dbo].[dvtable_{7473F07F-11ED-4762-9F1E-7FF10808DDD1}] as RefStaff_Units
on RefStaff_Employees.RootDepartment = RefStaff_Units.RowID
inner join [dbo].[dvtable_{88E884FD-5FD2-4F8F-A8CF-53CB50A8C085}] as CardRegistration_DDMSystem
on CardTask_TaskData.RegCard = CardRegistration_DDMSystem.InstanceID
where CardTask_TaskData.kind = '16FFF884-64AA-4B96-990B-0C6DFDF96C63'  --поручение
	or CardTask_TaskData.kind = '103FE7F7-AABE-42F4-AC29-35F2CD545C48' --передан получателям