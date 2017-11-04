BEGIN TRANSACTION;  
	 
	with Duplicate_Performers_CTE 
	as
	(
	select * ,ROW_NUMBER() OVER (PARTITION BY InstanceID, Performer order by [Order] desc) RANKD
	from  [dbo].[dvtable_{CF9010D2-CFB7-41E7-9DAE-524B4FD579C8}] as CardRegistration_Performers)

	delete Duplicate_Performers_CTE where RANKD > 1;
	
	select CardRegistration_Performers.InstanceID, CardRegistration_Performers.Performer,COUNT(*)
	 from 
	[dbo].[dvtable_{CF9010D2-CFB7-41E7-9DAE-524B4FD579C8}] as CardRegistration_Performers
	group by CardRegistration_Performers.InstanceID, CardRegistration_Performers.Performer
	having COUNT(*) >1;
	
ROLLBACK;
