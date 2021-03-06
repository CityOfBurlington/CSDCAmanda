USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementCOIssued]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[usp_CodeEnforcementCOIssued] (@dtmStartDate varchar(10), @dtmEndDate varchar(10))
as
SELECT 
CAST(Month(F.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.InDate) AS VARCHAR(4)) AS CreatedMonth,
CAST(Month(F.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.FinalDate) AS VARCHAR(4)) AS ClosedMonth,
F.FolderType, 
VF.FolderDesc, 
VS.StatusDesc,
SUM(1) AS FolderCount,
YEAR(F.InDate) AS FolderSort1, 
MONTH(F.InDate) AS FolderSort2
FROM Folder F
INNER JOIN ValidFolder VF ON F.FolderType = VF.FolderType
INNER JOIN ValidStatus VS ON F.StatusCode = VS.StatusCode
WHERE (F.FolderType LIKE 'Z%')
AND (F.FinalDate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME) 
or F.Indate between CAST(@dtmStartDate AS DATETIME) AND CAST(@dtmEndDate AS DATETIME) )
AND (VS.StatusDesc = 'Final CO Issued' OR VS.StatusDesc = 'Temp CO Issued')
GROUP BY 
CAST(Month(F.InDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.InDate) AS VARCHAR(4)),
CAST(Month(F.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.FinalDate) AS VARCHAR(4)),
F.FolderType, 
VF.FolderDesc,
VS.StatusDesc,
Year(F.InDate), 
Month(F.InDate)
ORDER BY F.FolderType, YEAR(F.InDate), MONTH(F.InDate)

GO
