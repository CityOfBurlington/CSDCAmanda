USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementComplianceMemo]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_CodeEnforcementComplianceMemo] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
select distinct 
CAST(Month(folder.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.InDate) AS VARCHAR(4)) AS CreatedMonth,
folder.folderrsn, folder.propertyrsn, 
accountbillfee.feeamount,
property.propHouse + ' ' + property.propStreet as Address,
YEAR(folder.InDate) AS FolderSort1, 
MONTH(folder.InDate) AS FolderSort2
from  folder 
inner join property on folder.propertyrsn = property.propertyrsn
inner join accountbillfee on folder.folderrsn = accountbillfee.folderrsn
inner join folderdocument on folder.folderrsn = folderdocument.folderrsn
where (folder.foldertype = 'QN')
and (folderdocument.DocumentCode = 21016)
and (folderdocument.DateGenerated between CAST(@dtmStartDate AS DATETIME) and CAST(@dtmEndDate AS DATETIME))
order by YEAR(folder.InDate), 
MONTH(folder.InDate)

GO
