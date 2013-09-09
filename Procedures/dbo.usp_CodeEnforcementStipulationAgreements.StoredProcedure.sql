USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementStipulationAgreements]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_CodeEnforcementStipulationAgreements] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
select distinct 
CAST(Month(folder.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.InDate) AS VARCHAR(4)) AS CreatedMonth,
CAST(Month(folder.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.FinalDate) AS VARCHAR(4)) AS ClosedMonth,
folder.folderrsn, folder.propertyrsn, 
accountbillfee.feeamount,
property.propHouse + ' ' + property.propStreet as Address,
VS.StatusDesc,
YEAR(folder.InDate) AS FolderSort1, 
MONTH(folder.InDate) AS FolderSort2
from  folder 
inner join validstatus vs on folder.statuscode = vs.statuscode 
inner join property on folder.propertyrsn = property.propertyrsn
inner join accountbillfee on folder.folderrsn = accountbillfee.folderrsn
where (folder.foldertype LIKE 'V%')
and (vs.statusdesc = 'Stipulation Agreement')
and (folder.indate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME) or folder.finaldate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME))
order by YEAR(folder.InDate), 
MONTH(folder.InDate)

GO
