USE [AMANDA_Production]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_GetZoningDecisionAttemptCode]    Script Date: 9/9/2013 9:43:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[udf_GetZoningDecisionAttemptCode](@intFolderRSN INT)
RETURNS INT
AS
BEGIN
DECLARE @intAttemptCode int
DECLARE @intProcessCode int

SET @intAttemptCode = 0 

SELECT @intProcessCode = dbo.udf_GetZoningDecisionProcessCode(@intFolderRSN)

SELECT @intAttemptCode = ISNULL(FolderProcessAttempt.ResultCode, 0)
FROM Folder, FolderProcess, FolderProcessAttempt 
WHERE Folder.FolderRSN = FolderProcess.FolderRSN
AND FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
AND FolderProcess.ProcessCode = @intProcessCode
AND Folder.FolderRSN = @intFolderRSN
AND FolderProcessAttempt.AttemptRSN = 
    ( SELECT max(FolderProcessAttempt.AttemptRSN) 
        FROM FolderProcess, FolderProcessAttempt
       WHERE FolderProcess.ProcessRSN = FolderProcessAttempt.ProcessRSN
         AND FolderProcess.ProcessCode = @intProcessCode
         AND FolderProcessAttempt.FolderRSN = @intFolderRSN )

RETURN @intAttemptCode
END

GO
