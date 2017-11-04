if not exists (select name from sys.databases where name = N'Test_Data_BI')
	create database [Test_Data_BI];
GO



drop table [Test_Data_BI].[dbo].[table_info_BI];


create table [Test_Data_BI].[dbo].table_info_BI(
	InstanceID uniqueidentifier not null ,
	OperationName nvarchar(50),
	DisplayString nvarchar(512),
    SystemNumber nvarchar(50),
	RegistrationNumber nvarchar(50),
    LogDate Date);
go

insert into [Test_Data_BI].[dbo].table_info_BI 
select
	-- Инстанс карточки
	CardRegistration_RegistrationData_1.InstanceID
	-- Название операции
	,case logapp.OperationID
				when 'c7702925-48f5-45a0-975a-a71436584011' then 'Сохранен файл'
				when '99adad55-5731-477b-871a-cf5e5bb402ad' then 'Открыт файл'
				when 'af3a6c48-ef17-4fda-a4b2-2e2bc83d0d7a' then 'Файл сохранен на диск'
				else ''
				end as OperationName 
	-- Пользователь выполнивший операцию
	,RefStaff_Employees.DisplayString
	-- Системный номер
	,CardRegistration_DDMSystem.SystemNumber
	-- Регистрационный номер и дата регистрации
	,CardRegistration_DDMSystem.RegistrationNumber + ' от ' + convert(varchar,CardRegistration_RegistrationData_1.RegistrationDate, 104)
	-- Дата выполнения операции
	,logapp.[Date]
	
	from [dbo].[dvtable_{F9D3EF11-A060-415A-BE69-DA9EFD3CA436}] as CardRegistration_RegistrationData_1
	inner join dvsys_log_application as logapp 
	on CardRegistration_RegistrationData_1.InstanceID = logapp.ResourceID
		and (logapp.OperationID = 'c7702925-48f5-45a0-975a-a71436584011' 
			or logapp.OperationID = '99adad55-5731-477b-871a-cf5e5bb402ad' 
			or logapp.OperationID = 'af3a6c48-ef17-4fda-a4b2-2e2bc83d0d7a' )
		and logapp.[Date] > '2016-01-01' -- здесь выставляем дату от которой делать выборку
	inner join [dbo].[dvtable_{DBC8AE9D-C1D2-4D5E-978B-339D22B32482}] as RefStaff_Employees 
	on RefStaff_Employees.RowID = logapp.EmployeeID
	inner join [dbo].[dvtable_{88E884FD-5FD2-4F8F-A8CF-53CB50A8C085}] as CardRegistration_DDMSystem  
	on CardRegistration_DDMSystem.InstanceID = CardRegistration_RegistrationData_1.InstanceID
	
	where   
			-- исключаем всех делопроизводителей общего отдела
			(logapp.EmployeeID not in  
				(select RefStaff_Group.EmployeeID  from [dbo].[dvtable_{A960E37B-F1BD-4981-858D-AE9706E0571E}] as RefStaff_Group
					where RefStaff_Group.ParentRowID = 'A23E85EA-B3B0-45DA-AD56-54038EF0389B') -- группа делопроизводителей
			and CardRegistration_RegistrationData_1.RegistratorDepartment !='5C452C92-2D6C-419A-88E9-BE6051D72349' -- Отдел делопроизводства
			) 
			-- исключаем всех регистраторов управлений
			and
				(not exists (
						select top 1 CardRegistration_RegistrationData_2.InstanceID
						from [dbo].[dvtable_{F9D3EF11-A060-415A-BE69-DA9EFD3CA436}] as CardRegistration_RegistrationData_2
						where CardRegistration_RegistrationData_2.InstanceID = CardRegistration_RegistrationData_1.InstanceID
						and CardRegistration_RegistrationData_2.Registrator = logapp.EmployeeID
						and  CardRegistration_RegistrationData_2.RegistratorDepartment = 
							(select RefStaff_Employees_2.RootDepartment 
							from [dbo].[dvtable_{DBC8AE9D-C1D2-4D5E-978B-339D22B32482}] as RefStaff_Employees_2
							where RowID = logapp.EmployeeID)
					)
				and
				-- исключаем всех участников РК включая заместителей
				not exists(
								select top 1 CardRegistration_RegistrationData_3.InstanceID
								from [dbo].[dvtable_{F9D3EF11-A060-415A-BE69-DA9EFD3CA436}] as CardRegistration_RegistrationData_3
								left join  [dbo].[dvtable_{CF9010D2-CFB7-41E7-9DAE-524B4FD579C8}] as CardRegistration_Performers 
								on CardRegistration_RegistrationData_3.InstanceID = CardRegistration_Performers.InstanceID
								left join [dbo].[dvtable_{D045C254-E38E-4A0F-B7B0-40BCB5FB8C87}] as CardRegistration_Approvers
								on CardRegistration_RegistrationData_3.InstanceID = CardRegistration_Approvers.InstanceID
								left join  [dbo].[dvtable_{5A296B39-B9F1-406E-9CBC-1123067923C5}] as CardRegistration_Addressees
								on CardRegistration_RegistrationData_3.InstanceID = CardRegistration_Addressees.InstanceID
								where 
										CardRegistration_RegistrationData_3.InstanceID = CardRegistration_RegistrationData_1.InstanceID
									and
										(CardRegistration_RegistrationData_3.Performer = logapp.EmployeeID 
										or CardRegistration_RegistrationData_3.Operator = logapp.EmployeeID 
										or CardRegistration_RegistrationData_3.Registrator = logapp.EmployeeID
										or CardRegistration_Performers.Performer = logapp.EmployeeID
										or CardRegistration_Approvers.Approver = logapp.EmployeeID
										or CardRegistration_Addressees.StaffEmpl = logapp.EmployeeID
										-- исключаем заместителей
										or CardRegistration_RegistrationData_3.Performer in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID)
										or CardRegistration_RegistrationData_3.Operator  in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										or CardRegistration_RegistrationData_3.Registrator   in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										or CardRegistration_Performers.Performer in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID)
										or CardRegistration_Approvers.Approver in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID)
										or CardRegistration_Addressees.StaffEmpl in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID)
										)
									)
				and 
				-- исключаем всех участников КЗ включая заместителей
				not exists(
								select top 1 CardTask_TaskData.RegCard 
								from [dbo].[dvtable_{794E3A56-36F4-4A48-AC56-4CE21C794E26}] as CardTask_TaskData
								where 
									CardTask_TaskData.RegCard = CardRegistration_RegistrationData_1.InstanceID
									and ( CardTask_TaskData.Curator = logapp.EmployeeID 
										or CardTask_TaskData.Author = logapp.EmployeeID 
										or CardTask_TaskData.Appointed = logapp.EmployeeID 
										or CardTask_TaskData.Executes = logapp.EmployeeID
										-- исключаем заместителей
										or CardTask_TaskData.Curator  in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										or CardTask_TaskData.Author in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										or CardTask_TaskData.Appointed in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										or CardTask_TaskData.Executes in 
										(select RefStaff_Deputies.ParentRowID 
											from [dbo].[dvtable_{ED414CB4-B205-4BE4-A2FA-5C0D3347CEB3}] as RefStaff_Deputies
											where RefStaff_Deputies.DeputyID = logapp.EmployeeID) 
										)
								));
