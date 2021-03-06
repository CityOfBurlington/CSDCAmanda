USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_CodeEnforcementFolderStatus]    Script Date: 9/9/2013 9:56:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_CodeEnforcementFolderStatus] (@dtmStartDate DATETIME, @dtmEndDate DATETIME)
AS
SELECT 
DATENAME(mm, F.InDate) + ', ' + DATENAME(yy, F.InDate) AS CreatedMonth,
VF.FolderDesc + ' (' + F.FolderType + ')' AS FolderType, 
VS.StatusDesc,
CAST(Month(F.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.FinalDate) AS VARCHAR(4)) AS ClosedMonth,
SUM(1) AS FolderCount,
YEAR(F.InDate) AS FolderSort1, 
MONTH(F.InDate) AS FolderSort2
FROM Folder F, ValidFolder VF, ValidStatus VS
WHERE (F.FolderType = VF.FolderType)
AND (F.StatusCode = VS.StatusCode)
AND (F.FolderType = 'Q2' OR F.FolderType LIKE 'V%')
AND ((F.InDate BETWEEN @dtmStartDate AND @dtmEndDate) 
OR (F.FinalDate BETWEEN @dtmStartDate AND @dtmEndDate))
GROUP BY 
DATENAME(mm, F.InDate) + ', ' + DATENAME(yy, F.InDate),
VF.FolderDesc + ' (' + F.FolderType + ')',
VS.StatusDesc,
CAST(Month(F.FinalDate) AS VARCHAR(2)) + '-' + CAST(YEAR(F.FinalDate) AS VARCHAR(4)),
Year(F.InDate), 
Month(F.InDate)
ORDER BY F.FolderType, YEAR(F.InDate), MONTH(F.InDate)

GO
