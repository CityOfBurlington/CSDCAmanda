USE [AMANDA_Production]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetAttemptSummary]    Script Date: 9/9/2013 9:56:57 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_GetAttemptSummary](@FolderRSN INT)
AS

SELECT DISTINCT FolderProcess.FolderRSN, FolderProcessAttempt.ProcessRSN, 
dbo.udf_GetDeficiencyDates(FolderProcessAttempt.ProcessRSN) AS Dates,
ValidProcess.ProcessDesc,
dbo.udf_SummarizeAttemptStatus(FolderProcessAttempt.ProcessRSN) AS Status
FROM FolderProcess 
INNER JOIN ValidProcess ON FolderProcess.ProcessCode = ValidProcess.ProcessCode
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcessAttempt.ResultCode = 45

UNION

SELECT DISTINCT FolderProcess.FolderRSN, FolderProcessAttempt.ProcessRSN, 
dbo.udf_Trunc(FolderProcessAttempt.AttemptDate) AS Dates,
ValidProcess.ProcessDesc,
ValidProcessAttemptResult.ResultDesc AS Status
FROM FolderProcess 
INNER JOIN ValidProcess ON FolderProcess.ProcessCode = ValidProcess.ProcessCode
INNER JOIN FolderProcessAttempt ON FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
INNER JOIN ValidProcessAttemptResult ON FolderProcessAttempt.ResultCode = ValidProcessAttemptResult.ResultCode
WHERE FolderProcessAttempt.FolderRSN = @FolderRSN
AND FolderProcessAttempt.ResultCode <> 45

GO
