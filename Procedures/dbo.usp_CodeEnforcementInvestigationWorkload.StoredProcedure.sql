USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementInvestigationWorkload]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[usp_CodeEnforcementInvestigationWorkload] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
select distinct 
CAST(Month(folder.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(folder.InDate) AS VARCHAR(4)) AS CreatedMonth,
folder.folderrsn, folder.propertyrsn, 
property.propHouse + ' ' + property.propStreet as Address, 
validuser.UserName,
folder.foldertype, vs.statusdesc,
YEAR(folder.InDate) AS FolderSort1, 
MONTH(folder.InDate) AS FolderSort2
from  folder 
inner join validstatus vs on folder.statuscode = vs.statuscode 
inner join foldercomment on folder.folderrsn = foldercomment.folderrsn
inner join validuser on foldercomment.commentuser = validuser.userid
inner join property on folder.propertyrsn = property.propertyrsn
where (folder.foldertype = 'Q2')
and (foldercomment.CommentDate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME))
order by YEAR(folder.InDate), 
MONTH(folder.InDate)


GO
