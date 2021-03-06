USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementViolationsSent]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_CodeEnforcementViolationsSent] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
select 
folder.foldertype, vs.statusdesc, sum(1) as countofviolations
from  folder inner join validstatus vs on folder.statuscode = vs.statuscode 
where (folder.foldertype = 'Q2' or folder.foldertype like 'V%')
and ((vs.statusdesc = 'Notice of Violation' and (folder.indate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME) OR folder.finaldate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME)))
or folder.folderrsn in(
select distinct attachment.tablersn
from attachment 
inner join folder f on attachment.tablersn = f.folderrsn
inner join validstatus on f.statuscode = validstatus.statuscode
where AttachmentDesc like '%Notice of Violation%'
and (f.foldertype = 'Q2' or foldertype like 'V%')
and (attachment.stampdate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME))) 
)
group by  folder.foldertype, vs.statusdesc
order by 1


GO
