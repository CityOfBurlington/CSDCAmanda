USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementResolvedCases]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_CodeEnforcementResolvedCases] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
select distinct 
CAST(Month(folder.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.InDate) AS VARCHAR(4)) AS CreatedMonth,
CAST(Month(folder.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.FinalDate) AS VARCHAR(4)) AS ClosedMonth,
folder.folderrsn, folder.propertyrsn, 
property.propHouse + ' ' + property.propStreet as Address, 
folder.foldertype, vs.statusdesc,
YEAR(folder.InDate) AS FolderSort1, 
MONTH(folder.InDate) AS FolderSort2
from  folder 
inner join validstatus vs on folder.statuscode = vs.statuscode 
inner join property on folder.propertyrsn = property.propertyrsn
where (folder.foldertype LIKE 'V%')
and (vs.statusdesc = 'Resolved')
and (folder.indate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME) or folder.finaldate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME))
order by YEAR(folder.InDate), 
MONTH(folder.InDate)



GO
